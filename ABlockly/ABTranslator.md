```swift
    for _ in 0..<10
    {
        move(dir:.forward, len:50)
        turn(dir:.right, angle:90)
        color(0xff0000)
    }
```
```swift
    if 5 == 5
    {
        move(dir:.forward, len:12+18)
    }else
    {
        turn(dir:.right, angle:90)
    }
```
### rules:
1. put a \n only at the start of every line except the first
2. expression & statement:
    \(name[att=value]$default)
3. return value if name == field
4. return attribute of 'name' if name == mutation
4. default value:
    $default
