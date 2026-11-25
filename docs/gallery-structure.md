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

**Поиск, пресеты, контекст** (vNext). Над главной — поиск: по именам страниц компонентов
(совпадение, начало, вхождение; скелетон, старое имя с `View` и `.ds` ведут к компоненту, как
ссылки из релизов) и по словам их описаний, плюс экраны основ по названию; ничего не нашлось —
`ContentUnavailableView.search`. В меню справа — пресет приложения: Tenra (индиго, стекло),
Dalada (зелёный, серые карточки), Platina (Плазма, серые карточки) или «Свой» — акцент из
`ColorPicker` и стекло или серое. На панели холста каждой страницы рядом с темой — контекст:
«Screen» (как есть), «Card» (в `cardStyle()` текущих поверхностей), «On colour» (на акценте,
`\.heroTone = .onColor`): так видно, как компонент ведёт себя в карточке и на цвете.

Первая строка главной — **Updates** (номер последней версии справа): все релизы из
`CHANGELOG.md` по убыванию, сгруппированные по мажорной версии, с поиском по тексту. Строка
релиза: версия, «Major» у мажорных, о чём релиз, дата и метки «Removals», «Visual changes»,
«Migration», если такие разделы есть. Страница релиза: разделы Added / Changed / Deprecated /
Removed / Fixed / Migration / Gallery and tooling (текст через `ArticleBody`, код моноширинным
блоком) и «In the Gallery» — чипы со страницами компонентов, которые релиз называет в
`` `коде` ``. Индекс «имя → страница» строится из самих страниц (`ComponentIndex`, как счётчики
`ShowcaseCount`): имя с аргументами, скелетон, старое имя с `View` и `.dsSearchSuggestions`
ведут на страницу компонента, а `ShowcasePage` открывается на ней (`showcaseInitialPage`).
Бейдж «since X» в шапке страницы компонента открывает заметки той версии. Файл тот же, что
заметки GitHub Release: `Gallery/project.yml` кладёт его в бандл, `ChangelogTests` проверяет,
что он читается.

Основы (6): **Colors**, **Typography**, **Spacing & Radius**, **Icon Sizes**, **Surfaces**
(`SurfaceStyle`: стекло или серая заливка, 8.12.0; `cardStyle`, `formCardStyle`,
`filterChipStyle`), **Motion** (пружины по назначению,
длительности, анимации SF Symbols, переходы `.popIn` / `.riseIn`, проявление текста, появление при
прокрутке, появление контента, `AmbientMotionGate`; с 2.3.0 прорисовка графиков `.chartDrawIn`,
`SkeletonReveal`, `.scrollHero`, хаптики `HapticCue`; docs/motion.md).

Компоненты (17 разделов, 4–16 страниц в каждом). Число справа в строке раздела на главной
Gallery — сколько в нём компонентов; оно считается из самих страниц раздела (`ShowcaseCount`
по `static var pages` экрана, каждая `ComponentPage` помечена), так что вписывать его руками
не нужно и оно не устаревает.

| Раздел | Компоненты | Аналог |
|---|---|---|
| **Actions** | `DSButton` (иконка слева, справа, сверху или одна; вид × роль × размер, форма, загрузка), `.dsButton`, `.bounce`, `ReactionButton`, `GlassActionMenu` (2.3.0), `AmountVisibilityToggle`, `UniversalFilterButton`, `SuggestionChips` (4.6.0), `VoiceOrbButton` (4.14.0) | M3 Actions, HIG Menus and actions |
| **Text Input** | `FormTextField`, `AnimatedTitleInput`, `MessageComposer`, `TagInput`, `SearchSuggestions` (`.dsSearchSuggestions`, 3.5.0) | M3 Text inputs |
| **Selection** | `SegmentedPicker`, `ChipPicker`, `Rating` / `RatingPicker`, `SelectionIndicator`, `DateButtons`, `IconPicker`, `SnapCardPicker`, `OptionCardPicker` (2.9.0), `PickerCarousel` (4.14.0), `SearchablePicker` (8.9.0) | M3 Selection, HIG Selection and input |
| **Amounts & Currency** | `AmountInput`, `CalculatorKeypad`, `CalculatorAmountDisplay`, `AmountDigitDisplay`, `CurrencyAmountInput`, `CurrencyPickerMenu`, `CurrencyList`, `FormattedAmountText`, `LiveAmountText` (2.3.0), `ConvertedAmount`, `SpentBudgetText`, `AmountPercentage`, `RedactableAmount`, `CurrencyRow` (3.6.0) | своя область DesignKit (у Polaris — Money) |
| **Rows: Settings & Forms** | `UniversalRow` (7.0.0: каждая строка формы и настроек, аксессуары `.info`, `.toggle`, `.navigation`, `.action`, `.checkmark`, `.menu`, `.picker`, `.date`, `.stepper`, `.slider`, `.colors`, `.textField`; двенадцать отдельных строк, от `InfoRow` до `ColorPickerRow`, удалены в 7.0.0), `DisclosureChevron` | M3 Lists |
| **Rows: Data** | `AmountRow` (с 2.1.0 вместо `BalanceRow`, `BreakdownRow`, `ProgressRingRow`, `InsightEntityRow`), `NetAmountRow`, `ScheduleRow`, `PersonRow`, `CommentRow`, `ChecklistRow`, `ChecklistSummaryRow`, `ThumbnailRow`, `DownloadRow` (2.8.0), `TransactionRow` (2.9.0), `ItemRow`, `MetaLine` (3.6.0) | M3 Lists, Ant Data Display |
| **Cards: Money** | `BalanceCard`, `SelectableBalanceCard`, `HoldingCard` (8.2.0), `FinanceCard`, `CashFlowCard`, `TotalsCard`, `ComparisonCard`, `RecurringPaymentCard`, `CalculationCard`, `WeightBreakdownCard` | M3 Containment |
| **Cards: Progress & Stats** | `LimitProgressCard`, `TargetProgressCard`, `PayoffProgressCard`, `ScoreCard`, `ScoreGaugeCard` (стиль `.hero` с 4.2.0, «Open as a screen» показывает его на экране), `MetricCard`, `InsightsStatCard`, `StatTile`, `StatsStrip`, `StreakCard`, `ProgressRingTile`, `ProgressRingTileGrid` | Ant Statistic, Data Display |
| **Cards: Content** | `ThreadCard`, `ReviewCard`, `ThumbnailCard`, `RecommendationBox`, `EmptyCard`, `RatingSummary` (4.1.0) | M3 Containment |
| **Charts** | `LineChart`, `BarChart`, `ChartSwitcher`, `CalendarHeatmap` (8.3.0), `HeroSparkline`, `Sparkline`, `OrbChart`, `ChartSelectionBanner`, `ChartZoomControls` | HIG Content (Charts) |
| **Progress & Gauges** | `LinearProgressBar`, `ProgressRing`, `ProportionBar`, `MiniProportionBar`, `HeroProportionBar`, `AmountComparisonBar`, `MiniDonut`, `MiniHalfGauge`, `HeroHalfGauge` (стиль `.bleed` и тон с 4.2.0), `MiniMilestoneGauge`, `HeroMilestoneGauge`, `MiniBarPair`, `HeroBarPair`, `MiniBars` (8.3.0) | HIG Status (gauges, progress) |
| **Status & Feedback** | `Badge`, `TrendBadge`, `StatusIndicatorBadge`, `StatusBanner`, `MessageBanner`, `InlineStatusText`, `Tooltip`, `.spotlight` (2.6.0), `TypingIndicator`, `EmptyState`, `StepTracker`, `ImportProgressSheet`, `.progressOverlay` (2.9.0), примитивы скелетонов (`Skeleton`, `SkeletonText`, `SkeletonRow`), `PendingItemCard` (3.6.0), `LoadMoreFooter` (4.1.0), `.dsRefreshable` · `RefreshIndicator` (vNext), `NoticeCard` (4.14.0), `InfoTip` (8.9.0), `MomentOverlay` и `MomentPresenter` (8.18.0) | M3 Communication, Atlassian Messaging + Loading |
| **Headers & Navigation** | `SectionHeader` (три стиля, `.card` с 2.0.0; с 3.2.0 иконки до и после заголовка в каждом, `.list` стал `.compact`, удалён в 4.0.0; `.compact` удалён в 8.0.0), `HeroSection`, `UniversalCarousel`, `OnboardingStepIndicator`, `PlusTabLabel`, `CreatureTabLabel` (4.8.0), `LiveSessionBar` (2.8.0), `PagerArrows` (2.9.0) | M3 Navigation, HIG Navigation and search |
| **Media & Identity** | `Icon` (символы, картинки, логотипы брендов), `Avatar`, `AvatarGroup`, `HeroSymbol`, `PackedCircleIcons`, `AchievementMedal`, `AchievementTile`, `AchievementProgressRow`, `ThumbnailPlaceholder`, `SquareImageCropper` (8.5.0), фото (2.8.0: `PhotoTile`, `PhotoStrip`, `PhotoGrid`, `PhotoCarousel`, `PhotoViewer`; 3.1.0: `RemotePhoto`), `ShareCardFrame`, `ParticleCreature` (4.6.0), `CreatureGlyph` (4.8.0) | Atlassian Images and icons |
| **Content & Layout** | `ExpandableText`, `ActivityTimeline`, `MonthCalendar`, `FlowLayout`, `FormSection`, `CardList` (8.0.0), `EditSheetContainer`, `EditableHero`, `ArticleBody` (2.8.0), `MessageBubble` (4.6.0), `ConversationDivider`, `RelativeTime` (8.9.0), `.readableWidth()` · `AppLayout` (8.13.0), `AdaptiveColumns` (8.15.0); `FormSection`'s glass style took 4.14.0's `ListCard` page (5.0.0), and since 8.0.0 every section is glass (or the grey of `SurfaceStyle.fill`, 8.12.0) | HIG Layout and organization |
| **Sheets & Flows** | `PromptSheet` (и праймер разрешения), `NotificationPermissionPrompt`, `OnboardingPager`, `OnboardingPage`, `OnboardingPageContainer`, `LoopOnboardingHero`, `ShareCardSheet` (2.8.0), `DateRangePickerSheet` (2.9.0), `AmountEntrySheet` (4.14.0) | HIG Presentation, M3 Containment (sheets) |
| **Effects** | `.celebration`, `.sparkleBurst`, `.shine`, `.attentionPulse`, `AuroraBackground`, `.interactiveTilt` (2.2.0), `.completionMoment`, `.ripple` / `.rippleOnTap` (2.3.0), `VoiceWave`, `EdgeGlow` (вместо `SiriGlow`, `SiriWave`, удалены в 3.0.0), `.thinkingShimmer` (2.4.0), `.grain` (2.5.0), `.holographic`, `.dissolve` (2.6.0), `.accentGlow`, `.borderBeam` / `.borderGlow`, `.heroBackground` (4.5.0), `.heroBackground(picture:)` (8.14.0) | — (своё: Liquid Glass, Siri) |

Последний раздел главной — **Patterns** (8.17.4, docs/benchmark.md 24): целые экраны из
компонентов, как их описывает §4 design-system.md, на образцах данных и без модели приложения.
Настройки (`FormSection` из `UniversalRow`, экран выбора с галочкой), деталь (`HeroSection`,
две `DSButton`, факты в `FormSection`, день истории из `TransactionRow`), то, что человек хранит
(`CardList` с панелью, его скелетон, `EmptyState` пустой и с ошибкой — переключатель состояния
внизу), дашборд (`StatsStrip`, `BalanceCard` в карусели, `CashFlowCard`, `ProgressRingTileGrid`),
переписка (`MessageBubble`, `ConversationDivider`, `TypingIndicator`, `SuggestionChips`,
`MessageComposer`), шторка редактирования (`EditSheetContainer` над `FormSection`,
`InlineStatusText`) и онбординг (`OnboardingPager`). Страниц компонентов в нём нет, поэтому
справка (docs/components.md) и бейджи его не читают; каждый экран держит `.readableWidth()`.
Новый паттерн — экран в `PatternsScreen.swift` и строка в его списке, только из публичных
компонентов DesignKit.

Правило для нового компонента: раздел выбирается по тому, **что компонент делает**
(действие, ввод, выбор, показ данных, статус, навигация), а если это строка или карточка — по
виду контейнера (Rows, Cards). Карточки и строки делятся на подразделы, когда их больше 12.

## Страница компонента в Gallery

Сверху вниз, каждый блок отделён:

1. **Шапка**: название, одна фраза о назначении, стили (значения параметра `style:`,
   `ComponentPage(styles:)`: «3 styles: default · large · card»; только у
   компонентов с таким параметром), с какой версии (бейдж ведёт на заметки версии в Updates),
   кто использует (Tenra, Dalada, Platina: `apps:`). Отделена от примера линией и отступом. Бейджи
   приложений сверяет с их кодом задание CI «Gallery badges» (5.2.0,
   `.github/scripts/gallery_badges.py`): приложение стоит на странице, если его Swift-код
   называет компонент (вне комментариев и строк); имя, под которым приложение берёт компонент
   (`.dsSearchSuggestions` у `SearchSuggestions`, хук `DesignKitTheme.surface` у `SurfaceStyle`),
   — в `ALIASES` скрипта. Если у приложения есть свой тип с тем же именем (модель `Avatar` в
   Platina), засчитывается только файл, который импортирует модуль DesignKit. Platina читается с
   8.17.1. `gallery_badges.py fix --tenra … --dalada … --platina …` переписывает бейджи сам.
2. **Пример** на холсте (серая подложка с рамкой, на ней видно стекло; при поверхностях
   Fill — страница приложения, белая или чёрная): компонент в текущих параметрах. Акцент
   (Tenra / Dalada / Platina) и поверхности (Glass / Fill, 8.12.0) переключаются в меню на главной и
   перерисовывают все страницы.
3. **Параметры**: переключатели, сегменты, ползунки — то, что принимает компонент.
   Первая строка — **состояние**: обычное, загрузка (скелетон компонента), пусто, ошибка,
   выключено — какие есть у компонента.
4. **Как использовать**: пара строк из `design-system.md`, если есть правило.
5. **Do and don't** (8.9.0): как надо и как не надо, по строке (`ComponentPage(dos:donts:)`). Эти
   строки, заметки, версия и приложения страницы попадают в docs/components.md и
   docs/components.json (`.github/scripts/components_reference.py`; их пишет релизный бот после
   каждого слияния, PR их не трогает, docs/releasing.md).

Экрана «Skeletons» больше нет: скелетон — состояние «Loading» на странице своего компонента.
Снапшот-тесты скелетонов остаются как были.

## Папки исходников

`Sources/DesignComponents/` раскладывается так же, как Gallery: `Actions/`, `TextInput/`,
`Selection/`, `Amounts/`, `Rows/`, `Cards/`, `Charts/`, `Progress/`, `Feedback/`,
`Navigation/`, `Media/`, `Content/`, `Sheets/`, `Effects/`. Модуль один, так что перенос файла
API не меняет.
