#!/bin/bash

# 定义颜色变量
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 检查是否以 root 身份运行
if [[ $EUID -ne 0 ]]; then
  echo -e "${red}某些操作需要 root 权限，请使用 sudo 运行此脚本。${plain}"
  exit 1
fi

# 通用依赖安装函数
install_common_dependencies() {
    echo -e "${green}正在安装常用系统依赖...${plain}"
    
    # 更新包列表
    apt-get update
    
    # 定义依赖列表
    local dependencies=(
        "libgit2-1.5"
        "gconf2"
        "gconf-service"
        "curl"
        "wget"
        "git"
        "tldr"
        "ca-certificates"
        "gnupg"
        "software-properties-common"
        "apt-transport-https"
        "neofetch"
        "bat"
        "geany"
        "terminator"
    )
    
    # 安装依赖
    for dep in "${dependencies[@]}"; do
        if ! dpkg -s "$dep" >/dev/null 2>&1; then
            echo -e "${yellow}正在安装 $dep...${plain}"
            apt-get install -y "$dep"
        else
            echo -e "${green}$dep 已安装。${plain}"
        fi
    done
    
    echo -e "${green}常用系统依赖安装完成。${plain}"
    post_installation_menu
}

# 函数：安装 zsh 和 oh-my-zsh
install_zsh_ohmyzsh() {
    install_common_dependencies
    
    chsh -s $(which zsh)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo -e "${green}zsh 和 oh-my-zsh 安装完成。${plain}"
    post_installation_menu
}

# 函数：安装 Homebrew (仅在需要安装 eg 时才需要)
install_homebrew() {
    install_common_dependencies

    # Check if Homebrew is already installed
    if command -v brew &> /dev/null; then
        echo -e "${green}Homebrew 已经安装。${plain}"
        post_installation_menu
        return 0
    fi

    # Install Homebrew
    echo -e "${green}正在安装 Homebrew...${plain}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Check installation status
    if [ $? -eq 0 ]; then
        # Configure Homebrew path for different shells
        echo -e "${green}Homebrew 安装成功。正在配置环境...${plain}"
        
        # Add Homebrew to PATH for bash
        if [ -f ~/.bashrc ]; then
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        fi
        
        # Add Homebrew to PATH for zsh
        if [ -f ~/.zshrc ]; then
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
        fi
        
        # Reload shell environment
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        
        echo -e "${green}Homebrew 安装并配置完成。${plain}"
    else
        echo -e "${red}Homebrew 安装失败。请检查网络连接和系统权限。${plain}"
        post_installation_menu
        return 1
    fi

    post_installation_menu
}

# 函数：安装 cheat.sh
install_cheatsh() {
  apt install -y rlwrap
  curl -s https://cht.sh/:cht.sh | sudo tee /usr/local/bin/cht.sh && chmod +x /usr/local/bin/cht.sh
  echo -e "${green}cheat.sh 安装完成。 使用方法：cht.sh 命令 (例如 cht.sh curl)${plain}"
  post_installation_menu
}

# 函数：安装 eg
install_eg() {
  if ! command -v brew &> /dev/null; then
    echo -e "${red}请先安装 Homebrew。${plain}"
    return 1
  fi
  brew install eg-examples
  echo -e "${green}eg 安装完成。 使用方法：eg 命令 (例如 eg curl)${plain}"
  post_installation_menu
}

# 函数：安装 angrysearch
install_angrysearch() {
    install_common_dependencies

    cd ~/Downloads
    wget https://github.com/DoTheEvo/ANGRYsearch/archive/refs/tags/v1.0.4.tar.gz
    tar -zxvf v1.0.4.tar.gz -C ~/Apps
    cd ~/Apps/ANGRYsearch-1.0.4
    sudo ./install.sh
    echo -e "${green}angrysearch 安装完成。${plain}"
    post_installation_menu
}

# 函数：安装 tabby
install_tabby() {
  cd ~/Downloads
  wget https://github.com/Eugeny/tabby/releases/download/v1.0.188/tabby-1.0.188-linux-x64.deb
  sudo dpkg -i tabby-1.0.188-linux-x64.deb
  echo -e "${green}tabby 安装完成。${plain}"
  post_installation_menu
}

# 函数：安装 WPS Office (注意版本号可能需要更新)
install_wps() {
  cd ~/Downloads
  wget https://wps-linux-personal.wpscdn.cn/wps/download/ep/Linux2019/11664/wps-office_11.1.0.11664_amd64.deb
  sudo dpkg -i wps-office_11.1.0.11664_amd64.deb
  sudo apt-mark hold wps-office  # 阻止 WPS 自动更新
  echo -e "${green}WPS Office 安装完成。  已阻止自动更新，请手动更新到稳定版本。${plain}"
  post_installation_menu
}

# 函数：安装 micro 编辑器
install_micro() {
    # 检查是否已安装 micro
    if command -v micro &> /dev/null; then
        echo -e "${green}micro 编辑器已安装。${plain}"
        post_installation_menu
        return 0
    fi

    # 创建临时下载目录
    mkdir -p ~/Downloads/micro_install

    # 下载最新版本的 micro
    echo -e "${yellow}正在下载 micro 编辑器...${plain}"
    if ! curl -L https://github.com/zyedidia/micro/releases/latest/download/micro-linux64.tar.gz -o ~/Downloads/micro_install/micro.tar.gz; then
        echo -e "${red}下载 micro 失败。请检查网络连接。${plain}"
        post_installation_menu
        return 1
    fi

    # 解压并安装
    echo -e "${yellow}正在安装 micro 编辑器...${plain}"
    tar -xzf ~/Downloads/micro_install/micro.tar.gz -C ~/Downloads/micro_install

    # 移动到系统路径
    sudo mv ~/Downloads/micro_install/micro-*/micro /usr/local/bin/

    # 清理临时文件
    rm -rf ~/Downloads/micro_install

    # 验证安装
    if command -v micro &> /dev/null; then
        echo -e "${green}micro 编辑器安装成功！${plain}"
        micro --version
    else
        echo -e "${red}micro 编辑器安装失败。${plain}"
        post_installation_menu
        return 1
    fi

    post_installation_menu
}

# 函数：安装 Brave 浏览器
install_brave() {
  apt update && apt install -y curl
  curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  apt update && apt install -y brave-browser
  echo -e "${green}Brave 浏览器安装完成。${plain}"
  post_installation_menu
}

# 函数：安装 Plank 快捷启动器
install_plank() {
  apt update && apt install -y plank
  echo -e "${green}Plank 快捷启动器安装完成。${plain}"
  post_installation_menu
}

# 函数：安装 v2rayA (两种方法)
install_v2raya() {
  read -p "请选择安装方法 (1: 使用脚本, 2: 使用软件源): " method
  case $method in
    1)
      curl -Ls https://mirrors.v2raya.org/go.sh | sudo bash
      sudo systemctl disable v2ray --now
      echo -e "${green}v2rayA (脚本安装) 完成。  systemd 服务已禁用。${plain}" ;;
    2)
      wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/trusted.gpg.d/v2raya.asc
      echo "deb https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list
      apt update && apt install -y v2raya
      echo -e "${green}v2rayA (软件源安装) 完成。${plain}" ;;
    *) echo -e "${red}无效的选项。${plain}" ;;
  esac
  post_installation_menu
}

# 函数：安装 Windsurf
install_windsurf() {
    # 检查是否已安装 Windsurf
    if command -v windsurf >/dev/null 2>&1; then
        echo -e "${green}Windsurf 已经安装。${plain}"
        post_installation_menu
        return 0
    fi

    # 确保必要的依赖已安装
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y curl gnupg
    elif command -v yum >/dev/null 2>&1; then
        yum update -y
        yum install -y curl gnupg
    else
        echo -e "${red}错误：未找到包管理器。无法安装 Windsurf。${plain}"
        post_installation_menu
        return 1
    fi

    # 下载并安装 Windsurf
    echo -e "${green}正在安装 Windsurf...${plain}"
    
    # 添加 Windsurf GPG 密钥
    curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg
    
    # 添加 Windsurf 软件源
    echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null
    
    # 更新并安装 Windsurf
    apt-get update
    apt-get install -y windsurf

    # 检查安装是否成功
    if [ $? -eq 0 ]; then
        echo -e "${green}Windsurf 安装成功！${plain}"
        post_installation_menu
    else
        echo -e "${red}安装 Windsurf 失败。请检查上面的错误消息。${plain}"
        post_installation_menu
        return 1
    fi
}

# 函数：安装 eggs (Debian/Ubuntu 系统工具)
install_eggs() {
    # 检查是否已安装 eggs
    if command -v eggs &> /dev/null; then
        echo -e "${green}eggs 已安装。${plain}"
        post_installation_menu
        return 0
    fi

    # 添加 GPG 密钥和仓库
    echo -e "${yellow}正在添加 eggs 仓库...${plain}"
    
    # 安装必要的依赖
    sudo apt update
    sudo apt install -y gnupg curl

    # 添加 eggs 官方仓库 GPG 密钥
    curl -fsSL https://pieroproietti.github.io/penguins-eggs/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/eggs-archive-keyring.gpg

    # 添加仓库源
    echo "deb [signed-by=/usr/share/keyrings/eggs-archive-keyring.gpg] https://pieroproietti.github.io/penguins-eggs/ stable main" | sudo tee /etc/apt/sources.list.d/eggs.list

    # 更新并安装 eggs
    sudo apt update
    if ! sudo apt install -y eggs; then
        echo -e "${red}eggs 安装失败。请检查网络连接和系统权限。${plain}"
        post_installation_menu
        return 1
    fi

    # 验证安装
    if command -v eggs &> /dev/null; then
        echo -e "${green}eggs 安装成功！${plain}"
        eggs --version
    else
        echo -e "${red}eggs 安装失败。${plain}"
        post_installation_menu
        return 1
    fi

    post_installation_menu
}

# 通用的安装后菜单函数
post_installation_menu() {
    while true; do
        echo ""
        echo -e "${green}安装完成！请选择下一步操作：${plain}"
        echo "0. 退出脚本"
        echo "1. 返回主菜单"
        read -p "请输入选项 (0-1): " post_choice

        case $post_choice in
            0)
                echo -e "${green}退出脚本。${plain}"
                exit 0
                ;;
            1)
                echo -e "${green}返回主菜单。${plain}"
                return
                ;;
            *)
                echo -e "${red}无效的选项，请重新输入。${plain}"
                ;;
        esac
    done
}

# 显示菜单
while true; do
    clear
    echo -e "${green}系统工具一键安装脚本 v2.1${plain}"
    echo "0. 安装所有常用系统依赖"
    echo "1. 安装 zsh 和 oh-my-zsh"
    echo "2. 安装 Homebrew"
    echo "3. 安装 cheat.sh"
    echo "4. 安装 eg"
    echo "5. 安装 angrysearch"
    echo "6. 安装 tabby"
    echo "7. 安装 WPS Office"
    echo "8. 安装 Docker 和 Docker Compose"
    echo "9. 安装 Brave 浏览器"
    echo "10. 安装 v2rayA"
    echo "11. 安装 Windsurf IDE"
    echo "12. 安装 micro 编辑器"
    echo "13. 安装 eggs"
    echo "14. 按顺序安装所有软件"
    echo "15. 退出"
    read -p "请输入选项 (0-15): " choice

    case $choice in
        0) install_common_dependencies ;;
        1) install_zsh_ohmyzsh ;;
        2) install_homebrew ;;
        3) install_cheatsh ;;
        4) install_eg ;;
        5) install_angrysearch ;;
        6) install_tabby ;;
        7) install_wps ;;
        8) install_docker ;;
        9) install_brave ;;
        10) install_v2raya ;;
        11) install_windsurf ;;
        12) install_micro ;;
        13) install_eggs ;;
        14)
            install_common_dependencies
            install_zsh_ohmyzsh
            install_homebrew
            install_cheatsh
            install_eg
            install_angrysearch
            install_tabby
            install_wps
            install_docker
            install_brave
            install_v2raya
            install_windsurf
            install_micro
            install_eggs
            ;;
        15)
            echo -e "${green}退出脚本。${plain}"
            exit 0
            ;;
        *)
            echo -e "${red}无效的选项，请重新输入。${plain}"
            ;;
    esac
done

# 为 zsh 添加 sudo 快捷键 (仅在 zsh 下生效)
if [ -n "$ZSH_VERSION" ]; then
    echo "bindkey -s '\e\e' '\C-asudo \C-e'" >> ~/.zshrc
    echo "请重新打开终端或运行 'exec zsh' 以应用更改。"
else
    echo "提示：sudo 快捷键仅在 zsh 下生效，当前 shell 不是 zsh。"
fi