import SwiftUI

struct OfflineView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var isAnimating = false

    private let brandPurple = Color(red: 124/255, green: 58/255, blue: 237/255)

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Offline icon with animation
                ZStack {
                    Circle()
                        .fill(brandPurple.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(brandPurple)
                        .offset(y: isAnimating ? -4 : 4)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }

                VStack(spacing: 12) {
                    Text("Nessuna connessione")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Verifica la tua connessione internet\ne riprova.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // Retry hint
                VStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundColor(brandPurple)

                    Text("L'app si riconnetter\u{00E0} automaticamente")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            isAnimating = true
            HapticManager.notification(.warning)
        }
    }
}

struct OfflineView_Previews: PreviewProvider {
    static var previews: some View {
        OfflineView()
            .environmentObject(NetworkMonitor())
    }
}
