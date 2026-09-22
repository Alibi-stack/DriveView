import Combine
import Foundation

@MainActor
final class AppRouter: ObservableObject {
    enum Section: Hashable {
        case home
        case browser
        case library
        case mirror
        case settings
    }

    @Published var selectedSection: Section = .home
}
