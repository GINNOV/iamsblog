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
import Logging

class AppHelper {
    static let shared = AppHelper()
    weak var delegate : AppMessages?
    
    var logger = Logger(label: "com.thegarageinnovation.macBitmoji")
    
    // MARK: ENDPOINTS HELPER
    
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
        let bitmoji_token = UserDefaults.standard.string(forKey: "\(AppKeys.Token)")!
        let semaphore = DispatchSemaphore (value: 0)
        
        var request = URLRequest(url: URL(string: EndPoints.AvatarURL)!,timeoutInterval: Double.infinity)
        request.addValue(bitmoji_token, forHTTPHeaderField: "bitmoji-token")
        request.addValue("\(EndPointsParams.Token)=\(bitmoji_token)", forHTTPHeaderField: "Cookie")
        
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                self.delegate?.showMessage(message: String(describing: error))
                return
            }
            do {
                let jsonWithObjectRoot = try JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = jsonWithObjectRoot as? [String: Any] {
                    if let token = dictionary[AppKeys.AvatarUUID] as? String {
                        UserDefaults.standard.set(token, forKey: AppKeys.AvatarUUID)
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
    
    func getTemplates(matching query: String, completion: ([Bits]) -> Void) {
        var searchURLComponents = URLComponents() // base URL components of the web service
        
        searchURLComponents.scheme = "https"
        searchURLComponents.host = EndPoints.HostURL
        searchURLComponents.path = "/content/templates"
        searchURLComponents.queryItems = [
            URLQueryItem(name: "app_name", value: EndPointsParams.AppName),
            URLQueryItem(name: "platform", value: EndPointsParams.Platform)
        ]
        
        let searchURL = searchURLComponents.url!
        
        let semaphore = DispatchSemaphore (value: 0)
        
        var request = URLRequest(url: searchURL, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler:  { (data, _, error) in
            guard let data = data else {
                self.delegate?.showMessage(message: String(describing: error))
                return
            }
            
            do {
                // Store auth data for future usage
                let decoder = JSONDecoder()
                let jsonResponse = try decoder.decode(Bits.self, from: data)

                self.delegate?.bitMojiQuery(state: .succeess, data: jsonResponse)
            } catch let parsingError {
                // check if the error generated a server error code
                AppHelper.shared.logError(whatToLog: "\(parsingError.localizedDescription)")
                semaphore.signal()
                self.delegate?.bitMojiQuery(state: .failed)
            }
            // call completion handler
            semaphore.signal()
        })
        task.resume()
        semaphore.wait()
    }
    
    func getComic(comicID: String) -> Void {
        let semaphore = DispatchSemaphore (value: 0)
        let AvatarUUID = UserDefaults.standard.string(forKey: AppKeys.AvatarUUID)!
        var request = URLRequest(url: URL(string: "\(EndPoints.AvatarURL)/\(comicID)-\(AvatarUUID)-v1.png")!,timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            self.delegate?.showMessage(message: String(describing: error))
            AppHelper.shared.logError(whatToLog: String(describing: error))
            return
          }
            
            print(String(data: data, encoding: .utf8)!)
          semaphore.signal()
        }

        task.resume()
        semaphore.wait()
    }
    
    func readJSONFromFile(fileName: String) -> Any? {
        var json: Any?
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            do {
                let fileUrl = URL(fileURLWithPath: path)
                // Getting data from JSON file using the file URL
                let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                json = try? JSONSerialization.jsonObject(with: data)
            } catch {
                // Handle error here
            }
        }
        return json
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
    
    // MARK: LOGGING
       
       func logInfo(whatToLog: String, dataBlog: String = "") -> Void {
           logger.logLevel = .info
           logger[metadataKey: "appData"] = "\(dataBlog)"
           logger.trace("ℹ️ \(whatToLog)")
           print("ℹ️ \(whatToLog)")
       }
       
       func logWarning(whatToLog: String, dataBlog: String = "") -> Void {
           logger.logLevel = .warning
           logger[metadataKey: "appData"] = "\(dataBlog)"
           logger.trace("😱 \(whatToLog)")
           print("😱 \(whatToLog)")
       }

       func logError(whatToLog: String, dataBlog: String = "") -> Void {
           logger.logLevel = .error
           logger[metadataKey: "appData"] = "\(dataBlog)"
           logger.trace("☢️ \(whatToLog)")
           print("☢️ \(whatToLog)")
       }

       func logError(whatToLog: String, dataBlog: Any) -> Void {
           logger.logLevel = .debug
           logger[metadataKey: "appData"] = "\(dataBlog)"
           logger.trace("🧐 \(whatToLog)")
           print("☢️ \(whatToLog)")
       }

       func logDebug(whatToLog: String, dataBlog: String = "") -> Void {
           logger.logLevel = .debug
           logger[metadataKey: "appData"] = "\(dataBlog)"
           logger.trace("🧐 \(whatToLog)")
           print("🧐 \(whatToLog)")
       }
       
       func logDebug(whatToLog: String, dataBlog: Any) -> Void {
           logger.logLevel = .debug
           logger[metadataKey: "appData"] = "\(dataBlog)"
           logger.trace("🧐 \(whatToLog)")
           print("🧐 \(whatToLog)")
       }
    
    // MARK: DOWNLOADER
    
    func loadFileAsync(url: URL, completion: @escaping (String?, Error?) -> Void)
    {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)

        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else
        {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(with: request, completionHandler:
            {
                data, response, error in
                if error == nil
                {
                    if let response = response as? HTTPURLResponse
                    {
                        if response.statusCode == 200
                        {
                            if let data = data
                            {
                                if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                                {
                                    completion(destinationUrl.path, error)
                                }
                                else
                                {
                                    completion(destinationUrl.path, error)
                                }
                            }
                            else
                            {
                                completion(destinationUrl.path, error)
                            }
                        }
                    }
                }
                else
                {
                    completion(destinationUrl.path, error)
                }
            })
            task.resume()
        }
    }
    
    func loadFileSync(url: URL, completion: @escaping (String?, Error?) -> Void)
    {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cacheFolder = "Pictures/macMoji"
        let picturesfolder = home.appendingPathComponent(cacheFolder)
        
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)

        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else if let dataFromURL = NSData(contentsOf: url)
        {
            if dataFromURL.write(to: destinationUrl, atomically: true)
            {
                print("file saved [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            }
            else
            {
                print("error saving file")
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(destinationUrl.path, error)
            }
        }
        else
        {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(destinationUrl.path, error)
        }
    }
}
