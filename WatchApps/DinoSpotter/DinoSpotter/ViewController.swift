//
//  ViewController.swift
//  DinoSpotter
//
//  Created by Mario Esposito on 10/17/19.
//  Copyright © 2019 The Garage Innovation. All rights reserved.
//  icons from https://icons8.com/icons/set/caveman

import UIKit
import CoreLocation
import WatchConnectivity

class ViewController: UIViewController, CLLocationManagerDelegate, WCSessionDelegate {

    // object for managing the location
    var locationManager : CLLocationManager!
    // object for managing comms between the hosted app and the watch app
    var session: WCSession?
    
    @IBOutlet weak var dangerImage: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        // setup communications between the app on the phone and the watch app
        // iPad doesn't support watch pairing so we have to check
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            updateDistance(beacons[0].proximity)
        } else {
            updateDistance(.unknown)
        }
    }

    func startScanning() {
        let beaconID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
        let constraint = CLBeaconIdentityConstraint(uuid: beaconID, major: 0, minor: 0)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "Bedroom Beacon")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: constraint)
    }
    
    // when the beacon is on the screen shows different level of warning
    func updateDistance(_ distance: CLProximity) {
        
        var imageToSet = "question-mark"
        var messageToSet = "I am confused"

        switch distance {
        case .unknown:
            imageToSet = "mouth-happy"
            messageToSet = "Looks safe, go hunt."
        case .far:
            imageToSet = "mouth-teeth"
            messageToSet = "Something is fishy..."
        case .near:
            imageToSet =  "mouth-watchout"
            messageToSet = "It's time to get out of here {cave}man!"
        case .immediate:
            imageToSet = "mouth-oh-shit"
            messageToSet = "Ruuuuuuunnnnnnn!!!"
        @unknown default:
            imageToSet = "question-mark"
            messageToSet = "something went very South, investigate and report."
        }
        
        // https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.8) {
                self.view.backgroundColor = .brown
                self.dangerImage.image = UIImage(imageLiteralResourceName: imageToSet)
                self.messageLabel.text = messageToSet
            }
        }
        
        // update the watch UI
        if let validSession = session {
               let iPhoneAppContext = ["imageToSet": imageToSet]
        
               do {
                   try validSession.updateApplicationContext(iPhoneAppContext)
               } catch {
                   print("👀⌚️Something went wrong while talking to the watch")
               }
           }
    }
    
    // MARK: DELEGATIONS
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}

}

