import Foundation

/// Role: Spine. Simulator demo shelf. Device never writes this. Key: mgt.demo.v1.
enum SheafSeed {
    static let clayHoursID = uuid("11111111-1111-4111-8111-111111111111")
    static let riverSheafID = uuid("22222222-2222-4222-8222-222222222222")
    static let returnedLightID = uuid("33333333-3333-4333-8333-333333333333")
    static let nightCommonplaceID = uuid("44444444-4444-4444-8444-444444444444")

    static let clayFirstSlipID = uuid("aaaaaaa1-1111-4111-8111-111111111111")
    static let claySecondSlipID = uuid("aaaaaaa2-1111-4111-8111-111111111111")
    static let riverFirstSlipID = uuid("bbbbbbb1-2222-4222-8222-222222222222")
    static let riverSecondSlipID = uuid("bbbbbbb2-2222-4222-8222-222222222222")
    static let returnedFirstSlipID = uuid("ccccccc1-3333-4333-8333-333333333333")
    static let returnedSecondSlipID = uuid("ccccccc2-3333-4333-8333-333333333333")
    static let nightFirstSlipID = uuid("ddddddd1-4444-4444-8444-444444444444")

    /// Seed identities are literals. Failure here is a programmer error.
    private static func uuid(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Demo seed UUID literal is invalid")
        }
        return value
    }

    static func florilegium() -> Florilegium {
        let clay = Volume(
            id: clayHoursID,
            title: "Clay Hours",
            totalPages: 248,
            sheaf: Sheaf(slips: [
                Slip(
                    id: clayFirstSlipID,
                    body: "A margin is a room the author left for you. Write in it before the thought cools.",
                    page: 18,
                    reread: true,
                    writtenOn: 20260304
                ),
                Slip(
                    id: claySecondSlipID,
                    body: "Page 72: the clay spine argument — keep the book by keeping the sheaf.",
                    page: 72,
                    reread: false,
                    writtenOn: 20260312
                ),
            ]),
            stance: .held(currentPage: 72)
        )
        let river = Volume(
            id: riverSheafID,
            title: "Sheaf of Rivers",
            totalPages: 312,
            sheaf: Sheaf(slips: [
                Slip(
                    id: riverFirstSlipID,
                    body: "Water does not bookmark. It passes, and the bank remembers the line.",
                    page: 41,
                    reread: false,
                    writtenOn: 20260402
                ),
                Slip(
                    id: riverSecondSlipID,
                    body: "At 118 I stopped to copy the sentence about returning a borrowed channel.",
                    page: 118,
                    reread: true,
                    writtenOn: 20260419
                ),
            ]),
            stance: .held(currentPage: 118)
        )
        let returned = Volume(
            id: returnedLightID,
            title: "Returned Light",
            totalPages: 196,
            sheaf: Sheaf(slips: [
                Slip(
                    id: returnedFirstSlipID,
                    body: "Finished on the train. The book goes back; these two slips stay.",
                    page: 190,
                    reread: true,
                    writtenOn: 20260508
                ),
                Slip(
                    id: returnedSecondSlipID,
                    body: "Last page: hollow the spine, do not hollow the commonplace.",
                    page: 196,
                    reread: false,
                    writtenOn: 20260509
                ),
            ]),
            stance: .gone(frozenPage: 196)
        )
        let night = Volume(
            id: nightCommonplaceID,
            title: "Night Commonplace",
            totalPages: 180,
            sheaf: Sheaf(slips: [
                Slip(
                    id: nightFirstSlipID,
                    body: "Lamp low, page 24. Tomorrow I write the next slip at the playhead.",
                    page: 24,
                    reread: false,
                    writtenOn: 20260601
                ),
            ]),
            stance: .held(currentPage: 24)
        )
        return Florilegium(
            volumes: [clay, river, returned, night],
            onboardingComplete: true
        )
    }
}
