// widgets/localized_text.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/translation_service.dart';
import '../providers/settings_provider.dart'; // Ensure this path points to your SettingsProvider

class LocalizedText extends StatelessWidget {
  // 🌟 FIX 1: Rename to 'translationKey' to resolve the Flutter widget key collision
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const LocalizedText(
    this.translationKey, {
    Key? key, // This remains the standard Flutter widget identity key
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // 🌟 FIX 2: Watch the settings provider language state change here.
    // This tells Flutter: "Whenever the app language updates, rebuild this specific text string!"
    final currentLanguage = context.watch<SettingsProvider>().language;
    
    return Text(
      // Pass your key to your translation layout engine
      TranslationService.instance.translate(translationKey),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}