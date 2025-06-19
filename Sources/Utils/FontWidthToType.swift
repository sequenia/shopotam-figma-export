public enum FontWidthType: Double {

    case light = 300.0
    case regular = 400.0
    case medium = 500.0
    case semibold = 600.0
    case bold = 700.0

    public func getType() -> String {
        switch self {
        case .light:
            return "-Light"
        case .regular:
            return "-Regular"
        case .medium:
            return "-Medium"
        case .semibold:
            return "-Semibold"
        case .bold:
            return "-Bold"
        }
    }
}
