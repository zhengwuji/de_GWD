#!/usr/bin/env bash
# ==============================================================================
# de_GWD NextGen - Environment, Distro Compatibility & Kernel Tuning Library
# ==============================================================================

# Global Project Constants
readonly DEGWD_VERSION="2.0.0"
readonly DEGWD_BASE="${DEGWD_BASE:-/opt/de_GWD}"
readonly DEGWD_CORE="${DEGWD_BASE}/core"
readonly DEGWD_BIN="${DEGWD_BASE}/bin"
readonly DEGWD_ETC="${DEGWD_BASE}/etc"
readonly DEGWD_LOG="${DEGWD_BASE}/log"
readonly DEGWD_BACKUP="${DEGWD_BASE}/backup"
readonly DEGWD_SERVER_CONF="${DEGWD_ETC}/server.json"
readonly DEGWD_CLIENT_CONF="${DEGWD_ETC}/client.json"
readonly DEGWD_ENV_FILE="${DEGWD_BASE}/degwd.env"

# Root Permission Check
check_root() {
    if [[ $EUID -ne 0 ]]; then
        msg_err "此脚本需要 root 特权运行。请使用 sudo 或切换至 root 用户执行！"
        exit 1
    fi
}

# Detect CPU Architecture
detect_arch() {
    local raw_arch
    raw_arch="$(uname -m)"
    case "$raw_arch" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            msg_err "不支持的 CPU 架构: ${raw_arch} (仅支持 amd64 与 arm64)"
            exit 1
            ;;
    esac
}

# Detect Linux Distribution and Version (Debian/Ubuntu & OpenWrt adaptive)
detect_os() {
    if [[ -f /etc/openwrt_release ]]; then
        # shellcheck disable=SC1091
        source /etc/openwrt_release
        echo "openwrt:${DISTRIB_RELEASE:-unknown}"
        return 0
    fi

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        local distro="${ID:-unknown}"
        local version="${VERSION_ID:-0}"

        if [[ "$distro" =~ ^(openwrt|kwrt|lede|immortalwrt)$ ]] || [[ "${ID_LIKE:-}" =~ (openwrt|lede) ]]; then
            echo "openwrt:${version}"
            return 0
        fi

        case "$distro" in
            debian)
                local ver_major
                ver_major="${version%%.*}"
                if [[ "$ver_major" -lt 11 ]]; then
                    msg_warn "检测到旧版 Debian ($version)，建议升级至 Debian 11/12/13 以获得最佳网络性能！"
                fi
                echo "debian:${version}"
                ;;
            ubuntu)
                local ver_major
                ver_major="${version%%.*}"
                if [[ "$ver_major" -lt 20 ]]; then
                    msg_warn "检测到旧版 Ubuntu ($version)，建议升级至 Ubuntu 22.04/24.04 LTS！"
                fi
                echo "ubuntu:${version}"
                ;;
            *)
                msg_warn "当前检测到系统: ${distro} (${version})。de_GWD 已适配 Debian / Ubuntu 及 OpenWrt。"
                echo "${distro}:${version}"
                ;;
        esac
    else
        echo "linux:unknown"
    fi
}

# Detect Virtualization Environment
detect_virt() {
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        systemd-detect-virt 2>/dev/null || echo "none"
    elif [[ -f /etc/openwrt_release || -f /etc/rc.common ]]; then
        echo "router/baremetal"
    else
        echo "unknown"
    fi
}

# Detect Default Network Interface
get_default_iface() {
    local iface
    iface="$(ip -4 route show default 2>/dev/null | awk '{print $5}' | head -n1)"
    if [[ -z "$iface" ]]; then
        iface="$(ip route show default 2>/dev/null | awk '{print $5}' | head -n1)"
    fi
    echo "${iface:-eth0}"
}

# Get Public IPv4 Address with Fallback
get_public_ip() {
    local ip
    ip="$(curl -4 -fsSL --max-time 4 https://api.ipify.org 2>/dev/null || \
          curl -4 -fsSL --max-time 4 https://icanhazip.com 2>/dev/null || \
          curl -4 -fsSL --max-time 4 https://ifconfig.me 2>/dev/null)"
    if [[ -z "$ip" ]]; then
        # Local interface IP as fallback
        ip="$(ip -4 addr show "$(get_default_iface)" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)"
    fi
    echo "${ip:-127.0.0.1}"
}

# Ensure Core Base Directories Exist
ensure_dirs() {
    mkdir -p "${DEGWD_BASE}" "${DEGWD_BIN}" "${DEGWD_ETC}" "${DEGWD_LOG}" "${DEGWD_BACKUP}"
    chmod 755 "${DEGWD_BASE}" "${DEGWD_BIN}" "${DEGWD_ETC}"
    chmod 700 "${DEGWD_LOG}" "${DEGWD_BACKUP}"
}

# Install System Prerequisites (adaptive for apt-get and opkg)
install_prereqs() {
    msg_step "检查并安装基础运行时依赖..."

    # OpenWrt (opkg)
    if command -v opkg >/dev/null 2>&1; then
        local pkgs=(curl wget jq openssl tar)
        local to_install=()
        for pkg in "${pkgs[@]}"; do
            if ! command -v "$pkg" >/dev/null 2>&1; then
                to_install+=("$pkg")
            fi
        done
        if [[ ${#to_install[@]} -gt 0 ]]; then
            msg_info "正在通过 opkg 安装缺失依赖: ${to_install[*]}"
            opkg update >/dev/null 2>&1 || true
            opkg install "${to_install[@]}" >/dev/null 2>&1 || true
        fi
        if [[ ! -c /dev/net/tun ]]; then
            msg_info "检测到 tun 虚拟网卡支持未加载，尝试安装 kmod-tun..."
            opkg install kmod-tun >/dev/null 2>&1 || true
        fi
        msg_ok "系统核心依赖就绪 (OpenWrt/opkg)"
        return 0
    fi

    # Debian / Ubuntu (apt-get)
    export DEBIAN_FRONTEND=noninteractive

    local pkgs=(
        curl
        wget
        jq
        openssl
        ca-certificates
        tar
        iproute2
        procps
        nftables
        iptables
        qrencode
        socat
    )

    local to_install=()
    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        msg_info "正在通过 apt 安装缺失依赖: ${to_install[*]}"
        apt-get update -qq >/dev/null 2>&1 || true
        apt-get install -y -qq "${to_install[@]}" >/dev/null 2>&1 || {
            msg_warn "部分软件包静默安装失败，尝试重试..."
            apt-get install -y "${to_install[@]}"
        }
    fi
    msg_ok "系统核心依赖就绪"
}

# Kernel Optimization & BBR Congestion Control
tune_kernel() {
    msg_step "检测并配置 Linux 内核参数与 BBR 拥塞控制..."

    # Check kernel support for BBR
    local current_cc
    current_cc="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")"
    
    local sysctl_file="/etc/sysctl.d/99-degwd.conf"
    cat << 'EOF' > "$sysctl_file"
# de_GWD High-Performance Network Tuning
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 100000
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
fs.file-max = 1000000
EOF

    # Apply sysctl parameters safely
    sysctl --system >/dev/null 2>&1 || sysctl -p "$sysctl_file" >/dev/null 2>&1 || sysctl -p /etc/sysctl.conf >/dev/null 2>&1 || true

    local new_cc
    new_cc="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")"
    if [[ "$new_cc" == "bbr" ]]; then
        msg_ok "BBR 拥塞控制与内核高并发网络栈已生效 (BBR + FQ)"
    else
        msg_warn "当前系统内核报告拥塞控制为: ${new_cc} (容器环境或旧内核可能需要宿主机支持)"
    fi
}

# Init System Detection & Universal Service Management (systemd & OpenWrt procd)
is_systemd() {
    command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system || -d /etc/systemd/system ]]
}

is_openwrt() {
    [[ -f /etc/openwrt_release || -f /etc/rc.common ]] || grep -qiE 'openwrt|kwrt|lede|immortalwrt' /etc/os-release 2>/dev/null
}

svc_start() {
    local svc="$1"
    if is_systemd; then
        systemctl start "$svc"
    elif [[ -x "/etc/init.d/$svc" ]]; then
        "/etc/init.d/$svc" start
    else
        return 1
    fi
}

svc_stop() {
    local svc="$1"
    if is_systemd; then
        systemctl stop "$svc" >/dev/null 2>&1 || true
    elif [[ -x "/etc/init.d/$svc" ]]; then
        "/etc/init.d/$svc" stop >/dev/null 2>&1 || true
    fi
}

svc_restart() {
    local svc="$1"
    if is_systemd; then
        systemctl restart "$svc"
    elif [[ -x "/etc/init.d/$svc" ]]; then
        "/etc/init.d/$svc" restart
    else
        return 1
    fi
}

svc_enable() {
    local svc="$1"
    if is_systemd; then
        systemctl enable "$svc" >/dev/null 2>&1 || true
    elif [[ -x "/etc/init.d/$svc" ]]; then
        "/etc/init.d/$svc" enable >/dev/null 2>&1 || true
    fi
}

svc_disable() {
    local svc="$1"
    if is_systemd; then
        systemctl disable "$svc" >/dev/null 2>&1 || true
    elif [[ -x "/etc/init.d/$svc" ]]; then
        "/etc/init.d/$svc" disable >/dev/null 2>&1 || true
    fi
}

svc_is_active() {
    local svc="$1"
    if is_systemd; then
        systemctl is-active "$svc" >/dev/null 2>&1
    elif [[ -x "/etc/init.d/$svc" ]]; then
        if "/etc/init.d/$svc" running >/dev/null 2>&1; then
            return 0
        fi
        pgrep -f "sing-box.*${svc}" >/dev/null 2>&1 || \
        pgrep -f "xray.*${svc}" >/dev/null 2>&1 || \
        pgrep -f "/opt/de_GWD/.*${svc}" >/dev/null 2>&1
    else
        return 1
    fi
}

svc_unit_exists() {
    local svc="$1"
    if is_systemd; then
        systemctl list-unit-files 2>/dev/null | grep -q "${svc}\.service" || [[ -f "/etc/systemd/system/${svc}.service" ]]
    elif [[ -f "/etc/init.d/${svc}" ]]; then
        return 0
    else
        return 1
    fi
}

is_service_active() {
    svc_is_active "$1"
}

is_port_in_use() {
    local port="$1"
    local proto="${2:-tcp}"
    if command -v ss >/dev/null 2>&1; then
        if [[ "$proto" == "udp" ]]; then
            ss -uln 2>/dev/null | grep -qE ":${port}\s"
        else
            ss -tln 2>/dev/null | grep -qE ":${port}\s"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if [[ "$proto" == "udp" ]]; then
            netstat -uln 2>/dev/null | grep -qE ":${port}\s"
        else
            netstat -tln 2>/dev/null | grep -qE ":${port}\s"
        fi
    elif command -v lsof >/dev/null 2>&1; then
        lsof -i ":$port" >/dev/null 2>&1
    else
        return 1
    fi
}
# Change WebUI Admin Password (double SHA256 hashed matching auth.php)
change_web_password() {
    local conf_file="/opt/de_GWD/0conf"
    mkdir -p "/opt/de_GWD"
    if [[ ! -f "$conf_file" ]]; then
        echo '{"address":{"alias":"de_GWD","PWD":""},"v2node":[]}' > "$conf_file"
        chmod 666 "$conf_file"
    fi

    local new_pass="$1"
    if [[ -z "$new_pass" ]]; then
        read -rsp "  请输入新的 Web 面板管理密码: " new_pass
        echo
        read -rsp "  请再次输入新密码以确认: " confirm_pass
        echo
        if [[ "$new_pass" != "$confirm_pass" ]]; then
            msg_err "两次输入的密码不一致！"
            return 1
        fi
        if [[ -z "$new_pass" ]]; then
            msg_err "密码不能为空！"
            return 1
        fi
    fi

    local hash1 hash2
    hash1="$(printf "%s" "$new_pass" | sha256sum | awk '{print $1}')"
    hash2="$(printf "%s" "$hash1" | sha256sum | awk '{print $1}')"

    local tmp_conf
    tmp_conf="$(mktemp)"
    jq --arg pwd "$hash2" '.address.PWD = $pwd' "$conf_file" > "$tmp_conf" && mv -f "$tmp_conf" "$conf_file"
    chmod 666 "$conf_file"
    msg_ok "Web 控制面板密码已更新成功！"
}

# Thorough Clean Uninstall Everything
thorough_uninstall() {
    msg_step "正在执行彻底干净卸载..."

    # 1. Stop and disable all related services
    local services=(degwd-server degwd-client degwd-xray-server degwd-xray-client degwd-argo coredns mosdns smartdns vtrui haproxy)
    for svc in "${services[@]}"; do
        svc_stop "$svc"
        svc_disable "$svc"
        rm -f "/etc/systemd/system/${svc}.service"
        rm -f "/lib/systemd/system/${svc}.service"
        rm -f "/etc/init.d/${svc}"
    done
    if is_systemd; then
        systemctl daemon-reload >/dev/null 2>&1 || true
    fi

    # 2. Terminate background processes if any
    killall -9 sing-box xray cloudflared vtrui coredns smartdns mosdns 2>/dev/null || true

    # 3. Clean firewall, NAT and routing tables
    if command -v nft >/dev/null 2>&1; then
        nft delete table inet degwd_nat 2>/dev/null || true
        nft delete table ip de_GWD 2>/dev/null || true
    fi
    if command -v iptables >/dev/null 2>&1; then
        local def_iface
        def_iface="$(get_default_iface)"
        if [[ -n "$def_iface" ]]; then
            iptables -t nat -D POSTROUTING -o "$def_iface" -j MASQUERADE 2>/dev/null || true
        fi
    fi

    # 4. Remove directories and data files
    rm -rf /opt/de_GWD
    rm -f /etc/sysctl.d/99-degwd.conf /etc/sysctl.d/99-degwd-bbr.conf
    rm -f /etc/nginx/conf.d/degwd.conf /var/www/ssl/de_GWD.* 2>/dev/null || true

    # 5. Remove system symlinks
    rm -f /usr/local/bin/degwd /usr/local/bin/degwd-server /usr/local/bin/degwd-client /usr/local/bin/gwd
    rm -f /usr/bin/degwd /usr/bin/degwd-server /usr/bin/degwd-client /usr/bin/gwd

    # 6. Reload sysctl
    sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.conf >/dev/null 2>&1 || true

    msg_ok "已彻底干净卸载 de_GWD，所有服务、端口、防火墙规则、配置文件与残留已被清除！"
}

# Auto load UI library if available
if [[ -f "${DEGWD_CORE}/ui.sh" ]]; then
    # shellcheck disable=SC1090
    source "${DEGWD_CORE}/ui.sh"
fi