//
//  InterfaceController.swift
//  DinoBasic WatchKit Extension
//
//  Created by Mario Esposito on 9/29/19.
//  Copyright © 2019 The Garage Innovation. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var tableView: WKInterfaceTable!
    
    var dinos = ["allosaurus", "ankylosaurus", "brachiosaurus", "brontosaurus", "ceratosaurus", "diplodocus"] // lazy to add more...
    
    func setupTable() {
        tableView.setNumberOfRows(dinos.count, withRowType: "DinoRow")
        
        for i in 0..<dinos.count {
            if let row = tableView.rowController(at: i) as? DinoRow {
                row.dinoName.setText(dinos[i])
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        setupTable()
    }
        
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        self.pushController(withName: "showDetails", context: dinos[rowIndex])
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
