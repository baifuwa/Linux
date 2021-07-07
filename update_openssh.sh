# 基于CentOS 7进行操作。
# 下载安装包

mkdir -p /opt/openssh && cd /opt/openssh
wget https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.6p1.tar.gz
# 下载openssl
wget https://www.openssl.org/source/openssl-1.1.1k.tar.gz
# 安装依赖服务
yum install -y gcc zlib-devel openssl-devel pam-devel  systemd-devel perl

# 升级openssl 到1.1.1k
tar xzvf openssl-1.1.1k.tar.gz && cd openssl-1.1.1k && cd openssl-1.1.1k
# 备份原来的openssl
mv /usr/bin/openssl /usr/bin/openssl_bak
mv /usr/include/openssl /usr/include/openssl_bak
# 编译安装openssl
./config --prefix=/usr/local/openssl  --shared
make && make install
ln -s /usr/local/openssl/bin/openssl  /usr/bin/openssl
ln -s /usr/local/openssl/include/openssl  /usr/include/openssl
# 添加动态库
echo "/usr/local/openssl/lib" >> /etc/ld.so.conf
ldconfig
#备份 ssh

mkdir /etc/sshold
mv /etc/ssh/* /etc/sshold
# 安装openssh

tar xzvf openssh-8.6p1.tar.gz  && cd openssh-8.6p1
# 修改sshd.c这个主函数文件，找到调用server_accept_loop这个函数的行，注意这个函数的定义也在这个文件，不要找错了，不然安装后sshd会一直重启（大概在2058行）

/* Signal systemd that we are ready to accept connections */
sd_notify(0, "READY=1");
# 下面为已有内容
/* Accept a connection and return in a forked child */
server_accept_loop(&sock_in, &sock_out,&newsock, config_s);
# 文件中添加引用 （大概在44行）

#include <systemd/sd-daemon.h>
# 编译 openssh

./configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam  --with-md5-passwords --mandir=/usr/share/man --with-ssl-dir=/usr/local/openssl 

# 修改Makefile，编译时还需要在makefile中指明，编辑文件：Makefile ，找到变量 LIBS，修改如下(50行)

LIBS=-lcrypto -ldl -lutil -lz -lcrypt -lresolv -lsystemd
# 安装 openssh

make 
make install
# 修改sshd_config配置文件，在文件末尾添加：

cat >> /etc/ssh/sshd_config<<EOF
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PubkeyAuthentication yes
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes

UsePAM yes
EOF
# 重启openssh 
systemctl restart opensshd
