#!/bin/bash
apt-get update
apt-get install build-essential curl net-tools -y
cd ~
apt-get install -y build-essential net-tools
wget https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz
tar xzf 0.9.3.tar.gz
cd ~/3proxy-0.9.3
make -f Makefile.Linux
mkdir /etc/3proxy
mkdir /usr/local/3proxy
cd ~/3proxy-0.9.3/bin
cp 3proxy /usr/bin/
cp 3proxy /usr/local/3proxy

PASS=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
DATA=$(date)

echo "post-up /etc/network/ip_add" >> /etc/network/interfaces

ext_interface () {
    for interface in /sys/class/net/*
    do
        [[ "${interface##*/}" != 'lo' ]] && \
            ping -c1 -W2 -I "${interface##*/}" 8.8.8.8 >/dev/null 2>&1 && \
                printf '%s' "${interface##*/}" && return 0
    done
}

interface=$(ext_interface)
ip_address=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

 echo  "
DefaultLimitDATA=infinity
DefaultLimitSTACK=infinity
DefaultLimitCORE=infinity
DefaultLimitRSS=infinity
DefaultLimitNOFILE=102400
DefaultLimitAS=infinity
DefaultLimitNPROC=102400
DefaultLimitMEMLOCK=infinity
" >> /etc/systemd/system.conf
 echo  "
* soft nofile 100000
* hard nofile 100000
root - nofile 100000
# End of file
" >>  /etc/security/limits.conf

touch /etc/rc.local
chmod +x /etc/rc.local
touch /etc/systemd/system/rc-local.service

tee  /etc/systemd/system/rc-local.service << EOF
[Unit]
 Description=/etc/rc.local Compatibility
  ConditionPathExists=/etc/rc.local

  [Service]
   Type=forking
    ExecStart=/etc/rc.local start
     TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes

[Install]
 WantedBy=multi-user.target
EOF

tee  /etc/rc.local << EOF
#!/bin/bash
ifconfig $interface txqueuelen 10000
exit 0
EOF

systemctl enable rc-local
systemctl start rc-local
tee  /etc/sysctl.conf << EOF

vm.max_map_count=1031062
kernel.pid_max=103102
kernel.threads-max=200000
fs.file-max=1000000
net.core.netdev_max_backlog=10000
net.core.somaxconn=600000
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_max_tw_buckets = 720000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_probes = 7
net.ipv4.tcp_keepalive_intvl = 30
net.core.wmem_max = 33554432
net.core.rmem_max = 33554432
net.core.rmem_default = 8388608
net.core.wmem_default = 4194394
net.ipv4.tcp_rmem = 4096 8388608 16777216
net.ipv4.tcp_wmem = 4096 4194394 16777216
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.icmp_echo_ignore_all=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0
EOF


##############
###generate file 3proxy
##############

echo > user.list
echo > ip.list
echo > proxy_user.txt
echo > /etc/network/ip_add


array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
MAXCOUNT=500
count=1
for ((i=1, y=1, MAXCOUNT=500, INT=10000, INT2=20000; i < 11; i++, INT+=500, INT2+=500))
do
x=1
tee 3proxy_$i.cfg << EOF
monitor /usr/local/3proxy/3proxy_$i.cfg
daemon
maxconn 500
nserver 8.8.8.8
nserver 8.8.4.4
nserver 1.1.1.1
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 60000
EOF

touch /etc/systemd/system/3proxy_$i.service
PASS=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
DATA=$(date)
tee /etc/systemd/system/3proxy_$i.service << EOF
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local

[Service]
 Type=simple
 Restart=on-failure
 ExecStart=/usr/local/3proxy/3proxy /usr/local/3proxy/3proxy_$i.cfg
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes

[Install]
 WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable 3proxy_$i

while  [ "$x" -lt 550 ]
do
    a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}

    CONFIG_NAME=$i
    #INT=10000
    #INT2=20000
    PORT=$(($INT+$x))
    PORT2=$(($INT2+$x))
    USER=$(openssl rand -base64 32 | sha256sum | base64 | head -c 12 ; echo)
    PASS=$(openssl rand -base64 32 | sha256sum | base64 | head -c 12 ; echo)
    echo $network:$a:$b:$c:$d >> ip.list
    echo users $USER:CL:$PASS >> user.list
    echo $ip_address:$PORT:$USER:$PASS >> proxy_user.txt
    echo ip -6 addr add $1:$a:$b:$c:$d dev $interface >> /etc/network/ip_add
    echo auth strong >> 3proxy_$i.cfg
    echo allow $USER >> 3proxy_$i.cfg
    echo proxy -6 -s0 -n -a -p$PORT -i$ip_address -e$1:$a:$b:$c:$d >> 3proxy_$i.cfg
    echo socks -6 -s0 -n -a -p$PORT2 -i$ip_address -e$1:$a:$b:$c:$d >> 3proxy_$i.cfg
    echo flush >> 3proxy_$i.cfg
    let "x += 1"
done
done
chmod +x /etc/network/ip_add
chmod +x /etc/rc.local
/usr/sbin/sysctl -p

for ((i=1; i <11; i++))
do
    cat ./user.list >> 3proxy_$i.cfg
done
