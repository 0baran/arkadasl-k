import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Local notifications initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler
        debugPrint('Bildirime tıklandı: ${response.payload}');
      },
    );

    // Firebase messaging initialization & Permissions (Tüm telefonlar için Android 13+ izin kontrolü)
    NotificationSettings fcmSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (fcmSettings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM İzni verildi. Bildirimler alınabilir.');
    } else {
      debugPrint('FCM İzni reddedildi veya sağlanmadı.');
    }

    // Configure foreground messages
    configureFirebaseMessaging();
  }

  Future<String> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      return token ?? '';
    } catch (e) {
      debugPrint('FCM token alınamadı: $e');
      return '';
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Topic aboneliği başarısız: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Topic aboneliği iptal edilemedi: $e');
    }
  }

  Future<void> showMatchNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.matchChannel,
      'Eşleşmeler',
      channelDescription: 'Yeni eşleşme bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.messageChannel,
      'Mesajlar',
      channelDescription: 'Yeni mesaj bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
      title,
      body,
      details,
    );
  }

  Future<void> showLikeNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.likeChannel,
      'Beğeniler',
      channelDescription: 'Beğeni bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.low,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2,
      title,
      body,
      details,
    );
  }

  Stream<String> get onMessage {
    return FirebaseMessaging.onMessage.map((message) {
      return message.notification?.body ?? '';
    });
  }

  void configureFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Arka planda değil de uygulama açıkken (Foreground) Firebase'den gelen bildirimler
      if (message.notification != null) {
        showMatchNotification(
          title: message.notification?.title ?? 'Bildirim',
          body: message.notification?.body ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Kullanıcı bildirime tıkladı: ${message.messageId}');
    });
  }
}
