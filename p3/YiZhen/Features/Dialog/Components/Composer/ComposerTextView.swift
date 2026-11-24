import SwiftUI
import UIKit

struct ComposerTextView: View {
    @Binding var text: String
    let onSend: () -> Void
    let maxLength: Int
    let minHeight: CGFloat
    let maxHeight: CGFloat

    @Environment(\.yzTheme) private var theme
    @State private var isFocused = false
    @State private var textHeight: CGFloat = 0

    private var displayHeight: CGFloat {
        min(max(textHeight == 0 ? minHeight : textHeight, minHeight), maxHeight)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ComposerUITextView(
                text: $text,
                isFocused: $isFocused,
                measuredHeight: $textHeight,
                maxLength: maxLength,
                minHeight: minHeight,
                maxHeight: maxHeight,
                onSend: onSend,
                font: theme.typography.scaledFont(for: .composerInput),
                textColor: UIColor(theme.colors.textPrimary),
                tintColor: UIColor(theme.colors.accent),
                paddingVertical: theme.metrics.spacing.composerInputPaddingV,
                paddingHorizontal: theme.metrics.spacing.composerInputPaddingH
            )
            .frame(height: displayHeight)
            .background(theme.colors.inputSurface)
            .clipShape(RoundedRectangle(cornerRadius: theme.metrics.radius.composerInput, style: .continuous))

            if text.isEmpty {
                Text(YZComposerStrings.inputPlaceholder)
                    .font(theme.typography.font(.composerInput))
                    .foregroundStyle(theme.colors.textWeak)
                    .padding(.vertical, theme.metrics.spacing.composerInputPaddingV)
                    .padding(.horizontal, theme.metrics.spacing.composerInputPaddingH)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.radius.composerInput, style: .continuous)
                .strokeBorder(
                    isFocused ? theme.colors.accent : theme.colors.inputStroke,
                    lineWidth: theme.metrics.size.composerInputStroke
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.radius.composerInput, style: .continuous))
    }
}

private struct ComposerUITextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var measuredHeight: CGFloat
    let maxLength: Int
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let onSend: () -> Void
    let font: UIFont
    let textColor: UIColor
    let tintColor: UIColor
    let paddingVertical: CGFloat
    let paddingHorizontal: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = textColor
        view.tintColor = tintColor
        view.font = font
        view.isScrollEnabled = true
        view.returnKeyType = .send
        view.enablesReturnKeyAutomatically = true
        view.autocorrectionType = .no
        view.spellCheckingType = .no
        view.smartQuotesType = .no
        view.smartDashesType = .no
        view.textContainerInset = UIEdgeInsets(
            top: paddingVertical,
            left: paddingHorizontal,
            bottom: paddingVertical,
            right: paddingHorizontal
        )
        view.textContainer.lineFragmentPadding = 0
        view.accessibilityLabel = YZComposerStrings.inputAccessibilityLabel
        view.accessibilityHint = YZComposerStrings.inputAccessibilityHint
        view.accessibilityIdentifier = AccessibilityID.composerInput
        applyTypingAttributes(to: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            if view.window != nil {
                view.becomeFirstResponder()
            }
        }
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        uiView.font = font
        uiView.textColor = textColor
        uiView.tintColor = tintColor
        if uiView.text != text, uiView.markedTextRange == nil {
            uiView.text = text
            let coordinator = context.coordinator
            DispatchQueue.main.async {
                coordinator.refreshHeight(for: uiView)
            }
        }
        applyTypingAttributes(to: uiView)
    }

    static func dismantleUIView(_ uiView: UITextView, coordinator: Coordinator) {
        uiView.resignFirstResponder()
    }

    private func applyTypingAttributes(to view: UITextView) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = font.lineHeight * 1.5
        paragraph.maximumLineHeight = font.lineHeight * 1.5
        view.typingAttributes = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ComposerUITextView

        init(parent: ComposerUITextView) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            if text == "\n" {
                if textView.markedTextRange != nil {
                    return true
                }
                parent.onSend()
                return false
            }
            if textView.markedTextRange != nil {
                return true
            }
            let current = textView.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return true }
            let next = current.replacingCharacters(in: swiftRange, with: text)
            return next.count <= parent.maxLength
        }

        func textViewDidChange(_ textView: UITextView) {
            let clamped = YZComposerRules.clamp(textView.text ?? "")
            if clamped != textView.text {
                textView.text = clamped
            }
            parent.text = clamped
            refreshHeight(for: textView)
        }

        func refreshHeight(for textView: UITextView) {
            let width = max(1, textView.bounds.width)
            let fitting = textView.sizeThatFits(
                CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            ).height
            let clamped = min(max(fitting, parent.minHeight), parent.maxHeight)
            if abs(clamped - parent.measuredHeight) > 0.5 {
                parent.measuredHeight = clamped
            }
        }
    }
}