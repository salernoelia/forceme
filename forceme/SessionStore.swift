import Foundation

struct LoopRecord: Codable {
    var goalText: String
    var answers: [String]
    var score: Int
    var scoreReason: String
}

struct SessionArtifact: Codable, Identifiable {
    var id: String
    var date: Date
    var goal: String
    var motivationLevel: Int?
    var score: Double
    var blocker: String
    var intentNext: String
    var loopsCompleted: Int
    var closingSentence: String
}

final class SessionStore {
    static let shared = SessionStore()
    private let fm = FileManager.default

    private var artifactsDir: URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("artifacts", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func save(_ artifact: SessionArtifact) {
        let url = artifactsDir.appendingPathComponent("\(artifact.id).json")
        if let data = try? JSONEncoder().encode(artifact) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func loadAll() -> [SessionArtifact] {
        let urls = (try? fm.contentsOfDirectory(at: artifactsDir, includingPropertiesForKeys: nil)) ?? []
        return urls.compactMap { url -> SessionArtifact? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(SessionArtifact.self, from: data)
        }.sorted { $0.date > $1.date }
    }

    func findRelevant(for goal: String, limit: Int = 3) -> [SessionArtifact] {
        let all = loadAll()
        guard !all.isEmpty else { return [] }
        let goalWords = Set(goal.lowercased().split(separator: " ").map(String.init))
        return all
            .map { a -> (SessionArtifact, Int) in
                let w = Set(a.goal.lowercased().split(separator: " ").map(String.init))
                return (a, goalWords.intersection(w).count)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    var latest: SessionArtifact? { loadAll().first }
}
