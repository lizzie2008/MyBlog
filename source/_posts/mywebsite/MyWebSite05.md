---
title: .NET Core 搭建个人网站 | (5) Api模拟和网站分析
tags:
  - .NET Core
  - Entity Framework
  - 百度统计
  - Web API
categories: 软件工程
date: 2018-01-05
---
![avatar](https://mysite.bj.bcebos.com/images/articles/bcb3e1e4-255a-4d30-a44f-a578966056e8.jpg)

### 摘要
经过前面几章，我们的网站已经最基本的功能，接下来就是继续拓展其他的功能，这期一起来实现一个该网站流量分析的工具，统计出这个网站每天用户相关数据，不仅要满足了我们对流量统计数字的基本要求，并且用更简单的图形显示方式，让我们一目了然地获取页面热度、点击率信息等等。有了这个想法以后，那怎么实现呢，跟着笔者一步步来吧。
首先，需要考虑怎么才能获得用户访问网站时的相关数据呢？我们没必要自己去记录这些信息，目前已经有很多成熟的解决方案，提供捕获这些信息的免费接口，我们只用去访问这些接口就可以了。
在众多的方案中，有2款目前是比较流行的，分别是google analytics和百度统计。怎么说呢，google的确实是行业的大牛，不仅很成熟，而且有详尽的技术文档，数据收集过程很顺利，但是数据呈现需要fanqiang(原因你们懂得)，这块是硬伤，一个开放的网站没法要求用户都要fanqiang吧，也是由于这个原因，让我忍痛放弃了google analytics。那只有一个选择了：百度统计。想比较而言，百度统计的相关技术文档不忍多说，都是泪，笔者在坑中摸爬滚打很久，才弄明白怎么调用和访问。
方案定下来，因为我们要访问百度统计的开放API，以后会经常调用到外网的各种API，为了磨刀不费砍柴工，我们开发一个API的模拟工具，用来调试。
<!-- more -->

### API模拟工具

单独给API模拟工具增加一个菜单项，菜单管理-->新增菜单，增加一个根节点菜单下的一个子菜单：“工具箱”。以后一些常用的开发工具菜单，就放置该目录，然后在“工具箱”菜单下，再新建一个子菜单：“API模拟”。
那C#中怎么调用远程API方法呢，一般用HttpClient可以访问，这里我们稍微再封装一下，分为Get请求（传递url参数）和Post请求（传递url和content参数）：
```csharp
public static class HttpClientExtensions
{
    /// <summary>
    /// Get请求API
    /// </summary>
    /// <param name="client"></param>
    /// <param name="url"></param>
    /// <param name="jsonValue"></param>
    /// <param name="headers"></param>
    /// <returns></returns>
    public static async Task<string> HttpGetAsync(this HttpClient client, string url)
    {
        //初始化内容
        var responseMessage = await client.GetAsync(url);
        if (responseMessage.IsSuccessStatusCode)
        {
            return await responseMessage.Content.ReadAsStringAsync();
        }
        else
        {
            return $"访问API地址:{url}出错,错误代码:{responseMessage.StatusCode},错误原因:{responseMessage.ReasonPhrase}";
        }
    }


    /// <summary>
    /// Post请求API
    /// </summary>
    /// <param name="client"></param>
    /// <param name="url"></param>
    /// <param name="jsonValue"></param>
    /// <param name="headers"></param>
    /// <returns></returns>
    public static async Task<string> HttpPostAsync(this HttpClient client, string url, string jsonValue)
    {
        //初始化内容
        var content = new StringContent(jsonValue, Encoding.UTF8, "application/json");

        var responseMessage = await client.PostAsync(url, content);
        if (responseMessage.IsSuccessStatusCode)
        {
            return await responseMessage.Content.ReadAsStringAsync();
        }
        else
        {
            return $"访问API地址:{url}出错,参数:{jsonValue},错误代码:{responseMessage.StatusCode}
　　　　　　　,错误原因:{responseMessage.ReasonPhrase}";
        }
    }
```
参考上一章的内容中，我们将Api的相关配置，比如url地址，url请求类型，参数等等，都配置到json文件中，并定义相应的数据结构MyRequest。后续依赖注入IOptions<MyRequest> myRequest即可访问。
- Areas/Tools/Controllers创建对应的控制器ApiSimulatorController
- InvokApi方法：根据读取的Api请求类型，想远程API服务商发送请求并传递参数，返回json格式给UI端；
- Index方法：根据用户在下拉框中选择的Api，切换显示Api相关信息；
```csharp
[Area("Tools")]
public class ApiSimulatorController : AppController
{
    private readonly MyRequest _myRequest;

    public ApiSimulatorController(IOptions<MyRequest> myRequest)
    {
        _myRequest = myRequest.Value;
    }

    /// <summary>
    /// API模拟主页
    /// </summary>
    /// <param name="selectedApiCode"></param>
    /// <returns></returns>
    public IActionResult Index(string selectedApiCode = null)
    {
        UpdateDropDownList(selectedApiCode);
        if (selectedApiCode == null)
        {
            return View("Index", new ApiRequest());

        }
        var selectedApi = _myRequest.ApiRequests.FirstOrDefault(s => s.ApiCode == selectedApiCode);
        if (selectedApi != null && selectedApi.Methord == "POST")
            selectedApi.ApiDatas = selectedApi.ApiDatas.ToJsonString();
        return View("Index", selectedApi);
    }

    /// <summary>
    /// 调用API
    /// </summary>
    /// <param name="request"></param>
    /// <returns></returns>
    public async Task<IActionResult> InvokApi(ApiRequest request)
    {
        var hc = new HttpClient();

        if (request.Methord == "GET")
        {
            var getUrl = request.Url + "?";
            foreach (var para in request.ApiParas)
            {
                getUrl += "&" + para.ParaName + "=" + para.ParaValue;
            }

            ViewBag.SendContent = getUrl;
            ViewBag.ReturnResult = (await hc.HttpGetAsync(getUrl)).ToJsonString();
        }
        else if (request.Methord == "POST")
        {
            if (!string.IsNullOrEmpty(request.ApiDatas))
            {
                ViewBag.SendContent = request.Url;
                ViewBag.ReturnResult = (await hc.HttpPostAsync(request.Url, request.ApiDatas)).ToJsonString();
            }
            else
            {
                ModelState.AddModelError(string.Empty, "请输入Json格式请求参数");
            }
        }
        else
        {
            ModelState.AddModelError(string.Empty, "请求方式非法");
        }

        UpdateDropDownList(request.ApiCode);
        return View("Index", request);
    }

    /// <summary>
    /// 初始化下拉选择框
    /// </summary>
    private void UpdateDropDownList(string selectedApiCode = null)
    {
        List<SelectListItem> listApiName = new List<SelectListItem>();
        foreach (var request in _myRequest.ApiRequests.Select(s => new { s.ApiName, s.ApiCode }))
        {
            listApiName.Add(new SelectListItem
            {
                Value = request.ApiCode,
                Text = request.ApiName,
                Selected = request.ApiCode == selectedApiCode
            });
        }
        ViewBag.ApiCodes = listApiName;
    }
}
```
Areas/Tools/Views创建对应的视图Index
```html
<div class="form-group">
    <label asp-for="ApiCode">API名称:</label>
    <select asp-for="ApiCode" class="form-control input-sm select2" asp-items="ViewBag.ApiCodes">
        <option value="">-- 请选择 --</option>
    </select>
</div>
<div class="form-group">
    <label asp-for="Url">API地址:</label>
    <input asp-for="Url" class="form-control input-sm" readonly>
</div>
<div class="form-group">
    <label asp-for="Methord">请求方式:</label>
    <input asp-for="Methord" class="form-control input-sm" readonly>
</div>
<div class="form-group">
    <label for="params" class="">请求参数：</label>
    @if (Model.Methord == "GET")
    {
        <div style="overflow-x:auto;">
            <table class="table table-bordered table-striped table-condensed" id="params">
                <thead>
                    <tr>
                        <td>参数名</td>
                        <td>类型</td>
                        <td>是否必填</td>
                        <td>说明</td>
                        <td>值</td>
                    </tr>
                </thead>
                <tbody>
                    @for (var i = 0; i < Model.ApiParas.Count(); i++)
                    {
                        <tr>
                            <td>
                                <span>@Model.ApiParas[i].ParaName</span>
                                @Html.TextBoxFor(a => a.ApiParas[i].ParaName,
                               new { @class = "form-control input-sm", type = "hidden" })
                            </td>
                            <td>
                                <span> @Model.ApiParas[i].ParaType</span>
                                @Html.TextBoxFor(a => a.ApiParas[i].ParaType,
                               new { @class = "form-control input-sm", type = "hidden" })
                            </td>
                            <td>
                                <span>@(Model.ApiParas[i].Required ? "是" : "否")</span>
                                @Html.TextBoxFor(a => a.ApiParas[i].Required,
                               new { @class = "form-control input-sm", type = "hidden" })
                            </td>
                            <td>
                                <span>@Model.ApiParas[i].Description</span>
                                @Html.TextBoxFor(a => a.ApiParas[i].Description,
                               new { @class = "form-control input-sm", type = "hidden" })
                            </td>
                            <td>
                                @Html.TextBoxFor(a => a.ApiParas[i].ParaValue,
                               new { @class = "form-control input-sm" })
                        </td>
                    </tr>
                    }
                </tbody>
            </table>
        </div>}
    else if ((Model.Methord == "POST"))
    {
        @Html.TextAreaFor(m => m.ApiDatas, 
       new { @class = "form-control", rows = "8", placeholder = "输入Json格式 ..." })
    }
</div>
<button type="submit" class="btn btn-success"><i class="fa fa-send-o margin-r-5"></i>发送请求</button>
```
json文件中增加“手机号码归属地”、“百度统计”相关API的配置，我们来测试一下：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180110133216551-1667812437.gif)

### 流量分析工具
有了上面API模拟工具，现在可以很方便的调试我们百度统计接口了。百度统计是怎么获取这些网站用户访问的相关信息的呢？原理其实很简单，百度针对你的注册服务提供一段js代码，其中包含标识你在百度统计的id。你在网页中添加这段代码后，每当用户访问该网站时，会下载这段js脚本，加载完毕和离开页面的时候，都会发送一次请求和传递参数，百度统计服务中心从而捕获到这些信息，维护在服务器中。调用百度统计API传递你的id，会根据id返回你的网站对应分析数据。
关于流量统计原理，有兴趣详见<a href="http://www.mahaixiang.cn/seoyjy/123.html" target="_blank">揭秘百度统计和Google Analytics的工作原理</a>。

#### 注册百度统计
知道了原理，那首先第一步我们注册百度统计用户。注册完成后，我们找到 代码管理-->代码获取，将百度统计帮你自动生成好的js脚本复制过来，粘贴到site.js文件中。由于_layout母版页引用了site.js文件，这样的话，网站域名下所有的用户访问，都会被统计。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180110140802254-295142522.png)
安装完百度统计的代码，发布网站程序，可以用百度统计中代码检查，看看自己统计代码有没有被正确的安装，如果安装成功，估计20分钟后，就可以在百度统计中查看网站的访问情况了。当然，你也可以添加多个域名的网站。
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180110141213629-173507601.png)

#### 申请Tongji API数据导出
现在我们很方便的在百度统计中查看各种统计数据了，比如流量分析、来源分析、访问分析、转化分析等等，接下来需要获取这些数据，来移植到我们自己的网站中来。百度提供了Tongji API，我们可以调用API来查询自己网站的分析数据，从而进一步组织增加的分析视图了。
要访问Tongji API，需要提供一个token值，这个需要开通申请，在 百度统计-->管理-->其他设置-->数据导出服务 中，请求开通，开通后百度统计会提供给你一个token字符串，以后用这个token就可以访问Tongji API。Tongji API具体的请求格式说明详见：<a href="https://tongji.baidu.com/open/api/more?p=tongjiapi_getData.tpl" target="_blank">百度统计开发平台</a>。
比如我们需要请求站点列表，使用API模拟工具，请求类型POST，url地址：
`https://api.baidu.com/json/tongji/v1/ReportService/getSiteList`，这里注意请求的data参数格式应该如下：
```bash
{
    "header": {
        "account_type": 1,
        "password": "<密码>",
        "token": "<token>",
        "username": "<用户名>"
    },
    "body": {}
}
```
输入百度统计的用户名和密码及访问使用的token，即可正常访问我们的注册的所有站点，这里我们可以拿到站点的site_id(也可以通过百度统计页面查看)，后面请求该站点的分析数据会用到。

#### 地域分布数据获取
百度统计提供的数据类型很多，我们选取其中一个来试验下效果。比如我们需要获得访问网站用户的地域信息，不同省份的用户访问情况。使用API模拟工具调试：请求类型POST，url地址：
`https://api.baidu.com/json/tongji/v1/ReportService/getData`，请求的data参数格式如下：
```bash
{
    "header": {
        "account_type": 1,
        "password": "<密码>",
        "token": "<token>",
        "username": "<用户名>"
    },
    "body": {
        "site_id": <站点id>,
        "method": "visit/district/a",
        "start_date": "30daysago",
        "end_date": "today",
        "metrics": "pv_count,pv_ratio,visit_count,visitor_count,new_visitor_count,new_visitor_ratio,
　　　　　　　　　　　　ip_count,bounce_ratio,avg_visit_time,avg_visit_pages,trans_count,trans_ratio",
        "order": "pv_count,desc",
        "max_results": 0
    }
}
```
可以看到，正常返回按照不同省份区域的网站统计数据。
实现控制器逻辑：按照上面提供的json格式，配置到json文件中，并定义MyRequest对象，映射我们所有的API请求，MyRequest存放的是所有API请求的配置信息，通过API请求的id，加载不同的API配置信息。Areas/Tools/Controllers创建对应的控制器SiteAnalyticsController，主要实现GetVisitDistrictAnalytics方法，用来根据时间范围，获取相应的区域分析json数据：
```csharp
[Area("Tools")]
public class SiteAnalyticsController : AppController
{
    private readonly IList<ApiRequest> _requests;

    public SiteAnalyticsController(IOptions<MyRequest> myRequest)
    {
        _requests = myRequest.Value.ApiRequests;
    }

    public IActionResult Index()
    {
        return View();
    }

    /// <summary>
    /// 获取百度访客区域统计数据
    /// </summary>
    /// <returns></returns>
    public async Task<JsonResult> GetVisitDistrictAnalytics(string startDate, string endDate)
    {
        var hc = new HttpClient();
        var request = _requests.FirstOrDefault(s => s.ApiCode == "BaiduGetVisitDistrict");
        var data = request.ApiDatas.Replace("30daysago", startDate).Replace("today", endDate);
        return Json(await hc.HttpPostAsync(request.Url, data));
    }

    /// <summary>
    /// 获取百度趋势分析数据
    /// </summary>
    /// <returns></returns>
    public async Task<JsonResult> GetTrendAnalytics(string startDate, string endDate)
    {
        var hc = new HttpClient();
        var request = _requests.FirstOrDefault(s => s.ApiCode == "BaiduGetTrend");
        var data = request.ApiDatas.Replace("30daysago", startDate).Replace("today", endDate);
        return Json(await hc.HttpPostAsync(request.Url, data));
    }
}
```

#### 区域分析显示
有了区域分析的数据，接下来考虑要怎么显示。
我们设计各个省份的访问量，可以通过地图展现，根据实际访问量的多少，通过颜色的深浅表现；
- 表格的形式，具体显示不同省份的访问量和占比；
- 柱状图的形式，显示最近7天的访问量趋势；
- 地图展现，采用jvectormap插件，它是矢量地图，且有自己的API，还是非常好用的，具体使用方法，推荐访问官网：<a href="http://jvectormap.com/" target="_blank">http://jvectormap.com/</a>

Areas/Tools/Views创建视图Index：
```html
<!-- 分布地图 -->
<div class="col-md-6 col-sm-6">
    <div class="box-body">
        <div id="map-markers" class="text-center" style="height: 420px;">
            <div>浏览量地域分布</div>
        </div>
    </div>
</div>
<!-- 分布表格 -->
<div class="col-md-4 col-sm-4" style="height: 440px; overflow: auto;">
    <table class="table table-bordered" id="districtTable">
        <tbody>
            <tr>
                <th style="width: 10px">#</th>
                <th>省份</th>
                <th>浏览量(PV)</th>
                <th>占比</th>
            </tr>
        </tbody>
    </table>
</div>
<!-- 近一周统计 -->
<div class="col-md-2 col-sm-2">
    <div class="pad box-pane-right bg-green" style="min-height: 280px">
        <div class="description-block margin-bottom" id="trend_pv_count">
            <div class="sparkbar pad" data-color="#fff"></div>
            <h5 class="description-header"></h5>
            <span class="description-text">浏览量(PV)</span>
        </div>
        <div class="description-block margin-bottom" id="trend_visitor_count">
            <div class="sparkbar pad" data-color="#fff"></div>
            <h5 class="description-header"></h5>
            <span class="description-text">访客数(UV)</span>
        </div>
        <div class="description-block" id="trend_ip_count">
            <div class="sparkbar pad" data-color="#fff"></div>
            <h5 class="description-header"></h5>
            <span class="description-text">IP数</span>
        </div>
        <div class="description-block" id="trend_avg_visit_time">
            <div class="sparkbar pad" data-color="#fff"></div>
            <h5 class="description-header"></h5>
            <span class="description-text">平均访问时长</span>
        </div>
    </div>
</div>
```
SiteAnalytics.js中，定义jvectormap显示样式，动态获取区域分析数据后， 设置数据集mapObject.series.regions[0].setValues(visitorsData);
```javascript
var options = {
    map: 'cn_mill',
    backgroundColor: 'transparent',
    regionStyle: {
        initial      : {
        fill            : 'rgba(210, 214, 222, 1)',
        'fill-opacity'  : 1,
        stroke          : 'none',
        'stroke-width'  : 0,
        'stroke-opacity': 1
      },
      hover        : {
        'fill-opacity': 0.7,
        cursor        : 'pointer'
      },
      selected     : {
        fill: 'yellow'
      },
      selectedHover: {}
    },
    series: {
        markers: [{
            attribute: 'fill',
            scale: ['#C8EEFF', '#0071A4'],
            normalizeFunction: 'polynomial',
            values: [408, 512, 550, 781],
            legend: {
                vertical: true
            }
        }],
        regions: [
            {
                scale: ['#ebf4f9', '#92c1dc'],
                normalizeFunction: 'polynomial'
            }
        ]
    },
    onRegionLabelShow: function (e, el, code) {
        var html = '';
        html += '<div style="width:120px;">';
        html += '<div style="border-bottom:1px solid;padding-bottom:5px;">' + el.html() + '</div>';
        html += '<div style="margin-top:5px;"><i class="fa fa-circle text-success margin-r-5"></i>浏览量(PV)<span class="pull-right">';
        if (typeof visitorsData[code] != 'undefined') {
            html += visitorsData[code];
        } else {
            html += 0;
        }
        html += '</div>';
        html += '<div style="margin-top:5px;"><i class="fa fa-circle text-primary margin-r-5"></i>占比<span class="pull-right">';
        if (typeof pecentData[code] != 'undefined') {
            html += pecentData[code];
        } else {
            html += 0;
        }
        html += ' %</div>';
        el.html(html);
    }
}

$('#map-markers').vectorMap(options);
```

### 小结
用地图显示区域分析功能至此就已经大体完成，我们加上图表数据的显示，这样内容更丰富些，最后，我们看下效果：
![avatar](https://mysite.bj.bcebos.com/images/201801/371995-20180110153340613-1902434699.gif)