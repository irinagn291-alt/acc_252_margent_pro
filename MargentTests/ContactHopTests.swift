import XCTest
@testable import Margent

private struct ProbeDTO: Decodable {
    var count: LooseCount
}

private actor ScriptedChannel: HopChannel {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func ping(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class ContactHopTests: XCTestCase {
    private let url = URL(string: "https://margent-sheaf.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let channel = ScriptedChannel(results: [
            .success((Data("{\"count\":1}".utf8), http(200))),
        ])
        let client = ContactHop(channel: channel)
        _ = try await client.decodeManifest(ProbeDTO.self, from: url)
        let request = await channel.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), ContactHop.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(ContactHop.userAgent, "Margent/1.0 (iOS; +https://margent-sheaf.pro)")
        XCTAssertEqual(ContactHop.contactURL.absoluteString, "https://margent-sheaf.pro/contact-us")
    }

    func test_retriesTransientTransportOnce() async throws {
        let channel = ScriptedChannel(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"count\":\"4.5\"}".utf8), http(200))),
        ])
        let client = ContactHop(channel: channel)
        let dto = try await client.decodeManifest(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.count.value, 4.5)
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let channel = ScriptedChannel(results: [
            .success((Data(), http(404))),
            .success((Data("{\"count\":1}".utf8), http(200))),
        ])
        let client = ContactHop(channel: channel)
        do {
            _ = try await client.decodeManifest(ProbeDTO.self, from: url)
            XCTFail("expected vacant")
        } catch {
            XCTAssertEqual(error as? HopFault, .vacant)
        }
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsUnreadable() async {
        let channel = ScriptedChannel(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = ContactHop(channel: channel)
        do {
            _ = try await client.decodeManifest(ProbeDTO.self, from: url)
            XCTFail("expected unreadable")
        } catch {
            XCTAssertEqual(error as? HopFault, .unreadable)
        }
    }

    func test_statusZeroMapsToVacant() async {
        let channel = ScriptedChannel(results: [
            .success((Data("{\"status\":0}".utf8), http(200))),
        ])
        let client = ContactHop(channel: channel)
        do {
            _ = try await client.readSignal(from: url)
            XCTFail("expected vacant")
        } catch {
            XCTAssertEqual(error as? HopFault, .vacant)
        }
    }

    func test_looseCountAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"count\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"count\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"count\":null}".utf8))
        XCTAssertEqual(number.count.value, 12.5)
        XCTAssertEqual(string.count.value, 12.5)
        XCTAssertNil(missing.count.value)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
