import Foundation
import CoreML

class WhisperModelManager {
    static let shared = WhisperModelManager()
    
    var activeModel: MLModel?
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Ahead-of-Time compilation of a raw model package
    func compileModelIfNeeded(at rawModelURL: URL) async throws -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let permanentURL = documentsDirectory.appendingPathComponent("optimized_whisper.mlmodelc")
        
        if fileManager.fileExists(atPath: permanentURL.path) {
            return permanentURL
        }
        
        let compiledTempURL = try await MLModel.compileModel(at: rawModelURL)
        try fileManager.moveItem(at: compiledTempURL, to: permanentURL)
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
