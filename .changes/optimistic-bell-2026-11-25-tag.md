---
bump: patch
---
The release bot pushes a release's tag again when GitHub refuses it at first. Nothing changes in an app.

### Gallery and tooling
- The release bot pushes a tag GitHub refused right after the release commit ("missing necessary objects") again after 5, 15 and 30 seconds. 8.19.0's run stopped there and a second run had to tag it.
