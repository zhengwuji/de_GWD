#!/usr/bin/env bash
# ==============================================================================
# de_GWD NextGen - Modern Nftables & LAN Transparent Gateway NAT Library
# ==============================================================================

# Enable LAN Gateway NAT Forwarding (Side-router / Gateway Mode)
setup_gateway_nat() {
    msg_step "配置局域网透明网关 NAT 转发与防火墙规则..."

    # Ensure IP forwarding in kernel
    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
    sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null 2>&1

    local default_iface
    default_iface="$(get_default_iface)"

    if command -v nft >/dev/null 2>&1; then
        msg_info "应用原生 nftables 极速流表 NAT 规则..."
        nft delete table inet degwd_nat 2>/dev/null || true
        nft -f - << EOF
table inet degwd_nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "${default_iface}" masquerade
        oifname "degwd-tun" masquerade
    }
}
EOF
        msg_ok "nftables 局域网 NAT 转发已配置 (出口: ${default_iface})"
    elif command -v iptables >/dev/null 2>&1; then
        msg_info "应用 iptables NAT 转发规则..."
        iptables -t nat -D POSTROUTING -o "$default_iface" -j MASQUERADE 2>/dev/null || true
        iptables -t nat -A POSTROUTING -o "$default_iface" -j MASQUERADE
        msg_ok "iptables 局域网 NAT 转发已配置 (出口: ${default_iface})"
    else
        msg_warn "未检测到 nftables 或 iptables 工具，旁路由 NAT 需手动转发"
    fi
}

# Clear NAT and Gateway rules safely
clean_gateway_nat() {
    msg_step "清理局域网 NAT 与防火墙规则..."
    if command -v nft >/dev/null 2>&1; then
        nft delete table inet degwd_nat 2>/dev/null || true
    fi
    if command -v iptables >/dev/null 2>&1; then
        local default_iface
        default_iface="$(get_default_iface)"
        iptables -t nat -D POSTROUTING -o "$default_iface" -j MASQUERADE 2>/dev/null || true
    fi
    msg_ok "防火墙 NAT 规则已清理还原"
}