//
//  ConfirmationDialog.swift
//  ADFinder
//
//  Created by Mario Esposito on 6/13/25.
//

import SwiftUI

extension View {
    func confirmationSheet(
        config: Binding<ConfirmationConfig?>,
        forceFlag: Binding<Bool>
    ) -> some View {
        // Use the .sheet(item:onDismiss:content:) modifier
        self.sheet(item: config, onDismiss: {
            // Reset the flag when the sheet is dismissed for any reason.
            forceFlag.wrappedValue = false
        }) { item in // 'item' is the unwrapped ConfirmationConfig
            ActionConfirmationView(
                title: item.title,
                message: item.message,
                imageName: item.imageName,
                confirmButtonTitle: item.confirmButtonTitle,
                confirmButtonRole: .destructive,
                showsForceToggle: item.showsForceToggle,
                forceFlag: forceFlag, // Pass the binding for the toggle's state directly to the view
                onConfirm: {
                    // The action is executed with the current state of the force flag.
                    item.action(forceFlag.wrappedValue)
                    // To dismiss the sheet, we set the source binding to nil.
                    config.wrappedValue = nil
                },
                onCancel: {
                    // To dismiss the sheet, we set the source binding to nil.
                    config.wrappedValue = nil
                }
            )
        }
    }
}
