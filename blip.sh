#!/usr/bin/env bash
#
# Publish a Blipr push notification. Driven entirely by BLIPR_* env vars set by
# action.yml. Uses only curl + coreutils so it runs on any GitHub-hosted or
# self-hosted runner with no build step.
#
set -euo pipefail

fail() { echo "::error::blipr: $*"; exit 1; }
truthy() { case "${1,,}" in 1 | yes | true) return 0 ;; *) return 1 ;; esac; }

server="${BLIPR_SERVER:-https://blipr.dev}"
server="${server%/}" # strip trailing slash
topic="${BLIPR_TOPIC:-}"

# --- validate topic (mirrors the server: A-Z a-z 0-9 - _, max 64) -----------
[[ -n "$topic" ]] || fail "'topic' is required"
[[ ${#topic} -le 64 ]] || fail "topic '$topic' is too long (max 64 chars)"
[[ "$topic" =~ ^[A-Za-z0-9_-]+$ ]] ||
  fail "topic '$topic' has invalid characters (allowed: letters, digits, - and _)"

# --- message: default to a summary of the run ------------------------------
message="${BLIPR_MESSAGE:-}"
if [[ -z "$message" ]]; then
  message="${GITHUB_WORKFLOW:-Workflow} on ${GITHUB_REPOSITORY:-this repo} (run #${GITHUB_RUN_NUMBER:-?})"
fi

# --- click: default to this workflow run -----------------------------------
click="${BLIPR_CLICK:-}"
if [[ -z "$click" && -n "${GITHUB_SERVER_URL:-}" && -n "${GITHUB_REPOSITORY:-}" && -n "${GITHUB_RUN_ID:-}" ]]; then
  click="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
fi

# --- assemble headers (only those that were set) ---------------------------
args=(-X POST)
add_header() { [[ -n "$2" ]] && args+=(-H "$1: $2") || true; }
add_header "X-Title" "${BLIPR_TITLE:-}"
add_header "X-Priority" "${BLIPR_PRIORITY:-}"
add_header "X-Tags" "${BLIPR_TAGS:-}"
add_header "X-Click" "$click"
add_header "X-Icon" "${BLIPR_ICON:-}"
add_header "X-Reply" "${BLIPR_REPLY:-}"
add_header "X-Options" "${BLIPR_OPTIONS:-}"
add_header "X-Callback" "${BLIPR_CALLBACK:-}"
truthy "${BLIPR_MARKDOWN:-}" && args+=(-H "X-Markdown: true") || true

url="${server}/blip/${topic}"

# --- dry run ---------------------------------------------------------------
if truthy "${BLIPR_DRY_RUN:-}"; then
  echo "blipr (dry-run): POST ${url}"
  for ((i = 0; i < ${#args[@]}; i++)); do
    [[ "${args[i]}" == "-H" ]] && echo "  ${args[i + 1]}"
  done
  echo "  body: ${message}"
  {
    echo "message_id="
    echo "http_code="
  } >>"${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

# --- publish ---------------------------------------------------------------
resp="$(mktemp)"
trap 'rm -f "$resp"' EXIT
code="$(curl -sS "${args[@]}" --data-binary "$message" -w '%{http_code}' -o "$resp" "$url" || true)"
body="$(cat "$resp")"

if [[ "$code" != 2* ]]; then
  fail "publish failed (HTTP ${code:-000}): ${body:-no response, is ${server} reachable?}"
fi

# --- extract message id (jq if available, else a portable grep) ------------
mid=""
if command -v jq >/dev/null 2>&1; then
  mid="$(printf '%s' "$body" | jq -r '.id // empty' 2>/dev/null || true)"
fi
if [[ -z "$mid" ]]; then
  mid="$(printf '%s' "$body" |
    grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 |
    sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/' || true)"
fi

echo "blipr: sent to '${topic}' (message ${mid:-?})"
{
  echo "message_id=${mid}"
  echo "http_code=${code}"
} >>"${GITHUB_OUTPUT:-/dev/null}"
