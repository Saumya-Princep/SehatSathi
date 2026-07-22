import json
import os

langs = ['en', 'hi', 'bn', 'te', 'mr', 'ta', 'gu']
date_translations = {
    'en': 'Date',
    'hi': 'तारीख',
    'bn': 'তারিখ',
    'te': 'తేదీ',
    'mr': 'तारीख',
    'ta': 'தேதி',
    'gu': 'તારીખ'
}

for lang in langs:
    file_path = f'lib/l10n/app_{lang}.arb'
    if not os.path.exists(file_path):
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if 'date' not in data:
        data['date'] = date_translations.get(lang, 'Date')
            
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

