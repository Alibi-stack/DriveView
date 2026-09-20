import SwiftUI

struct TabsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var browser: BrowserStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(browser.tabs) { tab in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(tab.title).lineLimit(1)
                            Text(tab.displayURL)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if browser.selectedID == tab.id {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.red)
                        }
                        Button { browser.close(tab) } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .disabled(browser.tabs.count == 1)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        browser.selectedID = tab.id
                        dismiss()
                    }
                }
            }
            .navigationTitle("Вкладки")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Готово") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        browser.addTab()
                        dismiss()
                    } label: { Image(systemName: "plus") }
                }
            }
        }
    }
}
