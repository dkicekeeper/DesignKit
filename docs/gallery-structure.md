# Структура DesignKit и Gallery

Как устроены разделы крупных дизайн-систем, и как по этим принципам разложены компоненты
DesignKit: в Gallery, в `docs/design-system.md` и в папках `Sources/DesignComponents/`.
Решение владельца (октябрь 2026): одна раскладка по назначению компонента вместо разделов,
которые росли по мере переноса из приложений.

## Что было не так

- Раздел «Components» — 38 страниц подряд, без порядка: карточки, строки, заголовки и баннеры
  вперемешку.
- Одни и те же виды компонентов в разных разделах: карточки в «Components», «Balances»,
  «Badges & Stats», «Community»; строки в «Components», «Forms», «Balances», «Community»,
  «Patterns»; графики в «Inputs & Charts», «Trend Charts», «Balances».
- Скелетоны — отдельным экраном, а не состоянием своего компонента.
- Параметры компонента не переключаются: на странице один-два готовых примера.
- Заголовок и описание стоят вплотную к компоненту и сливаются с ним.
- В исходниках то же: `FormattedAmountText` и `SelectableBalanceCard` лежат в `Input/`,
  `SiriGlow` в `Charts/`, `PlusTabLabel` в `Feedback/`, `IconPicker` в `Icons/`.

## Как устроены крупные системы

| Система | Разделы компонентов | Принцип |
|---|---|---|
| Apple HIG | Content · Layout and organization · Menus and actions · Navigation and search · Presentation · Selection and input · Status · System experiences | по назначению: что компонент делает для человека |
| Material 3 | Actions · Communication · Containment · Navigation · Selection · Text inputs | по назначению; карточки, списки, листы — «Containment» |
| Atlassian | Forms and inputs · Images and icons · Labels · Layout and structure · Loading · Messaging · Navigation · Overlays and layering · Primitives · Status indicators · Text and data display | по назначению, мельче; отдельно «Primitives» и «Loading» |
| Ant Design | General · Layout · Navigation · Data Entry · Data Display · Feedback · Other | по назначению; ввод и отображение данных разведены |

Общее у всех:
1. **Основы отдельно от компонентов**: цвета, типографика, отступы, иконки, движение.
2. **Разделы по назначению, а не по форме и не по приложению**: «действия», «ввод», «выбор»,
   «статус», «навигация», «отображение данных». Где компонент живёт в приложении (баланс,
   сообщество), на раздел не влияет.
3. **Один вид компонента — в одном разделе**: все кнопки вместе, все поля ввода вместе.
   Карточки и списки — контейнеры (Material: Containment, Atlassian: Layout and structure).
4. **Раздел — 5–15 компонентов.** Больше — делят (Ant: Data Entry 18 и Data Display 21 —
   самые крупные, и их читать труднее всего).
5. **Страница компонента**: название и одна фраза о назначении → живой пример → параметры
   и состояния (Storybook controls у Atlassian, Polaris, Carbon) → правила использования.
   Скелетон, ошибка, пусто, выключено — **состояния компонента** на его странице. Отдельный
   раздел «Loading» (Atlassian) — только для примитивов: spinner, skeleton, progress bar.

## Новая раскладка

Основы (6): **Colors**, **Typography**, **Spacing & Radius**, **Icon Sizes**, **Surfaces**
(`cardStyle`, `formCardStyle`, `filterChipStyle`, стекло), **Motion** (пружины по назначению,
длительности, анимации SF Symbols, переходы `.popIn` / `.riseIn`, проявление текста, появление при
прокрутке, появление контента, `AmbientMotionGate`; docs/motion.md).

Компоненты (17 разделов, 4–13 страниц в каждом):

| Раздел | Компоненты | Аналог |
|---|---|---|
| **Actions** | `DSButton` (иконка слева, справа, сверху или одна; вид × роль × размер, форма, загрузка), `.dsButton`, `.bounce`, `ReactionButton`, `AmountVisibilityToggle`, `UniversalFilterButton` | M3 Actions, HIG Menus and actions |
| **Text Input** | `FormTextField`, `AnimatedTitleInput`, `MessageComposer`, `TagInput` | M3 Text inputs |
| **Selection** | `SegmentedPicker`, `ChipPicker`, `RatingPicker`, `SelectionIndicator`, `DateButtons`, `IconPicker` | M3 Selection, HIG Selection and input |
| **Amounts & Currency** | `AmountInput`, `CalculatorKeypad`, `CalculatorAmountDisplay`, `AmountDigitDisplay`, `CurrencyAmountInput`, `CurrencyPickerMenu`, `CurrencyList`, `FormattedAmountText`, `ConvertedAmount`, `SpentBudgetText`, `AmountPercentage`, `RedactableAmount` | своя область DesignKit (у Polaris — Money) |
| **Rows: Settings & Forms** | `UniversalRow`, `InfoRow`, `NavigationSettingsRow`, `ToggleSettingsRow`, `ActionSettingsRow`, `MenuPickerRow`, `SliderRow`, `DatePickerRow`, `ColorPickerRow`, `CheckmarkRow`, `DisclosureChevron` | M3 Lists |
| **Rows: Data** | `AmountRow` (с 2.1.0 вместо `BalanceRow`, `BreakdownRow`, `ProgressRingRow`, `InsightEntityRow`), `NetAmountRow`, `ScheduleRow`, `PersonRow`, `CommentRow`, `ChecklistRow`, `ChecklistSummaryRow`, `ThumbnailRow` | M3 Lists, Ant Data Display |
| **Cards: Money** | `BalanceCard`, `SelectableBalanceCard`, `FinanceCard`, `CashFlowCard`, `TotalsCard`, `ComparisonCard`, `RecurringPaymentCard`, `CalculationCard`, `WeightBreakdownCard` | M3 Containment |
| **Cards: Progress & Stats** | `LimitProgressCard`, `TargetProgressCard`, `PayoffProgressCard`, `ScoreCard`, `ScoreGaugeCard`, `MetricCard`, `InsightsStatCard`, `StatTile`, `StatsStrip`, `StreakCard`, `ProgressRingTile`, `ProgressRingTileGrid` | Ant Statistic, Data Display |
| **Cards: Content** | `ThreadCard`, `ReviewCard`, `ThumbnailCard`, `RecommendationBox`, `EmptyCard` | M3 Containment |
| **Charts** | `LineChart`, `BarChart`, `ChartSwitcher`, `HeroSparkline`, `Sparkline`, `OrbChart`, `ChartSelectionBanner`, `ChartZoomControls` | HIG Content (Charts) |
| **Progress & Gauges** | `LinearProgressBar`, `ProgressRing`, `ProportionBar`, `MiniProportionBar`, `HeroProportionBar`, `AmountComparisonBar`, `MiniDonut`, `MiniHalfGauge`, `HeroHalfGauge`, `MiniMilestoneGauge`, `HeroMilestoneGauge`, `MiniBarPair`, `HeroBarPair` | HIG Status (gauges, progress) |
| **Status & Feedback** | `Badge`, `TrendBadge`, `StatusIndicatorBadge`, `StatusBanner`, `MessageBanner`, `InlineStatusText`, `Tooltip`, `TypingIndicator`, `EmptyState`, `StepTracker`, `ImportProgressSheet`, примитивы скелетонов (`Skeleton`, `SkeletonText`, `SkeletonRow`) | M3 Communication, Atlassian Messaging + Loading |
| **Headers & Navigation** | `SectionHeader` (пять стилей, с 2.0.0 и `.list`, `.card`), `HeroSection`, `UniversalCarousel`, `OnboardingStepIndicator`, `PlusTabLabel` | M3 Navigation, HIG Navigation and search |
| **Media & Identity** | `Icon` (символы, картинки, логотипы брендов), `Avatar`, `AvatarGroup`, `HeroSymbol`, `PackedCircleIcons`, `AchievementMedal`, `AchievementTile`, `AchievementProgressRow`, `ThumbnailPlaceholder` | Atlassian Images and icons |
| **Content & Layout** | `ExpandableText`, `ActivityTimeline`, `MonthCalendar`, `FlowLayout`, `FormSection`, `EditSheetContainer`, `EditableHero` | HIG Layout and organization |
| **Sheets & Flows** | `PromptSheet` (и праймер разрешения), `NotificationPermissionPrompt`, `OnboardingPager`, `OnboardingPage`, `LoopOnboardingHero` | HIG Presentation, M3 Containment (sheets) |
| **Effects** | `.celebration`, `.sparkleBurst`, `.shine`, `.attentionPulse`, `AuroraBackground`, `.interactiveTilt` (2.2.0), `GradientOrbsBackground`, `SiriGlow`, `SiriWave`, `.accentGlow`, `.borderBeam` / `.borderGlow` | — (своё: Liquid Glass, Siri) |

Правило для нового компонента: раздел выбирается по тому, **что компонент делает**
(действие, ввод, выбор, показ данных, статус, навигация), а если это строка или карточка — по
виду контейнера (Rows, Cards). Карточки и строки делятся на подразделы, когда их больше 12.

## Страница компонента в Gallery

Сверху вниз, каждый блок отделён:

1. **Шапка**: название, одна фраза о назначении, с какой версии, кто использует (Tenra,
   Dalada). Отделена от примера линией и отступом.
2. **Пример** на холсте (светлая подложка с рамкой): компонент в текущих параметрах.
3. **Параметры**: переключатели, сегменты, ползунки — то, что принимает компонент.
   Первая строка — **состояние**: обычное, загрузка (скелетон компонента), пусто, ошибка,
   выключено — какие есть у компонента.
4. **Как использовать**: пара строк из `design-system.md`, если есть правило.

Экрана «Skeletons» больше нет: скелетон — состояние «Loading» на странице своего компонента.
Снапшот-тесты скелетонов остаются как были.

## Папки исходников

`Sources/DesignComponents/` раскладывается так же, как Gallery: `Actions/`, `TextInput/`,
`Selection/`, `Amounts/`, `Rows/`, `Cards/`, `Charts/`, `Progress/`, `Feedback/`,
`Navigation/`, `Media/`, `Content/`, `Sheets/`, `Effects/`. Модуль один, так что перенос файла
API не меняет.
