import 'dart:async';

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
  Timer? _ticker;

  bool _running = false;
  String? _token;
  int? _accessExpireTime;
  int? _refreshExpireTime;
  String? _refreshTokenCookie;

  @override
  void initState() {
    super.initState();
    _refreshSnapshot();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasToken = AuthInterceptor.hasToken;
    final accessExpired = AuthInterceptor.isAccessTokenExpired;
    final refreshExpired = _isExpired(_refreshExpireTime);

    return Scaffold(
      backgroundColor: Color.lerp(
        scheme.surface,
        scheme.primaryContainer,
        theme.brightness == Brightness.dark ? 0.08 : 0.14,
      ),
      appBar: AppBar(title: const Text('认证测试中心')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (_running)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(minHeight: 4),
              ),
            if (_running) const SizedBox(height: 14),
            _buildHeroCard(
              theme: theme,
              hasToken: hasToken,
              accessExpired: accessExpired,
              refreshExpired: refreshExpired,
            ),
            const SizedBox(height: 14),
            _buildSnapshotCard(
              theme: theme,
              hasToken: hasToken,
              accessExpired: accessExpired,
              refreshExpired: refreshExpired,
            ),
            const SizedBox(height: 14),
            _buildActionCard(theme),
            const SizedBox(height: 14),
            _buildLogCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required ThemeData theme,
    required bool hasToken,
    required bool accessExpired,
    required bool refreshExpired,
  }) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(scheme.primary, scheme.tertiary, 0.22) ?? scheme.primary,
            Color.lerp(scheme.primaryContainer, scheme.surface, 0.14) ??
                scheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '认证测试中心',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '集中查看 Token 状态、调试刷新链路、跟踪本地认证数据。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.82,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatusPill(
                label: '登录状态',
                value: hasToken ? '已登录' : '未登录',
                icon: hasToken
                    ? Icons.verified_user_rounded
                    : Icons.person_off_rounded,
                tone: hasToken
                    ? const Color(0xFF0F9D58)
                    : const Color(0xFFD97706),
              ),
              _buildStatusPill(
                label: 'Access',
                value: accessExpired ? '已过期' : '有效',
                icon: accessExpired
                    ? Icons.gpp_bad_rounded
                    : Icons.gpp_good_rounded,
                tone: accessExpired
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF2563EB),
              ),
              _buildStatusPill(
                label: 'Refresh',
                value: refreshExpired ? '已过期' : '有效',
                icon: refreshExpired
                    ? Icons.timer_off_rounded
                    : Icons.timelapse_rounded,
                tone: refreshExpired
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF7C3AED),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required String value,
    required IconData icon,
    required Color tone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotCard({
    required ThemeData theme,
    required bool hasToken,
    required bool accessExpired,
    required bool refreshExpired,
  }) {
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前认证状态',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Access 与 Refresh 只显示实时倒计时，便于观察刷新链路。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _running ? null : _refreshSnapshot,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('刷新'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCountdownTile(
                  theme: theme,
                  title: 'Access 倒计时',
                  countdown: _formatCountdown(_accessExpireTime),
                  expired: accessExpired,
                  icon: Icons.key_rounded,
                  accent: accessExpired
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                ),
                _buildCountdownTile(
                  theme: theme,
                  title: 'Refresh 倒计时',
                  countdown: _formatCountdown(_refreshExpireTime),
                  expired: refreshExpired,
                  icon: Icons.restart_alt_rounded,
                  accent: refreshExpired
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF7C3AED),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSnapshotRow(
              theme: theme,
              label: '已登录',
              value: hasToken ? '是' : '否',
            ),
            _buildSnapshotRow(
              theme: theme,
              label: 'Access 是否过期',
              value: accessExpired ? '是' : '否',
            ),
            _buildSnapshotRow(
              theme: theme,
              label: 'Refresh 是否过期',
              value: refreshExpired ? '是' : '否',
            ),
            const SizedBox(height: 10),
            _buildPreviewBlock(
              theme: theme,
              label: 'Refresh Cookie',
              value: _preview(_refreshTokenCookie),
            ),
            const SizedBox(height: 10),
            _buildPreviewBlock(
              theme: theme,
              label: 'Access Token',
              value: _preview(_token),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownTile({
    required ThemeData theme,
    required String title,
    required String countdown,
    required bool expired,
    required IconData icon,
    required Color accent,
  }) {
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 152, maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.lerp(scheme.surfaceContainerHighest, accent, 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    expired ? '已过期' : '进行中',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              countdown,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotRow({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBlock({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(ThemeData theme) {
    final scheme = theme.colorScheme;
    final actions = <_ActionButtonData>[
      _ActionButtonData(
        label: '刷新状态',
        icon: Icons.refresh_rounded,
        description: '重新读取本地 token、cookie 和过期时间。',
        onTap: _refreshSnapshot,
      ),
      _ActionButtonData(
        label: '手动刷新 Token',
        icon: Icons.sync_rounded,
        description: '直接请求刷新接口并写回本地状态。',
        onTap: () => _runAction('手动刷新Token', _manualRefreshToken),
      ),
      _ActionButtonData(
        label: '请求用户信息',
        icon: Icons.person_search_rounded,
        description: '带当前登录态访问用户接口，验证可用性。',
        onTap: () => _runAction('请求用户信息', _requestUserInfo),
      ),
      _ActionButtonData(
        label: '标记 Access 过期',
        icon: Icons.event_busy_rounded,
        description: '本地强制把 Access Token 调成已过期状态。',
        onTap: () => _runAction('标记Access过期', _markAccessExpired),
      ),
      _ActionButtonData(
        label: '验证自动刷新',
        icon: Icons.route_rounded,
        description: '模拟过期后走一遍自动刷新与重试链路。',
        onTap: () => _runAction('验证自动刷新', _verifyAutoRefreshFlow),
      ),
      _ActionButtonData(
        label: '清理登录态',
        icon: Icons.delete_sweep_rounded,
        description: '移除本地 token、cookie 和用户缓存。',
        onTap: () => _runAction('清理登录态', _clearAuthState),
      ),
      _ActionButtonData(
        label: '清空日志',
        icon: Icons.cleaning_services_rounded,
        description: '清理当前调试面板里的执行记录。',
        onTap: () async {
          if (!mounted) {
            return;
          }
          setState(() {
            _logs.clear();
          });
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '调试动作',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '常用认证链路操作集中在这里，便于逐步验证问题。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 680;
                final tileWidth = wide
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: actions
                      .map(
                        (action) => SizedBox(
                          width: tileWidth,
                          child: _buildActionButton(theme: theme, data: action),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required _ActionButtonData data,
  }) {
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _running
            ? null
            : () async {
                await data.onTap();
              },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1628),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '执行日志',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '这里保留最近 80 条动作记录，方便排查刷新链路。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_logs.length} 条',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_logs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  '暂无日志',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            if (_logs.isNotEmpty)
              ..._logs.map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _levelColor(entry.level).withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: _levelColor(entry.level),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatClock(entry.time),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFAAB4C8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.message,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: _levelColor(entry.level),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _levelColor(
                            entry.level,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _levelLabel(entry.level),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
      '刷新成功，access倒计时=${_formatCountdown(AuthInterceptor.accessTokenExpireTime)}',
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
      '链路执行后 access倒计时=${_formatCountdown(updatedExpire)}',
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
        return const Color(0xFF22C55E);
      case _LogLevel.error:
        return const Color(0xFFF87171);
      case _LogLevel.warn:
        return const Color(0xFFF59E0B);
      case _LogLevel.info:
        return const Color(0xFFCBD5E1);
    }
  }

  String _levelLabel(_LogLevel level) {
    switch (level) {
      case _LogLevel.success:
        return 'SUCCESS';
      case _LogLevel.error:
        return 'ERROR';
      case _LogLevel.warn:
        return 'WARN';
      case _LogLevel.info:
        return 'INFO';
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

  bool _isExpired(int? epochMs) {
    if (epochMs == null) {
      return true;
    }
    return epochMs <= DateTime.now().millisecondsSinceEpoch;
  }

  String _formatCountdown(int? epochMs) {
    if (epochMs == null) {
      return '--:--:--';
    }
    final ttl = (epochMs - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
    if (ttl <= 0) {
      return '00:00:00';
    }
    final hours = (ttl ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((ttl % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (ttl % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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

class _ActionButtonData {
  const _ActionButtonData({
    required this.label,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String description;
  final Future<void> Function() onTap;
}
