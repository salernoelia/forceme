import SwiftUI

@main
struct TallyvityApp: App {
    init() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("optimized_whisper.mlmodelc")
        WhisperModelManager.shared.startPrewarming(modelURL: url)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
