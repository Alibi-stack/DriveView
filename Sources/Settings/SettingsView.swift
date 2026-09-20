import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Поиск") {
                    LabeledContent("Поисковая система", value: "Google")
                }

                Section("Внешние экраны") {
                    Label("AirPlay доступен в плеере", systemImage: "airplayvideo")
                    Label("CarPlay — после получения доступа", systemImage: "car")
                        .foregroundStyle(.secondary)
                }

                Section("Данные") {
                    Button("Очистить библиотеку", role: .destructive) {
                        confirmClear = true
                    }
                }

                Section {
                    Text("DriveView 0.1.0")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
            .confirmationDialog(
                "Удалить все сохранённые ссылки и прогресс?",
                isPresented: $confirmClear,
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) { library.clear() }
            }
        }
    }
}

