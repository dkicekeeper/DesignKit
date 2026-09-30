# Gallery в TestFlight

Каждое обновление DesignKit в `main` (изменения в `Sources/`, `Gallery/`, `Package.swift`)
собирает Gallery и загружает её в TestFlight: workflow **TestFlight**
(`.github/workflows/testflight.yml`). Mac не нужен — сборка идёт на Mac в GitHub Actions,
подпись облачная по ключу App Store Connect API (так же, как у Dalada).

- **Версия** сборки = последний тег DesignKit (`0.2.0`), **номер сборки** = номер запуска
  workflow.
- **What to Test** заполняется сам: коммиты DesignKit с предыдущего тега.
- В самой Gallery снизу видны версия и номер сборки, а справа вверху — переключатель темы
  **Tenra / Dalada** (акцент каждого приложения).
- Вручную: GitHub → Actions → **TestFlight** → Run workflow.

Пока секреты не заданы, workflow на пушах пропускает загрузку (в логе — notice), а ручной
запуск падает с перечнем недостающего.

## Один раз: настройка (~10 минут, в браузере)

### 1. Приложение в App Store Connect

API App Store Connect не умеет создавать приложения — это делается руками один раз.

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → «+» → **New App**:
- Platform: **iOS**; Name: «DesignKit Gallery» (если занято — любое другое, например
  «Dkicekeeper DesignKit»; пользователям TestFlight оно видно, в App Store не публикуется);
- Primary Language: English или Russian;
- Bundle ID: **`dakacom.DesignKitGallery`**. Если его нет в списке — один раз запустите workflow
  (Actions → TestFlight → Run workflow): он зарегистрирует идентификатор и остановится на
  отсутствии приложения; после этого идентификатор появится в списке;
- SKU: `designkit-gallery`; User Access: Full Access.

### 2. Ключ App Store Connect API

Подойдёт **тот же ключ, что у Dalada** (роль Admin). Нужны его Issuer ID, Key ID и содержимое
`.p8`. Если файла `.p8` уже нет (скачать можно только один раз) — создайте новый ключ:
**Users and Access** → **Integrations** → **App Store Connect API** → **Team Keys** → «+»,
Access: **Admin**, и обновите секреты и в Dalada, и здесь (или держите два ключа).

### 3. Секреты в репозитории DesignKit

GitHub → DesignKit → **Settings** → **Secrets and variables** → **Actions** →
**New repository secret**:

| Имя | Значение |
|-----|----------|
| `ASC_ISSUER_ID` | Issuer ID |
| `ASC_KEY_ID` | Key ID |
| `ASC_KEY_P8` | Всё содержимое `.p8`-файла вместе со строками `-----BEGIN PRIVATE KEY-----` / `-----END PRIVATE KEY-----` |

### 4. Тестировщики

App Store Connect → DesignKit Gallery → **TestFlight** → **Internal Testing** → «+» → группа →
добавить себя. Включите **Automatic Distribution** — новые сборки будут приходить сами. На
iPhone — приложение **TestFlight**, вход тем же Apple ID.

После настройки запустите workflow вручную один раз (или дождитесь следующего изменения в
`main`) — через 10–30 минут сборка появится в TestFlight.

## Если сборка не загрузилась

| Сообщение в логе | Что сделать |
|---|---|
| `No App Store Connect app with bundle id …` | Шаг 1 |
| `HTTP 401/403`, «needs the Admin role» | Ключ не Admin или секреты перепутаны — шаги 2–3 |
| `Missing secrets: …` | Шаг 3 |
| Ошибка 90474 (ориентации) / 90713 (иконка) | Настройки в `Gallery/project.yml` и `Assets.xcassets` — их проверяет Apple при загрузке |
| `The bundle version must be higher…` | Номер сборки уже занят (например, загрузкой из Xcode) — запустите workflow ещё раз |
