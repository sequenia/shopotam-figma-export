import Foundation

// MARK: - Root Structure
public struct SpaceTokens: Decodable {
    public let spaceValue: SpaceValue
    public let roundedSmooth: RoundedCategory
    public let roundedRounded: RoundedCategory
    public let roundedNone: RoundedCategory
    public let layoutMobile: LayoutCategory

    public enum CodingKeys: String, CodingKey {
        case spaceValue = "Space/Value"
        case roundedSmooth = "Rounded/Smooth"
        case roundedRounded = "Rounded/Rounded"
        case roundedNone = "Rounded/None"
        case layoutMobile = "Layout/Mobile"
    }

    public init(
        spaceValue: SpaceValue,
        roundedSmooth: RoundedCategory,
        roundedRounded: RoundedCategory,
        roundedNone: RoundedCategory,
        layoutMobile: LayoutCategory
    ) {
        self.spaceValue = spaceValue
        self.roundedSmooth = roundedSmooth
        self.roundedRounded = roundedRounded
        self.roundedNone = roundedNone
        self.layoutMobile = layoutMobile
    }
}

// MARK: - Space Value
public struct SpaceValue: Decodable {
    public let space: [String: SpaceTokenValue]

    public init(space: [String: SpaceTokenValue]) {
        self.space = space
    }
}

// MARK: - Token Types
public struct SpaceTokenValue: Decodable {
    public let value: Double
    public let type: String
    public let description: String?

    public init(value: Double, type: String, description: String? = nil) {
        self.value = value
        self.type = type
        self.description = description
    }
}

public struct TokenReference: Decodable {
    public let value: String
    public let type: String

    public init(value: String, type: String) {
        self.value = value
        self.type = type
    }

    public func resolvedValue(from spaceValues: [String: SpaceTokenValue]) -> Double? {
        guard value.starts(with: "{") && value.hasSuffix("}") else { return nil }
        let key = value.trimmingCharacters(in: ["{", "}"])
            .replacingOccurrences(of: "space.", with: "")
        return spaceValues[key]?.value
    }

    public func resolvedValueKey() -> String {
        guard value.starts(with: "{") && value.hasSuffix("}") else {
            return value
        }

        let key = value.trimmingCharacters(in: ["{", "}"])
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "_")

        return key
    }

    public func resolvedValueKeyForAndroid() -> String {
        guard value.starts(with: "{") && value.hasSuffix("}") else {
            return value
        }

        let key = value.trimmingCharacters(in: ["{", "}"])
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: ",", with: "_")

        return "\(key)"
    }
}

// MARK: - Rounded Categories
public struct RoundedCategory: Decodable {
    public let borderRadius: [String: SpaceTokenValue]?
    public let outline: [String: SpaceTokenValue]?
    public let conteiner4: [String: SpaceTokenValue]?
    public let conteiner6: [String: SpaceTokenValue]?
    public let bg1: [String: SpaceTokenValue]?
    public let conteiner2: [String: SpaceTokenValue]?
    public let x4: [String: SpaceTokenValue]?
    public let x6: [String: SpaceTokenValue]?

    public enum CodingKeys: String, CodingKey {
        case borderRadius = "border-radius"
        case outline
        case conteiner4 = "conteiner-4"
        case conteiner6 = "conteiner-6"
        case bg1 = "bg-1"
        case conteiner2 = "conteiner-2"
        case x4
        case x6
    }

    public init(
        borderRadius: [String: SpaceTokenValue]? = nil,
        outline: [String: SpaceTokenValue]? = nil,
        conteiner4: [String: SpaceTokenValue]? = nil,
        conteiner6: [String: SpaceTokenValue]? = nil,
        bg1: [String: SpaceTokenValue]? = nil,
        conteiner2: [String: SpaceTokenValue]? = nil,
        x4: [String: SpaceTokenValue]? = nil,
        x6: [String: SpaceTokenValue]? = nil
    ) {
        self.borderRadius = borderRadius
        self.outline = outline
        self.conteiner4 = conteiner4
        self.conteiner6 = conteiner6
        self.bg1 = bg1
        self.conteiner2 = conteiner2
        self.x4 = x4
        self.x6 = x6
    }
}

// MARK: - Layout Category
public struct LayoutCategory: Decodable {
    public let layout: Layout

    public init(layout: Layout) {
        self.layout = layout
    }
}

// MARK: - Layout Subtypes
public extension LayoutCategory {
    struct Layout: Decodable {
        public let market: Market?
        public let cms: Cms?

        public init(market: Market? = nil, cms: Cms? = nil) {
            self.market = market
            self.cms = cms
        }
    }

    struct Market: Decodable {
        public let block: Block?
        public let card: Card?
        public let section: Section?
        public let banner: Banner?
        public let productcard: ProductCard?
        public let paragraph: Paragraph?
        public let form: Form?

        public init(
            block: Block? = nil,
            card: Card? = nil,
            section: Section? = nil,
            banner: Banner? = nil,
            productcard: ProductCard? = nil,
            paragraph: Paragraph? = nil,
            form: Form? = nil
        ) {
            self.block = block
            self.card = card
            self.section = section
            self.banner = banner
            self.productcard = productcard
            self.paragraph = paragraph
            self.form = form
        }
    }

    struct Cms: Decodable {
        public let gap: TokenReference?
        public let side: TokenReference?
        public let top: TokenReference?
        public let card: CmsCard?
        public let banner: CmsBanner?
        public let max: SpaceTokenValue?
        public let sideEditor: TokenReference?
        public let bottom: TokenReference?
        public let section: CmsSection?

        public enum CodingKeys: String, CodingKey {
            case gap, side, top, card, banner, max
            case sideEditor = "side-editor"
            case bottom, section
        }

        public init(
            gap: TokenReference? = nil,
            side: TokenReference? = nil,
            top: TokenReference? = nil,
            card: CmsCard? = nil,
            banner: CmsBanner? = nil,
            max: SpaceTokenValue? = nil,
            sideEditor: TokenReference? = nil,
            bottom: TokenReference? = nil,
            section: CmsSection? = nil
        ) {
            self.gap = gap
            self.side = side
            self.top = top
            self.card = card
            self.banner = banner
            self.max = max
            self.sideEditor = sideEditor
            self.bottom = bottom
            self.section = section
        }
    }
}

// MARK: - Market Subtypes
public extension LayoutCategory.Market {
    struct Block: Decodable {
        public let gap: TokenReference?
        public let top: TokenReference?

        public init(gap: TokenReference? = nil, top: TokenReference? = nil) {
            self.gap = gap
            self.top = top
        }
    }

    struct Card: Decodable {
        public let sliderMin: SpaceTokenValue?
        public let sliderMax: SpaceTokenValue?
        public let listingMin: SpaceTokenValue?
        public let listingMax: SpaceTokenValue?

        public enum CodingKeys: String, CodingKey {
            case sliderMin = "slider-min"
            case sliderMax = "slider-max"
            case listingMin = "listing-min"
            case listingMax = "listing-max"
        }

        public init(
            sliderMin: SpaceTokenValue? = nil,
            sliderMax: SpaceTokenValue? = nil,
            listingMin: SpaceTokenValue? = nil,
            listingMax: SpaceTokenValue? = nil
        ) {
            self.sliderMin = sliderMin
            self.sliderMax = sliderMax
            self.listingMin = listingMin
            self.listingMax = listingMax
        }
    }

    struct Section: Decodable {
        public let side: TokenReference?
        public let largeMax: SpaceTokenValue?
        public let top: TokenReference?
        public let bottom: TokenReference?
        public let smallMax: SpaceTokenValue?
        public let sideCms: TokenReference?

        public enum CodingKeys: String, CodingKey {
            case side
            case largeMax = "large-max"
            case top, bottom
            case smallMax = "small-max"
            case sideCms = "side-cms"
        }

        public init(
            side: TokenReference? = nil,
            largeMax: SpaceTokenValue? = nil,
            top: TokenReference? = nil,
            bottom: TokenReference? = nil,
            smallMax: SpaceTokenValue? = nil,
            sideCms: TokenReference? = nil
        ) {
            self.side = side
            self.largeMax = largeMax
            self.top = top
            self.bottom = bottom
            self.smallMax = smallMax
            self.sideCms = sideCms
        }
    }

    struct Banner: Decodable {
        public let threeMin: SpaceTokenValue?
        public let threeMax: SpaceTokenValue?
        public let twoMin: SpaceTokenValue?
        public let twoMax: SpaceTokenValue?
        public let fourMin: SpaceTokenValue?
        public let fourMax: SpaceTokenValue?
        public let oneMax: SpaceTokenValue?
        public let oneMin: SpaceTokenValue?

        public enum CodingKeys: String, CodingKey {
            case threeMin = "3-min"
            case threeMax = "3-max"
            case twoMin = "2-min"
            case twoMax = "2-max"
            case fourMin = "4-min"
            case fourMax = "4-max"
            case oneMax = "1-max"
            case oneMin = "1-min"
        }

        public init(
            threeMin: SpaceTokenValue? = nil,
            threeMax: SpaceTokenValue? = nil,
            twoMin: SpaceTokenValue? = nil,
            twoMax: SpaceTokenValue? = nil,
            fourMin: SpaceTokenValue? = nil,
            fourMax: SpaceTokenValue? = nil,
            oneMax: SpaceTokenValue? = nil,
            oneMin: SpaceTokenValue? = nil
        ) {
            self.threeMin = threeMin
            self.threeMax = threeMax
            self.twoMin = twoMin
            self.twoMax = twoMax
            self.fourMin = fourMin
            self.fourMax = fourMax
            self.oneMax = oneMax
            self.oneMin = oneMin
        }
    }

    struct ProductCard: Decodable {
        public let top: TokenReference?
        public let pragraph: TokenReference?
        public let gap: TokenReference?

        public init(
            top: TokenReference? = nil,
            pragraph: TokenReference? = nil,
            gap: TokenReference? = nil
        ) {
            self.top = top
            self.pragraph = pragraph
            self.gap = gap
        }
    }

    struct Paragraph: Decodable {
        public let top: TokenReference?

        public init(top: TokenReference? = nil) {
            self.top = top
        }
    }

    struct Form: Decodable {
        public let top: TokenReference?
        public let gap: TokenReference?
        public let groupGap: TokenReference?

        public enum CodingKeys: String, CodingKey {
            case top, gap
            case groupGap = "group-gap"
        }

        public init(
            top: TokenReference? = nil,
            gap: TokenReference? = nil,
            groupGap: TokenReference? = nil
        ) {
            self.top = top
            self.gap = gap
            self.groupGap = groupGap
        }
    }
}

// MARK: - Cms Subtypes
public extension LayoutCategory.Cms {
    struct CmsCard: Decodable {
        public let cardMin: SpaceTokenValue?
        public let cardMax: SpaceTokenValue?

        public enum CodingKeys: String, CodingKey {
            case cardMin = "card-min"
            case cardMax = "card-max"
        }

        public init(cardMin: SpaceTokenValue? = nil, cardMax: SpaceTokenValue? = nil) {
            self.cardMin = cardMin
            self.cardMax = cardMax
        }
    }

    struct CmsBanner: Decodable {
        public let fourMin: SpaceTokenValue?
        public let fourMax: SpaceTokenValue?
        public let eightMin: SpaceTokenValue?
        public let eightMax: SpaceTokenValue?

        public enum CodingKeys: String, CodingKey {
            case fourMin = "4-min"
            case fourMax = "4-max"
            case eightMin = "8-min"
            case eightMax = "8-max"
        }

        public init(
            fourMin: SpaceTokenValue? = nil,
            fourMax: SpaceTokenValue? = nil,
            eightMin: SpaceTokenValue? = nil,
            eightMax: SpaceTokenValue? = nil
        ) {
            self.fourMin = fourMin
            self.fourMax = fourMax
            self.eightMin = eightMin
            self.eightMax = eightMax
        }
    }

    struct CmsSection: Decodable {
        public let largeMax: SpaceTokenValue?
        public let smallMax: SpaceTokenValue?
        public let side: TokenReference?
        public let gap: TokenReference?
        public let top: TokenReference?
        public let bottom: TokenReference?

        public enum CodingKeys: String, CodingKey {
            case largeMax = "large-max"
            case smallMax = "small-max"
            case side, gap, top, bottom
        }

        public init(
            largeMax: SpaceTokenValue? = nil,
            smallMax: SpaceTokenValue? = nil,
            side: TokenReference? = nil,
            gap: TokenReference? = nil,
            top: TokenReference? = nil,
            bottom: TokenReference? = nil
        ) {
            self.largeMax = largeMax
            self.smallMax = smallMax
            self.side = side
            self.gap = gap
            self.top = top
            self.bottom = bottom
        }
    }
}

// MARK: - Decoding Helper
public extension SpaceTokens {
    static func decode(from jsonData: Data) throws -> SpaceTokens {
        let decoder = JSONDecoder()
        return try decoder.decode(SpaceTokens.self, from: jsonData)
    }
}
