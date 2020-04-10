//
//  InterfaceController.swift
//  DinoSpotter WatchKit Extension
//
//  Created by Mario Esposito on 10/17/19.
//  Copyright © 2019 The Garage Innovation. All rights reserved.
//  icons from https://icons8.com/icons/set/caveman

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet weak var warningImage: WKInterfaceImage!
    
    // create a an option that will manage the comms between the watch and phone
    let session = WCSession.default

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        warningImage.setImage(UIImage(imageLiteralResourceName: "question-mark"))
// didReceiveApplicationContext is called when you actually receive a new Application Context.
// It is also called shortly after calling WCSession’s activateSession method if the app received a new Application Context while it was closed.
        processApplicationContext()
        
        // make sure that callbacks are received
        session.delegate = self
        session.activate()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    // MARK: DELEGATION
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // we received new data, process it accordingly and on the main thread
        DispatchQueue.main.async() {
            self.processApplicationContext()
        }
    }

    func processApplicationContext() {
        if let iPhoneContext = session.receivedApplicationContext as? [String : String] {
     
            if iPhoneContext["imageToSet"] != nil {
                warningImage.setImage(UIImage(imageLiteralResourceName: iPhoneContext["imageToSet"]!))
                // displayLabel.setText(iPhoneContext["messageToSet"]!)
            }
        }
    }
}
