import SwiftUI

struct IslandView: View {
    let message: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // The Icon
            Image(systemName: "drop.fill")
                .foregroundColor(.blue)
                .font(.system(size: 20, weight: .bold))

            // The Message
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}
