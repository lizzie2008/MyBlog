---
title: .NET Core 搭建个人网站 | (2) 一键部署和用户登录
tags:
  - .NET Core
  - Entity Framework
  - Indentity
categories: 软件工程
date: 2018-01-02
---
![avatar](https://mysite.bj.bcebos.com/images/articles/7e924335-4ad3-4382-812a-03ebf5a46d59.jpg)

### 摘要
俗话说，磨刀不费砍柴工。为了更方便的进行项目管理，我们先将个人网站项目配置一下，满足以下2个目标：
- VS2017中支持Git存储库，绑定Github项目，实现本地VS程序与线上Github一键代码提交和同步；
- 搭建服务器FTP站点，VS2017中配置一键部署网站文件到服务器；    

有了以上的配置，我们可以不用每次拉取和同步我们的程序到Github中，也不用每次在本地发布，拷贝服务器，我们只用在VS2017中简单的一键同步到Github或网站服务器。这样我们的开发效率有了很大的提高，也方便线上验证我们的程序代码。
<!-- more -->

### VS2017支持Github
选择 工具-->扩展和更新，搜索GitHub，安装GitHub的VS插件
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207153111550-745349484.png)
安装完插件，打开视图-->团队资源管理器，我们可以看到Git插件菜单。通过菜单我们可以新建Git存储库，可以提交修改的代码，并一键同步提交后的代码到自己的GitHub项目中。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207153527613-252782156.png)![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207153615191-386595220.png)      
再打开GitHub，可以看我们的代码已经同步了，是不是很方便？
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207153726347-1757772626.png)

### VS2017支持FTP远程发布
要VS支持FTP发布，首先要将网站服务器配置成FTP服务器。
Server2008添加新的角色，选中文件服务并安装新角色：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207154205925-1599825668.png)
再次选中已安装的IIS服务，增加FTP服务器相关的角色：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207154335566-667721509.png)
接着，在IIS网站右键选择“添加FTP站点”，选择FTP文件物理路径和添加站点名称：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207154623847-2011046128.png)
端口默认21，不用选择SSL证书，身份验证这里选择基本验证（为了一定的安全性，不要勾选匿名），授权访问里，指定administrator才能访问FTP站点，并具有读取和写入的权限；
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207154750941-397237430.png)
完成后，我们建好的FTP就自动启动了，这时浏览器中输入ftp://localhost ，输入用户名和密码，就可以访问对应的文件目录了。当然，我们外网还是无法访问，为什么呢？相信大家看过上一篇，应该知道是防火墙的原因，我们按照上一篇的配置，增加FTP 21端口的允许入站规则，这样我们外网就通过FTP访问网站发布目录。
配置完外网服务器，我们来配置一下本地VS2017，右键项目-->发布，选择FTP发布，选项配置如下：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207160235847-1301216090.png)
这样我们就已经配置好本地一键发布站点到远程服务器了。以后直接点发布按钮，就可以看到自动将生成的发布文件，同步到网站服务器：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207160450972-1598824494.png)

### 替换前端框架
准备工作做完，浏览器输入网站服务器IP，可以看到可以正常访问，但是.net core mvc帮我们自动生成的界面，不一定符合我们的需求，那还是自己找一个前端的UI框架，替换一下既有界面。这里我选择的是 AdminLTE ,这是一个基于 bootstrap 的轻量级后台模板，相关的资料大家可以去官网研究一下。
我们把下载的文件解压缩到wwwroot/lib目录下，第一步先重构一下登录的界面：
```html
@model LoginViewModel

@{
    Layout = null;
    ViewData["Title"] = "登录";
}

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - LanceL0t</title>

    @await Html.PartialAsync("_SiteCssPartial")
</head>
<body class="hold-transition login-page">
    <div class="login-box">
        <div class="login-box-body">
            <p class="login-box-msg">欢迎，由此登录</p>
            <form asp-route-returnurl="@ViewData["ReturnUrl"]" method="post">
                <div asp-validation-summary="All" class="text-danger"></div>
                <div class="form-group has-feedback">
                    <input asp-for="Email" class="form-control" placeholder="邮箱">
                    <span class="glyphicon glyphicon-envelope form-control-feedback"></span>
                </div>
                <div class="form-group has-feedback">
                    <input asp-for="Password" class="form-control" placeholder="密码">
                    <span class="glyphicon glyphicon-lock form-control-feedback"></span>
                </div>
                <div class="row">
                    <div class="col-xs-8">
                        <div class="checkbox icheck">
                            <label asp-for="RememberMe">
                                <input asp-for="RememberMe"> @Html.DisplayNameFor(m => m.RememberMe)
                            </label>
                        </div>
                    </div>
                    <div class="col-xs-4">
                        <button type="submit" class="btn btn-primary btn-block btn-flat">登录</button>
                    </div>
                </div>
            </form>
            <div class="social-auth-links text-center">
                <p>- 或者 -</p>
                <a href="#" class="btn btn-block btn-social btn-facebook btn-flat">
                    <i class="fa fa-facebook"></i> Sign in using
                    Facebook
                </a>
                <a href="#" class="btn btn-block btn-social btn-google btn-flat">
                    <i class="fa fa-google-plus"></i> Sign in using
                    Google+
                </a>
            </div>
            <a asp-action="ForgotPassword">忘记密码</a><br>
            <a asp-action="Register" asp-route-returnurl="@ViewData["ReturnUrl"]" class="text-center">立即注册</a>
        </div>
    </div>
</body>
</html>

@await Html.PartialAsync("_SiteScriptsPartial")
@await Html.PartialAsync("_ValidationScriptsPartial")
```
接着第二步，优化一下之前的新用户注册界面：
```html
@model RegisterViewModel

@{
    Layout = null;
    ViewData["Title"] = "注册";
}

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - LanceL0t</title>

    @await Html.PartialAsync("_SiteCssPartial")
</head>
<body class="hold-transition login-page">
    <div class="login-box">
        <div class="login-box-body">
            <p class="login-box-msg">欢迎，注册新用户</p>
            <form asp-route-returnurl="@ViewData["ReturnUrl"]" method="post">
                <div asp-validation-summary="All" class="text-danger"></div>
                <div class="form-group has-feedback">
                    <input asp-for="Email" class="form-control" placeholder="请输入邮箱">
                    <span class="glyphicon glyphicon-envelope form-control-feedback"></span>
                </div>
                <div class="form-group has-feedback">
                    <input asp-for="Password" class="form-control" placeholder="请输入密码">
                    <span class="glyphicon glyphicon-lock form-control-feedback"></span>

                </div>
                <div class="form-group has-feedback">
                    <input asp-for="ConfirmPassword" class="form-control" placeholder="请确认密码">
                    <span class="glyphicon glyphicon-lock form-control-feedback"></span>
                </div>
                <div class="row">
                    <div class="col-xs-8">
                        <div class="checkbox icheck">
                            <label asp-for="IsAgree">
                                <input asp-for="IsAgree"> 阅读并接受《<a href="#">用户协议</a>》
                            </label>
                        </div>
                    </div>
                    <div class="col-xs-4">
                        <button type="submit" class="btn btn-primary btn-block btn-flat">注册</button>
                    </div>
                </div>
            </form>
            <div class="social-auth-links text-center">
                <p>- 或者 -</p>
                <a href="#" class="btn btn-block btn-social btn-facebook btn-flat">
                    <i class="fa fa-facebook"></i> Sign in using
                    Facebook
                </a>
                <a href="#" class="btn btn-block btn-social btn-google btn-flat">
                    <i class="fa fa-google-plus"></i> Sign in using
                    Google+
                </a>
            </div>
            <a asp-controller="Account" asp-action="Login">已有账号</a><br>
        </div>
    </div>
</body>
</html>

@await Html.PartialAsync("_SiteScriptsPartial")
@await Html.PartialAsync("_ValidationScriptsPartial")
```
这里的知识很简单，就不在祥述了，不过因为用的是.net core提供的identity用户管理和验证，有些个人遇到的问题，我还是列出来，以免再走弯路。

#### 自定义的服务器端和客户单的验证
比如，新用户注册时，要保证用户已勾选“阅读并接受用户协议”。而MVC本身校验机制没有提供bool型必须为true的校验，这里我们自己实现一个服务器端属性的校验，需要继承ValidationAttribute和IClientModelValidator：
```csharp
/// <summary>
/// 复选框必须选中验证
/// </summary>
[AttributeUsage(AttributeTargets.Property, AllowMultiple = false, Inherited = false)]
public sealed class MustBeTrueAttribute : ValidationAttribute, IClientModelValidator
{
    //服务器端验证
    public override bool IsValid(object value)
    {
        return value != null && (bool)value;
    }

    public void AddValidation(ClientModelValidationContext context)
    {
        MergeAttribute(context.Attributes, "data-val", "true");
        var errorMessage = FormatErrorMessage(context.ModelMetadata.GetDisplayName());
        MergeAttribute(context.Attributes, "data-val-mustbetrue", errorMessage);
    }

    private bool MergeAttribute(
        IDictionary<string, string> attributes,
        string key,
        string value)
    {
        if (attributes.ContainsKey(key))
        {
            return false;
        }
        attributes.Add(key, value);
        return true;
    }
}
```
再加上客户端的验证方法：
```javascript
<script>
    //必须复选框勾选验证
    $.validator.addMethod("mustbetrue",
        function (value, element, parameters) {
            return value === "true";
        });

    $.validator.unobtrusive.adapters.add("mustbetrue", [], function (options) {
        options.rules.mustbetrue = {};
        options.messages["mustbetrue"] = options.message;
    });
</script>
```
#### identity的本地化
目前使用identity默认的错误描述是英文，这里我们需要显示成中文，所以新增一个IdentityExtensions类，继承IdentityErrorDescriber，重写错误描述 
```csharp
public class IdentityExtensions : IdentityErrorDescriber
{
    public override IdentityError PasswordRequiresNonAlphanumeric()
    {
        return new IdentityError
        {
            Code = nameof(PasswordRequiresNonAlphanumeric),
            Description = "密码至少包含1位非数字字母的特殊字符"
        };
    }

    public override IdentityError PasswordRequiresDigit()
    {
        return new IdentityError
        {
            Code = nameof(PasswordRequiresDigit),
            Description = "密码至少包含1位数字('0'-'9')"
        };
    }

    public override IdentityError PasswordRequiresLower()
    {
        return new IdentityError
        {
            Code = nameof(PasswordRequiresLower),
            Description = "密码至少包含1位小写字符 ('a'-'z')"
        };
    }

    public override IdentityError PasswordRequiresUpper()
    {
        return new IdentityError
        {
            Code = nameof(PasswordRequiresUpper),
            Description = "密码至少包含1位大写写字符 ('A'-'Z')"
        };
    }
}
```
重写中文错误描述后，我们还得在Startup.cs文件中的服务配置中注册：
```csharp
public void ConfigureServices(IServiceCollection services)
{
    services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(Configuration.GetConnectionString("DefaultConnection")));

    services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders()
        .AddErrorDescriber<IdentityExtensions>();

    // Add application services.
    services.AddTransient<IEmailSender, EmailSender>();

    services.AddMvc();
}
```
登录和注册新用户没有问题了，再来改造一下登录后主页的布局，把_Layout布局视图分割成顶部区域、左侧导航菜单、内容区域、底部区域、右侧侧边栏，并用部分视图分别渲染：
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - LanceL0t</title>

    @await Html.PartialAsync("_SiteCssPartial")
</head>
<body class="hold-transition skin-blue sidebar-mini">
    <div class="wrapper">
        <!-- 顶部区域 -->
        @await Html.PartialAsync("_LayoutHeaderPartial")
        <!-- 导航栏 -->
        @await Html.PartialAsync("_LayoutNavbarPartial")
        <!-- 内容区域 -->
        <div class="content-wrapper">
            <section class="content-header">
                <h1>
                    Dashboard
                    <small>Version 2.0</small>
                </h1>
                <ol class="breadcrumb">
                    <li><a href="#"><i class="fa fa-dashboard"></i> 主页</a></li>
                    <li class="active">Dashboard</li>
                </ol>
            </section>
            <section class="content">
                @RenderBody()
            </section>
        </div>
        <!-- 底部区域 -->
        @await Html.PartialAsync("_LayoutFooterPartial")
        <!-- 侧边栏 -->
        @await Html.PartialAsync("_LayoutSidebarPartial")
    </div>

    @await Html.PartialAsync("_SiteScriptsPartial")
    @RenderSection("Scripts", required: false)
</body>
</html>
```
这样，我们登录和注册功能大体完成了，我们看下效果：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20171207164558613-789033155.gif)