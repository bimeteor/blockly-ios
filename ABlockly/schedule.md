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


## Comparison:
### Introduction:
Another Blockly is a visual coding module provided by Jimu team. It's based on Google Blockly, with the same UI architecture but different running and code generating architectures


|Items|Google Blockly|Jimu ABlockly|
|:-:|:-:|:-:|
|内存占用|10分钟内耗尽|可忽略|
|内存泄漏|长期持有数10m内存|离开页面即释放|
|运行稳定性|差而难以解决|非常稳定|
|同时连接多个设备|不支持|支持|
|语法高亮|难|简单|
|交互体验|web体验差|原生体验好|
|自定义交互|难|简单|
|自定义运行规则|难|简单|
|输入问题|存在表情及全半角bug|无此问题|