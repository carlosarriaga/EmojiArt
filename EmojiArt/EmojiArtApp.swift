//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Carlos Arriaga on 02/04/24.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        let document = EmojiArtDocument()
        
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
