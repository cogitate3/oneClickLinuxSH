#!/bin/bash # 这是一个shebang行，它用来指定这个脚本的解释器，也就是Bash。
blue(){ # 定义一个函数，名字叫做blue，有一个参数，叫做$1，这个参数是一个字符串。
 echo -e "\033[34m\033[01m$1\033[0m" # 执行一个echo命令，它用来输出一个字符串，-e选项表示支持转义字符，\033是一个转义符，表示开始一个颜色控制序列，[34m表示设置前景色为蓝色，[01m表示设置字体为粗体，$1表示输出参数的值，\033[0m表示恢复默认的颜色和字体。这个函数的作用是输出一个蓝色的粗体的字符串。
}
green(){ # 定义一个函数，名字叫做green，有一个参数，叫做$1，这个参数是一个字符串。这个函数的原理和blue()函数一样，只是颜色不同，这里是绿色，也就是[32m。
 echo -e "\033[32m\033[01m$1\033[0m" # 这行代码和上面的blue()函数的第二行代码一样，只是颜色不同，这里是绿色，也就是[32m。
}
red(){ # 定义一个函数，名字叫做red，有一个参数，叫做$1，这个参数是一个字符串。这个函数的原理和blue()函数一样，只是颜色不同，这里是红色，也就是[31m。
 echo -e "\033[31m\033[01m$1\033[0m" # 这行代码和上面的blue()函数的第二行代码一样，只是颜色不同，这里是红色，也就是[31m。
}

if [[ -f /etc/redhat-release ]]; then # 开始一个if语句，if语句用来根据一个条件执行一段代码，如果条件为真，就执行then后面的代码，否则就执行else或者elif后面的代码。这里的条件是[[ -f /etc/redhat-release ]]，这是一个双中括号表达式，它用来进行高级的条件判断，-f选项表示检查一个文件是否存在，/etc/redhat-release是一个文件，它用来存储RedHat系列的操作系统的版本信息，如果这个文件存在，就表示当前的操作系统是RedHat系列的，比如CentOS、Fedora等。
    release="centos" # 执行一个赋值语句，它用来给一个变量赋一个值，这里的变量是release，它用来表示操作系统的类型，这里的值是"centos"，表示操作系统是CentOS。
    systemPackage="yum" # 执行另一个赋值语句，它用来给一个变量赋一个值，这里的变量是systemPackage，它用来表示操作系统的包管理器，这里的值是"yum"，表示操作系统使用yum来安装和管理软件包。
    systempwd="/usr/lib/systemd/system/" # 执行另一个赋值语句，它用来给一个变量赋一个值，这里的变量是systempwd，它用来表示操作系统的服务管理器的配置文件的路径，这里的值是"/usr/lib/systemd/system/"，表示操作系统使用systemd来管理服务，它的配置文件存放在这个路径下。
elif cat /etc/issue | grep -Eqi "debian"; then # 开始一个elif语句，elif语句用来在if语句的条件为假的情况下，再判断另一个条件，如果这个条件为真，就执行then后面的代码，否则就执行else或者elif后面的代码。这里的条件是cat /etc/issue | grep -Eqi "debian"，这是一个管道命令，它用来把一个命令的输出作为另一个命令的输入，cat命令用来输出一个文件的内容，/etc/issue是一个文件，它用来存储操作系统的发行版信息，grep命令用来搜索一个字符串，-E选项表示使用扩展的正则表达式，-q选项表示静默模式，不输出任何内容，只返回一个状态码，-i选项表示忽略大小写，"debian"是一个字符串，表示要搜索的内容，如果这个命令返回0，就表示在文件中找到了"debian"，就表示当前的操作系统是Debian。
    release="debian" # 执行一个赋值语句，它用来给一个变量赋一个值，这里的变量是release，它用来表示操作系统的类型，这里的值是"debian"，表示操作系统是Debian。
    systemPackage="apt-get" # 执行另一个赋值语句，它用来给一个变量赋一个值，这里的变量是systemPackage，它用来表示操作系统的包管理器，这里的值是"apt-get"，表示操作系统使用apt-get来安装和管理软件包。
    systempwd="/lib/systemd/system/" # 执行另一个赋值语句，它用来给一个变量赋一个值，这里的变量是systempwd，它用来表示操作系统的服务管理器的配置文件的路径，这里的值是"/lib/systemd/system/"，表示操作系统使用systemd来管理服务，它的配置文件存放在这个路径下。
elif cat /etc/issue | grep -Eqi "ubuntu"; then # 开始另一个elif语句，这里的条件是cat /etc/issue | grep -Eqi "ubuntu"，这是一个管道命令，它用来把一个命令的输出作为另一个命令的输入，cat命令用来输出一个文件的内容，/etc/issue是一个文件，它用来存储操作系统的发行版信息，grep命令用来搜索一个字符串，-E选项表示使用扩展的正则表达式，-q选项表示静默模式，不输出任何内容，只返回一个状态码，-i选项表示忽略大小写，"ubuntu"是一个字符串，表示要搜索的内容，如果这个命令返回0，就表示在文件中找到了"ubuntu"，就表示当前的操作系统是Ubuntu。
    release="ubuntu" # 执行一个赋值语句，它用来给一个变量赋一个值，这里的变量是release，它用来表示操作系统的类型，这里的值是"ubuntu"，表示操作系统是Ubuntu。
    systemPackage="apt-get" # 执行另一个赋值语句，它用来给一个变量赋一个值，这里的变量是systemPackage，它用来表示操作系统的包管理器，这里的值是"apt-get"，表示操作系统使用apt-get来安装和管理软件包。
    systempwd="/lib/systemd/system/" # 执行另一个赋值语句，它用来给一个变量赋一个值，这里的变量是systempwd，它用来表示操作系统的服务管理器的配置文件的路径，这里的值是"/lib/systemd/system/"，表示操作系统使用systemd来管理服务，它的配置文件存放在这个路径下。
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
fi

clear
green "=========================================================="
 blue "支持：centos7+/debian9+/ubuntu16.04+"
 blue "网站：www.v2rayssr.com （已开启禁止国内访问）"
 blue "YouTube频道：波仔分享"
 blue "本脚本禁止在国内网站转载"
green "=========================================================="
  red "简介：本脚本为Trojan分解安装第一部分（安装依赖环境和服务）"
green "=========================================================="
read -s -n1 -p "若同意上述协议，请按任意键继续 ... "
green " "
if cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
yum install epel-release
fi
$systemPackage update
$systemPackage -y install sudo nginx wget unzip zip curl tar
systemctl enable nginx
systemctl stop nginx
	green "======================="
	blue "请输入绑定到本VPS的域名"
	green "======================="
	read your_domain
	real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
	local_addr=`curl ipv4.icanhazip.com`
	green " "
	green " "
	green "==================================="
	 blue "检测到域名解析地址为 $real_addr"
	 blue "本VPS的IP为 $local_addr"
	green "==================================="
	sleep 3s
if [ $real_addr == $local_addr ] ; then
	green " "
	green " "
	green "=========================================="
	blue "        开始安装Nginx并配置"
	green "=========================================="
	sleep 3s
cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    server {
        listen       80;
        server_name  $your_domain;
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    }
}
EOF
	green " "
	green " "
	green "=========================================="
	blue "      开始下载伪装站点源码并部署"
	green "=========================================="
	sleep 3s
	rm -rf /usr/share/nginx/html/*
	cd /usr/share/nginx/html/
	wget https://github.com/V2RaySSR/Trojan/raw/master/web.zip
	unzip web.zip
	systemctl restart nginx
	green "=========================================="
	blue "      开始下载安装官方Trojan最新版本"
	green "=========================================="
	sleep 3s
	sudo bash -c "$(wget -O- https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
	systemctl enable trojan
	green "========================================================"
	blue "本次脚本安装完成，现在进行检测"
	green "========================================================"
	read -s -n1 -p "现在开始检测安装情况，请按任意键继续 ... "
	green " "
if test -s /etc/nginx/nginx.conf; then
	green " "
	green " "
	green "==========================="
	 blue "      Nginx安装正常"
	green "==========================="
	sleep 3s
else
	green " "
	green " "
	green "==========================="
	  red "      Nginx安装不成功"
	green "==========================="
	sleep 3s
fi
if test -s /usr/local/etc/trojan/config.json; then
	green " "
	green " "
	green "==========================="
	 blue "      Trojan安装正常"
	green "==========================="
	sleep 3s
else
	green " "
	green " "
	green "==========================="
	  red "     Trojan安装不成功"
	green "==========================="
	sleep 3s
fi
	green " "
	green " "
	green "========================================================"
	 blue " 本过程安装了sudo/nginx/wget/unzip/zip/curl/tar/trojan"
	 blue " 现在你访问 http://$your_domain 应该有伪装站点的存在了"
	 blue " 伪装站点目录在 /usr/share/nginx/html 可自行更换网站"
	 blue " Trojan配置文件在 /usr/local/etc/trojan"
	 blue " 检测没有问题之后可以进行下一部分安装"
	green "========================================================"
else
	green " "
	green " "
	red "================================"
	red "域名解析地址与本VPS IP地址不一致"
	red "本次安装失败，请确保域名解析正常"
	red "================================"
fi
