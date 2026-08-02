# Changelog

## [1.0.1](https://github.com/applogico/blipr-action/compare/v1.0.0...v1.0.1) (2026-08-02)


### Bug Fixes

* release the corrected priority description ([28f1356](https://github.com/applogico/blipr-action/commit/28f1356563250f14419e7d8fcaf96a80b5de189e))
* release the corrected priority description ([40c8986](https://github.com/applogico/blipr-action/commit/40c8986fb83f2d86e5835774bf2e360ebea1bdd7))

## 1.0.0 (2026-07-20)

### Features

* Composite action to send a Blipr push notification from CI — publishes to `<server>/blip/<topic>` with title, priority, tags, click, icon, markdown, and the reply/ask loop.
* CI-friendly defaults (message → run summary, click → workflow run URL) and `message_id` / `http_code` outputs.
