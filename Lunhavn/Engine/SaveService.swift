import Foundation

final class SaveService {
    static let shared = SaveService()

    private let fileName = "lunhavn_save.json"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    private init() {
        encoder.dateEncodingStrategy = .secondsSince1970
        decoder.dateDecodingStrategy = .secondsSince1970
    }

    func load() -> GameState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(GameState.self, from: data)
    }

    func save(_ state: GameState) {
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func wipe() {
        try? FileManager.default.removeItem(at: url)
    }
}
