# Копейка — трекер расходов для iOS

Личное приложение для учёта трат, доходов и баланса. Не для App Store, чисто под себя.
ТЗ: `Downloads/kopeyka-tz.md` (на машине, где велась разработка) — базовый MVP описан там,
но проект по ходу дела значительно вырос за рамки исходного ТЗ (см. «Сверх ТЗ» ниже).

## Стек и ограничения

- SwiftUI + Core Data, без внешних зависимостей
- Минимальная версия iOS: **16.0** (потолок — iPhone X)
- Сборка — **бесплатный Apple ID профиль**, не платный Developer Program. Из этого следует:
  - Приложение на устройстве перестаёт запускаться примерно через 7 дней — нужно зайти в
    Xcode и нажать Run заново (пересборка бесплатна, просто ограничение бесплатного профиля)
  - Нет TestFlight, нет публикации в App Store — это осознанно вне скоупа
- Репозиторий: **https://github.com/GUCCIFER-max/Kapeyka** (да, название репо с опечаткой
  относительно имени проекта «Копейка» — так исторически сложилось, не переименовывали,
  чтобы не пересоздавать проект в Xcode)
- Разработка код-стороны шла на Windows (без компилятора Swift), сборка и запуск — на Mac
  через Xcode. Из-за этого в истории коммитов есть несколько раундов чисто компиляторных
  фиксов (см. «Грабли» ниже) — код писался и вычитывался вручную, без возможности
  локально собрать.

## Структура проекта

```
Kopeyka/                       ← корень исходников (Xcode-проект лежит здесь же на Mac,
                                  но сам .xcodeproj не в git — см. «Как собрать» ниже)
├── App/
│   ├── KopeykaApp.swift        — точка входа, @main
│   ├── PersistenceController.swift — стек Core Data, сидинг дефолтных категорий/Settings
│   └── RootView.swift          — TabView + плавающая кнопка «+», онбординг на первом запуске
├── Model/
│   ├── Kopeyka.xcdatamodeld/   — модель Core Data (см. ниже)
│   └── DecimalBridging.swift   — обёртки Decimal поверх NSDecimalNumber (см. «Грабли»)
├── DesignSystem/
│   ├── OKLCHColor.swift        — своя реализация oklch() → RGB (в SwiftUI нет нативной)
│   ├── CategoryPalette.swift   — присвоение hue категориям через золотой угол
│   ├── Theme.swift             — единственный акцентный цвет приложения
│   ├── Typography.swift        — serif (New York) для сумм, обычный шрифт для остального
│   └── Components/             — AmountField, CategoryAvatarView, EmptyStateView,
│                                  PressScaleButtonStyle (переиспользуемые вью)
├── Features/
│   ├── Onboarding/              — 3 слайда при первом запуске, можно пропустить
│   ├── Dashboard/                — баланс, лента операций (расходы+доходы), поиск/фильтр
│   ├── QuickAdd/                  — шит быстрого добавления (Трата/Доход), шаблоны
│   ├── Categories/                — сетка категорий, CRUD категорий и шаблонов
│   ├── Analytics/                 — статистика день/неделя/месяц, Swift Charts
│   └── Profile/                   — уведомления (несколько времён), экспорт-заглушка
└── Shared/
    ├── Formatters/CurrencyFormatter.swift — форматирование сумм («7 500 000,00 сум»)
    ├── Haptics.swift             — вибрация вместо диалогов подтверждения
    └── NotificationManager.swift  — локальные ежедневные напоминания
```

## Модель данных (Core Data)

- **Category** — id, name, hue (Double), letter. Связи: expenses, templates (cascade delete)
- **Expense** — id, amountRaw (→ `.amount: Decimal` через обёртку), currency, date, note?,
  category (optional relationship)
- **Income** — id, amountRaw (→ `.amount: Decimal`), currency, date, source, isDebt (Bool).
  Доход — отдельная сущность, не связана с категориями
- **Template** — id, amountRaw (→ `.amount: Decimal`), label, category (optional relationship)
- **ReminderTime** — id, time (Date). Несколько записей = несколько ежедневных напоминаний
- **Settings** — единственная строка: defaultCurrency (всегда «UZS», переключатель убрали),
  notificationsEnabled

Все `category`-связи у Expense/Template помечены `optional="YES"` на уровне схемы — это
обязательно при наличии uniqueness constraint на Category.id, иначе Core Data не
компилирует модель («cannot have uniqueness constraints and to-one mandatory inverse»).

## Грабли, на которые уже наступили (не повторять)

1. **`NSSortDescriptor(keyPath: \Entity.optionalField, ascending:)` не компилируется** —
   `String?`/`Date?` не соответствуют `Comparable`. Используем строковый
   `NSSortDescriptor(key: "name", ascending:)` везде.
2. **Core Data `Decimal` не имеет скалярного представления** — генерируется всегда как
   `NSDecimalNumber?`, что бы ни стояло в `usesScalarValueType`. Решение: атрибуты названы
   `amountRaw`/`monthlyBudgetRaw` и т.д., а `Model/DecimalBridging.swift` добавляет
   computed-обёртки `var amount: Decimal` поверх них — весь остальной код работает с
   обычным `Decimal`, не зная о подмене.
3. **Каждый файл должен сам импортировать `CoreData`/`Combine`**, если использует их
   символы (`viewContext`, `@Published`, `ObservableObject` и т.д.) — транзитивный импорт
   из другого файла того же таргета не работает.
4. **Список не обновляет отдельную строку после правки объекта**, если строка держит
   `let object: Expense` вместо `@ObservedObject var object: Expense` — обязательно
   `@ObservedObject` для NSManagedObject, который показывается в строке списка.
5. При добавлении файлов в Xcode — **обязательно «Reference files in place»**, не «Copy
   items if needed» — иначе Xcode копирует файлы в свою собственную папку проекта, и
   правки в git-репозитории перестают на что-либо влиять.
6. При создании нового Core Data атрибута/сущности между сессиями — на телефоне проще
   **удалить и переустановить приложение**, чем рассчитывать на лёгкую миграцию (данные
   тестовые, потерять не жалко, а миграция часто требует явных renaming ID).

## Сверх исходного ТЗ (доп. функционал по ходу разработки)

ТЗ описывало бюджет + просто траты. По факту реализовано существенно больше:

- **Баланс вместо месячного бюджета** — доход минус расход, без сброса по месяцам
- **Доходы** (`Income`) — отдельный тип записи (зарплата, перевод, микрозайм), с полем
  «источник» и пометкой «это долг» — они попадают в общий баланс и отдельно суммируются
  на карточке баланса построчно по каждому источнику долга
- **QuickAdd с переключателем Трата/Доход** в одном шите
- **AmountField** — живое форматирование суммы с разрядами при вводе + кнопка очистки
- **Несколько ежедневных напоминаний** (не одно) — каждое своё время, локальные
  уведомления, работает офлайн
- **Своя иконка приложения** — золотая монограмма «К» на тёмном фоне с зелёной точкой
  (`Kopeyka/AppIcon-1024.png` в репозитории; в Xcode залита в слоты Any Appearance / Dark /
  Tinted набора AppIcon)

## Явно не сделано / вне скоупа (см. также ТЗ §3.2, §3.3)

- Виджеты, Siri/Shortcuts, Apple Watch — не начаты
- iCloud-синхронизация — одно устройство, без бэкапа
- Экспорт в CSV — только заглушка на экране Профиля
- Реальный курс конвертации валют — переключателя валют сейчас нет вообще (оставили
  только сум); если понадобится доллар обратно — учитывать, что настоящей конвертации по
  курсу быть не должно по ТЗ, только явный ввод в нужной валюте
- Подключение банковских карт / Open Banking — технически недостижимо для стороннего
  iOS-приложения без партнёрства с банком, обсуждали и отказались в пользу ручного ввода
  + push-напоминаний
- Автотесты — отсутствуют, вся проверка идёт вручную на реальном устройстве

## Как собрать (на Mac)

1. `git clone https://github.com/GUCCIFER-max/Kapeyka.git`
2. В Xcode: File → New → Project → iOS App, любое имя (не обязано совпадать), Storage: None
3. Сохранить проект **рядом** с папкой `Kopeyka/` из репозитория (не внутрь неё)
4. Из сгенерированного шаблона оставить только `Assets.xcassets` и `Preview Content`,
   остальное (`*App.swift`, `ContentView.swift`) удалить
5. Add Files to Project → выбрать папки `App`, `DesignSystem`, `Features`, `Model`,
   `Shared` из `Kopeyka/` → **Reference files in place** (не Copy)
6. Target → General → Minimum Deployments → iOS 16.0
7. Signing & Capabilities → выбрать Team (личный Apple ID для бесплатного профиля)
