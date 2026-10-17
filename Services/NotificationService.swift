import Foundation
import UserNotifications

// MARK: - Сервис уведомлений

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func notifyNewOrder(table: Int, itemsCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Новый заказ"
        content.body = "Стол \(table): \(itemsCount) позиций"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func notifyOrderReady(table: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Заказ готов"
        content.body = "Стол \(table): можно подавать"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
