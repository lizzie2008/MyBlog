---
title: .NET Core 搭建个人网站 | (3) 菜单管理
tags:
  - .NET Core
  - Entity Framework
categories: 软件工程
date: 2018-01-03
---
![avatar](https://bj.bcebos.com/v1/mysite/images/articles/9c93ff41-2251-428d-9a13-d553c20b6d65.jpg)

### 摘要
上一章，我们实现了用户的注册和登录，登录之后展示的是我们的主页，页面的左侧是多级的导航菜单，定位并展示用户需要访问的不同页面。目前导航菜单是写死的，考虑以后菜单管理的便捷性，我们这节实现下可视化配置菜单的功能，这样以后我们可以动态的配置导航菜单，不用再编译发布网站程序了。  
<!-- more -->

### 增加后台管理模块
第1步，左侧导航菜单中，添加后台管理模块，用作管理员登录后，可以进行一些后台管理的操作，当然，目前还没有权限控制（后期加入），所以对所有用户可见。大概菜单结构如下：
![avatar](https://bj.bcebos.com/v1/mysite/images/201801/371995-20171228105813566-843439505.png)
有了菜单项，我们还需要控制视图的跳转，所以，接下来需要写对应的控制器和视图。
为了将相关功能组织成一组单独命名空间（路由）和文件夹结构（视图），解决方案中右键添加区域（Area）,取名后台管理（Configuration），代表后台管理模块，.Net Core脚手架（scaffold）自动帮我们实现了目录划分：控制器（Controllers）、模型（Models）、视图（Views）

#### 菜单模型定义
菜单的基本属性有：菜单名称、菜单类型、菜单的图标样式、菜单url路径。另外，菜单在逻辑上是树状结构，但是要在物理数据库中存储，需要进行扁平化处理，每个菜单项有个父菜单属性（根节点的父菜单为空），还有同一父节点底下，在组类的排序属性，定义如下：
```csharp
/// <summary>
/// 菜单
/// </summary>
public class Menu
{
    /// <summary>
    /// 主键ID
    /// </summary>
    [DatabaseGenerated(DatabaseGeneratedOption.None)]
    [Required(ErrorMessage = "请输入菜单编号")]
    public string Id { get; set; }

    /// <summary>
    /// 菜单名称
    /// </summary>
    [Required(ErrorMessage = "请输入菜单名称")]
    [StringLength(256)]
    public string Name { get; set; }

    /// <summary>
    /// 父级ID
    /// </summary>
    [DisplayFormat(NullDisplayText = "无")]
    public string ParentId { get; set; }

    /// <summary>
    /// 菜单组内排序
    /// </summary>
    [Range(0, 99, ErrorMessage = "请选择1-99范围内的整数")]
    public int IndexCode { get; set; }

    /// <summary>
    /// 菜单路径
    /// </summary>
    [StringLength(256)]
    [DisplayFormat(NullDisplayText = "无")]
    public string Url { get; set; }

    /// <summary>
    /// 类型：0导航菜单；1操作按钮。
    /// </summary>
    [Required(ErrorMessage = "请选择菜单类型")]
    public MenuTypes? MenuType { get; set; }

    /// <summary>
    /// 菜单图标名称
    /// </summary>
    [Required(ErrorMessage = "请输入菜单图标")]
    [StringLength(50)]
    public string Icon { get; set; }

    /// <summary>
    /// 菜单备注
    /// </summary>
    public string Remarks { get; set; }
}
/// <summary>
/// 菜单类型
/// </summary>
public enum MenuTypes
{
    /// <summary>
    /// 导航菜单
    /// </summary>
    导航菜单,
    /// <summary>
    /// 操作菜单
    /// </summary>
    操作菜单
}
```
有了我们的菜单模型，在控制器目录中，我们右键建立第1个自己的控制器，取名MenuController，用来菜单管理，上下文选取定义好的Menu模型，还是利用脚手架，自动帮我们生成增删改查对应的后来逻辑和视图。此时，我们把菜单导向该控制器，其实是可以正常访问的，不过还远远达不到我们的要求，所以我们还得完善下自动生成的代码。
#### 菜单控制器改写
为了方便今后的拓展，新增一个AppController控制器，继承Controller，以后所有的控制器，都继承于AppController，方便一些公共的方法调用。
.Net Core有个比较方便的一点，就是实现了构造器的依赖注入，这样我们不用像以前那样手工New一个DBContext对象，直接在控制器将需要的DBContext注入，调用的时候，直接访问注入的对象即可，有关依赖注入的知识，这里就不在多说了，有兴趣大家可以了解一下：.Net Core依赖注入
首先，在ApplicationDbContext添加Menu数据集
```csharp
public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
    }

    public DbSet<ApplicationUser> ApplicationUsers { get; set; }

    public DbSet<Menu> Menus { get; set; }
}
```
这里我们修改下MenuController构造器：
```csharp
private readonly ApplicationDbContext _context;

public MenuController(ApplicationDbContext context, INavMenuService navMenuService)
{
    _context = context;
    _NavMenuService = navMenuService;
}　
```
为了后面方便统一提供下拉框选择，这里实现一个下拉框初始化方法：
```csharp
/// <summary>
/// 初始化下拉选择框
/// </summary>
/// <param name="menu"></param>
private void UpdateDropDownList(Menu menu = null)
{
    var menusParent = _context.Menus.AsNoTracking().Where(s => s.MenuType == MenuTypes.导航菜单);
    List<SelectListItem> listMenusParent = new List<SelectListItem>();
    foreach (var menuParent in menusParent)
    {
        listMenusParent.Add(new SelectListItem
        {
            Value = menuParent.Id,
            Text = menuParent.Id + $"({menuParent.Name})",
            Selected = (menu != null && menuParent.Id == menu.ParentId)
        });
    }
    ViewBag.ParentIds = listMenusParent;

    if (menu == null)
    {
        ViewBag.MenuTypes = MenuTypes.导航菜单.GetSelectListByEnum();
    }
    else
    {
        ViewBag.MenuTypes = MenuTypes.导航菜单.GetSelectListByEnum(Convert.ToInt32(menu.MenuType));
    }
}
```
#### 列表页改写
控制器调整：增加查询传入参数，根据参数筛选查询结果；
```csharp
/// <summary>
/// 列表页
/// </summary>
/// <param name="query"></param>
/// <returns></returns>
public async Task<IActionResult> Index(MenuIndexQuery query)
{
    var menus = _context.Menus.AsNoTracking();
    if (!string.IsNullOrEmpty(query.QName))
    {
        menus = menus.Where(s => s.Name.Contains(query.QName.Trim()));
    }
    if (!string.IsNullOrEmpty(query.QId))
    {
        menus = menus.Where(s => s.Id.Contains(query.QId.Trim()));
    }
    if (!string.IsNullOrEmpty(query.QParentId))
    {
        menus = menus.Where(s => s.ParentId == query.QParentId.Trim());
    }
    if (query.QMenuType != null)
    {
        menus = menus.Where(s => s.MenuType == query.QMenuType);
    }

    UpdateDropDownList();
    return View(new MenuIndexVM { Menus = await menus.ToListAsync(), Query = query });
}
```
视图调整：用户点击删除时，弹出确认框，调用Ajax方式删除数据，不再通过页面跳转；

```html
@using MyWebSite.ViewModels
@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers

@model MyWebSite.Areas.Configuration.ViewModels.MenuIndexVM
@{
    ViewData["Title"] = "菜单列表";

    var breadcrumb = new BreadCrumb("菜单列表", "Version 2.0", new List<NavCrumb>
    {
        new NavCrumb(name:"菜单管理",url: "/Configuration/Menu"),
        new NavCrumb(name:"菜单列表"),
    });
    ViewBag.BreadCrumb = breadcrumb;

    Layout = "~/Views/Shared/_Layout.cshtml";
}

<div class="row">
    <div class="col-xs-12">
        <div class="box with-border">
            <form class="form" asp-action="Index">
                <div class="box-header">
                    <h3 class="box-title"><i class="fa fa-search margin-r-5">查询条件</i></h3>
                    <div class="box-tools pull-right">
                        <button type="submit" class="btn btn-success margin-r-5"><i class="fa fa-search margin-r-5"></i>查询</button>
                        <a class="btn btn-primary" href="/Configuration/Menu/Create"><i class="fa fa-plus margin-r-5"></i>新建</a>
                    </div>
                    <div asp-validation-summary="All" class="text-danger"></div>
                    <div class="row">
                        <div class="col-md-3">
                            <div class="form-group">
                                <label asp-for="Query.QName">菜单名称:</label>
                                <input asp-for="Query.QName" class="form-control input-sm">
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="form-group">
                                <label asp-for="Query.QId">菜单编码:</label>
                                <input asp-for="Query.QId" class="form-control input-sm">
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="form-group">
                                <label asp-for="Query.QParentId">父级菜单:</label>
                                <select asp-for="Query.QParentId" class="form-control input-sm select2" asp-items="ViewBag.ParentIds">
                                    <option value="">-- 请选择 --</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <div class="form-group">
                                <label asp-for="Query.QMenuType">菜单类型:</label>
                                <select asp-for="Query.QMenuType" class="form-control input-sm select2" asp-items="ViewBag.MenuTypes">
                                    <option value="">-- 请选择 --</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
            <div class="box-body">
                <table class="table table-bordered table-hover" style="width: 100%">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>菜单名称</th>
                            <th>菜单编号</th>
                            <th>父级编号</th>
                            <th>组内排序</th>
                            <th>菜单类型</th>
                            <th>菜单图标</th>
                            <th>菜单路径</th>
                            <th>操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        @{
                            var index = 0;
                        }
                        @foreach (var item in Model.Menus)
                        {
                            index++;
                            <tr>
                                <td>
                                    @index.ToString("D3")
                                </td>
                                <td>
                                    @Html.ActionLink(@item.Name, "Details", new { id = @item.Id })
                                </td>
                                <td>
                                    <span>@item.Id</span>
                                </td>
                                <td>
                                    <span>@Html.DisplayFor(modelItem => item.ParentId)</span>
                                </td>
                                <td>
                                    <span>@item.IndexCode</span>
                                </td>
                                <td>
                                    <span>@item.MenuType</span>
                                </td>
                                <td>
                                    <i class="fa @item.Icon" data-toggle="tooltip" data-placement="right" title="@item.Icon"></i>
                                </td>
                                <td>
                                    <i class="fa fa-ellipsis-h" data-toggle="tooltip" data-placement="top" title="@Html.DisplayFor(modelItem => item.Url)"></i>
                                </td>
                                <td>
                                    @Html.ActionLink("编辑", "Edit", new { id = @item.Id })|
                                    @Html.ActionLink("详情", "Details", new { id = @item.Id })|
                                    <a href="#" onclick="onDelete('@item.Id', '@item.Name');">删除</a>
                                </td>
                            </tr>
                        }
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

@section Scripts{
    @{await Html.RenderPartialAsync("_ValidationScriptsPartial");}
    <script>
        function onDelete(id, name) {
            BootstrapDialog.show({
                message: '确认删除菜单-' + name + '[' + id + ']？',
                size: BootstrapDialog.SIZE_SMALL,
                draggable: true,
                buttons: [
                    {
                        icon: 'fa fa-check',
                        label: '确定',
                        cssClass: 'btn-primary',
                        action: function (dialogRef) {
                            dialogRef.close();
                            $.ajax({
                                type: 'POST',
                                url: '/Configuration/Menu/Delete',
                                data: { id: id },
                                success: function () {
                                    location.reload();
                                }
                            });
                        }
                    }, {
                        icon: 'fa fa-close',
                        label: '取消',
                        action: function (dialogRef) {
                            dialogRef.close();
                        }
                    }
                ]
            });
        }
    </script>
}
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201801/371995-20171228141832616-1124577518.png)

#### 新建页改写
控制器调整：这里控制器有2个Create方法，一个是Http Get类型，用户列表页点新建时，跳转到该方法，另外一个是Http Post类型，用户填完新建的菜单信息后，点击保存，跳转到该方法。在Http Post方法中，为了防止页面over post，需要指定绑定的属性Bind ("Id, Name, ParentId, IndexCode, Url, MenuType, Icon, Remarks")，当然，也可以用TryUpdateModel()实现，以后再介绍；
```csharp
/// <summary>
/// 新建空白页面
/// </summary>
/// <returns></returns>
public IActionResult Create()
{
    var model = new Menu
    {
        Id = "MXX_XX_XX",
        IndexCode = 1,
        Icon = "fa-circle-o"
    };
    UpdateDropDownList();
    return View(model);
}

/// <summary>
/// 新建保存页面
/// </summary>
/// <param name="menu"></param>
/// <returns></returns>
[HttpPost]
public async Task<IActionResult> Create([Bind("Id,Name,ParentId,IndexCode,Url,MenuType,Icon,Remarks")] Menu menu)
{
    if (ModelState.IsValid)
    {
        if (!MenuExists(menu.Id))
        {
            _context.Add(menu);
            await _context.SaveChangesAsync();

            _NavMenuService.InitOrUpdate();
            return RedirectToAction(nameof(Index));
        }
        else
        {
            ModelState.AddModelError("Id", "菜单编号已存在，请修改菜单编号.");
        }
    }
    UpdateDropDownList(menu);
    return View(menu);
}
```
视图调整： 引入前端数据验证，并增加一些数据控制，比如菜单类型非操作菜单时，菜单路径不可编辑等等；
```html
@using MyWebSite.ViewModels
@using MyWebSite.Areas.Configuration.Models
@model MyWebSite.Areas.Configuration.Models.Menu

@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers

@{
    ViewData["Title"] = "菜单新建";

    var breadcrumb = new BreadCrumb("菜单新建", "Version 2.0", new List<NavCrumb>
    {
        new NavCrumb(name:"菜单管理",url: "/Configuration/Menu"),
        new NavCrumb(name:"菜单新建"),
    });
    ViewBag.BreadCrumb = breadcrumb;

    Layout = "~/Views/Shared/_Layout.cshtml";
}
<section class="content">
    <div class="row">
        <div class="col-md-8">
            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">新建</h3>
                </div>
                <form asp-action="Create">
                    <div asp-validation-summary="All" class="text-danger"></div>
                    <div class="box-body">
                        <div class="form-group col-md-6">
                            <label asp-for="Id">菜单编号</label>
                            <input asp-for="Id" class="form-control input-sm">
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Name">菜单名称</label>
                            <input asp-for="Name" class="form-control input-sm">
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="ParentId">父级菜单</label>
                            <select asp-for="ParentId" class="form-control input-sm select2" asp-items="ViewBag.ParentIds">
                                <option value="">-- 请选择 --</option>
                            </select>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="IndexCode">组内排序</label>
                            <input asp-for="IndexCode" class="form-control input-sm">
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="MenuType">菜单类型</label>
                            <select asp-for="MenuType" class="form-control input-sm" asp-items="ViewBag.MenuTypes">
                                <option value="">-- 请选择 --</option>
                            </select>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Icon">菜单图标</label>
                            <div class="input-group">
                                <span class="input-group-addon"><i id="IconfShow" class="fa @Model.Icon"></i></span>
                                <input asp-for="Icon" class="form-control input-sm">
                            </div>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Url">菜单路径</label>
                            @if (Model.MenuType == MenuTypes.操作菜单)
                            {
                                <input asp-for="Url" class="form-control input-sm">
                            }
                            else
                            {
                                <input asp-for="Url" class="form-control input-sm" readonly>
                            }
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Remarks">备注</label>
                            <input asp-for="Remarks" class="form-control input-sm">
                        </div>
                    </div>
                    <div class="box-footer">
                        <button type="submit" class="btn btn-primary"><i id="IconfShow" class="fa fa-save"></i> 保存</button>
                        <a asp-action="Index" class="btn btn-default"><i id="IconfShow" class="fa fa-undo"></i> 返回</a>
                    </div>
                </form>
            </div>

        </div>
    </div>
</section>
@section Scripts {
    <script src="~/js/Configuration/Menu.js"></script>
    @{await Html.RenderPartialAsync("_ValidationScriptsPartial");}
}
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201801/371995-20171228143555022-1598498622.png)

#### 详情页改写
控制器调整：不用大的调整，只是增加了下拉框的初始化工作 ；
```csharp
/// <summary>
/// 详情页
/// </summary>
/// <param name="id"></param>
/// <returns></returns>
public async Task<IActionResult> Details(string id)
{
    if (id == null)
    {
        return NotFound();
    }

    var menu = await _context.Menus
    .SingleOrDefaultAsync(m => m.Id == id);
    if (menu == null)
    {
        return NotFound();
    }

    UpdateDropDownList(menu);
    return View(menu);
}
```
视图调整：跟创建界面大体差不多， 只是控制属性字段不允许编辑，也不用数据验证；
```csharp
@using MyWebSite.ViewModels
@model MyWebSite.Areas.Configuration.Models.Menu

@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers

@{
    ViewData["Title"] = "菜单详情";

    var breadcrumb = new BreadCrumb("菜单详情", "Version 2.0", new List<NavCrumb>
    {
        new NavCrumb(name:"菜单管理",url: "/Configuration/Menu"),
        new NavCrumb(name:"菜单详情"),
        new NavCrumb(name:Model.Id),
    });
    ViewBag.BreadCrumb = breadcrumb;

    Layout = "~/Views/Shared/_Layout.cshtml";
}
<section class="content">
    <div class="row">
        <div class="col-md-8">
            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">详情</h3>
                </div>
                <form>
                    <div class="box-body">
                        <div class="form-group col-md-6">
                            <label asp-for="Id">菜单编号</label>
                            <input asp-for="Id" class="form-control input-sm" readonly>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Name">菜单名称</label>
                            <input asp-for="Name" class="form-control input-sm" readonly>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="ParentId">父级菜单</label>
                            <select asp-for="ParentId" class="form-control input-sm" asp-items="ViewBag.ParentIds" disabled>
                            </select>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="IndexCode">组内排序</label>
                            <input asp-for="IndexCode" class="form-control input-sm" readonly>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="MenuType">菜单类型</label>
                            <input asp-for="MenuType" class="form-control input-sm" readonly>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Icon">菜单图标</label>
                            <div class="input-group">
                                <span class="input-group-addon"><i id="IconfShow" class="fa @Model.Icon"></i></span>
                                <input asp-for="Icon" class="form-control input-sm" readonly>
                            </div>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Url">菜单路径</label>
                            <input asp-for="Url" class="form-control input-sm" readonly>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Remarks">备注</label>
                            <input asp-for="Remarks" class="form-control input-sm" readonly>
                        </div>
                    </div>
                    <div class="box-footer">
                        <a asp-action="Edit" asp-route-id="@Model.Id" class="btn btn-primary"><i id="IconfShow" class="fa fa-edit"></i> 编辑</a>
                        <a asp-action="Index" class="btn btn-default"><i id="IconfShow" class="fa fa-undo"></i> 返回</a>
                    </div>
                </form>
            </div>

        </div>
    </div>
</section>
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201801/371995-20171228150423834-586017278.png)

#### 编辑页面改写
控制器调整：也是有Http Get和Http Post方法，分别是开始编辑和编辑保存跳转的方法，同时加上防止over post字段绑定；
```csharp
/// <summary>
/// 开始编辑
/// </summary>
/// <param name="id"></param>
/// <returns></returns>
public async Task<IActionResult> Edit(string id)
{
    if (id == null)
    {
        return NotFound();
    }

    var menu = await _context.Menus.SingleOrDefaultAsync(m => m.Id == id);
    if (menu == null)
    {
        return NotFound();
    }

    UpdateDropDownList(menu);
    return View(menu);
}

/// <summary>
/// 编辑保存
/// </summary>
/// <param name="id"></param>
/// <param name="menu"></param>
/// <returns></returns>
[HttpPost]
public async Task<IActionResult> Edit(string id, [Bind("Id,Name,ParentId,IndexCode,Url,MenuType,Icon,Remarks")] Menu menu)
{
    if (id != menu.Id)
    {
        return NotFound();
    }

    if (ModelState.IsValid)
    {
        try
        {
            _context.Update(menu);
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!MenuExists(menu.Id))
            {
                return NotFound();
            }
            else
            {
                throw;
            }
        }
        _NavMenuService.InitOrUpdate();
        return RedirectToAction(nameof(Index));
    }

    UpdateDropDownList(menu);
    return View(menu);
}
```
视图调整：跟创建界面大体差不多，需要数据验证和数据控制；
```html
@using MyWebSite.ViewModels
@using MyWebSite.Areas.Configuration.Models
@model MyWebSite.Areas.Configuration.Models.Menu

@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers

@{
    ViewData["Title"] = "菜单编辑";

    var breadcrumb = new BreadCrumb("菜单编辑", "Version 2.0", new List<NavCrumb>
    {
        new NavCrumb(name:"菜单管理",url: "/Configuration/Menu"),
        new NavCrumb(name:"菜单编辑"),
        new NavCrumb(name:Model.Id),
    });
    ViewBag.BreadCrumb = breadcrumb;

    Layout = "~/Views/Shared/_Layout.cshtml";
}
<section class="content">
    <div class="row">
        <div class="col-md-8">
            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">编辑</h3>
                </div>
                <form asp-action="Edit">
                    <div asp-validation-summary="All" class="text-danger"></div>
                    <div class="box-body">
                        <div class="form-group col-md-6">
                            <label asp-for="Id">菜单编号</label>
                            <input asp-for="Id" class="form-control input-sm" readonly>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Name">菜单名称</label>
                            <input asp-for="Name" class="form-control input-sm">
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="ParentId">父级菜单</label>
                            <select asp-for="ParentId" class="form-control input-sm select2" asp-items="ViewBag.ParentIds">
                                <option value="">-- 请选择 --</option>
                            </select>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="IndexCode">组内排序</label>
                            <input asp-for="IndexCode" class="form-control input-sm">
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="MenuType">菜单类型</label>
                            <select asp-for="MenuType" class="form-control input-sm" asp-items="ViewBag.MenuTypes">
                                <option value="">-- 请选择 --</option>
                            </select>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Icon">菜单图标</label>
                            <div class="input-group">
                                <span class="input-group-addon"><i id="IconfShow" class="fa @Model.Icon"></i></span>
                                <input asp-for="Icon" class="form-control input-sm">
                            </div>
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Url">菜单路径</label>
                            @if (Model.MenuType == MenuTypes.操作菜单)
                            {
                                <input asp-for="Url" class="form-control input-sm">
                            }
                            else
                            {
                                <input asp-for="Url" class="form-control input-sm" readonly>
                            }
                        </div>
                        <div class="form-group  col-md-6">
                            <label asp-for="Remarks">备注</label>
                            <input asp-for="Remarks" class="form-control input-sm">
                        </div>
                    </div>
                    <div class="box-footer">
                        <button type="submit" class="btn btn-primary"><i id="IconfShow" class="fa fa-save"></i> 保存</button>
                        <a asp-action="Index" class="btn btn-default"><i id="IconfShow" class="fa fa-undo"></i> 返回</a>
                    </div>
                </form>
            </div>

        </div>
    </div>
</section>
@section Scripts {
    <script src="~/js/Configuration/Menu.js" ></script>
    @{await Html.RenderPartialAsync("_ValidationScriptsPartial");}
}
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201801/371995-20171228150504788-1173707728.png)
以上，我们可以通过增删改查界面操作菜单项了，但是要怎么将数据库中的菜单跟左侧的导航菜单关联呢？下节，我们将实现下这个功能。

### 动态加载导航菜单
前面章节说过，物理数据库菜单Menu是表格结构，而界面上的导航菜单是树状结构，那应该怎么处理呢？我们考虑先定义树状导航菜单的数据结构，然后表格结构的菜单项通过逻辑处理，转换成树状的导航菜单，就可以满足我们的要求了。
第一步，定义导航菜单：属性跟菜单项差不多，不同的是没有父菜单，而是子菜单列表，这样可以包含子菜单，实现菜单的树状嵌套；
```csharp
/// <summary>
/// 导航菜单项
/// </summary>
public class NavMenu
{
    public string Id { get; set; }
    public string Name { get; set; }
    public MenuTypes MenuType { get; set; }
    public string Url { get; set; }
    public string Icon { get; set; }
    public bool IsOpen { get; set; }

    /// <summary>
    /// 子菜单
    /// </summary>
    public IList<NavMenu> SubNavMenus = new List<NavMenu>();
}

/// <summary>
/// 左侧导航菜单视图模型
/// </summary>
public class NavMenuVM
{
    public IList<NavMenu> NavMenus { get; set; }

    public string[] MenuidsOpen { get; set; }
}
```
第二步，实现获取数据库保存的所有菜单项信息服务NavMenuService：将表格结构的菜单项，转换成树状的导航菜单；
```csharp
/// <summary>
/// 菜单服务
/// </summary>
public class NavMenuService : INavMenuService
{
    private readonly ApplicationDbContext _context;
    public NavMenuService(ApplicationDbContext context)
    {
        _context = context;
    }

    private static IList<NavMenu> NavMenus { get; set; }

    /// <summary>
    /// 获取导航菜单
    /// </summary>
    /// <returns></returns>
    public IList<NavMenu> GetNavMenus()
    {
        if (NavMenus == null)
            InitOrUpdate();

        return NavMenus;
    }
    /// <summary>
    /// 生成导航菜单
    /// </summary>
    /// <returns></returns>
    public void InitOrUpdate()
    {
        NavMenus = new List<NavMenu>();

        var rootMenus = _context.Menus
            .Where(s => string.IsNullOrEmpty(s.ParentId))
            .AsNoTracking()
            .OrderBy(s => s.IndexCode)
            .ToList();

        foreach (var rootMenu in rootMenus)
        {
            NavMenus.Add(GetOneNavMenu(rootMenu));
        }
    }
    /// <summary>
    /// 根据给定的Menu，生成对应的导航菜单
    /// </summary>
    /// <param name="menu"></param>
    /// <returns></returns>
    public NavMenu GetOneNavMenu(Menu menu)
    {
        //构建菜单项
        var navMenu = new NavMenu
        {
            Id = menu.Id,
            Name = menu.Name,
            MenuType = menu.MenuType.Value,
            Url = menu.Url,
            Icon = menu.Icon
        };

        //构建子菜单
        var subMenus = _context.Menus
            .Where(s => s.ParentId == menu.Id)
            .AsNoTracking()
            .OrderBy(s => s.IndexCode)
            .ToList();

        foreach (var subMenu in subMenus)
        {
            navMenu.SubNavMenus.Add(GetOneNavMenu(subMenu));
        }

        return navMenu;
    }
```
第三步，我们需要定义一个部分视图_NavMenu，具体规定菜单的显示样式，重要的是，如果包含子菜单的时候，子菜单仍然使用_NavMenu递归渲染显示，这样理论上可以支持无穷级别的导航菜单的显示。如果菜单是导航菜单，增加展开样式，并渲染子菜单，如果是操作菜单，定义href为菜单路径；
```html
@using MyWebSite.Areas.Configuration.Models
@using MyWebSite.Areas.Configuration.ViewModels
@model MyWebSite.Areas.Configuration.ViewModels.NavMenuVM

@foreach (var navMenu in Model.NavMenus)
{
    if (navMenu.MenuType == MenuTypes.导航菜单)
    {
        <li menuid="@navMenu.Id" class="treeview @(Model.MenuidsOpen.Contains(navMenu.Id) ? "menu-open" : "")">
            <a href="#">
                <i class="fa @navMenu.Icon"></i> <span>@navMenu.Name</span>
                <span class="pull-right-container">
                    <i class="fa fa-angle-left pull-right"></i>
                </span>
            </a>
            <ul class="treeview-menu" @(Model.MenuidsOpen.Contains(navMenu.Id) ? @"style=display:block;" : "")>
                @await Html.PartialAsync("_NavMenu", new NavMenuVM
           {
               NavMenus = navMenu.SubNavMenus,
               MenuidsOpen = Model.MenuidsOpen
           })
            </ul>
        </li>
    }
    else if ((navMenu.MenuType == MenuTypes.操作菜单))
    {
        <li menuid="@navMenu.Id">
            <a href="@navMenu.Url" @(navMenu.Url != null && navMenu.Url.StartsWith("http") ? @"target=_blank" : "")>
                <i class="fa @navMenu.Icon"></i><span>@navMenu.Name</span>
            </a>
        </li>
    }
}
```
最后，我们渲染下整个导航视图，我们已经有了NavMenuService服务，那怎么在UI界面去访问和使用它呢？其实.Net Core里提供了很方便的机制去访问，直接在Razor视图里将服务注册就行了，如：@inject INavMenuService NavMenuServiceIns
```csharp
@using Microsoft.AspNetCore.Http
@using MyWebSite.Areas.Configuration.ViewModels
@using MyWebSite.Services.Interfaces
@model MyWebSite.Models.ApplicationUser

@inject IHttpContextAccessor  HttpContextAccessorIns
@inject INavMenuService NavMenuServiceIns

<aside class="main-sidebar">
    <section class="sidebar">
        <div class="user-panel">
            <div class="pull-left image">
                <img src="~/lib/AdminLTE/dist/img/user2-160x160.jpg" class="img-circle" alt="User Image">
            </div>
            <div class="pull-left info">
                <p>@Model.NickName</p>
                <a href="#"><i class="fa fa-circle text-success"></i> 在线</a>
            </div>
        </div>
        <form action="#" method="get" class="sidebar-form">
            <div class="input-group">
                <input type="text" name="q" class="form-control" placeholder="Search...">
                <span class="input-group-btn">
                    <button type="submit" name="search" id="search-btn" class="btn btn-flat">
                        <i class="fa fa-search"></i>
                    </button>
                </span>
            </div>
        </form>
        <ul class="sidebar-menu" data-widget="tree">
            <li class="header">菜单导航</li>
            @{
                var navMenus = NavMenuServiceIns.GetNavMenus();
                var cookieMenuidsOpen = HttpContextAccessorIns.HttpContext.Request.Cookies["menuids_open"] ?? "";
            }
            @await Html.PartialAsync("_NavMenu", new NavMenuVM
       {
           NavMenus = navMenus,
           MenuidsOpen = cookieMenuidsOpen == null ? new string[] { } : cookieMenuidsOpen.Split(",")
       })

            <li><a href="https://adminlte.io/docs"><i class="fa fa-book"></i> <span>Documentation</span></a></li>
            <li class="header">LABELS</li>
            <li><a href="#"><i class="fa fa-circle-o text-red"></i> <span>Important</span></a></li>
            <li><a href="#"><i class="fa fa-circle-o text-yellow"></i> <span>Warning</span></a></li>
            <li><a href="#"><i class="fa fa-circle-o text-aqua"></i> <span>Information</span></a></li>
        </ul>
    </section>
</aside>
```

### 导航菜单刷新优化
现在我们的导航菜单的展示功能基本完成了，但是这里有个小小的用户体验的问题，就是每次点击导航菜单项时，由于页面跳转，导致整个Layout页面会刷新，那左侧的导航菜单也会刷新，这样之前展开的菜单就会折叠起来：
![avatar](https://bj.bcebos.com/v1/mysite/images/201801/371995-20171228161317350-290079642.gif)
要保持原有的菜单不被折叠，有很多方法，比如不使用Layout，点击导航菜单项时，通过Ajax局部刷新右侧内容区域，或者直接做成单页模式的网站，保证左侧的导航菜单不因不同内容而刷新。这里考虑.Net Core使用Layout的便捷性，思路如下：点击导航菜单项时，保存展开的菜单项id到cookie中，跳转下一个界面以后，根据cookie中的菜单项id，重新设置展开状态
```javascript
$('.main-sidebar a').click(function () {
    //记录菜单展开状态
    var href = $(this).attr('href')
    if (href === null || href === "#") return
    var menuids = [];
    $('.menu-open').each(function () {
        menuids.push($(this).attr('menuid'))
    })
    $.cookie('menuids_open', menuids.join(','), { path: "/" })
})
```
![avatar](https://bj.bcebos.com/v1/mysite/images/201801/371995-20171228161505491-733929899.gif)
实现后效果：点击菜单后，不再折叠。

### 小结
至此，我们第一个后台管理功能--菜单管理已经完成，我们来看下效果：
![avatar](https://bj.bcebos.com/v1/mysite/images/201801/371995-20171228163753538-1491482338.gif)