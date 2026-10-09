#!/usr/bin/env bash
# ==============================================================================
# de_GWD NextGen - UI & Terminal Styling Library
# ==============================================================================

# Idempotency guard
if [[ -n "${_DEGWD_UI_LOADED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
_DEGWD_UI_LOADED=1

# ANSI Color & Style Palette
readonly C_RESET="\033[0m"
readonly C_BOLD="\033[1m"
readonly C_DIM="\033[2m"
readonly C_UNDERLINE="\033[4m"

readonly C_BLACK="\033[30m"
readonly C_RED="\033[31m"
readonly C_GREEN="\033[32m"
readonly C_YELLOW="\033[33m"
readonly C_BLUE="\033[34m"
readonly C_MAGENTA="\033[35m"
readonly C_CYAN="\033[36m"
readonly C_WHITE="\033[37m"

readonly C_B_RED="\033[1;31m"
readonly C_B_GREEN="\033[1;32m"
readonly C_B_YELLOW="\033[1;33m"
readonly C_B_BLUE="\033[1;34m"
readonly C_B_MAGENTA="\033[1;35m"
readonly C_B_CYAN="\033[1;36m"
readonly C_B_WHITE="\033[1;37m"

msg_info() {
    printf "${C_B_BLUE}[INFO]${C_RESET} %b\n" "$*"
}

msg_ok() {
    printf "${C_B_GREEN}[ OK ]${C_RESET} %b\n" "$*"
}

msg_warn() {
    printf "${C_B_YELLOW}[WARN]${C_RESET} %b\n" "$*"
}

msg_err() {
    printf "${C_B_RED}[FAIL]${C_RESET} %b\n" "$*" >&2
}

msg_step() {
    printf "${C_B_CYAN}[ >> ]${C_RESET} %b\n" "$*"
}

draw_line() {
    local char="${1:-─}"
    local len="${2:-66}"
    printf "${C_DIM}"
    printf '%*s' "$len" '' | tr ' ' "$char"
    printf "${C_RESET}\n"
}

draw_banner() {
    local role="${1:-System}"
    clear 2>/dev/null || true
    printf "${C_B_CYAN}"
    cat << 'EOF'
  ____     ______        ______
 / __ \___/ ____/ _    _/ __   \
/ / / / _ \/ __  | |  /| / / / /
 /_/ /  __/ /_/ /| | / |/ /_/ / 
\__,_/\___/\____/| |/| /_____/  
                 |__/           NextGen
EOF
    printf "${C_RESET}"
    printf "${C_B_WHITE}  de_GWD v2.0 · 现代高性能网络网关与防审查协议路由套件${C_RESET}\n"
    printf "${C_DIM}  原生支持 Debian 11/12/13 · Ubuntu 20.04/22.04/24.04 · VLESS-REALITY / Hy2${C_RESET}\n"
    printf "${C_B_MAGENTA}  当前角色: [ %s ]${C_RESET}\n" "$role"
    draw_line "━" 66
}

draw_status_row() {
    local label="$1"
    local status="$2"
    local extra="${3:-}"
    
    local badge
    case "$status" in
        "active"|"running"|"1"|"true")
            badge="${C_B_GREEN}● 运行中${C_RESET}"
            ;;
        "inactive"|"stopped"|"0"|"false")
            badge="${C_B_RED}○ 未运行${C_RESET}"
            ;;
        "not_installed")
            badge="${C_B_YELLOW}✕ 未安装${C_RESET}"
            ;;
        *)
            badge="${C_B_CYAN}${status}${C_RESET}"
            ;;
    esac
    
    if [[ -n "$extra" ]]; then
        printf "  %-22s : %-20b ${C_DIM}(%s)${C_RESET}\n" "$label" "$badge" "$extra"
    else
        printf "  %-22s : %-20b\n" "$label" "$badge"
    fi
}

draw_menu_item() {
    local num="$1"
    local desc="$2"
    local tag="${3:-}"
    if [[ -n "$tag" ]]; then
        printf "  ${C_B_CYAN}[%2s]${C_RESET} %-36s ${C_YELLOW}%s${C_RESET}\n" "$num" "$desc" "$tag"
    else
        printf "  ${C_B_CYAN}[%2s]${C_RESET} %s\n" "$num" "$desc"
    fi
}

draw_section() {
    local title="$1"
    printf "\n${C_B_WHITE}▶ %s${C_RESET}\n" "$title"
    draw_line "─" 66
}

render_qr() {
    local data="$1"
    if command -v qrencode >/dev/null 2>&1; then
        qrencode -t ANSIUTF8 "$data"
    elif command -v python3 >/dev/null 2>&1 && python3 -c 'import qrcode' >/dev/null 2>&1; then
        python3 -c "import qrcode; qr=qrcode.QRCode(); qr.add_data('$data'); qr.print_ascii(invert=True)"
    else
        msg_warn "未检测到 qrencode 工具，以下为原始节点链接："
        printf "${C_UNDERLINE}${C_CYAN}%s${C_RESET}\n" "$data"
    fi
}