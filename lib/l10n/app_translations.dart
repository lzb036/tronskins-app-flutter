import 'package:get/get.dart';
import 'package:tronskins_app/l10n/locale/en_US/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/fr_FR/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/ge_DE/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/in_ID/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/it_IT/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/ja_JP/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/ko_KR/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/la_LAT/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/po_PL/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/po_PT/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/ru_RU/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/sp_ES/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/th_TH/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/tu_TR/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/vi_VN/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/zh_CN/app_i18n.dart';
import 'package:tronskins_app/l10n/locale/zh_TW/app_i18n.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': en_US,
    'fr_FR': fr_FR,
    'ge_DE': ge_DE,
    'de_DE': ge_DE,
    'in_ID': in_ID,
    'id_ID': in_ID,
    'it_IT': it_IT,
    'ja_JP': ja_JP,
    'ko_KR': ko_KR,
    'la_LAT': la_LAT,
    'po_PL': po_PL,
    'pl_PL': po_PL,
    'po_PT': po_PT,
    'pt_PT': po_PT,
    'ru_RU': ru_RU,
    'sp_ES': sp_ES,
    'es_ES': sp_ES,
    'th_TH': th_TH,
    'tu_TR': tu_TR,
    'tr_TR': tu_TR,
    'vi_VN': vi_VN,
    'zh_CN': zh_CN,
    'zh_TW': zh_TW,
  };
}
