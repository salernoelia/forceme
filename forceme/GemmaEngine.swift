import Foundation
import MLX
import MLXLMCommon
import MLXVLM
import MLXHuggingFace
import HuggingFace
import Tokenizers
import UIKit

@MainActor
@Observable
final class GemmaEngine {

    enum State: Equatable {
        case idle
        case downloading(Double)
        case loading
        case ready
        case generating
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var output: String = ""

    private var container: ModelContainer?

    var isLoaded: Bool {
        container != nil && (state == .ready || state == .generating)
    }

    func load() async {
        guard !isLoaded else { return }
        state = .loading
        do {
            let config = VLMRegistry.gemma4_E2B_it_4bit
            let downloader = HubDownloader()
            let loader = HFTokenizerLoader()
            let loaded = try await VLMModelFactory.shared.loadContainer(
                from: downloader,
                using: loader,
                configuration: config,
                progressHandler: { [weak self] progress in
                    guard let self else { return }
                    Task { @MainActor in
                        self.state = .downloading(progress.fractionCompleted)
                    }
                }
            )
            container = loaded
            state = .ready
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func generate(image: UIImage? = nil, prompt: String) async {
        guard let container else { return }
        state = .generating
        output = ""
        do {
            var images: [UserInput.Image] = []
            if let uiImage = image, let ciImage = CIImage(image: uiImage) {
                images = [.ciImage(ciImage)]
            }
            let userInput = UserInput(prompt: prompt, images: images)
            let lmInput = try await container.prepare(input: userInput)
            let stream = try await container.generate(
                input: lmInput,
                parameters: GenerateParameters(maxTokens: 512)
            )
            for await event in stream {
                if case .chunk(let text) = event {
                    output += text
                }
            }
            state = .ready
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func cancelError() { state = isLoaded ? .ready : .idle }
}

// MARK: - HuggingFace bridge (inlined from MLXHuggingFace macros)

private struct HubDownloader: MLXLMCommon.Downloader {
    private let hub = HubClient()

    func download(
        id: String,
        revision: String?,
        matching patterns: [String],
        useLatest: Bool,
        progressHandler: @Sendable @escaping (Progress) -> Void
    ) async throws -> URL {
        guard let repoID = Repo.ID(rawValue: id) else {
            throw HubClientError.invalidRepoID(id)
        }
        return try await hub.downloadSnapshot(
            of: repoID,
            revision: revision ?? "main",
            matching: patterns,
            progressHandler: { @MainActor progress in progressHandler(progress) }
        )
    }
}

private struct HFTokenizerLoader: MLXLMCommon.TokenizerLoader {
    func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        let upstream = try await AutoTokenizer.from(modelFolder: directory)
        return HFTokenizerBridge(upstream)
    }
}

private struct HFTokenizerBridge: MLXLMCommon.Tokenizer {
    private let upstream: any Tokenizers.Tokenizer

    init(_ upstream: any Tokenizers.Tokenizer) { self.upstream = upstream }

    func encode(text: String, addSpecialTokens: Bool) -> [Int] {
        upstream.encode(text: text, addSpecialTokens: addSpecialTokens)
    }

    func decode(tokenIds: [Int], skipSpecialTokens: Bool) -> String {
        upstream.decode(tokens: tokenIds, skipSpecialTokens: skipSpecialTokens)
    }

    func convertTokenToId(_ token: String) -> Int? { upstream.convertTokenToId(token) }
    func convertIdToToken(_ id: Int) -> String? { upstream.convertIdToToken(id) }

    var bosToken: String? { upstream.bosToken }
    var eosToken: String? { upstream.eosToken }
    var unknownToken: String? { upstream.unknownToken }

    func applyChatTemplate(
        messages: [[String: any Sendable]],
        tools: [[String: any Sendable]]?,
        additionalContext: [String: any Sendable]?
    ) throws -> [Int] {
        do {
            return try upstream.applyChatTemplate(
                messages: messages, tools: tools, additionalContext: additionalContext)
        } catch Tokenizers.TokenizerError.missingChatTemplate {
            throw MLXLMCommon.TokenizerError.missingChatTemplate
        }
    }
}

private enum HubClientError: LocalizedError {
    case invalidRepoID(String)
    var errorDescription: String? {
        if case .invalidRepoID(let id) = self {
            return "Invalid HuggingFace repo ID: '\(id)'"
        }
        return nil
    }
}
