![AppHost](https://upload-images.jianshu.io/upload_images/277783-768ecdd81b026a44.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

AppHost 是一整体解决 H5 和 native 协作开发的框架和服务。试图解决 native 和 H5 目前开发质量低下、业务膨胀后代码混乱、两端联调困难等，彼此割裂的现状。
作为一种 JSBridge 的实现方法，AppHost 像一座桥，将 native 和 H5 开发打通，一边是提供设计良好的 native framework 和相关 protocol ，提高 native 接口的交付能力和开发质量；一边是为 H5 开发的页面和 native 联调，提供大量辅助调试工具和基本性能调优工具，让前端开发者对 H5 in App 的调试体验像调试原生浏览器一样，提升质量和开发效率。
## native 开发用例

### 1.基本加载 H5 页面
```objective-c
    AppHostViewController *appHost = [[AppHostViewController alloc] init];
    appHost.url = @"https://m.you.163.com";
    appHost.pageTitle = @"好的生活没那么贵";
    appHost.rightActionBarTitle = @"点赞";// 右上角按钮文案

    [self.navigationController pushViewController:appHost animated:YES];
```
### 2.用增强后的 AppHostViewController  加载 H5 页面
WebViewViewController 继承自AppHostViewController，自定义拦截`openapp.jdmobile:`协议和自定义了 HUD 行为，详见 [AppHostExample](https://github.com/hite/AppHostExample)源码。
```objective-c
    WebViewViewController *vc = [[WebViewViewController alloc] init];
    NSDictionary *object = self.objects[indexPath.row];
    NSString *url = [object objectForKey:@"url"];
    NSString *fileName = [object objectForKey:@"fileName"];
    if (url) {
        vc.url = url;
    } else if(fileName.length > 0){
        NSString *dir = [object objectForKey:@"dir"];
        NSURL * _Nonnull mainURL = [[NSBundle mainBundle] bundleURL];
        NSString* domain = [object objectForKey:@"domain"];
        if (dir.length > 0) {
            NSURL *url = [mainURL URLByAppendingPathComponent:dir];
            [vc loadIndexFile:fileName inDirectory:url domain:domain];
        } else {
            [vc loadLocalFile:[mainURL URLByAppendingPathComponent:fileName] domain:domain];
        }
    }

    [self.navigationController pushViewController:vc animated:YES];
```
### 3.自定义 Response，新增 h5 接口
详见 [AppHostExample](https://github.com/hite/AppHostExample)源码。
```objective-c
// HUDResponse.h
#import <AppHost/AppHost.h>

NS_ASSUME_NONNULL_BEGIN
@interface HUDResponse : AppHostResponse

@end
NS_ASSUME_NONNULL_END
// HUDResponse.m
+ (NSDictionary<NSString *, NSString *> *)supportActionList
{
    return @{
             @"hideLoading":@"1"
             };
}

#pragma mark - override
ah_doc_begin(hideLoading, "隐藏 loading 的 HUD 动画，UIView+Toast实现。")
ah_doc_code(window.appHost.invoke("hideLoading"))
ah_doc_code_expect("在有 loading 动画的情况下，调用此接口，会隐藏 loading。")
ah_doc_end
- (void)hideLoading
{
    [self.appHost.view hideToastActivity];
}
```
## Remote Debugger 演示
### 1.如何打开远程调试功能
工程代码运行之后，按照 XCode 日志里的提示(或者点击 App 里右上角一个 AH 样的图标，展开后的日志了有 url，长按复制或者在浏览器输入)，用电脑浏览器打开调试页面，展现的就是调试 Remote Debugger 的 Console界面。
![Debugger 整体使用](https://upload-images.jianshu.io/upload_images/277783-e520ecf4d92e53da.gif?imageMogr2/auto-orient/strip)

##  AppHost 的功能总览
![功能总览](https://upload-images.jianshu.io/upload_images/277783-d30643fad6c62bbd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 如何安装
介绍两种方式，作为动态链接库 framework 或者以子项目的方式引入。
#### 1. 动态链接库framework
-  打开`AppHost.xcodeproj`工程
- 选择 scheme 如图 ![分架构的 framework build 脚本](https://upload-images.jianshu.io/upload_images/277783-6144027c6b7af2d8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
- 运行后会自动打开一个文件夹，选择你需要的架构（模拟器或者 device）将`AppHost.framework` 托到桌面（任何一个容易找到的地方）。
- 接着，选择工程 target -> general 面板下面的 `Embedded Binaries` ，点击 + 号
- 选择`add others...`，选中刚刚 build 好的`AppHost.framework`，添加过程中，需要选择`copy items if needed`选项。(后续你可以把这个文件放置到工程目录下任意地方，然后 add 到 Xcode 工程里）
- 完毕，在工程里即可使用`#import <AppHost/AppHost.h>`
#### 2.Embedded Framework
- 切换到工程的根目录下，运行下面命令， 添加 AppHost 作为  git [submodule](https://git-scm.com/docs/git-submodule) 
  ```bash
  $ git submodule add https://github.com/hite/AppHost.git
  ```

- 打开 `AppHost` 文件夹, 把 `AppHost.xcodeproj` 拖到 Project Navigator tab，你的项目Xcode project 根目录下

    > AppHost.xcodeproj 应该在你的工程文件蓝色图标的下方，处于可打开状态，不能打开说明你单独打开了 AppHost.xcodeproj，请关闭

- 设置主工程和子工程的 deploy target 一致.
- Next, 在 Project Navigator 里选择你的项目（蓝色图标），切换到  target configuration 窗口，在 "Targets" 窗口下，选择应用 target 
- 在窗口顶部上面，选择 "General" 窗口.
-  "Embedded Binaries" 区域点击 + 号.
- 在弹出的选择窗口里，下拉到`Products` 文件夹，选择`AppHost.framework` 
  > `AppHost.framework` 会自动添加为 target 依赖。在`build phase\copy files` 的` linked framework` 和 `embedded framework` 也会自动添加`AppHost.framework`，这两个地方是为了能在模拟器和真机上运行
- 完毕，在工程里即可使用`#import <AppHost/AppHost.h>`
## H5 端使用示例
暴露给 h5 的数据有两类，一类是 apphost 的静态属性；一类是接口；
####  > AppHost 静态属性，包含属性有
1. appInfo
2. supportFunctionType
这两个静态属性可以在 h5 的任意地方调用都是可用的，调用举例，
```javascript
// 获取当前是否是 iPhone X 设备（iOS only）
var name = appHost.appInfo.iPhoneXInfo
// 获取当前 App 是否支持此某个接口，如 `oepnFinancial`,
if(apphost.supportFunctionType && parseInt(apphost.supportFunctionType.openFinancial, 10) >0){
 //支持打开理财界面 
}
```
#### > AppHost 的核心接口
大部分核心接口需要在 'onready', 内调用，但是如果是一些和 UI 无关的接口，可以在任意地方调用，如 统计接口，`appHost.invoke('log',{})`
```javascript
window.appHost.on('onready',function(data){
                    window.appHost.invoke('sendLogToES', {'content':'XXX' })
                    // your code go here.
                });
```
**第一个核心接口，`invoke`, 即 `window.appHost.invoke`**，它是 h5 调用 native 的唯一入口，可调用接口和调用用例可以使用 `Remote Debugger`的 console 来查看；

**第二个核心接口，`on`,即`window.appHost.on`**，它是 h5 接收 native 调用的一种方式，用 on 来接收 native 调用比较适合在 delegate 模式；
 `window.appHost.invoke` 也是可以接收 native 回调的，也就是在 invoke 的最后一个参数传入一个 function，如
```
window.appHost.invoke('alert', {'text': 'text'});
//如果是callback，支持如下语法
window.appHost.invoke('alert', {'text': '点击确定后，有回调'},function(){
      appHost.invoke('toast',{'text':'你点击了alet的确定按钮'});
     });
});
```

更多用例请查看  [AppHostExample](https://github.com/hite/AppHostExample) 源码
