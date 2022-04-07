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
    @State var lastGuessedRow = 0
    @State var lastGuessedCol = 0
    @State var p1Score = "0"
    @State var p3Score = "0"
    @State var border = Color.white
    @State var gameOver = false
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
                if gameOver == false{
                    // Display Scores
                    VStack{
                        Text("P1: \(p1Score)")
                        Text("P2: \(p3Score)")
                    }
                    .padding()

                    // Display Gameboard
                    LazyVGrid(columns: gridLayout, spacing: 10){
                        ForEach((0..<board.tiles.count), id: \.self) { i in //row
                            ForEach((0..<board.tiles.count), id: \.self) { j in //col
                                
                                if(board.tiles[i][j].item == nil){
                                    Button(action: {
                                        networkSupport.send(message: String("\(i),\(j)"))
                                        lastGuessedRow = i
                                        lastGuessedCol = j
                                    }) {
                                        Image(systemName: "circle")
                                    }
                                } else if (board.tiles[i][j].item == "Treasure"){
                                    Button(action: {
                                        networkSupport.send(message: String("\(i),\(j)"))
                                        lastGuessedRow = i
                                        lastGuessedCol = j
                                    }) {
                                        Image(systemName: "mustache.fill")
                                    }
                                } else if (board.tiles[i][j].item == "Guessed"){
                                    Button(action: {
                                        networkSupport.send(message: String("\(i),\(j)"))
                                        lastGuessedRow = i
                                        lastGuessedCol = j
                                    }) {
                                        Image(systemName: "circle.fill")
                                    }
                                }
                            }
                        }
                    }//end Lazy
                } else {
                    if p1Score > p3Score{
                        Text("Game Over! P1 Wins!")
                    } else {
                        Text("Game Over! P2 Wins!")
                    }
                   
                }

            }//end else
        }//end Vstack
        .padding()
        .onChange(of: networkSupport.incomingMessage){ newValue in
            
            print("NEW VALUE: \(newValue)")

            if newValue.starts(with: "Found Treasure"){
                let guessedRow = Array(newValue)[28]
                let guessedCol = Array(newValue)[40]
                let tempScore = Array(newValue)[46]
                let tempOpponentScore = Array(newValue)[49]
                p1Score = String(tempScore)
                p3Score = String(tempOpponentScore)
                print(guessedRow)
                print(guessedCol)
                let guessedRowInt = guessedRow.wholeNumberValue
                let guessedColInt = guessedCol.wholeNumberValue
                print("\nTreasure Found At \(guessedRow), \(guessedCol)")
                board.tiles[guessedRowInt!][guessedColInt!].item = "Treasure"
            }
            if newValue.starts(with: "No Treasure"){
                let guessedRow = Array(newValue)[25]
                let guessedCol = Array(newValue)[37]
                let guessedRowInt = guessedRow.wholeNumberValue
                let guessedColInt = guessedCol.wholeNumberValue
                print("\nNothing Found At \(guessedRow), \(guessedCol)")
                board.tiles[guessedRowInt!][guessedColInt!].item = "Guessed"
             }
            if newValue.starts(with: "Player"){
                if gameOver != true {
                    gameOver.toggle()
                }                
            }
        }//end onChange
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
