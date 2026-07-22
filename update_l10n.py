import json
import os

translations = {
    "en": {
        "myEhrDashboard": "My EHR Dashboard",
        "offlineView": "Offline View",
        "darkMode": "Dark Mode",
        "allMedicalRecords": "All Medical Records",
        "logout": "Logout",
        "joinDoctorQueue": "Join Doctor Queue",
        "requestConsultation": "Request a consultation for a new or existing issue.",
        "myRecentVitals": "My Recent Vitals",
        "myMedicalRecords": "My Medical Records",
        "more": "More",
        "requestAmbulance": "Request Ambulance",
        "noMedicalRecords": "No medical records found."
    },
    "hi": {
        "myEhrDashboard": "मेरा ईएचआर डैशबोर्ड",
        "offlineView": "ऑफ़लाइन दृश्य",
        "darkMode": "डार्क मोड",
        "allMedicalRecords": "सभी मेडिकल रिकॉर्ड",
        "logout": "लॉग आउट",
        "joinDoctorQueue": "डॉक्टर कतार में शामिल हों",
        "requestConsultation": "नई या मौजूदा समस्या के लिए परामर्श का अनुरोध करें।",
        "myRecentVitals": "मेरे हाल के वाइटल्स",
        "myMedicalRecords": "मेरे मेडिकल रिकॉर्ड",
        "more": "अधिक",
        "requestAmbulance": "एम्बुलेंस का अनुरोध करें",
        "noMedicalRecords": "कोई मेडिकल रिकॉर्ड नहीं मिला।"
    },
    "mr": {
        "myEhrDashboard": "माझा ईएचआर डॅशबोर्ड",
        "offlineView": "ऑफलाइन दृश्य",
        "darkMode": "डार्क मोड",
        "allMedicalRecords": "सर्व वैद्यकीय रेकॉर्ड",
        "logout": "लॉग आउट",
        "joinDoctorQueue": "डॉक्टर रांगेत सामील व्हा",
        "requestConsultation": "नवीन किंवा विद्यमान समस्येसाठी सल्लामसलत करण्याची विनंती करा.",
        "myRecentVitals": "माझे अलीकडील वाइटल्स",
        "myMedicalRecords": "माझे वैद्यकीय रेकॉर्ड",
        "more": "अधिक",
        "requestAmbulance": "रुग्णवाहिकेची विनंती करा",
        "noMedicalRecords": "कोणतेही वैद्यकीय रेकॉर्ड आढळले नाही."
    },
    "bn": {
        "myEhrDashboard": "আমার ইএইচআর ড্যাশবোর্ড",
        "offlineView": "অফলাইন ভিউ",
        "darkMode": "ডার্ক মোড",
        "allMedicalRecords": "সব মেডিকেল রেকর্ড",
        "logout": "লগ আউট",
        "joinDoctorQueue": "ডাক্তারের সারিতে যোগ দিন",
        "requestConsultation": "নতুন বা বিদ্যমান সমস্যার জন্য পরামর্শের অনুরোধ করুন।",
        "myRecentVitals": "আমার সাম্প্রতিক ভাইটালস",
        "myMedicalRecords": "আমার মেডিকেল রেকর্ড",
        "more": "আরও",
        "requestAmbulance": "অ্যাম্বুলেন্সের অনুরোধ করুন",
        "noMedicalRecords": "কোনো মেডিকেল রেকর্ড পাওয়া যায়নি।"
    },
    "te": {
        "myEhrDashboard": "నా EHR డాష్‌బోర్డ్",
        "offlineView": "ఆఫ్‌లైన్ వీక్షణ",
        "darkMode": "డార్క్ మోడ్",
        "allMedicalRecords": "అన్ని వైద్య రికార్డులు",
        "logout": "లాగ్ అవుట్",
        "joinDoctorQueue": "డాక్టర్ క్యూలో చేరండి",
        "requestConsultation": "కొత్త లేదా ఉన్న సమస్య కోసం సంప్రదింపులను అభ్యర్థించండి.",
        "myRecentVitals": "నా ఇటీవలి ప్రాణాధారాలు",
        "myMedicalRecords": "నా వైద్య రికార్డులు",
        "more": "మరింత",
        "requestAmbulance": "అంబులెన్స్ అభ్యర్థించండి",
        "noMedicalRecords": "ఎటువంటి వైద్య రికార్డులు కనుగొనబడలేదు."
    },
    "ta": {
        "myEhrDashboard": "எனது EHR டாஷ்போர்டு",
        "offlineView": "ஆஃப்லைன் பார்வை",
        "darkMode": "டார்க் பயன்முறை",
        "allMedicalRecords": "அனைத்து மருத்துவ பதிவுகள்",
        "logout": "வெளியேறு",
        "joinDoctorQueue": "டாக்டர் வரிசையில் சேரவும்",
        "requestConsultation": "புதிய அல்லது தற்போதைய பிரச்சனைக்கு ஆலோசனை கேட்கவும்.",
        "myRecentVitals": "எனது சமீபத்திய உயிராதாரங்கள்",
        "myMedicalRecords": "எனது மருத்துவ பதிவுகள்",
        "more": "மேலும்",
        "requestAmbulance": "ஆம்புலன்ஸ் கோரவும்",
        "noMedicalRecords": "மருத்துவ பதிவுகள் எதுவும் காணப்படவில்லை."
    },
    "gu": {
        "myEhrDashboard": "મારું EHR ડેશબોર્ડ",
        "offlineView": "ઑફલાઇન દૃશ્ય",
        "darkMode": "ડાર્ક મોડ",
        "allMedicalRecords": "તમામ મેડિકલ રેકોર્ડ્સ",
        "logout": "લૉગ આઉટ",
        "joinDoctorQueue": "ડૉક્ટરની કતારમાં જોડાઓ",
        "requestConsultation": "નવી અથવા વર્તમાન સમસ્યા માટે પરામર્શની વિનંતી કરો.",
        "myRecentVitals": "મારા તાજેતરના પાસાઓ",
        "myMedicalRecords": "મારા મેડિકલ રેકોર્ડ્સ",
        "more": "વધુ",
        "requestAmbulance": "એમ્બ્યુલન્સની વિનંતી કરો",
        "noMedicalRecords": "કોઈ મેડિકલ રેકોર્ડ મળ્યો નથી."
    }
}

l10n_dir = "lib/l10n"
for lang, new_strings in translations.items():
    file_path = os.path.join(l10n_dir, f"app_{lang}.arb")
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        data.update(new_strings)
        
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

print("Done updating ARB files.")
