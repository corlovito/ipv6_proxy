#!/bin/bash
echo "post-up /etc/network/ip_add" >> /etc/network/interfaces
#mkdir /usr/local/3proxy
touch /usr/local/3proxy/3proxy_$1.cfg
#cp /etc/3proxy/3proxy /usr/local/3proxy/3proxy
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
network=2a01:230:4:584 # your ipv6 network prefix
#apt-get update
#apt-get install curl net-tools -y

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


touch /etc/systemd/system/3proxy_$1.service
#touch ./3proxy_$1.service
PASS=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
DATA=$(date)
tee /etc/systemd/system/3proxy_$1.service << EOF
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local

[Service]
 Type=simple
 Restart=on-failure
 ExecStart=/usr/local/3proxy/3proxy /usr/local/3proxy/3proxy_$1.cfg
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes

[Install]
 WantedBy=multi-user.target
EOF
systemctl daemon-reload
##############
###generate file 3proxy
##############

echo > user.list
echo > ip.list
#echo > proxy_user.txt
#echo > /etc/network/ip_add
#echo > /etc/3proxy/3proxy.cfg
tee 3proxy_$1.cfg << EOF
monitor /usr/local/3proxy/$1.cfg
daemon
maxconn 500
nserver 8.8.8.8
nserver 8.8.4.4
nserver 1.1.1.1
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6000
EOF


array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
MAXCOUNT=500
count=1

rnd_ip_block ()
{
    a=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    b=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    c=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    d=${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}${array[$RANDOM%16]}
    
    CONFIG_NAME=10
    INT=14509
    INT2=24509
    PORT=$(($INT+$count))
    PORT2=$(($INT2+$count))
    USER=$(openssl rand -base64 32 | sha256sum | base64 | head -c 12 ; echo)
    PASS=$(openssl rand -base64 32 | sha256sum | base64 | head -c 12 ; echo)
    echo $network:$a:$b:$c:$d >> ip.list
    echo users $USER:CL:$PASS >> user.list
    echo $USER:$PASS:$ip_address:$PORT >> proxy_user.txt
    echo ip -6 addr add $network:$a:$b:$c:$d dev $interface >> /etc/network/ip_add
    echo auth strong >> 3proxy_$CONFIG_NAME.cfg
    echo allow $USER >> 3proxy_$CONFIG_NAME.cfg
    echo proxy -6 -s0 -n -a -p$PORT -i$ip_address -e$network:$a:$b:$c:$d >> 3proxy_$CONFIG_NAME.cfg
    echo socks -6 -s0 -n -a -p$PORT2 -i$ip_address -e$network:$a:$b:$c:$d >> 3proxy_$CONFIG_NAME.cfg
    echo flush >> 3proxy_$CONFIG_NAME.cfg
}

#echo "$MAXCOUNT случайных IPv6:"
#echo "-----------------"
while [ "$count" -le $MAXCOUNT ]        # Генерация 20 ($MAXCOUNT) случайных чисел.
do
        rnd_ip_block
        let "count += 1"                # Нарастить счетчик.
        done
#echo "-----------------"
cat user.list >> 3proxy_$1.cfg
chmod +x /etc/network/ip_add
/usr/sbin/sysctl -p
/usr/bin/systemctl disable 3proxy
