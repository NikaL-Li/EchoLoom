#if DEBUG
import SwiftUI

struct YZRecordsPreviewProvider: PreviewProvider {
    static var previews: some View {
        Group {
            RecordsView(
                sessions: YZSampleData.sessions,
                todaySessionCount: 1,
                totalSessionCount: 1,
                onSelectSession: { _ in },
                onRequestStartConversation: {}
            )
            .previewDisplayName("Default")

            RecordsView(
                sessions: [],
                todaySessionCount: 0,
                totalSessionCount: 0,
                onSelectSession: { _ in },
                onRequestStartConversation: {}
            )
            .previewDisplayName("Empty")
        }
    }
}
#endif