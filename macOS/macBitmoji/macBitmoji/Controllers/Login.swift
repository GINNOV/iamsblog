//
//  macBitmoji Edition
//
//  Login.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/7/20.
//


import Cocoa

class Login: NSViewController, AppMessages {
    
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var errorLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppHelper.shared.delegate = self
        
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cacheFolder = "Pictures/macMoji"
        let picturesfolder = home.appendingPathComponent(cacheFolder)
        if AppHelper.shared.directoryExistsAtPath(picturesfolder.absoluteString) {
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
        setupAccount()
    }
    
    func setupAccount() -> Void {
        
        // 2: get ID
        //AppHelper.shared.getBitmojiAccessToken(email: username.stringValue, password: password.stringValue)
        
        // 3: get avatar ID
        //AppHelper.shared.getAvatarID()
        
        // 4: cache images
        AppHelper.shared.getTemplates(matching: "") { (_: [Bits]) in
            self.showMessage(message: "gathering all your avatars...")
            
            // 5: go show images
//            let storyboardName = NSStoryboard.Name(stringLiteral: "Main")
//            let storyboard = NSStoryboard(name: storyboardName, bundle: nil)
//            let storyboardID = NSStoryboard.SceneIdentifier(stringLiteral: "CatalogID")
//
//            if let emojiWindowController = storyboard.instantiateController(withIdentifier: storyboardID) as? Catalog {
//                super.presentAsModalWindow(emojiWindowController)
//            }
        }
    }
    
    // MARK: DELEGATES
    
    func showMessage(message: String) {
        DispatchQueue.main.async {
            AppHelper.shared.fadeViewInThenOut(view: self.errorLabel, delay: 5.0)
            self.errorLabel.stringValue = "ℹ️ \(message)"
        }
    }
    
    func showError(message: Error) {
        DispatchQueue.main.async {
            AppHelper.shared.fadeViewInThenOut(view: self.errorLabel, delay: 5.0)
            self.errorLabel.stringValue = "🤦🏻‍♀️ \(message.localizedDescription)"
        }
    }
    
    func loginState(state: ExecutionStatus) {
        AppHelper.shared.logInfo(whatToLog: "not implemented")
    }
    
    func bitMojiQuery(state: ExecutionStatus) {
        AppHelper.shared.logInfo(whatToLog: "not implemented")
    }
    
    func bitMojiQuery(state: ExecutionStatus, data: Bits) {
        //AppHelper.shared.logInfo(whatToLog: "not implemented")
        let AvatarUUID = UserDefaults.standard.string(forKey: AppKeys.AvatarUUID)
         
        var comicURL = URL(string: "\(EndPoints.BitStripsURL)/\(data.imoji[0].comicID)-\(AvatarUUID!)-v1.png")
        AppHelper.shared.loadFileSync(url: comicURL!) { (path, error) in
            guard error == nil else {
                print(error?.localizedDescription)
                return
            }
            AppHelper.shared.logInfo(whatToLog: "file downloaded in \(path)")
        }
    }
}
