//
//  ViewController.swift
//  DinoSpotter
//
//  Created by Mario Esposito on 10/17/19.
//  Copyright © 2019 The Garage Innovation. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    var locationManager : CLLocationManager!
    
    @IBOutlet weak var dangerImage: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
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
    
    func startScanning() {
        let beaconID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
        let constraint = CLBeaconIdentityConstraint(uuid: beaconID, major: 0, minor: 0)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: "Bedroom Beacon")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: constraint)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            updateDistance(beacons[0].proximity)
        } else {
            updateDistance(.unknown)
        }
    }

    // when the beacon is on the screen shows different level of warning
    func updateDistance(_ distance: CLProximity) {
        // https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.8) {
                switch distance {
                case .unknown:
                    self.dangerImage.image = UIImage(imageLiteralResourceName: "mouth-happy")
                    self.messageLabel.text = "Looks safe, go hunt."
                case .far:
                    self.dangerImage.image = UIImage(imageLiteralResourceName: "mouth-teeth")
                    self.messageLabel.text = "Something is fishy..."
                case .near:
                    self.dangerImage.image = UIImage(imageLiteralResourceName: "mouth-watchout")
                    self.messageLabel.text = "It's time to get out of here {cave}man!"
                case .immediate:
                    self.dangerImage.image = UIImage(imageLiteralResourceName: "mouth-oh-shit")
                    self.messageLabel.text = "Ruuuuuuunnnnnnn!!!"
                @unknown default:
                    print("something went very South, investigate and report.")
                }
            }
        }
    }
}

