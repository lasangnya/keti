import SwiftUI

struct IslandView: View {
    let message: String
    let resourceName: String
    var onDismiss: () -> Void

    @State private var currentFrame = 0
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    let totalFrames = 120

    var body: some View {
        HStack(spacing: 20) {
            // The Animation
            let frameName = String(format: "\(resourceName)_%05d", currentFrame)
            Image(frameName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .onReceive(timer) { _ in
                    if currentFrame < totalFrames - 1 {
                        currentFrame += 1
                    }
                }

            // The Message
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            // The Dismiss Button
            Button(action: onDismiss) {
                Text("Dismiss")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}
