#!/bin/bash

# 定义颜色变量
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'


# 获取当前非 root 用户的 home 目录
NORMAL_USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
# 如果 SUDO_USER 为空（直接以 root 身份运行），则使用当前用户的 home 目录
NORMAL_USER_HOME=${NORMAL_USER_HOME:-$HOME}

# 检查是否以 root 身份运行
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${red}某些操作需要 root 权限，请使用 sudo 运行此脚本。${plain}"
    exit 1
  fi
}

# 通用依赖安装函数
install_common_dependencies() {
    echo -e "${yellow}正在安装常用系统依赖...${plain}"
    
    # 更新软件包列表
    sudo apt update -y

    # 安装基本依赖
    local dependencies=(
        "curl"
        "wget"
        "git"
        "terminator"
        "bat" # 使用命令是batcat
        "python3"
        "python3-venv"
        "python3-pip"  # 添加 pip
        "pipx"
        "build-essential"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "software-properties-common"
    )

    for dep in "${dependencies[@]}"; do
    # Iterate over each item in the 'dependencies' array
    if ! dpkg -l | grep -q "^ii  $dep"; then
        # Check if the package is not installed by searching for it in the list of installed packages
        echo -e "${yellow}正在安装 $dep...${plain}"
        # If the package is not installed, print a message indicating that the installation is starting
        sudo apt install -y "$dep"
        # Attempt to install the package using 'apt' with the '-y' flag to automatically confirm installation
        if [ $? -ne 0 ]; then
            # Check if the installation command failed (non-zero exit status)
            echo -e "${red}安装 $dep 失败${plain}"
            # Print an error message indicating the installation failed
            return 1
            # Exit the function or script with a status of 1 to indicate failure
        fi
    else
        echo -e "${green}$dep 已经安装${plain}"
        # If the package is already installed, print a message indicating it is already installed
    fi
    done
    # End of the loop over the 'dependencies' array

    # 确保 pip 是最新版本
    echo -e "${yellow}正在更新 pip...${plain}"
    python3 -m pip install --upgrade pip

    echo -e "${green}所有系统依赖安装完成${plain}"

    # 添加按两次ESC键自动在命令前插入 sudo
    echo -e "${yellow}正在设置自动 sudo...${plain}"
    echo 'set hook all:try-sudo' > ~/.inputrc
}

# 通用的安装后菜单函数
post_installation_menu() {
    clear
    echo -e "${green}==================== 后续安装菜单 ====================${plain}"
    echo -e "${yellow} 1. 返回主菜单${plain}"
    echo -e "${yellow} 2. 继续安装软件${plain}"
    echo -e "${yellow} 3. 卸载所有已安装软件${plain}"  # 新增选项
    read -p "请选择操作 [1-3]: " menu_choice

    case $menu_choice in
        1)
            main_menu
            ;;
        2)
            software_installation_menu
            ;;
        3)
            uninstall_all_software  # 调用新的卸载函数
            ;;
        *)
            echo -e "${red}无效的选择，返回主菜单。${plain}"
            main_menu
            ;;
    esac
}

# 卸载所有已安装软件的函数
uninstall_all_software() {
    # 定义需要卸载的软件列表
    local software_list=(
        "micro"           # 文本编辑器
        "plank"           # 桌面dock
        "fcitx5"           # 输入法
        "docker"          # 容器平台
        "docker-compose"  # Docker 编排工具
        "cheat.sh"        # 命令行工具
        "angrysearch"     # 搜索工具
        "google-noto-fonts"  # 字体
        "eg"             # 示例命令工具
        "eggs"           # 备份工具
        "zsh"            # Shell
    )

    # 用户确认
    echo -e "${yellow}警告：这将卸载通过本脚本安装的所有软件！${plain}"
    read -p "是否确定要卸载所有软件？(y/N): " confirm
    if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
        echo -e "${green}取消卸载操作。${plain}"

        return 0
    fi

    # 卸载函数
    uninstall_software() {
        local software="$1"
        case "$software" in
            "micro")
                # 卸载 Micro 编辑器
                sudo rm -f /usr/local/bin/micro
                echo -e "${green}已卸载 Micro 编辑器${plain}"
                ;;
            "plank")
                # 卸载 Plank Dock
                sudo apt remove -y plank
                sudo rm -f ~/.config/autostart/plank.desktop
                echo -e "${green}已卸载 Plank Dock${plain}"
                ;;
            "fcitx5")
                # 卸载 Fcitx5 输入法
                sudo apt purge -y fcitx5 fcitx5-chinese-addons
                sudo rm -f ~/.config/autostart/fcitx5.desktop
                echo -e "${green}已卸载 Fcitx5 输入法${plain}"
                ;;
            "docker")
                # 卸载 Docker
                sudo apt remove -y docker-ce docker-ce-cli containerd.io
                sudo rm -f /usr/local/bin/docker-compose
                echo -e "${green}已卸载 Docker 和 Docker Compose${plain}"
                ;;
            "docker-compose")
                # 已在 Docker 卸载中处理
                ;;
            "cheat.sh")
                # 卸载 Cheat.sh
                sudo rm -f /usr/local/bin/cht.sh
                echo -e "${green}已卸载 Cheat.sh${plain}"
                ;;
            "angrysearch")
                # 卸载 ANGRYsearch
                sudo rm -rfv $(find /usr -path "*angrysearch*")
                sudo rm -f ~/.config/autostart/angrysearch.desktop
                echo -e "${green}已卸载 ANGRYsearch${plain}"
                ;;
            "google-noto-fonts")
                # 卸载 Google Noto 字体
                sudo apt remove -y fonts-noto*
                echo -e "${green}已卸载 Google Noto 字体${plain}"
                ;;
            "eg")
                # 卸载 eg 命令行工具
                uninstall_eg
                echo -e "${green}已卸载 eg 命令行工具${plain}"
                ;;
            "eggs")
                # 卸载 eggs 备份工具
                uninstall_eggs
                echo -e "${green}已卸载 eggs 备份工具${plain}"
                ;;
            "zsh")
                # 卸载 zsh 和 oh-my-zsh
                uninstall_zsh
                echo -e "${green}已卸载 zsh 和 oh-my-zsh${plain}"
                ;;
            *)
                echo -e "${yellow}未找到卸载方法：$software${plain}"
                ;;
        esac
    }

    # 遍历并卸载软件
    for software in "${software_list[@]}"; do
        uninstall_software "$software"
    done

    # 清理残留
    sudo apt autoremove -y
    sudo apt autoclean

    echo -e "${green}所有软件卸载完成！${plain}"

}

# 安装 zsh
install_zsh() {
    # 检查是否已安装 zsh
    if command -v zsh &> /dev/null; then
        echo -e "${green}zsh 已经安装。${plain}"

        return 0
    fi

    # 安装 zsh
    echo -e "${yellow}正在安装 zsh...${plain}"
    sudo apt update
    if ! sudo apt install -y zsh; then
        echo -e "${red}zsh 安装失败。请检查网络连接和系统权限。${plain}"
        return 1
    fi

    # 更改默认 shell
    echo -e "${yellow}正在更改默认 shell...${plain}"

    # 获取当前非 root 用户
    local current_user="${SUDO_USER:-$(whoami)}"

    # 检查是否成功获取用户
    if [[ -z "$current_user" ]]; then
        echo -e "${red}无法确定当前用户，无法更改 shell。${plain}"
        return 1
    fi

    # 使用 sudo -u 以当前用户身份执行 chsh
    if sudo -u "$current_user" chsh -s "$(which zsh)"; then
        echo -e "${green}$current_user 用户的默认 shell 已更改为 zsh，请重新登录生效。${plain}"
    else
        echo -e "${red}更改 $current_user 用户的默认 shell 失败，请手动执行 'chsh -s $(which zsh)'。${plain}"
        return 1
    fi

    # 同时更新 /etc/passwd 中的 shell
    perl -i -pe "s|^($current_user:.*):(/bin/bash)|\1:/usr/bin/zsh|" /etc/passwd

        echo -e "${green}zsh 安装完成！${plain}"
        echo -e "${yellow}建议重新登录以使配置生效。${plain}"

}

# 卸载 zsh
uninstall_zsh() {
    # 检查是否以 root 权限运行
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red}需要 root 权限。请使用 sudo 运行此脚本。${plain}"
        return 1
    fi

    # 检查 zsh 是否已安装
    if ! command -v zsh &> /dev/null; then
        echo -e "${yellow}zsh 未安装。${plain}"
        return 0
    fi

    # 备份 /etc/passwd
    cp /etc/passwd /etc/passwd.backup
    
    # 尝试将默认 shell 更改回 bash
    echo -e "${yellow}正在将默认 shell 更改回 bash...${plain}"
    local bash_path=$(which bash)
    
    # 获取当前用户信息
    local current_user="${SUDO_USER:-$(whoami)}"
    
    # 安全地更新 /etc/passwd
    if [[ -n "$current_user" ]]; then
        echo -e "${yellow}正在更新用户 $current_user 的默认 shell...${plain}"
        
        # 使用 perl 安全地替换用户的 shell
        perl -i -pe "s|^($current_user:.*):(/usr/bin/zsh)|\1:/bin/bash|" /etc/passwd
        
        # 使用 chsh 更改用户 shell
        if chsh -s "$bash_path" "$current_user"; then
            echo -e "${green}$current_user 用户的默认 shell 已更改为 bash。${plain}"
        else
            echo -e "${red}更改 $current_user 用户的默认 shell 失败。${plain}"
        fi
    fi

    # 更改 root 用户的默认 shell
    perl -i -pe "s|^(root:.*):(/usr/bin/zsh)|\1:/bin/bash|" /etc/passwd

    # 卸载 zsh
    echo -e "${yellow}正在卸载 zsh...${plain}"
    apt remove -y zsh || {
        echo -e "${red}卸载 zsh 失败。${plain}"
        return 1
    }

    echo -e "${green}zsh 已成功卸载！${plain}"
}

# 安装 oh-my-zsh
install_ohmyzsh() {
    # 检查是否已安装 oh-my-zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${green}oh-my-zsh 已经安装。${plain}"

        return 0
    fi

    # 安装 oh-my-zsh
    echo -e "${yellow}正在安装 oh-my-zsh...${plain}"
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        echo -e "${green}oh-my-zsh 安装完成。${plain}"
    else
        echo -e "${red}oh-my-zsh 安装失败。${plain}"
        return 1
    fi

    echo -e "${green}oh-my-zsh 安装完成！${plain}"
    echo -e "${yellow}建议重新登录以使配置生效。${plain}"
    
}

uninstall_ohmyzsh() {
    # 卸载 oh-my-zsh
    echo -e "${yellow}正在卸载 oh-my-zsh...${plain}"
    rm -rf "$HOME/.oh-my-zsh"
    echo -e "${green}oh-my-zsh 已卸载！${plain}"

}

# 安装 cheat.sh
install_cheatsh() {
    # 检查是否已安装 cheat.sh
    if [ -f /usr/local/bin/cht.sh ]; then
        echo -e "${green}cheat.sh 已经安装。${plain}"
        return 0
    fi

    # 安装必要的依赖
    sudo apt install -y rlwrap

    # 下载并安装 cheat.sh
    curl -s https://cht.sh/:cht.sh | sudo tee /usr/local/bin/cht.sh && sudo chmod +x /usr/local/bin/cht.sh

    # 验证安装
    if [ -f /usr/local/bin/cht.sh ]; then
        echo -e "${green}cheat.sh 安装完成。 使用方法：cht.sh 命令 (例如 cht.sh curl)${plain}"

    else
        echo -e "${red}cheat.sh 安装失败。${plain}"
        return 1
    fi
}

# 卸载 cheat.sh
uninstall_cheatsh() {
    # 卸载 cheat.sh
    echo -e "${yellow}正在卸载 cheat.sh...${plain}"
    sudo rm -f /usr/local/bin/cht.sh
    echo -e "${green}cheat.sh 已卸载！${plain}"

}

# 安装 angrysearch
install_angrysearch() {
    # 检查必要的依赖
    local required_deps=("wget" "tar" "sudo" "python3-pyqt5")
    local missing_deps=()

    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${yellow}正在安装缺少的依赖：${missing_deps[*]}...${plain}"
        sudo apt update
        sudo apt install -y "${missing_deps[@]}"
    fi

    # 获取原始用户名和家目录
    original_user="${SUDO_USER:-$(whoami)}"
    original_home="/home/$original_user"
    [ "$original_user" = "root" ] && original_home="/root"

    # 检查是否已安装
    if command -v angrysearch &> /dev/null; then
        echo -e "${green}angrysearch 已经安装。${plain}"
        configure_autostart
        return 0
    fi

    # 创建下载目录并下载
    mkdir -p "$original_home/Downloads"
    cd "$original_home/Downloads" || exit 1

    # 下载 ANGRYsearch
    local version="v1.0.4"
    local download_url="https://github.com/DoTheEvo/ANGRYsearch/archive/refs/tags/${version}.tar.gz"
    local download_file="${version}.tar.gz"

    echo -e "${yellow}正在下载 ANGRYsearch ${version}...${plain}"
    if ! wget -q --show-progress "$download_url" -O "$download_file"; then
        echo -e "${red}下载失败，请检查网络连接。${plain}"
        return 1
    fi

    # 创建并解压到 Apps 目录
    mkdir -p "$original_home/Apps"
    echo -e "${yellow}正在解压 ANGRYsearch...${plain}"
    if ! tar -zxvf "$download_file" -C "$original_home/Apps"; then
        echo -e "${red}解压失败。${plain}"
        return 1
    fi

    # 安装
    cd "$original_home/Apps/ANGRYsearch-${version#v}" || exit 1
    if [ ! -f ./install.sh ]; then
        echo -e "${red}未找到安装脚本。${plain}"
        return 1
    fi

    chmod +x ./install.sh
    if ! sudo ./install.sh; then
        echo -e "${red}安装失败。${plain}"
        return 1
    fi

    # 配置自动启动
    configure_autostart
}

# 配置自动启动的辅助函数
configure_autostart() {
    # 获取原始用户信息
    original_user="${SUDO_USER:-$(whoami)}"
    original_home="/home/$original_user"
    [ "$original_user" = "root" ] && original_home="/root"

    # 确保目录存在并设置正确的所有权
    local autostart_dir="$original_home/.config/autostart"
    if [ "$original_user" != "root" ]; then
        # 为非root用户创建目录并设置权限
        sudo -u "$original_user" mkdir -p "$autostart_dir"
    else
        # 为root用户创建目录
        mkdir -p "$autostart_dir"
    fi

    # 创建desktop文件
    local desktop_file="$autostart_dir/angrysearch.desktop"
    cat > "$desktop_file" << EOL
[Desktop Entry]
Type=Application
Name=ANGRYsearch
Comment=Quick file search utility
Exec=angrysearch
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Icon=system-search
Categories=Utility;Search;
EOL

    # 设置正确的文件权限和所有权
    if [ "$original_user" != "root" ]; then
        sudo chown "$original_user:$original_user" "$desktop_file"
    fi
    chmod 644 "$desktop_file"

    echo -e "${green}已为用户 $original_user 配置 ANGRYsearch 开机自启动。${plain}"

    # 如果是root用户执行的，同时也配置root用户的自启动
    if [ "$original_user" != "root" ] && [ "$HOME" = "/root" ]; then
        local root_autostart="/root/.config/autostart"
        mkdir -p "$root_autostart"
        cp "$desktop_file" "$root_autostart/"
        chmod 644 "$root_autostart/angrysearch.desktop"
        echo -e "${green}已为root用户配置 ANGRYsearch 开机自启动。${plain}"
    fi
}

# 卸载 angrysearch
uninstall_angrysearch() {
    # 卸载 angrysearch
    echo -e "${yellow}正在卸载 angrysearch...${plain}"
    sudo rm -rfv $(find /usr -path "*angrysearch*")
    echo -e "${green}angrysearch 已卸载！${plain}"

}

# 获取 Docker Compose 最新版本号
get_latest_docker_compose_version() {
    local version
    
    # 使用 GitHub API 获取最新版本
    version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')
    
    # 如果获取失败，使用备用版本
    if [ -z "$version" ]; then
        version="2.17.2"  # 作为备用版本
        echo -e "${yellow}警告：无法获取最新版本，将使用默认版本 ${version}${plain}"
    else
        echo -e "${green}获取到最新 Docker Compose 版本：${version}${plain}"
    fi
    
    echo "$version"
}

# 安装 Docker
install_docker() {
    echo -e "${yellow}开始安装 Docker...${plain}"

    # 检查是否已经安装
    if command -v docker &> /dev/null; then
        echo -e "${green}Docker 已经安装。${plain}"
        docker --version
        docker compose version

        return 0
    fi

    # 更新软件包列表并安装依赖
    echo -e "${yellow}正在安装必要的依赖包...${plain}"
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release || {
        echo -e "${red}安装依赖包失败!${plain}"
        return 1
    }

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc


    # 设置 Docker 存储库
    # 检测是否存在docker.list文件，如果存在，删除
    if [ -f /etc/apt/sources.list.d/docker.list ]; then
        sudo rm -f /etc/apt/sources.list.d/docker.list
    fi
    DEBIAN_CODENAME="bookworm"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian/ ${DEBIAN_CODENAME} stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # 更新软件包列表并安装 Docker
    echo -e "${yellow}正在安装 Docker...${plain}"
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
        echo -e "${red}安装 Docker 失败!${plain}"
        return 1
    }

    # 启动 Docker 服务
    echo -e "${yellow}正在启动 Docker 服务...${plain}"
    sudo systemctl enable docker
    sudo systemctl start docker || {
        echo -e "${red}启动 Docker 服务失败!${plain}"
        return 1
    }

    # 将当前用户添加到 docker 组
    echo -e "${yellow}正在将当前用户添加到 docker 组...${plain}"
    sudo usermod -aG docker ${USER}
    
    # 验证安装
    echo -e "${yellow}正在验证 Docker 安装...${plain}"
    if sudo docker run --rm hello-world &> /dev/null; then
        echo -e "${green}Docker 安装成功!${plain}"
        echo -e "${yellow}请注意：${plain}"
        echo -e "1. 要使用 docker 命令而无需 sudo，请重新登录系统"
        echo -e "2. 如果遇到权限问题，运行: newgrp docker"
        
        # 显示版本信息
        docker --version
        docker compose version

        return 0
    else
        echo -e "${red}Docker 安装验证失败!${plain}"
        return 1
    fi
}

# 卸载 Docker
uninstall_docker() {
    echo -e "${yellow}正在卸载 Docker...${plain}"
    sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo -e "${green}Docker 已卸载！${plain}"

}

# 安装 micro 编辑器
install_micro() {
    # 检查是否已安装 micro
    if command -v micro &> /dev/null; then
        echo -e "${green}micro 编辑器已安装。${plain}"

        return 0
    fi

    # 检查并安装依赖
    local dependencies=("curl" "jq" "wget")
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${yellow}正在安装必要的依赖：${missing_deps[*]}...${plain}"
        sudo apt update
        sudo apt install -y "${missing_deps[@]}"
    fi

    # 创建临时下载目录
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || return 1

    # 获取最新版本号（带有网络状态检查）
    echo -e "${yellow}正在获取 micro 最新版本...${plain}"
    local latest_version download_url

    latest_version=$(curl -s https://api.github.com/repos/zyedidia/micro/releases/latest | jq -r '.tag_name' | grep -oP '\d+\.\d+\.\d+')

    if [ -z "$latest_version" ]; then
        echo -e "${red}无法解析 micro 最新版本。${plain}"
        return 1
    fi

    # 构建下载链接
    download_url="https://github.com/zyedidia/micro/releases/download/v${latest_version}/micro-${latest_version}-linux64.tar.gz"

    # 下载最新版本的 micro
    echo -e "${yellow}正在下载 micro 编辑器 v${latest_version}...${plain}"
    if ! curl -L "$download_url" -o micro.tar.gz; then
        echo -e "${red}下载 micro 失败。请检查网络连接。${plain}"
        return 1
    fi

    # 解压并安装
    echo -e "${yellow}正在安装 micro 编辑器...${plain}"
    tar -xzf micro.tar.gz

    # 移动到系统路径
    local micro_dir
    micro_dir=$(find . -maxdepth 1 -type d -name "micro-*")
    if [ -z "$micro_dir" ]; then
        echo -e "${red}未找到 micro 解压目录。${plain}"
        return 1
    fi

    sudo mv "$micro_dir/micro" /usr/local/bin/

    # 清理临时文件
    cd ~
    rm -rf "$temp_dir"

    # 验证安装
    if command -v micro &> /dev/null; then
        echo -e "${green}micro 编辑器安装成功！${plain}"
        micro --version

    else
        echo -e "${red}micro 编辑器安装失败。${plain}"
        return 1
    fi
}

# 卸载 micro 编辑器
uninstall_micro() {
    echo -e "${yellow}正在卸载 micro 编辑器...${plain}"
    sudo rm -f /usr/local/bin/micro
    echo -e "${green}micro 编辑器已卸载！${plain}"

}

# 安装 eg
install_eg() {
    echo -e "${yellow}正在安装 eg...${plain}"
    
    # 检查 Python 和 pip 是否已安装
    if ! command -v python3 &> /dev/null || ! command -v pipx &> /dev/null; then
        echo -e "${red}请先安装 Python3 和 pipx。${plain}"
        install_common_dependencies
        return 1
    fi

    # 获取真实用户名和家目录
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    [ "$REAL_USER" = "root" ] && REAL_HOME="/root"

    # 确保普通用户目录存在并设置权限
    mkdir -p "$REAL_HOME/.local/bin"
    chown -R "$REAL_USER:$(id -gn $REAL_USER)" "$REAL_HOME/.local"

    # 确保 root 用户目录存在
    mkdir -p /root/.local/bin
    chown -R root:root /root/.local

    # 为普通用户安装（如果是以 sudo 运行且不是 root）
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        echo -e "${yellow}正在为用户 $SUDO_USER 安装 eg...${plain}"
        if ! sudo -u "$SUDO_USER" python3 -m pipx list | grep -q "^eg "; then
            if ! sudo -u "$SUDO_USER" python3 -m pipx install eg; then
                echo -e "${red}普通用户 eg 安装失败。${plain}"
                return 1
            fi
            sudo -u "$SUDO_USER" python3 -m pipx ensurepath
            echo -e "${green}普通用户 eg 安装完成。${plain}"
        else
            echo -e "${green}普通用户 eg 已安装。${plain}"
        fi
    fi

    # 为 root 用户安装
    echo -e "${yellow}正在为 root 用户安装 eg...${plain}"
    if ! python3 -m pipx list | grep -q "^eg "; then
        if ! python3 -m pipx install eg; then
            echo -e "${red}root用户 eg 安装失败。${plain}"
            return 1
        fi
        pipx ensurepath
        echo -e "${green}root用户 eg 安装完成。${plain}"
    else
        echo -e "${green}root用户 eg 已安装。${plain}"
    fi

    # 为普通用户配置 PATH
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        # 配置 bashrc
        if [ ! -f "$REAL_HOME/.bashrc" ]; then
            touch "$REAL_HOME/.bashrc"
            chown "$REAL_USER:$(id -gn $REAL_USER)" "$REAL_HOME/.bashrc"
        fi
        if ! grep -q '^export PATH="\$HOME/\.local/bin:\$PATH"' "$REAL_HOME/.bashrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$REAL_HOME/.bashrc"
            echo -e "${yellow}已添加到普通用户的 .bashrc${plain}"
        fi

        # 配置 zshrc（如果存在）
        if [ -f "$REAL_HOME/.zshrc" ]; then
            sed -i -e '$a\' "$REAL_HOME/.zshrc"
            if ! grep -q '^export PATH="\$HOME/\.local/bin:\$PATH"' "$REAL_HOME/.zshrc"; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$REAL_HOME/.zshrc"
                echo -e "${yellow}已添加到普通用户的 .zshrc${plain}"
            fi
            chown "$REAL_USER:$(id -gn $REAL_USER)" "$REAL_HOME/.zshrc"
        fi
    fi

    # 为 root 用户配置 PATH
    if ! grep -q '^export PATH="\$HOME/\.local/bin:\$PATH"' /root/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc
        echo -e "${yellow}已添加到 root 的 .bashrc${plain}"
    fi
    if [ -f /root/.zshrc ] && ! grep -q '^export PATH="\$HOME/\.local/bin:\$PATH"' /root/.zshrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.zshrc
        echo -e "${yellow}已添加到 root 的 .zshrc${plain}"
    fi

    echo -e "${green}配置完成。${plain}"
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        echo -e "${yellow}普通用户请执行：source ~/.bashrc${plain}"
        echo -e "${yellow}root用户请执行：su - root 后使用${plain}"
    else
        echo -e "${yellow}请执行：source ~/.bashrc${plain}"
    fi
    
    # 尝试立即应用配置
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$SUDO_USER" bash -c "export PATH=\"$REAL_HOME/.local/bin:\$PATH\""
        export PATH="/root/.local/bin:$PATH"
    else
        export PATH="$REAL_HOME/.local/bin:$PATH"
    fi

    . "$REAL_HOME/.bashrc"
}

# 卸载 eg
uninstall_eg() {
    echo -e "${yellow}正在卸载 eg...${plain}"

    # 获取真实用户名和家目录
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    [ "$REAL_USER" = "root" ] && REAL_HOME="/root"

    # 如果是以 sudo 运行且不是 root 用户
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        # 卸载普通用户的 eg
        echo -e "${yellow}正在卸载普通用户 ${REAL_USER} 的 eg...${plain}"
        if sudo -u "$SUDO_USER" python3 -m pipx uninstall eg; then
            echo -e "${green}普通用户 ${REAL_USER} 的 eg 已卸载${plain}"
        else
            echo -e "${yellow}普通用户 ${REAL_USER} 未安装 eg 或卸载失败${plain}"
        fi

        # 清理普通用户的 PATH 配置
        if [ -f "$REAL_HOME/.bashrc" ]; then
            sed -i '/export PATH="\$HOME\/\.local\/bin:\$PATH"/d' "$REAL_HOME/.bashrc"
        fi
        if [ -f "$REAL_HOME/.zshrc" ]; then
            sed -i '/export PATH="\$HOME\/\.local\/bin:\$PATH"/d' "$REAL_HOME/.zshrc"
        fi
    fi

    # 卸载 root 用户的 eg
    echo -e "${yellow}正在卸载 root 用户的 eg...${plain}"
    if python3 -m pipx uninstall eg; then
        echo -e "${green}root 用户的 eg 已卸载${plain}"
    else
        echo -e "${yellow}root 用户未安装 eg 或卸载失败${plain}"
    fi

    # 清理 root 用户的 PATH 配置
    if [ -f "/root/.bashrc" ]; then
        sed -i '/export PATH="\$HOME\/\.local\/bin:\$PATH"/d' "/root/.bashrc"
    fi
    if [ -f "/root/.zshrc" ]; then
        sed -i '/export PATH="\$HOME\/\.local\/bin:\$PATH"/d' "/root/.zshrc"
    fi

    echo -e "${green}eg 卸载完成！${plain}"
    echo -e "${yellow}请执行 source ~/.bashrc 或重新登录以使更改生效${plain}"
}

# 安装 eggs
install_eggs() {
    # 检查是否已安装 eggs
    if command -v eggs &> /dev/null; then
        echo -e "${green}eggs 已安装。${plain}"

        return 0
    fi

    # 安装 nodejs 依赖
    install_nodejs() {
        # Check if curl is installed
        if ! command -v curl &> /dev/null; then
            echo "Error: curl is not installed. Attempting to install..."
            if ! apt-get install -y curl; then
                echo "Error: Failed to install curl."
                return 1
            fi
        fi

        # Download the setup script
        curl_result=$(curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to download setup script. curl returned: $curl_result"
            return 1
        fi

        # Run the setup script
        bash_result=$(bash nodesource_setup.sh)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to run setup script. bash returned: $bash_result"
            return 1
        fi

        # Install Node.js
        apt_result=$(apt-get install -y nodejs)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install Node.js. apt returned: $apt_result"
            return 1
        fi

        # Verify the installation
        node_version=$(node -v)
        if [ $? -ne 0 ]; then
            echo "Error: Node.js installation verification failed."
            return 1
        else
            echo "Node.js version: $node_version"
        fi

        echo "Node.js installation successful."
        return 0
    }
    # Call the function
    install_nodejs

    # 安装必要的依赖
    # echo -e "${yellow}正在安装必要的依赖...${plain}"
    # apt-get update
    # apt-get install -y \
    #     squashfs-tools \
    #     xorriso \
    #     live-boot \
    #     live-boot-doc \
    #     live-config \
    #     live-config-doc \
    #     live-config-systemd \
    #     debootstrap \
    #     syslinux-common \
    #     isolinux \
    #     xterm \
    #     rsync \
    #     zstd \
    #     lvm2 \
    #     dosfstools \
    #     whois || {
    #     echo -e "${red}安装依赖失败。${plain}"
    #     return 1
    # }

    # 下载 penguins-eggs deb 包
    echo -e "${yellow}正在下载 penguins-eggs deb 包...${plain}"
    wget -O penguins-eggs.deb "https://sourceforge.net/projects/penguins-eggs/files/Packages/DEBS/penguins-eggs_10.0.53-1_amd64.deb/download" || {
        echo -e "${red}下载 penguins-eggs 失败。请检查网络连接。${plain}"
        return 1
    }

    # 安装 penguins-eggs
    echo -e "${yellow}正在安装 penguins-eggs...${plain}"
    if ! dpkg -i penguins-eggs.deb; then
        echo -e "${yellow}尝试修复依赖关系...${plain}"
        apt-get install -f -y
        if ! dpkg -i penguins-eggs.deb; then
            echo -e "${red}安装 penguins-eggs 失败。${plain}"
            return 1
        fi
    fi

    # 验证安装
    if command -v eggs &> /dev/null; then
        echo -e "${green}eggs 安装成功！${plain}"
        eggs --version
    else
        echo -e "${red}eggs 安装失败。${plain}"
        return 1
    fi

    # 修改eggs的配置文件，使得支持SparkyLinux 7.5
    echo -e "${yellow}正在修改eggs的配置文件...${plain}"
    
    update_file() {
        local FILE="/usr/lib/penguins-eggs/conf/derivatives.yaml"
        
        # 检查文件是否存在
        if [ ! -f "$FILE" ]; then
            echo -e "${red}错误：配置文件 $FILE 不存在${plain}"
            return 1
        fi

        # 检查文件权限
        if [ ! -w "$FILE" ]; then
            echo -e "${red}错误：没有写入权限 $FILE${plain}"
            return 1
        fi

        # 创建备份
        if ! cp "$FILE" "${FILE}.bak"; then
            echo -e "${red}错误：无法创建配置文件备份${plain}"
            return 1
        fi
        echo -e "${green}已创建配置文件备份：${FILE}.bak${plain}"

        # 使用临时文件
        local TEMP_FILE="${FILE}.tmp"
        
        # 使用 awk 处理文件
        awk '
        BEGIN { 
            found = 0; 
            insert = 0; 
        }
        /^# bookworm derivated/ { 
            found = 1; 
            print;
            next;
        }
        found && /^[[:space:]]*$/ && !insert { 
            # 获取上一行的缩进
            match(prev, /^[[:space:]]*/);
            indent = substr(prev, RSTART, RLENGTH);
            # 插入新行，保持相同缩进
            print indent "- orion-belt # SparkyLinux 7.5";
            insert = 1;
            print;
            next;
        }
        { 
            print;
            prev = $0;
        }
        END {
            if (!insert && found) {
                print "- orion-belt # SparkyLinux 7.5";
            }
        }' "$FILE" > "$TEMP_FILE"

        # 检查 awk 是否成功
        if [ $? -ne 0 ]; then
            echo -e "${red}错误：处理文件时出错${plain}"
            rm -f "$TEMP_FILE"
            return 1
        fi

        # 检查临时文件是否为空
        if [ ! -s "$TEMP_FILE" ]; then
            echo -e "${red}错误：生成的文件为空${plain}"
            rm -f "$TEMP_FILE"
            return 1
        fi

        # 替换原文件
        if ! mv "$TEMP_FILE" "$FILE"; then
            echo -e "${red}错误：无法更新配置文件${plain}"
            rm -f "$TEMP_FILE"
            return 1
        fi

        echo -e "${green}配置文件更新成功${plain}"
        
        # 显示更改
        echo -e "${yellow}更新后的相关内容：${plain}"
        grep -n -C 3 "orion-belt" "$FILE" || {
            echo -e "${red}警告：无法找到更新的内容${plain}"
            return 1
        }

        return 0
    }

    # 调用更新函数
    if ! update_file; then
        echo -e "${red}修改配置文件失败${plain}"
        return 1
    fi

    # 安装 calamares, 暂不启用，安装太费时间了
    # echo -e "${yellow}正在安装 calamares...${plain}"
    # if ! eggs calamares --install; then
    #     echo -e "${red}安装 calamares 失败。${plain}"
    #     return 1
    # fi

    # echo -e "${green}calamares 安装成功！${plain}"
    # return 0
}

# 卸载 eggs
uninstall_eggs() {
    echo -e "${yellow}正在卸载 eggs (penguins-eggs)...${plain}"
    
    # 检查是否已安装
    if ! dpkg -l | grep -q penguins-eggs; then
        echo -e "${yellow}penguins-eggs 未安装。${plain}"

        return 0
    fi
    
    # 尝试卸载
    dpkg -r penguins-eggs || {
        echo -e "${red}卸载 penguins-eggs 失败。${plain}"
        return 1
    }
    
    echo -e "${green}eggs (penguins-eggs) 已卸载！${plain}"

}

# 安装 Plank Dock
install_plank() {
    # 检查是否已安装 Plank
    if command -v plank &> /dev/null; then
        echo -e "${green}Plank Dock 已经安装。${plain}"
        configure_plank_autostart
        return 0
    fi

    # 更新软件源并安装 Plank
    echo -e "${yellow}正在安装 Plank Dock...${plain}"
    sudo apt update
    if sudo apt install -y plank; then
        echo -e "${green}Plank Dock 安装成功！${plain}"
        echo -e "${yellow}可以通过命令 'plank' 启动 Dock${plain}"
        configure_plank_autostart
    else
        echo -e "${red}Plank Dock 安装失败。请检查网络连接和系统权限。${plain}"
        return 1
    fi
}

# 配置 Plank 自动启动的辅助函数
configure_plank_autostart() {
    # 获取原始用户信息
    original_user="${SUDO_USER:-$(whoami)}"
    original_home="/home/$original_user"
    [ "$original_user" = "root" ] && original_home="/root"

    # 确保目录存在并设置正确的所有权
    local autostart_dir="$original_home/.config/autostart"
    if [ "$original_user" != "root" ]; then
        # 为非root用户创建目录并设置权限
        sudo -u "$original_user" mkdir -p "$autostart_dir"
    else
        # 为root用户创建目录
        mkdir -p "$autostart_dir"
    fi

    # 创建desktop文件
    local desktop_file="$autostart_dir/plank.desktop"
    cat > "$desktop_file" << EOL
[Desktop Entry]
Type=Application
Name=Plank
Comment=Plank Dock Autostart
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOL

    # 设置正确的文件权限和所有权
    if [ "$original_user" != "root" ]; then
        sudo chown "$original_user:$original_user" "$desktop_file"
    fi
    chmod +x "$desktop_file"

    echo -e "${green}已为用户 $original_user 配置 Plank 开机自启动。${plain}"

    # 如果是root用户执行的，同时也配置root用户的自启动
    if [ "$original_user" != "root" ] && [ "$HOME" = "/root" ]; then
        local root_autostart="/root/.config/autostart"
        mkdir -p "$root_autostart"
        cp "$desktop_file" "$root_autostart/"
        chmod +x "$root_autostart/plank.desktop"
        echo -e "${green}已为root用户配置 Plank 开机自启动。${plain}"
    fi
}

# 卸载 Plank Dock
uninstall_plank() {
    echo -e "${yellow}正在卸载 Plank Dock...${plain}"
    sudo apt remove -y plank
    echo -e "${green}Plank Dock 已卸载！${plain}"

}

# 安装中文输入法 Fcitx
install_chinese_input() {
    check_fcitx_installed() {
        dpkg -l | grep -qw fcitx5 && dpkg -l | grep -qw fcitx5-chinese-addons
    }

    if check_fcitx_installed; then
        read -p "检测到已安装输入法，是否重新安装？(y/n) " choice
        if [[ ! "$choice" =~ ^[yY]$ ]]; then

            return 0
        fi
        echo -e "${yellow}卸载已有输入法...${plain}"
        sudo apt purge -y fcitx* ibus*
        sudo apt autoremove -y
        rm -rf ~/.config/fcitx5
    fi

    echo -e "${yellow}开始安装 Fcitx5 和中文输入法...${plain}"
    sudo apt update -y || {
        echo -e "${red}系统更新失败${plain}"
        return 1
    }

    if sudo apt install -y fcitx5 fcitx5-chinese-addons fonts-wqy-zenhei fonts-wqy-microhei fonts-noto-cjk; then
        
        # 配置环境变量
        local env_vars=(
            "GTK_IM_MODULE=fcitx5"
            "QT_IM_MODULE=fcitx5"
            "XMODIFIERS=@im=fcitx5"
            "INPUT_METHOD=fcitx5"
            "SDL_IM_MODULE=fcitx5"
        )

        for file in ~/.bashrc ~/.xprofile; do
            touch "$file"
            for var in "${env_vars[@]}"; do
                sed -i "/$var/d" "$file"  # 删除已存在的配置
                echo "export $var" >> "$file"
            done
        done

        # 设置默认输入法
        im-config -n fcitx5

        # 创建自启动配置
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/fcitx5.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Fcitx5
Comment=Fcitx5 input method framework
Exec=fcitx5
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Icon=system-search
Categories=Utility;Search;
EOF

        # 停止现有fcitx进程并启动新的
        pkill fcitx5 2>/dev/null
        sleep 1
        fcitx5 &

        echo -e "${green}中文输入法安装完成！${plain}"
        echo -e "${yellow}请重新启动系统或退出登录后重新登录，以确保配置生效。${plain}"
        echo -e "${yellow}使用快捷键 Ctrl + Space 切换输入法。${plain}"
        
        # post_installation_menu
    else
        echo -e "${red}中文输入法安装失败。请检查网络连接和系统权限。${plain}"
        return 1
    fi
}

# 卸载中文输入法 Fcitx
uninstall_chinese_input() {
    echo -e "${yellow}正在卸载中文输入法 Fcitx...${plain}"
    sudo apt purge -y fcitx* ibus*
    sudo apt autoremove -y
    rm -rf ~/.config/fcitx5
    echo -e "${green}中文输入法 Fcitx 已卸载！${plain}"

}

# 安装 Google 开源中文字体
install_google_noto_fonts() {
    # 检查是否已安装 Noto 中文字体
    check_noto_fonts_installed() {
        dpkg -l | grep -qE "fonts-noto-cjk|fonts-noto-color-emoji"
    }

    if check_noto_fonts_installed; then
        echo -e "${green}Google Noto 中文字体已经安装。${plain}"
        # post_installation_menu
        return 0
    fi

    echo -e "${yellow}开始安装 Google Noto 中文字体...${plain}"

    # 更新系统软件包列表
    echo -e "${yellow}更新系统软件包列表...${plain}"
    sudo apt update -y

    # 安装 Noto CJK 字体和 Emoji 字体
    echo -e "${yellow}安装 Google Noto 中文字体...${plain}"
    if sudo apt install -y \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        fonts-noto-mono \
        fonts-noto-ui-extra; then
        
        echo -e "${green}Google Noto 中文字体安装完成！${plain}"
        echo -e "${yellow}已安装以下字体：${plain}"
        echo "- Noto CJK 中文字体"
        echo "- Noto Color Emoji 表情字体"
        echo "- Noto Mono 等宽字体"
        echo "- Noto UI 扩展字体"

        # 更新字体缓存
        echo -e "${yellow}正在更新字体缓存...${plain}"
        fc-cache -fv

        # post_installation_menu
    else
        echo -e "${red}Google Noto 中文字体安装失败。请检查网络连接和系统权限。${plain}"
        return 1
    fi
}

# 卸载 Google 开源中文字体
uninstall_google_noto_fonts() {
    echo -e "${yellow}正在卸载 Google Noto 中文字体...${plain}"
    sudo apt remove -y \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        fonts-noto-mono \
        fonts-noto-ui-extra
    echo -e "${green}Google Noto 中文字体已卸载！${plain}"

}

# 声明关联数组和有序菜单数组
declare -A menu_options
declare -a menu_order

# 初始化菜单选项
init_menu_options() {
    # 定义有序菜单项，元素是按照插入顺序存储的，访问时通过索引（数字）
    menu_order=(
        "安装所有常用系统依赖"
        "安装 zsh"
        "安装 oh-my-zsh"
        "安装 cheat.sh"
        "安装 angrysearch"
        "安装 Docker 和 Docker Compose"
        "安装 micro 编辑器"
        "安装 eg 命令示例工具"
        "安装 eggs"
        "安装 Plank Dock"
        "安装中文输入法 Fcitx"
        "安装 Google 开源中文字体"
        "按顺序安装所有软件"
        "卸载所有已安装软件"
        "卸载 zsh"
        "卸载 oh-my-zsh"
        "卸载 cheat.sh"
        "卸载 angrysearch"
        "卸载 Docker 和 Docker Compose"
        "卸载 micro 编辑器"
        "卸载 eg 命令示例工具"
        "卸载 eggs"
        "卸载 Plank Dock"
        "卸载中文输入法 Fcitx"
        "卸载 Google 开源中文字体"
        "退出"
    )

    # 初始化关联数组，元素是通过键值对存储的，键的顺序与插入顺序无关。关联数组的键值对没有严格的顺序，访问时通过键。
    menu_options=(
        ["安装所有常用系统依赖"]="install_common_dependencies"
        ["安装 zsh"]="install_zsh"
        ["安装 oh-my-zsh"]="install_ohmyzsh"
        ["安装 cheat.sh"]="install_cheatsh"
        ["安装 angrysearch"]="install_angrysearch"
        ["安装 Docker 和 Docker Compose"]="install_docker"
        ["安装 micro 编辑器"]="install_micro"
        ["安装 eg 命令示例工具"]="install_eg"
        ["安装 eggs"]="install_eggs"
        ["安装 Plank Dock"]="install_plank"
        ["安装中文输入法 Fcitx"]="install_chinese_input"
        ["安装 Google 开源中文字体"]="install_google_noto_fonts"
        ["按顺序安装所有软件"]="install_all_software"
        ["卸载所有已安装软件"]="uninstall_all_software"
        ["卸载 zsh"]="uninstall_zsh"
        ["卸载 oh-my-zsh"]="uninstall_ohmyzsh"
        ["卸载 cheat.sh"]="uninstall_cheatsh"
        ["卸载 angrysearch"]="uninstall_angrysearch"
        ["卸载 Docker 和 Docker Compose"]="uninstall_docker"
        ["卸载 micro 编辑器"]="uninstall_micro"
        ["卸载 eg 命令示例工具"]="uninstall_eg"
        ["卸载 eggs"]="uninstall_eggs"
        ["卸载 Plank Dock"]="uninstall_plank"
        ["卸载中文输入法 Fcitx"]="uninstall_chinese_input"
        ["卸载 Google 开源中文字体"]="uninstall_google_noto_fonts"
        ["退出"]="exit"
    )
}

# 获取菜单选项的键（显示文本）
get_menu_keys() {
    printf '%s\n' "${menu_order[@]}"
}

# 获取菜单选项的值（函数名）
get_menu_values() {
    local key
    for key in "${menu_order[@]}"; do
        printf '%s\n' "${menu_options[$key]}"
    done
}

# 按顺序安装所有软件
install_all_software() {
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red}请使用 sudo 运行此命令${plain}"
        return 1
    fi

    echo -e "${yellow}开始按顺序安装所有软件...${plain}"
    
    # 创建一个数组来跟踪安装失败的软件
    local failed_installations=()
    local successful_installations=()

    # 定义安装函数数组，按照逻辑顺序排列
    local install_functions=(
        "install_common_dependencies"  # 首先安装系统依赖
        "install_zsh"                  # 安装 zsh
        "install_ohmyzsh"              # 安装 oh-my-zsh
        "install_cheatsh"              # 安装 cheat.sh
        "install_docker"               # 安装 Docker
        "install_micro"                # 安装 micro 编辑器
        "install_eg"                   # 安装 eg 命令示例工具
        "install_angrysearch"          # 安装 angrysearch
        "install_plank"                # 安装 Plank Dock
        "install_eggs"                 # 安装 eggs
        "install_chinese_input"        # 安装中文输入法
        "install_google_noto_fonts"    # 安装 Google 字体
    )

# 遍历并尝试安装每个软件
for func in "${install_functions[@]}"; do
    # 这行代码的解释：
    # 1. for循环遍历install_functions数组中的每个元素
    # 2. [@]表示获取数组中的所有元素
    # 3. ""引号保护元素中可能存在的空格
    # 4. func变量将存储当前正在处理的函数名

    echo -e "\n${yellow}正在尝试安装：${func#install_}${plain}"
    # 这行代码的解释：
    # 1. echo -e 启用转义字符解释
    # 2. \n 添加换行符使输出更清晰
    # 3. ${yellow} 将后面的文字设置为黄色
    ## 4. ${func#install_} 删除函数名中的"install_"前缀
    # 5. ${plain} 将颜色恢复为默认值
    
    if $func; then
    # 这行代码的解释：
    # 1. $func 执行函数名对应的函数
    # 2. if 检查函数返回值（0表示成功，非0表示失败）

        echo -e "${green}${func#install_} 安装成功。${plain}"
        # 输出绿色的成功消息
        successful_installations+=("${func#install_}")
        # 将成功的软件名（去掉install_前缀）添加到成功列表

    else
        echo -e "${red}${func#install_} 安装失败。${plain}"
        # 输出红色的失败消息
        failed_installations+=("${func#install_}")
        # 将失败的软件名（去掉install_前缀）添加到失败列表
    fi
done

    # 总结安装结果
    echo -e "\n${yellow}===== 安装总结 =====${plain}"
    
    if [ ${#successful_installations[@]} -gt 0 ]; then
        echo -e "${green}成功安装的软件：${plain}"
        printf '%s\n' "${successful_installations[@]}"
    fi
    
    if [ ${#failed_installations[@]} -gt 0 ]; then
        echo -e "${red}安装失败的软件：${plain}"
        printf '%s\n' "${failed_installations[@]}"
        return 1
    else
        echo -e "${green}所有软件安装成功！${plain}"
    fi
}

# 软件安装菜单
software_installation_menu() {
    clear
    echo -e "${yellow}=== 软件安装菜单 ===${plain}"
    echo

    # 获取所有菜单项并保存到数组
    readarray -t keys < <(get_menu_keys)
    local total=${#keys[@]}
    
    # 显示除了第一个和最后两个选项之外的所有选项
    for ((i=1; i<total-2; i++)); do
        echo -e "${green}$i.${plain} ${keys[$i]}"
    done
    
    echo
    echo -e "${yellow}请输入选项 [1-$((total-3))] ${plain}"
    read -p "输入 (按 Enter 返回主菜单): " choice

    if [[ -z "$choice" ]]; then
        return
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $((total-3)) ]; then
        echo -e "${red}无效的选择，请重试${plain}"
        sleep 2
        software_installation_menu
        return
    fi

    # 获取选择的函数名并执行
    local selected_key=${keys[$choice]}
    local func_name=${menu_options[$selected_key]}
    $func_name

    echo
    read -p "按 Enter 键返回菜单..."
    software_installation_menu
}

# 主菜单函数
main_menu() {
    while true; do
        clear
        echo -e "${yellow}=== 主菜单 ===${plain}"
        echo -e "${green}系统依赖和基础工具${plain}"
        echo -e "1. 安装所有常用系统依赖"
        
        echo -e "\n${green}开发和编程工具${plain}"
        echo -e "2. 安装 zsh"
        echo -e "3. 安装 oh-my-zsh"
        echo -e "4. 安装 cheat.sh"
        echo -e "5. 安装 micro 编辑器"
        echo -e "6. 安装 eg 命令示例工具"
        
        echo -e "\n${green}系统增强工具${plain}"
        echo -e "7. 安装 angrysearch"
        echo -e "8. 安装 Plank Dock"
        
        echo -e "\n${green}容器和虚拟化${plain}"
        echo -e "9. 安装 Docker 和 Docker Compose"
        echo -e "10. 安装 eggs"
        
        echo -e "\n${green}本地化和输入法${plain}"
        echo -e "11. 安装中文输入法 Fcitx"
        echo -e "12. 安装 Google 开源中文字体"
        
        echo -e "\n${green}批量操作${plain}"
        echo -e "13. 按顺序安装所有软件"
        
        echo -e "\n${red}卸载工具${plain}"
        echo -e "14. 卸载 zsh"
        echo -e "15. 卸载 oh-my-zsh"
        echo -e "16. 卸载 cheat.sh"
        echo -e "17. 卸载 micro 编辑器"
        echo -e "18. 卸载 eg 命令示例工具"
        echo -e "19. 卸载 angrysearch"
        echo -e "20. 卸载 Plank Dock"
        echo -e "21. 卸载 Docker 和 Docker Compose"
        echo -e "22. 卸载 eggs"
        echo -e "23. 卸载中文输入法 Fcitx"
        echo -e "24. 卸载 Google 开源中文字体"
        echo -e "25. 卸载所有已安装软件"
        
        echo -e "\n${yellow}0. 退出${plain}"
        
        read -p "请选择操作 [0-25]: " choice

        # 映射选择到对应的菜单项
        case $choice in
            1) install_common_dependencies && post_installation_menu ;;
            2) install_zsh && post_installation_menu ;;
            3) install_ohmyzsh && post_installation_menu ;;
            4) install_cheatsh && post_installation_menu ;;
            5) install_micro && post_installation_menu ;;
            6) install_eg && post_installation_menu ;;
            7) install_angrysearch && post_installation_menu ;;
            8) install_plank && post_installation_menu ;;
            9) install_docker && post_installation_menu ;;
            10) install_eggs && post_installation_menu ;;
            11) install_chinese_input && post_installation_menu ;;
            12) install_google_noto_fonts && post_installation_menu ;;
            13) install_all_software && post_installation_menu  ;;
            14) uninstall_zsh ;;
            15) uninstall_ohmyzsh ;;
            16) uninstall_cheatsh ;;
            17) uninstall_micro ;;
            18) uninstall_eg ;;
            19) uninstall_angrysearch ;;
            20) uninstall_plank ;;
            21) uninstall_docker ;;
            22) uninstall_eggs ;;
            23) uninstall_chinese_input ;;
            24) uninstall_google_noto_fonts ;;
            25) uninstall_all_software ;;
            0) 
                echo -e "${green}感谢使用，再见！${plain}"
                exit 0 
                ;;
            *)
                echo -e "${red}无效的选择，请重试${plain}"
                sleep 2
                continue
                ;;
        esac

        # 等待用户确认，除了退出选项
        if [ "$choice" != "0" ]; then
            echo
            read -p "按 Enter 键返回菜单..."
        fi
    done
}



# 主程序入口
main() {
    check_root
    init_menu_options
    main_menu
}

# 运行主程序
main