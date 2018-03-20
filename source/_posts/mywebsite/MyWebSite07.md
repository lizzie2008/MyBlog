---
title: .NET Core 搭建个人网站 | (7) Linux系统移植
tags:
  - .NET Core
  - Entity Framework
  - Linux/Unix
categories: 软件工程
date: 2018-01-07
---
![avatar](https://bj.bcebos.com/v1/mysite/images/articles/9c93ff41-2251-428d-9a13-d553c20b6d65.jpg)

### 摘要
考虑我们为什么要选择.NET Core？
因为它面向的是高性能服务器开发，抛却了 AspNet 的臃肿组件，非常轻量，加上微软的跨平台战略，对 Docker 的亲和性，对于开发人员也非常友好，所以整体环境来说是健康发展的，未来技术决策时 .Net Core 也有很大的优势。那既然.NET Core 本身具有跨平台 (Windows、Mac OSX、Linux) 特性，而之前我们的网站一直是部署在 Windows Server 服务器上，这个章节我们不妨学习在生产环境下，怎么将我们的网站应用程序切换部署在Linux系统上。
<!-- more -->

#### 环境说明
- CentOS / 7.1 (64bit) （Linux操作系统）
- MySQL5.7（网站应用数据库）
- .NET Core SDK 2.0.0（网站应用环境）
- Nginx（反向代理服务器）
- Supervisor（管理网站应用守护进程）
- Symantec SSL（域名型证书，提供https协议服务）

这里数据库由SQL Server改为MySQL，因为SQL Server 2017对运行环境要求的配置比较高，我这1G内存的低端云服务器伤不起，o(╥﹏╥)o

#### 工具介绍
- Xshell 5（终端模拟软件）
- WinSCP（图形化SFTP客户端）

### 安装 CentOS
首先将云服务器，重新安装操作系统，选择CentOS / 7.1 x86_64 (64bit)版本的镜像，并设置访问用户名和密码，系统会帮我们自动安装好CentOS系统。接下来我们配置一下Xshell和WinSCP，使得这2个工具能正常访问并管理操作系统，相关的配置和使用方法，请大家自行百度。
完成上述操作后，首先查看一下硬盘情况：
```
fdisk -l
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/e49d7a32-fcab-4c16-a0ed-540ec46505c7.png)
发现我们的第二块磁盘云磁盘(/dev/vdb)并没有被加载。
在挂载之前，首先要格式化这块硬盘。我们选择的是ext4格式：
```
mkfs.ext4 /dev/vdb
```
硬盘格式化后，创建一个挂载目标目录，并将磁盘挂载该目录上：
```
mkdir /data
mount /dev/vdb /data
```
这时候，我们再查看下系统磁盘情况：
```
df -h
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/4679e780-9e7a-4b01-b2f2-9b42552b73b2.png)
可以看到，云磁盘可以正常的被挂载了。但是如果重启系统的话，磁盘仍旧会丢失，我们还必须在每次启动的时候将磁盘挂载。
修改/etc/fstab文件，需要在该文件的最后添加一行，具体如下：
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/fcc47447-b411-440f-9e75-d5f889ba965a.png)
至此，我们重启系统，发现磁盘可以正常挂载使用了。

### 安装 .NET Core
参考官方文档：<a href="https://docs.microsoft.com/en-us/dotnet/core/linux-prerequisites?tabs=netcore2x" target="_blank">Prerequisites for .NET Core on Linux</a>
第1步，注册Microsoft签名密钥，然后添加Microsoft产品Feed：
```
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[packages-microsoft-com-prod]\nname=packages-microsoft-com-prod \nbaseurl=https://packages.microsoft.com/yumrepos/microsoft-rhel7.3-prod\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/dotnetdev.repo'
```
第2步，更新可用于安装的产品列表，安装.NET Core所需的组件，然后安装.NET Core SDK：
```
sudo yum update
sudo yum install libunwind libicu
sudo yum install dotnet-sdk-2.0.0
```
第3步，设置环境变量：
```
export PATH=$PATH:$HOME/dotnet
```
以上，.NET Core环境已配置完成，可以新建一个项目HelloWorld，执行命令：dotnet run，正常运行，并使用localhost:5000正常访问，这里就不再多述。

### 安装 MySQL
第1步，下载MySQL Yum仓库的RPM安装包：
在MySQL官网中下载YUM源rpm安装包：<a href="http://dev.mysql.com/downloads/repo/yum/ " target="_blank">http://dev.mysql.com/downloads/repo/yum/</a>
第2步，安装MySQL RPM安装包：
```
yum localinstall mysql57-community-release-el7-11.noarch.rpm
```
第3步，安装MySQL服务器：
```
yum install mysql-community-server
```
安装完毕后，我们启动MySQL，并查看运行状态，并设置开机启动：
```
service mysqld start
service mysqld status
systemctl enable mysqld
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/5efce521-9f8f-49a3-bc1b-c10c0ebe21bd.png)
mysql安装完成之后，在/var/log/mysqld.log文件中给root生成了一个默认密码。通过下面的方式找到root默认密码：
```
grep 'temporary password' /var/log/mysqld.log
```
我们获取了默认密码，就可以进行一些安全设置，输入命令：
```
mysql_secure_installation
```
最后设置远程访问权限：
```
mysql -u root -p mysql
mysql> grant all privileges on *.* to 'root'@'%' identified by 'password' with grant option;
```
默认情况，MySQL的字符集为lanti，考虑我们使用中文的习惯，修改mysql配置文件/etc/my.cnf，增加如下一行，把默认的字符集改成utf8：
```
[mysqld] 
character-set-server=utf8
```

### 程序移植
因为.NET Core本身就是支持跨平台，所以程序逻辑不用进行任何调整，但是我们已将数据库切换成MySQL，所以针对这块，稍微调整下。
首先，将appsettings.json中的数据库连接字符串修改为新的连接；
然后，Startup.cs文件启动配置修改如下：
```csharp
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseMySQL(Configuration.GetConnectionString("DefaultConnection")));
```
重新编译发布到目录：/data/wwwroot/MyWebSite
进入该目录，执行：
```
dotnet MyWebSite.dll
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/ffadaab9-1b22-4b0b-9807-c42f28d19323.png)
现在我们的项目就正常的部署并运行在localhost:5000上了。

### 安装 Nginx
Nginx是一个高性能的HTTP和反向代理服务器，在CentOS中很容易安装和配置，接下来进行如下操作：
```
yum install nginx
```
安装完成后，我们启动Nginx，并将它设置为开机启动：
```
service nginx start
systemctl enable nginx.service
```
要使得Nginx代理外网80端口，访问我们内部5000端口监听的网站程序，需要修改Nginx配置文件/etc/nginx/nginx.conf：
```
location / {
  proxy_pass http://localhost:5000;
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection keep-alive;
  proxy_set_header Host $host;
  proxy_cache_bypass $http_upgrade;
}
```
最后，我们重新启动restart nginx.service，并通过外网链接，发现可以正常访问我们的网站了。

### 安装 Supervisor
其实，经过以上的步骤，已经完成基本的移植和部署，网站访问也没有问题了。但是，.NET Core应用程序运行在shell之中，如果shell关闭，.NET Core应用程序也随之关闭，导致应用无法访问。而且.NET Core进程意外终止或者服务器宕机或重启，都会导致服务不可用，这是我们不想看到的。
为了解决这个问题，我们需要有一个守护进程来监听ASP.NET Core 应用程序的状况，在应用程序停止运行的时候立即重新启动。
这里利用Supervisor工具帮我们创建这样的守护进程，先安装：
```
easy_install supervisor
```
安装完毕后，如下操作
```
mkdir /etc/supervisor
echo_supervisord_conf > /etc/supervisor/supervisord.conf
```
修改supervisord.conf文件，将文件尾部的配置修改：
```
[include]
files = conf.d/*.conf
```
再创建一个/etc/supervisor/conf.d/ MyWebSite.conf文件，内容大致如下：
```
[program:MyWebSite]
command=dotnet .dll ; 运行程序的命令
directory=/data/wwwroot/MyWebSite/ ; 命令执行的目录
autorestart=true ; 程序意外退出是否自动重启
stderr_logfile=/var/log/MyWebSite.err.log ; 错误日志文件
stdout_logfile=/var/log/MyWebSite.out.log ; 输出日志文件
environment=ASPNETCORE_ENVIRONMENT=Production ; 进程环境变量
user=root ; 进程执行的用户身份
stopsignal=INT
```
运行supervisord，查看是否生效：
```
supervisord -c /etc/supervisor/supervisord.conf
ps -ef | grep MyWebSite
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/c5521dfb-85a6-4553-b8cd-10b5f460f92d.png)
最后，我们要配置Supervisor开机启动，新建一个“/usr/lib/systemd/system/supervisord.service”文件
```
# dservice for systemd (CentOS 7.0+)
# by ET-CS (https://github.com/ET-CS)
[Unit]
Description=Supervisor daemon
[Service]
Type=forking
ExecStart=/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
ExecStop=/usr/bin/supervisorctl shutdown
ExecReload=/usr/bin/supervisorctl reload
KillMode=process
Restart=on-failure
RestartSec=42s
[Install]
WantedBy=multi-user.target
```
执行命令，使得服务开机启动：
```
systemctl enable supervisord
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/efcc43dc-6fb6-4d1d-b803-6aa8fc22fe27.png)

### 开启防火墙
CentOS中防火墙程序主要是firewall和iptables，CentOS7中firewall服务已经默认安装好了。所以，这里介绍一下firewall相关配置。
默认防火墙是关闭的，为了访问的安全性，我们首先将防火墙开启，并设置开启启动：
```
systemctl start firewalld.service
systemctl enable firewalld.service
```
这时候，我们访问网站链接，发现已经端口屏蔽无法正常访问。所以接下来，我们要开放http(80端口)、https(443端口)、MySQL(3306端口)：
```
firewall-cmd --zone=public --add-port=80/tcp --permanen
firewall-cmd --zone=public --add-port=443/tcp --permanen
firewall-cmd --zone=public --add-port=3306/tcp --permanen
```
重启服务器，重新打开网站链接，可以正常访问。

### FTP 一键部署
在之前Windows Server服务器上，已经配置过FTP服务器，项目部署时，通过VS可以很方便的一键部署，那CentOS上该如何配置呢？
第1步，安装一下ftp服务：
```
yum -y install vsftpd
```
第2步，打开/etc/vsftpd/vsftpd.conf配置文件，修改如下2处：
```
anonymous_enable=NO 
chroot_local_user=YES
```
第3步，打开ftp服务，并设置开机启动，并开放远程访问端口：
```
systemctl restart vsftpd.service
systemctl enable vsftpd.service

firewall-cmd --permanent --add-service=ftp 
firewall-cmd --reload 
setsebool -P ftp_home_dir on
```
最后，增加一个ftp访问用户，配置发布目录，并提供写权限和设置密码：
```
useradd -d /data/wwwroot -m ftpuser -s /sbin/nologin
cd /data/wwwroot/
chmod -R 777 *
passwd ftpuser
```
VS2017中，修改ftp部署配置如下图：
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/20180315163612.jpg)

### 配置 https 协议
为了实现数据信息在客户端和服务器之间的加密传输，防止数据信息的泄露，保证双方传递信息的安全性，我们需要HTTP下加入SSL层，我之前已经申请过Symantec免费的SSL证书，所以就简单说明一下怎么配置。
前面我们的网站应用程序，已经通过Nginx反向代理来访问，那其实只用通过配置Nginx来管理我们申请的证书文件。首先下载证书文件，包括.crt和.key两个文件，然后拷贝到目录：/etc/nginx/ssl下，接着编辑Nginx配置文件，找到相关地方做如下修改：
```
listen       80 default_server;
listen       [::]:80 default_server;
listen       443 ssl;    #如果硬性要求全部走https协议，这里去除ssl  
server_name  _;
root         /usr/share/nginx/html;

#ssl on;   #如果硬性要求全部走https协议，这里开启ssl on  
ssl_certificate /etc/nginx/ssl/www.lancel0t.cn.crt;    
ssl_certificate_key /etc/nginx/ssl/www.lancel0t.cn.key;  
      	
ssl_session_cache    shared:SSL:1m;  
ssl_session_timeout  5m;  
      	
ssl_protocols  SSLv2 SSLv3 TLSv1.2;   
      	
ssl_ciphers  HIGH:!aNULL:!MD5;  
ssl_prefer_server_ciphers  on;  

# Load configuration files for the default server block.
include /etc/nginx/default.d/*.conf;
```
最后，我们重启一下Nginx，输入我们的网站地址：<a href="https://www.lancel0t.cn/" target="_blank">https://www.lancel0t.cn/</a> ，看到能够正常访问。
![avatar](https://bj.bcebos.com/v1/mysite/images/201803/20180315112534.jpg)

至此，网站应用程序移植到Linux环境中完美完成！当然，实施的过程中笔者也踩过不少的坑，这里希望能抛砖引玉，有什么问题欢迎给我博客留言，一起讨论。