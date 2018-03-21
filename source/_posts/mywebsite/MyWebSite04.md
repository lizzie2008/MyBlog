---
title: .NET Core 搭建个人网站 | (4) 主页和登录验证
tags:
  - .NET Core
  - Entity Framework
  - Indentity
categories: 软件工程
date: 2018-01-04
---
![avatar](https://mysite.bj.bcebos.com/images/articles/68899957-b647-41ef-b64c-cbc0f7db14f3.jpg)

### 摘要
上章节我们已经定制好动态配置的菜单，用户登录网站的第一步就是进入首页内容，那我们先搭建一下我们的首页内容。想着自己的网站内容主要是个人博客类型，所以，首页就展示博主本人的一些基本信息吧，哈哈。当然，做成静态的界面很简单，直接将信息填进html中就行了，基本没有什么技术含量，那我们这里要做成可配置的：将个人信息配置在json文件中（也可以存储在数据库，考虑信息内容结构的不可预期性和易变性，这里不采用数据库保存）。这样，以后我们要更新主页上的信息时，就不用编译发布网站，只要修改对应的json配置文件即可。
<!-- more -->

### .NET Core 配置机制介绍
提到“配置”二字，我们脑海中会立马浮现出两个特殊文件，那就是我们再熟悉不过的app.config和web.config，一直以来我们已经习惯了将结构化的配置信息定义在这两个文件之中。到了.NET Core的时候，很多我们习以为常的东西都发生了改变，其中也包括定义配置的方式。有兴趣的同学可以移步官方文档介绍：<a href="https://docs.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?tabs=basicconfiguration" target="_blank">.net core 配置</a>。
.NET Core不仅支持以键-值对的形式、结构化的形式读取相关的配置信息（可以自己去研究，这里不再祥述），更重要的是，如今可以将定义的结构化配置绑定为对象。之前我们必须逐条的读取配置信息，如果配置项太多的话，读取配置项其实是一项非常繁琐的工作。现在只用再定义对应结构的Option对象，框架自动帮我们绑定配置信息到这个对象，我们直接访问对象中的属性即可。除此之外，.NET Core采用依赖注入的方式来使用Option模型，这样我们就和方便的在需要的地方使用配置信息了。
接下来看具体怎么使用，首先，在项目中增加json配置文件，这里结构如下：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180104151151956-54474223.png)
我们按照Json的格式，定义一个接收配置信息的类（结构完全等同json中的定义）
```csharp
/// <summary>
/// 个人资料
/// </summary>
public class MyProfile
{
    public IEnumerable<Project> Projects { set; get; }
}

/// <summary>
/// 项目经历
/// </summary>
public class Project
{
    /// <summary>
    /// 持续至日期
    /// </summary>
    public string LastToDate { set; get; }
    /// <summary>
    /// 项目名称
    /// </summary>
    public string Name { set; get; }
    /// <summary>
    /// 持续时间
    /// </summary>
    public int Lasting { set; get; }
    /// <summary>
    /// 所在公司
    /// </summary>
    public string Company { set; get; }
    /// <summary>
    /// 项目职务
    /// </summary>
    public string MyTitle { set; get; }
    /// <summary>
    /// 项目职责
    /// </summary>
    public string MyDuty { set; get; }
    /// <summary>
    /// 项目技术
    /// </summary>
    public string Technology { set; get; }
    /// <summary>
    /// 项目规格
    /// </summary>
    public int NumOfPeople { set; get; }
    /// <summary>
    /// 项目描述
    /// </summary>
    public IEnumerable<string> ProjectDescs { set; get; }
    /// <summary>
    /// 项目图片
    /// </summary>
    public IEnumerable<string> ProjectImgs { set; get; }
}
```
那怎么建立json数据和对象之间的映射呢，见证奇迹的时候到了，在Startup.cs文件中ConfigureServices方法中，增加以下代码：
```csharp
var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("Datas/Config/MyProfile.json");

var config = builder.Build();

services.Configure<MyProfile>(config.GetSection("MyProfile"));
```
在需要使用配置信息地方通过构造器注册，可以看到相关信息完整的加载到对象中，是不是新的配置系统显得更加轻量级，具有更好的扩展性，并且支持多样化的数据源。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180104152159112-1996863975.png)

### 个人信息展示
有了可配置的个人信息数据，我们只需要在主页上将之展示出来即可，后台管理--菜单管理，添加一个主页菜单，排序最前，设置访问路径/Home/Index，图标样式，保存后左侧导航便出现新增的主页菜单项。在HomeController控制器的Index方法中，已经读取到个人信息数据，返回前端渲染，效果如下：
```html
<div class="tab-pane active" id="timeline">
    <ul class="timeline timeline-inverse">

        @foreach (var project in Model.Projects.Reverse())
        {
            <li class="time-label">
                <span class="bg-light-blue">@project.LastToDate</span>
            </li>
            <li>
                <i class="fa fa-tags bg-blue"></i>
                <div class="timeline-item">
                    <span class="time">持续时间:@(project.Lasting)个月 <i class="fa fa-clock-o"></i></span>
                    <h3 class="timeline-header">
                        <a>项目名称</a> @project.Name
                    </h3>
                    <div class="timeline-body">
                        <p class="text-muted">所在公司: @project.Company</p>
                        <p class="text-muted">项目职务: @project.MyTitle</p>
                        <p class="text-muted">项目职责: @project.MyDuty</p>
                        <p class="text-muted">项目技术: @project.Technology</p>
                    </div>
                    <div class="timeline-footer">
                        <a class="btn btn-primary btn-xs">更多 >></a>
                    </div>
                </div>
            </li>
            <li>
                <i class="fa fa-thumb-tack bg-aqua"></i>
                <div class="timeline-item">
                    <span class="time">规模:@(project.NumOfPeople)个人 <i class="fa fa-cube"></i></span>
                    <h3 class="timeline-header no-border">
                        <a>项目描述</a>
                    </h3>
                    <div class="timeline-body">
                        @if (project.ProjectDescs != null)
                        {

                            var descIndex = 0;

                            foreach (var projectDesc in project.ProjectDescs)
                            {
                                <p class="text-muted">@(++descIndex). @projectDesc.</p>
                            }
                        }
                    </div>
                </div>
            </li>
            if (project.ProjectImgs != null)
            {
                <li>
                    <i class="fa fa-camera bg-purple"></i>
                    <div class="timeline-item">
                        <span class="time"><i class="fa fa-photo"></i></span>
                        <h3 class="timeline-header">
                            <a>效果预览</a>
                        </h3>
                        <div class="timeline-body">
                            <div class="row">
                                @foreach (var projectImg in project.ProjectImgs)
                                {
                                    <div class="col-sm-6 col-md-4">
                                        <img style="cursor: pointer; height: 150px;" src="@projectImg"
                                             alt="..." class="img-responsive thumbnail center-block img-more">
                                    </div>
                                }
                            </div>
                        </div>
                    </div>
                </li>
            }

        }

        <!-- start -->
        <li class="time-label">
            <span class="bg-green">2009.02</span>
        </li>
        <li>
            <i class="fa fa-clock-o bg-gray"></i>
        </li>
    </ul>
</div>
```
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180104153333237-1128822963.png)
目前图片是用压缩后的缩略图显示的（为了网页快速加载），可能用户想要展开看原始图，所有我们这块可以优化一下，点击缩略图，弹出模态框，展示原始尺寸图片。ok，主页部分大功告成，后台修改json文件配置，我们的主页内容也和方便的更新了。
```javascript
 1 <script>
 2     $('.img-more').click(function () {
 3         var file = $(this).attr('src')
 4         var fileNames = file.split('.')
 5         $("#myModal").find("#img_show").html("<image src='" +
 6             fileNames[0] + '-lg.' + fileNames[1] +
 7             "' class='carousel-inner img-responsive img-rounded' />")
 8         $("#myModal").modal();
 9     })
10 </script>
```
### 登录验证功能
还记得第2章内容吗，我们已经实现了用户的注册和登录，但是目前没有做相关的登录验证和权限管理（权限管理以后等后面完成用户角色单独开一章说，本章主要说一下登录验证）。比如我们注销用户时，再次通过浏览器链接，输入<code>http://localhost:16546/Configuration/Menu/Index</code>，就可以跳过登录，直接访问菜单界面。这块我们要自己实现的话，不外乎2种方案：
第1种：定义一个公共的控制器，其他所有的控制器继承它，公共的控制器实现重写如下方法：
```csharp
public class AuthenticationControllor : Controller
{
    protected override void OnActionExecuting(ActionExecutingContext filterContext)
    {
        if (filterContext.HttpContext.Session["username"] == null)
            filterContext.Result = new RedirectToRouteResult("Login", new RouteValueDictionary { { "from", Request.Url.ToString() } });
            
        base.OnActionExecuting(filterContext);
    }
}
```
第2种：定义认证特性，继承ActionFilterAttribute，在需要验证的地方，增加属性认证：
```csharp
// 登录认证特性
public class AuthenticationAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext filterContext)
    {
        if (filterContext.HttpContext.Session["username"] == null)
            filterContext.Result = new RedirectToRouteResult("Login", new RouteValueDictionary { { "from", Request.Url.ToString() } });
            
        base.OnActionExecuting(filterContext);
    }
}
```
那我们采用哪种方法呢？都不用，哈哈，因为Indentity帮我们已经完成了所有的认证工作，直接在需要验证的控制器或方法上，增加属性过滤器[Authorize]即可。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180104160233518-474278203.png)
我们再试验下，注销登录后，我们浏览器中输入菜单界面地址链接，网站判断此时尚未登录，就会跳转到登录界面。用户输入登录信息无误后，跳转到需要访问的菜单界面。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180104160459143-776473374.gif)

### 加载Loading效果和form表单重复提交防护
上图我们可以看到，每次页面加载的时候页面头部会出现一条进度条和一个转动的loading，这样给用户的体验会很好，这是怎么实现的呢。其实AdminLTE已经提供了很方便的使用：首先我们在母版页Layout.cshtml引入<script src="~/lib/AdminLTE/plugins/pace/pace.js"></script>，然后加入以下脚本，就实现上述的效果，很简单吧：
```javascript
//ajax请求Pace效果
$(document).ajaxStart(function () {
    Pace.restart()
})
```
之前实现的菜单管理，存在一个小问题，比如用户在保存的时候，网速慢或服务器反应延迟的情况，用户等不急再次点击form表单中的提交按钮，就会造成重复提交的场景，一般会导致异常。虽然说在后台增加逻辑判断也可以解决，但是重复提交造成的异常各种各样，要就增加各种验证，得不偿失。我的想法是在前端提交后，服务器未返回结果之前，将提交按钮置为不可用状态，这样用户无法再次点击，从而避免服务器端异常。但是还有个问题，必须在jquery前端验证之后，才能开始置为不可用，否则前端验证失效。所以我们修改下jquery前端验证的默认的submitHandler。每当用户点击提交按钮时，会首先触发前端验证，验证不通过，直接显示错误提示；验证通过后，将按钮置不可用，直到服务器返回结果。
```javascript
1 //防止重复提交
2 $.validator.setDefaults({
3     submitHandler: function (form) {
4         $(form).find('[type="submit"]').attr('disabled', true);
5         form.submit();
6     }
7 });
```

### 404,500等错误页面提示
之前我们建了一些菜单项，因为没有指定访问路径，点击后会有404错误；另外，一些服务器异常，网页抛出500错误。这些需要捕获一下，并提供友好的页面显示给用户。在Startup.cs文件Configure方法中，配置如下：
```csharp
if (env.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error/500");
    app.UseStatusCodePagesWithReExecute("/Home/Error/{0}");

    app.UseDeveloperExceptionPage();
    app.UseBrowserLink();
    app.UseDatabaseErrorPage();
}
else
{
    app.UseExceptionHandler("/Home/Error/500");
    app.UseStatusCodePagesWithReExecute("/Home/Error/{0}");
}
```
对应的控制器代码更新如下：
```csharp
[Route("Home/Error/{statusCode}")]
public IActionResult Error(int statusCode)
{
    return View(new ErrorViewModel
    {
        StatusCode = statusCode,
        RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier
    });
}
```
对应视图代码也需要更新一下：
```html
@model MyWebSite.ViewModels.ErrorViewModel
@{
    ViewData["Title"] = "错误";
}
<div class="error-page" style="margin-top: 100px;">
    @if (Model.StatusCode == 500)
    {
        <!-- 500类型错误 -->
        <h2 class="headline text-red"> @Model.StatusCode</h2>

        <div class="error-content">
            <h3>
                <i class="fa fa-warning text-red"></i> Oops! Something went wrong.
            </h3>
            <div>
                StatusCode:<code>@Model.StatusCode</code>
            </div>
            <div>
                Request ID: <code>@Model.RequestId</code>
            </div>
            <p>
                We will work on fixing that right away.
                Meanwhile, you may <a asp-area="" asp-controller="Home" asp-action="Index">return to index</a> or try using the search form.
            </p>
            <form class="search-form">
                <div class="input-group">
                    <input type="text" name="search" class="form-control" placeholder="Search">
                    <div class="input-group-btn">
                        <button type="submit" name="submit" class="btn btn-danger btn-flat">
                            <i class="fa fa-search"></i>
                        </button>
                    </div>
                </div>
            </form>
        </div>
    }
    else
    {
        <!-- 其他类型错误 -->
        <h2 class="headline text-yellow"> @Model.StatusCode</h2>

        <div class="error-content">
            <h3>
                <i class="fa fa-warning text-yellow"></i> Oops! Page not found.
            </h3>
            <div>
                StatusCode:<code>@Model.StatusCode</code>
            </div>
            <div>
                Request ID: <code>@Model.RequestId</code>
            </div>
            <p>
                We could not find the page you were looking for.
                Meanwhile, you may <a asp-area="" asp-controller="Home" asp-action="Index">return to index</a> or try using the search form.
            </p>
            <form class="search-form">
                <div class="input-group">
                    <input type="text" name="search" class="form-control" placeholder="Search">
                    <div class="input-group-btn">
                        <button type="submit" name="submit" class="btn btn-warning btn-flat">
                            <i class="fa fa-search"></i>
                        </button>
                    </div>
                </div>
            </form>
        </div>
    }
</div>
```

### 小结
以上，这期关于网站的调整已介绍完毕，最后，后台管理--菜单管理，添加对应博客链接的菜单项，为了方便用户通过链接访问我的博客，看下演示效果吧：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180104142813315-250952657.gif)