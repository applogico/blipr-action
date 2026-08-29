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
server="${server%/}"
topic="${BLIPR_TOPIC:-}"

# Duplicated from the server's own topic rule; the two must not drift.
[[ -n "${topic}" ]] || fail "'topic' is required"
[[ ${#topic} -le 64 ]] || fail "topic '${topic}' is too long (max 64 chars)"
[[ "${topic}" =~ ^[A-Za-z0-9_-]+$ ]] ||
  fail "topic '${topic}' has invalid characters (allowed: letters, digits, - and _)"

message="${BLIPR_MESSAGE:-}"
if [[ -z "${message}" ]]; then
  message="${GITHUB_WORKFLOW:-Workflow} on ${GITHUB_REPOSITORY:-this repo} (run #${GITHUB_RUN_NUMBER:-?})"
fi

click="${BLIPR_CLICK:-}"
if [[ -z "${click}" && -n "${GITHUB_SERVER_URL:-}" && -n "${GITHUB_REPOSITORY:-}" && -n "${GITHUB_RUN_ID:-}" ]]; then
  click="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
fi

args=(-X POST)
add_header() { if [[ -n "$2" ]]; then args+=(-H "$1: $2"); fi; }
add_header "X-Title" "${BLIPR_TITLE:-}"
add_header "X-Priority" "${BLIPR_PRIORITY:-}"
add_header "X-Tags" "${BLIPR_TAGS:-}"
add_header "X-Click" "${click}"
add_header "X-Icon" "${BLIPR_ICON:-}"
add_header "X-Reply" "${BLIPR_REPLY:-}"
add_header "X-Options" "${BLIPR_OPTIONS:-}"
add_header "X-Callback" "${BLIPR_CALLBACK:-}"
# shellcheck disable=SC2310 # truthy is a predicate: a non-zero return means "false", not a failure
if truthy "${BLIPR_MARKDOWN:-}"; then args+=(-H "X-Markdown: true"); fi

url="${server}/blip/${topic}"

# shellcheck disable=SC2310 # truthy is a predicate: a non-zero return means "false", not a failure
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

resp="$(mktemp)"
trap 'rm -f "${resp}"' EXIT
code="$(curl -sS "${args[@]}" --data-binary "${message}" -w '%{http_code}' -o "${resp}" "${url}" || true)"
body="$(cat "${resp}")"

if [[ "${code}" != 2* ]]; then
  fail "publish failed (HTTP ${code:-000}): ${body:-no response, is ${server} reachable?}"
fi

# jq is not guaranteed on a self-hosted runner, hence the grep fallback.
mid=""
if command -v jq >/dev/null 2>&1; then
  mid="$(printf '%s' "${body}" | jq -r '.id // empty' 2>/dev/null || true)"
fi
if [[ -z "${mid}" ]]; then
  mid="$(printf '%s' "${body}" |
    grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 |
    sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/' || true)"
fi

echo "blipr: sent to '${topic}' (message ${mid:-?})"
{
  echo "message_id=${mid}"
  echo "http_code=${code}"
} >>"${GITHUB_OUTPUT:-/dev/null}"
