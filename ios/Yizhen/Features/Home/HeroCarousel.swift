import SwiftUI
import UIKit

struct HeroCarousel: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var current = 0
    @State private var outgoing: Int?
    @State private var outgoingOpacity: Double = 1
    @State private var zoom: CGFloat = 1
    @State private var outgoingZoom: CGFloat = 1
    @State private var transitionToken = 0
    @State private var timerToken = 0

    init() {}


    private let slides = HeroSlide.all
    private let autoInterval: UInt64 = 4_000_000_000

    var body: some View {
        Group {
            if YZTheme.highContrast {
                highContrastHero
            } else {
                normalHero
            }
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous))
        .overlay {
            if YZTheme.highContrast {
                RoundedRectangle(cornerRadius: YZTheme.cardRadius, style: .continuous)
                    .stroke(Color.black, lineWidth: 2)
            }
        }
        .yzCardShadow()
        .onAppear { restartZoom() }
        .onChange(of: reduceMotion) { _, _ in restartZoom() }
        .task(id: "\(timerToken)-\(reduceMotion)-\(YZTheme.highContrast)") {
            guard !reduceMotion, !YZTheme.highContrast else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: autoInterval)
                guard !Task.isCancelled else { break }
                advance()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var normalHero: some View {
        ZStack(alignment: .bottomLeading) {
            slideView(current, scale: zoom)

            if let outgoing {
                slideView(outgoing, scale: outgoingZoom)
                    .opacity(outgoingOpacity)
            }

            LinearGradient(
                colors: [Color.clear, Color(hex: 0x081024).opacity(0.76)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 6) {
                Text("让每句话，都被听见。")
                    .font(YZTheme.fontHero)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text("译诊 · 双向沟通")
                    .font(YZTheme.font(size: 11, weight: .medium, textStyle: .caption2, maxSize: 15))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(18)

            dots
        }
    }

    private var highContrastHero: some View {
        ZStack(alignment: .bottomLeading) {
            Color.white

            VStack(alignment: .leading, spacing: 6) {
                Text("让每句话，都被听见。")
                    .font(YZTheme.fontHero)
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text("高对比模式 · 已关闭图片与渐变")
                    .font(YZTheme.fontCaption)
                    .foregroundStyle(.black)
            }
            .padding(18)
        }
    }

    private var dots: some View {
        HStack(spacing: 4) {
            ForEach(slides.indices, id: \.self) { index in
                Button {
                    select(index)
                } label: {
                    Circle()
                        .fill(.white.opacity(index == current ? 1 : 0.45))
                        .frame(width: 7, height: 7)
                        .frame(width: 32, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(YZPressButtonStyle())
                .accessibilityLabel("第 \(index + 1) 张")
                .accessibilityAddTraits(index == current ? [.isSelected] : [])
            }
        }
        .padding(.trailing, 8)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    private func slideView(_ index: Int, scale: CGFloat) -> some View {
        ZStack {
            if let image = HeroSlide.image(named: slides[index].imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(scale)
            } else {
                slides[index].gradient
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private func advance() {
        select((current + 1) % slides.count)
    }

    private func select(_ index: Int) {
        guard slides.indices.contains(index), index != current else { return }
        transitionToken += 1
        let token = transitionToken
        outgoing = current
        outgoingZoom = zoom
        outgoingOpacity = 1
        current = index
        withAnimation(.easeInOut(duration: 0.6)) {
            outgoingOpacity = 0
        } completion: {
            guard transitionToken == token else { return }
            outgoing = nil
            outgoingOpacity = 1
        }
        restartZoom()
        if !reduceMotion {
            timerToken += 1
        }
    }

    private func restartZoom() {
        guard !reduceMotion, !YZTheme.highContrast else {
            zoom = 1
            return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { zoom = 1 }
        withAnimation(.linear(duration: 6)) { zoom = 1.06 }
    }
}

private struct HeroSlide {
    let imageName: String
    let gradient: LinearGradient

    static let all: [HeroSlide] = [
        HeroSlide(
            imageName: "hero1",
            gradient: LinearGradient(
                colors: [Color(hex: 0x1B41C8), Color(hex: 0x4C6FD6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        HeroSlide(
            imageName: "hero2",
            gradient: LinearGradient(
                colors: [Color(hex: 0x0F5C52), Color(hex: 0x2FA192)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        HeroSlide(
            imageName: "hero3",
            gradient: LinearGradient(
                colors: [Color(hex: 0x8A4B1F), Color(hex: 0xE09A5C)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        HeroSlide(
            imageName: "hero4",
            gradient: LinearGradient(
                colors: [Color(hex: 0x3B2E7E), Color(hex: 0x7A6BD6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    ]

    static func image(named name: String) -> UIImage? {
        guard let image = UIImage(named: name), image.size.width > 0, image.size.height > 0 else {
            return nil
        }
        return image
    }
}
