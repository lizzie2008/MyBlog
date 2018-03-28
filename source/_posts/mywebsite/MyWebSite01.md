---
title: .NET Core 搭建个人网站 | (1) 环境搭建
tags:
  - .NET Core
  - Entity Framework
  - Windows Server
  - SQL Server
categories: 软件工程
date: 2018-01-01
---
![avatar](https://mysite.bj.bcebos.com/images/articles/9c93ff41-2251-428d-9a13-d553c20b6d65.jpg)

### 摘要
ASP.NET Core2.0发布有一阵子了，这是.NET 开源跨平台的一个重大里程碑， 也意味着比1.0版本要更加成熟。目前.NET Core具有开源、跨平台、灵活部署、模块化架构等等特性，吸引着一大批开发者。笔者也开始加入拥抱.NET Core大军，那就搭建一个个人网站吧！
首先申明的是，这应该是一个长期的项目，我会不定期的更新，持续集成，慢慢的把想要的新功能叠加到网站上。这也是积累的过程，我希望通过文章分享给博友们，也欢迎你们关注我，与我一同讨论，共同进步！
话不多说，咱们开始~

<!-- more -->

### 部署环境
- **服务器环境**
 - 操作系统：Windows Server 2008 R2
 - 数据库：SQL Server 2012
- **开发环境**
 - IDE: VS 2017

这里为了搭建公网可以访问的网站，服务器我用的是XX云服务器（自带Server 2008系统，提供公网IP）。当然大家只是想练练手不想花钱，也没关系，本地运行调试也好，有些远程配置内容可以直接跳过。
有了服务器，我们还需要搭建数据库。这里我选的是SQL Server 2012 Express版（带数据库管理工具，大概700M），对应中小型应用就够了。主要因为云服务器CPU、内存、磁盘是在太珍贵了，尽量够用就好，不用最新或功能最全的版本。

#### SQL Server安装与配置
运行SQL Server 安装包，按照提示一步步安装即可，默认安装是包含客户单SDK和管理工具，安装完毕后，SQL Server会自动生成一个数据库实例；打开菜单中SQL Server Management Studio，连接数据库实例，可以看到能正常访问数据库。当然，这样访问本地的数据库没问题，但是我们需要外网远程访问数据库，所以需要做些配置：
第1步，我们选中数据库实例，右键-->属性-->选中 安全性
因为远程访问就不能仅仅通过Windows身份验证了，这里我们选中SQL Server和Windows身份验证模式；
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201160104711-1344648663.png)
第2步，选中 连接，确认“允许远程连接到此服务器”选中；
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201160400227-527939194.png)
第3步，数据库实例-->安全性-->登录名-->sa右键属性
将超级管理员sa密码设置一下，并将sa用户启用；
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201160511539-448005984.png)
第4步，先退出，再用sa登录，成功即表示sa帐户已经启用
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201160746789-217069105.png)
第5步，我们可以关闭SQL Server Management Studio，打开SQL Server 配置管理器，选中MSSQLSERVER的的协议，将TCP/IP协议状态改成已启用（默认是禁用），完毕后我们重启SQL Server；
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201160919055-1504234981.png)
TCP/IP属性，切换IP地址页签，确认TCP端口是否是1433，如果不是，如下配置：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180115164815693-1908387028.png)
至此，SQL Server的相关配置已经设置完毕，但还是不能支持远程访问，我们还需要设置一下服务器防火墙。

#### 服务器防火墙配置
打开服务器管理器，选中防火墙配置，里面有“入站规则”，点击进去；
选中“新建规则...”
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201161228711-1207053163.png)
规则类型选择端口：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201161527773-550201075.png)
协议选择TCP协议，端口号输入1433（SQL Server默认端口）
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201161627617-565429985.png)
下一步，选择“允许连接”
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201161714617-437161173.png)
下一步，规则配置文件，全选
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201161752367-43551662.png)
最后，输入规则名称，取名“SQL Server 端口”，点击完成，可以看到我们的添加的规则已在防火墙允许访问范围了。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201161943148-1956966750.png)
 
#### 测试远程访问数据库
在本地机器上打开VS 2017，找到视图-服务器资源管理器--数据连接，右键-->添加连接；
更改数据源，选择Microsoft SQL Server ；
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201162323523-39971004.png)
服务器名，输入云服务器的IP地址，选择SQL Server身份验证，敲入之前设置的用户名和密码，就可以加载远程数据库实例下的所有数据库。这样我们连远程数据库就没有问题了。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201162631570-849744745.png)

#### IIS环境和.NET Core Windows Server Hosting配置
为了在服务器上运行我们的网站，首先需要配置IIS。
Server 2008上，添加"角色"，选中“Web 服务器”，完成IIS安装。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201163503695-283945293.png)
一般的.NET发布的网站，现在就可以配置运行了，但是.NET Core与传统的ASP.NET程序不同，ASP.NET Core App使用了Kestrel Server。Kestrel是一个跨平台的Web Server，与IIS一样负责请求的监听、接收和响应，但没有IIS丰富的管理功能，仍需要由IIS来处理一些前置工作。
所以这块我们还需要安装IIS到Kestrel server的反向代理：[.NET Core Windows Server Hosting bundle](https://download.microsoft.com/download/1/1/0/11046135-4207-40D3-A795-13ECEA741B32/DotNetCore.2.0.5-WindowsHosting.exe)
安装完成后，需要重启一下机器，然后我们就可以正式的搭.NET Core网站了。


### 创建ASP.NET Core Web项目
准备工作做完后，我们终于可以开始建项目了，打开VS 2017，文件-->项目，创建ASP.NET Core Web项目，点击确定；
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201165905648-1627246029.png)
这里默认选择.NET Core 2.0环境,Web 应用程序（模型视图控制器），注意，这里的身份验证，我选择了个人用户账户，主要是方便用户和角色管理，和身份验证。后面有单独的章节，专门跟大家探讨一下这块的知识。确定后，VS 自动帮我们生成好可运行的项目代码。
这时候，我们就要通过连接远程服务器上的数据库，通过Code First方式，生成数据库表结构了。
先在数据库中实例中，创建一个数据库，命名为MyWebSite:
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201170820664-1052081749.png)
在本地VS中，通过之前服务器资源管理器的配置，我们看到可以连接MyWebSite这个数据库，并测试连接成功。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201171204008-911981763.png)
点确定建立数据连接，右键-->属性，可以查看连接字符串，拷贝一下这个连接字符串
```
Data Source=180.*.*.89;Initial Catalog=MyWebSite;User ID=sa;Password=***********
```
打开项目配置文件appsettings.json：
把默认的连接字符串用上面字符串替换如下：
```
"ConnectionStrings": {
  "DefaultConnection": "Data Source=180.*.*.89;Initial Catalog=MyWebSite;
  User ID=sa;Password=*******"
},
```
这样，数据库连接就配置好了。因为选择的是个人身份验证的项目，所以VS帮我们生成好了对应的实体类和数据库迁移，我们所要做的，是要数据库更新，来生成相应的表结构。
打开工具-->Nuget包管理器-->程序包管理器控制台
输入update-database并运行，成功后，我们回头看看远程的MyWebSite数据库，帮我们自动生成了所有的表结构
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201172705117-967726456.png)
接下来，我们ctrl+F5运行一下，网站正常启动如下：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201172908117-613955278.png)

### 发布网站到服务器
网站本地运行没问题了，我们继续后续发布的操作，项目右键，选择“发布...”，暂时我们选择本地文件夹(后面项目管理的时候，我们再配置远程发布)，将发布后生成的文件拷贝到云服务器上，这里放到c:\MyWebSite目录中。
IIS管理中，选中网站，把默认的Default Web Site停用，因为它占用了80端口，跟我们要搭建的冲突；
右键-->添加网站
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201173357961-790622300.png)
如下图配置，用80端口，HTTP默认访问端口。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201173549898-1974693916.png)
点确定，这样我们的网站至此，成功搭建！
用用浏览器，输入外网IP地址访问我们的云服务器（如果不能正常访问，请检查防火墙是否开放了80端口，按照之前设置一下就行）：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171201174154539-1487036508.png)
ok，完美~