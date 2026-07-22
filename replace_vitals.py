import re

file_path = 'lib/widgets/vitals_summary_widget.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import '../../l10n/app_localizations.dart';" not in content:
    content = content.replace("import 'package:fl_chart/fl_chart.dart';", "import 'package:fl_chart/fl_chart.dart';\nimport '../../l10n/app_localizations.dart';")

# Replacements
replacements = [
    ("const Text('No vitals recorded yet.'", "Text(AppLocalizations.of(context)!.noVitalsRecorded"),
    ("_buildVitalCard(context, 'BP',", "_buildVitalCard(context, AppLocalizations.of(context)!.bp,"),
    ("_buildVitalCard(context, 'Heart Rate',", "_buildVitalCard(context, AppLocalizations.of(context)!.heartRate,"),
    ("_buildVitalCard(context, 'Weight',", "_buildVitalCard(context, AppLocalizations.of(context)!.weight,"),
    ("const Text('Recent Trends',", "Text(AppLocalizations.of(context)!.recentTrends,"),
    ("Text('BP (Systolic)'", "Text(AppLocalizations.of(context)!.bpSystolic"),
    ("Text('Heart Rate'", "Text(AppLocalizations.of(context)!.heartRate")
]

for old, new in replacements:
    content = content.replace(old, new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("vitals_summary_widget.dart updated.")
