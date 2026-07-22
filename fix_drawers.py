import os

dashboard_files = [
    'lib/screens/admin/admin_dashboard.dart',
    'lib/screens/doctor/doctor_dashboard.dart',
    'lib/screens/lab/lab_dashboard.dart',
    'lib/screens/patient/patient_dashboard.dart',
    'lib/screens/pharmacist/pharmacist_dashboard.dart'
]

list_tile = """              ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)?.language ?? 'Language'),
                trailing: const LanguageSelector(),
              ),
              const Spacer(),"""

for file_path in dashboard_files:
    if not os.path.exists(file_path):
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    if "trailing: const LanguageSelector()," not in content:
        # Some files might have 'const Spacer(),' or 'Spacer(),' before the divider/logout
        if "const Spacer()," in content:
            content = content.replace("const Spacer(),", list_tile, 1)
        elif "Spacer()," in content:
            content = content.replace("Spacer(),", list_tile.replace("const Spacer(),", "Spacer(),"), 1)
            
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Dashboards updated with LanguageSelector in Drawer.")
