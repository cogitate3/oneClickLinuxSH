
#!/usr/bin/env bash

# Downloads the latest tarball from https://github.com/amir1376/ab-download-manager/releases and unpacks it into ~/.local/.
# Creates a .desktop entry for the app in ~/.local/share/applications based on FreeDesktop specifications.

set -euo pipefail

DEPENDENCIES=(curl tar)
LOG_FILE="/tmp/ab-dm-installer.log"

# --- Custom Logger
logger() {
  # 获取当前的日期和时间，并将其格式化为"年/月/日 时:分:秒"的形式
  timestamp=$(date +"%Y/%m/%d %H:%M:%S") 
  # 将命令放在小括号中会在一个子 shell 中执行这些命令。
  #这意味着在括号内的变量修改不会影响到外部的 shell。

  # 检查传入的第一个参数是否为"error"
  if [[ "$1" == "error" ]]; then
    # 如果是"error"，则用红色显示错误信息
    # 在控制台输出错误信息，并附加到日志文件中
    echo -e "${timestamp} -- "$0" [Error]: \033[0;31m$@\033[0m" | tee -a ${LOG_FILE}
  else
    # $0表示当前脚本的文件名
    # 如果不是"error"，则用默认颜色显示信息
    # 在控制台输出信息，并附加到日志文件中
    echo -e "${timestamp} -- "$0" [Info]: $@" | tee -a ${LOG_FILE}
  fi
}

# --- Detect OS and The Package Manager to use
detect_package_manager() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        local OS=${NAME}
    elif type lsb_release >/dev/null 2>&1; then #>/dev/null 2>&1 
        #用于丢弃命令的标准输出和标准错误输出，以便在检查命令是否存在时不输出任何信息。
        local OS=$(lsb_release -si)
        # 使用 type 命令检查 lsb_release 命令是否可用。
        # 如果可用，则执行 lsb_release -si 命令，并将结果赋值给变量 OS。
    elif [ -f /etc/lsb-release ]; then
        source /etc/lsb-release
        local OS="${DISTRIB_ID}"
    elif [ -f /etc/debian_version ]; then
        local OS=Debian
    else
        logger error "Your Linux Distro is not Supperted."
        logger error "Please install ${DEPENDENCIES[@]} Manually."
        exit 1
    fi

    if `grep -E 'Debian|Ubuntu' <<< $OS > /dev/null` ; then
        # 使用 grep 命令检查 OS 变量中是否包含 Debian 或 Ubuntu 字符串。
        # 如果包含，则执行 grep 命令，并将结果赋值给变量 systemPackage。
        # 否则，将 systemPackage 赋值为其他值。
        systemPackage="apt"
    elif `grep -E 'Fedora|CentOS|Red Hat|AlmaLinux' <<< $OS > /dev/null`; then
        systemPackage="dnf"
    fi
}

detect_package_manager

# --- Install dependencies
install_dependencies() {

    local answer
    read -p "Do you want to install $1? [Y/n]: " -r answer
    answer=${answer:-Y}  # Set default to 'Y' if no input is given

    case $answer in
        [Yy]* )
            sudo ${systemPackage} update -y
            logger "installing $1 package ..."
            sudo ${systemPackage} install -y $1
            ;;
        [Nn]* )
            logger "Skipping the installation of $1."
            ;;
        * )
            logger error "Please answer yes or no."
            install_dependencies "$1"  # re-prompt for the same package
            ;;
    esac
}

# Check dependencies and install if missing
check_dependencies() {
    for pkg in "${DEPENDENCIES[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            logger "$pkg is not installed. Installing..."
            install_dependencies "$pkg"
        else
            logger "$pkg is already installed."
        fi
    done
}

APP_NAME="ABDownloadManager"
PLATFORM="linux"
ARCH="x64"
EXT="tar.gz"

RELEASE_URL="https://api.github.com/repos/amir1376/ab-download-manager/releases/latest"
GITHUB_RELEASE_DOWNLOAD="https://github.com/amir1376/ab-download-manager/releases/download"

LATEST_VERSION=$(curl -fSs "${RELEASE_URL}" | grep '"tag_name":' | sed -E 's/.*"tag_name": ?"([^"]+)".*/\1/')
# curl -fSs "${RELEASE_URL}"：这部分使用 curl 命令从 RELEASE_URL 指定的网址下载
# 数据。 curl 就像一个网络快递员，它可以从网上下载文件或网页内容。 -f、
# -S 和 -s 是选项，它们告诉 curl 忽略错误、显示进度条和静默运行（不
# 显示额外的信息）。 下载下来的数据是一个 JSON 格式的文本，包含了最新
# 版本的各种信息。
# 
# grep '"tag_name":'：这部分使用 grep 命令查找包含 "tag_name": 的行。 grep
# 就像一个搜索引擎，它可以在文本中查找特定的模式。 "tag_name": 是 JSON
# 数据中表示版本号的关键字。 只有包含这个关键字的行才会被保留。
# 
# sed -E 's/.*"tag_name": ?"([^"]+)".*/\1/'：这部分使用 sed 命令提取版本号。
# sed 就像一个文本编辑器，它可以对文本进行各种操作。 s/.*"tag_name":
# ?"([^"]+)".*/\1/ 是一个替换命令，它将匹配到的行替换成括号 () 中的
# 内容。 .*"tag_name": ?"([^"]+)".* 是一个正则表达式，它匹配包含
# "tag_name": 的行，并用括号 () 将版本号提取出来。 \1 表示将括号中的
# 内容替换到整个行中。 最终，只留下版本号。
# 
# $(...)：这部分是命令替换。 它将前面命令的输出结果赋值给 LATEST_VERSION
# 变量。 你可以把它想象成一个盒子，盒子里面装的是 curl、grep 和 sed
# 命令执行的结果，也就是最新版本号。

ASSET_NAME="${APP_NAME}_${LATEST_VERSION:1}_${PLATFORM}_${ARCH}.${EXT}"
DOWNLOAD_URL="$GITHUB_RELEASE_DOWNLOAD/${LATEST_VERSION}/$ASSET_NAME"

BINARY_PATH="$HOME/.local/$APP_NAME/bin/$APP_NAME"


# --- Delete the old version Application if exists
delete_old_version() {
    # --- Killing Any Application Process 
    pkill -f "$APP_NAME"
    rm -rf "$HOME/.local/$APP_NAME"
    rm -rf "$HOME/.local/bin/$APP_NAME"
    logger "removed old version AB Download Manager"
}

# --- Generate a .desktop file for the app
generate_desktop_file() {
    cat <<EOF > "$HOME/.local/share/applications/abdownloadmanager.desktop"
[Desktop Entry]
Name=AB Download Manager
Comment=Manage and organize your download files better than before
GenericName=Downloader
Categories=Utility;Network;
Exec=$BINARY_PATH
Icon=$HOME/.local/$APP_NAME/lib/$APP_NAME.png
Terminal=false
Type=Application
StartupWMClass=com-abdownloadmanager-desktop-AppKt
EOF
}

# --- Download the latest version of the app
download_zip() {
    # Remove the app tarball if it exists in /tmp
    rm -f "/tmp/$ASSET_NAME"

    logger "downloading AB Download Manager ..."
    # Perform the download with curl
    if curl --progress-bar -fSL -o "/tmp/$ASSET_NAME" "${DOWNLOAD_URL}"; then
        logger "download finished successfully"
    else
        logger error "Download failed! Something Went Wrong"
        logger error "Hint: Check Your Internet Connectivity"
        # Optionally remove the partially downloaded file
        rm -f "/tmp/$ASSET_NAME"
    fi
}


# --- Install the app
install_app() {

    logger "Installing AB Download Manager ..."
    # --- Setup ~/.local directories
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
    tar -xzf "/tmp/$ASSET_NAME" -C "$HOME/.local"

    # --- remove tarball after installation
    rm "/tmp/$ASSET_NAME"

    # Link the binary to ~/.local/bin
    ln -s "$BINARY_PATH" "$HOME/.local/bin/$APP_NAME"

    # Create a .desktop file in ~/.local/share/applications
    generate_desktop_file

    logger "AB Download Manager installed successfully"
    logger "it can be found in Applications menu or run '$APP_NAME' in terminal"
    logger "Make sure $HOME/.local/bin exists in PATH"
    logger "installation logs saved in: ${LOG_FILE}"
    
}

# --- Check if the app is installed
check_if_installed() {
    local installed_version
    installed_version=$($APP_NAME --version 2>/dev/null)
    if [ -n "$installed_version" ]; then
        echo "$installed_version"
    else
        echo ""
    fi
}

# --- Update the app
update_app() {
    logger "checking update"
    if [ "$1" != "${LATEST_VERSION:1}" ]; then
        logger "new version is available: v${LATEST_VERSION:1}. Updating..."
        download_zip
        delete_old_version
        install_app
    else
        logger "You have the latest version installed."
        exit 0
    fi
}

main() {
    echo "" > "$LOG_FILE"
    local installed_version
    check_dependencies
    installed_version=$(check_if_installed)
    if [ -n "$installed_version" ]; then
        logger "AB Download Manager v$installed_version is currently installed."
        update_app "$installed_version"
    else
        download_zip
        install_app
    fi
}

main "$@"

