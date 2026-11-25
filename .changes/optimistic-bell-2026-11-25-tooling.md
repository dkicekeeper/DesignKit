---
bump: patch
---
Tooling after the first release given at merge: the bot's own fixes, Platina built in CI, and a
form to ask for a component. Nothing changes in an app.

### Gallery and tooling
- Notes released together keep their paragraphs apart in the CHANGELOG section: an intro or a block that follows another note's text starts after a blank line, and items of one section still run on.
- The release bot commits only the files it changed (`git add -u`), never a file a step left untracked in the checkout.
- TestFlight's build started by the release bot skips quietly when the signing secrets are missing, as a push does; a person's manual run still fails with the list of what to add.
- CI's `platina` job builds Platina against this checkout on GitHub's Xcode 27 image, as its own CI does: its XcodeGen spec is pointed at the local package, and a manual run takes `platina_ref` to check a Platina branch.
- CLAUDE.md, docs/agents.md and docs/adoption.md say that Platina moves its pin with its own DesignKit update workflow, as Tenra and Dalada do.
- An issue template, "Component request" (`.github/ISSUE_TEMPLATE/component-request.yml`): the app, the screen, what the person should see and do, what the app draws today, the components that come close, a screenshot (docs/benchmark.md 28).
