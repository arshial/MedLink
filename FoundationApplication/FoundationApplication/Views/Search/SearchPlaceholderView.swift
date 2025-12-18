import SwiftUI

struct SearchPlaceholderView: View {
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text("Search")
                .font(.headline)
            Text("Search feature coming soon.")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}
