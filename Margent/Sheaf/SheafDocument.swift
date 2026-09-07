import Foundation

/// Role: Sheaf. Preference keys. Snapshot is the assigned UserDefaults contract; demo is Simulator-only.
enum SheafKey {
    static let snapshot = "mgt.sheaf.v1"
    static let backup = "mgt.sheaf.v1.backup"
    static let demo = "mgt.demo.v1"
}

/// Role: Sheaf. Recoverable load outcome. Never crash on a corrupt snapshot.
enum SheafWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Sheaf. On-disk / UserDefaults envelope. Domain types never decode this JSON themselves.
struct SheafDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var volumes: [VolumeRecord]
}

struct VolumeRecord: Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var totalPages: Int
    var stance: String
    var page: Int
    var slips: [SlipRecord]
}

struct SlipRecord: Codable, Equatable, Sendable {
    var id: UUID
    var body: String
    var page: Int
    var reread: Bool
    var writtenOn: Int
}

enum SheafCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
        case unknownStance
    }

    static func encode(_ document: SheafDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document)
    }

    static func decode(_ data: Data) throws -> SheafDocument {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(SheafDocument.self, from: data)
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func committed(from florilegium: Florilegium) -> SheafDocument {
        SheafDocument(
            schemaVersion: currentSchema,
            onboardingComplete: florilegium.onboardingComplete,
            volumes: florilegium.volumes.map { volume in
                let stance: String
                switch volume.stance {
                case .held:
                    stance = "held"
                case .gone:
                    stance = "gone"
                }
                return VolumeRecord(
                    id: volume.id,
                    title: volume.title,
                    totalPages: volume.totalPages,
                    stance: stance,
                    page: volume.pinnedPage,
                    slips: volume.sheaf.slips.map { slip in
                        SlipRecord(
                            id: slip.id,
                            body: slip.body,
                            page: slip.page,
                            reread: slip.reread,
                            writtenOn: slip.writtenOn
                        )
                    }
                )
            }
        )
    }

    static func florilegium(from document: SheafDocument) throws -> Florilegium {
        let volumes: [Volume] = try document.volumes.map { record in
            let stance: Volume.Stance
            switch record.stance {
            case "held":
                stance = .held(currentPage: record.page)
            case "gone":
                stance = .gone(frozenPage: record.page)
            default:
                throw Failure.unknownStance
            }
            let slips = record.slips.map { row in
                Slip(
                    id: row.id,
                    body: row.body,
                    page: row.page,
                    reread: row.reread,
                    writtenOn: row.writtenOn
                )
            }
            return Volume(
                id: record.id,
                title: record.title,
                totalPages: record.totalPages,
                sheaf: Sheaf(slips: slips),
                stance: stance
            )
        }
        return Florilegium(volumes: volumes, onboardingComplete: document.onboardingComplete)
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
