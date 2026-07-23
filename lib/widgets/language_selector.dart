import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: DropdownButton<String>(
            isExpanded: true,
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
                child: Text('English', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'hi',
                child: Text('हिंदी (Hindi)', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'bn',
                child: Text('বাংলা (Bengali)', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'te',
                child: Text('తెలుగు (Telugu)', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'mr',
                child: Text('मराठी (Marathi)', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'ta',
                child: Text('தமிழ் (Tamil)', overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'gu',
                child: Text('ગુજરાતી (Gujarati)', overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      },
    );
  }
}
