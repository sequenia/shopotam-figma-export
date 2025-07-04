import Foundation
import FigmaExportCore

final public class XcodeIconsExporter: XcodeImagesExporterBase {

    public func export(assets: [AssetPair<ImagePack>], append: Bool) throws -> [FileContents] {
        var files: [FileContents] = []
        
        // Assets.xcassets/Icons/Contents.json
        let contentsJson = XcodeEmptyContents()
        files.append(FileContents(
            destination: Destination(directory: output.assetsFolderURL, file: contentsJson.fileURL),
            data: contentsJson.data
        ))
        
        try assets.forEach { pair in
            let name = pair.light.name

            // Create directory for imageset
            let dirURL = output.assetsFolderURL.appendingPathComponent("\(name).imageset")
            
            files.append(contentsOf: self.saveImagePair(pair, to: dirURL))
            
            let preservesVector = output.preservesVectorRepresentationIcons?.first(where: { $0 == name }) != nil ||
                output.preservesVectorRepresentation

//            var renderingIntent = output.renderIntent?.rawValue
//            if output.renderAsOriginalIcons?.first(where: { $0 == name }) != nil {
//                renderingIntent = RenderIntent.original.rawValue
//            } else if output.renderAsTemplateIcons?.first(where: { $0 == name }) != nil {
//
//            }
            let renderingIntent = RenderIntent.template.rawValue
            // Assets.xcassets/Icons/***.imageset/Contents.json
            let contents = XcodeAssetContents(
                icons: imageDataFromPair(pair),
                preservesVectorRepresentation: preservesVector,
                templateRenderingIntent: renderingIntent
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(contents)
            let fileURL = URL(string: "Contents.json")!
            files.append(FileContents(
                destination: Destination(directory: dirURL, file: fileURL),
                data: data
            ))
        }
        
        let imageNames = assets.map { $0.light.name }
        
        let extensionFiles = try generateExtensions(names: imageNames, append: append)
        files.append(contentsOf: extensionFiles)
        
        return files
    }

    private func makeEmptyContentsJson() -> FileContents {
        let contentsJson = XcodeEmptyContents()
        let destination = Destination(directory: output.assetsFolderURL, file: contentsJson.fileURL)

        return FileContents(
            destination: destination,
            data: contentsJson.data
        )
    }


    private func makeFileURL(for image: Image, scale: Double?, dark: Bool = false) -> URL {
        var urlString = image.name
        if dark {
            urlString.append("D")
        } else {
            urlString.append("L")
        }
        if let scale = scale, let scaleString = normalizeScale(scale) {
            urlString.append("@\(scaleString)x")
        }

        return URL(string: urlString)!.appendingPathExtension(image.format)
    }

    /// Extract all the images from AssetPair to specific directory
    private func saveImagePair(_ pair: AssetPair<ImagePack>, to directory: URL) -> [FileContents] {
        if let dark = pair.dark {
            return
                saveImagePack(pack: pair.light, to: directory) +
                saveImagePack(pack: dark, to: directory, dark: true)
        } else {
            return saveImagePack(pack: pair.light, to: directory)
        }
    }

    private func saveImagePack(pack: ImagePack, to directory: URL, dark: Bool = false) -> [FileContents] {
        switch pack {
        case .singleScale(let image):
            return [saveImage(image, to: directory, dark: dark)]
        case .individualScales(let images):
            return images.map { scale, image -> FileContents in
                saveImage(image, to: directory, scale: scale, dark: dark)
            }
        }
    }

    private func saveImage(_ image: Image, to directory: URL, scale: Double? = nil, dark: Bool) -> FileContents {
        let imageURL = makeFileURL(for: image, scale: scale, dark: dark)
        let destination = Destination(directory: directory, file: imageURL)

        if let content = image.content {
            return FileContents(
                destination: destination,
                data: content
            )
        }

        return FileContents(
            destination: destination,
            sourceURL: image.url
        )
    }

    // Link all the images with Contents.json
    private func imageDataFromPair(_ pair: AssetPair<ImagePack>) -> [XcodeAssetContents.ImageData] {
        if let dark = pair.dark {
            return
                imageDataFromPack(pair.light) +
                imageDataFromPack(dark, dark: true)

        } else {
            return imageDataFromPack(pair.light)
        }
    }

    private func imageDataFromPack(_ pack: ImagePack, dark: Bool = false) -> [XcodeAssetContents.ImageData] {
        switch pack {
        case .singleScale(let image):
            return [imageDataForImage(image, dark: dark)]
        case .individualScales(let images):
            return images.map { scale, image -> XcodeAssetContents.ImageData in
                imageDataForImage(image, scale: scale, dark: dark)
            }
        }
    }

    private func imageDataForImage(_ image: Image, scale: Double? = nil, dark: Bool) -> XcodeAssetContents.ImageData {

        var appearance: [XcodeAssetContents.DarkAppeareance]?
        if dark {
            appearance = [XcodeAssetContents.DarkAppeareance()]
        }

        let imageURL = makeFileURL(for: image, scale: scale, dark: dark)

        var scaleString: String?
        if let scale = scale, let normalizedScale = normalizeScale(scale) {
            scaleString = normalizedScale
        }

        return XcodeAssetContents.ImageData(
            scale: scaleString == nil ? nil : "\(scaleString!)x",
            appearances: appearance,
            filename: imageURL.absoluteString
        )
    }

    /// Trims trailing zeros from scale value 1.0 → 1, 1.5 → 1.5, 3.0 → 3
    private func normalizeScale(_ scale: Double) -> String? {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: scale))
    }
}
