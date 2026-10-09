#!/usr/bin/env bash
# ==============================================================================
# de_GWD NextGen - Xray Core & Cloudflare Argo Tunnel Management Library
# ==============================================================================

readonly XRAY_BIN="${DEGWD_BIN}/xray"
readonly CLOUDFLARED_BIN="${DEGWD_BIN}/cloudflared"
readonly XRAY_SERVER_CONF="${DEGWD_ETC}/xray_server.json"
readonly XRAY_CLIENT_CONF="${DEGWD_ETC}/xray_client.json"
readonly ARGO_LOG="${DEGWD_LOG}/argo.log"
readonly ARGO_DOMAIN_FILE="${DEGWD_ETC}/argo_domain"

# Ensure Xray-core binary is installed
install_xray_core() {
    local force="${1:-false}"
    if [[ "$force" != "true" ]] && [[ -x "$XRAY_BIN" ]]; then
        local current_ver
        current_ver="$("$XRAY_BIN" version 2>/dev/null | head -n1 | awk '{print $2}')"
        if [[ -n "$current_ver" ]]; then
            msg_ok "Xray 核心已就绪: ${current_ver}"
            return 0
        fi
    fi

    msg_step "获取 Xray 核心 (支持 xhttp 与 Post-Quantum ENC)..."
    local arch
    arch="$(detect_arch)"
    local cpu="$arch"

    local xarch="64"
    if [[ "$arch" == "arm64" ]]; then
        xarch="arm64-v8a"
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"

    # Official release & multi-mirror links
    local dl_urls=(
        "https://github.com/yonggekkk/argosbx/releases/download/argosbx/xray-${cpu}"
        "https://ghfast.top/https://github.com/yonggekkk/argosbx/releases/download/argosbx/xray-${cpu}"
        "https://ghproxy.net/https://github.com/yonggekkk/argosbx/releases/download/argosbx/xray-${cpu}"
        "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${xarch}.zip"
        "https://ghfast.top/https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${xarch}.zip"
        "https://ghproxy.net/https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${xarch}.zip"
    )

    local success=false
    for url in "${dl_urls[@]}"; do
        msg_info "尝试从镜像源下载 Xray 核心: ${url}..."
        if [[ "$url" =~ \.zip$ ]]; then
            if curl -fsSL --max-time 45 "$url" -o "${tmp_dir}/xray.zip" 2>/dev/null; then
                if command -v unzip >/dev/null 2>&1 || apt-get install -y -qq unzip >/dev/null 2>&1; then
                    unzip -q -o "${tmp_dir}/xray.zip" -d "${tmp_dir}/out" 2>/dev/null
                    if [[ -f "${tmp_dir}/out/xray" ]]; then
                        install -m 755 "${tmp_dir}/out/xray" "$XRAY_BIN"
                        success=true
                        break
                    fi
                fi
            fi
        else
            if curl -fsSL --max-time 45 "$url" -o "${tmp_dir}/xray" 2>/dev/null; then
                chmod +x "${tmp_dir}/xray"
                if "${tmp_dir}/xray" version >/dev/null 2>&1; then
                    install -m 755 "${tmp_dir}/xray" "$XRAY_BIN"
                    success=true
                    break
                fi
            fi
        fi
    done

    rm -rf "$tmp_dir"
    if [[ "$success" == "true" && -x "$XRAY_BIN" ]]; then
        local installed_ver
        installed_ver="$("$XRAY_BIN" version 2>/dev/null | head -n1 | awk '{print $2}')"
        msg_ok "Xray 核心安装成功: ${installed_ver}"
        return 0
    else
        msg_err "Xray 核心下载失败，请检查网络环境！"
        return 1
    fi
}

# Ensure Cloudflared binary is installed
install_cloudflared() {
    local force="${1:-false}"
    if [[ "$force" != "true" ]] && [[ -x "$CLOUDFLARED_BIN" ]]; then
        msg_ok "Cloudflared 隧道客户端已就绪"
        return 0
    fi

    msg_step "获取 Cloudflared (Argo 穿透隧道客户端)..."
    local arch
    arch="$(detect_arch)"
    local cpu="$arch"

    local dl_urls=(
        "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}"
        "https://ghfast.top/https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}"
        "https://ghproxy.net/https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${arch}"
        "https://github.com/yonggekkk/argosbx/releases/download/argosbx/cloudflared-${cpu}"
        "https://ghfast.top/https://github.com/yonggekkk/argosbx/releases/download/argosbx/cloudflared-${cpu}"
        "https://ghproxy.net/https://github.com/yonggekkk/argosbx/releases/download/argosbx/cloudflared-${cpu}"
    )

    local tmp_bin
    tmp_bin="$(mktemp)"
    local success=false

    for url in "${dl_urls[@]}"; do
        msg_info "下载 Cloudflared: ${url}..."
        if curl -fsSL --max-time 45 "$url" -o "$tmp_bin" 2>/dev/null; then
            chmod +x "$tmp_bin"
            if "$tmp_bin" --version >/dev/null 2>&1; then
                install -m 755 "$tmp_bin" "$CLOUDFLARED_BIN"
                success=true
                break
            fi
        fi
    done

    rm -f "$tmp_bin"
    if [[ "$success" == "true" ]]; then
        msg_ok "Cloudflared 安装成功"
        return 0
    else
        msg_warn "Cloudflared 下载失败，Argo 隧道功能暂不可用"
        return 1
    fi
}

# Generate Xray VLESS-ENC Keypair (MLKEM Post-Quantum Cryptography)
gen_vlessenc_keypair() {
    if [[ ! -x "$XRAY_BIN" ]]; then
        install_xray_core || return 1
    fi

    local out
    out="$("$XRAY_BIN" vlessenc 2>/dev/null)"
    local dekey enkey
    dekey="$(grep '"decryption":' <<< "$out" | sed -n '2p' | cut -d' ' -f2- | tr -d '", \r')"
    enkey="$(grep '"encryption":' <<< "$out" | sed -n '2p' | cut -d' ' -f2- | tr -d '", \r')"

    if [[ -z "$dekey" || -z "$enkey" ]]; then
        dekey="none"
        enkey="none"
    fi

    printf "%s|%s\n" "$dekey" "$enkey"
}

# Build Server-Side Xray Config (VLESS-xhttp-reality + VLESS-ws + VLESS-REALITY)
build_xray_server_config() {
    local uuid="$1"
    local dekey="$2"
    local xh_port="${3:-20081}"
    local vw_port="${4:-20082}"
    local vl_port="${5:-443}"
    local sni="${6:-www.microsoft.com}"
    local priv_key="$7"
    local short_id="$8"

    cat << EOF > "$XRAY_SERVER_CONF"
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "xhttp-reality",
      "listen": "::",
      "port": ${xh_port},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}"
          }
        ],
        "decryption": "${dekey}"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "target": "${sni}:443",
          "serverNames": [
            "${sni}"
          ],
          "privateKey": "${priv_key}",
          "shortIds": [
            "${short_id}"
          ]
        },
        "xhttpSettings": {
          "host": "",
          "path": "${uuid}-xh",
          "mode": "auto"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    },
    {
      "tag": "vless-ws",
      "listen": "::",
      "port": ${vw_port},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${uuid}-vw"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {
        "domainStrategy": "UseIPv4"
      }
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "type": "field",
        "ip": [
          "10.0.0.0/8",
          "172.16.0.0/12",
          "192.168.0.0/16",
          "127.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "block"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "direct"
      }
    ]
  }
}
EOF
    chmod 600 "$XRAY_SERVER_CONF"
}

# Start Cloudflare Argo Tunnel
start_argo_tunnel() {
    local port="${1:-20082}" # points to vless-ws
    if [[ ! -x "$CLOUDFLARED_BIN" ]]; then
        install_cloudflared || return 1
    fi

    # Kill old instance
    killall cloudflared 2>/dev/null || true
    rm -f "$ARGO_LOG"

    msg_step "正在启动 Cloudflare Argo 穿透隧道..."
    nohup "$CLOUDFLARED_BIN" tunnel --url "http://127.0.0.1:${port}" \
        --edge-ip-version auto --no-autoupdate --protocol http2 > "$ARGO_LOG" 2>&1 &

    local argo_pid=$!
    local domain=""
    local retries=15

    while [[ $retries -gt 0 ]]; do
        sleep 1
        if [[ -f "$ARGO_LOG" ]]; then
            domain="$(grep -oP 'https://\K[a-zA-Z0-9-]+\.trycloudflare\.com' "$ARGO_LOG" | head -n1)"
            if [[ -n "$domain" ]]; then
                echo "$domain" > "$ARGO_DOMAIN_FILE"
                msg_ok "Cloudflare Argo 临时穿透域名申请成功: ${domain}"
                return 0
            fi
        fi
        ((retries--))
    done

    msg_warn "Argo 域名等待超时，日志已记录至: ${ARGO_LOG}"
    return 1
}

# Setup Xray Server Systemd Unit
setup_xray_server_service() {
    local unit_file="/etc/systemd/system/degwd-xray-server.service"
    cat << EOF > "$unit_file"
[Unit]
Description=de_GWD NextGen Xray Multi-Protocol Service
Documentation=https://github.com/jacyl4/de_GWD
After=network.target network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${DEGWD_BASE}
ExecStart=${XRAY_BIN} run -c ${XRAY_SERVER_CONF}
Restart=always
RestartSec=3s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable degwd-xray-server >/dev/null 2>&1
    systemctl restart degwd-xray-server
}

# Build Client-Side Xray Outbound Configuration (SOCKS5 127.0.0.1:10808)
build_xray_client_config() {
    local server_host="$1"
    local server_port="$2"
    local uuid="$3"
    local proto="${4:-vless}"
    local network="${5:-tcp}"
    local security="${6:-reality}"
    local path="${7:-}"
    local host="${8:-}"
    local sni="${9:-$server_host}"
    local pbk="${10:-}"
    local sid="${11:-}"
    local flow="${12:-xtls-rprx-vision}"
    local encryption="${13:-none}"

    local stream_settings=""
    if [[ "$network" == "xhttp" ]]; then
        local real_sec="\"security\": \"${security}\","
        local reality_json=""
        if [[ "$security" == "reality" ]]; then
            reality_json=$(cat << EOF
        "realitySettings": {
          "show": false,
          "fingerprint": "chrome",
          "serverName": "${sni}",
          "publicKey": "${pbk}",
          "shortId": "${sid}",
          "spiderX": ""
        },
EOF
)
        elif [[ "$security" == "tls" ]]; then
            reality_json=$(cat << EOF
        "tlsSettings": {
          "serverName": "${sni}",
          "fingerprint": "chrome"
        },
EOF
)
        fi

        stream_settings=$(cat << EOF
      "streamSettings": {
        "network": "xhttp",
        ${real_sec}
        ${reality_json}
        "xhttpSettings": {
          "host": "${host}",
          "path": "${path}",
          "mode": "auto"
        }
      }
EOF
)
    elif [[ "$network" == "ws" ]]; then
        local tls_json=""
        local real_sec="\"security\": \"none\","
        if [[ "$security" == "tls" ]]; then
            real_sec="\"security\": \"tls\","
            tls_json=$(cat << EOF
        "tlsSettings": {
          "serverName": "${sni}",
          "fingerprint": "chrome"
        },
EOF
)
        fi

        stream_settings=$(cat << EOF
      "streamSettings": {
        "network": "ws",
        ${real_sec}
        ${tls_json}
        "wsSettings": {
          "path": "${path}",
          "headers": {
            "Host": "${host:-$sni}"
          }
        }
      }
EOF
)
    else
        # default reality tcp
        stream_settings=$(cat << EOF
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "serverName": "${sni}",
          "publicKey": "${pbk}",
          "shortId": "${sid}"
        }
      }
EOF
)
    fi

    cat << EOF > "$XRAY_CLIENT_CONF"
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "socks-in",
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "${server_host}",
            "port": ${server_port},
            "users": [
              {
                "id": "${uuid}",
                "flow": "${flow}",
                "encryption": "${encryption}"
              }
            ]
          }
        ]
      },
      ${stream_settings}
    }
  ]
}
EOF
    chmod 600 "$XRAY_CLIENT_CONF"
}

# Setup Xray Client Systemd Unit
setup_xray_client_service() {
    local unit_file="/etc/systemd/system/degwd-xray-client.service"
    cat << EOF > "$unit_file"
[Unit]
Description=de_GWD NextGen Xray Client Outbound Proxy Helper
Documentation=https://github.com/jacyl4/de_GWD
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${DEGWD_BASE}
ExecStart=${XRAY_BIN} run -c ${XRAY_CLIENT_CONF}
Restart=always
RestartSec=2s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable degwd-xray-client >/dev/null 2>&1
    systemctl restart degwd-xray-client
}
