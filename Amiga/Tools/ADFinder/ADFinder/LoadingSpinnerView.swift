//
//  LoadingSpinnerView.swift
//  ADFinder
//
//  Created by Mario Esposito on 5/23/25.
//


import SwiftUI

struct LoadingSpinnerView: View {
    @Binding var isLoading: Bool
    let onCancel: () -> Void

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)

                    Button(action: {
                        onCancel() // Trigger cancellation
                    }) {
                        Text("Cancel")
                            .font(.body)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
        }
    }
}
