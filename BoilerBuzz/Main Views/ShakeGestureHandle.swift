//
//  ShakeGestureHandle.swift
//  BoilerBuzz
//
//  Created by user272845 on 2/15/25.
//



import UIKit
import SwiftUI

class ShakeGestureHandler: UIResponder, UIWindowSceneDelegate {
    var onShake: (() -> Void)?

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
}

struct ShakeDetector: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = ShakeHandlingViewController()
        controller.onShake = onShake
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class ShakeHandlingViewController: UIViewController {
    var onShake: (() -> Void)?

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
}

