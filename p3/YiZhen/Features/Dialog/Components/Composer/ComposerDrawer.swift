import SwiftUI
import UIKit

struct ComposerDrawer: View {
    @Binding var draft: String
    let canSend: Bool
    let onSend: () -> Void
    let onClose: () -> Void

    @Environment(\.yzTheme) private var theme

    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                header

                ComposerTextView(
                    text: $draft,
                    onSend: onSend,
                    maxLength: theme.metrics.size.composerMaxLength,
                    minHeight: theme.metrics.size.composerInputMinHeight,
                    maxHeight: theme.metrics.size.composerInputMaxHeight
                )
                .padding(.top, theme.metrics.spacing.sheetItemGap)

                sendButton
                    .padding(.top, theme.metrics.spacing.sheetItemGap)

                notes
                    .padding(.top, theme.metrics.spacing.sheetItemGap)
            }
            .padding(.horizontal, theme.metrics.spacing.sheetPaddingH)
            .padding(.top, theme.metrics.spacing.sheetPaddingTop)
            .padding(.bottom, theme.metrics.spacing.sheetPaddingBottom)
        }
        .scrollBounceBehavior(.basedOnSize)
        .fixedSize(horizontal: false, vertical: true)
        .background(theme.colors.surface)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: theme.metrics.radius.sheet,
                topTrailingRadius: theme.metrics.radius.sheet,
                style: .continuous
            )
        )
        .yzShadow(theme.shadow.sheetUp)

        .accessibilityIdentifier(AccessibilityID.composer)
        .onAppear {
            guard UIAccessibility.isVoiceOverRunning else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                titleFocused = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 2) {
            Capsule()
                .fill(theme.colors.sheetGrip)
                .frame(
                    width: theme.metrics.size.sheetGripWidth,
                    height: theme.metrics.size.sheetGripHeight
                )
                .accessibilityHidden(true)

            HStack(alignment: .center, spacing: 0) {
                Text(YZComposerStrings.title)
                    .font(theme.typography.font(.composerTitle))
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .gesture(closeDragGesture)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier(AccessibilityID.composerTitle)
                    .accessibilityFocused($titleFocused)

                Button(action: onClose) {
                    Text(YZComposerStrings.close)
                        .font(theme.typography.font(.composerClose))
                        .foregroundStyle(theme.colors.composerSecondaryText)
                        .frame(width: theme.metrics.size.hitTarget, height: theme.metrics.size.hitTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(YZPressableButtonStyle())
                .accessibilityLabel(Text(YZComposerStrings.close))
                .accessibilityIdentifier(AccessibilityID.composerClose)
            }
            .frame(minHeight: theme.metrics.size.hitTarget)
        }
    }

    private var sendButton: some View {
        Button(action: onSend) {
            Text(YZComposerStrings.send)
                .font(theme.typography.font(.composerSend))
                .foregroundStyle(canSend ? theme.colors.onAccent : theme.colors.textWeak)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: theme.metrics.size.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: theme.metrics.radius.button, style: .continuous)
                        .fill(canSend ? theme.colors.accentFill : theme.colors.sendDisabledFill)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(YZPressableButtonStyle())
        .disabled(!canSend)
        .accessibilityLabel(Text(YZComposerStrings.send))
        .accessibilityIdentifier(AccessibilityID.composerSend)
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(YZComposerStrings.note1)
                .font(theme.typography.font(.composerNote))
                .foregroundStyle(theme.colors.composerSecondaryText)
                .lineSpacing(theme.typography.lineSpacing(for: .composerNote))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(AccessibilityID.composerNote)
            Text(YZComposerStrings.note2)
                .font(theme.typography.font(.composerNote))
                .foregroundStyle(theme.colors.composerSecondaryText)
                .lineSpacing(theme.typography.lineSpacing(for: .composerNote))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .allowsHitTesting(false)
    }

    private var closeDragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in
                if value.translation.height > theme.motion.composerDragCloseThreshold {
                    onClose()
                }
            }
    }
}