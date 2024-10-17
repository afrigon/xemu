import SwiftUI
import Vapor

struct GameUploadServerView: SwiftUI.View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    @State var app: Application
    @State var ip: String?

    let isPresented: Binding<Bool>
    let onFileUpload: (String, Data) -> Bool
    let port: Int = 4567
    
    init(isPresented: Binding<Bool>, onFileUpload: @escaping (String, Data) -> Bool) {
        self.isPresented = isPresented
        self.onFileUpload = onFileUpload
        self.ip = NetworkLocalAddress.get()

        
#if DEBUG
        app = Application(.development)
#else
        app = Application(.production)
#endif
        
        configure()
    }
    
    var body: some SwiftUI.View {
        NavigationStack {
            VStack(spacing: .xxxl) {
                    if let ip, let url = URL(string: "http://\(ip):\(port)") {
                        QRCodeView(url)
                            .frame(width: 300, height: 300)
                            .clipShape(.doubleRoundedRectangle)
                            .padding(.xl)
                            .background(.roleMuted)
                            .clipShape(.doubleRoundedRectangle)
                            .environment(\.colorRole, .primary)
                        
                        Group {
                            Text("Your upload server is started at")
                            +
                            Text(verbatim: " ")
                            +
                            Text(verbatim: url.absoluteString)
                        }
                        .retroTextStyle(size: .title)
                    } else {
                        Text("Your upload server is started.")
                            .retroTextStyle(size: .title)
                    }

                Button("Done") {
                    isPresented.wrappedValue = false
                }
            }
        }
        .vaporApp(isPresented: isPresented, app: $app)
    }
    
    private func configure() {
        app.http.server.configuration.serverName = "Xemu"
        app.http.server.configuration.hostname = "0.0.0.0"
        app.http.server.configuration.port = port
        
        // Routes
        app.routes.defaultMaxBodySize = "50MB"
        
#if DEBUG
        app.logger.logLevel = .debug
#endif
        
        do {
            let fileMiddleware = try FileMiddleware(
                bundle: .main,
                publicDirectory: ".",
                defaultFile: "index.html"
            )
            // TODO: Figure out how to not expore the entire bundle
            
            app.middleware.use(fileMiddleware)
        } catch let error {
            print(error)
        }

        app.routes.post("upload") { req in
            DispatchQueue.main.async {
                guard let data = try? req.content.decode(GameUploadBody.self) else {
                    return
                }
                
                _ = onFileUpload(data.file.filename, Data(buffer: data.file.data))
            }
            
            return HTTPStatus.accepted
        }
    }
}

struct GameUploadBody: Content {
    var file: File
}
