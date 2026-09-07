import Foundation

/// Role: Hollow. Typed hop failures. This product has no remote catalog.
enum HopFault: Error, Equatable, Sendable {
    case vacant
    case unreadable
    case seaState
    case cutShort
    case notHTTP
}

/// Role: Hollow. Injected hop so tests never leave the process.
protocol HopChannel: Sendable {
    func ping(_ request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Hollow. URLSession hop with a 15 s timeout and this app's User-Agent.
struct SessionHop: HopChannel {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": ContactHop.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func ping(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Hollow. Number or numeric string; missing stays nil. Never a domain field.
struct LooseCount: Sendable, Equatable, Decodable {
    var value: Double?

    init(value: Double?) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        if box.decodeNil() {
            value = nil
            return
        }
        if let number = try? box.decode(Double.self) {
            value = number
            return
        }
        if let whole = try? box.decode(Int.self) {
            value = Double(whole)
            return
        }
        if let text = try? box.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

struct HopSignalDTO: Decodable, Sendable {
    var status: Int
}

/// Role: Hollow. Owns the session. Contact URL is opened by Settings, not decoded here.
/// No Open Food Facts and no ISBN crate — own-slip lookup is in-process over the sheaf.
actor ContactHop {
    static let userAgent = "Margent/1.0 (iOS; +https://margent-sheaf.pro)"
    static let contactURL = URL(string: "https://margent-sheaf.pro/contact-us")!

    private let channel: any HopChannel

    init(channel: any HopChannel) {
        self.channel = channel
    }

    init() {
        self.channel = SessionHop()
    }

    func decodeManifest<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await haul(ticket(for: url))
        do {
            return try decoder().decode(DTO.self, from: body)
        } catch is CancellationError {
            throw HopFault.cutShort
        } catch {
            throw HopFault.unreadable
        }
    }

    func readSignal(from url: URL) async throws -> Int {
        let dto = try await decodeManifest(HopSignalDTO.self, from: url)
        if dto.status == 0 {
            throw HopFault.vacant
        }
        return dto.status
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }

    private func ticket(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func haul(_ request: URLRequest) async throws -> Data {
        do {
            return try await hop(request)
        } catch let fault as HopFault {
            throw fault
        } catch is CancellationError {
            throw HopFault.cutShort
        } catch {
            if Self.cutShort(error) {
                throw HopFault.cutShort
            }
            guard Self.choppy(error) else { throw HopFault.seaState }
            do {
                return try await hop(request)
            } catch let fault as HopFault {
                throw fault
            } catch is CancellationError {
                throw HopFault.cutShort
            } catch {
                if Self.cutShort(error) { throw HopFault.cutShort }
                throw HopFault.seaState
            }
        }
    }

    private func hop(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (body, reply) = try await channel.ping(request)
        guard let http = reply as? HTTPURLResponse else {
            throw HopFault.notHTTP
        }
        if http.statusCode == 404 {
            throw HopFault.vacant
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw HopFault.seaState
        }
        return body
    }

    private static func choppy(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cutShort(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
