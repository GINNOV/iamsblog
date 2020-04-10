//
//  macBitmoji Edition
//
//  Login.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/7/20.
//
//  ref: https://github.com/foundry/NSViewControllerPresentation
//  ref: https://www.appcoda.com/macos-programming/
//  ref: https://www.raywenderlich.com/666-filemanager-class-tutorial-for-macos-getting-started-with-the-file-system
//  ref: https://stackoverflow.com/questions/33572444/how-do-i-add-settings-to-my-cocoa-application-in-swift
//  ref: https://developer.apple.com/swift/blog/?id=37

import Cocoa

class Login: NSViewController {
    
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var errorLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cacheFolder = "Pictures/macMoji"
        let picturesfolder = home.appendingPathComponent(cacheFolder)
        if directoryExistsAtPath(picturesfolder.absoluteString) {
            let storyboardName = NSStoryboard.Name(stringLiteral: "Main")
            let storyboard = NSStoryboard(name: storyboardName, bundle: nil)
            let storyboardID = NSStoryboard.SceneIdentifier(stringLiteral: "CatalogID")
            
            if let emojiWindowController = storyboard.instantiateController(withIdentifier: storyboardID) as? Catalog {
                super.presentAsModalWindow(emojiWindowController)
            }
            
            // 3: close this window
            view.window?.close()
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func login(_ sender: Any) {
        // 1: login - it must be the first time
        setupAccount()
    }
    
    func setupAccount() -> Void {
        // 2: get ID
        //getBitmojiAccessToken(email: username.stringValue, password: password.stringValue)
        // 3: get avatar ID
        //getAvatarID()
        // 4: cache images
        getTemplates()
        // 5: go show images
        
    }
    
    // MARK: HELPER
    
    func getBitmojiAccessToken(email : String, password : String) -> Void {
        let semaphore = DispatchSemaphore (value: 0)
        
        let parameters = "client_id=imoji&username=\(email)&password=\(password)&client_secret=secret&grant_type=password"
        let postData =  parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: EndPoints.LoginURL)!,timeoutInterval: Double.infinity)
        request.addValue(EndPoints.RefererURL, forHTTPHeaderField: "Referer")
        request.addValue(EndPoints.HostURL, forHTTPHeaderField: "Host")
        request.addValue(EndPoints.OriginURL, forHTTPHeaderField: "Origin")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                self.errorLabel.stringValue = String(describing: error)
                return
            }
            // print(String(data: data, encoding: .utf8)!)
            do {
                let jsonWithObjectRoot = try JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = jsonWithObjectRoot as? [String: Any] {
                    if let token = dictionary["access_token"] as? String {
                        UserDefaults.standard.set(token, forKey: "bitmoji-token")
                        self.errorLabel.stringValue = "Token acquired."
                    }
                }
            } catch let error {
                self.errorLabel.stringValue = error.localizedDescription
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
    
    func getAvatarID() -> Void {
        let bitmoji_token = UserDefaults.standard.string(forKey: "bitmoji-token")!
        let semaphore = DispatchSemaphore (value: 0)

        var request = URLRequest(url: URL(string: EndPoints.AvatarURL)!,timeoutInterval: Double.infinity)
        request.addValue(bitmoji_token, forHTTPHeaderField: "bitmoji-token")
        request.addValue("bitmoji_bsauth_token=\(bitmoji_token)", forHTTPHeaderField: "Cookie")

        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            self.errorLabel.stringValue = String(describing: error)
            return
          }
          do {
              let jsonWithObjectRoot = try JSONSerialization.jsonObject(with: data, options: [])
              if let dictionary = jsonWithObjectRoot as? [String: Any] {
                  if let token = dictionary["avatar_version_uuid"] as? String {
                      UserDefaults.standard.set(token, forKey: "avatar_version_uuid")
                      self.errorLabel.stringValue = "Avatar ID acquired."
                  }
              }
          } catch let error {
              self.errorLabel.stringValue = error.localizedDescription
          }
          semaphore.signal()
        }

        task.resume()
        semaphore.wait()
    }
    
    func getTemplates() -> Void {

        let semaphore = DispatchSemaphore (value: 0)

        var request = URLRequest(url: URL(string: EndPoints.TemplatesURL)!,timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            self.errorLabel.stringValue = String(describing: error)
            return
          }
          do {
            let jsonWithObjectRoot = try JSONSerialization.jsonObject(with: data, options: [])
              if let dictionary = jsonWithObjectRoot as? [String: Any] {
                for(key, value) in dictionary {
                    print("key: \(key)")
                    print("value: \(value)")
                }
              }
          } catch let error {
            self.errorLabel.stringValue = error.localizedDescription
          }
          semaphore.signal()
        }

        task.resume()
        semaphore.wait()

    }
    
    fileprivate func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}

