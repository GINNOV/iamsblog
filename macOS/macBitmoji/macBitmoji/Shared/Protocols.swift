//
//  Protocols.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/27/20.
//  Copyright © 2020 IENA WHITE. All rights reserved.
//

import Foundation

protocol AppMessages : class {
    func loginState(state: ExecutionStatus) -> Void
    func bitMojiQuery(state: ExecutionStatus) -> Void
    func bitMojiQuery(state: ExecutionStatus, data: Bits) -> Void
    func showMessage(message: String)
    func showError(message : Error)
}
