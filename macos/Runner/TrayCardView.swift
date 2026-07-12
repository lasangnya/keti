import SwiftUI

struct TrayCardView: View {
    let message: String
    let resourceName: String
    
    @State private var currentFrame = 0
    @State private var isVisible = false
    
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    let totalFrames = 120

    var body: some View {
        HStack(spacing: 12) {
            // 1. The same animation sequence as the tray
            let frameName = String(format: "\(resourceName)_%05d", currentFrame)
            Image(frameName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24) // Slightly larger than the tray icon
                .onReceive(timer) { _ in
                    if currentFrame < totalFrames - 1 {
                        currentFrame += 1
                    }
                }
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        
        // Entry animation
        .offset(y: isVisible ? 0 : -8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}
