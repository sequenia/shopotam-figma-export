import ArgumentParser
import Foundation
import FigmaAPI
import XcodeExport
import AndroidExport
import FigmaExportCore
import Logging

extension FigmaExportCommand {
    
    struct ExportColors: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            commandName: "colors",
            abstract: "Exports colors from Figma",
            discussion: "Exports light and dark color palette from Figma to Xcode / Android Studio project")
        
        @Option(name: .shortAndLong, help: "An input YAML file with figma and platform properties.")
        var input: String

        @Option(name: .shortAndLong, help: "Target progect name")
        var project: String
        
        func run() throws {
//            let logger = Logger(label: "com.redmadrobot.figma-export")
//            
//            let reader = ParamsReader(inputPath: input.isEmpty ? "figma-export.yaml" : input)
//            let params = try reader.read()
//
//            guard let accessToken = ProcessInfo.processInfo.environment["FIGMA_PERSONAL_TOKEN"] else {
//                throw FigmaExportError.accessTokenNotFound
//            }
//
//            let client = FigmaClient(accessToken: accessToken)
//
//            logger.info("Using FigmaExport to export colors.")
//
//            logger.info("Fetching colors. Please wait...")
//            let loader = ColorsLoader(figmaClient: client, params: params.figma, project: project)
//            let colors = try loader.load()
//
//            if let ios = params.ios {
//                logger.info("Processing colors...")
//                let processor = ColorsProcessor(
//                    platform: .ios,
//                    nameValidateRegexp: params.common?.colors?.nameValidateRegexp,
//                    nameReplaceRegexp: params.common?.colors?.nameReplaceRegexp,
//                    ignoreBadNames: false,
//                    nameStyle: params.ios?.colors.nameStyle
//                )
//
//                let colorPairs = try processor.process(
//                    baseProject: colors.targetProjectColors ?? colors.baseProjectColors,
//                    targetProject: colors.targetProjectColors
//                ).get()
//
//                logger.info("Exporting colors to Xcode project...")
//                try exportXcodeColors(colorPairs: colorPairs, iosParams: ios, logger: logger)
//
//                logger.info("Done!")
//            }
//            
//            if let android = params.android {
//                logger.info("Processing colors...")
//                let processor = ColorsProcessor(
//                    platform: .android,
//                    nameValidateRegexp: params.common?.colors?.nameValidateRegexp,
//                    nameReplaceRegexp: params.common?.colors?.nameReplaceRegexp,
//                    nameStyle: .snakeCase
//                )
//                let colorPairs = try processor.process(
//                    baseProject: colors.baseProjectColors,
//                    targetProject: colors.targetProjectColors
//                ).get()
//
//                logger.info("Exporting colors to Android Studio project...")
//                try exportAndroidColors(colorPairs: colorPairs, androidParams: android)
//
//                logger.info("Done!")
//            }
        }
        
        private func exportXcodeColors(colorPairs: [AssetPair<Color>], iosParams: Params.iOS, logger: Logger) throws {
            var colorsURL: URL?
            if iosParams.colors.useColorAssets {
                if let folder = iosParams.colors.assetsFolder {
                    colorsURL = iosParams.xcassetsPathColors.appendingPathComponent(folder)
                } else {
                    throw FigmaExportError.colorsAssetsFolderNotSpecified
                }
            }
            
            let output = XcodeColorsOutput(
                assetsColorsURL: colorsURL,
                assetsInMainBundle: iosParams.xcassetsInMainBundle,
                colorSwiftURL: iosParams.colors.colorSwift,
                swiftuiColorSwiftURL: iosParams.colors.swiftuiColorSwift)

            let exporter = XcodeColorExporter(output: output)
            let files = exporter.export(colorPairs: colorPairs)
            
            if iosParams.colors.useColorAssets, let url = colorsURL {
                try? FileManager.default.removeItem(atPath: url.path)
            }
            
            try fileWritter.write(files: files)
            
            do {
                let xcodeProject = try XcodeProjectWritter(
                    xcodeProjPath: iosParams.xcodeprojPath,
                    xcodeprojMainGroupName: iosParams.xcodeprojMainGroupName,
                    target: iosParams.target
                )
                try files.forEach { file in
                    if file.destination.file.pathExtension == "swift" {
                        try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                    }
                }
                try xcodeProject.save()
            } catch {
                logger.error("Unable to add some file references to Xcode project")
            }
        }

        private func exportAndroidColors(colorPairs: [AssetPair<Color>], androidParams: Params.Android) throws {
            let outputPatch = URL(fileURLWithPath: androidParams.mainRes
                .appendingPathComponent(androidParams.colors?.output ?? "").path)

            let exporter = AndroidColorExporter(outputDirectory: outputPatch)
            let files = exporter.export(colorPairs: colorPairs)
            
            let lightColorsFileURL = androidParams.mainRes.appendingPathComponent("values/colors.xml")
            let darkColorsFileURL = androidParams.mainRes.appendingPathComponent("values-night/colors.xml")
            
            try fileWritter.write(files: files)
        }
    }
}
