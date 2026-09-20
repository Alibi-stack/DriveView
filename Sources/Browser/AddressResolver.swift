import Foundation

enum AddressResolver {
    static func resolve(_ input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if let url = URL(string: text), let scheme = url.scheme,
           ["http", "https"].contains(scheme.lowercased()) {
            return url
        }

        if !text.contains(" "), text.contains("."),
           let url = URL(string: "https://\(text)") {
            return url
        }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: text)]
        return components?.url
    }
}

