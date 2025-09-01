import ArgumentParser
import Foundation
import FigmaAPI
import XcodeExport
import AndroidExport
import FigmaExportCore
import Logging
import Utils

extension FigmaExportCommand {

    struct ExportDesignTokens: ParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "getTypography",
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

            let typographyURL = params.figma.projects?.first(where: { $0.name == project })?.typographyURL ?? ""

            guard let content = try? Data(contentsOf: URL(string: typographyURL)!)
            else {
                return
            }

            let decoder = JSONDecoder()
            let designTokens = try decoder.decode(DesignTokens.self, from: content)

            let textStylesBody = self.convertToTextStyle(
                fontName: "SFProDisplay",
                name: "body",
                designTokens: designTokens,
                typographyStyle: designTokens.typographyMobile.body
            )

            let textStylesTitle = self.convertToTextStyle(
                fontName: "SFProDisplay",
                name: "title",
                designTokens: designTokens,
                typographyStyle: designTokens.typographyMobile.title
            )

            let textStylesHeading = self.convertToTextStyle(
                fontName: "SFProDisplay",
                name: "heading",
                designTokens: designTokens,
                typographyStyle: designTokens.typographyMobile.heading
            )

            let textStylesDisplay = self.convertToTextStyle(
                fontName: "SFProDisplay",
                name: "display",
                designTokens: designTokens,
                typographyStyle: designTokens.typographyMobile.display
            )

            var textStylesControl = [TextStyle]()
            designTokens.controlValue.control.keys.forEach { controllKey in
                designTokens.fontWeights.forEach { keyWidth in
                    let fontWidth = keyWidth.value.fontWeight.value.getDoubleValue()
                    let fontName = "SFProDisplay" + (FontWidthType(rawValue: fontWidth ?? .zero)?.getType() ?? "")
                    let fontSize = designTokens.controlValue.fontSize[controllKey]?.value.getDoubleValue()
                    let lineHeight = designTokens.controlValue.lineHeight[controllKey]?.value.getDoubleValue()
                    let letterSpacing = designTokens.controlValue.letterSpacing[controllKey]?.value.getDoubleValue()

                    textStylesControl.append(
                        TextStyle(
                            name: "control\(keyWidth.key.upperCamelCased())\(controllKey.upperCamelCased())",
                            fontName: fontName,
                            fontSize: fontSize ?? .zero,
                            lineHeight: lineHeight ?? .zero,
                            letterSpacing: letterSpacing ?? .zero,
                            width: keyWidth.value.fontWeight.value.getDoubleValue()
                        )
                    )
                }
            }

            if let ios = params.ios {
                var textStyles = [TextStyle]()
                textStyles.append(contentsOf: textStylesBody)
                textStyles.append(contentsOf: textStylesTitle)
                textStyles.append(contentsOf: textStylesHeading)
                textStyles.append(contentsOf: textStylesDisplay)
                textStyles.append(contentsOf: textStylesControl)

                logger.info("Saving text styles...")
                try exportXcodeTextStyles(textStyles: textStyles, iosParams: ios, logger: logger)
                logger.info("Done!")
            }

            if let android = params.android {
                logger.info("Saving text styles...")
                try self.exportAndroidTextStyles(
                    textStyles: [
                        "body": textStylesBody,
                        "title": textStylesTitle,
                        "heading": textStylesHeading,
                        "display": textStylesDisplay,
                        "control": textStylesControl
                    ],
                    androidParams: android
                )
                logger.info("Done!")
            }
        }

        func convertToTextStyle(
            fontName: String,
            name: String,
            designTokens: DesignTokens,
            typographyStyle: TypographyStyle
        ) -> [TextStyle] {
            var textStyles = [TextStyle]()

            typographyStyle.fontSize?.keys.forEach { keyFontSize in
                designTokens.fontWeights.forEach { keyWidth in
                    let fontWidth = keyWidth.value.fontWeight.value.getDoubleValue()
                    let fontName = fontName + (FontWidthType(rawValue: fontWidth ?? .zero)?.getType() ?? "")

                    let fontSize = typographyStyle.fontSize?[keyFontSize]?.value.getDoubleValue()
                    let lineHeight = typographyStyle.lineHeight?[keyFontSize]?.value.getDoubleValue()
                    let letterSpacing = typographyStyle.letterSpacing?[keyFontSize]?.value.getDoubleValue()

                    textStyles.append(
                        TextStyle(
                            name: "\(name)\(keyFontSize.upperCamelCased())\(keyWidth.key.upperCamelCased())",
                            fontName: fontName,
                            fontSize: fontSize ?? .zero,
                            lineHeight: lineHeight ?? .zero,
                            letterSpacing: letterSpacing ?? .zero,
                            width: keyWidth.value.fontWeight.value.getDoubleValue()
                        )
                    )
                }
            }

            return textStyles
        }

        private func exportXcodeTextStyles(textStyles: [TextStyle], iosParams: Params.iOS, logger: Logger) throws {
            let exporter = XcodeTypographyExporter()

            var files: [FileContents] = []

            // Styles
            if let stylesDirectoryURL = iosParams.typography.stylesDirectory {
                files.append(
                    contentsOf: try exporter.exportStyles(
                        textStyles,
                        folderURL: stylesDirectoryURL,
                        version: iosParams.typography.typographyVersion
                    )
                )
            }

            // Components
            if iosParams.typography.generateComponents,
               let directory = iosParams.typography.componentsDirectory  {
                files.append(
                    contentsOf: try exporter.exportComponents(
                        textStyles: textStyles,
                        componentsDirectory: directory,
                        version: iosParams.typography.typographyVersion
                    )
                )
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
            } catch (let error) {
                print(error)
            }
        }

        private func exportAndroidTextStyles(
            textStyles: [String: [TextStyle]],
            androidParams: Params.Android
        ) throws {
            let outputPatch = URL(fileURLWithPath: androidParams.typography?.outputfilePath ?? "")

            let exporter = AndroidTypographyExporter(
                outputDirectory: outputPatch,
                attributes: nil,
                fileName: URL(string: androidParams.typography?.outputFileName ?? "")
            )

            let file = exporter.makeTypographyFile(textStyles)

            try fileWritter.write(file: file)
        }
    }
}
