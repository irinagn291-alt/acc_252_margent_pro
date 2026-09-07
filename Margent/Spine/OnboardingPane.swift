import SwiftUI

/// Role: Spine. Three-to-four pages. Skip still writes defaults. Re-runnable from Settings.
struct OnboardingPane: View {
    var onFinish: (Bool) -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(onFinish: @escaping (Bool) -> Void = { _ in }) {
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: StudioInk.space(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: "mgt_Onboarding1",
                        title: "Set down the book you are holding",
                        line: "Give it a name and a page count. Each spine on the shelf keeps one store of your slips — not a catalog crate."
                    )
                case 1:
                    pageView(
                        image: "mgt_Onboarding2",
                        title: "Write a slip at this page",
                        line: "Open a spine. Pin your line to the page you are on in one commit, before the thought cools."
                    )
                case 2:
                    pageView(
                        image: "mgt_Onboarding3",
                        title: "The book can leave. The slips stay.",
                        line: "Mark a returned or finished book gone. The spine hollows. The sheaf freezes so you can still reread."
                    )
                default:
                    pageView(
                        image: "mgt_TwistHero",
                        title: "Reread is a verdict",
                        line: "A slip is reread or not — never a star. Dashboard counts gone sheaves and reread slips."
                    )
                }
            }
            .frame(maxHeight: .infinity)
            .animation(reduceMotion ? nil : StudioFace.motion, value: page)
            StudioCapsule(title: page < 3 ? "Next" : "Open the shelf") {
                if page < 3 {
                    page += 1
                } else {
                    onFinish(false)
                }
            }
            Button {
                onFinish(true)
            } label: {
                Text("Skip")
                    .studio(.body)
                    .foregroundStyle(StudioInk.Palette.muted)
                    .frame(maxWidth: .infinity, minHeight: StudioInk.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(StudioPressStyle())
            .accessibilityLabel("Skip")
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StudioInk.Palette.background.ignoresSafeArea())
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: StudioInk.space(2)) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: StudioInk.space(35))
                .overlay {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .accessibilityHidden(true)
                }
            Text(title)
                .studio(.display)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .studio(.body)
                .foregroundStyle(StudioInk.Palette.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingPane()
}
