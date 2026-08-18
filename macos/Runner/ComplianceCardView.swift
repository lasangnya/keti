import SwiftUI

/// The compliance card itself: question + two buttons. Button 1 reports the
/// `completed` action, button 2 reports `dismissed` — the labels shown to
/// the participant never carry the outcome vocabulary.
struct ComplianceCardView: View {
    let question: String
    let button1Text: String
    let button2Text: String
    let onAction: (String) -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 16) {
            Text(question)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(action: { onAction("completed") }) {
                    Text(button1Text)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .frame(minWidth: 120)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button(action: { onAction("dismissed") }) {
                    Text(button2Text)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .frame(minWidth: 120)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(
            Color.black.opacity(0.9)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .offset(y: isVisible ? 0 : -20)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}
