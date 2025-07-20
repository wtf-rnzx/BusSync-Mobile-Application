import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<AppNotification> _notifications = [
    AppNotification(
      id: '1',
      title: 'Welcome to BusSync!',
      message:
          'Thank you for using BusSync. Enable location services for better tracking experience.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: NotificationType.announcement,
      isRead: false,
    ),

    AppNotification(
      id: '2',
      title: 'Bus 1 is arriving!',
      message: 'Bus will be arrive near at your location, be ready!!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      type: NotificationType.busUpdate,
      isRead: false,
    ),

    AppNotification(
      id: '3',
      title: 'System Maintenance!',
      message: 'BusSync will undergo maintenance',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      type: NotificationType.systemAlert,
      isRead: false,
    ),
    // ... other initial notifications ...
  ];

  List<AppNotification> get notifications => _notifications;

  void markAsRead(String id) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  void markAllAsRead() {
    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((notification) => notification.id == id);
  }

  void clearAll() {
    _notifications.clear();
  }

  void refresh() {
    // In a real app, you would fetch from an API here
    _notifications = _notifications.map((notification) {
      if (!notification.isRead) {
        return notification.copyWith(
          timestamp: DateTime.now().subtract(
            Duration(minutes: DateTime.now().minute % 10),
          ),
        );
      }
      return notification;
    }).toList();
  }
}
