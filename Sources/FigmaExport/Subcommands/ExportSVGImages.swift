import ArgumentParser
import Foundation
import FigmaAPI
import XcodeExport
import AndroidExport
import FigmaExportCore
import Logging
import Utils

extension FigmaExportCommand {

    struct ExportSVGImages: ParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "getSVGImages",
            abstract: "Exports typography from Figma",
            discussion: "Exports font styles from Figma to Xcode")

        @Option(name: .shortAndLong, help: "An input YAML file with figma and platform properties.")
        var input: String

        @Option(name: .shortAndLong, help: "Target progect name")
        var project: String

        func run() throws {
            let logger = Logger(label: "com.redmadrobot.figma-export")
            let reader = ParamsReader(inputPath: input.isEmpty ? "figma-export.yaml" : input)
            let params = try reader.read()

            let iconURL = params.figma.projects?.first(where: { $0.name == project })?.iconURL ?? ""

            guard let content = try? Data(contentsOf: URL(fileURLWithPath: iconURL))
            else { return }

            if let json = self.convertToDictionary(text: content) {
                let imageParser = ImageParser(jsonContent: json)
                let images = imageParser.run()

                if params.ios != nil {
                    try self.exportiOSIcons(
                        params: params,
                        logger: logger,
                        images: images
                    )
                }

                if params.android != nil {
                    logger.info("Using FigmaExport to export icons to Android Studio project.")
                    try exportAndroidIcons(
                        images: images,
                        params: params,
                        logger: logger
                    )
                }
            }
        }

        func convertToDictionary(text: Data?) -> [String: Any]? {
            if let data = text {
                do {
                    let json = try JSONSerialization.jsonObject(
                        with: data, options: []
                    ) as? [String: Any]
                    return json
                } catch {
                    print("Ошибка при преобразовании JSON: \(error.localizedDescription)")
                }
            }
            return nil
        }

        private func exportiOSIcons(
            params: Params,
            logger: Logger,
            images: [ImagePack]
        ) throws {
            guard let ios = params.ios else {
                logger.info("Nothing to do. You haven’t specified ios parameter in the config file.")
                return
            }

            logger.info("Fetching icons info from Figma. Please wait...")

            logger.info("Processing icons...")
            let processor = ImagesProcessor(
                platform: .ios,
                nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
                ignoreBadNames: false,
                nameStyle: params.ios?.icons.nameStyle
            )
            let icons = try processor.process(
                light: images,
                dark: nil
            ).get()

            let assetsURL = ios.xcassetsPathImages.appendingPathComponent(ios.icons.assetsFolder)
            let output = XcodeImagesOutput(
                assetsFolderURL: assetsURL,
                assetsInMainBundle: ios.xcassetsInMainBundle,
                preservesVectorRepresentation: ios.icons.preservesVectorRepresentation,
                preservesVectorRepresentationIcons: ios.icons.preservesVectorRepresentationIcons,
                renderIntent: ios.icons.renderIntent,
                renderAsOriginalIcons: ios.icons.renderAsOriginalIcons,
                renderAsTemplateIcons: ios.icons.renderAsTemplateIcons,
                uiKitImageExtensionURL: ios.icons.imageSwift,
                swiftUIImageExtensionURL: ios.icons.swiftUIImageSwift
            )

            let exporter = XcodeIconsExporter(output: output)
            let localAndRemoteFiles = try exporter.export(assets: icons, append: false)

            let localFiles = try fileDownloader.fetch(files: localAndRemoteFiles)
            try fileWritter.write(files: localFiles)

            do {
                let xcodeProject = try XcodeProjectWritter(
                    xcodeProjPath: ios.xcodeprojPath,
                    xcodeprojMainGroupName: ios.xcodeprojMainGroupName,
                    target: ios.target
                )
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

        private func exportAndroidIcons(
            images: [ImagePack],
            params: Params,
            logger: Logger
        ) throws {
            guard let android = params.android, let androidIcons = android.icons else {
                logger.info("Nothing to do. You haven’t specified android.icons parameter in the config file.")
                return
            }

            // 1. Get Icons info
            logger.info("Fetching icons info from Figma. Please wait...")

            // 2. Proccess images
            logger.info("Processing icons...")
            let processor = ImagesProcessor(
                platform: .android,
                nameValidateRegexp: params.common?.icons?.nameValidateRegexp,
                nameReplaceRegexp: params.common?.icons?.nameReplaceRegexp,
                ignoreBadNames: false,
                nameStyle: .snakeCase
            )

            let icons = try processor.process(
                light: images,
                dark: nil
            ).get()

            // Create empty temp directory
            let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

            // 3. Download SVG files to user's temp directory
            logger.info("Downloading remote files...")
            let remoteFiles = icons.map { asset -> FileContents in
                let image = asset.light
                let fileURL = URL(string: "\(image.name.snakeCased()).svg")!
                let dest = Destination(directory: tempDirectoryURL, file: fileURL)
                return FileContents(destination: dest, data: image.single.content!)
            }
            var localFiles = try fileDownloader.fetch(files: remoteFiles)

            // 4. Move downloaded SVG files to new empty temp directory
            try fileWritter.write(files: localFiles)

            // 5. Convert all SVG to XML files
            logger.info("Converting SVGs to XMLs...")
            try svgFileConverter.convert(inputDirectoryPath: tempDirectoryURL.path)

            // Create output directory main/res/custom-directory/drawable/
            let outputDirectory = URL(fileURLWithPath: android.mainRes
                                        .appendingPathComponent(androidIcons.output)
                                        .appendingPathComponent("drawable", isDirectory: true).path)

            localFiles = localFiles.map { fileContents -> FileContents in

                let source = fileContents.destination.url
                    .deletingPathExtension()
                    .appendingPathExtension("xml")

                let fileURL = fileContents.destination.file
                    .deletingPathExtension()
                    .appendingPathExtension("xml")

                return FileContents(
                    destination: Destination(directory: outputDirectory, file: fileURL),
                    dataFile: source
                )
            }

            logger.info("Writting files to Android Studio project...")
            try fileWritter.write(files: localFiles)

            logger.info("Done!")
        }
    }
}
