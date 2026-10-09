#!/usr/bin/env bash
# ==============================================================================
# de_GWD NextGen - Node Export, Multi-Protocol URI Parsing & Subscription Formatter
# ==============================================================================

# Parse Any Protocol URI Link (vless, hysteria2, vmess, ss, tuic, trojan)
parse_node_uri() {
    local raw_uri="$1"
    raw_uri="$(echo "$raw_uri" | tr -d '\r\n ')"

    PARSED_PROTO=""
    PARSED_HOST=""
    PARSED_PORT=""
    PARSED_UUID=""
    PARSED_PASS=""
    PARSED_NETWORK="tcp"
    PARSED_SECURITY="none"
    PARSED_SNI=""
    PARSED_PBK=""
    PARSED_SID=""
    PARSED_FLOW="xtls-rprx-vision"
    PARSED_PATH=""
    PARSED_HOST_HEADER=""
    PARSED_ENCRYPTION="none"
    PARSED_INSECURE="1"
    PARSED_PIN_SHA=""
    PARSED_TAG=""

    if [[ -z "$raw_uri" ]]; then
        return 1
    fi

    # Extract tag / fragment (#tag)
    if [[ "$raw_uri" == *"#"* ]]; then
        PARSED_TAG="${raw_uri##*#}"
        raw_uri="${raw_uri%%#*}"
    fi

    if [[ "$raw_uri" =~ ^vless://([^@]+)@([^:]+):([0-9]+)(\?(.*))? ]]; then
        PARSED_PROTO="vless"
        PARSED_UUID="${BASH_REMATCH[1]}"
        PARSED_HOST="${BASH_REMATCH[2]}"
        PARSED_PORT="${BASH_REMATCH[3]}"
        local query="${BASH_REMATCH[5]}"

        # Parse query parameters
        IFS='&' read -ra pairs <<< "$query"
        for pair in "${pairs[@]}"; do
            local k="${pair%%=*}"
            local v="${pair#*=}"
            case "$k" in
                type|network) PARSED_NETWORK="$v" ;;
                security)     PARSED_SECURITY="$v" ;;
                sni|peer)     PARSED_SNI="$v" ;;
                pbk|public_key) PARSED_PBK="$v" ;;
                sid|short_id) PARSED_SID="$v" ;;
                flow)         PARSED_FLOW="$v" ;;
                path)         PARSED_PATH="$v" ;;
                host)         PARSED_HOST_HEADER="$v" ;;
                encryption)   PARSED_ENCRYPTION="$v" ;;
                insecure|allowInsecure) PARSED_INSECURE="$v" ;;
                fp)           PARSED_FP="$v" ;;
            esac
        done

        if [[ -z "$PARSED_SNI" && -n "$PARSED_HOST_HEADER" ]]; then
            PARSED_SNI="$PARSED_HOST_HEADER"
        fi
        if [[ -z "$PARSED_SNI" ]]; then
            PARSED_SNI="$PARSED_HOST"
        fi
        [[ -z "$PARSED_TAG" ]] && PARSED_TAG="VLESS-${PARSED_NETWORK}-${PARSED_HOST}"
        return 0

    elif [[ "$raw_uri" =~ ^(hysteria2|hy2)://([^@]+)@([^:]+):([0-9]+)(\?(.*))? ]]; then
        PARSED_PROTO="hysteria2"
        PARSED_PASS="${BASH_REMATCH[2]}"
        PARSED_UUID="$PARSED_PASS"
        PARSED_HOST="${BASH_REMATCH[3]}"
        PARSED_PORT="${BASH_REMATCH[4]}"
        local query="${BASH_REMATCH[6]}"

        IFS='&' read -ra pairs <<< "$query"
        for pair in "${pairs[@]}"; do
            local k="${pair%%=*}"
            local v="${pair#*=}"
            case "$k" in
                sni) PARSED_SNI="$v" ;;
                insecure|allowInsecure) PARSED_INSECURE="$v" ;;
                pinSHA256) PARSED_PIN_SHA="$v" ;;
            esac
        done
        [[ -z "$PARSED_SNI" ]] && PARSED_SNI="$PARSED_HOST"
        [[ -z "$PARSED_TAG" ]] && PARSED_TAG="Hysteria2-${PARSED_HOST}"
        return 0

    elif [[ "$raw_uri" =~ ^vmess://(.*) ]]; then
        PARSED_PROTO="vmess"
        local b64="${BASH_REMATCH[1]}"
        local json_str
        json_str="$(echo "$b64" | base64 -d 2>/dev/null || true)"
        if [[ -n "$json_str" ]]; then
            PARSED_HOST="$(jq -r '.add // ""' <<< "$json_str" 2>/dev/null)"
            PARSED_PORT="$(jq -r '.port // "443"' <<< "$json_str" 2>/dev/null)"
            PARSED_UUID="$(jq -r '.id // ""' <<< "$json_str" 2>/dev/null)"
            PARSED_NETWORK="$(jq -r '.net // "ws"' <<< "$json_str" 2>/dev/null)"
            PARSED_PATH="$(jq -r '.path // ""' <<< "$json_str" 2>/dev/null)"
            PARSED_HOST_HEADER="$(jq -r '.host // ""' <<< "$json_str" 2>/dev/null)"
            PARSED_SNI="$(jq -r '.sni // .host // ""' <<< "$json_str" 2>/dev/null)"
            local tls_val
            tls_val="$(jq -r '.tls // ""' <<< "$json_str" 2>/dev/null)"
            [[ -n "$tls_val" && "$tls_val" != "none" ]] && PARSED_SECURITY="tls" || PARSED_SECURITY="none"
            PARSED_TAG="$(jq -r '.ps // ""' <<< "$json_str" 2>/dev/null)"
            [[ -z "$PARSED_TAG" ]] && PARSED_TAG="VMess-${PARSED_HOST}"
            return 0
        fi
        return 1

    elif [[ "$raw_uri" =~ ^ss://(.*) ]]; then
        PARSED_PROTO="shadowsocks"
        [[ -z "$PARSED_TAG" ]] && PARSED_TAG="SS-${raw_uri:5:10}"
        return 0
    else
        return 1
    fi
}

# Export VLESS-REALITY TCP Link
get_vless_reality_link() {
    local ip="${1:-$(get_public_ip)}"
    [[ ! -f "$DEGWD_ENV_FILE" ]] && return 1
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local tag="de_GWD-VLESS-REALITY"
    printf "vless://%s@%s:%s?security=reality&encryption=none&pbk=%s&headerType=none&fp=chrome&type=tcp&flow=xtls-rprx-vision&sni=%s&sid=%s#%s\n" \
        "$SERVER_UUID" "$ip" "$VLESS_PORT" "$REALITY_PUB_KEY" "$REALITY_SNI" "$REALITY_SHORT_ID" "$tag"
}

# Export VLESS-xhttp-reality-enc Link
get_vless_xhttp_link() {
    local ip="${1:-$(get_public_ip)}"
    [[ ! -f "$DEGWD_ENV_FILE" ]] && return 1
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local xh_port="${XHTTP_PORT:-20081}"
    local enkey="${VLESS_ENKEY:-none}"
    local tag="de_GWD-VLESS-xhttp-enc"
    printf "vless://%s@%s:%s?encryption=none&security=reality&sni=%s&fp=chrome&pbk=%s&sid=%s&type=xhttp&path=/%s-xh&mode=auto#%s\n" \
        "$SERVER_UUID" "$ip" "$xh_port" "$REALITY_SNI" "$REALITY_PUB_KEY" "$REALITY_SHORT_ID" "$SERVER_UUID" "$tag"
}

# Export VLESS-ws Link
get_vless_ws_link() {
    local ip="${1:-$(get_public_ip)}"
    [[ ! -f "$DEGWD_ENV_FILE" ]] && return 1
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local ws_port="${WS_PORT:-20082}"
    local tag="de_GWD-VLESS-ws"
    printf "vless://%s@%s:%s?encryption=none&type=ws&security=none&path=/%s-vw#%s\n" \
        "$SERVER_UUID" "$ip" "$ws_port" "$SERVER_UUID" "$tag"
}

# Export Cloudflare Argo Tunnel Links (443 TLS & 80 Plain)
get_vless_argo_links() {
    [[ ! -f "$DEGWD_ENV_FILE" ]] && return 1
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local argo_domain=""
    if [[ -f "${DEGWD_ETC}/argo_domain" ]]; then
        argo_domain="$(cat "${DEGWD_ETC}/argo_domain" 2>/dev/null | tr -d '\r\n ')"
    fi
    if [[ -z "$argo_domain" ]]; then
        return 1
    fi

    local argo_tls_link="vless://${SERVER_UUID}@${argo_domain}:443?encryption=none&type=ws&host=${argo_domain}&path=/${SERVER_UUID}-vw&security=tls&sni=${argo_domain}&fp=chrome&insecure=0&allowInsecure=0#de_GWD-Argo-TLS-443"
    local argo_http_link="vless://${SERVER_UUID}@${argo_domain}:80?encryption=none&type=ws&host=${argo_domain}&path=/${SERVER_UUID}-vw&security=none#de_GWD-Argo-HTTP-80"

    printf "%s\n%s\n" "$argo_tls_link" "$argo_http_link"
}

# Export Hysteria 2 Link
get_hy2_link() {
    local ip="${1:-$(get_public_ip)}"
    [[ ! -f "$DEGWD_ENV_FILE" ]] && return 1
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local tag="de_GWD-Hysteria2"
    printf "hysteria2://%s@%s:%s/?insecure=1&allowInsecure=1&sni=degwd.network#%s\n" \
        "$HY2_PASSWORD" "$ip" "$HY2_PORT" "$tag"
}

# Print Beautiful Full Node Dashboard
print_node_info() {
    if [[ ! -f "$DEGWD_ENV_FILE" ]]; then
        msg_err "未找到服务端凭据信息，请先运行 [1. 安装/重新部署服务端]！"
        return 1
    fi
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local public_ip
    public_ip="$(get_public_ip)"

    local vless_re_url="$(get_vless_reality_link "$public_ip")"
    local vless_xh_url="$(get_vless_xhttp_link "$public_ip")"
    local vless_ws_url="$(get_vless_ws_link "$public_ip")"
    local hy2_url="$(get_hy2_link "$public_ip")"

    local all_links=("$vless_re_url" "$vless_xh_url" "$vless_ws_url" "$hy2_url")

    draw_section "1. VLESS-REALITY (Vision / TCP) 节点详情"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务器地址 (IP)" "$public_ip"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务端口 (Port)" "$VLESS_PORT"
    printf "  ${C_BOLD}%-18s${C_RESET} : %s\n" "用户 ID (UUID)" "$SERVER_UUID"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_GREEN}%s${C_RESET}\n" "流控 (Flow)" "xtls-rprx-vision"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_YELLOW}%s${C_RESET}\n" "伪装域名 (SNI)" "$REALITY_SNI"
    printf "  ${C_BOLD}%-18s${C_RESET} : %s\n" "Public Key" "$REALITY_PUB_KEY"
    printf "  ${C_BOLD}%-18s${C_RESET} : %s\n" "Short ID" "$REALITY_SHORT_ID"
    printf "\n  ${C_B_WHITE}VLESS-REALITY 直连链接：${C_RESET}\n  ${C_CYAN}%s${C_RESET}\n\n" "$vless_re_url"
    render_qr "$vless_re_url"

    draw_section "2. VLESS-xhttp-reality-enc (XHTTP / SplitHTTP) 节点详情"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务端口" "${XHTTP_PORT:-20081}"
    printf "  ${C_BOLD}%-18s${C_RESET} : %s\n" "传输类型 (Network)" "xhttp (mode=auto)"
    printf "  ${C_BOLD}%-18s${C_RESET} : %s\n" "Path 路径" "${SERVER_UUID}-xh"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_GREEN}%s${C_RESET}\n" "ENC 抗量子加密" "${VLESS_ENKEY:0:24}..."
    printf "\n  ${C_B_WHITE}VLESS-xhttp 节点直连链接：${C_RESET}\n  ${C_CYAN}%s${C_RESET}\n\n" "$vless_xh_url"
    render_qr "$vless_xh_url"

    draw_section "3. VLESS-ws-enc (WebSocket + CDN 优选) 节点详情"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务端口" "${WS_PORT:-20082}"
    printf "  ${C_BOLD}%-18s${C_RESET} : %s\n" "传输类型 (Network)" "ws"
    printf "  ${C_BOLD}%-18s${C_RESET} : %s\n" "Path 路径" "${SERVER_UUID}-vw"
    printf "\n  ${C_B_WHITE}VLESS-WS 节点直连链接：${C_RESET}\n  ${C_CYAN}%s${C_RESET}\n\n" "$vless_ws_url"
    render_qr "$vless_ws_url"

    # Cloudflare Argo Tunnel section
    local argo_links
    argo_links="$(get_vless_argo_links 2>/dev/null || true)"
    if [[ -n "$argo_links" ]]; then
        draw_section "4. Cloudflare Argo 穿透隧道节点 (免备案 · 免证书 · 全球 CDN)"
        local argo_domain
        argo_domain="$(cat "${DEGWD_ETC}/argo_domain" 2>/dev/null)"
        printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_GREEN}%s${C_RESET}\n" "Argo 隧道域名" "$argo_domain"
        local idx=1
        while IFS= read -r alink; do
            if [[ -n "$alink" ]]; then
                all_links+=("$alink")
                printf "\n  ${C_B_WHITE}Argo 节点链接 #%d：${C_RESET}\n  ${C_CYAN}%s${C_RESET}\n" "$idx" "$alink"
                ((idx++))
            fi
        done <<< "$argo_links"
    fi

    draw_section "5. Hysteria 2 (UDP/QUIC 抗高丢包拥塞控制) 节点详情"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务器地址 (IP)" "$public_ip"
    printf "  ${C_BOLD}%-18s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务端口 (UDP)" "$HY2_PORT"
    printf "  ${C_BOLD}%-18s${C_RESET} : %s\n" "认证密码" "$HY2_PASSWORD"
    printf "\n  ${C_B_WHITE}Hysteria 2 直连链接：${C_RESET}\n  ${C_CYAN}%s${C_RESET}\n\n" "$hy2_url"
    render_qr "$hy2_url"

    draw_section "Clash.Meta (Mihomo) 配置片段"
    cat << EOF
proxies:
  - name: "de_GWD-REALITY"
    type: vless
    server: ${public_ip}
    port: ${VLESS_PORT}
    uuid: ${SERVER_UUID}
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: ${REALITY_SNI}
    reality-opts:
      public-key: ${REALITY_PUB_KEY}
      short-id: ${REALITY_SHORT_ID}
    client-fingerprint: chrome

  - name: "de_GWD-Hysteria2"
    type: hysteria2
    server: ${public_ip}
    port: ${HY2_PORT}
    password: ${HY2_PASSWORD}
    skip-cert-verify: true
EOF

    draw_section "Base64 全协议聚合订阅链接"
    local raw_sub=""
    for lk in "${all_links[@]}"; do
        raw_sub+="${lk}"$'\n'
    done
    local b64_sub
    b64_sub="$(printf "%s" "$raw_sub" | base64 -w 0 2>/dev/null || printf "%s" "$raw_sub" | base64)"
    printf "  ${C_DIM}%s${C_RESET}\n" "$b64_sub"
}
