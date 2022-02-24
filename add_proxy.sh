#!/bin/bash
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
 ExecStart=/usr/local/3proxy/3proxy /usr/local/3proxy/$1.cfg
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
 SysVStartPriority=99

[Install]
 WantedBy=multi-user.target
EOF
systemctl daemon-reload

tee  /usr/local/3proxy/$1.cfg << EOF
### cfgig for modem $1. filename $1.cfg
monitor /usr/local/3proxy/$1.cfg

daemon
nserver 192.168.20.1
timeouts 1 5 30 60 180 1800 15 60
maxconn 5000
nscache 65535
log /dev/null

auth strong
users $1:CL:$PASS
deny * * $/usr/local/3proxy/acl/deny.txt * * * *
allow *
proxy -n -a -p$2 -i$3 -e$4
flush
EOF

echo $3:$2:$1:$PASS $DATA >> /usr/local/3proxy/pass.csv
