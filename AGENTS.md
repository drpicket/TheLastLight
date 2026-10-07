# The Last Light — contributor notes

## Project
- iPhone/iPad game using SwiftUI for menus/HUD and SpriteKit for the world.
- Keep the existing free-flight game, scene, archive, saves, audio, regions and upgrades; extend them incrementally rather than replacing working systems.
- Use Xcode workspace-relative paths with Xcode tools for project files. Build with Xcode's BuildProject command and verify touch gameplay on an iPhone simulator after gameplay changes.

## Git workflow
- Check `git status` before major changes and inspect unfamiliar changes before editing them.
- Use Git checkpoints: after completing a meaningful feature, run the appropriate tests/build, review the diff, and make a commit with a clear descriptive message.
- Never commit broken or unfinished changes. Do not delete or rewrite Git history unless explicitly requested.
- Create a version tag only when the user explicitly says a major version is complete. Do not tag intermediate checkpoints.
- Keep commits focused and preserve save-data compatibility when adding persistent fields.
