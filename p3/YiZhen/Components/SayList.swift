import SwiftUI

struct SayList: View {
    let context: SayListContext

    var body: some View {
        SayListView(context: context)
    }
}