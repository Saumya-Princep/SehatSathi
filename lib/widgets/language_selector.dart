import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return DropdownButton<String>(
          value: languageProvider.currentLocale.languageCode,
          underline: const SizedBox(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              languageProvider.setLanguage(newValue);
            }
          },
          items: const [
            DropdownMenuItem(
              value: 'en',
              child: Text('English'),
            ),
            DropdownMenuItem(
              value: 'hi',
              child: Text('हिंदी (Hindi)'),
            ),
            DropdownMenuItem(
              value: 'bn',
              child: Text('বাংলা (Bengali)'),
            ),
            DropdownMenuItem(
              value: 'te',
              child: Text('తెలుగు (Telugu)'),
            ),
            DropdownMenuItem(
              value: 'mr',
              child: Text('मराठी (Marathi)'),
            ),
            DropdownMenuItem(
              value: 'ta',
              child: Text('தமிழ் (Tamil)'),
            ),
            DropdownMenuItem(
              value: 'gu',
              child: Text('ગુજરાતી (Gujarati)'),
            ),
          ],
        );
      },
    );
  }
}
