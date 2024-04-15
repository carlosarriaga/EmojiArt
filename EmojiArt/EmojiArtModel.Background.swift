//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by Carlos Arriaga on 02/04/24.
//

import Foundation


extension EmojiArtModel{
    enum Background {
        case blanc
        case url(URL)
        case imageData(Data)
        
        var url: URL? {
            switch self {
            case .url(let url): return url
            default: return nil
            }
        }
        
        var imageData: Data? {
            switch self {
            case .imageData(let data): return data
            default: return nil
            }
        }
    }//enum
}
