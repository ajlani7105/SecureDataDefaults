import CryptoKit
import Foundation




class SecureFileDefaults {
    static var FolderName = "AppData"
    static var SecureFolderName = "SecretFolder"
    static var SecureFileName = "Secret.scf"


}

public class SecureFile {
    
    private static var SecureFileKey    = ""

    public init (SecureFileKey : String,KeyData : String){
        if KeyData.count != 16 || SecureFileKey.isEmpty {
            debugPrint("SecureFileError : Key length most be 16 for AES-128bit keys and file key length not empty")
            return
        }
        SecureFile.SecureFileKey = SecureFileKey;
        var isDirectory : ObjCBool = true

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        if !FileManager().fileExists(atPath: documentsURL.path,isDirectory:  &isDirectory) {
            debugPrint("SecureFileLog : documents directory were not found .")
            return;
        }

        let AppDataURL = documentsURL.appendingPathComponent(SecureFileDefaults.FolderName)
        if FileManager().fileExists(atPath: AppDataURL.path,isDirectory:  &isDirectory) {
            let SecureFileFolderNameURL = AppDataURL.appendingPathComponent(SecureFileDefaults.SecureFolderName)
            if FileManager().fileExists(atPath: SecureFileFolderNameURL.path,isDirectory:  &isDirectory){
                debugPrint("SecureFileLog : SecureFile directory were created already")
                isDirectory = false;
                let SecureFileURL = SecureFileFolderNameURL.appendingPathComponent(SecureFileDefaults.SecureFileName)
                if FileManager().fileExists(atPath: SecureFileURL.path,isDirectory:  &isDirectory){
                    debugPrint("SecureFileLog : SecureFile were created already")
                    return;
                }

            }
            do {
               
                try fileManager.createDirectory(at: SecureFileFolderNameURL, withIntermediateDirectories: true,attributes: nil)
                guard let FilekeyToData = SecureFileKey.data(using: .utf8) else {
                    debugPrint("SecureFileError : FileKey can't convert to data ")
                    return
                }
                guard let keyToData = KeyData.data(using: .utf8) else {
                    debugPrint("SecureFileError : keyToData can't convert to data ")
                    return
                }
                let encryptionKey = SymmetricKey(data: FilekeyToData)
               
                guard CreateSecureFile(data: keyToData, filename: SecureFileDefaults.SecureFileName, encryptionKey: encryptionKey) else {
                    debugPrint("SecureFileError : Failed to create secure file ")
                    return
                }

                return
            } catch let error  {
                debugPrint("SecureFileError : An unexpected error occurred > \(error.localizedDescription)")
                return

            }


        }
        
        
    }
    public static func isSecretFileExists () -> Bool {
        var isDirectory : ObjCBool = true

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        if !FileManager().fileExists(atPath: documentsURL.path,isDirectory:  &isDirectory) {
            return false;
        }

        let AppDataURL = documentsURL.appendingPathComponent(SecureFileDefaults.FolderName)
        if FileManager().fileExists(atPath: AppDataURL.path,isDirectory:  &isDirectory) {
            let SecureFileFolderNameURL = AppDataURL.appendingPathComponent(SecureFileDefaults.SecureFolderName)
            if FileManager().fileExists(atPath: SecureFileFolderNameURL.path,isDirectory:  &isDirectory){
                isDirectory = false;
                let SecureFileURL = SecureFileFolderNameURL.appendingPathComponent(SecureFileDefaults.SecureFileName)
                if FileManager().fileExists(atPath: SecureFileURL.path,isDirectory:  &isDirectory){
                    return true;
                }
                
            }
        }
        return false
    }
    public func GetKey() -> String {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("SecureFile::GetKey(): documents directory not found. .")
            return ""
        }
        let AppDataURL = documentsURL.appendingPathComponent(SecureFileDefaults.FolderName)
        var isDirectory : ObjCBool = true
        if !FileManager().fileExists(atPath: AppDataURL.path,isDirectory:  &isDirectory) {
            debugPrint("SecureFile::GetKey(): AppData directory not found. .")

            return ""
        }
        let SecureFileFolderNameURL = AppDataURL.appendingPathComponent(SecureFileDefaults.SecureFolderName)
        if !FileManager().fileExists(atPath: SecureFileFolderNameURL.path,isDirectory:  &isDirectory){
            debugPrint("SecureFile::GetKey(): SecureFile directory not found. .")

            return "";
        }
        let SecureFileURL = SecureFileFolderNameURL.appendingPathComponent(SecureFileDefaults.SecureFileName)
        isDirectory = false;
        if !FileManager().fileExists(atPath: SecureFileURL.path,isDirectory:  &isDirectory){
            debugPrint("SecureFile::GetKey(): SecureFile not found. .")
            return "";
        }
        do {
            
            guard let keyToData = SecureFile.SecureFileKey.data(using: .utf8) else {
                debugPrint("SecureFile::GetKey(): Failed to convert key string token to data .")
                return ""
            }
            let key = SymmetricKey(data: keyToData)

            // Read encrypted data from file
            let sealedBoxData = try Data(contentsOf: SecureFileURL)
            let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)

            // Decrypt data
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            guard let KeyString = String(data: decryptedData, encoding: .utf8) else {
                debugPrint("SecureFile::GetKey(): Failed to convert key data to string .")
                return ""
            }
            return KeyString

        } catch {
            debugPrint("SecureFile::GetKey(): Failed to read or decrypt secure file: \(error)")
            return ""
        }
        
    }
    
    private func CreateSecureFile(data: Data, filename: String, encryptionKey: SymmetricKey) -> Bool {
        do {
           
            let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
            guard let encryptedData = sealedBox.combined else {
                debugPrint("SecureFileError CreateSecureFile: Failed to combine sealed box data.")
                return false
            }
            
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                debugPrint("SecureFileError CreateSecureFile: Documents directory not found.")

                return false
            }
            
            let AppDataURL = documentsDirectory.appendingPathComponent(SecureFileDefaults.FolderName)
            var isDirectory : ObjCBool = true
            if !FileManager().fileExists(atPath: AppDataURL.path,isDirectory:  &isDirectory){
                debugPrint("SecureFileError CreateSecureFile : AppData directory not found.")
                return false
            }
            
            let SecureFileURL = AppDataURL.appendingPathComponent(SecureFileDefaults.SecureFolderName)
            if !FileManager().fileExists(atPath: SecureFileURL.path,isDirectory:  &isDirectory){
                debugPrint("SecureFileError CreateSecureFile : SecureFile directory not found.")
                return false
            }


            let fileURL = SecureFileURL.appendingPathComponent(filename)

            try encryptedData.write(to: fileURL, options: .atomicWrite)
            debugPrint("SecureFile CreateSecureFile : Secure file created at > \(fileURL.path)")
            return true
        } catch let error {
            debugPrint("SecureFileError CreateSecureFile : An unexpected error occurred > \(error.localizedDescription)")
            return false
        }
    }

    
    
    
}


 
