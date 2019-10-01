//
//  DetailInterfaceController.swift
//  DinoBasic WatchKit Extension
//
//  Created by Mario Esposito on 9/29/19.
//  Copyright © 2019 The Garage Innovation. All rights reserved.
//

import WatchKit
import Foundation
import AVFoundation

class DetailInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var dinoName: WKInterfaceLabel!
    @IBOutlet weak var dinoImage: WKInterfaceImage!
    @IBOutlet weak var whatInfo: WKInterfaceLabel!
    
    var player = AVAudioPlayer()
    let audioSession = AVAudioSession.sharedInstance()
    
    let whats = ["allosaurus" : "poops a lot",
                 "ankylosaurus" : "limps when it smiles",
                 "brachiosaurus" : "farts often",
                 "brontosaurus" : "complains for everything",
                 "ceratosaurus" : "marries whales",
                 "diplodocus" : "study like a nerd"]
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
        let name = context as! String
        dinoName.setText(name)
        whatInfo.setText(whats[name]!)
        dinoImage.setImage(UIImage(named:name))
        setFileAudioToPlay(soundToPlay: name)
    }
    
    @IBAction func soundButton() {
        audioSession.activate(options: []) { (success, error) in
            guard error == nil else {
                print("*** error occurred: \(error!.localizedDescription) ***")
                    // Handle the error here.
                return
            }
            if(success){
                // Play the audio file.
                self.player.play()
            }
        }
    }
    
    func setFileAudioToPlay(soundToPlay fileToPlay : String) {
        do {
            // Working Reroutes to headset
            //            try session.setCategory(AVAudioSession.Category.playback,
            //                                    mode: .default,
            //                                    policy: .longForm,
            //                                    options: [])
            
            // Plays in watch speaker
            try audioSession.setCategory(AVAudioSession.Category.playback,
                                         mode: .default,
                                         policy: .default,
                                         options: [])
        } catch let error {
            fatalError("*** Unable to set up the audio session: \(error.localizedDescription) ***")
        }
        
        // select from the bundle which file we want to play
        if let path = Bundle.main.url(forResource: fileToPlay, withExtension: "wav") {
            let fileUrl = path
            do{
                // tell the player, when I hit play you are going to play the selected sound - got it?!
                player = try AVAudioPlayer(contentsOf: fileUrl)
            }
            catch
            {
                print("*** Unable to set up the audio player: \(error.localizedDescription) ***")
                // Handle the error here.
                return
            }
        }
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
