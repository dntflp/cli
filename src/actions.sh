#!/usr/bin/env bash

# ==============================================================================
# Command implementations
# ==============================================================================

action_help() {
  cat <<'EOF'
TGProxy CLI Commands:
  tgproxy install          - Setup proxy via systemd (default)
  tgproxy install-docker   - Setup proxy via Docker (installs Docker if needed)
  tgproxy link             - Show the tg:// connection link for your proxy
  tgproxy restart          - Restart the MTProto service (applies new config)
  tgproxy status           - Check the service status and configuration
  tgproxy help             - Display this help message
EOF
}

action_install() {
  setup_tgproxy_systemd
}

action_install_docker() {
  setup_tgproxy_docker
}

action_link() {
  load_env

  if [[ -z "${TGPROXY_SECRET:-}" ]]; then
    print_err "MTProto secret not found. Have you run 'tgproxy install' yet?"
    exit 1
  fi

  local ip
  ip=$(get_public_ip)
  local port="${TGPROXY_PORT:-443}"
  local link="tg://proxy?server=$ip&port=$port&secret=$TGPROXY_SECRET"

  echo ""
  print_ok "Your MTProto Telegram Link:"
  echo "$link"
  echo ""
}

action_restart() {
  require_root
  load_env

  if [[ "${TGPROXY_MODE:-systemd}" == "docker" ]]; then
    if type setup_docker_container &>/dev/null; then
       setup_docker_container
    else
       if docker ps -a --format '{{.Names}}' | grep -q "^tgproxy$"; then
         docker rm -f tgproxy >/dev/null
       fi
       docker run -d \
         --name tgproxy \
         --restart unless-stopped \
         -p "${TGPROXY_PORT:-443}:${TGPROXY_PORT:-443}" \
         ghcr.io/9seconds/mtg:latest \
         simple-run 0.0.0.0:${TGPROXY_PORT:-443} ${TGPROXY_SECRET} >/dev/null
       print_ok "Docker container 'tgproxy' recreated and restarted successfully."
    fi
  else
    if systemctl is-active --quiet "$SERVICE_NAME"; then
      setup_systemd
      systemctl restart "$SERVICE_NAME"
      print_ok "Service $SERVICE_NAME restarted successfully."
    else
      print_err "Service $SERVICE_NAME is not running or not installed."
    fi
  fi
}

action_status() {
  load_env
  echo "TGProxy Status:"

  if [[ "${TGPROXY_MODE:-systemd}" == "docker" ]]; then
    if docker ps --format '{{.Names}}' | grep -q "^tgproxy$"; then
       print_ok "Docker Container 'tgproxy' is RUNNING"
    else
       print_err "Docker Container 'tgproxy' is NOT RUNNING or missing"
    fi
  else
    if systemctl is-active --quiet "$SERVICE_NAME"; then
      print_ok "Service ($SERVICE_NAME) is ACTIVE"
    else
      print_err "Service ($SERVICE_NAME) is INACTIVE or not installed"
    fi
  fi

  if [[ -f "$CONFIG_FILE" ]]; then
    print_ok "Config found: $CONFIG_FILE"
    echo "  Mode: ${TGPROXY_MODE:-systemd}"
    echo "  Port: ${TGPROXY_PORT:-443}"
    echo "  Domain: ${TGPROXY_DOMAIN:-google.com}"
  else
    print_err "Config missing at $CONFIG_FILE"
  fi
}
