import SwiftUI

/// A horizontal tab bar for switching between task lists.
struct TabBarView: View {
    let tabs: [TabStore.Tab]
    let selectedTabID: TabStore.Tab.ID
    var onSelectTab: (TabStore.Tab.ID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    let isActive = (tab.id == selectedTabID)

                    Text(tab.name)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(isActive ? Theme.accent.opacity(0.3)
                                            : Theme.base.opacity(0.2))
                        .onTapGesture { onSelectTab(tab.id) }
                }
            }
        }
        .frame(height: 28)
    }
}
