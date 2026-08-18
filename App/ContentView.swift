import SwiftUI
import Network

@main
struct iPadReceiverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var currentImage: UIImage? = nil
    @State private var listener: NWListener?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let img = currentImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Đang chờ tín hiệu USB từ Windows (Port 5000)...")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .onAppear { startServer() }
    }

    func startServer() {
        do {
            listener = try NWListener(using: .tcp, on: 5000)
            listener?.newConnectionHandler = { connection in
                connection.start(queue: .main)
                readFrame(from: connection)
            }
            listener?.start(queue: .main)
        } catch {
            print("Lỗi Listener: \(error)")
        }
    }

    func readFrame(from connection: NWConnection) {
        connection.receive(exactLength: 4) { data, _, isComplete, err in
            guard let data = data, data.count == 4, err == nil else { return }
            let frameSize = Int(data.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })

            connection.receive(exactLength: frameSize) { payload, _, _, _ in
                if let payload = payload, let image = UIImage(data: payload) {
                    DispatchQueue.main.async {
                        self.currentImage = image
                    }
                }
                if !isComplete { readFrame(from: connection) }
            }
        }
    }
}
