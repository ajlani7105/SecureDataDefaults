# 🔐 SecureDataDefaults library
create secure data defaults in iOS & MacOS &others .


## ❓what's the problem with UserDefaults api in Foundation ?
- UserDefaults does not use encryption in storing data for your app.
- From personal use, I found that UserDefaults lose data with unkown issues and you can't tracking it.
- sometime you need to store data that you don't need to put them in Database and you want fast way to store them and access them without using SwiftData,CoreData complexity,data like web history,game user info , simple data that doesn't involve passwords and sensitve logins .




# 🎯 usage 
### 1 - write your struct to create your own data , important that your struct confirm to Codable protocol !
```swift
struct History : Codable {
    var Name : String
    var Age : Int
    init(Name: String, Age: Int) {
        self.Name = Name
        self.Age = Age
    }
}
```

### 2 - Create SecureDataDefaults Object and create secure keys for both file and data
```swift
let secureDataDefault = SecureDataDefaults(SecureFileKey: "ArarCityNorthBor", DataKey: "_DataDefaultArar")
```
> 🔑 only support and work with (AES-128bit) for now 

>  so string keys most be 16 lenght .



### 3 - Saving data and Accessing them
```swift
// Create some data for two users info 
var someData : [History] = [
    History(Name: "Abdulrhman", Age: 30),
    History(Name: "Ziyad", Age: 36)
]

// Save data now using SaveData
SecureDataDefaults.SaveData(someData, forKey: "UserHistory")


// Access data using GetData
if let GetData = SecureDataDefaults.GetData(forKey: "UserHistory", as: [History].self) {
    print(GetData) // print as json 
}
```

