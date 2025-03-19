import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final LocalizationService _localizationService = LocalizationService();
  late String _selectedLanguage;
  
  @override
  void initState() {
    super.initState();
    _selectedLanguage = _localizationService.getLanguageName(
      _localizationService.currentLanguage,
    );
  }
  
  void _changeLanguage(String language) async {
    setState(() {
      _selectedLanguage = language;
    });
    
    await _localizationService.changeLanguage(language);
    
    if (mounted) {
      // Show a snackbar to inform the user that they need to restart the app
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please restart the app to apply the language change'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: ListView.builder(
        itemCount: _localizationService.availableLanguageNames.length,
        itemBuilder: (context, index) {
          final language = _localizationService.availableLanguageNames[index];
          final isSelected = language == _selectedLanguage;
          
          return ListTile(
            title: Text(language),
            subtitle: Text(_getLanguageSubtitle(language)),
            leading: _buildLanguageFlag(language),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () => _changeLanguage(language),
            selected: isSelected,
          );
        },
      ),
    );
  }
  
  Widget _buildLanguageFlag(String language) {
    // Return flag emoji based on language
    switch (language) {
      case 'English':
        return const Text('🇺🇸', style: TextStyle(fontSize: 24));
      case 'Spanish':
        return const Text('🇪🇸', style: TextStyle(fontSize: 24));
      case 'French':
        return const Text('🇫🇷', style: TextStyle(fontSize: 24));
      case 'Chinese':
        return const Text('🇨🇳', style: TextStyle(fontSize: 24));
      case 'Arabic':
        return const Text('🇸🇦', style: TextStyle(fontSize: 24));
      case 'Hindi':
        return const Text('🇮🇳', style: TextStyle(fontSize: 24));
      default:
        return const Icon(Icons.language);
    }
  }
  
  String _getLanguageSubtitle(String language) {
    // Return language name in its native script
    switch (language) {
      case 'English':
        return 'English';
      case 'Spanish':
        return 'Español';
      case 'French':
        return 'Français';
      case 'Chinese':
        return '中文';
      case 'Arabic':
        return 'العربية';
      case 'Hindi':
        return 'हिन्दी';
      default:
        return '';
    }
  }
}
