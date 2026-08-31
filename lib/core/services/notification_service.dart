import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Plugin'i başlat - sadece ihtiyaç duyulduğunda ilk kez çağrılır
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      final result = await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
        },
      );

      _initialized = (result == true);
      debugPrint('NotificationService: initialized = $_initialized');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      _initialized = false;
    }
  }

  /// Bildirim izni iste
  Future<bool> requestPermission() async {
    try {
      await _ensureInitialized();

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      // iOS için izin isteği
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('Notification permission error: $e');
      return false;
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _ensureInitialized();
      if (!_initialized) return;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'deals_channel',
            'İndirim Bildirimleri',
            channelDescription: 'Yeni indirim ve kupon uyarıları',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService showNotification error: $e');
    }
  }

  Future<void> schedulePriceDropAlert(
    String productName,
    double newPrice,
  ) async {
    try {
      await showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: '📉 Fiyat Düştü!',
        body:
            '$productName ürününde fiyat ${newPrice.toStringAsFixed(2)} TL\'ye düştü! Hemen incele.',
      );
    } catch (e) {
      debugPrint('schedulePriceDropAlert error: $e');
    }
  }
}
