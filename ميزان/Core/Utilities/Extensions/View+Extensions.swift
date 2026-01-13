//
//  View+Extensions.swift
//  Mizan
//
//  SwiftUI View extensions and modifiers
//

import SwiftUI

// MARK: - RTL Support

extension View {
    /// Apply RTL layout direction for Arabic
    func rtlSupport(language: AppLanguage) -> some View {
        self.environment(\.layoutDirection, language == .arabic ? .rightToLeft : .leftToRight)
    }
}

// MARK: - Animations

extension View {
    /// Apply gentle spring animation
    func gentleSpring() -> some View {
        let config = ConfigurationManager.shared.animationConfig.springs["gentle"]!
        return self.animation(
            .spring(response: config.response, dampingFraction: config.dampingFraction),
            value: UUID()
        )
    }

    /// Apply bouncy spring animation
    func bouncySpring() -> some View {
        let config = ConfigurationManager.shared.animationConfig.springs["bouncy"]!
        return self.animation(
            .spring(response: config.response, dampingFraction: config.dampingFraction),
            value: UUID()
        )
    }

    /// Apply snappy spring animation
    func snappySpring() -> some View {
        let config = ConfigurationManager.shared.animationConfig.springs["snappy"]!
        return self.animation(
            .spring(response: config.response, dampingFraction: config.dampingFraction),
            value: UUID()
        )
    }
}

// MARK: - Conditional Modifiers

extension View {
    /// Apply modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply modifier if let
    @ViewBuilder
    func ifLet<Value, Transform: View>(_ value: Value?, transform: (Self, Value) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Loading States

struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0.3 : 1.0)
                .disabled(isLoading)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}

extension View {
    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

// MARK: - Error Handling

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<Error?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

// MARK: - Haptic Feedback

extension View {
    /// Add tap gesture with haptic feedback
    func onTapWithHaptic(_ type: HapticType = .light, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.shared.trigger(type)
            action()
        }
    }
}

// MARK: - Shadows and Glows

struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: x, y: y)
    }
}

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.7), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.5), radius: radius * 0.7, x: 0, y: 0)
    }
}

extension View {
    func customShadow(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        modifier(ShadowModifier(color: color, radius: radius, x: x, y: y))
    }

    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Keyboard

extension View {
    /// Dismiss keyboard on tap
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Safe Area

extension View {
    /// Get safe area insets
    func getSafeAreaInsets() -> EdgeInsets {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return EdgeInsets()
        }

        let insets = window.safeAreaInsets
        return EdgeInsets(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
    }
}

// MARK: - Corner Radius

extension View {
    /// Apply corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Placeholder

extension View {
    /// Show placeholder when condition is true
    @ViewBuilder
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Readable Content Guide

extension View {
    /// Limit content width for readability
    func readableContentGuide() -> some View {
        self.frame(maxWidth: 600)
    }
}

// MARK: - Device Detection

extension View {
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - Navigation

extension View {
    /// Add navigation bar items with RTL support
    func navigationBarItems<L: View, T: View>(
        leading: L,
        trailing: T,
        rtl: Bool = false
    ) -> some View {
        self
            .toolbar {
                ToolbarItem(placement: rtl ? .navigationBarTrailing : .navigationBarLeading) {
                    leading
                }
                ToolbarItem(placement: rtl ? .navigationBarLeading : .navigationBarTrailing) {
                    trailing
                }
            }
    }
}

// MARK: - Frame Modifiers

extension View {
    /// Fill available space
    func fillWidth() -> some View {
        self.frame(maxWidth: .infinity)
    }

    func fillHeight() -> some View {
        self.frame(maxHeight: .infinity)
    }

    func fillSpace() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Scroll Effects

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// Track scroll offset
    func trackScrollOffset(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("scroll")).minY
                )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: onChange)
    }
}
