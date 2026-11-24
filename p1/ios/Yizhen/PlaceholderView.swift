import SwiftUI

struct PlaceholderView: View {
    let title: String

    var body: some View {
        Text("\(title)（占位）")
            .font(.system(size: 17))
            .foregroundStyle(YZTheme.ink2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PlaceholderView(title: "首页")
}