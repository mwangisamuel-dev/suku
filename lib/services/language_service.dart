import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static final ValueNotifier<String> language = ValueNotifier('English');
  static const _storageKey = 'app_language';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    language.value = prefs.getString(_storageKey) ?? 'English';
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, value);
    language.value = value;
  }

  static String get current => language.value;
  static bool get isEnglish => current == 'English';

  static String text(String key) {
    return _translations[current]?[key] ?? key;
  }

  static String planName(String planKey) {
    return _planNames[current]?[planKey] ?? planKey;
  }

  static String planPrice(String planKey) {
    return _planPrices[current]?[planKey] ?? '';
  }

  static String planSelectedMessage(String planKey) {
    final planName = LanguageService.planName(planKey);
    return text('planSelected').replaceFirst('{plan}', planName);
  }

  static String switchLanguageMessage(String languageKey) {
    if (languageKey == 'English') {
      return text('switchToEnglish');
    }
    return text('switchToKiswahili');
  }

  static const Map<String, Map<String, String>> _translations = {
    'English': {
      'accountTitle': 'Account',
      'subscriptionTitle': 'Subscription Plan',
      'subscriptionDescription': 'Manage your subscription and choose the best plan for your business.',
      'freePlan': 'Free',
      'proPlan': 'Pro',
      'businessPlan': 'Business',
      'freePlanSubtitle': 'Basic bookkeeping and business tracking',
      'proPlanSubtitle': 'Advanced reports, PDF exports, and premium support',
      'businessPlanSubtitle': 'Full business management tools for growing enterprises',
      'planPerMonth': 'per month',
      'currentPlan': 'Current plan',
      'businessInfoTitle': 'Business Info',
      'personalInfoTitle': 'Personal Info',
      'accountType': 'Account Type',
      'businessAccount': 'Business Account',
      'personalAccount': 'Personal Account',
      'updateProfileDescriptionBusiness': 'Update your business name, location and category for reports and receipts.',
      'updateProfileDescriptionPersonal':
          'Update your personal profile, location and occupation for receipts and tracking.',
      'businessName': 'Business Name',
      'fullName': 'Full Name',
      'location': 'Location',
      'occupation': 'Occupation',
      'saveBusinessInfo': 'Save business info',
      'savePersonalInfo': 'Save personal info',
      'languageTitle': 'Language / Lugha',
      'languageDescription': 'Pick your preferred app language. This is stored locally for your device.',
      'switchToEnglish': 'Switched to English',
      'switchToKiswahili': 'Switched to Kiswahili',
      'planSelected': 'You chose {plan}',
      'settingsSubscription': 'Subscription Plan',
      'settingsMpesa': 'M-Pesa Settings',
      'settingsBusinessInfo': 'Business Info',
      'settingsNotifications': 'Notifications',
      'settingsLanguage': 'Language / Lugha',
      'settingsHelpSupport': 'Help & Support',
      'settingsSignOut': 'Sign Out',
      'businessBadgeBusiness': 'Business',
      'businessBadgePersonal': 'Personal',
      'businessAccountSection': 'Business account fields',
      'personalAccountSection': 'Personal account fields',
      'helpSupportTitle': 'Help & Support',
    },
    'Kiswahili': {
      'accountTitle': 'Akaunti',
      'subscriptionTitle': 'Mpango wa Usajili',
      'subscriptionDescription': 'Dhibiti usajili wako na uchague mpango unaofaa kwa biashara yako.',
      'freePlan': 'Bure',
      'proPlan': 'Pro',
      'businessPlan': 'Biashara',
      'freePlanSubtitle': 'Uhasibu wa msingi na ufuatiliaji wa biashara',
      'proPlanSubtitle': 'Ripoti za juu, PDF, na msaada wa kitaalamu',
      'businessPlanSubtitle': 'Zana kamili za usimamizi wa biashara kwa biashara zinazokua',
      'planPerMonth': 'kwa mwezi',
      'currentPlan': 'Mpango wa sasa',
      'businessInfoTitle': 'Taarifa za Biashara',
      'personalInfoTitle': 'Taarifa za Binafsi',
      'accountType': 'Aina ya Akaunti',
      'businessAccount': 'Akaunti ya Biashara',
      'personalAccount': 'Akaunti ya Binafsi',
      'updateProfileDescriptionBusiness': 'Sasisha jina la biashara, eneo, na aina kwa ripoti na risiti.',
      'updateProfileDescriptionPersonal': 'Sasisha taarifa zako binafsi, eneo, na kazi kwa risiti na ufuatiliaji.',
      'businessName': 'Jina la Biashara',
      'fullName': 'Jina Kamili',
      'location': 'Mahali',
      'occupation': 'Kazi',
      'saveBusinessInfo': 'Hifadhi taarifa za biashara',
      'savePersonalInfo': 'Hifadhi taarifa binafsi',
      'languageTitle': 'Lugha / Language',
      'languageDescription': 'Chagua lugha unaopendelea kwa programu. Hifadhiwa kwa kifaa chako.',
      'switchToEnglish': 'Umebadilisha kuwa Kiingereza',
      'switchToKiswahili': 'Umebadilisha kuwa Kiswahili',
      'planSelected': 'Umechagua {plan}',
      'settingsSubscription': 'Mpango wa Usajili',
      'settingsMpesa': 'Mipangilio ya M-Pesa',
      'settingsBusinessInfo': 'Taarifa za Biashara',
      'settingsNotifications': 'Arifa',
      'settingsLanguage': 'Lugha / Language',
      'settingsHelpSupport': 'Msaada & Usaidizi',
      'settingsSignOut': 'Toka',
      'businessBadgeBusiness': 'Biashara',
      'businessBadgePersonal': 'Binafsi',
      'businessAccountSection': 'Mashamba ya akaunti ya biashara',
      'personalAccountSection': 'Mashamba ya akaunti ya binafsi',
      'helpSupportTitle': 'Msaada & Usaidizi',
    },
  };

  static const Map<String, Map<String, String>> _planNames = {
    'English': {
      'Free': 'Free',
      'Pro': 'Pro',
      'Business': 'Business',
    },
    'Kiswahili': {
      'Free': 'Bure',
      'Pro': 'Pro',
      'Business': 'Biashara',
    },
  };

  static const Map<String, Map<String, String>> _planPrices = {
    'English': {
      'Free': '0 Ksh / month',
      'Pro': '499 Ksh / month',
      'Business': '999 Ksh / month',
    },
    'Kiswahili': {
      'Free': '0 Ksh / mwezi',
      'Pro': '499 Ksh / mwezi',
      'Business': '999 Ksh / mwezi',
    },
  };
}
