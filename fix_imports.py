import os
import re
import shutil

# Move missing files
moves = {
    r"lib\screens\edit_profile_screen.dart": r"lib\features\profile\screens\edit_profile_screen.dart",
    r"lib\screens\settings_screen.dart": r"lib\features\profile\screens\settings_screen.dart",
    r"lib\screens\phone_login_screen.dart": r"lib\features\auth\screens\phone_login_screen.dart",
    r"lib\screens\register_screen.dart": r"lib\features\auth\screens\register_screen.dart",
}

for src, dst in moves.items():
    if os.path.exists(src):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.move(src, dst)

def fix_imports_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # If it's a newly moved file, it might still have old relative paths
    if filepath.endswith("edit_profile_screen.dart") or filepath.endswith("settings_screen.dart") or filepath.endswith("phone_login_screen.dart") or filepath.endswith("register_screen.dart"):
        content = re.sub(r"'\.\./models/", "'../../../models/", content)
        content = re.sub(r"'\.\./services/", "'../../../services/", content)
        content = re.sub(r"'\.\./core/", "'../../../core/", content)
        content = re.sub(r"'\.\./screens/", "'../../../features/discover/screens/", content)

    # Cross-feature imports
    replacements = {
        "'home_screen.dart'": "'../../discover/screens/home_screen.dart'",
        "'settings_screen.dart'": "'../../profile/screens/settings_screen.dart'",
        "'edit_profile_screen.dart'": "'../../profile/screens/edit_profile_screen.dart'",
        "'login_screen.dart'": "'../../auth/screens/login_screen.dart'",
        "'matches_screen.dart'": "'../../matches/screens/matches_screen.dart'",
        "'messages_screen.dart'": "'../../chat/screens/messages_screen.dart'",
        "'profile_screen.dart'": "'../../profile/screens/profile_screen.dart'",
        "'phone_login_screen.dart'": "'../../auth/screens/phone_login_screen.dart'",
        "'register_screen.dart'": "'../../auth/screens/register_screen.dart'",
        "'discover_screen.dart'": "'../../discover/screens/discover_screen.dart'",
    }

    # For files within the same feature directory, we should use relative imports like 'login_screen.dart'
    # Wait, if they are in the same folder, they should just be 'login_screen.dart'
    # So let's conditionally replace based on the current file's location.

    filename = os.path.basename(filepath)
    feature = filepath.split(os.sep)[2] if len(filepath.split(os.sep)) > 2 else ""

    # Specific fixes
    for old, new in replacements.items():
        # If they belong to the same feature, don't use ../../
        target_feature = new.split('/')[2]
        if target_feature == feature:
            content = content.replace(old, f"'{old.strip(chr(39))}'")
        else:
            content = content.replace(old, new)
            
    # Remove any double processing (e.g. if we already replaced it)
    content = content.replace("'../../discover/screens/../../discover/screens/", "'../../discover/screens/")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)


for root, _, files in os.walk(r"lib\features"):
    for file in files:
        if file.endswith(".dart"):
            fix_imports_in_file(os.path.join(root, file))

# main.dart specific fixes
if os.path.exists(r"lib\main.dart"):
    with open(r"lib\main.dart", 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("'screens/splash_screen.dart'", "'features/auth/screens/splash_screen.dart'")
    content = content.replace("'screens/home_screen.dart'", "'features/discover/screens/home_screen.dart'")
    content = content.replace("'screens/login_screen.dart'", "'features/auth/screens/login_screen.dart'")
    with open(r"lib\main.dart", 'w', encoding='utf-8') as f:
        f.write(content)

print("Refactoring imports complete.")
