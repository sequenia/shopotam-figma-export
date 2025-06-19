import Foundation

public struct TokenValue: Decodable {
    public let value: StringOrNumber
    public let type: String
    public var description: String?

    enum CodingKeys: String, CodingKey {
        case value, type, description
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        if let stringValue = try? container.decode(String.self, forKey: .value) {
            value = .string(stringValue)
        } else if let numberValue = try? container.decode(Double.self, forKey: .value) {
            value = .number(numberValue)
        } else {
            throw DecodingError.typeMismatch(
                StringOrNumber.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or Double for value"
                )
            )
        }
    }
}

public enum StringOrNumber {
    case string(String)
    case number(Double)

    public func getDoubleValue() -> Double? {
        switch self {
        case .string:
            return nil
        case .number(let double):
            return double
        }
    }
}

public struct FontWeightData: Decodable {
    public let fontWeight: TokenValue

    enum CodingKeys: String, CodingKey {
        case fontWeight = "font-weight"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontWeight = try container.decode(TokenValue.self, forKey: .fontWeight)
    }
}

// Структуры для Control/Value
public struct ControlValue: Decodable {
    public let fontSize: [String: TokenValue]
    public let lineHeight: [String: TokenValue]
    public let letterSpacing: [String: TokenValue]
    public let paragraphSpacing: [String: TokenValue]
    public let control: [String: TokenValue]

    enum CodingKeys: String, CodingKey {
        case fontSize = "font-size"
        case lineHeight = "line-height"
        case letterSpacing = "letter-spacing"
        case paragraphSpacing = "paragraph-spacing"
        case control
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontSize = try container.decode([String: TokenValue].self, forKey: .fontSize)
        lineHeight = try container.decode([String: TokenValue].self, forKey: .lineHeight)
        letterSpacing = try container.decode([String: TokenValue].self, forKey: .letterSpacing)
        paragraphSpacing = try container.decode([String: TokenValue].self, forKey: .paragraphSpacing)
        control = try container.decode([String: TokenValue].self, forKey: .control)
    }
}

public struct TypographyStyle: Decodable {
    public let fontSize: [String: TokenValue]?
    public let lineHeight: [String: TokenValue]?
    public let letterSpacing: [String: TokenValue]?
    public let paragraphSpacing: [String: TokenValue]?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontSize = try container.decodeIfPresent([String: TokenValue].self, forKey: .fontSize)
        lineHeight = try container.decodeIfPresent([String: TokenValue].self, forKey: .lineHeight)
        letterSpacing = try container.decodeIfPresent([String: TokenValue].self, forKey: .letterSpacing)
        paragraphSpacing = try container.decodeIfPresent([String: TokenValue].self, forKey: .paragraphSpacing)
    }

    enum CodingKeys: String, CodingKey {
        case fontSize = "font-size"
        case lineHeight = "line-height"
        case letterSpacing = "letter-spacing"
        case paragraphSpacing = "paragraph-spacing"
    }
}

// Структуры для Typography/Mobile
public struct TypographyMobile: Decodable {
    public let body: TypographyStyle
    public let title: TypographyStyle
    public let heading: TypographyStyle
    public let display: TypographyStyle

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        body = try container.decode(TypographyStyle.self, forKey: .body)
        title = try container.decode(TypographyStyle.self, forKey: .title)
        heading = try container.decode(TypographyStyle.self, forKey: .heading)
        display = try container.decode(TypographyStyle.self, forKey: .display)
    }

    enum CodingKeys: String, CodingKey {
        case body, title, heading, display
    }
}

public struct DesignTokens: Decodable {
    public let fontWeights: [String: FontWeightData]
    public let controlValue: ControlValue
    public let typographyMobile: TypographyMobile

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let jsonDict = try container.decode([String: AnyDecodable].self)

        // Parse font weights
        var fontWeights = [String: FontWeightData]()
        for (key, value) in jsonDict {
            if key.hasPrefix("Font-weight/") {
                let fontWeightKey = String(key.dropFirst("Font-weight/".count))
                let data = try JSONDecoder().decode(FontWeightData.self, from: JSONSerialization.data(withJSONObject: value.value))
                fontWeights[fontWeightKey] = data
            }
        }

        // Parse Control/Value
        guard let controlValueData = jsonDict["Control/Value"]?.value else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing Control/Value"))
        }
        let controlValue = try JSONDecoder().decode(ControlValue.self, from: JSONSerialization.data(withJSONObject: controlValueData))

        // Parse Typography/Mobile
        guard let typographyData = jsonDict["Typography/Mobile"]?.value else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing Typography/Mobile"))
        }
        let typographyMobile = try JSONDecoder().decode(TypographyMobile.self, from: JSONSerialization.data(withJSONObject: typographyData))

        self.fontWeights = fontWeights
        self.controlValue = controlValue
        self.typographyMobile = typographyMobile
    }
}

// Вспомогательная структура для динамического декодирования
public struct AnyDecodable: Decodable {
    public let value: Any

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let dict = try? container.decode([String: AnyDecodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyDecodable].self) {
            value = array.map { $0.value }
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let number = try? container.decode(Double.self) {
            value = number
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported value type")
        }
    }
}
