import os
import re

def fix_imports():
    for root, dirs, files in os.walk('lib/features'):
        for file in files:
            if not file.endswith('.dart'): continue
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content

            # 1. Fix up relative paths for newly moved files
            if file in ['edit_profile_screen.dart', 'settings_screen.dart', 'phone_login_screen.dart', 'register_screen.dart']:
                content = re.sub(r"'\.\./models/", "'../../../models/", content)
                content = re.sub(r"'\.\./services/", "'../../../services/", content)
                content = re.sub(r"'\.\./core/", "'../../../core/", content)
                content = re.sub(r"'\.\./screens/", "'../../../features/discover/screens/", content)
            
            # 2. Convert all naked imports to absolute cross-feature paths
            content = re.sub(r"'(?:\./)?login_screen\.dart'", "'../../auth/screens/login_screen.dart'", content)
            content = re.sub(r"'(?:\./)?splash_screen\.dart'", "'../../auth/screens/splash_screen.dart'", content)
            content = re.sub(r"'(?:\./)?phone_login_screen\.dart'", "'../../auth/screens/phone_login_screen.dart'", content)
            content = re.sub(r"'(?:\./)?register_screen\.dart'", "'../../auth/screens/register_screen.dart'", content)
            
            content = re.sub(r"'(?:\./)?home_screen\.dart'", "'../../discover/screens/home_screen.dart'", content)
            content = re.sub(r"'(?:\./)?discover_screen\.dart'", "'../../discover/screens/discover_screen.dart'", content)
            
            content = re.sub(r"'(?:\./)?matches_screen\.dart'", "'../../matches/screens/matches_screen.dart'", content)
            
            content = re.sub(r"'(?:\./)?messages_screen\.dart'", "'../../chat/screens/messages_screen.dart'", content)
            content = re.sub(r"'(?:\./)?chat_screen\.dart'", "'../../chat/screens/chat_screen.dart'", content)
            
            content = re.sub(r"'(?:\./)?profile_screen\.dart'", "'../../profile/screens/profile_screen.dart'", content)
            content = re.sub(r"'(?:\./)?edit_profile_screen\.dart'", "'../../profile/screens/edit_profile_screen.dart'", content)
            content = re.sub(r"'(?:\./)?settings_screen\.dart'", "'../../profile/screens/settings_screen.dart'", content)

            # 3. Simplify paths if they belong to the same feature directory
            root_norm = root.replace('\\', '/')
            if 'auth/screens' in root_norm:
                content = content.replace("'../../auth/screens/", "'")
            if 'discover/screens' in root_norm:
                content = content.replace("'../../discover/screens/", "'")
            if 'matches/screens' in root_norm:
                content = content.replace("'../../matches/screens/", "'")
            if 'chat/screens' in root_norm:
                content = content.replace("'../../chat/screens/", "'")
            if 'profile/screens' in root_norm:
                content = content.replace("'../../profile/screens/", "'")

            if content != original_content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)

fix_imports()
