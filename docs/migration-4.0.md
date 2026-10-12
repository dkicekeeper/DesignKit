# Moving to DesignKit 4.0

4.0.0 (2026-10) is a major release for one reason: it removes the last deprecated name,
`SectionHeader.Style.list`. Nothing else changes: no component looks different, and no other API
is renamed or removed.

Neither Tenra nor Dalada used `.list` when 4.0.0 shipped, so both move to it by changing the pin
(their daily DesignKit update workflow does it on its own).

## Removed

| Removed | Use | Since |
|---|---|---|
| `SectionHeader(_:style: .list)` | `.compact` | deprecated in 3.2.0, when `.compact` stopped padding itself and took `.list`'s job (a `List` / `Form` section header as it is; on a screen add `.screenPadding()`) |

`.compact` also shows the action (`SectionHeader(title, style: .compact) { … }`), which `.list`
dropped, and both symbols (`systemImage:`, `trailingSystemImage:`).

## Checking an app

```bash
grep -rn "style: .list" --include=*.swift . | grep SectionHeader
```

No output means the app builds on 4.0 unchanged.
