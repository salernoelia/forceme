import Foundation

@MainActor
final class PromptStore {
    static let shared = PromptStore()

    struct VoicePrompt: Codable {
        let cue: String?
        let fallback: String?
        let presets: [String]?
        let text: String?
    }

    struct PromptSchema: Codable {
        let voice_prompts: [String: VoicePromptValue]
        let ui_labels: [String: String]
    }

    enum VoicePromptValue: Codable {
        case prompt(VoicePrompt)
        case string(String)
        case array([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                let prompt = try container.decode(VoicePrompt.self)
                self = .prompt(prompt)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .prompt(let p): try container.encode(p)
            case .string(let s): try container.encode(s)
            case .array(let a): try container.encode(a)
            }
        }
    }

    private var data: PromptSchema?

    private init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "prompts", withExtension: "json"),
              let rawData = try? Foundation.Data(contentsOf: url) else {
            return
        }
        do {
            self.data = try JSONDecoder().decode(PromptSchema.self, from: rawData)
        } catch {
            print("Error decoding prompts: \(error)")
        }
    }

    func string(for key: String) -> String {
        data?.ui_labels[key] ?? key
    }

    func voicePrompt(for key: String) -> VoicePrompt? {
        guard let value = data?.voice_prompts[key] else { return nil }
        if case .prompt(let p) = value {
            return p
        }
        return nil
    }

    func presets(for key: String) -> [String] {
        guard let value = data?.voice_prompts[key] else { return [] }
        switch value {
        case .array(let a): return a
        case .prompt(let p): return p.presets ?? []
        default: return []
        }
    }

    func fallback(for key: String) -> String {
        guard let value = data?.voice_prompts[key] else { return "" }
        switch value {
        case .string(let s): return s
        case .prompt(let p): return p.fallback ?? p.text ?? ""
        default: return ""
        }
    }
}
