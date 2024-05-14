//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Carlos Arriaga on 02/04/24.
//

import Foundation
import UIKit

struct EmojiArtModel {
    var background = Background.blank
    var emojis = [Emoji]()
    
    
    struct Emoji : Identifiable, Hashable {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        var id: Int
        
        //Para prevenir que se acceda a Emoji, pero sin bloquear la capacidad de crearlos cuando se ejecute
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int){
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
    
    //Para prevenir que accedan a background y emojis
    init(){}
    
    
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int){
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
    
    
}
