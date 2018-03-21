---
title: .NET Core 搭建个人网站 | (6) 单页模式和优化
tags:
  - .NET Core
  - Entity Framework
  - AngularJS
  - 单页模式
  - 多页模式
categories: 软件工程
date: 2018-01-06
---
![avatar](https://mysite.bj.bcebos.com/images/articles/da0e7291-e501-4e6c-b6b6-f072407c0672.jpg)

### 摘要
HI，有段时间没有更新了，主要因为第一年前事情比较多，有些事得忙着张罗下；第二呢，对个人网站进行了一次大范围的优化，主要是申请的云服务器资源有限，1m的网络带宽，带上图片展示的话，打开网站的平均速度会达到20s以上，用户的体验不是很好；经过这次优化，已将访问速度控制在1s左右，整体感觉速度和用户体验提升了不少。当然，最主要的是，把网站的模式改成了单页应用模式，算得上是比较大的重构了，所以耽搁的时间比较久，请大家见谅。
那今天主要来说一下我是怎么重构之前的网站代码，更新为单页模式吧，顺便分享下个人性能优化的经验。
<!-- more -->

### 重构出发点和目标
之前.Net Core自动帮我们生成的网站代码，主要是多页的应用，我们定义页面的时候，引入了_layout文件，相当视图区域的模板页，那通过控制器调整页面的同时，会将整个页面包括模板页都会再次加载一遍。所以，之前的多页应用，对应我的个人应用来说，有以下问题：
- 页面导航跳转时，需要重新加载整个页面包含的css、js和html元素，云服务器带宽有限，重新加载资源有些浪费；
- 用户体验不好，在网速带宽不够的情况下，页面刷新慢，用户需要等待很长一段时间才能看到内容区域；
- 作为后台管理系统，页面布局包含导航栏，头部区域、尾部区域和内容区域，除了内容区域的视图会经常变换，其他区域不会有大的变化，却每次需要重新加载和刷新；
- 当初网站设计需要在移动端提供支持，多页应用在移动设备中页面切换的表现加载慢、不流畅、用户体验差；

现在，网页设计整体趋向于单页网站设计，但是这里我还是要强调一下，我从没说过单页模式就一定比多页模式要好，只是这对我个人网站项目来说，单页模式可能会更合适。其实2者都有很明显的优缺点，多页模式也有它的优势，比如可以很方便的做SEO，单页模式也有自己的劣势，比如得单独方案做SEO，而且开发难度相对多页会复杂些。
所以说，一切抛开具体应用去谈技术之间的好坏都是耍流氓！！！这里，我们的网站也不完全是单页模式，比如登录页面跳转等等用的还是多页，所以只能说是以单页模式为主的混合模式。
那既然我们决定要改造我们的网站为单页应用，首先定一下优化的目标吧：
- 以简单、容易和可操作的方式展示给用户，提供用户简单的线性体验；
- 整个页面有固定的导航栏，头部区域、尾部区域和变化的内容区域，实现页面片段局部刷新；
- 公共资源首次加载后，页面更新后不在重新加载；
- 选择专门的UI框架，降低单页模式的开发难度；
- 很好的响应式设计，支持移动端良好的用户体验；

### 引入UI路由框架
既然我们舍弃了多页模式，就不能再用微软提供的_layout模板页取渲染视图了，很方便的Razor引擎也没法再用了（这里稍微解释下，.Net Core之前版本的，是可以继续用Razor来渲染数据模型的，但是.Net Core中，会将cshtml文件一起编译成dll文件，所以cshtml文件在发布路径中是找不到的，所以路由后的url是找不到的），那选用那种UI框架，来满足单页模式应用呢？
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180129114442890-1447557048.png)
我们理一下思路：如图，我们通过导航栏side的url地址，通过一种路由方式找到对应的html文件，然后后台加载数据，通过UI渲染，在内容区域content中显示。这里可以看出，主要要满足一是url的路由，二是数据模型的渲染。当然，满足这样需求的UI框架很多，我这里用的一种主流框架angular-ui-router(url路由，可以支持多样化视图和嵌入式视图)+angular（数据模型和UI界面双向绑定），大家也可以用别的方式，条条大道通罗马嘛！

#### angular-ui-router配置
本文只是简单介绍angular的使用方法，如果需要了解更多的使用方法，请参考官网文档。
首先，我们引入以下2个脚本：angular.js和angular-ui-router.js。导航菜单结构重构如下：
```csharp
/// <summary>
/// 导航菜单项
/// </summary>
public class NavMenu
{
    public string Name { get; set; }
    public string TemplateUrl { get; set; }
    public string Icon { get; set; }

    /// <summary>
    /// 子菜单
    /// </summary>
    public IList<NavMenu> SubNavMenus { get; set; }
}

/// <summary>
/// 左侧导航菜单视图模型
/// </summary>
public class NavBarMenus
{
    public IList<NavMenu> NavMenus { get; set; }
}
```
在site.js里，做如下配置：
```javascript
//Angular相关配置
var app = angular.module('app', ['ui.router']);
//路由配置
app.config(['$stateProvider', '$urlRouterProvider', function ($stateProvider, $urlRouterProvider) {
    $urlRouterProvider.otherwise('/');
    $stateProvider.state('Home', {
        //主页
        url: '/',
        templateUrl: 'App/Home/Home.html'
    }).state('MenuManagement', {
        //菜单管理
        url: '/Configuration/MenuManagement',
        templateUrl: 'App/Configuration/MenuManagement/MenuManagement.html'
    }).state('ApiSimulator', {
        //API模拟
        url: '/Tools/ApiSimulator',
        templateUrl: 'App/Tools/ApiSimulator/ApiSimulator.html'
    }).state('SiteAnalytics', {
        //网站分析
        url: '/Tools/SiteAnalytics',
        templateUrl: 'App/Tools/SiteAnalytics/SiteAnalytics.html'
    }).state('Error', {
        url: '/Error',
        templateUrl: 'App/Home/Error.html'
    });
}]);
```
之前的嵌套菜单也需要重构，注意这里操作菜单不再用<a>标签的默认导航属性href，而是改用ui-sref属性：
```html
@foreach (var navMenu in Model.NavMenus)
{
    if (navMenu.SubNavMenus != null && navMenu.SubNavMenus.Any())
    {
        <li class="treeview">
            <a href="#">
                <i class="fa @navMenu.Icon"></i><span>@SharedLocalizer[navMenu.Name]</span>
                <span class="pull-right-container">
                    <i class="fa fa-angle-left pull-right"></i>
                </span>
            </a>
            <ul class="treeview-menu">
                @await Html.PartialAsync("_NavMenu", new NavBarMenus { NavMenus = navMenu.SubNavMenus })
            </ul>
        </li>
    }
    else
    {
        <li>
            @if (navMenu.TemplateUrl != null && navMenu.TemplateUrl.StartsWith("http"))
            {
                <a href="@navMenu.TemplateUrl" target="_blank">
                    <i class="fa @navMenu.Icon"></i><span>@SharedLocalizer[navMenu.Name]</span>
                </a>
            }
            else
            {
                <a ui-sref="@navMenu.TemplateUrl">
                    <i class="fa @navMenu.Icon"></i><span>@SharedLocalizer[navMenu.Name]</span>
                </a>
            }
        </li>
    }
}
```
以上，我们的路由配置就可以了，点击左侧的导航菜单，angular-ui-router会自动帮我们解析，对应做部分视图更新，我们可以看到，现在整页只有内容区域部分刷新，其他区域不再会被重新加载。

#### angularjs数据视图双向绑定
多页模式下，我们的控制器方法返回的是View视图，即整个html页面。改造成单页模式，控制器需要返回的是数据模型的json，通过angularjs提供的数据双向绑定，可以很方便的改造，以下用菜单管理功能作为示例。
我们新增一个html视图_MenuPartial.html，作为菜单项的部分视图（相当于叶节点），可以看到节点会判断有没有子菜单，如果有子菜单，会再次引用_MenuPartial.html，实现了子菜单的嵌套：
```html
<div class='dd-handle dd3-handle'></div>
<div class="dd3-content" ng-click="editMenu(item)">
    <i class="fa {{item.icon}} margin-r-5"></i>{{item.name}}
    <span class='pull-right'>
        <a style="cursor: pointer"
           ng-click="deleteMenu(item,$event);$event.stopPropagation();">
            <i class="fa fa-minus text-success margin-r-5"></i>
        </a>
    </span>
</div>
<ol class='dd-list' ng-if="item.subNavMenus">
    <li class="dd-item dd3-item"
        ng-repeat="item in item.subNavMenus"
        ng-include="'App/Configuration/MenuManagement/_MenuPartial.html'"></li>
</ol>
```
有了菜单项模板，接下来重构一下菜单管理页面MenuManagement.html，控制器指定MenuManagementController：
```html
<section class="content-header">
    <h1>
        菜单管理
        <small>Preview</small>
    </h1>
    <ol class="breadcrumb">
        <li><a href="#"><i class="fa fa-home"></i></a></li>
        <li>后台管理</li>
        <li class="active">菜单管理</li>
    </ol>
</section>
<section class="content">
    <div class="box" ng-controller="MenuManagementController">
        <div class="box-body row">
            <div class="col-md-7">
                <div class="dd">
                    <ol class='dd-list'>
                        <li class="dd-item dd3-item" ng-repeat="item in navMenus" 
                            ng-include="'App/Configuration/MenuManagement/_MenuPartial.html'"></li>
                    </ol>
                </div>
            </div>
            <div class="col-md-5">
                <div class="box box-solid">
                    <div class="box-header">
                        <i class="fa fa-bars"></i>
                        <h3 class="box-title">编辑菜单</h3>
                    </div>
                    <form class="form">
                        <div class="form-group">
                            <label for="name">菜单名称:</label>
                            <input class="form-control" type="text" id="name" 
                                   ng-model="selectedMenu.name">
                        </div>
                        <div class="form-group">
                            <label for="icon">菜单图标:</label>
                            <input class="form-control" type="text" id="icon" 
                                   ng-model="selectedMenu.icon">
                        </div>
                        <div class="form-group">
                            <label for="templateUrl">菜单路径:</label>
                            <input class="form-control" type="text" id="templateUrl" 
                                   ng-model="selectedMenu.templateUrl">
                        </div>
                        <div class="pull-right">
                            <a ng-click="addMenu()"
                               class="btn btn-social btn-instagram margin-r-5">
                                <i class="fa fa-plus margin-r-5"></i>新增
                            </a>
                            <a ng-click="save(navMenus)"
                               ng-disabled="submitting"
                               class="btn btn-social btn-instagram">
                                <i class="fa fa-save margin-r-5"></i>保存
                            </a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</section>
```
最后，我们实现MenuManagementController控制器逻辑：
```javascript
app.controller('MenuManagementController', ['$scope', function ($scope) {
    //编辑菜单
    $scope.editMenu = function (item) {
        $scope.selectedMenu = item;
    };
    //新增菜单
    $scope.addMenu = function () {
        var newMenu = { name: "<新增菜单>", icon: "fa-circle-o", templateUrl: "" };
        $scope.navMenus.push(newMenu);
        $scope.selectedMenu = newMenu;
    };
    //删除菜单
    $scope.deleteMenu = function (item, $event) {
        $.confirm({
            icon: 'fa fa-info',
            title: '删除',
            content: '确认删除菜单[' + item.name + ']？',
            type: 'dark',
            closeIcon: true,
            typeAnimated: true,
            buttons: {
                confirm: {
                    text: '确定',
                    btnClass: 'btn-dark',
                    action: function () {
                        $($event.target).closest('li').remove();
                    }
                },
                cancel: {
                    text: '取消',
                    btnClass: 'btn-dark'
                }
            }
        });
    };
    //保存菜单
    $scope.save = function (menus) {
        $scope.submitting = true;
        $.ajax({
            type: 'POST',
            url: '/Configuration/MenuManagement/Save',
            data: {},
            success: function (data) {
                //TODO:
            },
            complete: function () {
                $scope.submitting = false;
                $scope.$apply();
            }
        });
    }
    $scope.selectedMenu = {};
    //加载菜单
    $.ajax({
        type: 'GET',
        url: '/Configuration/MenuManagement/GetMenus',
        success: function (data) {
            $scope.navMenus = data;
            $scope.$apply();
            setTimeout(function () {
                $('.dd').nestable();
            }, 100);
        }
    });
}]);
```
简单说下大体的加载流程：用户点击左侧导航菜单-->angular-ui-router会根据咱们site.js中的路由配置，找到对应的MenuManagement.html页面进行局部刷新-->根据视图中的控制器MenuManagementController，执行对应控制器中的逻辑并返回数据，由angularjs绑定到视图-->内容区域获取到绑定后的视图，在内容区域显示。
最终菜单管理页面效果：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180129144020406-2048683542.png)

### 网站性能优化
我们已经将网站改造成单页应用，用户体验已经有了很大的提高，但是还是有许多值得优化的地方。由于云服务器提供的带宽非常有限，有时资源和图片下载稍微有点慢的情况，会导致整个体验会非常不好。当然，优化网站的手段非常多，实际情况往往比较复杂，那针对本人的网站，这里列出我自己此次实际过程中采取的优化方法，跟大家分享下。

#### 引入CDN资源
之前我们访问css/js资源，我们都是直接去=访问的是网站服务器，这样的话，在带宽不足的情况下，下载特别慢，另外也占用了其他html元素和图片下载时间，比如bootstrap.min.css文件，可能就需要几秒的下载时间，一但css/js文件多的情况下，整体页面下载经常超过20s。
那像这种经常使用的外部库文件，现在有许多免费的前端开源项目 CDN 加速服务，可以提供我们稳定、快速访问这些库文件的功能，我们直接引用这些CDN服务即可：
```html
<script src="https://cdn.bootcss.com/jquery/3.3.1/jquery.min.js"></script>
<script src="https://cdn.bootcss.com/jquery-cookie/1.4.1/jquery.cookie.min.js"></script>
<script src="https://cdn.bootcss.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
<script src="https://cdn.bootcss.com/angular.js/1.6.8/angular.min.js"></script>
<script src="https://cdn.bootcss.com/angular-ui-router/1.0.3/angular-ui-router.min.js"></script>
<script src="https://cdn.bootcss.com/spin.js/2.3.2/spin.min.js"></script>
<script src="https://cdn.bootcss.com/Ladda/1.0.5/ladda.min.js"></script>
<script src="https://cdn.bootcss.com/angular-ladda/0.4.3/angular-ladda.min.js"></script>
<script src="https://cdn.bootcss.com/jquery_lazyload/1.9.7/jquery.lazyload.min.js"></script>
<script src="https://cdn.bootcss.com/Nestable/2012-10-15/jquery.nestable.min.js"></script>
<script src="https://cdn.bootcss.com/jquery-confirm/3.3.2/jquery-confirm.min.js"></script>
<script src="https://cdn.bootcss.com/Chart.js/2.7.1/Chart.min.js"></script>
<script src="https://cdn.bootcss.com/jquery-sparklines/2.1.2/jquery.sparkline.min.js"></script>
<script src="https://cdn.bootcss.com/moment.js/2.20.0/moment.min.js"></script>
<script src="https://cdn.bootcss.com/moment.js/2.20.0/locale/zh-cn.js"></script>
<script src="https://cdn.bootcss.com/bootstrap-daterangepicker/2.1.27/daterangepicker.min.js"></script>
<script src="https://cdn.bootcss.com/jQuery-slimScroll/1.3.8/jquery.slimscroll.min.js"></script>
<script src="https://cdn.bootcss.com/fastclick/1.0.6/fastclick.min.js"></script>
<script src="https://cdn.bootcss.com/iCheck/1.0.2/icheck.min.js"></script>
<script src="https://cdn.bootcss.com/pace/1.0.2/pace.min.js"></script>
```
```html
<link rel="stylesheet" href="https://cdn.bootcss.com/bootstrap/3.3.7/css/bootstrap.min.css" />
<link rel="stylesheet" href="https://cdn.bootcss.com/Ladda/1.0.5/ladda-themeless.min.css" />
<link rel="stylesheet" href="https://cdn.bootcss.com/jquery-confirm/3.3.2/jquery-confirm.min.css" />
<link rel="stylesheet" href="https://cdn.bootcss.com/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="https://cdn.bootcss.com/bootstrap-daterangepicker/2.1.27/daterangepicker.min.css" />
<link rel="stylesheet" href="https://cdn.bootcss.com/ionicons/4.0.0-9/css/ionicons.min.css">
<link rel="stylesheet" href="https://cdn.bootcss.com/iCheck/1.0.2/skins/all.css" />
<link rel="stylesheet" href="https://fonts.cat.net/css?family=Source+Sans+Pro:300,400,600,700,300italic,400italic,600italic" />
```
引入后，我们监测下网络传输，可以看到，现在访问这些资源直接从CDN服务器中去取，大大提高了访问速度：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180129145513109-1859896302.png)
 
#### 使用对象存储服务
网站难免包含一些图片或稍微大一点的资源，几十kb到几M。没有缓存情况下，访问这些资源，我那可怜的带宽基本就占用差不多了，打开这种界面，经常就卡死或超时很严重。其实国内外很多云服务器服务商已经提供了这种解决方案，比如云存储服务。您可以将任意数量和形式的非结构化数据存入对象存储服务，并对数据进行管理和处理，满足各类场景的存储需求。
我们将图片存储到申请的对象存储服务中，这样我们访问网站图片的时候，就可以直接访问云存储服务器。再来看下访问速度，可以明显看出，现在图片下载速度控制在几百ms内，比之前几秒甚至十几秒才能下载一张图片，有了很大的性能提高。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180129155620265-1174147050.png)

#### 图片延迟加载
相对来说，一般图片算是比较大的文件，往往网页传输过程中，占了很大的带宽，如果一个页面图片比较多，出现图片集中加载的时候，网站整体感觉加载偏慢。
我们考虑用图片延迟加载的方法，只有滚动条快要滚动到图片位置时，才去加载对应的图片，否则暂时不需要加载图片，因为视图区域尚未存在改图片，即使加载了也看不到。
这里我们需要引入jquery.lazyload.min.js，在需要延迟加载的图片，实现对应的代码：`$("img.lazyload").lazyload()`;
监测一下网络传输，刚开始未加载图片，发现只有滚动条到达图片内容区域时，才会实时加载图片，相对来说，它帮助减轻服务器负载。

#### 合并压缩资源
为了合理的管理自己的代码，我们可以将css和js文件打包并压缩，这样我们可以将所有的css或js压缩成1个文件，文件体积也比原先小很多。
.Net Core已经提供了合并和压缩资源的工具，我们在程序包管理控制台，安装BundlerMinifier工具：`Install-Package BundlerMinifier.Core -Version 2.6.362`
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180129163856765-1522063145.png)
安装完成后，我们配置根目录下的bundleconfig.json，关于BundlerMinifier的使用方法和配置说明，参考<a href="https://docs.microsoft.com/en-us/aspnet/core/client-side/bundling-and-minification?tabs=visual-studio%2Caspnetcore2x" target="_blank">官方文档</a>：
```bash
[
  {
    "outputFileName": "wwwroot/dist/bundles.min.css",
    // An array of relative input file paths. Globbing patterns supported
    "inputFiles": [
      "wwwroot/css/skins/_all-skins.css",
      "wwwroot/css/adminlte.css",
      "wwwroot/css/site.css"
    ]
  },
  {
    "outputFileName": "wwwroot/dist/bundles.min.js",
    "inputFiles": [
      "wwwroot/js/adminlte.js",
      "wwwroot/js/site.js",
      "wwwroot/App/**/*.js"
    ],
    // Optionally specify minification options
    "minify": {
      "enabled": true,
      "renameLocals": true
    },
    // Optionally generate .map file
    "sourceMap": false
  }
]
```
编译代码，可以看到会自动将配置的所有css和js打包：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180129164200765-1881841796.png)
这里注意一个小细节，angular依赖注入的js文件，必须严格按照标准格式来写，否则的话，打包后会执行报错。
我们可以设置在开发环境下，用原始的css/js资源，方便调试，发布时用打包后的资源
```html
<environment names="Development">
    <script>window.environment = 'Development'</script>
    <script src="~/js/adminlte.js"></script>
    <script src="~/js/site.js"></script>
    <script src="~/App/Home/Home.js"></script>
    <script src="~/App/Home/Error.js"></script>
    <script src="~/App/Configuration/MenuManagement/MenuManagement.js"></script>
    <script src="~/App/Tools/ApiSimulator/ApiSimulator.js"></script>
    <script src="~/App/Tools/SiteAnalytics/SiteAnalytics.js"></script>
</environment>
<environment names="Production">
    <script>window.environment = 'Production'</script>
    <script src="~/dist/bundles.min.js" asp-append-version="true"></script>
</environment>
```
我们再监测下网站传输，可以看到，打包后的文件大小，较之前压缩了很多，很大提高了传输效率。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180129162706546-1336026234.png)

### 总结
我们最后看下优化后的效果，主页在没有缓存情况下，2s内就完成了加载，实际用户体验良好。 我们的单页模式改造和性能优化，顺利完成！
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180129160113343-1945808807.png)