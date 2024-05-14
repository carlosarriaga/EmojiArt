//
//  ContentView.swift
//  EmojiArt
//
//  Created by Carlos Arriaga on 02/04/24.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    //Creamos un documento
    @ObservedObject var document: EmojiArtDocument
    
    let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    
    //.onDrop - recibe los Items que se suelten en el
        //Solo recibira de tipo .plainText, url e imagenes
    //providers, location in - se activan al usar onDrop. providers es un contenedor
        //de info del Item y location es un CGPoint
    //OptionalImage - Si tiene una imagen, la carga
    //.scaleEffect(zoomScale) - para que afecte a el BG y emojis ya que el plano crecerá o se reducira al usar doubleTapToZoom()
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack{
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0,0), in: geometry))
                )
                .gesture(doubleTapToZoom(in: geometry.size))
                
                if (document.backgroundImageFetchStatus == .fetching){
                    ProgressView()
                        .scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .scaleEffect(zoomScale)
                            .font(.system(size: fontSize(for: emoji)))
                            .position(position(for: emoji, in: geometry))
                    }
                }
                
                
            }//ZStack
            .clipped() //Para que el background solo use su espacio
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGeture())) //Gesto de pellizco simultaneo con draGesture
        }//Geometry Reader
    }
    
    
    //funciona para detectar que se "dropeo" y procese la info
    //url.imageURL - Extension creada para extraer solo la base de la url de la imagen, sin otra informacion
    //jpegData(compressionQuality: 1.0) - Extrae la data de la imagen y conserva su calidad
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(EmojiArtModel.Background.url(url.imageURL))//No es necesario EmojiArtModel.Background, se infiere
        }
        
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data)) //Infiere el EmojiArtModel.Background
                }
            }
        }
        
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale
                    )
                }
            }
        }
        
        return found
    }
        
    
    
    //En tuplas no es necesario especificar x: emoji.x, y: emoji.y
    func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    //GeometryProxy: Prop. Info sobre la vista en la que se usa el metodo.
    //geometry.frame(in: .local).center: Obtiene el centro del marco (documentBody)
        //.center: fue creado en UtilityExtensions. ya que .frame devuelve una recta
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset : CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue  in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    
    //@STate - Almacena el estado de la vista. Se actualiza la var, se actualiza la vista
        //Es sincrono, cambio inmediato
    //@GestureState - Almacena el estado del gesto
        //Es asincrono, por eso necesita la func zoomGesture para actualizar en tiempo real la vista.
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureScale
    }
    
    //Gesto de pellizco para zoom
    //MagnificationGesture - es el gesto de pellizco
    //updating - se ejecuta continuamente mientras esta en progreso
        //latestGestureScale - escala mas reciente del gesto
        //gestureZoomScale - es una ref. a @GestureState gestureScale
        //Transaction - proporciona info del estado del gesto
    //$gestureScale - $(two way binding) hace la conexion con gestureScale para poder actualizarla
        //Funciona con @gestureState y @State
    //.onEnded - se ejecuta cuando ha terminado
    private func zoomGeture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaledAtEnd in
                steadyStateZoomScale *= gestureScaledAtEnd
            }
    }
    
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }

            }
    }
    
    
    //Funcion para escalar el background y se ajuste al espacio disponible.
    //UIImage? - Es Optional porque puede ser blank
    //min(hZoom, vZoom) - Elige el que ofrezca menos espacio faltante y la imagen se ajuste a eso
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    
    //MARK: Otras vistas
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmojis = "😏🚒⚠️🎳🏄‍♂️🥌🦜🏎😭🎲🚁🖐🏻😜🥺🎯🦁🦀🐔🍑🛼🥊"
}//EmojiArtDocumentView

struct ScrollingEmojisView: View {
    let emojis: String
    
    
    //.map: Mapea los emojis para que se considere individualmente
    //.onDrag: Activa la capacidad de drag
    //NSItemProvider: Encapsula al objeto (emoji y su info) y lo prepara para el drop
    //NSString: para transformar String a un tipo valido para NSItemProvider
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map {String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) }
                }
            }
        }//ScrollView
    }
}
















struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
