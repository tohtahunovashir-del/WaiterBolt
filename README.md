# WaiterBolt — приложение для официантов

## Требования
- macOS 14+ с Xcode 15+
- iOS 17+ (SwiftData)
- Swift 5.9+

## Запуск
1. Создайте новый проект в Xcode: File → New → Project → App (SwiftUI, Swift, SwiftData).
2. Удалите сгенерированные файлы (ContentView.swift, *App.swift).
3. Скопируйте все файлы из папок Models/Services/ViewModels/Views/Components/Utilities в проект, сохранив структуру групп.
4. Добавьте `Info.plist` настройки (камера/фото) через Project → Info.
5. Убедитесь, что Deployment Target = iOS 17.0.
6. Соберите и запустите на симуляторе/устройстве.

## Внешние библиотеки
Не используются — только стандартные фреймворки (SwiftUI, SwiftData, Vision, UserNotifications, PhotosUI).

## Структура
- Models/ — SwiftData модели
- Services/ — DataService, OCRService, NotificationService
- ViewModels/ — MVVM логика
- Views/ — экраны
- Components/ — переиспользуемые UI-компоненты
- Utilities/ — расширения
