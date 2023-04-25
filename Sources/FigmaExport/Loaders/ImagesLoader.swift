import Foundation
import FigmaAPI
import FigmaExportCore

final class ImagesLoader {

    let figmaClient: FigmaClient
    let params: Params
    let platform: Platform
    let project: String?

    private var iconsFrameName: String {
        params.common?.icons?.figmaFrameName ?? "Icons"
    }
    
    private var imagesFrameName: String {
        params.common?.images?.figmaFrameName ?? "Illustrations"
    }
    
    init(figmaClient: FigmaClient, params: Params, project: String?, platform: Platform) {
        self.figmaClient = figmaClient
        self.params = params
        self.platform = platform
        self.project = project
    }

    func loadIcons(
        filter: String? = nil
    ) throws -> (baseProjectImages: [ImagePack], targetProjectImages: [ImagePack]?) {

        guard let baseFileIconId = params.figma.base.fileIconId else { fatalError("Specify the fileIconId") }
        let targetProjectIds = params.figma.projects?.first(where: { $0.name == self.project })

        switch (platform, params.ios?.icons.format) {
        case (.android, _),
             (.ios, .svg):

            let baseProjectImages = try _loadImages(
                fileId: baseFileIconId,
                frameName: iconsFrameName,
                params: SVGParams(),
                filter: filter
            )

            let targetProjectImages = try targetProjectIds.map {
                guard let fileIconId = $0.fileIconId else { fatalError("Specify the fileIconId for target project") }

                return try _loadImages(
                    fileId: fileIconId,
                    frameName: iconsFrameName,
                    params: SVGParams(),
                    filter: filter
               )
            }

            return (
                baseProjectImages.map { ImagePack.singleScale($0) },
                targetProjectImages?.map { ImagePack.singleScale($0) }
            )

        case (.ios, _):
            let baseProjectImages = try _loadImages(
                fileId: baseFileIconId,
                frameName: iconsFrameName,
                params: PDFParams(),
                filter: filter
            )

            let targetProjectImages = try targetProjectIds.map {
                guard let fileIconId = $0.fileIconId else { fatalError("Specify the fileIconId for target project") }

                return try _loadImages(
                    fileId: fileIconId,
                    frameName: iconsFrameName,
                    params: PDFParams(),
                    filter: filter
               )
            }

            return (
                baseProjectImages.map { ImagePack.singleScale($0) },
                targetProjectImages?.map { ImagePack.singleScale($0) }
            )
        }
    }

    func loadImages(filter: String? = nil) throws -> (light: [ImagePack], dark: [ImagePack]?) {
        switch (platform, params.android?.images?.format) {
        case (.android, .png), (.android, .webp), (.ios, .none):
            let lightImages = try loadPNGImages(
                fileId: params.figma.lightFileId,
                frameName: imagesFrameName,
                filter: filter,
                platform: platform)
            let darkImages = try params.figma.darkFileId.map {
                try loadPNGImages(
                    fileId: $0,
                    frameName: imagesFrameName,
                    filter: filter,
                    platform: platform)
            }
            return (
                lightImages,
                darkImages
            )
        default:
            let light = try _loadImages(
                fileId: params.figma.lightFileId,
                frameName: imagesFrameName,
                params: SVGParams(),
                filter: filter)
            
            let dark = try params.figma.darkFileId.map {
                try _loadImages(
                    fileId: $0,
                    frameName: imagesFrameName,
                    params: SVGParams(),
                    filter: filter)
            }
            return (
                light.map { ImagePack.singleScale($0) },
                dark?.map { ImagePack.singleScale($0) }
            )
        }
    }

    // MARK: - Helpers

    private func fetchImageComponents(fileId: String, frameName: String, filter: String? = nil) throws -> [NodeId: Component] {
        var components = try loadComponents(fileId: fileId)
            .filter {
                $0.containingFrame.pageName.contains(frameName) &&
                    ($0.description == platform.rawValue || $0.description == nil || $0.description == "") &&
                    $0.description?.contains("none") == false
            }
        
        if let filter = filter {
            let assetsFilter = AssetsFilter(filter: filter)
            components = components.filter { component -> Bool in
                assetsFilter.match(name: component.name)
            }
        }
        
        return Dictionary(uniqueKeysWithValues: components.map { ($0.nodeId, $0) })
    }

    private func _loadImages(fileId: String, frameName: String, params: FormatParams, filter: String? = nil) throws -> [Image] {
        let imagesDict = try fetchImageComponents(fileId: fileId, frameName: frameName, filter: filter)
        
        guard !imagesDict.isEmpty else {
            throw FigmaExportError.componentsNotFound
        }
        
        let imagesIds: [NodeId] = imagesDict.keys.map { $0 }
        let imageIdToImagePath = try loadImages(fileId: fileId, nodeIds: imagesIds, params: params)
        
        return imageIdToImagePath.map { (imageId, imagePath) -> Image in
            var name = imagesDict[imageId]!.name
            if let stateGroupName = imagesDict[imageId]!.containingFrame.containingStateGroup?.name {
                name = "\(stateGroupName) \(name)"
            }
            name = name.components(separatedBy: .init(charactersIn: "-_=")).joined(separator: " ")
            return Image(
                name: name,
                url: URL(string: imagePath)!,
                format: params.format
            )
        }
    }

    private func loadPNGImages(fileId: String, frameName: String, filter: String? = nil, platform: Platform) throws -> [ImagePack] {
        let imagesDict = try fetchImageComponents(fileId: fileId, frameName: frameName, filter: filter)
        
        guard !imagesDict.isEmpty else {
            throw FigmaExportError.componentsNotFound
        }
        
        let imagesIds: [NodeId] = imagesDict.keys.map { $0 }

        var images: [Double: [NodeId: ImagePath]] = [:]
        images[1.0] = try loadImages(fileId: fileId, nodeIds: imagesIds, params: PNGParams(scale: 1.0))
        images[2.0] = try loadImages(fileId: fileId, nodeIds: imagesIds, params: PNGParams(scale: 2.0))
        images[3.0] = try loadImages(fileId: fileId, nodeIds: imagesIds, params: PNGParams(scale: 3.0))
        if platform == .android {
            images[1.5] = try loadImages(fileId: fileId, nodeIds: imagesIds, params: PNGParams(scale: 1.5))
            images[4.0] = try loadImages(fileId: fileId, nodeIds: imagesIds, params: PNGParams(scale: 4.0))
        }
        return imagesIds.map { imageId -> ImagePack in
            let name = imagesDict[imageId]!.name

            var scaledImages: [Double: Image] = [:]
                
            images.forEach { scale, idToPath in
                let url = URL(string: idToPath[imageId]!)!
                let image = Image(name: name, url: url, format: "png")
                scaledImages[scale] = image
            }
            return ImagePack.individualScales(scaledImages)
        }
    }

    // MARK: - Figma

    private func loadComponents(fileId: String) throws -> [Component] {
        let endpoint = ComponentsEndpoint(fileId: fileId)
        return try figmaClient.request(endpoint)
    }

    private func loadImages(fileId: String, nodeIds: [NodeId], params: FormatParams) throws -> [NodeId: ImagePath] {
        let endpoint = ImageEndpoint(fileId: fileId, nodeIds: nodeIds, params: params)
        return try figmaClient.request(endpoint)
    }
}
