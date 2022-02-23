cd ~
wget https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz
tar xzf 0.9.3.tar.gz
cd ~/3proxy-0.9.3
sudo make -f Makefile.Linux
mkdir /etc/3proxy
cd ~/3proxy-0.9.3/bin
cp 3proxy /usr/bin/
