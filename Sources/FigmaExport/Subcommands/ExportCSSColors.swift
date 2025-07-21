//
//  File.swift
//  shopotam-figma-export
//
//  Created by Ivan Mikhailovskii on 03.06.2025.
//

import Foundation
import ArgumentParser
import XcodeExport
import AndroidExport
import FigmaExportCore
import Logging
import Utils

extension FigmaExportCommand {

    struct ExportCSSColors: ParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "getColors",
            abstract: "Exports CSSColors",
            discussion: "Exports light and dark color palette from Figma to Xcode / Android Studio project"
        )

        @Option(name: .shortAndLong, help: "An input YAML file with figma and platform properties.")
        var input: String

        @Option(name: .shortAndLong, help: "Target progect name")
        var project: String

        func run() throws {
            let logger = Logger(label: "\(project)")

            let reader = ParamsReader(inputPath: input.isEmpty ? "figma-export.yaml" : input)
            let params = try reader.read()

            let colorURL = params.figma.projects?.first(where: { $0.name == project })?.colorURL ?? ""

            var data = try? Data(contentsOf: URL(fileURLWithPath: colorURL))

            if let url = URL(string: colorURL) {
                data = data == nil ? try? Data(contentsOf: url) : data
            }

            guard let dataCss = data,
                  let css = String(data: dataCss, encoding: .utf8)
            else { return }

            if #available(macOS 13.0, *) {
                let parser = CSSColorParser(css: css)

                if let ios = params.ios {
                    logger.info("Processing colors...")
                    let processor = ColorsProcessor(
                        platform: .ios,
                        nameValidateRegexp: params.common?.colors?.nameValidateRegexp,
                        nameReplaceRegexp: params.common?.colors?.nameReplaceRegexp,
                        ignoreBadNames: false,
                        nameStyle: params.ios?.colors.nameStyle
                    )

                    let colorPairs = try processor.process(
                        light: parser.colorsLight,
                        dark: parser.colorsDark
                    ).get()

                    logger.info("Exporting colors to Android Studio project...")
                    try exportXcodeColors(
                        colorPairs: colorPairs,
                        iosParams: ios,
                        logger: logger
                    )

                    logger.info("Done!")
                }

                if let android = params.android {
                    logger.info("Processing colors...")
                    let processor = ColorsProcessor(
                        platform: .android,
                        nameValidateRegexp: params.common?.colors?.nameValidateRegexp,
                        nameReplaceRegexp: params.common?.colors?.nameReplaceRegexp,
                        ignoreBadNames: false,
                        nameStyle: .snakeCase
                    )

                    let colorPairs = try processor.process(
                        light: parser.colorsLight,
                        dark: parser.colorsDark
                    ).get()

                    logger.info("Exporting colors to Android Studio project...")
                    try exportAndroidColors(colorPairs: colorPairs, androidParams: android)

                    logger.info("Done!")
                }
            }
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
            let outputPatch = URL(fileURLWithPath: androidParams.colors?.outputfilePath ?? "")

            let exporter = AndroidColorExporter(
                outputDirectory: outputPatch,
                fileName: URL(string: androidParams.colors?.outputFileName ?? "")
            )
            let file = exporter.exportCompose(colorPairs: colorPairs)

            try fileWritter.write(file: file)
        }
    }
}
