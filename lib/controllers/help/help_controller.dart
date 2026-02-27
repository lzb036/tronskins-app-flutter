import 'package:get/get.dart';
import 'package:tronskins_app/api/help.dart';
import 'package:tronskins_app/api/model/help/help_models.dart';

class HelpController extends GetxController {
  HelpController({ApiHelpServer? api}) : _api = api ?? ApiHelpServer();

  final ApiHelpServer _api;

  final RxList<HelpCategory> categories = <HelpCategory>[].obs;
  final RxList<HelpItem> helpItems = <HelpItem>[].obs;

  final RxBool categoryLoading = false.obs;
  final RxBool listLoading = false.obs;

  Future<void> loadCategories() async {
    if (categoryLoading.value) return;
    categoryLoading.value = true;
    try {
      final res = await _api.categoryList();
      if (res.success && res.datas != null) {
        categories.assignAll(res.datas!);
      }
    } finally {
      categoryLoading.value = false;
    }
  }

  Future<void> loadHelpList(String categoryCode) async {
    if (listLoading.value) return;
    listLoading.value = true;
    try {
      final res = await _api.helpList(categoryCode: categoryCode);
      if (res.success && res.datas != null) {
        helpItems.assignAll(res.datas!);
      } else {
        helpItems.clear();
      }
    } finally {
      listLoading.value = false;
    }
  }
}
