#!/usr/bin/env bash
set -uo pipefail

HOST=${WISH_HOST:-localhost}
PORT=${WISH_SSH_PORT:-2323}
IDENTITY=${WISH_IDENTITY_FILE:-}

function wait_for_server() {
  local waited=0
  while ! nc -z "${HOST}" "${PORT}" >/dev/null 2>&1; do
    if (( waited == 0 )); then
      echo "Waiting for Wish server at ${HOST}:${PORT} …"
    fi
    sleep 1
    waited=$((waited + 1))
    if (( waited % 10 == 0 )); then
      echo "Still waiting for Wish server…"
    fi
  done
}

echo "Starting auto-reconnecting SSH client to ${HOST}:${PORT}. Press Ctrl+C to stop."
trap 'echo; echo "Stopping auto-reconnect."; exit 0' INT TERM

wait_for_server

ssh_base=(
  env TERM=xterm-256color ssh -tt
  -F /dev/null
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o PreferredAuthentications=publickey,keyboard-interactive,password
  -p "${PORT}"
)

if [[ -n "${IDENTITY}" && -f "${IDENTITY}" ]]; then
  ssh_base+=( -i "${IDENTITY}" )
fi

ssh_base+=( charm@"${HOST}" )

while true; do
  "${ssh_base[@]}"
  status=$?
  if [[ ${status} -eq 0 ]]; then
    echo "SSH session ended normally. Reconnecting in 2s…"
  else
    echo "SSH exited with status ${status}. Retrying in 2s…"
  fi
  sleep 2
done
