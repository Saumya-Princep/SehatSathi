import re

file_path = 'lib/widgets/record_card.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import '../../l10n/app_localizations.dart';" not in content:
    content = content.replace("import '../../services/firestore_service.dart';", "import '../../services/firestore_service.dart';\nimport '../../l10n/app_localizations.dart';")

# Replacements
replacements = [
    ("Text('Diagnosis: ${record.diagnosis}'", "Text('${AppLocalizations.of(context)!.diagnosis}: ${record.diagnosis}'"),
    ("Text('Notes: ${record.notes}'", "Text('${AppLocalizations.of(context)!.notes}: ${record.notes}'"),
    ("const Text('Prescriptions:',", "Text('${AppLocalizations.of(context)!.prescriptions}:',"),
    ("p.isDispensed ? 'Dispensed' : 'Pending'", "p.isDispensed ? AppLocalizations.of(context)!.dispensed : AppLocalizations.of(context)!.pending"),
    ("const Text('Clinical Encounter Details',", "Text(AppLocalizations.of(context)!.clinicalEncounterDetails,"),
    ("_buildSectionTitle(context, 'Doctor')", "_buildSectionTitle(context, AppLocalizations.of(context)!.doctor)"),
    ("_buildSectionTitle(context, 'Diagnosis / Impression')", "_buildSectionTitle(context, AppLocalizations.of(context)!.diagnosisImpression)"),
    ("_buildSectionTitle(context, 'Allergies')", "_buildSectionTitle(context, AppLocalizations.of(context)!.allergies)"),
    ("_buildSectionTitle(context, 'Progress Notes & Treatment Plan')", "_buildSectionTitle(context, AppLocalizations.of(context)!.progressNotesTreatmentPlan)"),
    ("record.notes.isEmpty ? 'No clinical notes provided.' : record.notes", "record.notes.isEmpty ? AppLocalizations.of(context)!.noClinicalNotes : record.notes"),
    ("_buildSectionTitle(context, 'Prescribed Medications')", "_buildSectionTitle(context, AppLocalizations.of(context)!.prescribedMedications)"),
    ("const Text('No medications prescribed during this visit.',", "Text(AppLocalizations.of(context)!.noMedications,"),
    ("Text('Dosage: ${p.dosage}\\nQuantity: ${p.quantity}')", "Text('${AppLocalizations.of(context)!.dosage}: ${p.dosage}\\n${AppLocalizations.of(context)!.quantity}: ${p.quantity}')"),
    ("_buildSectionTitle(context, 'Laboratory Reports')", "_buildSectionTitle(context, AppLocalizations.of(context)!.laboratoryReports)"),
    ("const Text('No lab reports attached to this encounter.',", "Text(AppLocalizations.of(context)!.noLabReports,"),
    ("'Completed on ${DateFormat('MMM dd, yyyy - hh:mm a').format(r.timestamp!)}'", "'${AppLocalizations.of(context)!.completedOn} ${DateFormat('MMM dd, yyyy - hh:mm a').format(r.timestamp!)}'"),
    (": 'Completed'", ": AppLocalizations.of(context)!.completed"),
    ("const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold))", "Text('${AppLocalizations.of(context)!.notes}:', style: const TextStyle(fontWeight: FontWeight.bold))")
]

for old, new in replacements:
    content = content.replace(old, new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("record_card.dart updated.")
