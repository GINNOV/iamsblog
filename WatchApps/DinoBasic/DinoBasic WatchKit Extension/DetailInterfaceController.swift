//
//  DetailInterfaceController.swift
//  DinoBasic WatchKit Extension
//
//  Created by Mario Esposito on 9/29/19.
//  Copyright © 2019 The Garage Innovation. All rights reserved.
//

import WatchKit
import Foundation


class DetailInterfaceController: WKInterfaceController {

    @IBOutlet weak var dinoName: WKInterfaceLabel!
    @IBOutlet weak var dinoImage: WKInterfaceImage!
    @IBOutlet weak var whatInfo: WKInterfaceLabel!
    
    let whats = ["allosaurus" : "poops a lot",
                 "ankylosaurus" : "limps when it smiles",
                 "brachiosaurus" : "farts often",
                 "ceratosaurus" : "marries whales",
                 "diplodocus" : "study like a nerd"]
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        let name = context as! String
        dinoName.setText(name)
        whatInfo.setText(whats[name]!)
        dinoImage.setImage(UIImage(named:name))
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
