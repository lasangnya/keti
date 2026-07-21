import SwiftUI

struct ComplianceCardView: View {
    let title: String
    let button1Text: String
    let button2Text: String
    let onAction: (String) -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 8) {
                Button(action: { onAction(button1Text) }) {
                    Text(button1Text)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 80)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                Button(action: { onAction(button2Text) }) {
                    Text(button2Text)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 80)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            VisualEffectView(material: .underWindowBackground, blendingMode: .withinWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
