import SwiftUI

struct MirrorView: View {
    @StateObject private var receiver = MirrorFrameStore()

    @AppStorage(
        MirrorShared.longEdgeKey,
        store: MirrorShared.defaults
    ) private var longEdge = MirrorShared.defaultLongEdge

    @AppStorage(
        MirrorShared.framesPerSecondKey,
        store: MirrorShared.defaults
    ) private var framesPerSecond = MirrorShared.defaultFramesPerSecond

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    preview

                    HStack(spacing: 14) {
                        ScreenBroadcastPicker()
                            .frame(width: 52, height: 52)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Начать зеркалирование")
                                .font(.headline)
                            Text("Нажмите системную кнопку и выберите DriveView")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    settings

                    Label(
                        "Перед запуском включите режим «Не беспокоить», чтобы уведомления не попали на экран автомобиля.",
                        systemImage: "moon.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Экран")
        }
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(.black)
                .aspectRatio(16 / 9, contentMode: .fit)

            if let frame = receiver.frame {
                Image(uiImage: frame)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 38))
                    Text(receiver.appGroupAvailable
                         ? "Ожидание трансляции"
                         : "App Group недоступен")
                }
                .foregroundStyle(.white.opacity(0.8))
            }

            VStack {
                HStack {
                    statusBadge
                    Spacer()
                }
                Spacer()
            }
            .padding(12)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(receiver.isReceiving ? .green : .gray)
                .frame(width: 8, height: 8)
            if receiver.isReceiving, let status = receiver.status {
                Text("\(status.width)×\(status.height) · \(status.framesPerSecond) FPS")
            } else {
                Text("Неактивно")
            }
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.65), in: Capsule())
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Качество зеркалирования")
                .font(.headline)

            Picker("Разрешение", selection: $longEdge) {
                Text("480p").tag(854)
                Text("720p").tag(1280)
                Text("1080p").tag(1920)
            }
            .pickerStyle(.segmented)

            Picker("Частота кадров", selection: $framesPerSecond) {
                Text("10 FPS").tag(10)
                Text("15 FPS").tag(15)
                Text("24 FPS").tag(24)
            }
            .pickerStyle(.segmented)

            Text("Новые настройки применятся при следующем запуске трансляции. Для первого теста рекомендуется 720p и 15 FPS.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

