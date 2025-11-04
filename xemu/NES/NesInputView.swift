import SwiftUI

struct NesInputView: View {
    let red: Color = .init(hex: 0xe64a46)
    let gray: Color = .init(hex: 0xd9d9d9)
    let black: Color = .init(hex: 0x383838)

    var body: some View {
        VStack(spacing: .zero) {
            HStack(spacing: .zero) {
                dpad()
                
                Spacer(minLength: .zero)
                
                HStack(spacing: .m) {
                    button(label: "B")
                    button(label: "A")
                }
                .padding(.s)
            }
            
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: .xs)
                    .fill(gray)
                
                HStack() {
                    RoundedRectangle(cornerRadius: .s)
                        .fill(black)
                        .frame(height: .m)
                    RoundedRectangle(cornerRadius: .s)
                        .fill(black)
                        .frame(height: .m)
                }
            }
        }
        .background(black)
        .frame(maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func dpad() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: .xs)
                .fill(black)
                .frame(width: 70)
            RoundedRectangle(cornerRadius: .xs)
                .fill(black)
                .frame(height: 70)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func button(label: String) -> some View {
        VStack(alignment: .trailing, spacing: .xxs) {
            RoundedRectangle(cornerRadius: .s)
                .fill(gray)
                .stroke(gray.darker(), lineWidth: .xxxxs)
//                .frame(width: 72, height: 72)
                .overlay {
                    Circle()
                        .fill(red)
                        .strokeBorder(red.darker(), lineWidth: .xxs)
                        .strokeBorder(.black.opacity(0.7), lineWidth: .xxxxs)
                        .padding(.xs)
                }
                .aspectRatio(1, contentMode: .fit)
            
            Text(label)
                .font(.retro(size: .header, weight: .bold))
                .foregroundStyle(red)
        }
    }
}

#Preview {
    NesInputView()
}
