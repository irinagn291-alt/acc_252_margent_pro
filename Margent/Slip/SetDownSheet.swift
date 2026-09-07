import SwiftUI

/// Role: Volume. Set down a book with its page count. Empty-shelf primary action.
struct SetDownSheet: View {
    @ObservedObject var watch: SheafWatch
    var onClose: () -> Void

    @State private var title = ""
    @State private var pagesText = ""
    @State private var confirmClose = false
    @FocusState private var focus: Field?

    private enum Field: Hashable {
        case title
        case pages
    }

    init(watch: SheafWatch, onClose: @escaping () -> Void = {}) {
        self.watch = watch
        self.onClose = onClose
    }

    init() {
        self.init(watch: .previewEmpty())
    }

    private var pages: Int? {
        let trimmed = pagesText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(trimmed), value >= 1 else { return nil }
        return value
    }

    private var canSetDown: Bool {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && pages != nil && !watch.isBusy
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StudioInk.space(2)) {
            StudioSheetBar(title: "Set down a book", onClose: attemptClose)
            ScrollView {
                VStack(alignment: .leading, spacing: StudioInk.space(2)) {
                    Text("Name the volume and how many pages it has. It starts Held at page 1.")
                        .studio(.body)
                        .foregroundStyle(StudioInk.Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let fault = watch.fault {
                        Text(fault)
                            .studio(.caption)
                            .foregroundStyle(StudioInk.Palette.muted)
                    }
                    TextField("Title", text: $title)
                        .studio(.body)
                        .padding(.horizontal, StudioInk.space(2))
                        .frame(minHeight: StudioInk.tap)
                        .background(StudioInk.Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous))
                        .focused($focus, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focus = .pages }
                    TextField("Page count", text: $pagesText)
                        .studio(.body)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, StudioInk.space(2))
                        .frame(minHeight: StudioInk.tap)
                        .background(StudioInk.Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: StudioInk.chipRadius, style: .continuous))
                        .focused($focus, equals: .pages)
                        .onChange(of: pagesText) { _, next in
                            pagesText = next.filter(\.isNumber)
                        }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            StudioCapsule(title: "Set down on the shelf", enabled: canSetDown) {
                guard let pages else { return }
                focus = nil
                Task {
                    await watch.setDown(title: title, totalPages: pages)
                    if watch.fault == nil {
                        onClose()
                    }
                }
            }
        }
        .padding(StudioInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(StudioInk.Palette.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .confirmationDialog(
            "Leave this book off the shelf?",
            isPresented: $confirmClose,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive, action: onClose)
            Button("Keep editing", role: .cancel) {}
        }
        .interactiveDismissDisabled(isDirty)
    }

    private var isDirty: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !pagesText.isEmpty
    }

    private func attemptClose() {
        if isDirty {
            confirmClose = true
        } else {
            onClose()
        }
    }
}

#Preview {
    SetDownSheet()
}
