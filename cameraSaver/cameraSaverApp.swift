//
//  cameraSaverApp.swift
//  cameraSaver
//
//  Created by Aleksandr Popov on 5/24/23.
//


import SwiftUI
import AVKit
import Photos

struct ContentView: View {
    var body: some View {
        UIViewControllerWrapper()
            .edgesIgnoringSafeArea(.all)
    }
}

struct UIViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = ViewController

    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // No update needed
    }
}

//@main
//struct cameraSaverApp: App {
//    var body: some Scene {
//        WindowGroup {
//            VideoCaptureView()
//        }
//    }
//}

@main
struct cameraSaverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

