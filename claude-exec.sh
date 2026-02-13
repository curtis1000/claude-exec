#!/usr/bin/env bash

# Strict settings
set -o errexit
set -o pipefail
set -o nounset

# On-the-fly debugging
[[ -n "${DEBUG:-}" ]] && set -x

# "Magic" variables
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename "${__file}" .sh)"

# Env parsing
ENV_FILE=${ENV_FILE:-~/.claude-exec}

# shellcheck source=/dev/null
test -f "${ENV_FILE}" && source "${ENV_FILE}" || {
  echo "⛔️ Config file not found (${ENV_FILE}), see README."
  exit 1
}
[ -n "${RUNTIME+set}" ] || {
  echo "⛔️ RUNTIME is not set in ${ENV_FILE}."
  exit 1
}
[ -n "${IMAGE_TAG+set}" ] || {
  echo "⛔️ IMAGE_TAG is not set in ${ENV_FILE}."
  exit 1
}
[ -n "${AWS_IAM_ROLE+set}" ] || {
  echo "⛔️ AWS_IAM_ROLE is not set in ${ENV_FILE}."
  exit 1
}

# Input parsing
# default to "run" subcommand if none are provided
cmd=$([ -n "${1+set}" ] && echo "$1" || echo "run")

# Subcommand definitions
cmd_build() {
  "${RUNTIME}" build --build-arg CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION}" . -t "${IMAGE_TAG}"
}

# 1. Authenticates with AWS STS
# 2. Runs the claude container, passing in auth creds via env
cmd_run() {
  echo "⌛️ Authenticating with AWS STS..."
  assume_role() {
    aws sts assume-role \
      --profile "${AWS_PROFILE:-default}" \
      --role-arn "${AWS_IAM_ROLE}" \
      --role-session-name "ClaudeCodeSession" \
      --duration-seconds "${AWS_SESSION_DURATION:-3600}" \
      --output json
  }
  sts_output=$(assume_role)
  AWS_ACCESS_KEY_ID=$(echo "${sts_output}"     | jq -r '.Credentials.AccessKeyId')
  AWS_SECRET_ACCESS_KEY=$(echo "${sts_output}" | jq -r '.Credentials.SecretAccessKey')
  AWS_SESSION_TOKEN=$(echo "${sts_output}"     | jq -r '.Credentials.SessionToken')
  echo "✅ Received credentials for ${AWS_IAM_ROLE}"

  "${RUNTIME}" run \
    --interactive \
    --tty \
    --rm \
    --volume "$(pwd):/src" \
    --env-file "${ENV_FILE}" \
    --env "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
    --env "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
    --env "AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}" \
    "${IMAGE_TAG}" \
    claude ${CLAUDE_OPTIONS:-}
}

# creates a symlink in $PATH
# most environments include $HOME/.local/bin in $PATH by default
cmd_symlink() {
  ln -s ${__file} $HOME/.local/bin/cx
  echo "Creating symlink:"
  echo "ln -s ${__file} $HOME/.local/bin/cx"
  echo "You may now invoke Claude Exec with \`cx\`."
}

cmd_unlink() {
  echo "Deleting symlink:"
  echo "rm $HOME/.local/bin/cx"
  rm $HOME/.local/bin/cx
}

# Subcommand routing
case "$cmd" in
  build)
    cmd_build "$@"
    ;;
  run)
    cmd_run "$@"
    ;;
  symlink)
    cmd_symlink "$@"
    ;;
  unlink)
    cmd_unlink "$@"
    ;;
  help)
    echo "Usage: ${__base} {build|run|symlink|unlink|help}"
    ;;
esac
