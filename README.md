# Arkadaşlık Uygulaması 🚀

Flutter ile geliştirilmiş tam özellikli Türkçe arkadaşlık/dating uygulaması.

## 📱 Özellikler

### ✅ Tamamlanan Özellikler

- **Kimlik Doğrulama**
  - E-posta/Şifre ile kayıt olma
  - E-posta/Şifre ile giriş yapma
  - Şifre sıfırlama
  - Oturum yönetimi

- **Profil Yönetimi**
  - Profil oluşturma
  - Profil düzenleme
  - Fotoğraf yükleme
  - İlgi alanları ekleme
  - Bio ve kişisel bilgiler
  - Yaş ve cinsiyet bilgileri

- **Keşfet Sistemi**
  - Konum bazlı kullanıcı keşfi
  - Swipe kart sistemi (sağ/sol kaydırma)
  - Beğen/Beğenme/Süper Beğen özellikleri
  - Mesafe bazlı filtreleme
  - Yaş aralığı filtreleme

- **Eşleşme Sistemi**
  - Eşleşme listesi görüntüleme
  - Eşleşme detayları
  - Son mesaj gösterimi

- **Mesajlaşma Sistemi**
  - Real-time mesajlaşma
  - 1-1 sohbet
  - Mesaj gönderme/alma
  - Okundu bilgis
  - Mesaj zaman damgası

- **Bildirim Sistemi**
  - Firebase Cloud Messaging (FCM)
  - Local bildirimler
  - Match bildirimleri
  - Mesaj bildirimleri

- **UI/UX**
  - Modern Material Design 3
  - Dark mode desteği
  - Türkçe arayüz
  - Responsive tasarım
  - Animasyonlar ve geçişler

## 🏗️ Proje Yapısı

```
arkadaslik_uygulamasi/
├── lib/
│   ├── core/
│   │   ├── constants.dart      # Sabitler ve stringler
│   │   ├── theme.dart           # Uygulama teması
│   │   └── utils.dart           # Yardımcı fonksiyonlar
│   ├── models/
│   │   ├── user.dart            # Kullanıcı modeli
│   │   ├── message.dart         # Mesaj modeli
│   │   └── match.dart           # Eşleşme modeli
│   ├── services/
│   │   ├── auth_service.dart    # Firebase Authentication
│   │   ├── database_service.dart # Firestore Database
│   │   ├── storage_service.dart  # Firebase Storage
│   │   ├── location_service.dart # Konum servisleri
│   │   ├── notification_service.dart # Bildirim servisleri
│   │   └── auth_provider.dart   # State Management
│   ├── screens/
│   │   ├── splash_screen.dart   # Splash ekranı
│   │   ├── login_screen.dart    # Giriş ekranı
│   │   ├── register_screen.dart # Kayıt ekranı
│   │   ├── home_screen.dart     # Ana ekran
│   │   ├── discover_screen.dart # Keşfet ekranı
│   │   ├── matches_screen.dart  # Eşleşmeler ekranı
│   │   ├── messages_screen.dart # Mesajlar ekranı
│   │   ├── profile_screen.dart  # Profil ekranı
│   │   ├── edit_profile_screen.dart # Profil düzenleme
│   │   └── chat_screen.dart     # Sohbet ekranı
│   ├── widgets/                 # Reusable widgetlar
│   └── main.dart                # Uygulama giriş noktası
├── android/                     # Android native kodları
├── assets/                      # Resim ve ikonlar
└── pubspec.yaml                 # Bağımlılıklar
```

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK (3.12.0 veya üzeri)
- Dart SDK
- Android Studio / VS Code
- Firebase hesabı

### Adım 1: Firebase Kurulumu

Detaylı kurulum için [FIREBASE_SETUP.md](FIREBASE_SETUP.md) dosyasına bakın.

### Adım 2: Bağımlılıkları Yükle

```bash
flutter pub get
```

### Adım 3: Firebase Config Dosyası

Firebase Console'dan indirdiğiniz `google-services.json` dosyasını:
```
android/app/google-services.json
```
konumuna kopyalayın.

### Adım 4: Uygulamayı Çalıştır

```bash
flutter run
```

## 🔧 Teknoloji Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Provider
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Firebase Storage
  - Cloud Messaging
- **UI Kit**: Material Design 3
- **Location**: Geolocator
- **Maps**: Google Maps Flutter

## 📝 Kullanım

### Kayıt Olma

1. Uygulamayı açın
2. "Kayıt Ol" butonuna tıklayın
3. İsim, e-posta, şifre bilgilerini girin
4. Doğum tarihinizi seçin
5. Cinsiyetinizi seçin
6. "Kayıt Ol" butonuna tıklayın

### Profil Düzenleme

1. "Profil" sekmesine gidin
2. "Profili Düzenle" butonuna tıklayın
3. Fotoğraflarınızı ekleyin
4. Bio ve ilgi alanlarınızı güncelleyin
5. "Kaydet" butonuna tıklayın

### Kişiler Bulma

1. "Keşfet" sekmesine gidin
2. Konum izni verin
3. Kartları sağ/sol kaydırarak beğenin/beğenmeyin
4. Eşleşme durumunu kontrol edin

### Mesajlaşma

1. "Eşleşmeler" veya "Mesajlar" sekmesine gidin
2. Bir kişi seçin
3. Mesajınızı yazın
4. Gönder butonuna tıklayın

## 🛠️ Geliştirme

### Yeni Özellik Ekleme

1. Model'i `lib/models/` altına ekleyin
2. Service'i `lib/services/` altına ekleyin
3. Screen'i `lib/screens/` altına ekleyin
4. Navigation'ı güncelleyin

### Test

```bash
flutter test
```

### Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen pull request gönderin.

## 📞 İletişim

Sorularınız için issue açabilirsiniz.

## ⚠️ Notlar

- Firebase projenin güvenlik kurallarını production'a geçmeden önce güncelleyin
- Google Sign-In için `google_sign_in` paketi eklemeniz gerekebilir
- Gerçek kullanım için daha detaylı validasyon ve hata yönetimi gereklidir

---

**Versiyon**: 1.0.0  
**Son Güncelleme**: 2026-05-22
