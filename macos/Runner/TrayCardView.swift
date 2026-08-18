import SwiftUI

/// Card dropped under the tray item: plays the animation once, then the
/// out-animation triggers immediately when the last frame is reached.
/// Text is intentionally hidden — the ambient/character animation alone
/// carries the reminder.
struct TrayCardView: View {
    let resourceName: String
    let totalFrames: Int
    let visibilityMs: Int
    let onAnimationDone: () -> Void

    @State private var currentFrame = 0
    @State private var isVisible = false
    @State private var hasFinished = false

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
                    } else if !hasFinished {
                        let t0 = CFAbsoluteTimeGetCurrent()
                        print("[TrayCardView] 🎞️ Last frame reached — starting out-animation. totalFrames=\(totalFrames)")
                        hasFinished = true
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("[TrayCardView] ✅ onAnimationDone() called. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
                            onAnimationDone()
                        }
                    }
                }
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
            let t0 = CFAbsoluteTimeGetCurrent()
            print("[TrayCardView] onAppear fired. totalFrames=\(totalFrames)")

            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isVisible = true
            }
            print("[TrayCardView] In-animation started (isVisible -> true). t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
        }
        .onDisappear {
            print("[TrayCardView] 👻 onDisappear fired")
        }
    }
}
