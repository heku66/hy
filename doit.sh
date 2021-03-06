#!/bin/sh
export LANG=en_US.UTF-8

mkdir -p /etc/hysteria
echo -e "\033[1;;35m\n正在查找下载匹配的安装包...\n\033[0m"
opsys() {
  if [[ "$(uname)" == 'Linux' ]]; then
    case "$(uname -m)" in
      'i386' | 'i686')
        MACHINE='386'
        ;;
      'amd64' | 'x86_64')
        MACHINE='amd64'
        ;;
      's390x')
        MACHINE='s390x'
        ;;
      'armv5tel' | 'armv6l' | 'armv7' | 'armv7l')
        MACHINE='arm'
        ;;
      'armv8' | 'aarch64')
        MACHINE='arm64'
        ;;
      'mips' | 'mipsle' | 'mips64' | 'mips64le')
        MACHINE='mipsle'
        ;;
      *)
        echo "错误：此架构不支持！"
        exit 1
        ;;
    esac
    if [[ ! -f '/etc/os-release' ]]; then
      echo "错误：系统版本太旧！"
      exit 1
    fi
  else
    echo "错误：此操作平台不支持！"
    exit 1
  fi
}


version=`wget -qO- -t1 -T2 --no-check-certificate "https://api.github.com/repos/HyNetwork/hysteria/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'`

opsys

wget -O /etc/hysteria/hysteria --no-check-certificate https://github.com/HyNetwork/hysteria/releases/download/$version/hysteria-linux-$MACHINE

chmod 755 /etc/hysteria/hysteria
cd /etc/hysteria
ip=`curl -4 -s ip.sb`
openssl ecparam -genkey -name prime256v1 -out ca.key
openssl req -new -x509 -days 36500 -key ca.key -out ca.crt  -subj "/CN=bing.com"
echo
echo -e "\033[1;;31m\n警告：使用跳跳工具会有封号的风险！请慎用！\n\033[0m"
echo
read -p "自定义UDP端口[6888]:" redPort
if [ -z $redPort ]; then
  redPort=6888
fi
echo
read -p "自定义混淆密码[g6813]:" redPass
if [ -z $redPass ]; then
  redPass="g6813"
fi
cat <<EOF > ./config.json
{
  "listen": ":$redPort",
  "cert": "/etc/hysteria/ca.crt",
  "key": "/etc/hysteria/ca.key",
  "obfs": "$redPass"
}
EOF
cd /root
cat <<EOF > config.json
{
  "server": "$ip:$redPort",
  "obfs": "$redPass",
  "up_mbps": 20,
  "down_mbps": 100,
  "insecure": true,
  "socks5": {
    "listen": "127.0.0.1:10808"
  },
  "http": {
    "listen": "127.0.0.1:10809"
  }
}
EOF

ufw disable
iptables -F
cat <<EOF >/etc/systemd/system/hysteria.service
[Unit]
Description=hysteria:Hello World!
After=network.target
[Service]
Type=simple
PIDFile=/run/hysteria.pid
ExecStart=/etc/hysteria/hysteria --log-level warn -c /etc/hysteria/config.json server
#Restart=on-failure
#RestartSec=10s
[Install]
WantedBy=multi-user.target
EOF
chmod 644 /etc/systemd/system/hysteria.service
echo -e "\033[1;;35m\n正在启动服务...\n\033[0m"
systemctl daemon-reload
systemctl enable hysteria
systemctl start hysteria
sleep 3
status=`systemctl is-active hysteria`
if [ "${status}" = "active" ];then
  crontab -l > ./crontab.tmp
  echo  "0 4 * * * systemctl restart hysteria" >> ./crontab.tmp
  crontab ./crontab.tmp
  rm -rf ./crontab.tmp
  echo -e "\033[1;;35m\n服务已正常启动...[hysteria]\n\033[0m"
  echo -e "\033[35m↓***********************************↓↓↓以下为客户端配置文件↓↓↓*******************************↓\033[0m"
  cat ./config.json
  echo -e "\033[35m↑*************************************↑↑↑可复制使用↑↑↑*********************************↑\033[0m"
  echo
  echo -e "\033[1;;31m\n客户端配置相关参考：https://github.com/emptysuns/Hi_Hysteria/blob/main/md/v2n.md\n\033[0m"
else
  echo -e "\033[1;;31m\n服务启动异常，请检查相关日志...\n\033[0m"
  exit 1
fi
