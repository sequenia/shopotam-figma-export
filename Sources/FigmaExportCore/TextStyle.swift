public struct TextStyle {
    
    public let name: String
    public let fontName: String
    public let fontSize: Double
    public let lineHeight: Double?
    public let letterSpacing: Double
    public let width: Double?

    public init(
        name: String,
        fontName: String,
        fontSize: Double,
        lineHeight: Double? = nil,
        letterSpacing: Double,
        width: Double? = nil
    ) {

        self.name = name
        self.fontName = fontName
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.width = width
    }
}
