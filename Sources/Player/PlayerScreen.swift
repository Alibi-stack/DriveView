import AVFoundation
import AVKit
import SwiftUI

struct PlayerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: LibraryStore

    let request: PlayerRequest
    @State private var player: AVPlayer
    @State private var timeObserver: Any?
    @State private var isExternalPlaybackActive = false

    init(request: PlayerRequest) {
        self.request = request
        _player = State(initialValue: AVPlayer(url: request.url))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VideoPlayer(player: player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .background(.black)

                HStack {
                    AirPlayRoutePicker()
                        .frame(width: 44, height: 44)
                    Text(isExternalPlaybackActive
                         ? "Идёт на внешнем экране (AirPlay)"
                         : "Выберите AirPlay-экран системной кнопкой")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(request.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .onAppear {
                configureAudioSession()
                if request.startPosition > 0 {
                    player.seek(to: CMTime(seconds: request.startPosition, preferredTimescale: 600))
                }
                installProgressObserver()
                player.play()
            }
            .onDisappear {
                persistProgress()
                if let timeObserver { player.removeTimeObserver(timeObserver) }
                timeObserver = nil
                player.pause()
            }
            .onReceive(player.publisher(for: \.isExternalPlaybackActive)) { active in
                isExternalPlaybackActive = active
            }
        }
    }

    private func configureAudioSession() {
        // .playback + UIBackgroundModes=audio держат AirPlay-маршрут (в т.ч.
        // видео в машину) активным, когда телефон сворачивается или блокируется.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }

    private func installProgressObserver() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 5, preferredTimescale: 600),
            queue: .main
        ) { _ in persistProgress() }
    }

    private func persistProgress() {
        guard let id = request.libraryItemID else { return }
        let position = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds
        guard position.isFinite else { return }
        library.updateProgress(
            for: id,
            position: position,
            duration: duration?.isFinite == true ? duration : nil
        )
    }
}

struct AirPlayRoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.prioritizesVideoDevices = true
        picker.activeTintColor = .systemRed
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

