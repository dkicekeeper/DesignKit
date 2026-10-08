# DesignKit и крупные дизайн-системы: сравнение (октябрь 2026)

С чем сравнивали: **Apple HIG** (iOS 26), **Material Design 3** (Google), **Fluent 2** (Microsoft,
версия для iOS), **Carbon** (IBM), **Polaris** (Shopify), **Atlassian Design System**. Первые три —
мобильные, последние три — в основном веб, но набор компонентов у всех похож, и пробелы видны
сразу.

## Принцип: что DesignKit делает сам, а что берёт у iOS

DesignKit — дизайн-система поверх SwiftUI, а не замена ему. Системные контролы iOS уже выглядят
как часть платформы (Liquid Glass, Dynamic Type, VoiceOver, RTL), поэтому мы их **не дублируем**,
а используем со своими токенами: `Toggle`, `Picker`, `DatePicker`, `Stepper`, `Slider`, `Menu`,
`.sheet`, `.alert`, `.confirmationDialog`, `TabView`, `NavigationStack`, `.searchable`,
`ShareLink`, `PhotosPicker`, `ProgressView()` (спиннер), подсказки — `TipKit`.

Свой компонент нужен, когда системного нет или когда оба приложения должны выглядеть одинаково
там, где системный вид не подходит (карточки, строки, бейджи, графики, суммы).

Обозначения: ✓ есть · **+** добавлено в этих раундах (0.4.0–0.7.0) · ○ системный компонент iOS ·
— нет · ✗ нет, кандидат.

Таблицы составлены по публичным спискам компонентов систем. Названия и границы компонентов у всех
разные (у Carbon «Tile», у Atlassian «Lozenge», у Fluent «Pill button bar»), поэтому отметка
значит «есть близкий по назначению компонент», а не точное совпадение.

## Компоненты

### Действия

| Компонент | HIG | M3 | Fluent | Carbon | Polaris | Atlassian | DesignKit |
|---|---|---|---|---|---|---|---|
| Кнопка (основная / второстепенная) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `DSButton`, `.dsButton` (2.0.0) |
| Кнопка в состоянии загрузки | — | — | — | ✓ | ✓ | ✓ | **+** `DSButton(isLoading:)` |
| Иконка-кнопка / FAB | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `DSButton(iconPlacement: .only / .top)`, `PlusTabLabel` |
| Сегменты / группа кнопок | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `SegmentedPicker` |
| Меню, кнопка с меню | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `Menu`; ✓ `UniversalFilterButton` |

### Ввод

| Компонент | HIG | M3 | Fluent | Carbon | Polaris | Atlassian | DesignKit |
|---|---|---|---|---|---|---|---|
| Текстовое поле, многострочное | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `FormTextField` (`.multiline`) |
| Поиск | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `.searchable` |
| Чекбокс / радио | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `SelectionIndicator` (+ `tint`) |
| Строка с переключателем | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `ToggleSettingsRow` |
| Чипсы: выбор одного | — | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `ChipPicker` |
| Чипсы: фильтр из нескольких | — | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `ChipPicker(selection: Set)` |
| Дата / время | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `DatePickerRow`, `DateButtons` |
| Слайдер, степпер | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `Slider`, `Stepper` |
| Рейтинг | ✓ | — | — | — | — | — | **+** `Rating`, `RatingPicker` |
| Цвет | ✓ | — | — | — | — | — | ✓ `ColorPickerRow` |
| Файл | ✓ | — | — | ✓ | ✓ | — | ✓ `DocumentPicker` |
| Ввод суммы, калькулятор | — | — | — | — | — | — | ✓ `CalculatorKeypad`, `AmountInput` (специфика финансов) |
| Ввод тегов (token field) | ✓ | ✓ | — | ✓ | ✓ | ✓ | **+** `TagInput` (0.7.0), `FlowLayout` для переноса чипсов |

### Отображение

| Компонент | HIG | M3 | Fluent | Carbon | Polaris | Atlassian | DesignKit |
|---|---|---|---|---|---|---|---|
| Аватар | — | — | ✓ | — | ✓ | ✓ | **+** `Avatar` |
| Группа аватаров | — | — | ✓ | — | — | ✓ | **+** `AvatarGroup`; ✓ `PackedCircleIcons` (облако) |
| Бейдж / тег / лозенж | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `Badge`, `TrendBadge`; ✓ `StatusIndicatorBadge` |
| Карточка | — | ✓ | ✓ | ✓ | ✓ | — | ✓ `cardStyle()`, `FinanceCard`, `InsightsStatCard` |
| Показатель (KPI) | — | — | — | — | — | — | **+** `StatTile` (паттерн дашбордов; нужен Dalada) |
| Строка списка | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `UniversalRow`, `InfoRow`, строки настроек |
| Заголовок секции | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `SectionHeader` (пять стилей, с действием в конце строки) |
| «Показать ещё» для текста | — | — | — | — | — | — | **+** `ExpandableText` (паттерн App Store; отзывы и статьи Dalada) |
| Раскрывающийся блок | ✓ | ✓ | — | ✓ | ✓ | ✓ | ○ `DisclosureGroup` |
| Пустое состояние / ошибка | — | — | — | ✓ | ✓ | ✓ | ✓ `EmptyState` (`.error` с «Повторить») |
| Карусель | — | ✓ | — | — | — | — | ✓ `UniversalCarousel`, `PhotoCarousel` (2.8.0) |
| Графики | ✓ | — | — | ✓ | ✓ | — | ✓ `OrbChart`, датчики; **+** `LineChart`, `BarChart`, `ChartSwitcher`, `Sparkline`, `HeroSparkline` |
| Календарь месяца с отметками | — | ✓ | ✓ | — | ✓ | ✓ | **+** `MonthCalendar` (0.7.0, из Tenra `SubscriptionCalendarView`) |
| Таймлайн (лента событий) | — | — | — | — | — | — | **+** `ActivityTimeline` (0.7.0) |
| Таблица данных | — | — | — | ✓ | ✓ | ✓ | — на телефоне это список |

### Обратная связь и загрузка

| Компонент | HIG | M3 | Fluent | Carbon | Polaris | Atlassian | DesignKit |
|---|---|---|---|---|---|---|---|
| Тост / снэкбар | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `MessageBanner` |
| Снэкбар с действием («Отменить») | — | ✓ | ✓ | ✓ | ✓ | ✓ | **+** `MessageBanner(actionTitle:action:)` |
| Сообщение в потоке / баннер | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `InlineStatusText`, `RecommendationBox` |
| Полоса и кольцо прогресса | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `LinearProgressBar` (**+** `value:`), `ProgressRing` |
| Спиннер | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ `ProgressView()` |
| Скелетон (заглушка загрузки) | — | — | ✓ | ✓ | ✓ | ✓ | **+** `Skeleton`, `SkeletonRow`, `.skeleton(isLoading:)`; плавная смена на контент `SkeletonReveal` (2.3.0) |
| Шаги процесса | — | — | — | ✓ | — | ✓ | **+** `StepTracker` |
| Подсказка / тултип / коучмарк | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ `Tooltip` (2.0.0), `.attentionPulse` (2.2.0), `.spotlight` (2.6.0); ○ `TipKit` для подсказок |
| Индикатор «печатает» | ✓ | — | — | — | — | ✓ | **+** `TypingIndicator` (2.2.0) |
| Праздничный эффект (конфетти) | — | — | — | — | — | — | **+** `.celebration` (2.2.0), `.completionMoment`, `.ripple` (2.3.0) |
| Плавающая кнопка с меню (speed dial) | — | ✓ | ✓ | — | — | — | **+** `GlassActionMenu` (2.3.0, перетекание Liquid Glass) |
| Тактильный отклик по смыслу | ✓ | — | — | — | — | — | **+** `HapticCue` (2.3.0) |
| Диалог, шторка | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ○ системные; ✓ `EditSheetContainer` |
| Запрос разрешения (до системного) | ✓ | — | — | — | — | — | **+** `PromptSheet` (праймер с 0.7.0, с 2.0.0 одна шторка с вопросом, общая для обоих приложений) |
| Онбординг | ✓ | — | — | — | — | ✓ | **+** `OnboardingPager`, `OnboardingPage`, `HeroSymbol` (0.7.0); ✓ шаги Tenra |

### Навигация

Таб-бар, навбар, сайдбар, индикатор страниц, нижняя панель — системные (○). DesignKit добавляет
только `PlusTabLabel` (вкладка-действие «+»). Хлебные крошки и пагинация — веб, на iOS не нужны.

## Токены

| | Крупные системы | DesignKit |
|---|---|---|
| Цвета | Роли: поверхность / контейнер / текст / акцент / статусы (M3: ~30 ролей) | `AppColors`: фоны (`bgBase`, `bgCard`, `bgMuted`), текст (3 уровня), акцент (настраивается, `DesignKitTheme.accent`), статусы (`success`, `warning`, `destructive`), финансовые (`income`, `expense`, `transfer`, `planned`), палитра категорий |
| Типографика | 10–15 стилей, Dynamic Type | `AppTypography`: 10 стилей (h1–h4, body, bodySmall, caption…), Inter, Dynamic Type |
| Отступы | 4/8-pt сетка | `AppSpacing`, 4-pt сетка |
| Скругления | 4–6 ступеней | `AppRadius` |
| Анимация | Токены длительности и кривых (M3 motion, Fluent motion) | `AppAnimation`, уважение Reduce Motion, `AmbientMotionGate` |
| Глубина | Тени / elevation | Liquid Glass (`glassEffect`) вместо теней |

Токены по составу на уровне крупных систем. Отличие — цветовые роли «контейнеров» (M3
`surfaceContainer…`) у нас сведены к трём фонам. Для двух приложений этого хватает, а с третьим
приложением или тёмной темой с несколькими уровнями поверхностей стоит добавить роли.

## Что добавлено в этих раундах

- **0.4.0** — из Dalada и Tenra: `BadgeView`, `TrendBadge`, `StatTile`, `AvatarView`,
  `RatingView` / `RatingPicker`, `ChipPicker`, `LinearProgressBar(value:)`, `SelectionIndicator(tint:)`.
- **0.5.0** — графики трендов на общей модели `ChartPoint`: `LineChart`, `BarChart`,
  `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `ChartSelectionBanner`.
- **0.6.0** — пробелы по сравнению с крупными системами: `SkeletonView` / `.skeleton`,
  `LoadingButtonLabel`, `StepTracker`, `ToggleSettingsRow`, `AvatarGroup`, `ChipPicker` с
  множественным выбором и иконками, `ExpandableText`, `MessageBanner` с действием.
- **0.7.0** — кандидаты прошлого раунда: `PermissionPrimerView` (общий экран запроса
  разрешения, меняет вид экрана в Tenra), `OnboardingPager` / `OnboardingPage` / `HeroSymbol`,
  `MonthCalendar` / `CalendarRange` (из Tenra), `ActivityTimeline`, `TagInput`, `FlowLayout`;
  `OnboardingStepIndicator(symbols:)`; стабильные цвета категорий (`CategoryColors.paletteIndex`).
- **1.0.0** — первая мажорная версия: удалены устаревшие API, которые не использует ни одно
  приложение (`BudgetProgressBar`, `BudgetProgressCircle`, `ExpenseIncomeProgressBar`,
  `DonutChart`, `ChartDisplayMode`, `inlineFieldStyle`, `inlineNoteStyle`). Снапшот-тесты
  покрывают внешний вид компонентов (docs/snapshots.md).
- **1.1.0** — первая партия переноса из Tenra (компоненты, которые нужны только Tenra, с нейтральными
  именами): `TotalsCard`, `LimitProgressCard`, `WeightBreakdownCard`, `CalculationCard`,
  `NetAmountRow`, `ScheduleRow`. Модели Tenra в них не попали: Tenra передаёт данные через
  переходники.
- **1.2.0** — вторая партия: `ComparisonCard`, `CashFlowCard`, `ScoreGaugeCard`, `ScoreCard`,
  `TargetProgressCard`, `RecurringPaymentCard`, `PayoffProgressCard`, `BreakdownRow`,
  `AmountPercentageView`. В Tenra остались переходники со старыми именами.
- **1.3.0** — крупный шрифт (AX1–AX5): `ComparisonCard`, `TotalsCard`, `InsightEntityRow`,
  `BreakdownRow` и `MenuPickerRow` раскладываются в столбик вместо обрезки и переносов посреди
  слова. На обычных размерах вид прежний.
- **1.4.0** — единое правило отступов (design-system.md §10): `ScheduleRow` и `NetAmountRow`
  получили вертикальный отступ пресета строк `.info` (8), как остальные строки.
- **1.5.0** — третья партия: `BalanceCard`, `SelectableBalanceCard`, `BalanceRow`,
  `ProgressRingRow`, `ProgressRingTile` (с `LimitProgress`), `MetricCard`,
  `GradientOrbsBackground`, `PromptSheet`. В Tenra остались переходники со старыми именами.
- **1.5.1** — крупный шрифт в новых строках: в `BalanceRow` сумма начисления встаёт под подпись,
  в `ProgressRingRow` «потрачено», «/ лимит» и доля идут тремя строками вместо «185… / 250…».
- **1.6.0** — семантические цвета v2: группы `AppColors.Text`, `.Background` (уровни `base` /
  `elevation1–3`, нейтральные контейнеры, заливки), `.Status` (со светлыми `…Pale`), `.Border`;
  модификаторы `OnDark` / `OnLight` (одинаковы в обеих темах); `AppColors.pale(_:)`. Старые плоские
  имена — псевдонимы, цвета не изменились.
- **1.7.0** — суммы: скрытие (`.amountsHidden()`, «•••• ₸» во всех `FormattedAmountText`, кнопка
  `AmountVisibilityToggle`), знак `sign: .always` с настоящим минусом «−», валюта кодом, символом
  SF или без неё (`currencyDisplay`); `StatusBanner` (уведомление, которое остаётся на экране, по
  устройству как `RecommendationBox`); `SkeletonText` (заглушка строки по стилю текста);
  `appButton(вид, роль, размер)` поверх системных стилей Liquid Glass; `.fadeTruncation()`.
- **1.8.0** — вид: цифры сумм табличные (`AppTypography.numbers(_:)`, все цифры одной ширины,
  суммы в столбце выравниваются, меняющаяся сумма не прыгает); все цветные подложки бейджей, плашек
  и иконок на `AppColors.pale(_:)` (12% в светлой теме, 24% в тёмной, раньше 10–15% везде по-разному).
  Скрытие сумм дошло до легенды `HeroProportionBar` и подсказки `HeroBarPair`, для своего текста
  приложения есть `Formatting.hiddenAmount(currency:)`.
- **1.10.0** — скелетон у каждого компонента с данными (`BalanceCardSkeleton`, `UniversalRowSkeleton`,
  `LineChartSkeleton`, …, около 70): контейнер и скругление компонента как есть, серые формы
  вместо текста, сумм, иконок и графиков; форма без своего скругления берёт «мягкое»
  `AppRadius.soft`. Один блик на весь скелетон, `.skeletonShimmer(false)` его останавливает.
  Последняя партия из Tenra: `CheckmarkRow` (строка списка выбора в фильтрах),
  `ProgressRingTileGrid` (сетка категорий с суммами), `.carouselItemTransition()`; и компоненты,
  ждавшие хуков: `EditableHero`, `IconPicker` (с каталогом `IconCatalog` на 550 символов и поиском
  на 11 языках), `CurrencyPickerMenu`, `CurrencyAmountInput`, `CurrencyList`. Новые хуки:
  `DesignKitLogoCatalog` (бренды выбора иконки) и `DesignKitCurrencyConverter.convertSync`.
  Экраны фильтров и секции главного экрана остались в Tenra: это экраны над моделями приложения.
- **1.11.0** — `CategoryColors.pickerPalette`: в выборе цвета категории 30 цветов вместо 14
  (14 цветов хеша, затем 16 глубоких и нейтральных оттенков); палитра хеша осталась из 14.
- **1.12.0** — `MessageComposer`: поле сообщения внизу переписки (комментарии, ответы) на Liquid
  Glass, растёт до пяти строк, кнопка отправки внутри, цитата того, на что отвечают, ошибка
  отправки над полем. Вторая партия из Dalada, с нейтральными именами и скелетонами: `PersonRow`,
  `CommentRow` (с цитатой `MessageQuote`), `ThreadCard`, `ReviewCard`, `ReactionButton`,
  `AchievementMedal` / `AchievementTile` / `AchievementProgressRow`, `ChecklistRow` /
  `ChecklistSummaryRow`, `StatsStrip`, `StreakCard`, `ThumbnailCard` / `ThumbnailRow`. Загрузка
  фото, реакции, модерация и каталог достижений остались в Dalada и приходят слотами и строками.
- **1.13.0** — порядок, без новых компонентов и без изменения вида. Размеры иконок — две шкалы с
  именами как у отступов: глифы `AppIconSize.xs…xl` и плашки `AppIconSize.Tile.xs…xxxl`
  (`avatar`, `mega`, `ultra` и другие — устаревшие синонимы тех же значений). `BrandLogoView`
  стал движком `IconView(source: .brandService)`. `primaryButton()`/`secondaryButton()` описаны
  как сокращения `appButton`. Исходники и Gallery разложены по назначению компонента
  (docs/gallery-structure.md, сравнение с HIG, Material 3, Atlassian, Ant); у каждого компонента
  в Gallery своя страница с параметрами и состояниями, скелетон — состояние «Loading».
- **1.14.0** — строка «≈» в `CurrencyAmountInput`: параметр `equivalentCurrency` (валюта счёта:
  сумма в другой валюте показывается в валюте счёта, сумма в собственной иностранной валюте
  счёта в базовой; без параметра в базовой, как раньше). Без курса строка пропадает, а не держит
  прежнее число; одна конвертация за раз, и последний ввод побеждает более медленную старую.
- **1.15.0** — третий круг аудита приложений. `SectionHeaderView` получил действие в конце строки
  (`trailing`: «Все», кнопка, спиннер), которое Dalada собирала вручную в пяти местах. `SliderRow`
  из Tenra: строка настройки со слайдером, значением справа и подсказкой. Компоненты берут
  смысловые цвета `AppColors.Background.*` и `AppColors.Text.*` вместо плоских `bgCard`,
  `textPrimary` и других (вид не меняется); ещё семь компонентов и два скелетона графиков под
  снапшот-тестами.
- **2.0.0** — один компонент на одну вещь. `DSButton`: заголовок с иконкой слева, справа, сверху
  (плитка) или одна иконка, вид × роль × размер, форма, во всю ширину, загрузка; стиль
  `.dsButton` для своей подписи. Он заменяет `appButton`, `primaryButton`/`secondaryButton`,
  `LoadingButtonLabel`, `BulkDeleteButton` и `EntityActionButton`. `SectionHeader` получил стили
  `.list` (бывший `SettingsSectionHeaderView`) и `.card` (бывший `DateSectionHeaderView`);
  `PromptSheet` стал и праймером разрешения (бывший `PermissionPrimerView`): асинхронное главное
  действие с загрузкой, крупнее заголовок и текст. Имена компонентов без `View` и `App`
  (`SectionHeader`, `EmptyState`, `Avatar`, `Badge`, `Icon`, …), старые остались устаревшими
  синонимами; токены (`AppColors`, `AppSpacing`, …) сохранили префикс. 40 pt стали глифом
  `AppIconSize.xxl`: плашка начинается с `Tile.sm` 44, меньше ей не хватает отступов. Удалены
  имена размеров, устаревшие в 1.13.0, и `BrandLogoView`. Новый `Tooltip`: непрозрачная подсказка
  с хвостиком, в нём сумма столбца `HeroBarPair`. Исправлено: `SegmentedPicker` реагирует на
  короткое нажатие (стекло поверх больше не забирает касание), аватары `AvatarGroup` непрозрачны,
  `PackedCircleIcons` рисует символ на бледной подложке его цвета. Переход: docs/migration-2.0.md.
- **2.1.0** — `AmountRow`: одна строка с суммой вместо четырёх. Стиль `.list` (имя `h4`, значение
  под ним: бывшие `BalanceRow` и `ProgressRingRow`) и `.info` (имя `body`, значение справа: бывшие
  `BreakdownRow` и `InsightEntityRow`); значение — сумма, доля или лимит с кольцом вокруг иконки.
  Старые имена стали обёртками с теми же пикселями. Строка с лимитом держит место кольца и без
  лимита, поэтому категории с бюджетом и без него больше не идут лесенкой. `CategoryColors.color(for:)`
  вместо `hexColor(for:)`: метод возвращает цвет, а не hex.
- **2.2.0** — движение и эффекты (docs/motion.md). Пружины по назначению (`snappy`, `smooth`,
  `bouncy`, `expressive`) и бюджеты длительностей. Анимированные SF Symbols по смыслу: символ
  дорисовывается при появлении (Draw из SF Symbols 7) в `HeroSymbol`, `EmptyState`, `StepTracker`,
  отскок на каждое нажатие `DSButton`, покачивание у ошибок, Magic Replace в глазе скрытия сумм
  и в отметках выбора, «дыхание» и «в работе» для живых состояний. Переходы `.popIn`, `.riseIn`,
  `.textReveal`, которые при Reduce Motion становятся растворением. Новые эффекты: конфетти
  `.celebration`, искры `.sparkleBurst` (в `ReactionButton`), блик `.shine`, кольца внимания
  `.attentionPulse`, `AuroraBackground` (живой mesh-градиент), наклон за пальцем
  `.interactiveTilt`, появление при прокрутке `.scrollReveal`, текст по буквам
  `.textRevealOnAppear`, `TypingIndicator`. Всё лёгкое: системные эффекты, Canvas с путями от
  времени, одноразовые эффекты живут только пока играют, циклы под `AmbientMotionGate`;
  `.designKitMotion(false)` останавливает всё.
- **2.3.0** — второй раунд движения. Перетекание Liquid Glass (`GlassActionMenu`), живые суммы
  (`LiveAmountText`: докрутка от нуля и вспышка изменения), графики прорисовываются
  (`.chartDrawIn` в `LineChart`, `BarChart`, `HeroSparkline`), момент завершения
  (`.completionMoment`, `ProgressRing(celebratesCompletion:)`, полосы чек-листа и цели),
  скелетон перетекает в контент (`SkeletonReveal`), хаптики по смыслу (`HapticCue`: тики
  слайдера и сегментов, паттерн праздника), градиентные SF Symbols в героях и пустых
  состояниях, шапка от прокрутки (`.scrollHero`), параллакс в онбординге и рябь на
  Metal-шейдере (`.ripple`). Шейдеры поставляются скомпилированными, приложениям не нужен
  Metal Toolchain.
- **2.4.0** — голос на экране. `VoiceWave`: ленты света в палитре Aurora поднимаются с каждым
  слогом, или жидкий шар (`.orb`), который набухает от голоса; фаза `.thinking` успокаивает
  волну и пускает по ней блик. `EdgeGlow(level:)` вместо `SiriGlow` и `SiriWave`: свет по краю
  экрана на Metal, без размытия, растёт и ускоряется от голоса. `.borderBeam` стал кометой по
  самому контуру, `.thinkingShimmer` переливает текст «Слушаю…», «Анализирую…».
- **2.5.0** — неподвижный свет для фонов. `AuroraBackground(_ spots:)`: пятна цвета по весам в
  одной неподвижной сетке, без размытия, вместо `GradientOrbsBackground`; при смене данных
  сетка перетекает за 0,6 с. `.accentGlow` по умолчанию рисуется полосой Aurora (`.soft` —
  прежний размытый круг). `.grain()` против полос в тёмной теме. Фоны под Liquid Glass не
  двигаются: иначе стекло пересчитывается каждый кадр.
- **2.6.0** — поверхности и моменты. `.holographic()`: голографическая фольга, переливается от
  пальца (вместе с `.interactiveTilt`). `.transition(.dissolve)`: удаление рассыпается в пыль.
  `ScrambleText`: результат «расшифровывается» по буквам. `.spotlight`: коучмарк, экран
  затемняется кроме вырезанного элемента, рядом `Tooltip`.
- **2.7.0** — эффекты внутри карточек: `BalanceCard(isLive:)` (баланс докручивается и
  вспыхивает при изменении), `ScoreGaugeCard` / `ScoreCard(decodesScore:)` (балл «расшифровывается»).
- **2.8.0** — аудит, раунд 4, из Dalada: фото (`PhotoTile`, `PhotoStrip`, `PhotoGrid`,
  `PhotoCarousel`, `PhotoViewer` с масштабом щипком и двойным тапом), картинки для Stories
  (`ShareCardSheet`, `ShareCardFrame`, `ShareCard.Format` / `.Style`), `LiveSessionBar` в
  аксессуаре панели вкладок, `DownloadRow` для офлайн-загрузок, `ArticleBody`,
  `ChipPicker(allTitle:)`, `PersonRow(style: .card)`.
- **2.9.0** — аудит, раунд 4, из Tenra: `TransactionRow` (строка операции и перевода),
  `SnapCardPicker` (выбор карточкой в ряду с доводкой), `OptionCard` / `OptionCardPicker`,
  `StreamingText` (текст по словам с подсветкой), `DateRangePickerSheet`, `.cascadeIn`,
  `PagerArrows`, `.progressOverlay`, `FlowLayout(alignment:)`. Редизайн `PackedCircleIcons`:
  глянцевые шарики (прежний вид — `.flat`). Шкала `HeroHalfGauge` в стеклянной карточке
  рисуется одной картинкой: маркеры больше не просвечивают.
- **3.0.0** — мажорный выпуск: удалены все устаревшие имена (ни одно приложение их не
  использовало), стекло `cardStyle()` рисуется за содержимым (цвета внутри карточек точные),
  `TransactionRow` на крупном шрифте ставит суммы под текст. Для форм Dalada: `StepperRow`,
  `EditSheetContainer(isSaving:)`, строки переключателя и действия без иконки.

Для 1.6.0–1.7.0 смотрели и на дизайн-систему TUI Т-Банка (Figma): как референс устройства токенов
и списка состояний, а не как образец внешнего вида. Вид остаётся своим: Liquid Glass, Inter,
системные цвета iOS.

## Кандидаты на следующие раунды

С октября 2026 правило «двух потребителей» отменено (решение владельца): в DesignKit идёт любой
компонент, который можно сделать общим, с нейтральным именем и API, даже если он нужен одному
приложению. Кандидаты 1–5 прошлого раунда (календарь, запрос разрешения, онбординг, таймлайн,
теги) вошли в 0.7.0.

1. ~~**Роли поверхностей** в `AppColors`~~ — сделано в 1.6.0 (`AppColors.Background`: `base`,
   `baseAlt`, `elevation1–3`, `neutral1–2`, `fill`). С 1.15.0 все компоненты берут `Background.*`
   и `Text.*`.
2. **Поиск с подсказками** (недавние запросы, подсказки под `.searchable`) — если оба приложения
   придут к одинаковому виду.
3. **Фото по ссылке со скелетоном** — с 2.8.0 в DesignKit всё, что показывает фото (`PhotoTile`,
   `PhotoStrip`, `PhotoGrid`, `PhotoCarousel`, `PhotoViewer`), а картинку отдаёт приложение. Осталась
   сама загрузка — `RemotePhoto` Dalada (фото места, улова, отчёта): загрузка
   через кэш приложения, пока грузится — спиннер. В DesignKit понадобится хук загрузки (по образцу
   `DesignKitLogoLoader`), а спиннер сменится скелетоном: это изменение вида в Dalada, решение
   владельца.
4. **Один вид строки со слайдером** — `SliderRow` (1.15.0) повторяет строку Tenra; радиус зоны
   приватности в Dalada свёрстан иначе (жирный заголовок, значение основным цветом). Перевести его
   на `SliderRow` — изменение вида, решение владельца.
5. ~~**Одна строка с суммой**~~ — сделано в 2.1.0 (`AmountRow`, решение владельца). `BalanceRow`, `BreakdownRow`, `InsightEntityRow` и `ProgressRingRow`
   устроены одинаково: слева иконка (или кольцо), заголовок с подзаголовком, справа сумма с
   подписью или долей, все на `UniversalRow(.info)`. Их можно свести к одной `AmountRow` со
   слотом слева и видом подписи справа (подпись, доля, ничего), оставив старые имена тонкими
   обёртками. Пиксели должны совпасть (их держат снапшоты); затрагивает списки Tenra, решение
   владельца. Строки настроек (`NavigationSettingsRow`, `ToggleSettingsRow`, `ActionSettingsRow`,
   `MenuPickerRow`, `DatePickerRow`, `CheckmarkRow`) уже тонкие обёртки `UniversalRow(.settings)`
   по 60–100 строк, как отдельные `Toggle`, `Picker`, `DatePicker` и `NavigationLink` в SwiftUI;
   сводить их в одну не нужно.
