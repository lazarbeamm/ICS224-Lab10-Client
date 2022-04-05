//
//  ClientApp.swift
//  Client
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI

@main
struct ClientApp: App {
    @StateObject var board = Board()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(board)
        }
    }
}

