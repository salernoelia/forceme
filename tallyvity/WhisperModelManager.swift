import Foundation
import CoreML

class WhisperModelManager {
    static let shared = WhisperModelManager()
    
    var activeModel: MLModel?
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Ahead-of-Time compilation of a raw model package
    func compileModelIfNeeded(at rawModelURL: URL) async throws -> URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let permanentURL = docs.appendingPathComponent("optimized_whisper.mlmodelc")
        
        if fileManager.fileExists(atPath: permanentURL.path) {
            print("Found existing compiled model at \(permanentURL.path)")
            return permanentURL
        }
        
        print("Compiling raw model for AOT storage...")
        let compiledTempURL = try await MLModel.compileModel(at: rawModelURL)
        
        // Ensure destination is clean
        if fileManager.fileExists(atPath: permanentURL.path) {
            try fileManager.removeItem(at: permanentURL)
        }
        
        try fileManager.moveItem(at: compiledTempURL, to: permanentURL)
        print("Successfully moved compiled model to persistent storage: \(permanentURL.path)")
        return permanentURL
    }
    
    /// Asynchronous Background Initialization (Pre-warming)
    func startPrewarming(modelURL: URL) {
        Task(priority: .background) {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                self.activeModel = try await MLModel.load(contentsOf: modelURL, configuration: config)
            } catch {
                print("Pre-warming failed: \(error)")
            }
        }
    }
}
