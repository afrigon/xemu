import SwiftUI

struct NesInputView: View {
    @Environment(NESInput.self) var input
    
    let red: Color = .init(hex: 0xe64a46)
    let lightGray: Color = .init(hex: 0xd9d9d9)
    let gray: Color = .init(hex: 0x959691)
    let black: Color = .init(hex: 0x383838)
    
    let onMenu: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            createBackground()
            
            VStack(spacing: .zero) {
                HStack(alignment: .bottom, spacing: .l) {
                    createDPad()
                    
                    VStack(alignment: .trailing, spacing: .m) {
                        Button(action: {
                            onMenu()
                        }, label: {
                            HStack(spacing: .xxs) {
                                Text("MENU")
                                    .retroTextStyle(size: .s, weight: .bold)
                                    .padding(.top, 2)
                                    .foregroundStyle(lightGray)
                                Circle()
                                    .fill(lightGray)
                                    .frame(width: .m, height: .m)
                            }
                            .padding(.vertical, .m)
                        })
                        
                        createAB()
                    }
                }

                VStack(spacing: .s) {
                    HStack(spacing: .zero) {
                        StateButton(isPressed: input.binding(for: .select), label: {
                            RoundedRectangle(cornerRadius: .l)
                                .fill(black)
                        })
                        .frame(width: .xxxl, height: .s)
                        .padding(.xs)
                        .padding(.vertical, 2)
                        .padding(.top, .m)

                        StateButton(isPressed: input.binding(for: .start), label: {
                            RoundedRectangle(cornerRadius: .l)
                                .fill(black)
                        })
                        .frame(width: .xxxl, height: .s)
                        .padding(.xs)
                        .padding(.vertical, 2)
                        .padding(.top, .m)
                    }
                    
                    ZStack {
                        Text("Xemu")
                            .retroTextStyle(size: .xs, weight: .black)
                            .foregroundStyle(red)
                            .padding(.top, .xs + 2)
                            .padding(.bottom, .xs)
                            .padding(.horizontal, .m)
                            .offset(x: 120, y: 24)
                        
                        createStartSelectLabel()
                    }
                }
            }
        }
        .padding(.horizontal, .m)
        .padding(.top, .l)
        .padding(.bottom, .m)
        .background(lightGray)
    }
    
    @ViewBuilder
    private func createDPad() -> some View {
        GeometryReader { geometry in
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            let radius = min(
                geometry.size.width,
                geometry.size.height
            ) / 2
            let deadZone = radius * 0.15
            
            Image(.nesdPad)
                .resizable()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let p = value.location
                            let deltaX = p.x - center.x
                            let deltaY = p.y - center.y
                            let distance = hypot(deltaX, deltaY)

                            guard distance >= deadZone else {
                                keyUp(key: .up)
                                keyUp(key: .left)
                                keyUp(key: .right)
                                keyUp(key: .down)
                                return
                            }

                            if abs(deltaX) > abs(deltaY) {
                                if deltaX > 0 {
                                    keyDown(key: .right)
                                    keyUp(key: .up)
                                    keyUp(key: .left)
                                    keyUp(key: .down)
                                } else {
                                    keyDown(key: .left)
                                    keyUp(key: .up)
                                    keyUp(key: .right)
                                    keyUp(key: .down)
                                }
                            } else {
                                if deltaY > 0 {
                                    keyDown(key: .down)
                                    keyUp(key: .up)
                                    keyUp(key: .left)
                                    keyUp(key: .right)
                                } else {
                                    keyDown(key: .up)
                                    keyUp(key: .left)
                                    keyUp(key: .right)
                                    keyUp(key: .down)
                                }
                            }
                        }
                        .onEnded { _ in
                            keyUp(key: .up)
                            keyUp(key: .left)
                            keyUp(key: .right)
                            keyUp(key: .down)
                        }
                )
        }
        .frame(width: .xxxxxxxl, height: .xxxxxxxl)
    }
    
    @ViewBuilder
    private func createAB() -> some View {
        let buttonSize: CGFloat = 72
        let spacing: CGFloat = .l

        GeometryReader { geometry in
            let centerA = CGPoint(
                x: (buttonSize / 2) * 3 + spacing,
                y: geometry.size.height / 2
            )
            let centerB = CGPoint(
                x: buttonSize / 2,
                y: geometry.size.height / 2
            )
            let radius = (buttonSize + spacing) / 2
            
            HStack(spacing: spacing) {
                createButton(label: "B")
                createButton(label: "A")
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let p = value.location
                        let deltaA = hypot(p.x - centerA.x, p.y - centerA.y)
                        let deltaB = hypot(p.x - centerB.x, p.y - centerB.y)
                        let overlap = radius * 1.2
                        
                        if deltaA <= overlap && deltaB <= overlap {
                            keyDown(key: .a)
                            keyDown(key: .b)
                        } else if deltaA <= radius {
                            keyDown(key: .a)
                            keyUp(key: .b)
                        } else if deltaB <= radius {
                            keyUp(key: .a)
                            keyDown(key: .b)
                        } else {
                            keyUp(key: .a)
                            keyUp(key: .b)
                        }
                    }
                    .onEnded { value in
                        if input.isPressed(.a) || input.isPressed(.b) {
                            HapticsService.shared.prepare()
                            HapticsService.shared.impactOccurred(intensity: 0.5)
                            input.keyUp(.a)
                            input.keyUp(.b)
                        }
                    }
            )
        }
        .frame(
            width: buttonSize * 2 + spacing,
            height: buttonSize
        )
        .padding(.bottom, 24)
    }
    
    @ViewBuilder
    private func createButton(label: LocalizedStringResource) -> some View {
        VStack(alignment: .trailing, spacing: .xxs) {
            RoundedRectangle(cornerRadius: .s)
                .fill(lightGray)
                .stroke(gray, lineWidth: .xxxxs)
                .overlay {
                    Circle()
                        .fill(red)
                        .strokeBorder(red.darker(), lineWidth: .xxs)
                        .strokeBorder(.black.opacity(0.7), lineWidth: .xxxxs)
                        .padding(.xs)
                }
                .overlay(alignment: .bottomTrailing) {
                    Text(label)
                        .retroTextStyle(size: .xl, weight: .black)
                        .foregroundStyle(red)
                        .offset(y: 24)
                }
        }
    }
    
    @ViewBuilder
    private func createBackground() -> some View {
        VStack(spacing: .s) {
            createStartSelectLabel()
                .opacity(0)
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: .zero,
                        bottomLeadingRadius: .xs,
                        bottomTrailingRadius: .xs,
                        topTrailingRadius: .zero,
                    )
                    .fill(gray)
                }
            
            createStartSelectLabel()
                .opacity(0)
                .background {
                    RoundedRectangle(cornerRadius: .xs)
                        .fill(gray)
                }
            
            createStartSelectLabel()
                .opacity(0)
                .background {
                    RoundedRectangle(cornerRadius: .xs)
                        .fill(gray)
                }

            createStartSelectLabel()
                .opacity(0)
                .background {
                    RoundedRectangle(cornerRadius: .xs)
                        .fill(gray)
                }
            
            createStartSelectLabel()
                .opacity(0)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: .xs)
                            .fill(lightGray)
                        
                        Rectangle()
                            .fill(lightGray)
                            .padding(.xxs)
                            .shadow(color: .black.opacity(0.75), radius: 1, x: -1, y: -1)
                            .shadow(color: .white, radius: 1, x: 1, y: 1)
                    }
                }

            createStartSelectLabel()
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: .xs,
                        bottomLeadingRadius: .zero,
                        bottomTrailingRadius: .zero,
                        topTrailingRadius: .xs,
                    )
                    .fill(gray)
                }
        }
        .frame(maxWidth: .infinity)
        .background(black)
        .overlay {
            Image(.grainNoise)
                .resizable()
                .scaledToFill()
                .opacity(0.2)
                .blendMode(.overlay)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: .xs,
                bottomLeadingRadius: .xl,
                bottomTrailingRadius: .xl,
                topTrailingRadius: .xs,
            )
        )
    }

    @ViewBuilder
    private func createStartSelectLabel() -> some View {
        HStack(spacing: .m) {
            Text("SELECT")
            
            Text("START")
        }
        .retroTextStyle(size: .m, weight: .black)
        .foregroundStyle(red)
        .padding(.top, .xs + 2)
        .padding(.bottom, .xs)
        .padding(.horizontal, .m)
    }
    
    private func keyDown(key: NESInputKey) {
        if !input.isPressed(key) {
            input.keyDown(key)
            HapticsService.shared.prepare()
            HapticsService.shared.impactOccurred()
        }
    }
    
    private func keyUp(key: NESInputKey) {
        if input.isPressed(key) {
            input.keyUp(key)
            HapticsService.shared.prepare()
            HapticsService.shared.impactOccurred(intensity: 0.6)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        
        NesInputView(onMenu: {})
            .environment(NESInput())
    }
    .ignoresSafeArea()
}
