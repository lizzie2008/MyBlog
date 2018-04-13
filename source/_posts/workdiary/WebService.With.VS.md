---
title: 工作笔记 | Visual Studio 调用 Web Service
tags:
  - 流程
categories: 软件工程
date: 2018-04-12
---
![avatar](https://mysite.bj.bcebos.com/images/articles/3a8146cd-6b6c-4a54-bcec-4575150f2162.jpg)
 
### 引言
最近笔者负责ERP财务系统跟中粮集团财务公司的财务系统做对接，鉴于ERP系统中应付结算单结算量比较大，而且管理相对集中，ERP系统与中粮财务公司的支付平台系统对接，实现银企直联，将网银录入的环节、付款以后ERP确认环节自动化，节省人工操作环节带来的误差。
这样公司财务人员在我们的系统中做对外的付款单，自动向集团财务系统发起付款指令，由集团统一通过银行给对应的供应商转账，并监控付款单的状态，完成供应商在系统的正常结算。

<!-- more -->

### 系统对接环境
业务层面不再多述，本文主要介绍技术层面实施：
- 集团财务公司提供的是基于SAP架构的Web Service接口
- ERP开发环境使用VS2013
- 访问模式是半双工，我们ERP系统单向远程调用接口，发起付款指令、并轮询付款单状态

自VS2008以后，为了对.NET Framework 3.0 或 3.5版本上WCF Service Library的支持。增加了Add Service Reference（添加服务引用）功能，这样可以在VS中很方便的添加Web Service接口引用，并通过简单的配置，调用远程服务。

#### 申请开通集团通道白名单
一般来说不可以随便访问集团SAP，必须找运维人员开通访问权限。开通后，通过telnet查看ip地址和端口是否已经开放，或者浏览器访问，正常的话应该如下图：
![avatar](https://mysite.bj.bcebos.com/images/201804/20180412152030.jpg)

#### 项目中添加服务引用
选中项目，右键 -> Add -> Service Reference
![avatar](https://mysite.bj.bcebos.com/images/201804/20180412152401.jpg)
弹出的界面中，Address输入提供的Web Service地址，然后点击 GO 按钮，这里一般会提示输入用户名和密码，输入后可以看到Web Service引用连通。展开服务，可以看到接口提供了2个方法。如果这一步提示错误，可以在浏览器中输入地址，看看是否能访问，其实就是访问远程的wsdl文件，如果访问不了，再检查是否是网络或者权限的原因。
![avatar](https://mysite.bj.bcebos.com/images/201804/20180412152911.jpg)
我们点“确定”，可以看到VS自动帮我们在项目目录下生成了一个文件夹：Service References，里面有刚才看到的服务名，同时会在  app.config 中增加一段配置类似如下（如果当前没有app.config文件，会自动生成）：
```xml
  <system.serviceModel>
    <client>
      <endpoint address="http://xx.xx.xxx.xx:50000/xxxxxxx"
        binding="basicHttpBinding" bindingConfiguration="SOS_TxService_SendBinding"
        contract="TxService.SOS_TxService_Send" name="HTTP_Port" />
    </client>
  </system.serviceModel>
```

#### VS帮我们做了什么
为了更好的学习，我们深入了解一下，VS帮我们都做了哪些工作。
项目新建的Service References目录下的服务，在VS中是无法查看的，我们可以进入对应的目录下，看看都生成了哪些文件：
![avatar](https://mysite.bj.bcebos.com/images/201804/20180412155213.jpg)
首先可以看到，目录下有个wsdl文件，大家应该都熟悉，这是用来定义和描述Web Service的，通过这个文件，就可以知道接口都提供了哪些方法，输入参数类型和输出结果格式。打开这个wsdl文件看一下，跟我们想象的一样，原来，VS在引用服务访问远程wsdl文件的同时，在本地拷贝了一份。
接下来我们看一个后缀为 .cs 重要的文件，打开看下，这里面，VS帮我们生成了关于这个服务的接口和实现类。
![avatar](https://mysite.bj.bcebos.com/images/201804/20180412160034.jpg)
这里最重要的，是帮我们生成了 SOS_TxService_SendClient 这个类，研究一下，发现已经实现了之前看到的Send、Send1两个方法，并提供了对应的异步方法。
![avatar](https://mysite.bj.bcebos.com/images/201804/20180412160346.jpg)
我们整理一下VS做的工作：
1. 添加服务引用时，访问远程 wsdl 文件，并拷贝本地；
2. 根据 wsdl 文件中的接口定义，定义调用端接口（比如Send，Send1）；
3. 定义代理服务 SendClient 类，继承上述定义的调用端接口，并提供具体实现（实现Send，Send1）；
4. 定义和实现其他辅助类，比如 SendRequest，SendResponse;
5. 生成 app.config 中相关配置；

到这里，聪明的你可能要问，既然VS已经帮我们生成了代理服务类 SendClient，而且类已经提供了接口方法的具体实现，现在是不是直接实例化一个服务类，直接调用方法就可以远程调用？是的，没错！VS基本把需要做的工作都帮你做了，剩下的就是使用就行了，简单吧。

#### 其他相关配置
一般情况下，我们访问Web Service，需要提供用户名和密码的权限认证，否则直接调用的话，会报错。
这里我们修改一下 app.config 文件如下：
```xml
  <system.serviceModel>
    <bindings>
      <basicHttpBinding>
        <binding name="SOS_TxService_SendBinding" >
          <security mode="TransportCredentialOnly" > 
            <transport clientCredentialType="Basic"/>           
            <message clientCredentialType="UserName"/>
          </security> 
        </binding>
      </basicHttpBinding>
    </bindings>
    <client>
      <endpoint address="http://xx.xx.xxx.xx:50000/xxxxxxx"
        binding="basicHttpBinding" bindingConfiguration="SOS_TxService_SendBinding"
        contract="TxService.SOS_TxService_Send" name="HTTP_Port" />
    </client>
  </system.serviceModel>
```
单元测试调用一下，可以看到能正常返回 xml 格式的结果：
```csharp
[TestMethod]
public void WebServiceTest()
{
    var client = new SOS_TxService_SendClient();
    if (client.ClientCredentials != null)
    {
        client.ClientCredentials.UserName.UserName = "username";
        client.ClientCredentials.UserName.Password = "password";
        try
        {
            var tt = client.Send("test");
            Assert.IsTrue(tt.Length > 0);
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            throw;
        }
    }
}
```
还有一个问题，就是跨项目引用，比如在一个基础服务项目中，实现了远程调用。在应用层项目中，引用了基础服务项目dll，应该注意以下一点：选中生成的服务，右键-> Configure Service Reference:
![avatar](https://mysite.bj.bcebos.com/images/201804/20180412165009.jpg)
保证相关的程序集能够正常引用，然后在应用层项目，并手动将 app.config 的相关配置拷贝至项目目录下。

### 写在最后
至此，我们通过VS调用 Web Service 实施成功，还是比较简单，其实没有什么技术难点，主要希望能深入了解原理，知道VS后台自动帮助我们做了哪些工作，如果我们不使用辅助工具的时候，要实现远程访问，应该怎么去实现。
注：目前 .net core 环境对 Web Service 支持不是很好，笔者在VS2017中，.net core 引用 Web Service依旧报错，大家有兴趣可以自己研究一下。
