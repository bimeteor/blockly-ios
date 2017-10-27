## UI：
1. 弹窗
1. block外观
3. toolbar
4. tipbar
5. 复制功能
6. 运行时显示loops等变量数值
7. 自动调整blocks至可视区域
8. 尝试用png替代svg
## 运行：
1. 分支运行
2. 支持更多基本语句
3. 模拟器
## 数据：
1. 支持多语言
1. 可配置
1. block中type命名
10. 兼容旧数据
## 工程及优化：
1. 简化XMLNode中XML搜索算法
2. 用XMLNode替换AEXML
2. 调整架构和命名
3. 打包
4. 连接蓝牙
13. 日志
14. issues & release notes
5. Kotlin版本
6. Typescript版本

## owners:
|module|owner|
|:-:|:-:|
|UI|覃文周|
|运行及代码|王刚|
|数据及配置|陈小雨|

## Comparison:
### Introduction:
Another Blockly is a visual coding module provided by Jimu team. It's based on Google Blockly, with the same UI architecture but different running and code generating architectures

### ABlockly vs Blockly

|Items|Google Blockly|Jimu ABlockly|
|:-:|:-:|:-:|
|内存占用|10分钟内耗尽|可忽略|
|内存泄漏|长期持有数10m内存|离开页面立刻释放|
|稳定性|多分支出错概率高|非常稳定|
|输入问题|存在表情及全半角bug|无此问题|
|暂停和继续|不支持|支持|
|交互体验|web体验差|原生体验好|
|蓝牙通信|一次问答需要web与原生语言交互两次|直接通信|
|同时连接多个设备|不支持|支持|
|语法高亮|难|简单|
|自定义交互|难|简单|
|自定义运行规则|难|简单|

### Language
#### Why it's Swift & Kotlin
1. CPP
    1. iOS和Android库不兼容，比如xml库
    2. 不可以直接跟界面和蓝牙交互，需要iOS和Android提供兼容接口
    3. 在Android项目中必须以库的形式存在，不利于调试
    4. 相比于现代的Swift和Kotlin语言，CPP学习曲线陡峭，所以开发和维护成本高
2. Typescript
    1. 不可以直接跟界面和蓝牙交互，需要iOS和Android建立Javascript和原生互通的桥梁
    2. 内存占用比iOS和Android高
3. Swift & Kotlin
    1. 更现代的语言，简单，高效
    2. 语法相似度高，一个人维护可以同时维护两个平台
    3. 直接跟界面和蓝牙交互
