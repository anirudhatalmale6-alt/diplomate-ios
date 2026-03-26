import SwiftUI

struct NativeTabBar: View {
    @Binding var selectedTab: WebViewManager.Tab
    @Environment(\.colorScheme) var colorScheme

    private let brandPurple = Color(red: 124/255, green: 58/255, blue: 237/255)
    private let inactiveGray = Color(red: 142/255, green: 142/255, blue: 147/255)

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))

            HStack {
                ForEach(WebViewManager.Tab.allCases, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        brandColor: brandPurple,
                        inactiveColor: inactiveGray
                    ) {
                        if selectedTab != tab {
                            HapticManager.selection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            .padding(.horizontal, 16)
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
            )
            // Safe area padding for bottom (home indicator)
            .padding(.bottom, safeAreaBottom)
        }
    }

    private var safeAreaBottom: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}

struct TabBarButton: View {
    let tab: WebViewManager.Tab
    let isSelected: Bool
    let brandColor: Color
    let inactiveColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? brandColor : inactiveColor)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? brandColor : inactiveColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NativeTabBar_Previews: PreviewProvider {
    static var previews: some View {
        NativeTabBar(selectedTab: .constant(.home))
    }
}
