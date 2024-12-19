#!/bin/bash
export LC_ALL=C
export LANG=en_US
export LANGUAGE=en_US.UTF-8

branch="master"
VERSION="$(curl -fsL https://api.github.com/repos/phlinhng/v2ray-tcp-tls-web/releases/latest | grep tag_name | sed -E 's/.*"v(.*)".*/\1/')"

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCmd="sudo"
else
  sudoCmd=""
fi

#copied & modified from atrandys trojan scripts
#copy from 秋水逸冰 ss scripts
if [[ -f /etc/redhat-release ]]; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
elif cat /etc/issue | grep -Eqi "debian|SparkyLinux"; then
  # grep 是一个文本搜索工具，用于在输入中查找匹配的文本。
  # -E 选项启用扩展正则表达式，使得可以使用更复杂的匹配模式。
  # -q 选项使 grep 在找到匹配项时不输出结果，只返回退出状态（0 表示找到匹配项，1 表示未找到）。
  # -i 选项使搜索不区分大小写。
  # "debian|SparkyLinux" 正则表达式匹配包含 "debian" 或 "SparkyLinux" 的文本。
  release="debian"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
elif cat /proc/version | grep -Eqi "debian"; then
  release="debian"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
  release="ubuntu"
  systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
  release="centos"
  systemPackage="yum"
  #colorEcho ${RED} "unsupported OS"
  #exit 0
fi

# install requirements
${sudoCmd} ${systemPackage} update -q
${sudoCmd} ${systemPackage} install curl wget jq lsof coreutils unzip -y -qq

${sudoCmd} mkdir -p /usr/local/etc/v2script

if [ ! -f "/usr/local/etc/v2script/config.json" ]; then
  ${sudoCmd} wget -q https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/config/v2script.json -O /usr/local/etc/v2script/config.json
elif [ -f "/usr/local/etc/v2script/config.json" ]; then
  ${sudoCmd} bash <(curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/migrate_v2ray.sh)
  ${sudoCmd} bash <(curl -sL https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/tools/migrate_tjgo.sh)
fi

${sudoCmd} wget -q -N https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/src/v2script.sh -O /usr/local/bin/v2script
${sudoCmd} chmod +x /usr/local/bin/v2script

${sudoCmd} wget -q -N https://raw.githubusercontent.com/phlinhng/v2ray-tcp-tls-web/${branch}/src/v2sub.sh -O /usr/local/bin/v2sub
${sudoCmd} chmod +x /usr/local/bin/v2sub

jq -r ".version = \"${VERSION}\"" /usr/local/etc/v2script/config.json > tmp.$$.json && ${sudoCmd} mv tmp.$$.json /usr/local/etc/v2script/config.json
