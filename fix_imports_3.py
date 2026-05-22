import os
import re

files_to_fix = []
for root, dirs, files in os.walk('lib/features'):
    for f in files:
        if f.endswith('.dart'):
            files_to_fix.append(os.path.join(root, f))

for path in files_to_fix:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    orig = content
    
    # Fix models, services, core
    content = re.sub(r"import '(?:[\.\/]+)models/", r"import '../../../models/", content)
    content = re.sub(r"import '(?:[\.\/]+)services/", r"import '../../../services/", content)
    content = re.sub(r"import '(?:[\.\/]+)core/", r"import '../../../core/", content)
    
    # Fix screens
    screen_map = {
        'login_screen.dart': 'features/auth/screens/login_screen.dart',
        'splash_screen.dart': 'features/auth/screens/splash_screen.dart',
        'phone_login_screen.dart': 'features/auth/screens/phone_login_screen.dart',
        'register_screen.dart': 'features/auth/screens/register_screen.dart',
        
        'home_screen.dart': 'features/discover/screens/home_screen.dart',
        'discover_screen.dart': 'features/discover/screens/discover_screen.dart',
        
        'matches_screen.dart': 'features/matches/screens/matches_screen.dart',
        
        'messages_screen.dart': 'features/chat/screens/messages_screen.dart',
        'chat_screen.dart': 'features/chat/screens/chat_screen.dart',
        
        'profile_screen.dart': 'features/profile/screens/profile_screen.dart',
        'edit_profile_screen.dart': 'features/profile/screens/edit_profile_screen.dart',
        'settings_screen.dart': 'features/profile/screens/settings_screen.dart',
    }
    
    for screen_name, correct_path in screen_map.items():
        pattern = r"import '(?:[\.\/a-zA-Z0-9_]*)?" + re.escape(screen_name) + r"';"
        replacement = f"import '../../../{correct_path}';"
        content = re.sub(pattern, replacement, content)
        
    if orig != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {path}")
