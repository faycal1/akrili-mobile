import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('ar'),
    Locale('en'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('fr'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get languageCode => locale.languageCode;
  bool get isArabic => languageCode == 'ar';

  String _t(String fr, {String? ar, String? en}) {
    if (languageCode == 'ar') return ar ?? fr;
    if (languageCode == 'en') return en ?? fr;
    return fr; // French is the absolute default
  }

  // --- Brand & App ---
  String get appName => 'Akrili';
  String get appTagline => _t(
        'Locations de courte durée en Algérie',
        ar: 'كراء قصير المدى في الجزائر',
        en: 'Short-term rentals across Algeria',
      );

  // --- Navigation ---
  String get navExplore => _t('Explorer', ar: 'استكشاف', en: 'Explore');
  String get navBookings => _t('Réservations', ar: 'حجوزاتي', en: 'Bookings');
  String get navFavorites => _t('Favoris', ar: 'المفضلة', en: 'Favorites');
  String get navInbox => _t('Messages', ar: 'الرسائل', en: 'Inbox');
  String get navProfile => _t('Profil', ar: 'حسابي', en: 'Profile');
  String get navListings => _t('Mes Annonces', ar: 'عقاراتي', en: 'Listings');
  String get navReservations => _t('Réservations', ar: 'الحجوزات', en: 'Reservations');

  // --- Common Actions ---
  String get cancel => _t('Annuler', ar: 'إلغاء', en: 'Cancel');
  String get save => _t('Enregistrer', ar: 'حفظ', en: 'Save');
  String get apply => _t('Appliquer', ar: 'تطبيق', en: 'Apply');
  String get clear => _t('Effacer', ar: 'مسح', en: 'Clear');
  String get close => _t('Fermer', ar: 'إغلاق', en: 'Close');
  String get retry => _t('Réessayer', ar: 'إعادة المحاولة', en: 'Retry');
  String get edit => _t('Modifier', ar: 'تعديل', en: 'Edit');
  String get editProperty => _t("Modifier l'annonce", ar: 'تعديل الإعلان', en: 'Edit listing');
  String get saveChanges => _t('Enregistrer les modifications', ar: 'حفظ التعديلات', en: 'Save changes');
  String get currentPhotos => _t('Photos actuelles', ar: 'الصور الحالية', en: 'Current photos');
  String get delete => _t('Supprimer', ar: 'حذف', en: 'Delete');
  String get deletePhotoConfirm => _t(
        'Supprimer cette photo ?',
        ar: 'هل تريد حذف هذه الصورة؟',
        en: 'Delete this photo?',
      );
  String get deleteListing => _t('Supprimer l\'annonce', ar: 'حذف الإعلان', en: 'Delete listing');
  String get onlyDraftEditable => _t(
        'Seules les annonces en brouillon ou refusées peuvent être modifiées.',
        ar: 'يمكن تعديل الإعلانات المسودة أو المرفوضة فقط.',
        en: 'Only draft or rejected listings can be edited.',
      );
  String get deleteListingConfirm => _t(
        'Supprimer définitivement cette annonce ?',
        ar: 'هل تريد حذف هذا الإعلان نهائيًا؟',
        en: 'Delete this listing permanently?',
      );
  String get listingDeleted => _t(
        'Annonce supprimée.',
        ar: 'تم حذف الإعلان.',
        en: 'Listing deleted.',
      );
  String get cannotDeleteListing => _t(
        'Impossible de supprimer une annonce avec des réservations.',
        ar: 'لا يمكن حذف إعلان به حجوزات.',
        en: 'Can\'t delete a listing that has bookings.',
      );
  String get search => _t('Rechercher', ar: 'بحث', en: 'Search');
  String get seeAll => _t('Voir tout', ar: 'عرض الكل', en: 'See All');
  String get viewDetails => _t('Voir les détails', ar: 'عرض التفاصيل', en: 'View Details');
  String get back => _t('Retour', ar: 'رجوع', en: 'Back');

  // --- Auth Screen ---
  String get welcomeToAkrili => _t('Bienvenue sur Akrili', ar: 'مرحباً بك في أكرلي', en: 'Welcome to Akrili');
  String get welcomeSubtitle => _t(
        'Locations de courte durée à travers toute l\'Algérie',
        ar: 'كراء قصير المدى عبر جميع ربوع الجزائر',
        en: 'Short-term rentals across Algeria',
      );
  String get joinAkrili => _t('Rejoindre Akrili', ar: 'الانضمام إلى أكرلي', en: 'Join Akrili');
  String get joinSubtitle => _t(
        'Découvrez et réservez des séjours vérifiés dans les 58 wilayas d\'Algérie',
        ar: 'اكتشف واحجز إقامات موثوقة في 58 ولاية',
        en: 'Discover and rent verified stays across all 58 wilayas of Algeria',
      );
  String get emailOrPhone => _t('Email ou Téléphone', ar: 'البريد أو الهاتف', en: 'Email or Phone');
  String get emailAddress => _t('Adresse e-mail', ar: 'البريد الإلكتروني', en: 'Email Address');
  String get password => _t('Mot de passe', ar: 'كلمة المرور', en: 'Password');
  String get confirmPassword => _t('Confirmer le mot de passe', ar: 'تأكيد كلمة المرور', en: 'Confirm Password');
  String get fullName => _t('Nom complet', ar: 'الاسم الكامل', en: 'Full Name');
  String get phoneOptional => _t('Numéro de téléphone (optionnel)', ar: 'رقم الهاتف (اختياري)', en: 'Phone Number (Optional)');
  String get logIn => _t('Se connecter', ar: 'تسجيل الدخول', en: 'Log In');
  String get createAccount => _t('Créer un compte', ar: 'إنشاء حساب', en: 'Create Account');
  String get signUp => _t('S\'inscrire', ar: 'تسجيل جديد', en: 'Sign Up');
  String get signIn => _t('Connexion', ar: 'دخول', en: 'Sign In');
  String get dontHaveAccount => _t('Vous n\'avez pas de compte ?', ar: 'ليس لديك حساب؟', en: 'Don\'t have an account?');
  String get alreadyHaveAccount => _t('Vous avez déjà un compte ?', ar: 'لديك حساب بالفعل؟', en: 'Already have an account?');
  String get continueAsGuest => _t('Continuer sans compte', ar: 'المتابعة كزائر', en: 'Continue browsing as Guest');
  String get quickLogin => _t('CONNEXION RAPIDE', ar: 'تسجيل سريع', en: 'QUICK LOGIN');
  String get roleRenter => _t('Locataire / Voyageur', ar: 'مستأجر / مسافر', en: 'Renter / Guest');
  String get roleHost => _t('Hôte / Propriétaire', ar: 'مضيف / مالك', en: 'Host / Owner');
  String get guestBadge => _t('Voyageur', ar: 'مسافر', en: 'Guest');
  String get hostBadge => _t('Hôte', ar: 'مضيف', en: 'Host');
  String get adminBadge => _t('Admin', ar: 'مسؤول', en: 'Admin');

  // --- Validation Messages ---
  String get enterEmailOrPhone => _t('Veuillez saisir votre email ou téléphone', ar: 'يرجى إدخال البريد أو الهاتف', en: 'Enter your email or phone');
  String get enterPassword => _t('Veuillez saisir votre mot de passe', ar: 'يرجى إدخال كلمة المرور', en: 'Enter your password');
  String get enterFullName => _t('Veuillez saisir votre nom complet', ar: 'يرجى إدخال الاسم الكامل', en: 'Enter your full name');
  String get enterValidEmail => _t('Veuillez saisir une adresse email valide', ar: 'يرجى إدخال بريد إلكتروني صحيح', en: 'Enter a valid email address');
  String get passwordMinLength => _t('Le mot de passe doit comporter au moins 6 caractères', ar: 'كلمة المرور يجب أن لا تقل عن 6 أحرف', en: 'Password must be at least 6 characters');
  String get passwordsDoNotMatch => _t('Les mots de passe ne correspondent pas', ar: 'كلمتا المرور غير متطابقتين', en: 'Passwords do not match');

  // --- Explore & Search Filters ---
  String get searchHint => _t('Rechercher ville, séjour, wilaya...', ar: 'ابحث عن مدينة، إقامة، ولاية...', en: 'Search city, stay name, or wilaya...');
  String get filtersTitle => _t('Filtres de recherche', ar: 'خيارات التصفية', en: 'Filters');
  String get activeFilters => _t('Filtres actifs', ar: 'الفلاتر النشطة', en: 'Active Filters');
  String get selectWilaya => _t('Sélectionner une wilaya', ar: 'اختر ولاية', en: 'Select Wilaya');
  String get allWilayas => _t('Toutes les wilayas (58)', ar: 'كل الولايات (58)', en: 'All Wilayas (58)');
  String get wilayaLabel => _t('Wilaya', ar: 'الولاية', en: 'Wilaya');
  String get communeLabel => _t('Commune', ar: 'البلدية', en: 'Commune');
  String get selectCommune => _t('Sélectionner une commune', ar: 'اختر بلدية', en: 'Select Commune');
  String get allCommunes => _t('Toutes les communes', ar: 'كل البلديات', en: 'All Communes');
  String get chooseWilayaFirst => _t('Veuillez d\'abord choisir une wilaya', ar: 'يرجى اختيار ولاية أولاً', en: 'Please select a wilaya first');
  String get propertyType => _t('Type de bien', ar: 'نوع العقار', en: 'Property Type');
  String get allTypes => _t('Tous les types', ar: 'كل الأنواع', en: 'All Types');
  String get typeApartment => _t('Appartement', ar: 'شقة', en: 'Apartment');
  String get typeVilla => _t('Villa', ar: 'فيلا', en: 'Villa');
  String get typeStudio => _t('Studio', ar: 'ستوديو', en: 'Studio');
  String get typeBungalow => _t('Bungalow', ar: 'بنغل', en: 'Bungalow');
  String get typeTraditional => _t('Maison traditionnelle', ar: 'منزل تقليدي', en: 'Traditional House');
  String get rentalMode => _t('Mode de location', ar: 'نوع الإيجار', en: 'Rental Mode');
  String get allRentalModes => _t('Tous les modes', ar: 'كل الأنواع', en: 'All Modes');
  String get modeSeasonal => _t('Saisonnier', ar: 'موسمي', en: 'Seasonal');
  String get modeYearly => _t('À l\'année', ar: 'سنوي', en: 'Yearly');
  String get modeBoth => _t('Les deux', ar: 'كلاهما', en: 'Both');
  String get modeMonthly => _t('Mensuel', ar: 'شهري', en: 'Monthly');
  String get modeDaily => _t('Journalier', ar: 'يومي', en: 'Daily');

  String rentalModeLabel(String mode) {
    switch (mode) {
      case 'seasonal':
        return modeSeasonal;
      case 'yearly':
        return modeYearly;
      case 'both':
        return modeBoth;
      default:
        return mode;
    }
  }
  String get pricePerNight => _t('Prix par nuit (DZD)', ar: 'السعر لليلة (د.ج)', en: 'Price per night (DZD)');
  String get minNightsLabel => _t('Nuits minimum', ar: 'الحد الأدنى لليالي', en: 'Min nights');
  String get minGuestsLabel => _t('Capacité minimale (voyageurs)', ar: 'الحد الأدنى للضيوف', en: 'Min guests capacity');
  String get instantBookingOnly => _t('Réservation instantanée uniquement', ar: 'حجز فوري فقط', en: 'Instant booking only');
  String get clearAll => _t('Tout effacer', ar: 'مسح الكل', en: 'Clear All');
  String get applyFilters => _t('Appliquer les filtres', ar: 'تطبيق الفلاتر', en: 'Apply Filters');
  String get noPropertiesFound => _t('Aucun séjour trouvé', ar: 'لم يتم العثور على أي إقامة', en: 'No properties found');
  String get adjustFiltersPrompt => _t('Essayez de modifier vos critères de recherche ou vos filtres.', ar: 'جرب تعديل خيارات البحث أو التصفية.', en: 'Try adjusting your search criteria or filters.');
  String get seenAllStays => _t('Vous avez vu tous les séjours disponibles', ar: 'لقد اطلعت على جميع الإقامات المتاحة', en: 'You\'ve seen all available stays');
  String get perNightLabel => _t('DZD / nuit', ar: 'د.ج / ليلة', en: 'DZD / night');
  String get guestsUnit => _t('voyageurs', ar: 'ضيوف', en: 'guests');
  String get bedroomsUnit => _t('chambres', ar: 'غرف', en: 'bedrooms');
  String get bathroomsUnit => _t('salles de bain', ar: 'حمامات', en: 'bathrooms');
  String get instantBookingBadge => _t('Instantané', ar: 'فوري', en: 'Instant');

  // --- Bookings ---
  String get myBookingsTitle => _t('Mes Réservations', ar: 'حجوزاتي', en: 'My Bookings');
  String get hostReservationsTitle => _t('Réservations Reçues', ar: 'الحجوزات المستلمة', en: 'Host Reservations');
  String get bookingDetailsTitle => _t('Détails de la réservation', ar: 'تفاصيل الحجز', en: 'Booking Details');
  String get referenceLabel => _t('RÉFÉRENCE', ar: 'المرجع', en: 'REFERENCE');
  String get bookedOnLabel => _t('RÉSERVÉ LE', ar: 'تاريخ الحجز', en: 'BOOKED ON');
  String get checkInLabel => _t('ARRIVÉE', ar: 'تسجيل الوصول', en: 'CHECK-IN');
  String get checkOutLabel => _t('DÉPART', ar: 'المغادرة', en: 'CHECK-OUT');
  String get reservationDetails => _t('Détails du séjour', ar: 'تفاصيل الإقامة', en: 'Reservation Details');
  String get durationLabel => _t('Durée', ar: 'المدة', en: 'Duration');
  String get nightsUnit => _t('nuits', ar: 'ليالي', en: 'nights');
  String get priceSummary => _t('Récapitulatif du prix', ar: 'ملخص السعر', en: 'Price Summary');
  String get totalLabel => _t('Total (DZD)', ar: 'المجموع (د.ج)', en: 'Total (DZD)');
  String get nightlyPriceRow => _t('Tarif par nuit', ar: 'سعر الليلة', en: 'Nightly Rate');
  String get cleaningFeeRow => _t('Frais de ménage', ar: 'رسوم التنظيف', en: 'Cleaning Fee');
  String get depositRow => _t('Caution', ar: 'مبلغ التأمين', en: 'Deposit');
  String get tenantField => _t('Locataire', ar: 'المستأجر', en: 'Tenant');
  String get hostField => _t('Hôte', ar: 'المضيف', en: 'Host');
  String get acceptBtn => _t('Accepter la réservation', ar: 'قبول الحجز', en: 'Accept Booking');
  String get rejectBtn => _t('Refuser', ar: 'رفض', en: 'Reject');
  String get leaveReviewBtn => _t('Laisser un avis', ar: 'كتابة تقييم', en: 'Leave a Review');
  String get viewListingBtn => _t('Voir l\'annonce', ar: 'عرض العقار', en: 'View Listing');
  String get signInToViewBookings => _t('Connectez-vous pour voir vos réservations', ar: 'سجل الدخول لعرض حجوزاتك', en: 'Sign in to view Bookings');
  String get bookingsSignInPrompt => _t(
        'Suivez vos demandes, validations et historique de séjours en un seul endroit.',
        ar: 'تابع طلباتك وتأكيداتك وسجل إقاماتك في مكان واحد.',
        en: 'Keep track of your stay reservations, confirmation status, and host reviews in one place.',
      );

  // --- Booking Statuses ---
  String get statusPending => _t('En attente', ar: 'قيد الانتظار', en: 'Pending');
  String get statusConfirmed => _t('Confirmée', ar: 'مؤكدة', en: 'Confirmed');
  String get statusCancelled => _t('Annulée', ar: 'ملغاة', en: 'Cancelled');
  String get statusRejected => _t('Refusée', ar: 'مرفوضة', en: 'Rejected');
  String get statusCompleted => _t('Terminée', ar: 'مكتملة', en: 'Completed');

  // --- Booking Creation & Messaging ---
  String get confirmAndBook => _t('Confirmer et réserver', ar: 'تأكيد الحجز', en: 'Confirm & Book');
  String get requestToBook => _t('Demander la réservation', ar: 'طلب الحجز', en: 'Request to Book');
  String get bookingCreatedSuccess => _t('Demande de réservation créée avec succès !', ar: 'تم إرسال طلب الحجز بنجاح!', en: 'Booking request created successfully!');
  String get datesTitle => _t('Dates', ar: 'التواريخ', en: 'Dates');
  String get guestsTitle => _t('Voyageurs', ar: 'الضيوف', en: 'Guests');
  String get priceBreakdown => _t('Détail du prix', ar: 'تفاصيل السعر', en: 'Price Breakdown');
  String get typeYourMessage => _t('Écrivez votre message...', ar: 'اكتب رسالتك...', en: 'Type your message...');
  String get noMessagesYet => _t('Aucun message pour le moment. Envoyez un message pour commencer !', ar: 'لا توجد رسائل بعد. أرسل رسالة لبدء المحادثة!', en: 'No messages yet. Send a message to start chatting!');
  String get sendMessageFailed => _t('Échec de l\'envoi du message', ar: 'فشل إرسال الرسالة', en: 'Failed to send message');

  // --- Favorites ---
  String get savedStaysTitle => _t('Séjours enregistrés', ar: 'الإقامات المحفوظة', en: 'Saved Stays');
  String get signInToViewFavorites => _t('Connectez-vous pour voir vos favoris', ar: 'سجل الدخول لعرض المفضلة', en: 'Sign in to view Saved Stays');
  String get favoritesSignInPrompt => _t(
        'Enregistrez vos coups de cœur pour planifier facilement vos prochains séjours.',
        ar: 'احفظ إقاماتك المفضلة لتخطيط رحلاتك القادمة بكل سهولة.',
        en: 'Save and organize your favorite stays to plan your upcoming visits and compare options.',
      );
  String get noFavoritesYet => _t('Aucun séjour enregistré', ar: 'لا توجد إقامات مفضلة بعد', en: 'No saved stays yet');

  // --- Notifications ---
  String get notificationsTitle => _t('Notifications', ar: 'الإشعارات', en: 'Notifications');
  String get markAllAsRead => _t('Tout marquer comme lu', ar: 'تحديد الكل كمقروء', en: 'Mark all as read');
  String get signInForNotifications => _t('Connectez-vous pour les notifications', ar: 'سجل الدخول لمتابعة الإشعارات', en: 'Sign in for Notifications');
  String get notificationsSignInPrompt => _t(
        'Recevez des alertes instantanées sur l\'état de vos réservations et vos messages.',
        ar: 'احصل على تنبيهات فورية عند قبول حجوزاتك أو وصول رسائل جديدة.',
        en: 'Receive instant alerts when hosts accept your booking requests or send you messages.',
      );
  String get noNotificationsYet => _t('Aucune notification pour le moment', ar: 'لا توجد إشعارات حتى الآن', en: 'No notifications yet');

  // --- Profile Screen ---
  String get profileAndSettings => _t('Profil & Paramètres', ar: 'الحساب والإعدادات', en: 'Profile & Settings');
  String get personalInfo => _t('Informations personnelles', ar: 'المعلومات الشخصية', en: 'Personal Information');
  String get nameField => _t('Nom', ar: 'الاسم', en: 'Name');
  String get phoneField => _t('Téléphone', ar: 'الهاتف', en: 'Phone');
  String get roleField => _t('Rôle', ar: 'الدور', en: 'Role');
  String get switchToHostMode => _t('Passer en mode Propriétaire', ar: 'التحويل إلى وضع المضيف', en: 'Switch to Host Mode');
  String get switchToGuestMode => _t('Passer en mode Voyageur', ar: 'التحويل إلى وضع المسافر', en: 'Switch to Guest Mode');
  String get languageSetting => _t('Langue de l\'application', ar: 'لغة التطبيق', en: 'App Language');
  String get selectLanguageTitle => _t('Choisir la langue', ar: 'اختيار اللغة', en: 'Choose Language');
  String get frenchOption => 'Français (Défaut)';
  String get arabicOption => 'العربية';
  String get englishOption => 'English';
  String get darkMode => _t('Mode Sombre', ar: 'الوضع الليلي', en: 'Dark Mode');
  String get themeModeSetting => _t('Thème d\'affichage', ar: 'مظهر التطبيق', en: 'Theme Mode');
  String get chooseThemeTitle => _t('Choisir le mode d\'affichage', ar: 'اختيار مظهر التطبيق', en: 'Choose Theme Mode');
  String get themeLight => _t('Mode Clair', ar: 'الوضع النهاري', en: 'Light Mode');
  String get themeDark => _t('Mode Sombre', ar: 'الوضع الليلي', en: 'Dark Mode');
  String get themeSystem => _t('Système (Automatique)', ar: 'حسب إعدادات النظام', en: 'System Default');
  String get apiBaseUrlSetting => _t('Paramètres de connexion API', ar: 'إعدادات خادم API', en: 'API Connection Settings');
  String get signOut => _t('Se déconnecter', ar: 'تسجيل الخروج', en: 'Sign Out');
  String get confirmSignOutTitle => _t('Voulez-vous vraiment vous déconnecter ?', ar: 'هل تريد تسجيل الخروج؟', en: 'Are you sure you want to sign out?');
  String get confirmSignOutMsg => _t(
        'Vous devrez vous reconnecter pour accéder à vos réservations et favoris.',
        ar: 'سيتوجب عليك تسجيل الدخول مرة أخرى للوصول إلى حجوزاتك ومفضلاتك.',
        en: 'You will need to sign back in to access your bookings and saved stays.',
      );

  // --- Reviews & Ratings (Airbnb style) ---
  String get reviewsTitle => _t('Évaluations & Avis', ar: 'التقييمات والآراء', en: 'Reviews & Ratings');
  String reviewsCountText(int count) => _t(
        '$count avis',
        ar: '$count تقييم',
        en: '$count reviews',
      );
  String get noReviewsYet => _t('Aucun avis pour le moment', ar: 'لا توجد تقييمات حتى الآن', en: 'No reviews yet');
  String get beFirstToReview => _t(
        'Soyez le premier voyageur à laisser une évaluation après votre séjour.',
        ar: 'كن أول مسافر يترك تقييماً بعد إقامتك.',
        en: 'Be the first guest to leave a review after your stay.',
      );
  String get guestFavoriteBadge => _t('Coup de cœur voyageurs', ar: 'مفضل لدى المسافرين', en: 'Guest favorite');
  String get guestFavoriteSubtitle => _t(
        'L\'un des logements les plus appréciés sur Akrili selon les voyageurs.',
        ar: 'أحد أكثر المساكن تفضيلاً على أكرلي وفقاً لآراء المسافرين.',
        en: 'One of the most loved homes on Akrili according to guests.',
      );
  String get overallRating => _t('Note globale', ar: 'التقييم العام', en: 'Overall rating');
  String get ratingBreakdown => _t('Répartition des notes', ar: 'تفاصيل التقييمات', en: 'Rating breakdown');
  String get eligibleStayBannerTitle => _t('Vous avez séjourné dans ce logement !', ar: 'لقد أقمت في هذا المسكن!', en: 'You stayed at this property!');
  String get eligibleStayBannerSubtitle => _t(
        'Partagez votre expérience avec la communauté Akrili.',
        ar: 'شارك تجربتك مع مجتمع أكرلي.',
        en: 'Share your experience with the Akrili community.',
      );
  String get writeReviewBtn => _t('Rédiger un avis', ar: 'كتابة تقييم', en: 'Write a Review');
  String get reviewModalTitle => _t('Évaluer votre séjour', ar: 'تقييم إقامتك', en: 'Rate Your Stay');
  String get reviewModalSubtitle => _t(
        'Votre évaluation aide les futurs voyageurs et permet à l\'hôte d\'améliorer son accueil.',
        ar: 'تقييمك يساعد المسافرين الآخرين ويشجع المضيف على تقديم الأفضل.',
        en: 'Your review helps future guests make great choices and helps hosts improve.',
      );
  String get ratingLabel5 => _t('Exceptionnel', ar: 'ممتاز', en: 'Exceptional');
  String get ratingLabel4 => _t('Très bien', ar: 'جيد جداً', en: 'Very Good');
  String get ratingLabel3 => _t('Moyen', ar: 'متوسط', en: 'Average');
  String get ratingLabel2 => _t('Décevant', ar: 'مخيّب', en: 'Disappointing');
  String get ratingLabel1 => _t('Mauvais', ar: 'سيء', en: 'Poor');
  String get commentPlaceholder => _t(
        'Parlez de la propreté, de l\'accueil de l\'hôte, de l\'emplacement...',
        ar: 'تحدث عن النظافة، حسن الاستقبال، راحة المكان، الموقع...',
        en: 'Mention cleanliness, host hospitality, accuracy, location...',
      );
  String get publishReviewBtn => _t('Publier mon avis', ar: 'نشر تقييمي', en: 'Publish Review');
  String get reviewMinChars => _t(
        'Veuillez écrire au moins 5 caractères pour votre avis.',
        ar: 'يرجى كتابة 5 أحرف على الأقل في التقييم.',
        en: 'Please write at least 5 characters for your review.',
      );
  String get hostReplyTitle => _t('Réponse de l\'hôte', ar: 'رد المضيف', en: 'Host response');
  String seeAllReviews(int count) => _t(
        'Afficher tous les $count avis',
        ar: 'عرض كل $count تقييم',
        en: 'Show all $count reviews',
      );

  // --- Feedback & Alerts ---
  String get bookingAcceptedSuccess => _t('Réservation acceptée avec succès.', ar: 'تم قبول الحجز بنجاح.', en: 'Booking accepted successfully.');
  String get bookingRejectedSuccess => _t('Réservation refusée.', ar: 'تم رفض الحجز.', en: 'Booking rejected.');
  String get reviewSubmittedSuccess => _t('Votre avis a été publié.', ar: 'تم نشر تقييمك بنجاح.', en: 'Review submitted successfully.');
  String get connectionTimeoutMsg => _t(
        'Délai de connexion dépassé. Vérifiez votre réseau ou le serveur.',
        ar: 'انتهت مهلة الاتصال. يرجى التحقق من الشبكة أو الخادم.',
        en: 'Connection timed out. Please check your network or server URL.',
      );
  String get cannotConnectMsg => _t(
        'Impossible de joindre le serveur. Vérifiez les paramètres de connexion.',
        ar: 'تعذر الاتصال بالخادم. يرجى مراجعة إعدادات الاتصال.',
        en: 'Cannot connect to server. Check server settings (gear icon top right).',
      );
  String get invalidCredentialsMsg => _t(
        'Ces identifiants ne correspondent pas à nos enregistrements.',
        ar: 'بيانات الاعتماد هذه غير مطابقة لسجلاتنا.',
        en: 'These credentials do not match our records.',
      );
  String get tooManyAttemptsMsg => _t(
        'Trop de tentatives de connexion. Veuillez patienter un instant.',
        ar: 'محاولات دخول كثيرة جداً. يرجى الانتظار قليلاً.',
        en: 'Too many login attempts. Please wait a minute and try again.',
      );
  String get serverErrorMsg => _t(
        'Erreur serveur. Veuillez réessayer ultérieurement.',
        ar: 'خطأ في الخادم. يرجى المحاولة لاحقاً.',
        en: 'Server error. Please try again later.',
      );
  String minNightsRequired(int n) => _t(
        'Le séjour minimum est de $n nuits.',
        ar: 'الحد الأدنى للإقامة هو $n ليالي.',
        en: 'Minimum stay is $n nights.',
      );
  String guestsExceedCapacity(int max) => _t(
        'La capacité maximale est de $max voyageurs.',
        ar: 'الطاقة الاستيعابية القصوى هي $max ضيوف.',
        en: 'Maximum capacity is $max guests.',
      );
  String get cannotBookOwnProperty => _t(
        'Vous êtes le propriétaire de ce bien. Vous ne pouvez pas le réserver.',
        ar: 'أنت مالك هذا العقار. لا يمكنك حجزه.',
        en: 'You are the owner of this property. You cannot book it.',
      );
  String get checkBookingInfoMsg => _t(
        'Veuillez vérifier les informations de réservation.',
        ar: 'يرجى مراجعة تفاصيل الحجز.',
        en: 'Please check your booking details.',
      );

  // --- Host Property Wizard ---
  String get listYourProperty => _t('Publier une annonce', ar: 'أضف عقارك', en: 'List your property');
  String get listYourPropertySubtitle => _t(
        'Créez une annonce pour louer votre bien et commencez à recevoir des réservations.',
        ar: 'أنشئ إعلاناً لكراء عقارك وابدأ باستقبال الحجوزات.',
        en: 'Create a listing for your stay and start receiving bookings.',
      );
  String get stepBasics => _t('Général', ar: 'الأساسيات', en: 'Basics');
  String get stepLocation => _t('Localisation', ar: 'الموقع', en: 'Location');
  String get stepDetails => _t('Détails', ar: 'التفاصيل', en: 'Details');
  String get stepPricing => _t('Tarifs', ar: 'الأسعار', en: 'Pricing');
  String get stepPhotos => _t('Photos', ar: 'الصور', en: 'Photos');
  String get stepReview => _t('Validation', ar: 'المراجعة', en: 'Review');
  String get nextStepBtn => _t('Étape suivante', ar: 'التالي', en: 'Next Step');
  String get prevStepBtn => _t('Étape précédente', ar: 'السابق', en: 'Previous Step');
  String get titleFrRequired => _t('Titre (Français, obligatoire)', ar: 'العنوان (بالفرنسية، إجباري)', en: 'Title (French, required)');
  String get titleArOptional => _t('Titre (Arabe, optionnel)', ar: 'العنوان (بالعربية، اختياري)', en: 'Title (Arabic, optional)');
  String get titleEnOptional => _t('Titre (Anglais, optionnel)', ar: 'العنوان (بالإنجليزية، اختياري)', en: 'Title (English, optional)');
  String get descriptionFr => _t('Description (Français)', ar: 'الوصف (بالفرنسية)', en: 'Description (French)');
  String get descriptionAr => _t('Description (Arabe)', ar: 'الوصف (بالعربية)', en: 'Description (Arabic)');
  String get descriptionEn => _t('Description (Anglais)', ar: 'الوصف (بالإنجليزية)', en: 'Description (English)');
  String get addressOptional => _t('Adresse exacte (optionnel)', ar: 'العنوان الدقيق (اختياري)', en: 'Exact address (optional)');
  String get capacityLabel => _t('Capacité d\'accueil (voyageurs)', ar: 'الطاقة الاستيعابية (ضيوف)', en: 'Max capacity (guests)');
  String get bedroomsLabel => _t('Chambres', ar: 'عدد الغرف', en: 'Bedrooms');
  String get bathroomsLabel => _t('Salles de bain', ar: 'عدد الحمامات', en: 'Bathrooms');
  String get amenitiesTitle => _t('Équipements inclus', ar: 'وسائل الراحة والتجهيزات', en: 'Amenities');
  String get houseRulesTitle => _t('Règlement intérieur', ar: 'شروط وقواعد المسكن', en: 'House Rules');
  String get nightlyPriceLabel => _t('Prix par nuit (DZD)', ar: 'السعر لليلة (د.ج)', en: 'Price per night (DZD)');
  String get cleaningFeeLabel => _t('Frais de ménage (DZD)', ar: 'رسوم التنظيف (د.ج)', en: 'Cleaning fee (DZD)');
  String get depositLabel => _t('Caution de garantie (DZD)', ar: 'مبلغ التأمين (د.ج)', en: 'Deposit (DZD)');
  String get coverPhotoLabel => _t('Photo de couverture', ar: 'الصورة الرئيسية', en: 'Cover Photo');
  String get coverPhotoHint => _t(
        'Cette photo apparaîtra en premier dans les résultats de recherche.',
        ar: 'هذه الصورة ستظهر في نتائج البحث والواجهة الرئيسية.',
        en: 'This photo will appear first in search results.',
      );
  String get galleryPhotosLabel => _t('Photos de la galerie', ar: 'معرض الصور', en: 'Gallery Photos');
  String get galleryPhotosHint => _t(
        'Ajoutez jusqu\'à 20 photos mettant en valeur votre bien (max 8 Mo par photo).',
        ar: 'أضف حتى 20 صورة تُبرز جمال وتجهيزات عقارك (حتى 8 ميغابايت لكل صورة).',
        en: 'Add up to 20 photos showcasing your stay (max 8 MB per image).',
      );
  String get pickCover => _t('Choisir la photo principale', ar: 'اختيار الصورة الرئيسية', en: 'Pick cover photo');
  String get addPhotos => _t('Ajouter des photos', ar: 'إضافة صور', en: 'Add photos');
  String get submitForReviewBtn => _t('Créer et soumettre pour validation', ar: 'إنشاء وإرسال للمراجعة', en: 'Submit for Review');
  String get creatingDraftStatus => _t('Création du brouillon...', ar: 'إنشاء المسودة...', en: 'Creating draft listing...');
  String get uploadingPhotosStatus => _t('Téléversement des photos...', ar: 'جاري رفع الصور...', en: 'Uploading photos...');
  String get submittingStatus => _t('Soumission pour modération...', ar: 'إرسال للمراجعة...', en: 'Submitting for review...');
  String get propertySubmittedSuccess => _t('Annonce soumise avec succès !', ar: 'تم إرسال إعلانك بنجاح!', en: 'Listing submitted for review!');
  String get propertySubmittedPendingMsg => _t(
        'Votre logement a été créé avec le statut En attente de modération. Dès validation par notre équipe, il sera visible dans les recherches.',
        ar: 'تم إنشاء إعلانك بحالة "قيد المراجعة". بمجرد موافقة فريق الإشراف، سيظهر مباشرة في نتائج البحث.',
        en: 'Your listing is now pending review. Once approved by our moderation team, it will be visible in public search.',
      );
  String get viewMyListings => _t('Voir mes annonces', ar: 'عرض إعلاناتي', en: 'View my listings');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['fr', 'ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this);
}
