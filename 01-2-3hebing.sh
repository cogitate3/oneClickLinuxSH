#!/bin/bash

# 引入日志函数
source 001log2File.sh

# 检查依赖工具是否安装
check_dependencies() {
  local dependencies=("jq" "curl" "wget")
  for tool in "${dependencies[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      log 3 "依赖工具 $tool 未安装，正在安装..."
      sudo apt install -y "$tool" || {
        log 3 "安装工具 $tool 失败，请手动安装后重试。"
        exit 1
      }
    fi
  done
}

# 从 GitHub Release 页面提取资源下载链接
get_assets_links() {
  # 检查参数
  if [ $# -ne 1 ]; then
    log 3 "参数错误: 需要提供 GitHub Release 页面 URL"
    return 1
  fi

  local url="$1"

  # 提取 owner/repo
  local owner_repo
  owner_repo=$(echo "$url" | grep -oP 'github\.com/\K[^/]+/[^/]+')
  if [ -z "$owner_repo" ]; then
    log 3 "无法从提供的 URL 中提取 owner/repo，请检查 URL 格式是否正确。"
    return 1
  fi

  # 检查依赖工具
  check_dependencies

  # 获取最新 Release 的 JSON 数据
  local release_json
  release_json=$(curl -s "https://api.github.com/repos/$owner_repo/releases/latest")
  if [ $? -ne 0 ] || [ -z "$release_json" ]; then
    log 3 "无法从 GitHub API 获取 Release 数据，请检查网络连接或 URL 是否正确。"
    return 1
  fi

  # 提取最新版本号
  local latest_version
  latest_version=$(echo "$release_json" | jq -r '.tag_name')
  if [ -z "$latest_version" ]; then
    log 3 "未能从 API 返回的数据中提取版本号，请检查 API 响应格式。"
    return 1
  fi
  log 1 "成功获取最新版本号: $latest_version"

  # 提取 assets 下载链接
  local download_links
  download_links=$(echo "$release_json" | jq -r '.assets[]?.browser_download_url')
  if [ -z "$download_links" ]; then
    log 2 "该版本 ($latest_version) 没有可用的资源下载链接。"
    return 0
  fi

  # 输出所有下载链接
  log 1 "最新版本 ($latest_version) 的资源下载链接如下："
  local link_array=()
  while IFS= read -r link; do
    link_array+=("$link")
    log 1 "- $link"
  done <<< "$download_links"

  # 返回链接数组
  DOWNLOAD_LINKS=("${link_array[@]}")
  return 0
}

# 如果脚本被直接运行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # 示例调用
  get_assets_links "https://github.com/localsend/localsend/releases"
fi

# 获取下载链接并匹配正则表达式
get_download_link() {
  # 检查参数
  if [ $# -lt 1 ]; then
    log 3 "参数错误: 需要提供 GitHub Releases 页面 URL"
    return 1
  fi

  local url="$1"
  local regex="${2:-}" # 如果未提供正则表达式，默认空值

  # 调用 `get_assets_links` 获取链接和版本号
  get_assets_links "$url" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    log 3 "获取资源链接失败，请检查 URL 是否正确。"
    return 1
  fi

  # 如果未提供正则表达式，仅输出版本号
  if [ -z "$regex" ]; then
    log 1 "未提供正则表达式，最新版本号为: $LATEST_VERSION"
    return 0
  fi

  # 检查是否获取到下载链接
  if [ ${#DOWNLOAD_LINKS[@]} -eq 0 ]; then
    log 3 "未找到任何资源链接，请检查 Releases 页面是否有可用资源。"
    return 1
  fi

  # 匹配正则表达式
  declare -a MATCHED_LINKS=()
  for link in "${DOWNLOAD_LINKS[@]}"; do
    if [[ "$link" =~ $regex ]]; then
      MATCHED_LINKS+=("$link")
      log 1 "匹配到下载链接: $link"
    else
      log 2 "不匹配: $link"
    fi
  done

  # 检查匹配结果
  if [ ${#MATCHED_LINKS[@]} -eq 0 ]; then
    log 3 "没有找到符合正则表达式 (${regex}) 的下载链接。"
    return 1
  fi

  # 返回第一个匹配的下载链接
  DOWNLOAD_URL="${MATCHED_LINKS[0]}"
  log 1 "选择的下载链接: $DOWNLOAD_URL"
  return 0
}

# 安装下载的包
install_package() {
  local download_link="$1"
  local max_retries=3
  local retry_delay=5
  local timeout=30
  local retry_count=0
  local success=false

  # 创建临时目录
  local tmp_dir="/tmp/downloads"
  mkdir -p "$tmp_dir"

  # 下载文件
  log 1 "开始下载: $download_link"
  local filename
  filename="$tmp_dir/$(basename "$download_link")"
  while [ $retry_count -lt $max_retries ] && [ "$success" = false ]; do
    if curl -fSL --connect-timeout "$timeout" --retry "$max_retries" --retry-delay "$retry_delay" -o "$filename" "$download_link"; then
      success=true
      log 1 "下载成功: $filename"
    else
      retry_count=$((retry_count + 1))
      log 2 "下载失败，重试中 (${retry_count}/${max_retries})..."
      sleep "$retry_delay"
    fi
  done

  if [ "$success" = false ]; then
    log 3 "下载失败，已达到最大重试次数。"
    return 1
  fi

  # 根据文件类型安装
  case "${filename##*.}" in
    deb)
      log 1 "安装 DEB 包: $filename"
      if sudo dpkg -i "$filename"; then
        log 1 "安装成功: $filename"
      else
        log 2 "安装失败，尝试修复依赖..."
        if sudo apt-get install -f -y && sudo dpkg -i "$filename"; then
          log 1 "依赖修复并安装成功: $filename"
        else
          log 3 "安装失败: $filename"
          return 1
        fi
      fi
      ;;
    gz|tgz)
      log 1 "检测到压缩包: $filename，解压到临时目录..."
      local extract_dir="$tmp_dir/extracted"
      mkdir -p "$extract_dir"
      if tar -xzf "$filename" -C "$extract_dir"; then
        log 1 "解压成功，文件已解压到: $extract_dir"
        log 2 "请手动完成安装。"
        return 2
      else
        log 3 "解压失败: $filename"
        return 1
      fi
      ;;
    *)
      log 3 "不支持的文件类型: ${filename##*.}"
      return 1
      ;;
  esac

  # 清理临时文件
  log 1 "清理临时文件..."
  rm -f "$filename"
  return 0
}

# 示例调用
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  get_download_link "https://github.com/amir1376/ab-download-manager/releases" ".*linux.*\.deb$"
  if [ $? -eq 0 ]; then
    install_package "$DOWNLOAD_URL"
  fi
fi