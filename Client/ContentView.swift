//
//  ContentView.swift
//  Client
//
//  Created by Michael on 2022-02-24.
//

import SwiftUI

struct ContentView: View {
    /// A String used to hold any messages sent from the server or other clients, to this client
    @State var message = ""
    /// An instantiation of the NetworkSupport class, used to facilitate matters relating to setting up Server and Client Multipeer services
    @StateObject var networkSupport = NetworkSupport(browse: true)
    /// A string representation of the first player that connects to the servers score
    @State var p1Score = "0"
    /// A string representation of the second player that connects to the servers score
    @State var p2Score = "0"
    /// An integer representing the index (within a string) containing the row the player guessed, when treasure was found (coming from the server)
    private var index_of_row_with_treasure = 28
    /// An integer representing the index (within a string) containing the column the player guessed, when treasure was found (coming from the server)
    private var index_of_col_with_treasure = 40
    /// An integer representing the index containing the score of the first player (coming from the server)
    private var index_of_p1_score = 46
    /// An integer representing the index containing the score of the second player (coming from the server)
    private var index_of_p2_score = 49
    /// An integer representing the index (within a string) containing the row the player guessed, when no treasure was found (coming from the server)
    private var index_of_row_without_treasure = 25
    /// An integer representing the index (within a string)  containing the row the player guessed, when no treasure was found (coming from the server)
    private var index_of_col_without_treasure = 37
    /// A boolean representing the state of the game (true == there are still treasures left to find, false == all treasures have been found & the game has ended)
    @State var gameOver = false
    /// A reference to the instantiated Board object, which stores the information pertaining to each of the 100 gameboard tiles
    @EnvironmentObject var board: Board
    /// Create layout for LazyGrid to adhere to (in this case, a 10 x 10 grid)
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
                // If the game is still active, display the current scores, and gameboard
                if gameOver == false{
                    // Display Scores
                    VStack{
                        Text("P1: \(p1Score)")
                        Text("P2: \(p2Score)")
                    }
                    .padding()

                    // Display Gameboard
                    LazyVGrid(columns: gridLayout, spacing: 10){
                        ForEach((0..<board.tiles.count), id: \.self) { i in //row
                            ForEach((0..<board.tiles.count), id: \.self) { j in //col
                                
                                if(board.tiles[i][j].item == nil){
                                    Button(action: {
                                        networkSupport.send(message: String("\(i),\(j)"))
                                    }) {
                                        Image(systemName: "circle")
                                    }
                                } else if (board.tiles[i][j].item == "Treasure"){
                                    Button(action: {
                                        networkSupport.send(message: String("\(i),\(j)"))
                                    }) {
                                        Image(systemName: "mustache.fill")
                                    }
                                } else if (board.tiles[i][j].item == "Guessed"){
                                    Button(action: {
                                        networkSupport.send(message: String("\(i),\(j)"))
                                    }) {
                                        Image(systemName: "circle.fill")
                                    }
                                }
                            }
                        }
                    }//end Lazy
                } else {
                    // All treasures have been found - Display the winner
                    if p1Score > p2Score{
                        Text("Game Over! P1 Wins!")
                    } else {
                        Text("Game Over! P2 Wins!")
                    }
                }
            }//end else
        }//end Vstack
        .padding()
        .onChange(of: networkSupport.incomingMessage){ newValue in
            
            if newValue.starts(with: "Found Treasure"){ // The server response, indicating treasure was found by the last guess
                // Parse the incoming message from the server, and extract the row the player guessed
                let guessedRow = Array(newValue)[index_of_row_with_treasure]
                // Parse the incoming message from the server, and extract the column the player guessed
                let guessedCol = Array(newValue)[index_of_col_with_treasure]
                // Parse the incoming message from the server, and extract the current players score
                let tempScore = Array(newValue)[index_of_p1_score]
                // Parse the incoming message from the server, and extract the opponent players score
                let tempOpponentScore = Array(newValue)[index_of_p2_score]
                // Convert the current players parsed score into a String
                p1Score = String(tempScore)
                // Convert the opponent players parsed score into a String
                p2Score = String(tempOpponentScore)
                // Convert the row the player guessed into an integer
                let guessedRowInt = guessedRow.wholeNumberValue
                // Convert the column the player guessed into an integer
                let guessedColInt = guessedCol.wholeNumberValue
                // Update the board's tile array to refelect the treasure found at the row & column the player guessed
                board.tiles[guessedRowInt!][guessedColInt!].item = "Treasure"
//                print("\nTreasure Found At \(guessedRow), \(guessedCol)")
            }
            if newValue.starts(with: "No Treasure"){ // The server response, indicating no treasure was found by the last guess
                // Parse the incoming message from the server, and extract the row the player guessed
                let guessedRow = Array(newValue)[index_of_row_without_treasure]
                // Parse the incoming message from the server, and extract the column the player guessed
                let guessedCol = Array(newValue)[index_of_col_without_treasure]
                // Convert the row the player guessed into an integer
                let guessedRowInt = guessedRow.wholeNumberValue
                // Convert the column the player guessed into an integer
                let guessedColInt = guessedCol.wholeNumberValue
                // Update the board's tile array to reflect the empty tile (no treasure) at the row & column the player guessed
                board.tiles[guessedRowInt!][guessedColInt!].item = "Guessed"
//                print("\nNothing Found At \(guessedRow), \(guessedCol)")
             }
            if newValue.starts(with: "Player"){ // The server response, indicating one of the players has won the game, and all treasure are found
                
                // toggle the boolean gameOver variable so the gameover view is displayed instead of the gameboard
                if gameOver != true {
                    gameOver.toggle()
                }
            }
        }//end onChange
    }
}


/// Defines the structure for the Tile object, which is used by the Board class to instantiate a gameboard
struct Tile: Identifiable, Hashable {
    
//    static func == (lhs: Tile, rhs: Tile) -> Bool {
//        return  lhs.id == rhs.id
//    }
    
    /// A unique identifier for each tile
    let id = UUID()
    /// The contents of a given tile. May be nil (empty), "Guessed" or "Treasure"
    var item: String?
    /// A reference to the row position the tile occupies on the gameboard
    var rowNumber: Int
    /// A reference to the column position the tile occupies on the gameboard
    var colNumber: Int
    
    
    /// The default initializer for a tile object
    /// - Parameters:
    ///   - item: The string representation of what a given tile contains (nil, guessed, or treasure)
    ///   - rowNumber: An integer representing the row position the tile occupies
    ///   - colNumber: An integer representing the column position the tile occupies
    init(item: String?, rowNumber: Int, colNumber: Int){
        self.item = item
        self.rowNumber = rowNumber
        self.colNumber = colNumber
    }

}

/// This class is used behind the scenes to represent the state of the game, in the form of an array of tile objects called tiles
/// The board class is instantated once during startup, and initially each tile in the array is empy (nil)
/// As players take turns guessing, the board is updated to reflect whether or not a tile has been guessed and is empty, or has been guessed and contained treasure
class Board: ObservableObject {
    /// The size of a board object (in this case, 10 x 10)
    let boardSize = 10
    /// An array of tile objects, used to store information about the gamestate
    @Published var tiles: [[Tile]]
    
    
    /// The default initializer for the Board object
    init(){
        // create the tiles array
        tiles = [[Tile]]()
        
        for i in 0..<boardSize{
            var tileRow = [Tile]()
            for j in 0..<boardSize{
                let t = Tile(item: nil, rowNumber: i, colNumber: j)
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
