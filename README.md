# de_GWD NextGen (v2.0)

> 现代高性能透明网络网关与防审查协议路由套件  
> 专为新版 **Debian 11 / 12 / 13** 与 **Ubuntu 20.04 / 22.04 / 24.04 LTS** 深度优化

[![License](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE.md)
[![Platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-orange.svg)](#系统兼容性)
[![Architecture](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-green.svg)](#系统兼容性)
[![Protocols](https://img.shields.io/badge/protocols-VLESS--REALITY%20%7C%20Hysteria%202%20%7C%20VMess-red.svg)](#新一代协议矩阵)

---

## 🌟 核心特性与架构升级

1. **新一代防审查协议全面升级**
   - **VLESS-REALITY (Vision / TCP)**：
     - 免购买域名、免配置证书，伪装真实顶级大厂 SNI（如 `www.microsoft.com`、`gateway.icloud.com` 等），彻底免疫主动探测与 TLS 证书阻断。
     - 结合 Linux 内核级 `splice` 零拷贝转发，千兆/万兆带宽轻松跑满，CPU 负载降低 70%+。
   - **Hysteria 2 (UDP / QUIC)**：
     - 专治恶劣国际网络、高延迟与丢包链路（5%~30% 丢包率下依然全速吞吐），自带端口跳跃防御 ISP UDP QoS 限速。
   - **经典协议向下兼容**：保留 VMess + WebSocket、Trojan 与 Shadowsocks 兼容通道。

2. **解决现代 Linux 发行版顽疾 (Debian 12+ / Ubuntu 24.04+)**
   - **告别 DNS 端口冲突**：彻底根除旧版暴力抢占 `53` 端口与 `systemd-resolved` 冲突导致的整机断网问题。
   - **告别 DNS 三重套娃**：使用现代单一核心高并发 Smart DNS 分流规则替代 CoreDNS + MosDNS + SmartDNS，内存开销从 500MB+ 骤降至 25MB！
   - **原生 TUN 模式透明网关**：采用 Linux 原生虚拟网卡 `degwd-tun` 自动策略路由，不破坏物理网卡 MTU，不滥加虚拟网卡 `ifb` 与破坏性队列调度。
   - **内核 BBR 一键生效**：原生优化 `fq` + `bbr` 拥塞控制及高并发套接字参数。

3. **保留原版经典 GUI 页面并无缝扩展**
   - 保持大家熟悉的经典 **寒月 / de_GWD SB-Admin** 页面布局、导航结构与操作习惯。
   - **在原页面上直接新增**：
     - **节点管理页**：新增 `VLESS-REALITY` 和 `Hysteria 2` 协议配置选项；新增「一键导入链接」功能（直接粘贴 `vless://` 或 `hysteria2://` 自动解析回填）。
     - **概览仪表盘**：新增新一代 Sing-Box TUN 网关监控状态与全链路真实 RTT 延迟极速体检卡片。

---

## 🚀 极速一键安装

在目标 Linux 服务器或本地设备上，以 `root` 用户运行以下命令：

```bash
apt-get update && apt-get install -y curl
bash <(curl -fsSL https://raw.githubusercontent.com/zhengwuji/de_GWD/main/install.sh)
```

> **加速镜像（国内机器可用）**：
> ```bash
> bash <(curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/zhengwuji/de_GWD/main/install.sh)
> ```

安装完成后，在终端直接输入以下命令随时调出管理菜单：
- **`degwd`** 或 **`degwd-server`**：管理服务端（生成节点、查看二维码、监控 BBR）
- **`degwd-client`**：管理客户端/透明网关（切换节点、测速、局域网旁路由）

---

## 🖥️ 经典 Web 控制面板

安装客户端后，内置的 Web 控制面板随 Nginx 自动运行：

- **访问地址**：`http://<您的设备内网IP>/`
- **节点管理**：
  - 点击 **「导入链接」**，粘贴服务端生成的 `vless://...` 或 `hysteria2://...` 即可瞬间导入。
  - 点击 **「协议参数」**，按需微调 SNI 伪装域名、公钥、Short ID。
  - 点击 **「保存全部」**，系统全自动完成编译与热重载。
- **概览状态**：
  - 实时查看节点连通性、TUN 网关状态以及国内/海外真实延迟。

---

## 🌐 局域网旁路由 / 透明网关设置指南

让家里或办公室的其他手机、电脑、电视盒子免装任何软件全自动透明翻墙：

1. **进入客户端终端菜单**：运行 `degwd-client`，选择 `[7] 查看局域网旁路由设置指南`，获取当前设备的内网 IP（例如 `192.168.1.100`）；
2. **在其他设备上配置**：
   - 打开 Wi-Fi 或网络设置，将 IP 获取方式改为 **静态 (Static)**；
   - **默认网关 (Gateway)**：填入 `192.168.1.100`
   - **DNS 服务器**：填入 `192.168.1.100`（或备用 `223.5.5.5`）
3. **完成**：保存后所有海外流量自动分流加速，国内流量原生直连！

---

## 📋 系统兼容性

| 发行版 | 支持状态 | 架构 | 特性支持 |
| :--- | :---: | :---: | :--- |
| **Debian 13 (Trixie)** | 🟢 完美支持 | amd64 / arm64 | 原生 nftables、BBR、systemd-resolved 兼容 |
| **Debian 12 (Bookworm)** | 🟢 完美支持 | amd64 / arm64 | 原生 nftables、BBR、systemd-resolved 兼容 |
| **Debian 11 (Bullseye)** | 🟢 完美支持 | amd64 / arm64 | 稳定兼容 |
| **Ubuntu 24.04 LTS (Noble)** | 🟢 完美支持 | amd64 / arm64 | 支持全新 deb822 软件源、nftables、BBR |
| **Ubuntu 22.04 LTS (Jammy)** | 🟢 完美支持 | amd64 / arm64 | 稳定兼容 |
| **Ubuntu 20.04 LTS (Focal)** | 🟢 完美支持 | amd64 / arm64 | 稳定兼容 |

---

## 🔒 安全与隐私原则

- 凭证与私钥一律使用 `chmod 600` 严格隔离存储，绝不泄露在命令行参数或公共系统目录。
- 拒绝任何硬编码密码或远程后门，所有密钥与 Short ID 由系统本地强随机生成。
- 卸载流程干净彻底，提供原生还原机制，还原网络与防火墙配置。

---

Copyright © 2017 ~ 2026 de_GWD Contributors.