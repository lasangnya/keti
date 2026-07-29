import SwiftUI

/// Top-center notch card. Purely presentational (uniform study instrument):
/// the animation plays once, holds its final frame, and the manager ends
/// the visibility window — there is deliberately no dismiss affordance.
struct IslandView: View {
    let message: String
    let resourceName: String
    let totalFrames: Int
    let visibilityMs: Int

    @State private var currentFrame = 0
    @State private var isVisible = false

    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            let frameName = String(format: "\(resourceName)_%05d", currentFrame)
            Image(frameName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onReceive(timer) { _ in
                    if currentFrame < totalFrames - 1 {
                        currentFrame += 1
                    }
                }
        }
        .background(Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }

            // Start exit animation 500ms before the manager's dismiss() is called.
            let exitDelay = max(0.1, Double(visibilityMs) / 1000.0 - 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + exitDelay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isVisible = false
                }
            }
        }
    }
}
