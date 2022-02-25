cd ~
apt-get update
apt-get install -y build-essential
wget https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz
tar xzf 0.9.3.tar.gz
cd ~/3proxy-0.9.3
make -f Makefile.Linux
mkdir /etc/3proxy
mkdir /usr/local/3proxy
cd ~/3proxy-0.9.3/bin
cp 3proxy /usr/bin/
cp 3proxy /usr/local/3proxy
