
import Foundation
import CommonCrypto


class SecureDataDefaults {
    
    static var DefaultFolderName = "AppData"
    static var secureFile : SecureFile? = nil
    
    init (SecureFileKey FileKey : String, DataKey KeyData : String) {
        if KeyData.count != 16 || FileKey.count != 16 {
            debugPrint("SecureDataDefaults : both Key length most be 16 long for AES-128bit keys and  key length can't be empty")
            return
        }

        var isDirectory : ObjCBool = true

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        if FileManager().fileExists(atPath: documentsURL.path,isDirectory:  &isDirectory) {
            debugPrint("SecureDataDefaults setup : documents directory found  .")
        }
        let AppDataURL = documentsURL.appendingPathComponent(SecureFileDefaults.FolderName)
        if FileManager().fileExists(atPath: AppDataURL.path,isDirectory:  &isDirectory) {
            debugPrint("SecureDataDefaults setup : AppDataURL directory found  .")
            SecureDataDefaults.secureFile = SecureFile(SecureFileKey: FileKey,KeyData: KeyData)
            return
        }
        do {
           
            try fileManager.createDirectory(at: AppDataURL, withIntermediateDirectories: true,attributes: nil)
            debugPrint("SecureDataDefaults setup : AppDataURL directory created at \(AppDataURL.path) .")
            SecureDataDefaults.secureFile = SecureFile(SecureFileKey: FileKey, KeyData: KeyData)
            return
        } catch let error {
            debugPrint("SecureDataDefaults setup Error : \(error.localizedDescription) .")
            return

        }
        
    }

    
     static func SaveData(_ codable: Codable, forKey key: String){
         var isDirectory : ObjCBool = true
         let fileManager = FileManager.default
         let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
         if !FileManager().fileExists(atPath: documentsURL.path,isDirectory:  &isDirectory) {
             debugPrint("SecureDataDefaults saveData : documents directory not found  .")
             return
         }

         let AppDataURL = documentsURL.appending(path: SecureFileDefaults.FolderName)
         if !FileManager().fileExists(atPath: AppDataURL.path,isDirectory:  &isDirectory) {
             debugPrint("SecureDataDefaults saveData : AppDataURL directory not found  .")
             return
         }

         let fileURL = AppDataURL.appending(path: key + ".json")
         
         do {

             let data = try JSONEncoder().encode(codable)
             
             if let SecKeyData = secureFile?.GetKey() {
                 if SecKeyData.isEmpty {return}
                 if let secretKey = SecKeyData.data(using: .utf8) {

                     if let encryptedData = SecureDataDefaults.encrypt(data: data, key: secretKey) {

                         try encryptedData.write(to: fileURL,options: [.atomic])
                         debugPrint("Data saved for \(key)")
                         return;

                     }
                 }
                 
             }
             
            
         } catch let error {
            print("SecureDataDefaults Error saving data: \(error.localizedDescription)")
         }


    }
    static func GetData<T: Codable>(forKey key: String, as type: T.Type) -> T? {
      //  let data = // Fetch raw data from disk as done above
        let fileManager = FileManager.default
        let documentsURL = URL.documentsDirectory.appending(path: SecureFileDefaults.FolderName)
        let KeyDataURL = documentsURL.appending(path: key + ".json")
        var isDirectory : ObjCBool = false
        if FileManager().fileExists(atPath: KeyDataURL.path,isDirectory: &isDirectory) {
            //print("I am here")
            
            do {
                if let fileData = fileManager.contents(atPath: KeyDataURL.path()) {
                    let data =  fileData
                    
                    if let SecKeyData = secureFile?.GetKey() {
                        if let secretKey = SecKeyData.data(using: .utf8) {
                            if let decryptedData = SecureDataDefaults.decrypt(data: data, key: secretKey) {
                                return try JSONDecoder().decode(T.self, from: decryptedData)

                            }
                        }
                    }

                    

                }
                
                debugPrint("SecureDataDefaults Decoding Error  > codable : An unexpected error occurred ")
                return nil
                
            } catch let error {
                debugPrint("SecureDataDefaults Decoding Error  > codable : An unexpected error occurred > \(error.localizedDescription) .")
                return nil
            }
        }
        
        debugPrint("SecureDataDefaults GetData : not found  key .")

        return nil
        
    }
    
    static func encrypt(data: Data, key: Data) -> Data? {
        var outLength = Int(0)
        var buffer = Data(count: data.count + kCCBlockSizeAES128)
        let bufCount = buffer.count
        let status = data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                buffer.withUnsafeMutableBytes { bufferBytes in
                    CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            nil,
                            dataBytes.baseAddress, data.count,
                            bufferBytes.baseAddress, bufCount,
                            &outLength)
                }
            }
        }
        
        guard status == kCCSuccess else {
            debugPrint("SecureDataDefaults encrypt : failed .")

            return nil
        }
        
        buffer.count = outLength
        return buffer
    }
    static func decrypt(data: Data, key: Data) -> Data? {
        var outLength = Int(0)
        var buffer = Data(count: data.count + kCCBlockSizeAES128)
        let bufferCount = buffer.count

        let status = data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                buffer.withUnsafeMutableBytes { bufferBytes in
                    CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            nil,
                            dataBytes.baseAddress, data.count,
                            bufferBytes.baseAddress, bufferCount,
                            &outLength)
                }
            }
        }
        
        guard status == kCCSuccess else {
            debugPrint("SecureDataDefaults decrypt : failed .")
            return nil
        }
        
        buffer.count = outLength
        return buffer
    }
}

