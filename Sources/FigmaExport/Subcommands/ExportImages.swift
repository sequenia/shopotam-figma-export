import Foundation
import ArgumentParser
import FigmaAPI
import XcodeExport
import FigmaExportCore
import AndroidExport
import Logging

extension FigmaExportCommand {

    struct ExportImages: ParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "images",
            abstract: "Exports images from Figma",
            discussion: "Exports images from Figma to Xcode / Android Studio project")

        @Option(name: .shortAndLong,
                help: "An input YAML file with figma and platform properties.")
        var input: String
        
        @Argument(help: """
        [Optional] Name of the images to export. For example \"img/login\" to export \
        single image, \"img/onboarding/1, img/onboarding/2\" to export several images \
        and \"img/onboarding/*\" to export all images from onboarding group
        """)
        var filter: String?

        @Option(name: .shortAndLong, help: "Target progect name")
        var project: String
        
        func run() throws {
            let logger = Logger(label: "com.redmadrobot.figma-export")

            let reader = ParamsReader(inputPath: input.isEmpty ? "figma-export.yaml" : input)
            let params = try reader.read()

             guard let accessToken = ProcessInfo.processInfo.environment["FIGMA_PERSONAL_TOKEN"] else {
                throw FigmaExportError.accessTokenNotFound
            }
            
            let client = FigmaClient(accessToken: accessToken)

            if let _ = params.ios {
                logger.info("Using FigmaExport to export images to Xcode project.")
                try exportiOSImages(client: client, params: params, logger: logger)
            }

            if let _ = params.android {
                logger.info("Using FigmaExport to export images to Android Studio project.")
                try exportAndroidImages(client: client, params: params, logger: logger)
            }
        }

        private func exportiOSImages(client: FigmaClient, params: Params, logger: Logger) throws {
            guard let ios = params.ios else {
                logger.info("Nothing to do. You haven’t specified ios parameter in the config file.")
                return
            }

            logger.info("Fetching images info from Figma. Please wait...")
            let loader = ImagesLoader(figmaClient: client, params: params, project: project, platform: .ios)
            let imagesTuple = try loader.loadImages(filter: filter)

            logger.info("Processing images...")
            let processor = ImagesProcessor(
                platform: .ios,
                nameValidateRegexp: params.common?.images?.nameValidateRegexp,
                nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
                ignoreBadNames: false,
                nameStyle: params.ios?.images.nameStyle
            )
            let images = try processor.process(
                light: imagesTuple.light,
                dark: imagesTuple.dark
            ).get()

            let assetsURL = ios.xcassetsPathImages.appendingPathComponent(ios.images.assetsFolder)
            
            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                uiKitImageExtensionURL: ios.images.imageSwift,
                swiftUIImageExtensionURL: ios.images.swiftUIImageSwift)
            
            let exporter = XcodeImagesExporter(output: output)
            let localAndRemoteFiles = try exporter.export(assets: images, append: filter != nil)
            let appIconExport = try exporter.export(appIcon: imagesTuple.appIcon!, append: true)

            if filter == nil {
                try? FileManager.default.removeItem(atPath: assetsURL.path)
            }
            logger.info("Downloading remote files...")
            let localFiles = try fileDownloader.fetch(files: localAndRemoteFiles)
            let localAppIconFile = try fileDownloader.fetch(files: appIconExport)

            logger.info("Writting files to Xcode project...")
            try fileWritter.write(files: localFiles)
            try fileWritter.write(files: localAppIconFile)

            do {
                let xcodeProject = try XcodeProjectWritter(
                    xcodeProjPath: ios.xcodeprojPath,
                    xcodeprojMainGroupName: ios.xcodeprojMainGroupName,
                    target: ios.target)
                try localFiles.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                logger.error("Unable to add some file references to Xcode project")
            }
            
            logger.info("Done!")
        }
        
        private func exportAndroidImages(client: FigmaClient, params: Params, logger: Logger) throws {
            guard let androidImages = params.android?.images else {
                logger.info("Nothing to do. You haven’t specified android.images parameter in the config file.")
                return
            }

            logger.info("Fetching images info from Figma. Please wait...")
            let loader = ImagesLoader(figmaClient: client, params: params, project: project, platform: .android)
            let imagesTuple = try loader.loadImages(filter: filter)

            logger.info("Processing images...")
            let processor = ImagesProcessor(
                platform: .android,
                nameValidateRegexp: params.common?.images?.nameValidateRegexp,
                nameReplaceRegexp: params.common?.images?.nameReplaceRegexp,
                ignoreBadNames: false,
                nameStyle: .snakeCase
            )
            let images = try processor.process(light: imagesTuple.light, dark: imagesTuple.dark).get()
            
            switch androidImages.format {
            case .svg:
                try exportAndroidSVGImages(images: images, params: params, logger: logger)
            case .png, .webp:
                try exportAndroidRasterImages(images: images, params: params, logger: logger)
            }
            
            logger.info("Done!")
        }
        
        private func exportAndroidSVGImages(images: [AssetPair<ImagesProcessor.AssetType>], params: Params, logger: Logger) throws {
            guard let android = params.android, let androidImages = android.images else {
                logger.info("Nothing to do. You haven’t specified android.images parameter in the config file.")
                return
            }

            // Create empty temp directory
            let tempDirectoryLightURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let tempDirectoryDarkURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // Download SVG files to user's temp directory
            logger.info("Downloading remote files...")
            let remoteFiles = images.flatMap { asset -> [FileContents] in
                let image = asset.light
                let fileURL = URL(string: "\(image.name).svg")!
                let dest = Destination(directory: tempDirectoryLightURL, file: fileURL)
                var result = [FileContents(destination: dest, sourceURL: image.single.url)]

                if let dark = asset.dark {
                    let fileURL = URL(string: "\(dark.name).svg")!
                    let dest = Destination(directory: tempDirectoryDarkURL, file: fileURL)
                    var file = FileContents(destination: dest, sourceURL: dark.single.url)
                    file.dark = true
                    result.append(file)
                }
                return result
            }
            var localFiles = try fileDownloader.fetch(files: remoteFiles)
            
            // Move downloaded SVG files to new empty temp directory
            try fileWritter.write(files: localFiles)
            
            // Convert all SVG to XML files
            logger.info("Converting SVGs to XMLs...")
            try svgFileConverter.convert(inputDirectoryPath: tempDirectoryLightURL.path)
            if images.first?.dark != nil {
                logger.info("Converting dark SVGs to XMLs...")
                try svgFileConverter.convert(inputDirectoryPath: tempDirectoryDarkURL.path)
            }

            logger.info("Writting files to Android Studio project...")
            
            // Create output directory main/res/drawable/
            
            let lightDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidImages.output)
                .appendingPathComponent("drawable", isDirectory: true).path)
            
            let darkDirectory = URL(fileURLWithPath: android.mainRes
                .appendingPathComponent(androidImages.output)
                .appendingPathComponent("drawable-night", isDirectory: true).path)
            
            if filter == nil {
                // Clear output directory
//                try? FileManager.default.removeItem(atPath: lightDirectory.path)
//                try? FileManager.default.removeItem(atPath: darkDirectory.path)
            }
            
            // Move XML files to main/res/drawable/
            localFiles = localFiles.map { fileContents -> FileContents in
                
                let source = fileContents.destination.url
                    .deletingPathExtension()
                    .appendingPathExtension("xml")
                
                let fileURL = fileContents.destination.file
                    .deletingPathExtension()
                    .appendingPathExtension("xml")
                
                let directory = fileContents.dark ? darkDirectory : lightDirectory
                
                return FileContents(
                    destination: Destination(directory: directory, file: fileURL),
                    dataFile: source
                )
            }
            try fileWritter.write(files: localFiles)
            
            try FileManager.default.removeItem(at: tempDirectoryLightURL)
            try FileManager.default.removeItem(at: tempDirectoryDarkURL)
        }
        
        private func exportAndroidRasterImages(images: [AssetPair<ImagesProcessor.AssetType>], params: Params, logger: Logger) throws {
            guard let android = params.android, let androidImages = android.images else {
                logger.info("Nothing to do. You haven’t specified android.images parameter in the config file.")
                return
            }

            // Create empty temp directory
            let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            
            // Download files to user's temp directory
            logger.info("Downloading remote files...")
            let remoteFiles = images.flatMap { asset -> [FileContents] in
                var result = [FileContents]()
                if case ImagePack.individualScales(let images) = asset.light {
                    result.append(contentsOf: makeRemoteFiles(images: images, dark: false, outputDirectory: tempDirectoryURL))
                }
                if let darkImages = asset.dark, case ImagePack.individualScales(let images) = darkImages {
                    result.append(contentsOf: makeRemoteFiles(images: images, dark: true, outputDirectory: tempDirectoryURL))
                }
                return result
            }
            var localFiles = try fileDownloader.fetch(files: remoteFiles)

            // Move downloaded files to new empty temp directory
            try fileWritter.write(files: localFiles)
            
            // Convert to WebP
            if androidImages.format == .webp, let options = androidImages.webpOptions {
                logger.info("Converting PNG files to WebP...")
                let converter: WebpConverter
                switch (options.encoding, options.quality) {
                case (.lossless, _):
                    converter = WebpConverter(encoding: .lossless)
                case (.lossy, let quality?):
                    converter = WebpConverter(encoding: .lossy(quality: quality))
                case (.lossy, .none):
                    fatalError("Encoding quality not specified. Set android.images.webpOptions.quality in YAML file.")
                }
                localFiles = try localFiles.map { file in
                    try converter.convert(file: file.destination.url)
                    return file.changingExtension(newExtension: "webp")
                }
            }
            
            if filter == nil {
                // Clear output directory
//                let outputDirectory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(androidImages.output).path)
//                try? FileManager.default.removeItem(atPath: outputDirectory.path)
            }

            logger.info("Writting files to Android Studio project...")
            
            // Move PNG/WebP files to main/res/figma-export-images/drawable-XXXdpi/
            localFiles = localFiles.map { fileContents -> FileContents in
                let directoryName = Drawable.scaleToDrawableName(fileContents.scale, dark: fileContents.dark)
                let directory = URL(fileURLWithPath: android.mainRes.appendingPathComponent(androidImages.output).path)
                    .appendingPathComponent(directoryName, isDirectory: true)
                return FileContents(
                    destination: Destination(directory: directory, file: fileContents.destination.file),
                    dataFile: fileContents.destination.url
                )
            }
            try fileWritter.write(files: localFiles)
            
            try FileManager.default.removeItem(at: tempDirectoryURL)
        }
        
        /// Make array of remote FileContents for downloading images
        /// - Parameters:
        ///   - images: Dictionary of images. Key = scale, value = image info
        ///   - dark: Dark mode?
        ///   - outputDirectory: URL of the output directory
        private func makeRemoteFiles(images: [Double: Image], dark: Bool, outputDirectory: URL) -> [FileContents] {
            var result: [FileContents] = []
            for scale in images.keys {
                guard let image = images[scale] else { continue }
                let fileURL = URL(string: "\(image.name).\(image.format)")!
                let dest = Destination(
                    directory: outputDirectory
                        .appendingPathComponent(dark ? "dark" : "light")
                        .appendingPathComponent(String(scale))
                    , file: fileURL)
                var file = FileContents(destination: dest, sourceURL: image.url)
                file.scale = scale
                file.dark = dark
                result.append(file)
            }
            return result
        }
    }
}
