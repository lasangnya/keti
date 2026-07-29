import SwiftUI

/// Card dropped under the tray item: plays the animation once, holds the
/// final frame, and shows the reminder message text next to it.
struct TrayCardView: View {
    let message: String
    let resourceName: String
    let totalFrames: Int
    let visibilityMs: Int

    @State private var currentFrame = 0
    @State private var isVisible = false

    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 12) {
            let frameName = String(format: "\(resourceName)_%05d", currentFrame)
            Image(frameName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .onReceive(timer) { _ in
                    if currentFrame < totalFrames - 1 {
                        currentFrame += 1
                    }
                }

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)

        .offset(y: isVisible ? 0 : -8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isVisible = true
            }

            // Start exit animation 500ms before the manager's dismiss() is called.
            let exitDelay = max(0.1, Double(visibilityMs) / 1000.0 - 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + exitDelay) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isVisible = false
                }
            }
        }
    }
}
