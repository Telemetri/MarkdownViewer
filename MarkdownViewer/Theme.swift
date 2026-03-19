import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue >> 16) & 0xFF) / 255.0,
            green: Double((rgbValue >> 8) & 0xFF) / 255.0,
            blue: Double(rgbValue & 0xFF) / 255.0
        )
    }

    // Catppuccin Latte (light mode)
    static let latteBase = Color(hex: "eff1f5")
    static let latteMantle = Color(hex: "e6e9ef")
    static let latteCrust = Color(hex: "dce0e8")
    static let latteText = Color(hex: "4c4f69")
    static let latteSubtext = Color(hex: "6c6f85")
    static let latteBlue = Color(hex: "1e66f5")
    static let latteGreen = Color(hex: "40a02b")
    static let latteRed = Color(hex: "d20f39")

    // Catppuccin Mocha (dark mode)
    static let mochaBase = Color(hex: "1e1e2e")
    static let mochaMantle = Color(hex: "181825")
    static let mochaCrust = Color(hex: "11111b")
    static let mochaText = Color(hex: "cdd6f4")
    static let mochaSubtext = Color(hex: "a6adc8")
    static let mochaBlue = Color(hex: "89b4fa")
    static let mochaGreen = Color(hex: "a6e3a1")
    static let mochaRed = Color(hex: "f38ba8")
}
