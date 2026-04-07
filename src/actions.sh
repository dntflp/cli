#!/usr/bin/env bash

# ==============================================================================
# Command implementations
# ==============================================================================

action_help() {
  cat <<'EOF'
TGProxy CLI Commands:
  tgproxy install  - Set up and configure the MTProto Proxy
  tgproxy link     - Show the tg:// connection link for your proxy
  tgproxy restart  - Restart the MTProto service
  tgproxy status   - Check the service status and configuration
  tgproxy help     - Display this help message
EOF
}

action_install() {
  setup_tgproxy
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
  if systemctl is-active --quiet "$SERVICE_NAME"; then
    systemctl restart "$SERVICE_NAME"
    print_ok "Service $SERVICE_NAME restarted successfully."
  else
    print_err "Service $SERVICE_NAME is not running or not installed."
  fi
}

action_status() {
  load_env
  echo "TGProxy Status:"
  if systemctl is-active --quiet "$SERVICE_NAME"; then
    print_ok "Service ($SERVICE_NAME) is ACTIVE"
  else
    print_err "Service ($SERVICE_NAME) is INACTIVE or not installed"
  fi

  if [[ -f "$CONFIG_FILE" ]]; then
    print_ok "Config found: $CONFIG_FILE"
    echo "  Port: ${TGPROXY_PORT:-443}"
    echo "  Domain: ${TGPROXY_DOMAIN:-google.com}"
  else
    print_err "Config missing at $CONFIG_FILE"
  fi
}
