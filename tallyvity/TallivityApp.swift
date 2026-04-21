import SwiftUI

@main
struct TallyvityApp: App {
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let whisperURL = docs.appendingPathComponent("optimized_whisper.mlmodelc")
        if FileManager.default.fileExists(atPath: whisperURL.path) {
            WhisperModelManager.shared.startPrewarming(modelURL: whisperURL)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
