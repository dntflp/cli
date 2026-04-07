#!/usr/bin/env bash

# ==============================================================================
# Installation logic
# ==============================================================================

download_mtg() {
  local version
  version=$(curl -fsSL https://api.github.com/repos/9seconds/mtg/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -z "$version" ]]; then
    version="v2.2.8"
  fi

  local arch
  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) print_err "Unsupported architecture for MTG: $(uname -m)"; exit 1 ;;
  esac

  local version_no_v="${version#v}"
  local url="https://github.com/9seconds/mtg/releases/download/${version}/mtg-${version_no_v}-linux-${arch}.tar.gz"

  print_info "Downloading MTProto proxy (mtg $version for $arch)..."
  mkdir -p "$BIN_DIR"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  local archive="$tmp_dir/mtg.tar.gz"

  if ! curl -fsSLo "$archive" "$url"; then
    print_err "Failed to download MTG proxy from $url"
    exit 1
  fi

  tar -xzf "$archive" -C "$tmp_dir"
  local extracted_bin
  extracted_bin=$(find "$tmp_dir" -type f -name "mtg*" -perm -111 | head -n 1)

  if [[ -z "$extracted_bin" ]]; then
    print_err "Could not locate 'mtg' binary in archive."
    exit 1
  fi

  install -m 0755 "$extracted_bin" "$MTG_BIN"
  rm -rf "$tmp_dir"
  print_ok "MTProto proxy installed at $MTG_BIN."
}

configure_secret() {
  if [[ -z "${TGPROXY_SECRET:-}" ]]; then
    print_info "Generating secure MTProto secret for domain: ${TGPROXY_DOMAIN:-google.com}"
    local new_secret
    new_secret=$("$MTG_BIN" generate-secret --hex "${TGPROXY_DOMAIN:-google.com}")

    # Save the new secret directly to the config file
    echo "TGPROXY_SECRET=$new_secret" >> "$CONFIG_FILE"

    print_ok "Secret generated: $new_secret"
    # Ensure it's available for the current script run
    export TGPROXY_SECRET="$new_secret"
  else
    print_info "Using existing secret."
  fi
}

setup_systemd() {
  local service_file="/etc/systemd/system/$SERVICE_NAME"
  print_info "Configuring systemd service ($service_file)..."

  cat > "$service_file" <<EOF
[Unit]
Description=TGProxy MTProto service (mtg)
After=network.target

[Service]
Type=simple
ExecStart=$MTG_BIN simple-run 0.0.0.0:${TGPROXY_PORT:-443} ${TGPROXY_SECRET}
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now "$SERVICE_NAME"
  print_ok "Service $SERVICE_NAME started successfully."
}

setup_tgproxy() {
  require_root
  ensure_deps
  load_env

  download_mtg
  configure_secret
  setup_systemd

  print_ok "Setup complete."
}
