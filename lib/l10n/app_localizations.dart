import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SehatSathi'**
  String get appTitle;

  /// No description provided for @selectPortal.
  ///
  /// In en, this message translates to:
  /// **'Please select your portal to continue'**
  String get selectPortal;

  /// No description provided for @patientPortal.
  ///
  /// In en, this message translates to:
  /// **'Patient Portal'**
  String get patientPortal;

  /// No description provided for @doctorPortal.
  ///
  /// In en, this message translates to:
  /// **'Doctor Portal'**
  String get doctorPortal;

  /// No description provided for @adminPortal.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get adminPortal;

  /// No description provided for @pharmacistPortal.
  ///
  /// In en, this message translates to:
  /// **'Pharmacist Portal'**
  String get pharmacistPortal;

  /// No description provided for @labTechPortal.
  ///
  /// In en, this message translates to:
  /// **'Lab Tech Portal'**
  String get labTechPortal;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @myEhrDashboard.
  ///
  /// In en, this message translates to:
  /// **'My EHR Dashboard'**
  String get myEhrDashboard;

  /// No description provided for @offlineView.
  ///
  /// In en, this message translates to:
  /// **'Offline View'**
  String get offlineView;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @allMedicalRecords.
  ///
  /// In en, this message translates to:
  /// **'All Medical Records'**
  String get allMedicalRecords;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @joinDoctorQueue.
  ///
  /// In en, this message translates to:
  /// **'Join Doctor Queue'**
  String get joinDoctorQueue;

  /// No description provided for @requestConsultation.
  ///
  /// In en, this message translates to:
  /// **'Request a consultation for a new or existing issue.'**
  String get requestConsultation;

  /// No description provided for @myRecentVitals.
  ///
  /// In en, this message translates to:
  /// **'My Recent Vitals'**
  String get myRecentVitals;

  /// No description provided for @myMedicalRecords.
  ///
  /// In en, this message translates to:
  /// **'My Medical Records'**
  String get myMedicalRecords;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @requestAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Request Ambulance'**
  String get requestAmbulance;

  /// No description provided for @noMedicalRecords.
  ///
  /// In en, this message translates to:
  /// **'No medical records found.'**
  String get noMedicalRecords;

  /// No description provided for @clinicalEncounterDetails.
  ///
  /// In en, this message translates to:
  /// **'Clinical Encounter Details'**
  String get clinicalEncounterDetails;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @diagnosisImpression.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis / Impression'**
  String get diagnosisImpression;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @progressNotesTreatmentPlan.
  ///
  /// In en, this message translates to:
  /// **'Progress Notes & Treatment Plan'**
  String get progressNotesTreatmentPlan;

  /// No description provided for @noClinicalNotes.
  ///
  /// In en, this message translates to:
  /// **'No clinical notes provided.'**
  String get noClinicalNotes;

  /// No description provided for @prescribedMedications.
  ///
  /// In en, this message translates to:
  /// **'Prescribed Medications'**
  String get prescribedMedications;

  /// No description provided for @noMedications.
  ///
  /// In en, this message translates to:
  /// **'No medications prescribed during this visit.'**
  String get noMedications;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @dispensed.
  ///
  /// In en, this message translates to:
  /// **'Dispensed'**
  String get dispensed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @laboratoryReports.
  ///
  /// In en, this message translates to:
  /// **'Laboratory Reports'**
  String get laboratoryReports;

  /// No description provided for @noLabReports.
  ///
  /// In en, this message translates to:
  /// **'No lab reports attached to this encounter.'**
  String get noLabReports;

  /// No description provided for @completedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed on'**
  String get completedOn;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @prescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @noVitalsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No vitals recorded yet.'**
  String get noVitalsRecorded;

  /// No description provided for @bp.
  ///
  /// In en, this message translates to:
  /// **'BP'**
  String get bp;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @recentTrends.
  ///
  /// In en, this message translates to:
  /// **'Recent Trends'**
  String get recentTrends;

  /// No description provided for @bpSystolic.
  ///
  /// In en, this message translates to:
  /// **'BP (Systolic)'**
  String get bpSystolic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'gu',
    'hi',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
