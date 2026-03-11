import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isLoading = true;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  bool get isArabic => _locale.languageCode == 'ar';

  LanguageProvider() {
    _loadLanguage();
  }

  void toggleLanguage() {
    final newLanguage = _locale.languageCode == 'ar'
        ? 'en'
        : (_locale.languageCode == 'en' ? 'fr' : 'en');
    setLanguage(newLanguage);
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'welcome': 'Welcome to Darna',
      'welcome_subtitle':
          'Discover the perfect property in Morocco.\nYour journey to a new home starts here.',
      'get_started': 'Get Started',
      'signin': 'Sign In',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'or': 'OR',
      'dont_have_account': "Don't have an account? ",
      'already_have_account': 'Already have an account? ',
      'full_name': 'Full Name',
      'phone': 'Phone Number',
      'create_account': 'Create your account to continue',
      'account_created': 'Account Created!',
      'welcome_darna': 'Welcome to the Darna family!',
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'settings': 'Settings',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'logout': 'Logout',
      'coming_soon': 'Coming Soon!',
      'update': 'Update Profile',
      'success': 'Success',
      'profile_updated': 'Profile updated successfully!',
      'social_accounts': 'Social Accounts',
      'link': 'Link',
      'unlink': 'Unlink',
      'listings_count': 'Listings',
      'sold_count': 'Sold',
      'reviews_count': 'Reviews',
      'transactions_count': 'Transactions',
      'no_sold_properties': 'No Sold Properties',
      'no_sold_subtitle': 'Your sold properties will appear here',
      'hello': 'Hello 👋',
      'categories': 'Categories',
      'featured_properties': 'Featured Properties',
      'best_deals': 'Best deals for you',
      'top_locations': 'Top Locations',
      'explore_popular': 'Explore popular areas',
      'best_for_rent': 'Best For Rent',
      'monthly_rental': 'Monthly rental options',
      'search_properties': 'Search properties...',
      'see_all': 'See All',
      'explore': 'Explore',
      'properties': 'Properties',
      'agents': 'Agents',
      'listings_suffix': 'listings',
      // Navigation
      'nav_home': 'Home',
      'nav_search': 'Search',
      'nav_favorites': 'Favorites',
      'nav_profile': 'Profile',
      // Property Details & Missing items
      'bedrooms': 'Bedrooms',
      'bathroom': 'Bathroom',
      'location_facilities': 'Location & Public Facilities',
      'cost_of_living': 'Cost of Living',
      'see_details': 'See details',
      'reviews': 'Reviews',
      'view_all_reviews': 'View all reviews',
      'nearby_location': 'Nearby From this Location',
      'mad': 'MAD',
      'month': 'month',
      'drive': 'drive',
      'map_view': 'Map View Placeholder',
      'contact_agent': 'Contact Agent (Coming Soon)',
      'ar_view': 'AR View (Coming Soon)',
      'my_favorites': 'My Favorites',
      'favorites': 'Favorites',
      'favorite': 'Favorite',
      'clear_all': 'Clear All',
      'empty_favorites_title': 'Your favorite page is empty',
      'empty_favorites_subtitle':
          'Click add button above to start exploring and choose your favorite estates.',
      'explore_estates': 'Explore Estates',
      'browse_as_guest': 'Browse as Guest',
    },
    'fr': {
      'welcome': 'Bienvenue chez Darna',
      'welcome_subtitle':
          'Découvrez la propriété parfaite au Maroc.\nVotre voyage vers une nouvelle maison commence ici.',
      'get_started': 'Commencer',
      'signin': 'Se connecter',
      'signup': "S'inscrire",
      'email': 'E-mail',
      'password': 'Mot de passe',
      'forgot_password': 'Mot de passe oublié ?',
      'or': 'OU',
      'dont_have_account': "Vous n'avez pas de compte ? ",
      'already_have_account': 'Vous avez déjà un compte ? ',
      'full_name': 'Nom complet',
      'phone': 'Numéro de téléphone',
      'create_account': 'Créez votre compte pour continuer',
      'account_created': 'Compte créé !',
      'welcome_darna': 'Bienvenue dans la famille Darna !',
      'profile': 'Profil',
      'edit_profile': 'Modifier le profil',
      'settings': 'Paramètres',
      'language': 'Langue',
      'dark_mode': 'Mode sombre',
      'light_mode': 'Mode clair',
      'logout': 'Déconnexion',
      'coming_soon': 'Bientôt disponible !',
      'update': 'Mettre à jour',
      'success': 'Succès',
      'profile_updated': 'Profil mis à jour avec succès !',
      'social_accounts': 'Comptes sociaux',
      'link': 'Lier',
      'unlink': 'Délier',
      'listings_count': 'Annonces',
      'sold_count': 'Vendu',
      'reviews_count': 'Avis',
      'transactions_count': 'Transactions',
      'no_sold_properties': 'Aucune propriété vendue',
      'no_sold_subtitle': 'Vos propriétés vendues apparaîtront ici',
      'hello': 'Bonjour 👋',
      'categories': 'Catégories',
      'featured_properties': 'Propriétés vedettes',
      'best_deals': 'Meilleures offres pour vous',
      'top_locations': 'Emplacements populaires',
      'explore_popular': 'Explorer les zones populaires',
      'best_for_rent': 'Meilleur à louer',
      'monthly_rental': 'Options de location mensuelle',
      'search_properties': 'Rechercher des propriétés...',
      'see_all': 'Tout voir',
      'explore': 'Explorer',
      'properties': 'Propriétés',
      'agents': 'Agents',
      'listings_suffix': 'annonces',
      // Navigation
      'nav_home': 'Accueil',
      'nav_search': 'Recherche',
      'nav_favorites': 'Favoris',
      'nav_profile': 'Profil',
      // Property Details & Missing items
      'bedrooms': 'Chambres',
      'bathroom': 'Salle de bain',
      'location_facilities': 'Emplacement et installations publiques',
      'cost_of_living': 'Coût de la vie',
      'see_details': 'Voir les détails',
      'reviews': 'Avis',
      'view_all_reviews': 'Voir tous les avis',
      'nearby_location': 'À proximité de cet emplacement',
      'mad': 'MAD',
      'month': 'mois',
      'drive': 'trajet',
      'map_view': 'Espace pour la carte',
      'contact_agent': 'Contacter l\'agent (Bientôt disponible)',
      'ar_view': 'Vue AR (Bientôt disponible)',
      'my_favorites': 'Mes Favoris',
      'favorites': 'Favoris',
      'favorite': 'Favori',
      'clear_all': 'Tout effacer',
      'empty_favorites_title': 'Votre page de favoris est vide',
      'empty_favorites_subtitle':
          'Cliquez sur le bouton ajouter ci-dessus pour commencer à explorer et choisir vos propriétés préférées.',
      'explore_estates': 'Explorer les propriétés',
      'browse_as_guest': 'Parcourir en tant qu\'invité',
    },
    'ar': {
      'welcome': 'مرحباً بكم في دارنا',
      'welcome_subtitle':
          'اكتشف العقار المثالي في المغرب.\nرحلتك إلى بيت جديد تبدأ من هنا.',
      'get_started': 'ابدأ الآن',
      'signin': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgot_password': 'هل نسيت كلمة المرور؟',
      'or': 'أو',
      'dont_have_account': 'ليس لديك حساب؟ ',
      'already_have_account': 'لديك حساب بالفعل؟ ',
      'full_name': 'الاسم الكامل',
      'phone': 'رقم الهاتف',
      'create_account': 'أنشئ حسابك للمتابعة',
      'account_created': 'تم إنشاء الحساب!',
      'welcome_darna': 'مرحباً بك في عائلة دارنا!',
      'profile': 'الملف الشخصي',
      'edit_profile': 'تعديل الملف الشخصي',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'dark_mode': 'الوضع الليلي',
      'light_mode': 'الوضع النهاري',
      'logout': 'تسجيل الخروج',
      'coming_soon': 'قريباً!',
      'update': 'تحديث الملف',
      'success': 'نجاح',
      'profile_updated': 'تم تحديث الملف الشخصي بنجاح!',
      'social_accounts': 'الحسابات الاجتماعية',
      'link': 'ربط',
      'unlink': 'إلغاء الربط',
      'listings_count': 'العقارات',
      'sold_count': 'المباعة',
      'reviews_count': 'التقييمات',
      'transactions_count': 'المعاملات',
      'no_sold_properties': 'لا توجد عقارات مباعة',
      'no_sold_subtitle': 'عقاراتك المباعة ستظهر هنا',
      'hello': 'مرحباً 👋',
      'categories': 'الفئات',
      'featured_properties': 'عقارات مميزة',
      'best_deals': 'أفضل العروض لك',
      'top_locations': 'أفضل المواقع',
      'explore_popular': 'استكشف المناطق الشهيرة',
      'best_for_rent': 'الأفضل للإيجار',
      'monthly_rental': 'خيارات الإيجار الشهري',
      'search_properties': 'البحث عن عقارات...',
      'see_all': 'عرض الكل',
      'explore': 'استكشاف',
      'properties': 'عقارات',
      'agents': 'وكلاء',
      'listings_suffix': 'عقار',
      // Navigation
      'nav_home': 'الرئيسية',
      'nav_search': 'بحث',
      'nav_favorites': 'المفضلة',
      'nav_profile': 'حسابي',
      // Property Details & Missing items
      'bedrooms': 'غرف نوم',
      'bathroom': 'حمام',
      'location_facilities': 'الموقع والمرافق العامة',
      'cost_of_living': 'تكلفة المعيشة',
      'see_details': 'عرض التفاصيل',
      'reviews': 'التقييمات',
      'view_all_reviews': 'عرض كل التقييمات',
      'nearby_location': 'بالقرب من هذا الموقع',
      'mad': 'درهم',
      'month': 'شهر',
      'drive': 'قيادة',
      'map_view': 'خريطة',
      'contact_agent': 'اتصل بالوكيل (قريباً)',
      'ar_view': 'الواقع المعزز (قريباً)',
      'my_favorites': 'مفضلاتي',
      'favorites': 'المفضلة',
      'favorite': 'المفضلة',
      'clear_all': 'مسح الكل',
      'empty_favorites_title': 'صفحة المفضلة لديك فارغة',
      'empty_favorites_subtitle':
          'انقر فوق زر الإضافة أعلاه لبدء الاستكشاف واختيار عقاراتك المفضلة.',
      'explore_estates': 'استكشاف العقارات',
      'browse_as_guest': 'تصفح كزائر',
    },
  };

  void setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(languageCode);
    _isLoading = false;
    notifyListeners();
  }

  String translate(String key) {
    return _translations[_locale.languageCode]?[key] ?? key;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key) => Provider.of<LanguageProvider>(this).translate(key);
}
