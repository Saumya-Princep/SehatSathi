import json
import os
import re

langs = ['en', 'hi', 'bn', 'te', 'mr', 'ta', 'gu']

new_keys = {
    'noVitalsRecorded': {
        'en': 'No vitals recorded yet.',
        'hi': 'अभी तक कोई महत्वपूर्ण डेटा रिकॉर्ड नहीं किया गया है।',
        'bn': 'এখনও কোন গুরুত্বপূর্ণ তথ্য রেকর্ড করা হয়নি।',
        'te': 'ఇంకా ఎటువంటి ప్రాణాధారాలు నమోదు కాలేదు.',
        'mr': 'अद्याप कोणतेही जीवनावश्यक तपशील नोंदवले नाहीत.',
        'ta': 'இதுவரை எந்த முக்கிய தரவுகளும் பதிவு செய்யப்படவில்லை.',
        'gu': 'હજુ સુધી કોઈ મહત્વપૂર્ણ ડેટા નોંધવામાં આવ્યો નથી.'
    },
    'bp': {
        'en': 'BP',
        'hi': 'रक्तचाप',
        'bn': 'রক্তচাপ',
        'te': 'రక్తపోటు (BP)',
        'mr': 'रक्तदाब',
        'ta': 'ரத்த அழுத்தம்',
        'gu': 'બ્લડ પ્રેશર'
    },
    'heartRate': {
        'en': 'Heart Rate',
        'hi': 'हृदय गति',
        'bn': 'হৃদস্পন্দন',
        'te': 'హృదయ స్పందన',
        'mr': 'हृदय गती',
        'ta': 'இதய துடிப்பு',
        'gu': 'હૃદય દર'
    },
    'weight': {
        'en': 'Weight',
        'hi': 'वजन',
        'bn': 'ওজন',
        'te': 'బరువు',
        'mr': 'वजन',
        'ta': 'எடை',
        'gu': 'વજન'
    },
    'recentTrends': {
        'en': 'Recent Trends',
        'hi': 'हालिया रुझान',
        'bn': 'সাম্প্রতিক প্রবণতা',
        'te': 'ఇటీవలి పోకడలు',
        'mr': 'अलीकडील ट्रेंड्स',
        'ta': 'சமீபத்திய போக்குகள்',
        'gu': 'તાજેતરના વલણો'
    },
    'bpSystolic': {
        'en': 'BP (Systolic)',
        'hi': 'रक्तचाप (सिस्टोलिक)',
        'bn': 'রক্তচাপ (সিস্টোলিক)',
        'te': 'రక్తపోటు (సిస్టోలిక్)',
        'mr': 'रक्तदाब (सिस्टोलिक)',
        'ta': 'ரத்த அழுத்தம் (சிஸ்டோலிக்)',
        'gu': 'બ્લડ પ્રેશર (સિસ્ટોલિક)'
    }
}

for lang in langs:
    file_path = f'lib/l10n/app_{lang}.arb'
    if not os.path.exists(file_path):
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    for key, values in new_keys.items():
        if key not in data:
            data[key] = values.get(lang, values['en'])
            
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("ARB files updated.")
