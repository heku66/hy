#!/bin/sh
export LANG=en_US.UTF-8

mkdir -p /etc/hysteria
version=`wget -qO- -t1 -T2 --no-check-certificate "https://api.github.com/repos/HyNetwork/hysteria/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'`

wget -q -O /etc/hysteria/hysteria --no-check-certificate https://github.com/HyNetwork/hysteria/releases/download/$version/hysteria-linux-amd64

chmod 755 /etc/hysteria/hysteria
ip=`curl -4 -s ip.sb`
openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/hysteria/ca.key
openssl req -new -x509 -days 36500 -key ca.key -out /etc/hysteria/hysteria/ca.crt  -subj "/CN=bing.com"

cat <<EOF > /etc/hysteria/config.json
{
  "listen": ":6888",
  "cert": "/etc/hysteria/ca.crt",
  "key": "/etc/hysteria/ca.key",
  "obfs": "g6813"
}
EOF

cat <<EOF > config.json
{
  "server": "$ip:6888",
  "obfs": "g6813",
  "up_mbps": 20,
  "down_mbps": 100,
  "insecure": true,
  "socks5": {
    "listen": "127.0.0.1:1080"
  },
  "http": {
    "listen": "127.0.0.1:1081"
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
systemctl daemon-reload
systemctl enable hysteria
systemctl start hysteria
echo -e "\033[1;;35m\nwait...\n\033[0m"
sleep 3
status=`systemctl is-active hysteria`
if [ "${status}" = "active" ];then
crontab -l > ./crontab.tmp
echo  "0 4 * * * systemctl restart hysteria" >> ./crontab.tmp
crontab ./crontab.tmp
rm -rf ./crontab.tmp

echo -e "\033[35m↓***********************************↓↓↓copy↓↓↓*******************************↓\033[0m"
cat ./config.json
echo -e "\033[35m↑***********************************↑↑↑copy↑↑↑*******************************↑\033[0m"
