import Foundation

struct PlexServer: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var host: String
    var port: Int
    var token: String
    var isSecure: Bool

    var baseURL: URL? {
        let scheme = isSecure ? "https" : "http"
        return URL(string: "\(scheme)://\(host):\(port)")
    }

    var displayAddress: String {
        "\(host):\(port)"
    }

    init(id: String = UUID().uuidString, name: String, host: String, port: Int = 32400, token: String, isSecure: Bool = false) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.token = token
        self.isSecure = isSecure
    }
}

enum ServerConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
