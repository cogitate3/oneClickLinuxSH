# 一些有用的软件代码片段



# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
}

# 下载GitHub release包的函数
# 参数: github release页面的下载链接
# 步骤1: 通过github api获取发布的软件名称，最新版本号
# 步骤2: 通过解析本机的cpu架构，linux发行版本，构造文件名，或者查找release页面的下载文件名
# 步骤3: 构造下载链接，下载到临时目录
# 步骤4: 给下载的文件执行权限，通过sudo apt install /path/to/file来完成安装
# 步骤5: 删除临时文件
download_github_latest_release() {
    # 检查参数
    if [ $# -ne 1 ]; then
        log "ERROR" "参数错误: 需要提供下载链接"
        return 1
    fi

    # 提取owner和repo
    url=$1
    owner_repo=$(echo "$url" | grep -oP 'github\.com/\K[^/]+/[^/]+')

    # 获取最新版本号
    latest_version=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/$owner_repo/releases/latest" | grep -q 200 && curl -s "https://api.github.com/repos/$owner_repo/releases/latest" | jq -r '.tag_name')
    if [ $? -ne 0 ] || [ -z "$latest_version" ]; then
        log "ERROR" "无法获取最新版本号"
        return 1
    fi

    # 获取所有 assets 的下载链接，并检查 curl 和 jq 的返回值
    download_links_json=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/$owner_repo/releases/latest" | grep -q 200 && curl -s "https://api.github.com/repos/$owner_repo/releases/latest" | jq -r '.assets[] | .browser_download_url')

    if [ $? -ne 0 ] || [ -z "$download_links_json" ]; then
        log "ERROR" "无法获取下载链接: curl 返回码 $?，链接: $download_links_json"
        return 1
    fi

    # 使用 jq 解析 JSON 数组，并循环输出
    readarray -t download_links <<< "$download_links_json"

    if (( ${#download_links[@]} == 0 )); then
        log "WARNING" "没有找到任何下载链接"
        return 0 # 警告，但不是错误
    fi

    echo "最新版本: $latest_version"
    echo "下载链接:"
    for link in "${download_links[@]}"; do
        echo "  - $link"
    done

    # 获取文件名
    architecture=$(uname -m)
    log "INFO" "检测到的CPU架构: $architecture"

    # 根据架构选择合适的文件名
    case $architecture in
        x86_64)
            arch_suffix="amd64"
            ;;
        aarch64)
            arch_suffix="arm64"
            ;;
        armv7l)
            arch_suffix="armhf"
            ;;
        *)
            log "ERROR" "不支持的CPU架构: $architecture"
            return 1
            ;;
    esac


    # 选择下载链接中包含“linux-本机架构”，且以.deb结尾的下载链接
    for link in "${download_links[@]}"; do
        log "INFO" "Checking link: $link"  # Log each link being checked
        if [[ $link == *"linux-$architecture"* ]] && [[ $link == *".deb"* ]]; then
            download_link="$link"
            log "INFO" "Found matching download link: $download_link"
            break
        fi
    done
    
    # Check if a download link was found
    if [ -z "$download_link" ]; then
        log "ERROR" "没有找到合适的下载链接"
        return 1
    fi

    # 下载到临时目录
    temp_dir=$(mktemp -d)
    log "INFO" "下载文件到临时目录: $temp_dir"
    filename="${download_link##*/}"  # 去除 URL 中最后一个 `/` 之后的部分
    temp_file="$temp_dir/$filename"

    # Download the file and check for errors
    if curl -L -o "$temp_file" "$download_link"; then
        echo "下载成功，文件名: $filename"
    else
        log "ERROR" "下载失败"
        return 1
    fi

    # 给下载的文件执行权限
    chmod +x "$temp_file"

    # 安装文件
    log "INFO" "安装文件..."
    if ! sudo apt install -y "$temp_file"; then
        log "ERROR" "安装失败"
        return 1
    fi

    # 删除临时文件
    rm -rf "$temp_dir"
    log "INFO" "安装成功，临时文件已删除"
    return 0
}


# 获取github仓库所有release页面的最新版本的下载链接
# 以https://github.com/localsend/localsend/releases页面为例
# 最新版是v1.16.1，下载链接为https://github.com/localsend/localsend/releases/download/v1.16.1/LocalSend-1.16.1-android-arm32v7.apk等等14个文件
# 参数为: github仓库的release页面的访问链接
get_github_latest_release_download_link() {
    # 检查参数
    if [ $# -ne 1 ]; then
        log "ERROR" "参数错误: 需要提供release页面的访问链接"
        return 1
    fi

# 提取owner和repo
    url=$1
    owner_repo=$(echo "$url" | sed -E 's|https://github.com/(.*?)/(.*?)/releases.*|\1/\2|')

    # 获取最新版本号
    latest_version=$(curl -s "https://api.github.com/repos/$owner_repo/releases/latest" | jq -r .tag_name)
    if [ -z "$latest_version" ]; then
        log "ERROR" "无法获取最新版本号"
        return 1
    fi

    # 获取所有assets的下载链接
    download_links=$(curl -s "https://api.github.com/repos/$owner_repo/releases/latest" | jq -r '.assets[] | .browser_download_url')
    if [ -z "$download_links" ]; then
        log "ERROR" "无法获取下载链接"
        return 1
    fi

    # 打印所有下载链接
    echo "$download_links"
}