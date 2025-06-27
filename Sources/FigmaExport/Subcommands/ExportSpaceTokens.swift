import ArgumentParser
import Foundation
import FigmaAPI
import XcodeExport
import AndroidExport
import FigmaExportCore
import Logging
import Utils

extension FigmaExportCommand {

    struct ExportSpaceTokens: ParsableCommand {

        static let configuration = CommandConfiguration(
            commandName: "getSpaceTokens",
            abstract: "Exports typography from Figma",
            discussion: "Exports font styles from Figma to Xcode"
        )

        @Option(name: .shortAndLong, help: "An input YAML file with figma and platform properties.")
        var input: String

        @Option(name: .shortAndLong, help: "Target progect name")
        var project: String

        func run() throws {
            let logger = Logger(label: "com.redmadrobot.figma-export")

            let reader = ParamsReader(inputPath: input.isEmpty ? "figma-export.yaml" : input)
            let params = try reader.read()

            let spaceTokensURL = params.figma.projects?.first(where: { $0.name == project })?.spaceTokensURL ?? ""

            guard let content = try? Data(contentsOf: URL(fileURLWithPath: spaceTokensURL))
            else { return }

            let spaceTokens = try SpaceTokens.decode(from: content)

            if let ios = params.ios {
                try xcodeExport(spaceTokens: spaceTokens, params: params)
            }

            if let android = params.android {
                try androidExport(spaceTokens: spaceTokens, params: params)
            }
        }

        private func xcodeExport(spaceTokens: SpaceTokens,  params: Params) throws {
            guard let ios = params.ios else { fatalError() }

            let roudedTheme = switch ios.spaceTokens!.roundedTheme {
                case .smooth: spaceTokens.roundedSmooth
                case .rounded: spaceTokens.roundedRounded
                case .none: spaceTokens.roundedNone
            }

            let outputPatch = URL(fileURLWithPath: ios.spaceTokens?.output ?? "")
            let fileName = URL(string: ios.spaceTokens?.outputFileName ?? "")

            let exporter = XcodeSpaceTokensExporter(
                outputDirectory: outputPatch,
                fileName: fileName
            )

            let file = exporter.makeSpaceTokensFile(spaceTokens, roundedCategory: roudedTheme)

            try fileWritter.write(files: [file])

            do {
                let xcodeProject = try XcodeProjectWritter(
                    xcodeProjPath: ios.xcodeprojPath,
                    xcodeprojMainGroupName: ios.xcodeprojMainGroupName,
                    target: ios.target
                )

                if file.destination.file.pathExtension == "swift" {
                    try xcodeProject.addFileReferenceToXcodeProj(file.destination.url)
                }

                try xcodeProject.save()
            } catch (let error) {
                print(error)
            }
        }

        private func androidExport(spaceTokens: SpaceTokens,  params: Params) throws {
            guard let android = params.android else { fatalError() }

            let roudedTheme = switch android.spaceTokens!.roundedTheme {
            case .smooth: spaceTokens.roundedSmooth
            case .rounded: spaceTokens.roundedRounded
            case .none: spaceTokens.roundedNone
            }

            let outputPatch = URL(fileURLWithPath: android.spaceTokens?.output ?? "")
            let fileName = URL(string: android.spaceTokens?.outputFileName ?? "")

            let exporter = AndroidSpaceTokensExporter(
                outputDirectory: outputPatch,
                fileName: fileName
            )

            let files = exporter.makeSpaceTokensFile(spaceTokens, roundedCategory: roudedTheme)

            try fileWritter.write(files: [files])
        }
    }
}
