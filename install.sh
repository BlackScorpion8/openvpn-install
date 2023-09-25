#!/bin/bash

# 更新系统
sudo apt-get update

# 安装 Danted 服务
sudo apt-get install dante-server -y

# 安装 dos2unix 工具
sudo apt-get install dos2unix -y

# 安装 iptables 和 iptables-persistent
sudo apt-get install iptables iptables-persistent -y

# 配置 Danted
echo "logoutput: syslog
user.privileged: root
user.unprivileged: nobody
internal: 0.0.0.0 port=50088
external: eth0
socksmethod: username
clientmethod: none
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
}" | sudo tee /etc/danted.conf

# 转换脚本文件换行符
dos2unix /etc/danted.conf

# 创建用户并设置密码
echo "Created Users:" > users_credentials.txt
for user in user1 user2 user3; do
    sudo useradd -r -s /bin/false $user
    # 生成随机密码
    password=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 12 | xargs)
    echo -e "$password\n$password" | sudo passwd $user
    echo "Username: $user, Password: $password" >> users_credentials.txt
done

# 启动 Danted 服务
sudo systemctl restart danted
sudo systemctl enable danted

# 配置 iptables 放行端口
sudo iptables -A INPUT -p tcp --dport 50088 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 50088 -j ACCEPT

# 保存 iptables 规则
sudo sh -c 'iptables-save > /etc/iptables/rules.v4'

# 设置 iptables 规则在重启后仍然生效
sudo systemctl enable netfilter-persistent

# 显示服务状态
sudo systemctl status danted

# 输出创建的用户名和密码
cat users_credentials.txt
