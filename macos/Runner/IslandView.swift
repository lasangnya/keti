import SwiftUI

struct IslandView: View {
    let message: String
    let resourceName: String
    var onDismiss: () -> Void

    @State private var currentFrame = 0
    @State private var isVisible = false
    @State private var hasFinished = false // Prevent multiple dismissal triggers
    
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    let totalFrames = 120

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Animation Sequence
            let frameName = String(format: "\(resourceName)_%05d", currentFrame)
            Image(frameName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onReceive(timer) { _ in
                    if currentFrame < totalFrames - 1 {
                        currentFrame += 1
                    } else if !hasFinished {
                        // 1. Auto-trigger exit when sequence ends
                        hasFinished = true
                        dismissWithAnimation()
                    }
                }

            // Dismiss Button
            Button(action: {
                if !hasFinished {
                    hasFinished = true
                    dismissWithAnimation()
                }
            }) {
                Text("Dismiss")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 12)
            .padding(.bottom, 8)
        }
        .background(Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        
        // Entry & Exit Animations
        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }

    // 2. Helper to handle the smooth exit
    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isVisible = false
        }
        // Wait for the spring animation (0.5s) before actually closing the native window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDismiss()
        }
    }
}
