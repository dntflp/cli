#!/usr/bin/env bash

# ==============================================================================
# Common Configuration & Utilities for tgproxy
# ==============================================================================

# Core paths
CONFIG_DIR="/etc/tgproxy"
CONFIG_FILE="$CONFIG_DIR/config.env"
INSTALL_DIR="/opt/tgproxy"
BIN_DIR="$INSTALL_DIR/bin"
MTG_BIN="$BIN_DIR/mtg"
SERVICE_NAME="tgproxy.service"

print_info() {
  echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_ok() {
  echo -e "\033[0;32m[OK]\033[0m $1"
}

print_warn() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}

print_err() {
  echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    print_err "Action requires root privileges. Try running with sudo."
    exit 1
  fi
}

load_env() {
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  else
    print_warn "Config file not found at $CONFIG_FILE. Will use defaults."
  fi
}

get_public_ip() {
  local ip
  ip=$(curl -4 -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)
  if [[ -z "$ip" ]]; then
    ip=$(hostname -I | awk '{print $1}')
  fi
  echo "${ip:-<YOUR_IP>}"
}

ensure_deps() {
  if ! command -v curl &> /dev/null || ! command -v tar &> /dev/null; then
    print_info "Installing dependencies (curl, tar, openssl)..."
    apt-get update -yqq
    apt-get install -yqq curl tar openssl ca-certificates
  fi
}
