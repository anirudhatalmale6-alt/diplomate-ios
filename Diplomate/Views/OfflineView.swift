import SwiftUI

struct OfflineView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 124/255, green: 58/255, blue: 237/255))
                }

                VStack(spacing: 12) {
                    Text("You're Offline")
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    Text("Diplomate needs an internet connection to practice conversations. Please check your connection and try again.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 124/255, green: 58/255, blue: 237/255)))

                    Text("Waiting for connection...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }
}
