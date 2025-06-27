import Foundation

public struct Image: Asset {
    
    public var name: String
    public let format: String
    public let url: URL
    public let content: Data?
    public var platform: Platform?
    
    public init(name: String, platform: Platform? = nil, url: URL, format: String) {
        self.name = name.transformUnicode()
        self.platform = platform
        self.url = url
        self.format = format
        self.content = nil
    }

    public init(name: String, platform: Platform? = nil, content: Data, format: String) {
        self.name = name.transformUnicode()
        self.platform = platform
        self.content = content
        self.format = format
        self.url = URL(string: "/empty")!
    }

    // MARK: Hashable
    
    public static func == (lhs: Image, rhs: Image) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

public enum ImagePack: Asset {

    public typealias Scale = Double
    
    case singleScale(Image)
    case individualScales([Scale: Image])

    public var single: Image {
        switch self {
        case .singleScale(let image):
            return image
        case .individualScales:
            fatalError("Unable to extract image from image pack")
        }
    }

    public var name: String {
        get {
            switch self {
            case .singleScale(let image):
                return image.name
            case .individualScales(let images):
                return images.first!.value.name
            }
        }
        set {
            switch self {
            case .singleScale(var image):
                image.name = newValue
                self = .singleScale(image)
            case .individualScales(var images):
                for key in images.keys {
                    images[key]?.name = newValue
                }
                self = .individualScales(images)
            }
        }
    }

    public var platform: Platform? {
        switch self {
        case .singleScale(let image):
            return image.platform
        case .individualScales(let images):
            return images.first?.value.platform
        }
    }
}
