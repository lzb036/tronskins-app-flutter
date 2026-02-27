import 'package:tronskins_app/api/model/wallet/wallet_models.dart';
import 'package:tronskins_app/common/http/http_helper.dart';
import 'package:tronskins_app/common/http/model/base_response.dart';

class ApiWalletServer {
  final HttpHelper http = HttpHelper.getInstance();

  Future<BaseHttpResponse<WalletListResponse<WalletFundFlowItem>>>
  fundChangesList({int page = 1, int pageSize = 20}) async {
    final response = await http.post(
      'api/app/fund/changes/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletListResponse.fromJson(
        json as Map<String, dynamic>,
        WalletFundFlowItem.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<List<WalletLockedItem>>> lockingFundList({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await http.get(
      'api/app/locking/fund/list',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(response.data as Map<String, dynamic>, (
      json,
    ) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map(WalletLockedItem.fromJson)
            .toList();
      }
      if (json is Map<String, dynamic>) {
        final rawList = json['list'] ?? json['records'];
        if (rawList is List) {
          return rawList
              .whereType<Map<String, dynamic>>()
              .map(WalletLockedItem.fromJson)
              .toList();
        }
      }
      return <WalletLockedItem>[];
    });
  }

  Future<BaseHttpResponse<WalletLockedDetail>> lockingFundDetail({
    required String id,
    int? lockType,
  }) async {
    final response = await http.post(
      'api/app/locking/fund/$id/detail',
      data: {'id': id, if (lockType != null) 'lockType': lockType},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletLockedDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<WalletListResponse<WalletIntegralRecord>>>
  integralChangesList({int page = 1, int pageSize = 20}) async {
    final response = await http.post(
      'api/app/integral/changes/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletListResponse.fromJson(
        json as Map<String, dynamic>,
        WalletIntegralRecord.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<WalletListResponse<WalletRechargeRecord>>>
  rechargeRecords({int page = 1, int pageSize = 20}) async {
    final response = await http.post(
      'api/app/recharge/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletListResponse.fromJson(
        json as Map<String, dynamic>,
        WalletRechargeRecord.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<WalletListResponse<WalletWithdrawRecord>>>
  withdrawRecords({int page = 1, int pageSize = 20}) async {
    final response = await http.post(
      'api/app/withdraws/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletListResponse.fromJson(
        json as Map<String, dynamic>,
        WalletWithdrawRecord.fromJson,
      ),
    );
  }

  Future<BaseHttpResponse<bool>> rechargeCheck() async {
    final response = await http.get('api/app/user/recharge/check');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _asBool(json),
    );
  }

  Future<BaseHttpResponse<bool>> withdrawCheck() async {
    final response = await http.get('api/app/user/withdraw/check');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => _asBool(json),
    );
  }

  Future<BaseHttpResponse<WalletSettlementResponse>> settlementRecords({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await http.post(
      'api/app/settlement/fund/list',
      data: {'page': page, 'pageSize': pageSize},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletSettlementResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<List<WalletCouponItem>>> couponsList() async {
    final response = await http.get('api/app/card/coupons/list');
    return BaseHttpResponse.fromJson(response.data as Map<String, dynamic>, (
      json,
    ) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map(WalletCouponItem.fromJson)
            .toList();
      }
      return <WalletCouponItem>[];
    });
  }

  Future<BaseHttpResponse<dynamic>> couponsExchange({required int type}) async {
    final response = await http.post(
      'api/app/card/coupons/exchange',
      data: {'type': type},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<List<WalletCouponRecord>>> couponsRecords() async {
    final response = await http.get('api/app/card/coupons/record/list');
    return BaseHttpResponse.fromJson(response.data as Map<String, dynamic>, (
      json,
    ) {
      if (json is Map<String, dynamic>) {
        final raw = json['list'];
        if (raw is List) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map(WalletCouponRecord.fromJson)
              .toList();
        }
      }
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map(WalletCouponRecord.fromJson)
            .toList();
      }
      return <WalletCouponRecord>[];
    });
  }

  Future<BaseHttpResponse<List<WalletLotteryPrize>>> lotteryPrizeList() async {
    final response = await http.get('api/app/lottery/app/prize/list');
    return BaseHttpResponse.fromJson(response.data as Map<String, dynamic>, (
      json,
    ) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map(WalletLotteryPrize.fromJson)
            .toList();
      }
      return <WalletLotteryPrize>[];
    });
  }

  Future<BaseHttpResponse<WalletLotteryResult>> integralLottery({
    int type = 1,
  }) async {
    final response = await http.post(
      'api/app/lottery/integral/lottery',
      data: {'type': type},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletLotteryResult.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<dynamic>> withdrawAdd({
    required double amount,
    required String account,
    String? twoFa,
  }) async {
    final response = await http.post(
      'api/app/withdraws/add',
      data: {
        'amount': amount,
        'account': account,
        if (twoFa != null && twoFa.isNotEmpty) 'twoFa': twoFa,
      },
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> withdrawCancel({required String id}) async {
    final response = await http.post(
      'api/app/withdraws/cancel',
      data: {'id': id},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<WalletOfficialWallet>> officialWalletGet() async {
    final response = await http.get('api/app/official/wallet/get');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletOfficialWallet.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<WalletOfficialWallet>> officialWalletAssign() async {
    final response = await http.post('api/app/official/wallet/assign');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletOfficialWallet.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<BaseHttpResponse<dynamic>> consumeChargeCard({
    required String password,
  }) async {
    final response = await http.post(
      'api/app/charge/card/consume',
      data: {'password': password},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<List<WalletWithdrawAddress>>>
  withdrawWalletList() async {
    final response = await http.get('api/app/withdraw/wallet/list');
    return BaseHttpResponse.fromJson(response.data as Map<String, dynamic>, (
      json,
    ) {
      if (json is List) {
        return json
            .whereType<Map<String, dynamic>>()
            .map(WalletWithdrawAddress.fromJson)
            .toList();
      }
      return <WalletWithdrawAddress>[];
    });
  }

  Future<BaseHttpResponse<dynamic>> withdrawWalletAdd({
    required String name,
    required String account,
  }) async {
    final response = await http.post(
      'api/app/withdraw/wallet/add',
      data: {'name': name, 'account': account},
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<dynamic>> withdrawWalletRemove({
    required String id,
  }) async {
    final response = await http.request(
      'api/app/withdraw/wallet/$id',
      method: 'DELETE',
    );
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );
  }

  Future<BaseHttpResponse<WalletShopEnableStatus>> shopEnableStatus() async {
    final response = await http.get('api/shop/setting/enable/get.do');
    return BaseHttpResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => WalletShopEnableStatus.fromJson(json as Map<String, dynamic>),
    );
  }
}

bool _asBool(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1';
}
