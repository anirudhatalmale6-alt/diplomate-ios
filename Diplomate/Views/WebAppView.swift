import SwiftUI

struct WebAppView: View {
    @StateObject private var viewModel = WebViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        ZStack(alignment: .top) {
            // Status bar background
            Color(red: 124/255, green: 58/255, blue: 237/255)
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // Progress bar
                if viewModel.isLoading {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.purple.opacity(0.2))
                                .frame(height: 3)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 124/255, green: 58/255, blue: 237/255),
                                            Color(red: 168/255, green: 85/255, blue: 247/255)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * viewModel.estimatedProgress, height: 3)
                                .animation(.linear(duration: 0.2), value: viewModel.estimatedProgress)
                        }
                    }
                    .frame(height: 3)
                }

                // Web content
                WebViewRepresentable(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.bottom)
            }

            // Error overlay
            if viewModel.showError {
                ErrorOverlayView(
                    errorMessage: viewModel.errorMessage,
                    onRetry: {
                        viewModel.retry()
                    }
                )
                .transition(.opacity)
            }
        }
        .onChange(of: networkMonitor.isConnected) { connected in
            if connected && viewModel.showError {
                viewModel.retry()
            }
        }
    }
}

struct ErrorOverlayView: View {
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 56))
                    .foregroundColor(Color(red: 124/255, green: 58/255, blue: 237/255))

                Text("Connection Issue")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text(errorMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 124/255, green: 58/255, blue: 237/255),
                                Color(red: 109/255, green: 40/255, blue: 217/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
}
