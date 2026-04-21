import Foundation
import CoreML

final class CoreMLModelManager {
    static let shared = CoreMLModelManager()
    
    private(set) var activeModels: [String: MLModel] = [:]
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Compiles a raw model (mlpackage/mlmodel) to a persistent .mlmodelc if it doesn't exist
    func compileAndStoreModel(at rawURL: URL, name: String) async throws -> URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let permanentURL = docs.appendingPathComponent("\(name).mlmodelc")
        
        if fileManager.fileExists(atPath: permanentURL.path) {
            print("Model \(name) already exists at \(permanentURL.path)")
            return permanentURL
        }
        
        print("Compiling model \(name) for persistence...")
        let tempURL = try await MLModel.compileModel(at: rawURL)
        
        if fileManager.fileExists(atPath: permanentURL.path) {
            try fileManager.removeItem(at: permanentURL)
        }
        
        try fileManager.moveItem(at: tempURL, to: permanentURL)
        print("Stored compiled model \(name) at \(permanentURL.path)")
        return permanentURL
    }
    
    /// Pre-warms a model by loading it into memory on a background thread
    func startPrewarming(modelURL: URL, key: String) {
        Task(priority: .background) {
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                let model = try await MLModel.load(contentsOf: modelURL, configuration: config)
                self.activeModels[key] = model
                print("Successfully pre-warmed model: \(key)")
            } catch {
                print("Failed to pre-warm model \(key): \(error)")
            }
        }
    }
    
    func getModel(for key: String) -> MLModel? {
        return activeModels[key]
    }
}
