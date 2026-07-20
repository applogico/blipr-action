# Changelog

## 1.0.0 (2026-07-20)

### Features

* Composite action to send a Blipr push notification from CI — publishes to `<server>/blip/<topic>` with title, priority, tags, click, icon, markdown, and the reply/ask loop.
* CI-friendly defaults (message → run summary, click → workflow run URL) and `message_id` / `http_code` outputs.
