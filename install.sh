#!/usr/bin/env bash
# ==============================================================================
# de_GWD NextGen - Universal One-Click Installer
# Compatible with Debian 11/12/13 & Ubuntu 20.04/22.04/24.04 LTS (amd64 / arm64)
# ==============================================================================

set -e

readonly DEGWD_INSTALL_DIR="/opt/de_GWD"

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31m[错误]\033[0m 请使用 root 权限运行此安装脚本！" >&2
    exit 1
fi

echo -e "\033[1;36m===============================================================\033[0m"
echo -e "\033[1;37m        de_GWD NextGen v2.0 · 新一代网络网关一键管理器          \033[0m"
echo -e "\033[1;36m===============================================================\033[0m"

# Ensure target directories exist
mkdir -p "${DEGWD_INSTALL_DIR}" "${DEGWD_INSTALL_DIR}/core" "${DEGWD_INSTALL_DIR}/bin" "${DEGWD_INSTALL_DIR}/etc"

# If running from local repository directory, copy local files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
if [[ -n "$SCRIPT_DIR" && -f "${SCRIPT_DIR}/server" && -f "${SCRIPT_DIR}/core/env.sh" ]]; then
    echo -e "\033[1;32m[>>]\033[0m 从本地目录同步文件至 ${DEGWD_INSTALL_DIR}..."
    cp -rf "${SCRIPT_DIR}/server" "${DEGWD_INSTALL_DIR}/"
    cp -rf "${SCRIPT_DIR}/client" "${DEGWD_INSTALL_DIR}/"
    cp -rf "${SCRIPT_DIR}/core" "${DEGWD_INSTALL_DIR}/"
    if [[ -d "${SCRIPT_DIR}/resource" ]]; then
        cp -rf "${SCRIPT_DIR}/resource" "${DEGWD_INSTALL_DIR}/"
    fi
else
    # Remote raw installation from repository
    echo -e "\033[1;32m[>>]\033[0m 从 GitHub 拉取 de_GWD NextGen 最新文件..."
    REPO_RAW="https://raw.githubusercontent.com/zhengwuji/de_GWD/main"
    MIRROR_RAW="https://ghfast.top/${REPO_RAW}"

    dl() {
        local rel="$1"
        local target="${DEGWD_INSTALL_DIR}/${rel}"
        mkdir -p "$(dirname "$target")"
        if ! curl -fsSL --max-time 15 "${REPO_RAW}/${rel}" -o "$target" 2>/dev/null; then
            curl -fsSL --max-time 15 "${MIRROR_RAW}/${rel}" -o "$target"
        fi
    }

    dl "server"
    dl "client"
    dl "core/env.sh"
    dl "core/ui.sh"
    dl "core/singbox.sh"
    dl "core/node.sh"
    dl "core/xray.sh"
    dl "core/nftables.sh"
fi

chmod +x "${DEGWD_INSTALL_DIR}/server" "${DEGWD_INSTALL_DIR}/client"
chmod +x "${DEGWD_INSTALL_DIR}"/core/*.sh 2>/dev/null || true

# Setup system command symlink
ln -sf "${DEGWD_INSTALL_DIR}/server" /usr/local/bin/degwd-server
ln -sf "${DEGWD_INSTALL_DIR}/client" /usr/local/bin/degwd-client
ln -sf "${DEGWD_INSTALL_DIR}/server" /usr/local/bin/degwd
ln -sf "${DEGWD_INSTALL_DIR}/server" /usr/local/bin/gwd

echo -e "\033[1;32m[ OK ]\033[0m de_GWD NextGen 组件已就绪！"
echo -e "快捷管理命令: \033[1;33mdegwd\033[0m (服务端) 或 \033[1;33mdegwd-client\033[0m (客户端/网关)"
echo

ROLE="${1:-}"
if [[ -z "$ROLE" ]]; then
    echo -e "请选择操作："
    echo -e "  \033[1;36m1.\033[0m 部署服务端 (Server · 运行在境外 VPS 上，提供 VLESS-REALITY / Hy2 节点)"
    echo -e "  \033[1;36m2.\033[0m 部署客户端 / 透明网关 (Client · 运行在本地设备，实现全局/旁路由翻墙)"
    echo -e "  \033[1;36m3.\033[0m 更改 Web 控制面板管理密码"
    echo -e "  \033[1;31m4.\033[0m 彻底干净卸载 de_GWD 并清除所有配置与残留"
    echo -e "  \033[1;37m0.\033[0m 仅安装管理命令并退出"
    read -rp "请输入选项 [默认: 1]: " choice
    case "$choice" in
        2) ROLE="client" ;;
        3) 
            # shellcheck disable=SC1091
            source "${DEGWD_INSTALL_DIR}/core/env.sh"
            change_web_password
            exit 0
            ;;
        4)
            # shellcheck disable=SC1091
            source "${DEGWD_INSTALL_DIR}/core/env.sh"
            thorough_uninstall
            exit 0
            ;;
        0) exit 0 ;;
        *) ROLE="server" ;;
    esac
fi

if [[ "$ROLE" == "client" ]]; then
    exec "${DEGWD_INSTALL_DIR}/client"
else
    exec "${DEGWD_INSTALL_DIR}/server"
fi