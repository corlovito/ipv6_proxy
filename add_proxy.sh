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

[Install]
 WantedBy=multi-user.target
EOF
systemctl daemon-reload

tee  /usr/local/3proxy/$1.cfg << EOF
### cfgig for modem $1. filename $1.cfg
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


