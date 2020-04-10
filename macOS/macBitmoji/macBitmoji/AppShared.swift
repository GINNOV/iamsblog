//
//  macBitmoji Edition
//
//  AppShared.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/9/20.
//  Copyright © 2020 IENA WHITE. All rights reserved.
//

import Cocoa

class AppHelper {
    static let shared = AppHelper()
    weak var delegate : MessagesToUser?
    
    // MARK: HELPER
    
    /// A cheap way to get a Berar token for authentication
    /// you get in return an auth token for making further requests
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
                self.delegate?.showMessage(message: String(describing: error))
                return
            }
            // print(String(data: data, encoding: .utf8)!)
            do {
                let jsonWithObjectRoot = try JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = jsonWithObjectRoot as? [String: Any] {
                    if let token = dictionary["access_token"] as? String {
                        UserDefaults.standard.set(token, forKey: "bitmoji-token")
                        self.delegate?.showMessage(message: "Token acquired.")
                    }
                }
            } catch let error {
                self.delegate?.showError(message: error)
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
    
    /// Avatar ID is critical to form the unique URL for your individual avatars
    ///
    func getAvatarID() -> Void {
        let bitmoji_token = UserDefaults.standard.string(forKey: "bitmoji-token")!
        let semaphore = DispatchSemaphore (value: 0)
        
        var request = URLRequest(url: URL(string: EndPoints.AvatarURL)!,timeoutInterval: Double.infinity)
        request.addValue(bitmoji_token, forHTTPHeaderField: "bitmoji-token")
        request.addValue("bitmoji_bsauth_token=\(bitmoji_token)", forHTTPHeaderField: "Cookie")
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                self.delegate?.showMessage(message: String(describing: error))
                return
            }
            do {
                let jsonWithObjectRoot = try JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = jsonWithObjectRoot as? [String: Any] {
                    if let token = dictionary["avatar_version_uuid"] as? String {
                        UserDefaults.standard.set(token, forKey: "avatar_version_uuid")
                        self.delegate?.showMessage(message: "Avatar ID acquired.")
                    }
                }
            } catch let error {
                self.delegate?.showError(message: error)
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
    
    /// Retrieves the whole list of customized emojis and maps it to a class to later
    /// can be used to retrieve all PNGs and store locally tags and other searchable info
    func getTemplates() -> Void {
        
        let semaphore = DispatchSemaphore (value: 0)
        
        var request = URLRequest(url: URL(string: EndPoints.TemplatesURL)!,timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                self.delegate?.showMessage(message: String(describing: error))
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
                self.delegate?.showMessage(message: "Templates retrieved. Parsing...")
            } catch let error {
                self.delegate?.showError(message: error)
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
    }
    
    // MARK: FILE MANAGEMENT
    
    /// Check if given a url that local end point exists
    ///
    func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    /// Once a message/error has been seen it can get out of the way and on its own...
    ///
    func fadeViewInThenOut(view : NSView, delay: Double) {
        
        NSAnimationContext.runAnimationGroup({_ in
            
            //Indicate the duration of the animation
            NSAnimationContext.current.duration = delay
            
            // Make sure it is visible
            view.animator().alphaValue = 1.0
            
        }, completionHandler:{
            // clear up the message line
            view.animator().alphaValue = 0.0
        })
    }
}
