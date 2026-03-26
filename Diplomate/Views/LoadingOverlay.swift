import SwiftUI

struct LoadingOverlay: View {
    let progress: Double
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0

    private let brandPurple = Color(red: 124/255, green: 58/255, blue: 237/255)
    private let lightPurple = Color(red: 167/255, green: 139/255, blue: 250/255)

    var body: some View {
        ZStack {
            // Background gradient matching the app theme
            LinearGradient(
                gradient: Gradient(colors: [
                    brandPurple,
                    Color(red: 109/255, green: 40/255, blue: 217/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // App icon / branding
                VStack(spacing: 16) {
                    // Animated logo
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseScale)

                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .onAppear {
                        withAnimation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                        ) {
                            pulseScale = 1.15
                        }
                    }

                    Text("Diplomate")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Pratica le tue conversazioni")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Loading indicator
                VStack(spacing: 16) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: geometry.size.width * CGFloat(max(progress, 0.05)), height: 4)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 4)
                    .frame(maxWidth: 200)

                    Text("Caricamento...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
                    .frame(height: 80)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct LoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        LoadingOverlay(progress: 0.5)
    }
}
