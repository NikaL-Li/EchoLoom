import SwiftUI
import UIKit

struct HeroWallpaper: View {
    let image: UIImage?
    let token: UUID
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var visibleImage: UIImage?
    @State private var previousImage: UIImage?
    @State private var phase: CGFloat = 1
    @State private var zoom: CGFloat = 1.03
    @State private var pan: CGSize = .zero
    @State private var transitionID = UUID()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // New image is opaque underneath. Old image fades out on top,
                // so the blue fallback never bleeds through mid-transition.
                if let visibleImage {
                    layer(visibleImage, size: proxy.size)
                }
                if let previousImage {
                    layer(previousImage, size: proxy.size)
                        .opacity(1 - phase)
                        .blur(radius: 1.0 * phase)
                }
            }
            .scaleEffect(zoom)
            .offset(pan)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .onAppear {
                if visibleImage == nil {
                    visibleImage = image
                }
                startKenBurns()
            }
            .onChange(of: token) { _, _ in
                guard let image else { return }
                transition(to: image)
            }
        }
    }

    private func layer(_ image: UIImage, size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func transition(to newImage: UIImage) {
        if reduceMotion {
            previousImage = nil
            visibleImage = newImage
            phase = 1
            return
        }
        let id = UUID()
        transitionID = id
        previousImage = visibleImage
        visibleImage = newImage
        phase = 0
        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 1.35)) {
            phase = 1
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_650_000_000)
            guard transitionID == id else { return }
            previousImage = nil
        }
    }

    private func startKenBurns() {
        zoom = 1.03
        pan = .zero
        guard !reduceMotion else { zoom = 1; return }
        withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
            zoom = 1.105
            pan = CGSize(width: 5, height: -3)
        }
    }
}
