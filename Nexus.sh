#!/bin/bash

# ================== Nexus CLI 管理脚本 ==================
# 作者：K2 节点教程分享
# 推特：@BtcK241918
# ========================================================

# 彩色定义
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # 无颜色

# 更新系统并安装依赖项，包括 screen
echo -e "${GREEN}🔄 正在更新系统并安装依赖项...${NC}"
apt-get update && apt-get upgrade -y
apt-get install -y pkg-config libssl-dev curl protobuf-compiler screen

# 检查 Rust 是否安装
if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}⚠️  Rust 未安装，正在安装...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo -e "${GREEN}✅ Rust 已安装，跳过安装。${NC}"
fi

# 确保 Rust 环境已加载
source "$HOME/.cargo/env"

# 安装并启动 Nexus CLI
install_and_run_nexus_cli() {
    if screen -list | grep -q "nexus-cli-session"; then
        echo -e "${GREEN}🚀 Nexus CLI 已在运行，跳过启动。${NC}"
    else
        echo -e "${BLUE}🔧 正在创建 screen 会话并安装 Nexus CLI...${NC}"
        screen -dmS nexus-cli-session bash -c "curl https://cli.nexus.xyz/ | sh && source $HOME/.cargo/env && nexus-cli"
        echo -e "${GREEN}✅ Nexus CLI 已在 screen 会话中安装并启动。${NC}"
    fi
    echo -e "${CYAN}📜 使用以下命令查看会话输出：${NC}"
    echo -e "${YELLOW}screen -r nexus-cli-session${NC}"
}

# 卸载 Nexus CLI
uninstall_nexus_cli() {
    echo -e "${RED}🗑️  正在卸载 Nexus CLI...${NC}"
    screen -S nexus-cli-session -X quit
    echo -e "${GREEN}✅ 已停止 Nexus CLI 的 screen 会话。${NC}"
}

# 创建 systemd 服务文件，实现开机启动
create_systemd_service() {
    echo -e "${BLUE}🔧 创建 Nexus CLI 开机启动服务...${NC}"
    cat <<EOF | tee /etc/systemd/system/nexus-cli.service
[Unit]
Description=Nexus CLI in Screen Session
After=network.target

[Service]
ExecStart=/usr/bin/screen -dmS nexus-cli-session bash -c "source /root/.cargo/env && /root/.nexus/nexus-cli"
Restart=always
User=root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable nexus-cli.service
    systemctl start nexus-cli.service
    echo -e "${GREEN}✅ Nexus CLI 开机启动服务已创建并启用。${NC}"
}

# 菜单选择
while true; do
    clear
    echo -e "${CYAN}================== Nexus CLI 管理脚本 ==================${NC}"
    echo -e "${YELLOW}1) 🚀 安装并启动 Nexus CLI${NC}"
    echo -e "${YELLOW}2) 🗑️  卸载 Nexus CLI${NC}"
    echo -e "${YELLOW}3) 📜 查看 Nexus CLI 会话${NC}"
    echo -e "${YELLOW}4) 🔧 设置开机自启${NC}"
    echo -e "${YELLOW}5) ❌ 退出${NC}"
    echo -e "${CYAN}=========================================================${NC}"
    echo -e "${BLUE}请输入您的选择 (1-5): ${NC}"
    read choice

    case $choice in
        1)
            install_and_run_nexus_cli
            ;;
        2)
            uninstall_nexus_cli
            systemctl stop nexus-cli.service
            systemctl disable nexus-cli.service
            ;;
        3)
            echo -e "${BLUE}📜 查看 Nexus CLI 会话...${NC}"
            screen -r nexus-cli-session
            ;;
        4)
            create_systemd_service
            ;;
        5)
            echo -e "${GREEN}✅ 退出脚本${NC}"
            break
            ;;
        *)
            echo -e "${RED}❌ 无效选项，请输入 1-5 之间的数字。${NC}"
            ;;
    esac
    echo -e "${YELLOW}🔙 按回车键返回菜单...${NC}"
    read -r
done
