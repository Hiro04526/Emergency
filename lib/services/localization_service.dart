import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  // Singleton pattern
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  // Available languages
  static const Map<String, Locale> availableLanguages = {
    'English': Locale('en', 'US'),
    'Spanish': Locale('es', 'ES'),
    'French': Locale('fr', 'FR'),
    'Chinese': Locale('zh', 'CN'),
    'Arabic': Locale('ar', 'SA'),
    'Hindi': Locale('hi', 'IN'),
  };

  // Default language
  static const Locale defaultLanguage = Locale('en', 'US');

  // Current language
  Locale _currentLanguage = defaultLanguage;
  Locale get currentLanguage => _currentLanguage;

  // Get available language names
  List<String> get availableLanguageNames => availableLanguages.keys.toList();

  // Initialize the service
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');
    final countryCode = prefs.getString('countryCode');
    
    if (languageCode != null && countryCode != null) {
      _currentLanguage = Locale(languageCode, countryCode);
    }
  }

  // Change the language
  Future<void> changeLanguage(String languageName) async {
    if (availableLanguages.containsKey(languageName)) {
      _currentLanguage = availableLanguages[languageName]!;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', _currentLanguage.languageCode);
      await prefs.setString('countryCode', _currentLanguage.countryCode!);
    }
  }

  // Get language name from locale
  String getLanguageName(Locale locale) {
    for (final entry in availableLanguages.entries) {
      if (entry.value.languageCode == locale.languageCode &&
          entry.value.countryCode == locale.countryCode) {
        return entry.key;
      }
    }
    return 'English'; // Default
  }
}

// Translations class
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  // Helper method to get localized strings
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  // Static delegate for the localization
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  // Translations
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Emergency Services',
      'home': 'Home',
      'search': 'Search',
      'alerts': 'Alerts',
      'settings': 'Settings',
      'sos': 'SOS',
      'police': 'Police',
      'fire': 'Fire Department',
      'medical': 'Medical Services',
      'rescue': 'Rescue Services',
      'call_now': 'Call Now',
      'get_directions': 'Get Directions',
      'emergency_contacts': 'Emergency Contacts',
      'report_emergency': 'Report Emergency',
      'emergency_alerts': 'Emergency Alerts',
      'all_alerts': 'All Alerts',
      'nearby_services': 'Nearby Services',
      'search_services': 'Search Services',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'about': 'About',
      'help': 'Help',
      'logout': 'Logout',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'remove': 'Remove',
      'close': 'Close',
      'open': 'Open',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'continue': 'Continue',
      'finish': 'Finish',
      'start': 'Start',
      'stop': 'Stop',
      'pause': 'Pause',
      'resume': 'Resume',
      'retry': 'Retry',
      'refresh': 'Refresh',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Information',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'done': 'Done',
      'sos_activated': 'SOS ACTIVATED',
      'sos_countdown': 'SOS will activate in %d seconds',
      'sos_instructions': 'Press and hold the SOS button in case of emergency',
      'sos_activated_message': 'Emergency services have been notified. Stay calm and wait for help.',
      'sos_deactivate': 'Deactivate SOS',
      'quick_emergency_calls': 'Quick Emergency Calls',
      'alert_title': 'Alert Title',
      'alert_description': 'Alert Description',
      'alert_location': 'Alert Location',
      'alert_type': 'Alert Type',
      'alert_date': 'Alert Date',
      'alert_time': 'Alert Time',
      'alert_status': 'Alert Status',
      'alert_priority': 'Alert Priority',
      'alert_source': 'Alert Source',
      'alert_actions': 'Alert Actions',
      'alert_details': 'Alert Details',
      'report_alert': 'Report Alert',
      'upload_image': 'Upload Image',
      'take_photo': 'Take Photo',
      'choose_from_gallery': 'Choose from Gallery',
      'directions': 'Directions',
      'estimated_time': 'Estimated time: %s',
      'start_navigation': 'Start Navigation',
      'driving': 'Driving',
      'walking': 'Walking',
      'cycling': 'Cycling',
      'transit': 'Transit',
      'your_location': 'Your Location',
      'destination': 'Destination',
      'overview': 'Overview',
      'alternative_routes': 'Alternative Routes',
    },
    'es': {
      'app_name': 'Servicios de Emergencia',
      'home': 'Inicio',
      'search': 'Buscar',
      'alerts': 'Alertas',
      'settings': 'Configuración',
      'sos': 'SOS',
      'police': 'Policía',
      'fire': 'Bomberos',
      'medical': 'Servicios Médicos',
      'rescue': 'Servicios de Rescate',
      'call_now': 'Llamar Ahora',
      'get_directions': 'Obtener Direcciones',
      'emergency_contacts': 'Contactos de Emergencia',
      'report_emergency': 'Reportar Emergencia',
      'emergency_alerts': 'Alertas de Emergencia',
      'all_alerts': 'Todas las Alertas',
      'nearby_services': 'Servicios Cercanos',
      'search_services': 'Buscar Servicios',
      'language': 'Idioma',
      'dark_mode': 'Modo Oscuro',
      'notifications': 'Notificaciones',
      'about': 'Acerca de',
      'help': 'Ayuda',
      'logout': 'Cerrar Sesión',
      'cancel': 'Cancelar',
      'submit': 'Enviar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Añadir',
      'remove': 'Quitar',
      'close': 'Cerrar',
      'open': 'Abrir',
      'back': 'Atrás',
      'next': 'Siguiente',
      'previous': 'Anterior',
      'continue': 'Continuar',
      'finish': 'Finalizar',
      'start': 'Iniciar',
      'stop': 'Detener',
      'pause': 'Pausar',
      'resume': 'Reanudar',
      'retry': 'Reintentar',
      'refresh': 'Actualizar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'warning': 'Advertencia',
      'info': 'Información',
      'confirm': 'Confirmar',
      'yes': 'Sí',
      'no': 'No',
      'ok': 'OK',
      'done': 'Hecho',
      'sos_activated': 'SOS ACTIVADO',
      'sos_countdown': 'SOS se activará en %d segundos',
      'sos_instructions': 'Mantén presionado el botón SOS en caso de emergencia',
      'sos_activated_message': 'Se ha notificado a los servicios de emergencia. Mantén la calma y espera ayuda.',
      'sos_deactivate': 'Desactivar SOS',
      'quick_emergency_calls': 'Llamadas Rápidas de Emergencia',
      'alert_title': 'Título de Alerta',
      'alert_description': 'Descripción de Alerta',
      'alert_location': 'Ubicación de Alerta',
      'alert_type': 'Tipo de Alerta',
      'alert_date': 'Fecha de Alerta',
      'alert_time': 'Hora de Alerta',
      'alert_status': 'Estado de Alerta',
      'alert_priority': 'Prioridad de Alerta',
      'alert_source': 'Fuente de Alerta',
      'alert_actions': 'Acciones de Alerta',
      'alert_details': 'Detalles de Alerta',
      'report_alert': 'Reportar Alerta',
      'upload_image': 'Subir Imagen',
      'take_photo': 'Tomar Foto',
      'choose_from_gallery': 'Elegir de la Galería',
      'directions': 'Direcciones',
      'estimated_time': 'Tiempo estimado: %s',
      'start_navigation': 'Iniciar Navegación',
      'driving': 'Conduciendo',
      'walking': 'Caminando',
      'cycling': 'En Bicicleta',
      'transit': 'Transporte Público',
      'your_location': 'Tu Ubicación',
      'destination': 'Destino',
      'overview': 'Vista General',
      'alternative_routes': 'Rutas Alternativas',
    },
    // Add more languages as needed
  };
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
  
  String translateWithParams(String key, List<dynamic> params) {
    final String template = translate(key);
    
    if (params.isEmpty) return template;
    
    String result = template;
    for (int i = 0; i < params.length; i++) {
      result = result.replaceFirst('%${i + 1}', params[i].toString());
      result = result.replaceFirst('%s', params[i].toString());
      result = result.replaceFirst('%d', params[i].toString());
    }
    
    return result;
  }
}

// Localization delegate
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'zh', 'ar', 'hi'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
