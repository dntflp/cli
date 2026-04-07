#!/usr/bin/env bash
set -e

# ==============================================================================
# TGProxy Installer
# Automates the setup of MTProto Proxy via tgproxy CLI
# ==============================================================================

REPO="dntflpef/cli"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"

APP_NAME="tgproxy"
INSTALL_PATH="/opt/tgproxy"
LINK_PATH="/usr/local/bin/tgproxy"
CONFIG_PATH="/etc/tgproxy"
LOG_PATH="/var/log/tgproxy"

# Print helpers
print_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
print_ok() { echo -e "\033[0;32m[OK]\033[0m $1"; }
print_err() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

# Pre-checks
if [[ "$EUID" -ne 0 ]]; then
  print_err "Please run as root or with sudo"
  exit 1
fi

if ! command -v curl &> /dev/null; then
  print_info "Installing curl..."
  apt-get update -yqq && apt-get install -yqq curl
fi

# Directory setup
print_info "Setting up directories..."
mkdir -p "$INSTALL_PATH/src"
mkdir -p "$CONFIG_PATH"
mkdir -p "$LOG_PATH"

# Download files
print_info "Downloading tgproxy components..."
curl -fsSL "$RAW_URL/tgproxy" -o "$INSTALL_PATH/tgproxy"
chmod +x "$INSTALL_PATH/tgproxy"

curl -fsSL "$RAW_URL/src/common.sh" -o "$INSTALL_PATH/src/common.sh"
curl -fsSL "$RAW_URL/src/setup.sh" -o "$INSTALL_PATH/src/setup.sh"
curl -fsSL "$RAW_URL/src/actions.sh" -o "$INSTALL_PATH/src/actions.sh"

# Default config creation
CFG_FILE="$CONFIG_PATH/config.env"
if [[ ! -f "$CFG_FILE" ]]; then
  print_info "Creating default configuration..."
  cat > "$CFG_FILE" <<EOF
TGPROXY_PORT=443
TGPROXY_DOMAIN=google.com
TGPROXY_SECRET=
EOF
fi

# Symlink
ln -sf "$INSTALL_PATH/tgproxy" "$LINK_PATH"

print_ok "tgproxy CLI installed successfully."
echo
echo "Usage:"
echo "  1) Run 'tgproxy install' to configure the MTProto Proxy."
echo "  2) Run 'tgproxy link' to get your Telegram connection link."
echo
