# Blipr GitHub Action

Send a [Blipr](https://apps.apple.com/us/app/blipr-notifications/id6785094245) push notification from your CI — **curl your phone.**

Subscribe to a topic in the Blipr app, then have any workflow publish to it. Priority 4–5 alerts arrive as Time-Sensitive, so the one that matters breaks through Focus and Do Not Disturb.

It's a composite action: just `curl`, no build step, runs on any GitHub-hosted or self-hosted runner.

## Quick start

```yaml
- uses: applogico/blipr-action@v1
  with:
    topic: my-ci-alerts
    message: Build finished
```

That's the whole thing. `topic` is the only required input.

## Notify on failure

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make build

      - name: Blip me if the build fails
        if: failure()
        uses: applogico/blipr-action@v1
        with:
          topic: my-ci-alerts
          title: Build failed
          message: "${{ github.workflow }} broke on ${{ github.ref_name }}"
          priority: 5
          tags: rotating_light
```

## Notify on success, with a tap-through link

```yaml
- name: Ship it
  if: success()
  uses: applogico/blipr-action@v1
  with:
    topic: deploys
    title: Deployed 🚀
    message: "${{ github.sha }} is live"
    priority: 4
    tags: white_check_mark
    click: https://status.example.com   # defaults to this workflow run if omitted
```

## Inputs

| Input      | Required | Default            | Description |
|------------|----------|--------------------|-------------|
| `topic`    | **yes**  | —                  | Topic to publish to. `A–Z a–z 0–9 - _`, ≤64 chars. Anyone who knows the name can publish — keep sensitive topics unguessable. |
| `message`  | no       | run summary        | Message body. Defaults to `"<workflow> on <repo> (run #<n>)"`. |
| `title`    | no       | —                  | Notification title. |
| `priority` | no       | `default` (3)      | `1`–`5`, or `min`/`low`/`default`/`high`/`max`/`urgent`. 4–5 are Time-Sensitive. |
| `tags`     | no       | —                  | Comma-separated tags / emoji shortcodes, e.g. `rocket,white_check_mark`. |
| `click`    | no       | this workflow run  | URL to open when the notification is tapped. |
| `icon`     | no       | —                  | URL of an icon image to display. |
| `markdown` | no       | `false`            | Render the body as Markdown. |
| `reply`    | no       | —                  | Ask for a reply: `binary`, `ack`, or `choice`. See below. |
| `options`  | no       | —                  | Comma-separated choices (2–10), required when `reply: choice`. |
| `callback` | no       | —                  | URL POSTed the reply when it lands. |
| `server`   | no       | `https://blipr.dev`| Base URL of the Blipr / notify server. Point at your own host to self-host. |
| `dry_run`  | no       | `false`            | Print the request and exit without publishing. Handy for testing. |

## Outputs

| Output       | Description                                   |
|--------------|-----------------------------------------------|
| `message_id` | ID of the published message.                  |
| `http_code`  | HTTP status returned by the server.           |

## Ask for a reply (advanced)

Blipr can ask the recipient a question and collect the answer. The reply is delivered asynchronously to your `callback` URL — CI fires it and moves on; it does not wait.

```yaml
- name: Ask before promoting to prod
  uses: applogico/blipr-action@v1
  with:
    topic: deploys
    title: Promote to prod?
    message: "${{ github.sha }} passed staging."
    reply: choice
    options: "Promote,Hold,Rollback"
    callback: https://ci.example.com/blipr-hook
```

`reply: binary` gives a Yes/No, `reply: ack` a single Acknowledge. The first reply on the topic wins and locks the answer.

## Self-hosting

Point `server` at your own notify host:

```yaml
- uses: applogico/blipr-action@v1
  with:
    server: https://notify.mycompany.internal
    topic: alerts
    message: Nightly job done
```

## How it works

The action `POST`s to `<server>/blip/<topic>` with the message as the raw body and metadata as `X-*` headers — the same [ntfy-style](https://ntfy.sh) contract the Blipr app publishes with. Publishing is public-by-topic: no token or API key required.

## License

MIT © Applogico
