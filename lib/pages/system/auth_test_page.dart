import 'package:flutter/material.dart';
import 'package:tronskins_app/api/loginServer.dart';
import 'package:tronskins_app/common/http/interceptors/auth_interceptor.dart';
import 'package:tronskins_app/common/storage/session_storage.dart';
import 'package:tronskins_app/common/storage/user_storage.dart';

class AuthTestPage extends StatefulWidget {
  const AuthTestPage({super.key});

  @override
  State<AuthTestPage> createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  final ApiLoginServer _api = ApiLoginServer();
  final List<_LogEntry> _logs = <_LogEntry>[];

  bool _running = false;
  String? _token;
  int? _accessExpireTime;
  int? _refreshExpireTime;
  String? _refreshTokenCookie;

  @override
  void initState() {
    super.initState();
    _refreshSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasToken = AuthInterceptor.hasToken;
    final accessExpired = AuthInterceptor.isAccessTokenExpired;

    return Scaffold(
      appBar: AppBar(title: const Text('认证测试中心')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_running) const LinearProgressIndicator(minHeight: 2),
            _buildSnapshotCard(
              theme: theme,
              hasToken: hasToken,
              accessExpired: accessExpired,
            ),
            const SizedBox(height: 12),
            _buildActionCard(),
            const SizedBox(height: 12),
            _buildLogCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotCard({
    required ThemeData theme,
    required bool hasToken,
    required bool accessExpired,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前认证状态',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildSnapshotRow('已登录', hasToken ? '是' : '否'),
            _buildSnapshotRow('Access 是否过期', accessExpired ? '是' : '否'),
            _buildSnapshotRow('Access 过期时间', _formatTime(_accessExpireTime)),
            _buildSnapshotRow('Refresh 过期时间', _formatTime(_refreshExpireTime)),
            _buildSnapshotRow('Refresh Cookie', _preview(_refreshTokenCookie)),
            _buildSnapshotRow('Access Token', _preview(_token)),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionButton(label: '刷新状态', onTap: _refreshSnapshot),
            _buildActionButton(
              label: '手动刷新Token',
              onTap: () => _runAction('手动刷新Token', _manualRefreshToken),
            ),
            _buildActionButton(
              label: '请求用户信息',
              onTap: () => _runAction('请求用户信息', _requestUserInfo),
            ),
            _buildActionButton(
              label: '标记Access过期',
              onTap: () => _runAction('标记Access过期', _markAccessExpired),
            ),
            _buildActionButton(
              label: '验证自动刷新',
              onTap: () => _runAction('验证自动刷新', _verifyAutoRefreshFlow),
            ),
            _buildActionButton(
              label: '清理登录态',
              onTap: () => _runAction('清理登录态', _clearAuthState),
            ),
            _buildActionButton(
              label: '清空日志',
              onTap: () async {
                setState(() {
                  _logs.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Future<void> Function() onTap,
  }) {
    return FilledButton.tonal(
      onPressed: _running
          ? null
          : () async {
              await onTap();
            },
      child: Text(label),
    );
  }

  Widget _buildLogCard(ThemeData theme) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '执行日志',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_logs.isEmpty)
              const Text('暂无日志', style: TextStyle(color: Color(0xFF6B7280))),
            if (_logs.isNotEmpty)
              ..._logs.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatClock(entry.time),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.message,
                          style: TextStyle(
                            fontSize: 12,
                            color: _levelColor(entry.level),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshSnapshot() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _token = AuthInterceptor.token;
      _accessExpireTime = AuthInterceptor.accessTokenExpireTime;
      _refreshExpireTime = AuthInterceptor.refreshTokenExpireTime;
      _refreshTokenCookie = SessionStorage.getRefreshToken();
    });
  }

  Future<void> _runAction(String name, Future<void> Function() action) async {
    if (_running) {
      _appendLog(_LogLevel.warn, '正在执行任务，请稍后');
      return;
    }

    setState(() {
      _running = true;
    });
    _appendLog(_LogLevel.info, '$name 开始');

    try {
      await action();
      _appendLog(_LogLevel.success, '$name 完成');
    } catch (error) {
      _appendLog(_LogLevel.error, '$name 失败: ${_errorMessage(error)}');
    } finally {
      await _refreshSnapshot();
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  Future<void> _manualRefreshToken() async {
    final result = await _api.refreshAccessToken();
    if (!result.success || result.datas == null) {
      throw Exception(result.message.isEmpty ? '刷新接口返回失败' : result.message);
    }

    final payload = result.datas!;
    final accessToken =
        payload['accessToken']?.toString() ??
        payload['token']?.toString() ??
        '';
    if (accessToken.isEmpty) {
      throw Exception('刷新接口未返回 access token');
    }

    await AuthInterceptor.setAccessToken(
      accessToken: accessToken,
      accessTokenExpireTime: _toInt(payload['accessTokenExpireTime']),
      refreshTokenExpireTime:
          _toInt(payload['refreshTokenExpireTime']) ??
          _toInt(payload['refreshExpireTime']),
      header: payload['header']?.toString(),
    );

    _appendLog(
      _LogLevel.success,
      '刷新成功，accessExpire=${_formatTime(AuthInterceptor.accessTokenExpireTime)}',
    );
  }

  Future<void> _requestUserInfo() async {
    final result = await _api.getUserApi();
    if (!result.success || result.datas == null) {
      throw Exception(result.message.isEmpty ? '用户接口请求失败' : result.message);
    }

    final nickname = result.datas?.nickname ?? '';
    _appendLog(
      _LogLevel.success,
      '用户信息请求成功${nickname.isEmpty ? '' : '，nickname=$nickname'}',
    );
  }

  Future<void> _markAccessExpired() async {
    if (!AuthInterceptor.hasToken) {
      throw Exception('当前没有登录 token');
    }

    final expiredAt = DateTime.now().millisecondsSinceEpoch - 60 * 1000;
    await AuthInterceptor.setAccessTokenExpireTimeForDebug(expiredAt);
    _appendLog(_LogLevel.info, '已设置 access token 本地过期');
  }

  Future<void> _verifyAutoRefreshFlow() async {
    if (!AuthInterceptor.hasToken) {
      throw Exception('当前没有登录 token');
    }

    await AuthInterceptor.setAccessTokenExpireTimeForDebug(
      DateTime.now().millisecondsSinceEpoch - 60 * 1000,
    );
    _appendLog(_LogLevel.info, '先设置本地过期，再请求用户接口');
    await _requestUserInfo();
    final updatedExpire = AuthInterceptor.accessTokenExpireTime;
    _appendLog(
      _LogLevel.success,
      '链路执行后 accessExpire=${_formatTime(updatedExpire)}',
    );
  }

  Future<void> _clearAuthState() async {
    await AuthInterceptor.clearToken();
    SessionStorage.clearAuthCookies();
    UserStorage.setUserInfo(null);
    _appendLog(_LogLevel.info, '本地登录态与认证Cookie已清理');
  }

  void _appendLog(_LogLevel level, String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _logs.insert(0, _LogEntry(level: level, message: message));
      if (_logs.length > 80) {
        _logs.removeRange(80, _logs.length);
      }
    });
  }

  Color _levelColor(_LogLevel level) {
    switch (level) {
      case _LogLevel.success:
        return const Color(0xFF059669);
      case _LogLevel.error:
        return const Color(0xFFDC2626);
      case _LogLevel.warn:
        return const Color(0xFFD97706);
      case _LogLevel.info:
        return const Color(0xFF374151);
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  String _errorMessage(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) {
      return '未知错误';
    }
    return text.replaceFirst('Exception: ', '');
  }

  String _preview(String? text) {
    if (text == null || text.isEmpty) {
      return '(空)';
    }
    if (text.length <= 26) {
      return text;
    }
    return '${text.substring(0, 12)}...${text.substring(text.length - 10)}';
  }

  String _formatTime(int? epochMs) {
    if (epochMs == null) {
      return '未知';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final ttl = epochMs - DateTime.now().millisecondsSinceEpoch;
    final ttlText = ttl <= 0 ? '已过期' : '剩余${(ttl / 1000).floor()}s';
    return '${date.toLocal()} ($ttlText)';
  }

  String _formatClock(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final ss = value.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

enum _LogLevel { info, success, warn, error }

class _LogEntry {
  _LogEntry({required this.level, required this.message})
    : time = DateTime.now();

  final DateTime time;
  final _LogLevel level;
  final String message;
}
