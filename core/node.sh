#!/usr/bin/env bash
# ==============================================================================
# de_GWD NextGen - Node Export, URI & Subscription Formatter
# ==============================================================================

# Export VLESS-REALITY Link
get_vless_link() {
    local ip="${1:-$(get_public_ip)}"
    if [[ ! -f "$DEGWD_ENV_FILE" ]]; then
        return 1
    fi
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local tag="de_GWD-VLESS-REALITY"
    printf "vless://%s@%s:%s?security=reality&encryption=none&pbk=%s&headerType=none&fp=chrome&type=tcp&flow=xtls-rprx-vision&sni=%s&sid=%s#%s\n" \
        "$SERVER_UUID" "$ip" "$VLESS_PORT" "$REALITY_PUB_KEY" "$REALITY_SNI" "$REALITY_SHORT_ID" "$tag"
}

# Export Hysteria 2 Link
get_hy2_link() {
    local ip="${1:-$(get_public_ip)}"
    if [[ ! -f "$DEGWD_ENV_FILE" ]]; then
        return 1
    fi
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local tag="de_GWD-Hysteria2"
    printf "hysteria2://%s@%s:%s/?insecure=1&sni=degwd.network#%s\n" \
        "$HY2_PASSWORD" "$ip" "$HY2_PORT" "$tag"
}

# Print Beautiful Node Card
print_node_info() {
    if [[ ! -f "$DEGWD_ENV_FILE" ]]; then
        msg_err "未找到服务端凭据信息，请先运行 [1. 安装/重置服务端]！"
        return 1
    fi
    # shellcheck disable=SC1090
    source "$DEGWD_ENV_FILE"

    local public_ip
    public_ip="$(get_public_ip)"

    local vless_url
    vless_url="$(get_vless_link "$public_ip")"
    local hy2_url
    hy2_url="$(get_hy2_link "$public_ip")"

    draw_section "VLESS-REALITY (Vision / TCP) 节点详情"
    printf "  ${C_BOLD}%-16s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务器地址 (IP)" "$public_ip"
    printf "  ${C_BOLD}%-16s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务端口 (Port)" "$VLESS_PORT"
    printf "  ${C_BOLD}%-16s${C_RESET} : %s\n" "用户 ID (UUID)" "$SERVER_UUID"
    printf "  ${C_BOLD}%-16s${C_RESET} : ${C_B_GREEN}%s${C_RESET}\n" "流控 (Flow)" "xtls-rprx-vision"
    printf "  ${C_BOLD}%-16s${C_RESET} : %s\n" "加密方式" "none"
    printf "  ${C_BOLD}%-16s${C_RESET} : ${C_B_YELLOW}%s${C_RESET}\n" "伪装域名 (SNI)" "$REALITY_SNI"
    printf "  ${C_BOLD}%-16s${C_RESET} : %s\n" "公钥 (Public Key)" "$REALITY_PUB_KEY"
    printf "  ${C_BOLD}%-16s${C_RESET} : %s\n" "Short ID" "$REALITY_SHORT_ID"
    printf "  ${C_BOLD}%-16s${C_RESET} : %s\n" "客户端指纹" "chrome"

    printf "\n  ${C_B_WHITE}VLESS 节点直连链接：${C_RESET}\n"
    printf "  ${C_CYAN}%s${C_RESET}\n\n" "$vless_url"
    printf "  ${C_B_WHITE}VLESS 节点二维码：${C_RESET}\n"
    render_qr "$vless_url"

    draw_section "Hysteria 2 (UDP/QUIC 抗丢包拥塞控制) 节点详情"
    printf "  ${C_BOLD}%-16s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务器地址 (IP)" "$public_ip"
    printf "  ${C_BOLD}%-16s${C_RESET} : ${C_B_CYAN}%s${C_RESET}\n" "服务端口 (UDP)" "$HY2_PORT"
    printf "  ${C_BOLD}%-16s${C_RESET} : %s\n" "认证密码" "$HY2_PASSWORD"
    printf "  ${C_BOLD}%-16s${C_RESET} : %s\n" "TLS 证书跳过验证" "true (自签凭证)"

    printf "\n  ${C_B_WHITE}Hysteria 2 节点直连链接：${C_RESET}\n"
    printf "  ${C_CYAN}%s${C_RESET}\n\n" "$hy2_url"
    printf "  ${C_B_WHITE}Hysteria 2 节点二维码：${C_RESET}\n"
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

    draw_section "Base64 订阅链接内容"
    local raw_sub
    raw_sub=$(printf "%s\n%s\n" "$vless_url" "$hy2_url" | base64 -w 0 2>/dev/null || printf "%s\n%s\n" "$vless_url" "$hy2_url" | base64)
    printf "  ${C_DIM}%s${C_RESET}\n" "$raw_sub"
}