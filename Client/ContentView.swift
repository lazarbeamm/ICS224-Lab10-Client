//
//  ContentView.swift
//  Client
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI

struct ContentView: View {
    @State var message = ""
    @StateObject var networkSupport = NetworkSupport(browse: true)
    @State var outgoingMessage = ""
    @State var board = Board()
    
    // Create layout for LazyGrid to adhere to (in this case, a 10 x 10 grid)
    private var gridLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    // Define Data LazyGrid will display
    let gridData = (1...100).map { "\($0)" }
    
    
    
    var body: some View {
        VStack {
            if !networkSupport.connected {
                TextField("Message", text: $message)
                    .multilineTextAlignment(.center)
                
                List ($networkSupport.peers, id: \.self) {
                    $peer in
                    Button(peer.displayName) {
                        do {
                            try networkSupport.contactPeer(peerID: peer, request: Request(details: message))
                        }
                        catch let error {
                            print(error)
                        }
                    }
                }
            }
            else {
                TextField("Message", text: $outgoingMessage)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Display Gameboard Test
//                LazyVGrid(columns: gridLayout, spacing: 10){
//                    ForEach(gridData, id: \.self) { item in
//                        Text(item)
//                    }
//                }
                
                // Display Gameboard Real
                LazyVGrid(columns: gridLayout, spacing: 10){
                    ForEach((0...9), id: \.self) { row in
                        ForEach((0...9), id: \.self) { col in
                            Button("\(row),\(col)", action: {
                                // When Player Presses Button (A tile on the grid), transmit info to server
                                networkSupport.send(message: String("\(row),\(col)"))
                                outgoingMessage = ""
                            })
                        }
                    }
                }//end of LazyVGrid
                
                Button("Send") {
                    networkSupport.send(message: outgoingMessage)
                    outgoingMessage = ""
                }
                .padding()
                
                Text(networkSupport.incomingMessage)
                    .padding()
            }
        }
        .padding()
        .onChange(of: networkSupport.incomingMessage){ newValue in
            // Handle incoming message here
            // This could be request for board state, or a move request (col, row)
            // If the same incomingMessage is sent twice, this will not trigger a second time (only called on change)
        }
    }
}

class Tile {
    var item: String?
    
    init(item: String?){
        self.item = item
    }
    
    deinit{
        print("Deinitializing Tile")
    }
}

class Board {
    let boardSize = 10
    // declare an array of tiles caled tiles
    var tiles: [[Tile]]
    
    init(){
        // create the tiles array
        tiles = [[Tile]]()
        
        for _ in 1...boardSize{
            var tileRow = [Tile]()
            for _ in 1...boardSize{
                tileRow.append(Tile(item: nil))
            }
            tiles.append(tileRow)
        }
    }
    
    deinit{
        print("Deinitializing Board")
    }
    
    
    
    subscript(row: Int, column: Int) -> String? {
        get {
            if(row < 0) || (boardSize <= row) || (column < 0) || (boardSize <= column){
                return nil
            } else {
                return tiles[row][column].item
            }
        }
        set {
            if(row < 0) || (boardSize <= row) || (column < 0) || (boardSize <= column){
                return
            } else {
                tiles[row][column].item = newValue
            }
        }
    }//end of subscript helper
    
}//end of Board class
