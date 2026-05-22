# Firebase Kurulum Rehberi

Bu uygulama Firebase'i backend olarak kullanmaktadır. Aşağıdaki adımları takip ederek Firebase projenizi kurabilirsiniz.

## 1. Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. "Add project" diyerek yeni bir proje oluşturun
3. Proje adı: "ArkadaslikUygulamasi" (veya istediğiniz isim)
4. Google Analytics'i devre dışı bırakabilir veya aktif edebilirsiniz
5. Proje oluşturulunca "Continue" diyerek devam edin

## 2. Android Uygulaması Ekleme

1. Firebase Console'da Android ikonuna tıklayın
2. Şu bilgileri girin:
   - Package name: `com.example.arkadaslik_uygulamasi` (veya android/app/build.gradle dosyasındaki applicationId)
   - App nickname (opsiyonel): `Arkadaşlık Uygulaması`
   - Debug signing certificate SHA-1 (opsiyonel):
     - Terminalde şu komutu çalıştırın:
     ```
     keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
     ```
     - SHA-1 değerini kopyalayın
3. "Register app" diyerek devam edin
4. `google-services.json` dosyasını indirin
5. Dosyayı `android/app/` dizinine kopyalayın
6. "Next" diyerek devam edin

## 3. Firebase SDK'ları Ekleme

Aşağıdaki değişiklikler zaten yapılmıştır, kontrol edin:

### android/build.gradle (Project level)

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

### android/app/build.gradle (App level)

```gradle
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services' // Bu satırı ekleyin
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.1.0')
}
```

## 4. Firebase Özelliklerini Aktif Etme

### Authentication

1. Firebase Console'da "Authentication" seçeneğine gidin
2. "Get started" diyerek başlayın
3. "Sign-in method" sekmesine gidin
4. "Email/Password" yöntemini aktif edin
5. İsterseniz "Google" sign-in'i de aktif edin

### Cloud Firestore

1. Firebase Console'da "Firestore Database" seçeneğine gidin
2. "Create database" diyerek başlayın
3. Bir bölge seçin (örneğin: europe-west1)
4. "Start in test mode" seçeneğini seçin (30 gün sonra güvenlik kurallarını güncelleyin)
5. "Enable" diyerek aktif edin

### Firebase Storage

1. Firebase Console'da "Storage" seçeneğine gidin
2. "Get started" diyerek başlayın
3. Bir bölge seçin (Firestore ile aynı bölgeyi seçin)
4. "Start in test mode" seçeneğini seçin
5. "Enable" diyerek aktif edin

### Cloud Messaging

1. Firebase Console'da "Cloud Messaging" seçeneğine gidin
2. "Get started" diyerek başlayın (zaten aktiftir)

## 5. Güvenlik Kuralları

### Firestore Security Rules

Firebase Console > Firestore Database > Rules sekmesine gidin ve şu kuralları yapıştırın:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || request.auth.uid == resource.data.id);
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Matches collection
    match /matches/{matchId} {
      allow read: if request.auth != null && (request.auth.uid == resource.data.userId1 || request.auth.uid == resource.data.userId2);
      allow create: if request.auth != null;
      allow update: if request.auth != null && (request.auth.uid == resource.data.userId1 || request.auth.uid == resource.data.userId2);
    }
    
    // Chats collection
    match /chats/{chatId} {
      allow read: if request.auth != null && chatId.matches(request.auth.uid + '_.*') || chatId.matches('.*_' + request.auth.uid);
      allow write: if request.auth != null;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null && (request.auth.uid == request.resource.data.senderId || request.auth.uid == request.resource.data.receiverId);
        allow update: if request.auth != null && request.auth.uid == request.resource.data.senderId;
      }
    }
  }
}
```

### Storage Security Rules

Firebase Console > Storage > Rules sekmesine gidin ve şu kuralları yapıştırın:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images
    match /profile_images/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat images
    match /chat_images/{chatId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && chatId.matches(request.auth.uid + '_.*') || chatId.matches('.*_' + request.auth.uid);
    }
  }
}
```

## 6. Uygulamayı Çalıştırma

1. `google-services.json` dosyasını `android/app/` dizinine kopyaladığınızdan emin olun
2. Terminalde şu komutları çalıştırın:
```bash
flutter clean
flutter pub get
flutter run
```

## 7. Test

Uygulamayı açın ve kayıt olmayı deneyin. Firebase Console'da Authentication ve Firestore'da verilerin göründüğünden emin olun.

## Notlar

- Firebase projesini test modunda başlattınız, 30 gün içinde production mod için güvenlik kurallarını güncelleyin
- Gerçek uygulamada daha detaylı güvenlik kuralları ve veri validasyonu gereklidir
- Google Sign-in için `google_sign_in` paketini eklemeniz gerekebilir
