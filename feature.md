##AppHost：大前端融合下的 Hybrid 开发解决方案

AppHost 是一套解决 H5 和 native 协作开发的整体框架和服务。试图解决 native 和 H5 目前迭代频繁、时间仓促造成质量不高，业务膨胀后代码混乱，两端联调困难，多端协作彼此割裂等痛点。
**作为一种 JSBridge 的实现方法，AppHost 像一座桥，将 native 和 H5 开发打通**；
一边是提供设计良好的 native framework 和相关 protocol ，提高 native 接口的交付能力和开发质量；
一边是为 H5 开发的页面和 native 联调，提供辅助调试工具和性能调优工具，让前端开发者对 H5 in App 的调试体验像调试原生浏览器一样，从而提高质量和提升开发效率。

### Hybrid 的接口开发生命周期
![生命周期](https://upload-images.jianshu.io/upload_images/277783-4d429c08fc003f20.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这是实际工作中 JSBridge 面对的工作，很多是重复、乏味，又容易出错的。常见场景——“新需求里需要增加新的接口”的流程是这样的：
1.  新增一个文件或者在旧文件上编写代码，新开接口和属性
2. 在 Android、native 和 H5 共有的接口文档上补充 API 接口。如果有需要，需要升级 JSBridge 接口的版本号
3. 将改动通知 Android、H5 等相关方
4. 增加测试用例（testcase 应该 iOS 、Android、 QA、前端，共建测试用例）
4. 如果有必要需要告知，QA 增加自动化测试用例
5. 前端需要考虑版本号升级之后，需不需要对新旧 native App 做兼容实现

AppHost 处理负责 JSBridge 接口从 0 到 N 个、1岁到 5岁、出生到死亡周期，以及 JSBridge 之间的关系管理、对外提供数据支持等工作，所以它是`解决方案`，而不是个技术方案（如`WebViewJavascriptBridge`只是技术方案）。
### AppHost 的功能总览
![功能总览](https://upload-images.jianshu.io/upload_images/277783-2957bbc40a8287c9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

分两部分，AppHost Core 为 native 开发提供基础模块和基本功能封装；AppHost Debug Service 为 native、H5 前端、QA 等人员提供调试服务。下面详细介绍功能。
### AppHostCore
1.  **webview 核心，包含常见需求的实现逻辑**，包括
- native 和 H5 的通讯协议，封装了 native 端解析、H5 端发送逻辑。native 开发人员只需要面向业务编码，然后通知 H5； H5 开发面向业务开发，只需关心两个接口。
- 新增接口用继承 AppHostResponse 的方式实现，解决业务需求增长、代码无序膨胀的问题。特别的，支持业务接口的延迟加载，不使用的接口，不会初始化。
- Cookie管理，最烦人的 Cookie 丢失和 Cookie 同步问题，已经内部妥善处理
- 一些人性化的小优化。更合理的进度条、浏览历史滚动记忆、增强的 native 执行 js 代码能力、基本的 API 接口调用鉴权等等。
2. **JSBridge 接口管理**
- 独立于 App 的版本号，H5 使用特性嗅探实现新旧 App 的兼容，简单直观。
- API 接口签名，可实现 API 参数粒度的接口升级和开关管理。
3. **资源加载**
- 加载远程 URL，单向同步 Cookie 到 WKWebView。
- 本地文件夹资源，可实现用离线包渲染动态页面。
- 某些业务场景下，可实现 HTML 里的 xhr、js、css 资源请求拦截，不需要动用私有 webkit API。
4. **API 接口文档一体化和 testcase 自动化**
对于“native 为 H5 提供接口” 这件事情，如前述，需要多方的协调同步，很容易出现：接口文档过时、文档缺失、接口查找麻烦、接入新 API 不直观、测试不方便，QA 回归不充分，或者是多个环节重复写测试用例等坏情况。
***AppHost 的 API 文档模块，将这些环节需要的文档和测试用例，全部集中到开发阶段完成，后续 H5 查询的 API 文档、QA 走查用例、自动化测试，全部自动生成***。保证接口文档的最新，省去多个环节的重复建设，内置的自动化测试支持，方便 QA 使用脚本回归测试。
### AppHost Debug Service
1.  **Remote Debugger 通过电脑浏览器提供 Debug Service**
电脑浏览器具有访问方便、可展示区域大、输入快捷方便、易于集成第三方调试工具的特点。相同的调试功能，理论上也可以集成在手机 App端，但是体验会大打折扣，是个低效的调试方案。
2. **帮助系统和文档**。
在浏览器端 Console ，实现了一个小型命令行程序，指导用户如何使用本 Remote Debugger；同时还提供 **即时查询 API 接口** 名称、参数解释、示例代码等功能，让你的工作流不需要切换到打开的API 文档文件或者浏览器，保持操作上下文。
3. **REPL[（Read-Eval-Print Loop）](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)环境**
Console 里实现了完整 webview 执行环境，将传统语言的探索、调试新特性的体验带到 Remote Debugger，如同 Bash 的` shell prompt`和 ruby 的`irb `那样。在这里输入的所有命令如同在远端 webview 的 console 里执行一样。当然还有`Off mobile` 和`On mobile `来切换当前命令是本地执行还是远端 webview 执行。
4. **辅助功能**
Console 提供了左侧快捷命令；内置了命令的历史记忆，实现上下箭头遍历；支持` :clear `，清除当前界面等功能
5. **扩展性**
-  和 Safari 的 Develop 工具配合
我们知道 Safari Develop 工具是在页面打开后才会出现。如果我们有个页面由 302 跳转，我们想抓到想要的请求是做不到的。接入 AppHost 之后，我们保持Safari Develop 工具打开的状态，在 Remote Debugger 输入命令 ，让当前 webview 加载初始 URL，这样我们就可以抓到从 302 跳转开始后的网络请求了。
- 集成 weinre。
通过`:weinre --` 命令，不需要改动被调试页面的源码，即可提供 weinre 调试服务，而且一次注入当前 App 启动后全程有效，后续页面无需再注入。用这个特性，甚至可以调试第三方页面。
- 支持 console.log。这个无需赘言，曾经的` [https://jsconsole.com/](https://jsconsole.com/) 是首选的远程调试服务。AppHost 内置此功能。
6. **演示**
   6.1  **基本操作演示**
![Debugger 整体使用](https://upload-images.jianshu.io/upload_images/277783-e520ecf4d92e53da.gif?imageMogr2/auto-orient/strip)
    6.2 **查看严选首页的 onload 事件时间**
![查看当前 H5 页面的 timing 数据](https://upload-images.jianshu.io/upload_images/277783-7b99adf129b64dc1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
    6.3 **使用 weinre 调试严选页面**
![weinre服务](https://upload-images.jianshu.io/upload_images/277783-d7113e5153fc074b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

