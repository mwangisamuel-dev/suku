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
      'businessType': 'Business Type',
      'saveBusinessInfo': 'Save business info',
      'savePersonalInfo': 'Save personal info',
      'businessProfileSaved': 'Business profile saved',
      'personalProfileSaved': 'Personal profile saved',
      'languageTitle': 'Language / Lugha',
      'languageDescription': 'Pick your preferred app language. This is stored locally for your device.',
      'switchToEnglish': 'Switched to English',
      'switchToKiswahili': 'Switched to Kiswahili',
      'planSelected': 'You chose {plan}',
      'subscriptionSavedNotice': 'Switching plans is saved locally and will be reflected across your app settings.',
      'homeLabel': 'Home',
      'transactionsLabel': 'Transactions',
      'reportsLabel': 'Reports',
      'profileLabel': 'Profile',
      'addAction': 'Add',
      'scanAction': 'Scan',
      'mpesaAction': 'M-Pesa',
      'reportAction': 'Report',
      'greetingMorning': 'Good morning',
      'greetingAfternoon': 'Good afternoon',
      'greetingEvening': 'Good evening',
      'recentTransactionsTitle': 'Recent transactions',
      'monthlySpending': 'Monthly spending',
      'businessInsightsTitle': 'Business insights',
      'businessInsightsTopCategory': 'Top expense',
      'businessInsightsDailyAverage': 'Daily average spend',
      'businessInsightsReceipts': 'Receipts ready',
      'topExpenseNone': 'No expenses yet',
      'seeAll': 'See all',
      'viewAll': 'View all',
      'noTransactionsTitle': 'No transactions yet',
      'noTransactionsSubtitle': 'Tap + to add your first transaction',
      'helpSupportInfo': 'Need help? Reach out to Suku support or view quick troubleshooting tips.',
      'supportEmail': 'support@sukuapp.co.ke',
      'phoneSupport': '+254 700 000 000',
      'emailLabel': 'Support email',
      'phoneLabel': 'Phone support',
      'copySuccess': 'Copied to clipboard',
      'helpTipsLabel': 'Quick tips',
      'helpTips':
          'Update your business profile, enable M-Pesa import, and keep your notifications on for the smoothest experience.',
      'helpSupportFooter': 'You can also email us anytime with your feedback or questions.',
      'helpSupportTitle': 'Help & Support',
      'subscriptionPaymentTitle': 'Complete payment',
      'choosePaymentMethod': 'Choose payment method',
      'mpesaPaymentOption': 'M-Pesa',
      'airtelPaymentOption': 'Airtel Money',
      'mtnPaymentOption': 'MTN Mobile Money',
      'cardPaymentOption': 'Card payment',
      'enterPhoneNumber': 'Enter phone number',
      'phoneNumberHint': '+254 7XXXXXXXX',
      'cardNumber': 'Card number',
      'cardNumberHint': '1234 5678 9012 3456',
      'cardExpiry': 'Expiry',
      'cardExpiryHint': 'MM/YY',
      'cardCvc': 'CVC',
      'cardCvcHint': '123',
      'cardName': 'Cardholder name',
      'cardNameHint': 'Name on card',
      'continueButton': 'Continue',
      'confirmButton': 'Confirm payment',
      'mobileMoneyPaymentTitle': 'Mobile money payment request',
      'paymentRequestInstruction':
          'A payment request will be sent to {phone} using {provider}. When your network prompt appears, enter your PIN on your phone.',
      'enterMobileMoneyPinOnPhone': 'Enter your mobile money PIN on your phone to complete the request.',
      'cardPaymentSummaryTitle': 'Card payment summary',
      'payButton': 'Pay',
      'paymentSuccess': 'Payment confirmed',
      'paymentCancelled': 'Payment cancelled',
      'invoiceGenerateSuccess': 'Invoice generated',
      'invoiceShareError': 'Could not share invoice',
      'shareInvoice': 'Share invoice',
      'downloadInvoice': 'Download invoice',
      'receiptPreview': 'Receipt preview',
      'receiptNotAttached': 'No receipt image attached',
      'okButton': 'OK',
      'settingsSubscription': 'Subscription Plan',
      'settingsMpesa': 'M-Pesa Settings',
      'settingsBusinessInfo': 'Business Info',
      'settingsNotifications': 'Notifications',
      'settingsLanguage': 'Language / Lugha',
      'settingsHelpSupport': 'Help & Support',
      'settingsSignOut': 'Sign Out',
      'signOutPrompt': 'Sign out?',
      'signOutWarning': 'You will need to verify your phone number again.',
      'cancelButton': 'Cancel',
      'businessBadgeBusiness': 'Business',
      'businessBadgePersonal': 'Personal',
      'businessAccountSection': 'Business account fields',
      'personalAccountSection': 'Personal account fields',
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
      'businessType': 'Aina ya Biashara',
      'saveBusinessInfo': 'Hifadhi taarifa za biashara',
      'savePersonalInfo': 'Hifadhi taarifa binafsi',
      'businessProfileSaved': 'Taarifa za biashara zimehifadhiwa',
      'personalProfileSaved': 'Taarifa binafsi zimehifadhiwa',
      'languageTitle': 'Lugha / Language',
      'languageDescription': 'Chagua lugha unaopendelea kwa programu. Hifadhiwa kwa kifaa chako.',
      'switchToEnglish': 'Umebadilisha kuwa Kiingereza',
      'switchToKiswahili': 'Umebadilisha kuwa Kiswahili',
      'planSelected': 'Umechagua {plan}',
      'subscriptionSavedNotice': 'Mabadiliko ya mipango yamehifadhiwa kisheria na yataonekana kwenye mipangilio yako.',
      'homeLabel': 'Nyumbani',
      'transactionsLabel': 'Miamala',
      'reportsLabel': 'Ripoti',
      'profileLabel': 'Profaili',
      'addAction': 'Ongeza',
      'scanAction': 'Chapa',
      'mpesaAction': 'M-Pesa',
      'reportAction': 'Ripoti',
      'greetingMorning': 'Habari za asubuhi',
      'greetingAfternoon': 'Habari za mchana',
      'greetingEvening': 'Habari za jioni',
      'recentTransactionsTitle': 'Miamala ya hivi karibuni',
      'monthlySpending': 'Matumizi ya mwezi',
      'businessInsightsTitle': 'Maelezo ya Biashara',
      'businessInsightsTopCategory': 'Matumizi makubwa',
      'businessInsightsDailyAverage': 'Wastani wa kila siku',
      'businessInsightsReceipts': 'Risiti tayari',
      'topExpenseNone': 'Hakuna matumizi bado',
      'seeAll': 'Tazama zote',
      'viewAll': 'Angalia zote',
      'noTransactionsTitle': 'Hakuna miamala bado',
      'noTransactionsSubtitle': 'Gusa + kuongeza muamala wako wa kwanza',
      'helpSupportInfo': 'Unahitaji msaada? Wasiliana na msaada wa Suku au angalia vidokezo vya haraka.',
      'supportEmail': 'support@sukuapp.co.ke',
      'phoneSupport': '+254 700 000 000',
      'emailLabel': 'Barua pepe ya msaada',
      'phoneLabel': 'Msaada wa simu',
      'copySuccess': 'Imebandikwa kwa clipboard',
      'helpTipsLabel': 'Vidokezo vya haraka',
      'helpTips':
          'Sasisha profaili yako ya biashara, wezesha uingiza M-Pesa, na weka arifa ili kupata uzoefu mzuri zaidi.',
      'helpSupportFooter': 'Unaweza pia kututumia barua pepe wakati wowote kwa maoni au maswali.',
      'helpSupportTitle': 'Msaada & Usaidizi',
      'subscriptionPaymentTitle': 'Maliza malipo',
      'choosePaymentMethod': 'Chagua njia ya malipo',
      'mpesaPaymentOption': 'M-Pesa',
      'airtelPaymentOption': 'Airtel Money',
      'mtnPaymentOption': 'MTN Mobile Money',
      'cardPaymentOption': 'Malipo ya kadi',
      'enterPhoneNumber': 'Weka nambari ya simu',
      'phoneNumberHint': '+254 7XXXXXXXX',
      'cardNumber': 'Namba ya kadi',
      'cardNumberHint': '1234 5678 9012 3456',
      'cardExpiry': 'Mwisho',
      'cardExpiryHint': 'MM/YY',
      'cardCvc': 'CVC',
      'cardCvcHint': '123',
      'cardName': 'Jina kwenye kadi',
      'cardNameHint': 'Jina kamili',
      'continueButton': 'Endelea',
      'confirmButton': 'Thibitisha malipo',
      'mobileMoneyPaymentTitle': 'Ombi la malipo ya simu',
      'paymentRequestInstruction':
          'Ombi la malipo litatumwa kwa {phone} kwa kutumia {provider}. Unapotokea ombi kutoka kwa mtandao wako, ingiza PIN yako kwenye simu yako.',
      'enterMobileMoneyPinOnPhone': 'Weka PIN yako ya malipo ya simu kwenye simu yako kukamilisha ombi.',
      'cardPaymentSummaryTitle': 'Muhtasari wa malipo kwa kadi',
      'payButton': 'Lipa',
      'paymentSuccess': 'Malipo yamethibitishwa',
      'paymentCancelled': 'Malipo yametagwa',
      'invoiceGenerateSuccess': 'Ankara imeundwa',
      'invoiceShareError': 'Haikuweza kushiriki ankara',
      'shareInvoice': 'Shiriki ankara',
      'downloadInvoice': 'Pakua ankara',
      'receiptPreview': 'Onyesho la risiti',
      'receiptNotAttached': 'Hakuna picha ya risiti',
      'okButton': 'Sawa',
      'settingsSubscription': 'Mpango wa Usajili',
      'settingsMpesa': 'Mipangilio ya M-Pesa',
      'settingsBusinessInfo': 'Taarifa za Biashara',
      'settingsNotifications': 'Arifa',
      'settingsLanguage': 'Lugha / Language',
      'settingsHelpSupport': 'Msaada & Usaidizi',
      'settingsSignOut': 'Toka',
      'signOutPrompt': 'Toka?',
      'signOutWarning': 'Utahitaji kuthibitisha tena nambari yako ya simu.',
      'cancelButton': 'Ghairi',
      'businessBadgeBusiness': 'Biashara',
      'businessBadgePersonal': 'Binafsi',
      'businessAccountSection': 'Mashamba ya akaunti ya biashara',
      'personalAccountSection': 'Mashamba ya akaunti ya binafsi',
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
