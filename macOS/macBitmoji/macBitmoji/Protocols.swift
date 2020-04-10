//
//  macBitmoji Edition
//
//  Protocols.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/9/20.
//  Copyright © 2020 IENA WHITE. All rights reserved.
//

import Foundation

protocol MessagesToUser : class {
    func showMessage(message: String)
    func showError(message : Error)
}
