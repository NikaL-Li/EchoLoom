import SwiftUI
import UIKit

struct RemoteImage: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .task(id: url) {
            guard let data = try? await URLSession.shared.data(from: url).0,
                  let loaded = UIImage(data: data) else { return }
            await MainActor.run { image = loaded }
        }
    }
}
