import SwiftUI

/// Top-center notch card. Purely presentational (uniform study instrument):
/// the animation plays once, then the out-animation triggers immediately
/// when the last frame is reached.
struct IslandView: View {
    let message: String
    let resourceName: String
    let totalFrames: Int
    let visibilityMs: Int
    let onAnimationDone: () -> Void

    @State private var currentFrame = 0
    @State private var isVisible = false
    @State private var hasFinished = false

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
                    } else if !hasFinished {
                        let t0 = CFAbsoluteTimeGetCurrent()
                        print("[IslandView] 🎞️ Last frame reached — starting out-animation. totalFrames=\(totalFrames)")
                        hasFinished = true
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("[IslandView] ✅ onAnimationDone() called. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
                            onAnimationDone()
                        }
                    }
                }
        }
        .background(Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            let t0 = CFAbsoluteTimeGetCurrent()
            print("[IslandView] onAppear fired. totalFrames=\(totalFrames)")

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
            print("[IslandView] In-animation started (isVisible -> true). t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
        }
        .onDisappear {
            print("[IslandView] 👻 onDisappear fired")
        }
    }
}
