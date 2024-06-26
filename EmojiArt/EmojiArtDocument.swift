//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Carlos Arriaga on 03/04/24.
//

import SwiftUI

class EmojiArtDocument : ObservableObject {
    
    //Se valida cualquier cambio en Background
        //Si cambia se valida el cambio en fetchBackgroundImageDataIfNecessary()
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    @Published var BackgroundImage: UIImage?
    
    init(){
        emojiArt = EmojiArtModel()
    }
    
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus {
        case idle
        case fetching
    }
    
    //try? - Intenta obtener la data de la url, si falla, asigna nil en lugar de un error
    //DispatchQueue.global(qos: .userInitiated).async - Multithreading, ejecuta en segundo plano
    //DispatchQueue.main.async - Ejecuta en primer plano
        //Actualizacione de UI deben hacerse en primer plano
        //.async - no bloquea el hilo principal mientras se ejecuta
    //[weak self] - Convierte a self.backgroundImage en una entidad debil
        //Siendo una referencia fuerte puede traer problemas de memoria  al no desecharla cuando se deba
        //No lo mantiene en memoria Heap
        //self?.backgroundImage - Pasado el tiempo se elimina la busqueda realizada y volveria a NIL
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        
        switch emojiArt.background {
        case .url(let url):
            backgroundImageFetchStatus = .fetching
            DispatchQueue.global(qos: .userInitiated).async { //Inicia tarea segundo plano
                let imageData = try? Data(contentsOf: url)
                DispatchQueue.main.async { [weak self] in
                    if self?.emojiArt.background == EmojiArtModel.Background.url(url) {
                        self!.backgroundImageFetchStatus = .idle
                        if imageData != nil {   //Se valida que tenga info
                            self?.backgroundImage = UIImage(data: imageData!)
                        }
                    }
                }
            }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    //MARK: - Intent(s)
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("Background set to: \(background)")
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale)
                                                .rounded(.toNearestOrAwayFromZero))
        }
    }
    
}//EmojiArtDocument
