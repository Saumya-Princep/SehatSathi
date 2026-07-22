import os
import re

dashboard_files = [
    'lib/screens/admin/admin_dashboard.dart',
    'lib/screens/doctor/doctor_dashboard.dart',
    'lib/screens/lab/lab_dashboard.dart',
    'lib/screens/patient/patient_dashboard.dart',
    'lib/screens/pharmacist/pharmacist_dashboard.dart'
]

for file_path in dashboard_files:
    if not os.path.exists(file_path):
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove from AppBar actions
    # This might match the whole Padding block
    pattern = r'actions:\s*(const\s*)?\[\s*Padding\(\s*padding:\s*EdgeInsets\.symmetric\(horizontal:\s*8\.0\),\s*child:\s*LanguageSelector\(\),\s*\),?\s*\],?'
    # Some files might have other actions, let's just remove the Padding part if it's the only one, or carefully remove it.
    
    # Simpler: just remove the exact string
    pad_str1 = """          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: LanguageSelector(),
            ),
          ],"""
    pad_str2 = """          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: LanguageSelector(),
            ),
          ],"""
    pad_str3 = """            actions: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: LanguageSelector(),
              ),
            ],"""
    
    if pad_str1 in content:
        content = content.replace(pad_str1, "          actions: [],")
    if pad_str2 in content:
        content = content.replace(pad_str2, "          actions: [],")
    if pad_str3 in content:
        content = content.replace(pad_str3, "            actions: [],")
        
    # Also handle doctor_dashboard which might have multiple actions
    doc_pad = """            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: LanguageSelector(),
            ),"""
    if "doctor_dashboard.dart" in file_path and doc_pad in content:
        content = content.replace(doc_pad, "")
    
    # Now add to Drawer
    # Find the end of the children array of the Drawer's Column or ListView
    # Usually it's after UserAccountsDrawerHeader and some ListTiles
    # I'll just append it before the Logout ListTile or at the end of the children if Logout doesn't exist
    list_tile = """                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(AppLocalizations.of(context)?.language ?? 'Language'),
                  trailing: const LanguageSelector(),
                ),"""
                
    if "ListTile(\n                  leading: const Icon(Icons.language)" not in content:
        # insert before Logout
        if "leading: const Icon(Icons.exit_to_app)," in content:
            content = content.replace(
                "leading: const Icon(Icons.exit_to_app),",
                "leading: const Icon(Icons.language),\n                  title: Text(AppLocalizations.of(context)?.language ?? 'Language'),\n                  trailing: const LanguageSelector(),\n                ),\n                ListTile(\n                  leading: const Icon(Icons.exit_to_app),"
            )
        elif "leading: Icon(Icons.exit_to_app)," in content:
            content = content.replace(
                "leading: Icon(Icons.exit_to_app),",
                "leading: const Icon(Icons.language),\n                  title: Text(AppLocalizations.of(context)?.language ?? 'Language'),\n                  trailing: const LanguageSelector(),\n                ),\n                ListTile(\n                  leading: Icon(Icons.exit_to_app),"
            )
            
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Dashboards updated.")
