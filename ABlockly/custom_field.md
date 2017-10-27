#  Custom field

有时blockly自带的field可能不符合我们的需求，因此我们需要学会创建自定义的Field，下面就是创建的步骤：

1、新建一个Model，继承于Field类，例如FieldCustom，并且重写父类以下方法：
（1）func copyField() -> Field
（2）func setValueFromSerializedText(_ text: String) throws
（3）func serializedText() throws -> String?

提示：内部更多的操作可以参考FieldAngle或者FieldColor

2、在Field+Json文件中（起始位置）增加一个Field type，例如FIELD_TYPE_CUSTOM

3、在Field+Json文件的private override init()这个方法中注册这个Field Type：
registerType(FIELD_TYPE_CUSTOM) { (json: [String: Any]) throws -> Field in
return FieldCustom(name: (json[PARAMETER_NAME] as? String ?? "NAME"))
}

4、新建一个Layout，继承于FieldLayout，例如FieldCustomLayout

5、新建一个View，继承于FieldView，例如FieldCustomView，并且重写父类的以下方法：
（1）func refreshView(forFlags flags: LayoutFlag = LayoutFlag.All, animated: Bool = false)
（2）func prepareForReuse()

同时必须实现FieldLayoutMeasurer的以下方法：
// 这个方法的作用返回field在block中的size
public static func measureLayout(_ layout: FieldLayout, scale: CGFloat) -> CGSize

提示：内部更多的操作可以参考FieldAngleView或者FieldColorView

6、在ViewFactory文件的public override init()这个方法中注册这个Layout：
registerLayoutType(FieldCustomLayout.self, withViewType: FieldCustomView.self)

7、在DefaultLayoutFactory文件的public override init()这个方法中创建这个Layout：
registerLayoutCreator(forFieldType: FieldCustom.self) { (field: Field, engine: LayoutEngine) throws -> FieldLayout in
return FieldCustomLayout(engine: engine, measurer: FieldCustomView.self)
}

All done!
Enjoy youself!
