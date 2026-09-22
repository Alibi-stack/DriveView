import SwiftUI
import UIKit

/// Подключается к `UIWindowSceneSessionRoleCarPlay` только после выдачи Apple
/// разрешения `com.apple.developer.carplay-video`.
final class CarPlayMirrorWindowSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(
            rootView: CarPlayMirrorSurface()
        )
        window.makeKeyAndVisible()
        self.window = window
    }
}

private struct CarPlayMirrorSurface: View {
    @StateObject private var receiver = MirrorFrameStore()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let frame = receiver.frame {
                Image(uiImage: frame)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 46))
                    Text("Запустите трансляцию в DriveView на iPhone")
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}

