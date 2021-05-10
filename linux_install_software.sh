#!/bin/bash

export LC_ALL=C
export LANG=C
export LANGUAGE=en_US.UTF-8


# fonts color
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}



sudoCommand=""


if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  sudoCommand="sudo"
fi


osReleaseVersion=""
osRelease=""
osSystemPackage=""
osSystemMdPath=""
osSystemShell="bash"

# 系统检测版本
function getLinuxOSVersion(){
    # copy from 秋水逸冰 ss scripts
    if [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemMdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemMdPath="/usr/lib/systemd/system/"
    fi


	if [[ -s /etc/redhat-release ]]; then
		grep -oE  "[0-9.]+" /etc/redhat-release
        osReleaseVersion=$(cat /etc/redhat-release | tr -dc '0-9.'|cut -d \. -f1)
	else
		grep -oE  "[0-9.]+" /etc/issue
        osReleaseVersion=$(cat /etc/issue | tr -dc '0-9.'|cut -d \. -f1)
	fi


    [[ -z $(echo $SHELL|grep zsh) ]] && osSystemShell="bash" || osSystemShell="zsh"

    echo "OS info: ${osRelease}, ${osReleaseVersion}, ${osSystemPackage}, ${osSystemMdPath}， ${osSystemShell}"
}


osPort80=""
osPort443=""
osSELINUXCheck=""
osSELINUXCheckIsRebootInput=""

function testLinuxPortUsage(){
    $osSystemPackage -y install net-tools socat

    osPort80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
    osPort443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`

    if [ -n "$osPort80" ]; then
        process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
        red "==========================================================="
        red "检测到80端口被占用，占用进程为：${process80}，本次安装结束"
        red "==========================================================="
        exit 1
    fi

    if [ -n "$osPort443" ]; then
        process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
        red "============================================================="
        red "检测到443端口被占用，占用进程为：${process443}，本次安装结束"
        red "============================================================="
        exit 1
    fi

    osSELINUXCheck=$(grep SELINUX= /etc/selinux/config | grep -v "#")
    if [ "$osSELINUXCheck" == "SELINUX=enforcing" ]; then
        red "======================================================================="
        red "检测到SELinux为开启强制模式状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
        red "======================================================================="
        read -p "是否现在重启? 请输入 [Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS 重启中..."
            reboot
        fi
        exit
    fi

    if [ "$osSELINUXCheck" == "SELINUX=permissive" ]; then
        red "======================================================================="
        red "检测到SELinux为宽容模式状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
        red "======================================================================="
        read -p "是否现在重启? 请输入 [Y/n] :" osSELINUXCheckIsRebootInput
        [ -z "${osSELINUXCheckIsRebootInput}" ] && osSELINUXCheckIsRebootInput="y"

        if [[ $osSELINUXCheckIsRebootInput == [Yy] ]]; then
            sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
            echo -e "VPS 重启中..."
            reboot
        fi
        exit
    fi

    if [ "$osRelease" == "centos" ]; then
        if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ; then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        if  [ -n "$(grep ' 5\.' /etc/redhat-release)" ] ; then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        ${sudoCommand} systemctl stop firewalld
        ${sudoCommand} systemctl disable firewalld

        if [ "$osReleaseVersion" == "7" ]; then
            rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
        fi
        


    elif [ "$osRelease" == "ubuntu" ]; then
        if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi
        if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
            red "==============="
            red "当前系统不受支持"
            red "==============="
            exit
        fi

        ${sudoCommand} systemctl stop ufw
        ${sudoCommand} systemctl disable ufw


    elif [ "$osRelease" == "debian" ]; then
        $osSystemPackage update -y
        $osSystemPackage install curl wget git unzip zip tar -y
    fi

}



# 编辑 SSH 公钥 文件用于 免密码登录
function editLinuxLoginWithPublicKey(){
    if [ ! -d "${HOME}/ssh" ]; then
        mkdir -p ${HOME}/.ssh
    fi

    vi ${HOME}/.ssh/authorized_keys
}

# 修改SSH 端口号
function changeLinuxSSHPort(){
    green "修改的SSH登陆的端口号, 不要使用常用的端口号. 例如 20|21|23|25|53|69|80|110|443|123!"
    read -p "请输入要修改的端口号(必须是纯数字并且在1024~65535之间或22):" osSSHLoginPortInput
    osSSHLoginPortInput=${osSSHLoginPortInput:-0}

    if [ $osSSHLoginPortInput -eq 22 -o $osSSHLoginPortInput -gt 1024 -a $osSSHLoginPortInput -lt 65535 ]; then
        sed -i "s/#\?Port [0-9]*/Port $osSSHLoginPortInput/g" /etc/ssh/sshd_config

        if [ "$osRelease" == "centos" ] ; then
            $osSystemPackage -y install policycoreutils-python

            semanage port -a -t ssh_port_t -p tcp $osSSHLoginPortInput
            firewall-cmd --add-port=$osSSHLoginPortInput/tcp --permanent
            firewall-cmd --reload
            ${sudoCommand} service sshd restart
            ${sudoCommand} systemctl restart sshd
        fi

        if [ "$osRelease" == "ubuntu" ] || [ "$osRelease" == "debian" ] ; then
            ${sudoCommand} service ssh restart
            ${sudoCommand} systemctl restart ssh
        fi

        green "设置成功, 请记住设置的端口号 ${osSSHLoginPortInput}!"
        green "登陆服务器命令: ssh -p ${osSSHLoginPortInput} root@111.111.111.your ip !"
    else
        echo "输入的端口号错误! 范围: 22,1025~65534"
    fi
}

# 设置北京时区
function setLinuxDateZone(){

    tempCurrentDateZone=$(date +'%z')

    if [[ ${tempCurrentDateZone} == "+0800" ]]; then
        yellow "当前时区已经为北京时间  $tempCurrentDateZone | $(date -R) "
    else 
        green " =================================================="
        yellow "当前时区为: $tempCurrentDateZone | $(date -R) "
        yellow "是否设置时区为北京时间 +0800区, 以便cron定时重启脚本按照北京时间运行."
        green " =================================================="
        # read 默认值 https://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value

        read -p "是否设置为北京时间 +0800 时区? 请输入[Y/n]?" osTimezoneInput
        osTimezoneInput=${osTimezoneInput:-Y}

        if [[ $osTimezoneInput == [Yy] ]]; then
            if [[ -f /etc/localtime ]] && [[ -f /usr/share/zoneinfo/Asia/Shanghai ]];  then
                mv /etc/localtime /etc/localtime.bak
                cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

                yellow "设置成功! 当前时区已设置为 $(date -R)"
                green " =================================================="
            fi
        fi

    fi


    if [ "$osRelease" == "centos" ]; then   
        $osSystemPackage -y install ntpdate
        ntpdate -q 0.rhel.pool.ntp.org
        systemctl enable ntpd
        systemctl restart ntpd
    else
        $osSystemPackage install -y ntp
        systemctl enable ntp
        systemctl restart ntp
    fi
    
}




# 安装 BBR 加速网络软件
function installBBR(){
    wget -O tcp_old.sh -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp_old.sh && ./tcp_old.sh
}

function installBBR2(){
    
    if [[ -f ./tcp.sh ]];  then
        mv ./tcp.sh ./tcp_old.sh
    fi    
    wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}


function installSoftEditor(){

    if [ "$osRelease" == "ubuntu" ]; then
        
        ${sudoCmd} $osSystemPackage install software-properties-common -y
        ${sudoCmd} add-apt-repository ppa:nginx/stable -y
    fi

    $osSystemPackage update -y
    $osSystemPackage install -y curl wget git unzip zip tar nano
    $osSystemPackage install -y iputils-ping 


    if [ "$osRelease" == "centos" ]; then   
        
        $osSystemPackage install -y xz 
    else
        $osSystemPackage install -y vim-gui-common vim-runtime vim 
        $osSystemPackage install -y xz-utils
        
    fi



    # 安装 micro 编辑器
    if [[ ! -f "${HOME}/bin/micro" ]] ;  then
        mkdir -p ${HOME}/bin
        cd ${HOME}/bin
        curl https://getmic.ro | bash

        cp ${HOME}/bin/micro /usr/local/bin

        green " =================================================="
        yellow " micro 编辑器 安装成功!"
        green " =================================================="
    fi



    # 设置vim 中文乱码
    if [[ ! -d "${HOME}/.vimrc" ]] ;  then
        cat > "${HOME}/.vimrc" <<-EOF
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1
set enc=utf8
set fencs=utf8,gbk,gb2312,gb18030

syntax on
set number
colorscheme elflord
se mouse+=a

EOF
    fi
}



function installNodejs(){

    if [ "$osRelease" == "centos" ] ; then

        if [ "$osReleaseVersion" == "8" ]; then
            ${sudoCommand} dnf module list nodejs
            ${sudoCommand} dnf module enable nodejs:14
            ${sudoCommand} dnf install nodejs
        fi

        if [ "$osReleaseVersion" == "7" ]; then
            curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
            ${sudoCommand} yum install -y nodejs
        fi

    else 
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
        echo 'export NVM_DIR="$HOME/.nvm"' >> ${HOME}/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ${HOME}/.zshrc
        source ${HOME}/.zshrc

        command -v nvm
        nvm --version
        nvm ls-remote
        nvm install --lts

    fi

    green " Nodejs 版本:"
    node --version 
    green " NPM 版本:"
    npm --version  

    green " =================================================="
    yellow " 准备安装 PM2 进程守护程序"
    green " =================================================="
    npm install -g pm2 

    green " ================================================== "
    green "   Nodejs 与 PM2 安装成功 !"
    green " ================================================== "

}



configDockerPath="${HOME}/download"
configV2rayPoseidonPath="${HOME}"


function installDocker(){

    green " =================================================="
    yellow " 准备安装 Docker 与 Docker Compose"
    green " =================================================="

    mkdir -p ${configDockerPath}
    cd ${configDockerPath}

    curl -fsSL https://get.docker.com -o get-docker.sh  
    sh get-docker.sh

    ${sudoCommand} curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    ${sudoCommand} chmod a+x /usr/local/bin/docker-compose

    rm -f `which dc`
    ${sudoCommand} ln -s /usr/local/bin/docker-compose /usr/bin/dc
    ${sudoCommand} ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    systemctl start docker
    systemctl enable docker.service


    green " ================================================== "
    green "   Docker 与 Docker Compose 安装成功 !"
    green " ================================================== "
    docker-compose --version

    # systemctl status docker.service
}




function installV2rayPoseidon(){

    green " =================================================="
    yellow " 准备安装 V2rayPoseidon"
    green " =================================================="

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
    green " ================================================== "

    read configSSLDomain

    mkdir -p ${configV2rayPoseidonPath}
    cd ${configV2rayPoseidonPath}
    
    git clone https://github.com/ColetteContreras/v2ray-poseidon.git

    cd v2ray-poseidon

    green " ================================================== "
    green "   V2rayPoseidon 安装成功 请再次运行脚本编辑配置文件"
    green " ================================================== "
 	
}

function startV2rayPoseidonWS(){
    cd ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls
    docker-compose up -d      
}

function stopV2rayPoseidonWS(){
    cd ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls
    docker-compose stop   
}

function restartV2rayPoseidonWS(){
    cd ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls
    docker-compose restart 
}

function checkLogV2rayPoseidon(){
    cd ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls
    docker-compose logs
}

function deleteDockerLogs(){
     truncate -s 0 /var/lib/docker/containers/*/*-json.log
}

function editV2rayPoseidonWSconfig(){
    vi ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/config.json
}

function editV2rayPoseidonDockerComposeConfig(){
    vi ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml
}



function replaceV2rayPoseidonConfig(){

    if test -s ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml; then

        sed -i "s?#- ./v2ray.crt:/etc/v2ray/v2ray.crt?- ${configSSLCertPath}/fullchain.cer:/etc/v2ray/v2ray.crt?g" ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml
        sed -i "s?#- ./v2ray.key:/etc/v2ray/v2ray.key?- ${configSSLCertPath}/private.key:/etc/v2ray/v2ray.key?g" ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml
        
        sed -i 's/#- CERT_FILE=/- CERT_FILE=/g' ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml
        sed -i 's/#- KEY_FILE=/- KEY_FILE=/g' ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml

        sed -i "s/demo.oppapanel.xyz/${configSSLDomain}/g" ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml


        read -p "请输入节点ID (纯数字):" inputV2boardNodeId
        sed -i "s/1,/${inputV2boardNodeId},/g" ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/config.json

        read -p "请输入面板域名 例如www.123.com 不要带有http或https前缀 结尾不要带/ :" inputV2boardDomain
        sed -i "s?http or https://YOUR V2BOARD DOMAIN?https://${inputV2boardDomain}?g" ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/config.json

        read -p "请输入token 即通信密钥:" inputV2boardWebApiKey
        sed -i "s/v2board token/${inputV2boardWebApiKey}/g" ${configV2rayPoseidonPath}/v2ray-poseidon/docker/v2board/ws-tls/config.json

    fi

}


function installSoga(){

    green " =================================================="
    green "    准备安装 soga !"
    green " =================================================="

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
    green " ================================================== "

    read configSSLDomain

    mkdir -p ${configDockerPath}
    cd ${configDockerPath}

    wget -O soga_install.sh -N --no-check-certificate "https://raw.githubusercontent.com/sprov065/soga/master/install.sh" && chmod +x soga_install.sh && ./soga_install.sh

}

function editSogaConfig(){
    vi /etc/soga/soga.conf
}

function replaceSogaConfig(){

    if test -s /etc/soga/soga.conf; then

        sed -i 's/type=sspanel-uim/type=v2board/g' /etc/soga/soga.conf
        #sed -i "s?cert_file=?cert_file=${configSSLCertPath}/fullchain.cer?g" /etc/soga/soga.conf
        #sed -i "s?key_file=?key_file=${configSSLCertPath}/private.key?g" /etc/soga/soga.conf

        sed -i 's/cert_mode=/cert_mode=http/g' /etc/soga/soga.conf
        sed -i "s/cert_domain=/cert_domain=${configSSLDomain}/g" /etc/soga/soga.conf

        read -p "请输入面板域名 例如www.123.com 不要带有http或https前缀 结尾不要带/ :" inputV2boardDomain
        sed -i "s/www.domain.com/${inputV2boardDomain}/g" /etc/soga/soga.conf

        read -p "请输入webapi key 即通信密钥:" inputV2boardWebApiKey
        sed -i "s/webapi_mukey=/webapi_mukey=${inputV2boardWebApiKey}/g" /etc/soga/soga.conf

        read -p "请输入节点ID (纯数字):" inputV2boardNodeId
        sed -i "s/node_id=1/node_id=${inputV2boardNodeId}/g" /etc/soga/soga.conf
     
    fi
}


configNetworkRealIp=""
configNetworkLocalIp=""
configSSLDomain=""

configSSLCertPath="${HOME}/website/cert"
configWebsitePath="${HOME}/website/html"


function getHTTPSCertificate(){

    # 申请https证书
	mkdir -p ${configSSLCertPath}
	mkdir -p ${configWebsitePath}
	curl https://get.acme.sh | sh

    green "=========================================="

	if [[ $1 == "standalone" ]] ; then
	    green "  开始申请证书 acme.sh standalone mode !"
	    ~/.acme.sh/acme.sh  --issue  -d ${configSSLDomain}  --standalone

        ~/.acme.sh/acme.sh  --installcert  -d ${configSSLDomain}   \
        --key-file   ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer

	else
	    green "  开始申请证书 acme.sh nginx mode !"
        ~/.acme.sh/acme.sh  --issue  -d ${configSSLDomain}  --webroot ${configWebsitePath}/

        ~/.acme.sh/acme.sh  --installcert  -d ${configSSLDomain}   \
        --key-file   ${configSSLCertPath}/private.key \
        --fullchain-file ${configSSLCertPath}/fullchain.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
    fi

}


function compareRealIpWithLocalIp(){

    yellow " 是否检测域名指向的IP正确 (默认检测，如果域名指向的IP不是本机器IP则无法继续. 如果已开启CDN不方便关闭可以选择否)"
    read -p "是否检测域名指向的IP正确? 请输入[Y/n]?" isDomainValidInput
    isDomainValidInput=${isDomainValidInput:-Y}

    if [[ $isDomainValidInput == [Yy] ]]; then
        if [ -n $1 ]; then
            configNetworkRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
            # configNetworkLocalIp=`curl ipv4.icanhazip.com`
            configNetworkLocalIp=`curl v4.ident.me`

            green " ================================================== "
            green "     域名解析地址为 ${configNetworkRealIp}, 本VPS的IP为 ${configNetworkLocalIp}. "
            green " ================================================== "

            if [[ ${configNetworkRealIp} == ${configNetworkLocalIp} ]] ; then
                green " ================================================== "
                green "     域名解析的IP正常!"
                green " ================================================== "
                true
            else
                green " ================================================== "
                red "     域名解析地址与本VPS IP地址不一致!"
                red "     本次安装失败，请确保域名解析正常, 请检查域名和DNS是否生效!"
                green " ================================================== "
                false
            fi
        else
            green " ================================================== "        
            red "     域名输入错误!"
            green " ================================================== "        
            false
        fi
        
    else
        green " ================================================== "
        green "     不检测域名解析是否正确!"
        green " ================================================== "
        true
    fi
}




function getHTTPS(){

    testLinuxPortUsage

    green " ================================================== "
    yellow " 请输入绑定到本VPS的域名 例如www.xxx.com: (此步骤请关闭CDN后和nginx后安装 避免80端口占用导致申请证书失败)"
    green " ================================================== "

    read configSSLDomain

    read -p "是否申请证书? 默认为自动申请证书,如果二次安装或已有证书可以选否 请输入[Y/n]?" isDomainSSLRequestInput
    isDomainSSLRequestInput=${isDomainSSLRequestInput:-Y}

    if compareRealIpWithLocalIp "${configSSLDomain}" ; then
        if [[ $isDomainSSLRequestInput == [Yy] ]]; then

            getHTTPSCertificate "standalone"

            if test -s ${configSSLCertPath}/fullchain.cer; then
                green " =================================================="
                green "   域名SSL证书申请成功 !"
                green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/fullchain.cer "
                green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/private.key "
                green " =================================================="

            else
                red "==================================="
                red " https证书没有申请成功，安装失败!"
                red " 请检查域名和DNS是否生效, 同一域名请不要一天内多次申请!"
                red " 请检查80和443端口是否开启, VPS服务商可能需要添加额外防火墙规则，例如阿里云、谷歌云等!"
                red " 重启VPS, 重新执行脚本, 可重新选择修复证书选项再次申请证书 ! "
                red "==================================="
                exit
            fi

        else
            green " =================================================="
            green "   不申请域名的证书, 请把证书放到如下目录, 或自行修改trojan或v2ray配置!"
            green " ${configSSLDomain} 域名证书内容文件路径 ${configSSLCertPath}/fullchain.cer "
            green " ${configSSLDomain} 域名证书私钥文件路径 ${configSSLCertPath}/private.key "
            green " =================================================="
        fi
    else
        exit
    fi

}








function start_menu(){
    clear

    if [[ $1 == "first" ]] ; then
        getLinuxOSVersion
        ${osSystemPackage} -y install wget curl git 
    fi

    green " =================================================="
    green " Trojan Trojan-go V2ray 一键安装脚本 2020-12-6 更新.  系统支持：centos7+ / debian9+ / ubuntu16.04+"
    red " *请不要在任何生产环境使用此脚本 请不要有其他程序占用80和443端口"
    red " *若是已安装trojan 或第二次使用脚本，请先执行卸载trojan"
    green " =================================================="
    green " 1. 安装 老版本 BBR-PLUS 加速4合一脚本"
    green " 2. 安装 新版本 BBR-PLUS 加速6合一脚本"
    echo
    green " 3. 编辑 SSH 登录的用户公钥 用于SSH密码登录免登录"
    green " 4. 修改 SSH 登陆端口号"
    green " 5. 设置时区为北京时间"
    green " 6. 安装 Vim Nano Micro 编辑器"
    green " 7. 安装 Nodejs 与 PM2"
    green " 8. 安装 Docker 与 Docker Compose"
    echo
    green " 21. 安装 V2Ray-Poseidon 服务器端"
    green " 22. 编辑 V2Ray-Poseidon WS-TLS 模式配置文件 v2ray-poseidon/docker/v2board/ws-tls/config.json"
    green " 23. 编辑 V2Ray-Poseidon WS-TLS 模式Docker Compose文件 v2ray-poseidon/docker/v2board/ws-tls/docker-compose.yml"
    green " 24. 启动 V2Ray-Poseidon 服务器端"
    green " 25. 重启 V2Ray-Poseidon 服务器端"
    green " 26. 停止 V2Ray-Poseidon 服务器端"
    green " 27. 查看 V2Ray-Poseidon 服务器端 日志"
    green " 28. 清空 V2Ray-Poseidon Docker日志"
    red " 29. 卸载 V2Ray-Poseidon"
    echo
    green " 31. 安装 Soga 服务器端"
    green " 32. 编辑 Soga 配置文件 /etc/soga/soga.conf"
    echo
    green " 41. 单独申请域名SSL证书"
    green " 0. 退出脚本"
    echo
    read -p "请输入数字:" menuNumberInput
    case "$menuNumberInput" in
        1 )
            installBBR
        ;;
        2 )
            installBBR2
        ;;
        3 )
            editLinuxLoginWithPublicKey
        ;;
        4 )
            changeLinuxSSHPort
        ;;
        5 )
            setLinuxDateZone
        ;;
        6 )
            installSoftEditor
        ;;
        7 )
            installNodejs
        ;;
        8 )
            testLinuxPortUsage
            setLinuxDateZone
            installSoftEditor
            installDocker
        ;;
        9 )
            installPython3
        ;;
        10 )
            installPython3
            installPython3Rembg
        ;;
        21 )
            setLinuxDateZone
            installV2rayPoseidon
            getHTTPS
            replaceV2rayPoseidonConfig
        ;;
        22 )
            editV2rayPoseidonWSconfig
        ;;
        23 )
            editV2rayPoseidonDockerComposeConfig
        ;;
        24 )
            startV2rayPoseidonWS
        ;;
        25 )
            restartV2rayPoseidonWS
        ;;
        26 )
            stopV2rayPoseidonWS
        ;;
        27 )
            checkLogV2rayPoseidon
        ;;
        28 )
            deleteDockerLogs
        ;;           
        29 )
            checkLogV2rayPoseidon
        ;; 
        31 )
            setLinuxDateZone
            installSoga
            replaceSogaConfig
        ;;
        32 )
            editSogaConfig
        ;;                       
        41 )
            getHTTPS
            replaceV2rayPoseidonConfig
            replaceSogaConfig
        ;;               
        0 )
            exit 1
        ;;
        * )
            clear
            red "请输入正确数字 !"
            sleep 2s
            start_menu
        ;;
    esac
}



start_menu "first"

