# Changelog

## [1.0.1](https://github.com/applogico/blipr-action/compare/v1.0.0...v1.0.1) (2026-07-20)


### Bug Fixes

* rename Marketplace action to "Blipr Notifications" ([74d2c6e](https://github.com/applogico/blipr-action/commit/74d2c6e693c026b86ff08d2e9e291d081e87243e))
* rename Marketplace action to "Blipr Notifications" ([200b16c](https://github.com/applogico/blipr-action/commit/200b16cf88c4db38db09c4fe8bc06a23a28873b1))

## 1.0.0 (2026-07-20)

### Features

* Composite action to send a Blipr push notification from CI — publishes to `<server>/blip/<topic>` with title, priority, tags, click, icon, markdown, and the reply/ask loop.
* CI-friendly defaults (message → run summary, click → workflow run URL) and `message_id` / `http_code` outputs.
