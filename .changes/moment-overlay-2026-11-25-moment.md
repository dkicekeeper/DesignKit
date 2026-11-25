---
bump: minor
---
A moment of success over the whole app, without a card: the screen dims and blurs, a hero springs in at the centre with a title and a line under it, confetti for a celebration, the buttons at the bottom. For Tenra's assistant: Ten appears over the app when a goal is reached, a debt is settled or an accessory is earned. And `ProgressOverlay` takes a hero in its spinner's place (Ten at work over a backup's restore).

### Added

- `MomentOverlay(title:message:celebrates:primary:dismissTitle:onDismiss:hero:reward:)`, and the same without `reward:`: the hero (any view, sized by the host) grows in on the expressive spring, the title, message, reward and buttons rise in after it. `celebrates` plays confetti behind the hero with the success haptic, otherwise a light tap. Every close plays the exit (everything fades, the hero shrinks a little), then runs `primary.action` for the primary button or `onDismiss` for any other close: the dismiss button, a tap outside the hero and the buttons, a swipe down, VoiceOver's escape. Under Reduce Motion and `.designKitMotion(false)` it comes and goes by opacity only. VoiceOver moves into it, hears the title and the message, and reads the hero with the title. No strings of its own, no skeleton.
- `MomentAction(_:action:)`: a moment's primary button.
- `MomentPresenter.shared`: `present(onDismissed:_:)` shows a moment over the whole app, sheets, tab bar and navigation included, in a window of its own above the app's windows and below system alerts, with the app's own light or dark choice and its accent; it returns false while another moment is up or with no foreground-active scene. A close removes the window first, then runs the button's action (it may navigate or open a sheet), then `onDismissed`. `dismiss()` removes the moment at once, without its exit or any callback; `isPresenting` tells whether one is up. Unavailable in app extensions.
- `AppColors.Background.scrim`: dims the app under a moment, over the material that blurs it (black 10% in light mode, 45% in dark mode).
- `.progressOverlay(isPresented:title:message:hero:)` and `ProgressOverlay(title:message:hero:)`: a view in the spinner's place that shows the progress itself, sized by the host. Without `hero:` the overlay looks as before.

### Migration

Nothing to change in code. A moment over the whole app:

```swift
MomentPresenter.shared.present(onDismissed: { moments.next() }) {
    MomentOverlay(
        title: "Goal reached",
        message: "A new bike: 250 000 saved.",
        celebrates: true,
        primary: MomentAction("See the goal") { router.open(goal) },
        dismissTitle: "Close"
    ) {
        ParticleCreature(mood: .celebrating).frame(width: 220, height: 220)
    }
}
```

The blur of the app's windows under the moment's window is to be checked on a device.

### Gallery and tooling

- Gallery: a MomentOverlay page in Status & Feedback, over a screen of an app, with its title, message, celebration, primary button, reward and the hero's mood, and "Show over everything" through `MomentPresenter.shared`; the ProgressOverlay page has a "With hero" switch; the Colors page lists `Background.scrim`.
- Snapshot tests: `OverlaySnapshotTests`, the moment with its primary button and reward (light, dark, large text) and with the dismiss button alone (light, dark), and `ProgressOverlay` with a hero (light, dark). References are recorded by CI (`record_snapshots: missing`).
- docs/components.md and docs/agents.md list the moment.
