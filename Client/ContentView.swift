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
    @State var lastGuessedRow = 0
    @State var lastGuessedCol = 0
    @State var playerScore = 0
    @State var opponentScore = 0
    @State var border = Color.white
    @EnvironmentObject var board: Board
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
    
    var body: some View {
        VStack {
            if !networkSupport.connected {
                
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
                // Display Gameboard
                VStack{
                    Text("Your Score: \(playerScore)")
                    Text("Opponents Score: \(opponentScore)")
                }
                .padding()

                
                LazyVGrid(columns: gridLayout, spacing: 10){
                    ForEach((0..<board.tiles.count), id: \.self) { i in
                        ForEach((0..<board.tiles.count), id: \.self) { j in
                            
                            if(board.tiles[i][j].item == nil){
                                Button("N", action: { // not yet guessed
                                    networkSupport.send(message: String("\(i),\(j)"))
                                    lastGuessedCol = j
                                    lastGuessedRow = i
                                    outgoingMessage = ""
                                })
                            } else if (board.tiles[i][j].item == "Treasure"){
                                Button("T", action: { // treasure
                                    // When Player Presses Button (A tile on the grid), transmit that grid information to server
                                    networkSupport.send(message: String("\(i),\(j)"))
                                    lastGuessedCol = j
                                    lastGuessedRow = i
                                    outgoingMessage = ""
                                })
                            } else if (board.tiles[i][j].item == "Guessed"){
                                Button("G", action: { // guessed, no treasure
                                    networkSupport.send(message: String("\(i),\(j)"))
                                    lastGuessedCol = j
                                    lastGuessedRow = i
                                    outgoingMessage = ""
                                })
                            }
                        }
                    }
                }//end Lazy
            }//end else
        }//end Vstack
        .padding()
        .onChange(of: networkSupport.incomingMessage){ newValue in
            // Handle incoming message here
            // This could be request for board state, or a move request (col, row)
            // If the same incomingMessage is sent twice, this will not trigger a second time (only called on change)
            
//            print(newValue)

            if newValue.starts(with: "Found Treasure"){
                print("\nTreasure Found At \(lastGuessedRow), \(lastGuessedCol)")
                board.tiles[lastGuessedRow][lastGuessedCol].item = "Treasure"
            } else if newValue.starts(with: "No Treasure"){
                print("\nNothing Found At \(lastGuessedRow), \(lastGuessedCol)")
                board.tiles[lastGuessedRow][lastGuessedCol].item = "Guessed"
            } else if newValue.starts(with: "Score"){
                playerScore += 1
            }
        }
    }
}

struct Tile: Identifiable, Hashable {
    static func == (lhs: Tile, rhs: Tile) -> Bool {
        return  lhs.id == rhs.id
    }
    
    let id = UUID()
    var item: String?
    var rowNumber: Int
    var colNumber: Int
    
    init(item: String?, rowNumber: Int, colNumber: Int){
        self.item = item
        self.rowNumber = rowNumber
        self.colNumber = colNumber
    }

}

class Board: ObservableObject {
    let boardSize = 10
    // declare an array of tiles caled tiles
    @Published var tiles: [[Tile]]
    
    init(){
        // create the tiles array
        tiles = [[Tile]]()
        
        for i in 0..<boardSize{
            var tileRow = [Tile]()
            for j in 0..<boardSize{
                let t = Tile(item: nil, rowNumber: i, colNumber: j)
//                print(t)
//                print(t.id, t.rowNumber, t.colNumber)
                tileRow.append(t)
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




//                LazyVGrid(columns: gridLayout, spacing: 10){
//                    ForEach(board.tiles, id: \.self) { row in
//                        ForEach(row) { cell in
//
//                            if (cell.item == nil){
//                                Button("N", action: { // not yet guessed
//                                    // When Player Presses Button (A tile on the grid), transmit that grid information to server
//                                    networkSupport.send(message: String("\(cell.rowNumber),\(cell.colNumber)"))
//                                    lastGuessedCol = cell.colNumber
//                                    lastGuessedRow = cell.rowNumber
//                                    outgoingMessage = ""
//                                })
//                            } else if (cell.item == "Treasure"){
//                                Button("T", action: { // treasure
//                                    // When Player Presses Button (A tile on the grid), transmit that grid information to server
//                                    networkSupport.send(message: String("\(cell.rowNumber),\(cell.colNumber)"))
//                                    lastGuessedCol = cell.colNumber
//                                    lastGuessedRow = cell.rowNumber
//                                    outgoingMessage = ""
//                                })
//                            } else if (cell.item == "Guessed"){
//                                Button("G", action: { // guessed, no treasure
//                                    // When Player Presses Button (A tile on the grid), transmit that grid information to server
//                                    networkSupport.send(message: String("\(cell.rowNumber),\(cell.colNumber)"))
//                                    lastGuessedCol = cell.colNumber
//                                    lastGuessedRow = cell.rowNumber
//                                    outgoingMessage = ""
//                                })
//                            }
//                        }
//                    }
//                }//end of LazyVGrid
//                    .border(border)
