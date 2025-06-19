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
            }

            print(textStylesBody)
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

let content = """
{
  "Font-weight/Semibold": {
    "font-weight": {
      "value": 600,
      "type": "number"
    }
  },
  "Font-weight/Bold": {
    "font-weight": {
      "value": 700,
      "type": "number"
    }
  },
  "Font-weight/Light": {
    "font-weight": {
      "value": 300,
      "type": "number"
    }
  },
  "Font-weight/Regular": {
    "font-weight": {
      "value": 400,
      "type": "number"
    }
  },
  "Font-weight/Medium": {
    "font-weight": {
      "value": 500,
      "type": "number"
    }
  },
  "Control/Value": {
    "font-size": {
      "50": {
        "value": 10,
        "type": "number"
      },
      "100": {
        "value": 11,
        "type": "number"
      },
      "200": {
        "value": 12,
        "type": "number"
      },
      "300": {
        "value": 13,
        "type": "number"
      },
      "400": {
        "value": 14,
        "type": "number"
      },
      "500": {
        "value": 15,
        "type": "number"
      },
      "600": {
        "value": 16,
        "type": "number"
      },
      "700": {
        "value": 17,
        "type": "number"
      },
      "800": {
        "value": 18,
        "type": "number"
      },
      "850": {
        "value": 20,
        "type": "number"
      },
      "900": {
        "value": 24,
        "type": "number"
      },
      "950": {
        "value": 28,
        "type": "number"
      },
      "1000": {
        "value": 32,
        "type": "number"
      }
    },
    "line-height": {
      "50": {
        "value": 12,
        "type": "number"
      },
      "100": {
        "value": 16,
        "type": "number"
      },
      "200": {
        "value": 16,
        "type": "number"
      },
      "300": {
        "value": 16,
        "type": "number"
      },
      "400": {
        "value": 20,
        "type": "number"
      },
      "500": {
        "value": 20,
        "type": "number"
      },
      "600": {
        "value": 20,
        "type": "number"
      },
      "700": {
        "value": 24,
        "type": "number"
      },
      "800": {
        "value": 24,
        "type": "number"
      },
      "850": {
        "value": 28,
        "type": "number"
      },
      "900": {
        "value": 32,
        "type": "number"
      },
      "950": {
        "value": 36,
        "type": "number"
      },
      "1000": {
        "value": 40,
        "type": "number"
      }
    },
    "letter-spacing": {
      "50": {
        "value": 0.3,
        "type": "number"
      },
      "100": {
        "value": 0.2,
        "type": "number"
      },
      "200": {
        "value": 0.1,
        "type": "number"
      },
      "300": {
        "value": 0.1,
        "type": "number"
      },
      "400": {
        "value": 0,
        "type": "number"
      },
      "500": {
        "value": 0,
        "type": "number"
      },
      "600": {
        "value": 0,
        "type": "number"
      },
      "700": {
        "value": 0,
        "type": "number"
      },
      "800": {
        "value": 0,
        "type": "number"
      },
      "850": {
        "value": -0.1,
        "type": "number"
      },
      "900": {
        "value": -0.2,
        "type": "number"
      },
      "950": {
        "value": -0.3,
        "type": "number"
      },
      "1000": {
        "value": -0.4,
        "type": "number"
      }
    },
    "paragraph-spacing": {
      "50": {
        "value": "{space.10}",
        "type": "number"
      },
      "100": {
        "value": "{space.12}",
        "type": "number"
      },
      "200": {
        "value": "{space.12}",
        "type": "number"
      },
      "300": {
        "value": "{space.14}",
        "type": "number"
      },
      "400": {
        "value": "{space.14}",
        "type": "number"
      },
      "500": {
        "value": "{space.16}",
        "type": "number"
      },
      "600": {
        "value": "{space.16}",
        "type": "number"
      },
      "700": {
        "value": "{space.20}",
        "type": "number"
      },
      "800": {
        "value": "{space.20}",
        "type": "number"
      },
      "850": {
        "value": "{space.20}",
        "type": "number"
      },
      "900": {
        "value": "{space.24}",
        "type": "number"
      },
      "950": {
        "value": "{space.28}",
        "type": "number"
      },
      "1000": {
        "value": "{space.40}",
        "type": "number"
      }
    },
    "control": {
      "50": {
        "value": "{font-size.50}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "100": {
        "value": "{font-size.100}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "200": {
        "value": "{font-size.200}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "300": {
        "value": "{font-size.300}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "400": {
        "value": "{font-size.400}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "500": {
        "value": "{font-size.500}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "600": {
        "value": "{font-size.600}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "700": {
        "value": "{font-size.700}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "800": {
        "value": "{font-size.800}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "850": {
        "value": "{font-size.850}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "900": {
        "value": "{font-size.900}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "950": {
        "value": "{font-size.950}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      },
      "1000": {
        "value": "{font-size.1000}",
        "type": "number",
        "description": "fontSize, lineHeight, tetterSpacing, paragraphSpacing"
      }
    }
  },
  "Typography/Mobile": {
    "body": {
      "font-size": {
        "50": {
          "value": 10,
          "type": "number"
        },
        "100": {
          "value": 11,
          "type": "number"
        },
        "200": {
          "value": 12,
          "type": "number"
        },
        "300": {
          "value": 13,
          "type": "number"
        },
        "400": {
          "value": 14,
          "type": "number"
        },
        "500": {
          "value": 14,
          "type": "number"
        },
        "600": {
          "value": 14,
          "type": "number"
        },
        "700": {
          "value": 15,
          "type": "number"
        },
        "800": {
          "value": 16,
          "type": "number"
        },
        "900": {
          "value": 17,
          "type": "number"
        }
      },
      "letter-spacing": {
        "50": {
          "value": 0.3,
          "type": "number"
        },
        "100": {
          "value": 0.2,
          "type": "number"
        },
        "200": {
          "value": 0.1,
          "type": "number"
        },
        "300": {
          "value": 0.4,
          "type": "number"
        },
        "400": {
          "value": 0,
          "type": "number"
        },
        "500": {
          "value": 0,
          "type": "number"
        },
        "600": {
          "value": 0,
          "type": "number"
        },
        "700": {
          "value": 0,
          "type": "number"
        },
        "800": {
          "value": 0,
          "type": "number"
        },
        "900": {
          "value": -0.1,
          "type": "number"
        }
      },
      "paragraph-spacing": {
        "50": {
          "value": "{space.2,5}",
          "type": "number"
        },
        "100": {
          "value": "{space.3}",
          "type": "number"
        },
        "200": {
          "value": "{space.3}",
          "type": "number"
        },
        "300": {
          "value": "{space.3,5}",
          "type": "number"
        },
        "400": {
          "value": "{space.3,5}",
          "type": "number"
        },
        "500": {
          "value": "{space.3,5}",
          "type": "number"
        },
        "600": {
          "value": "{space.3,5}",
          "type": "number"
        },
        "700": {
          "value": "{space.4}",
          "type": "number"
        },
        "800": {
          "value": "{space.4}",
          "type": "number"
        },
        "900": {
          "value": "{space.5}",
          "type": "number"
        }
      },
      "line-height": {
        "50": {
          "value": 14,
          "type": "number"
        },
        "100": {
          "value": 15,
          "type": "number"
        },
        "200": {
          "value": 17,
          "type": "number"
        },
        "300": {
          "value": 18,
          "type": "number"
        },
        "400": {
          "value": 20,
          "type": "number"
        },
        "500": {
          "value": 20,
          "type": "number"
        },
        "600": {
          "value": 20,
          "type": "number"
        },
        "700": {
          "value": 22,
          "type": "number"
        },
        "800": {
          "value": 22,
          "type": "number"
        },
        "900": {
          "value": 24,
          "type": "number"
        }
      }
    },
    "title": {
      "font-size": {
        "t1": {
          "value": 28,
          "type": "number"
        },
        "t2": {
          "value": 24,
          "type": "number"
        },
        "t3": {
          "value": 18,
          "type": "number"
        },
        "t4": {
          "value": 17,
          "type": "number"
        },
        "t5": {
          "value": 17,
          "type": "number"
        }
      },
      "line-height": {
        "t1": {
          "value": 32,
          "type": "number"
        },
        "t2": {
          "value": 28,
          "type": "number"
        },
        "t3": {
          "value": 22,
          "type": "number"
        },
        "t4": {
          "value": 20,
          "type": "number"
        },
        "t5": {
          "value": 20,
          "type": "number"
        }
      },
      "letter-spacing": {
        "t1": {
          "value": -0.3,
          "type": "number"
        },
        "t2": {
          "value": -0.2,
          "type": "number"
        },
        "t3": {
          "value": -0.1,
          "type": "number"
        },
        "t4": {
          "value": 0,
          "type": "number"
        },
        "t5": {
          "value": 0,
          "type": "number"
        }
      },
      "paragraph-spacing": {
        "t1": {
          "value": "{space.7}",
          "type": "number"
        },
        "t2": {
          "value": "{space.6}",
          "type": "number"
        },
        "t3": {
          "value": "{space.5}",
          "type": "number"
        },
        "t4": {
          "value": "{space.5}",
          "type": "number"
        },
        "t5": {
          "value": "{space.5}",
          "type": "number"
        }
      }
    },
    "heading": {
      "font-size": {
        "h1": {
          "value": 20,
          "type": "number"
        },
        "h2": {
          "value": 18,
          "type": "number"
        },
        "h3": {
          "value": 16,
          "type": "number"
        },
        "h4": {
          "value": 15,
          "type": "number"
        },
        "h5": {
          "value": 14,
          "type": "number"
        }
      },
      "line-height": {
        "h1": {
          "value": 24,
          "type": "number"
        },
        "h2": {
          "value": 22,
          "type": "number"
        },
        "h3": {
          "value": 20,
          "type": "number"
        },
        "h4": {
          "value": 20,
          "type": "number"
        },
        "h5": {
          "value": 17,
          "type": "number"
        }
      },
      "letter-spacing": {
        "h1": {
          "value": -0.2,
          "type": "number"
        },
        "h2": {
          "value": -0.1,
          "type": "number"
        },
        "h3": {
          "value": 0,
          "type": "number"
        },
        "h4": {
          "value": 0,
          "type": "number"
        },
        "h5": {
          "value": 0,
          "type": "number"
        }
      },
      "paragraph-spacing": {
        "h1": {
          "value": "{space.5}",
          "type": "number"
        },
        "h2": {
          "value": "{space.5}",
          "type": "number"
        },
        "h3": {
          "value": "{space.5}",
          "type": "number"
        },
        "h4": {
          "value": "{space.4}",
          "type": "number"
        },
        "h5": {
          "value": "{space.3,5}",
          "type": "number"
        }
      }
    },
    "display": {
      "font-size": {
        "d1": {
          "value": 48,
          "type": "number"
        },
        "d2": {
          "value": 40,
          "type": "number"
        },
        "d3": {
          "value": 34,
          "type": "number"
        },
        "d4": {
          "value": 32,
          "type": "number"
        },
        "d5": {
          "value": 28,
          "type": "number"
        }
      },
      "line-height": {
        "d1": {
          "value": 58,
          "type": "number"
        },
        "d2": {
          "value": 48,
          "type": "number"
        },
        "d3": {
          "value": 40,
          "type": "number"
        },
        "d4": {
          "value": 36,
          "type": "number"
        },
        "d5": {
          "value": 32,
          "type": "number"
        }
      },
      "letter-spacing": {
        "d1": {
          "value": -0.6,
          "type": "number"
        },
        "d2": {
          "value": -0.6,
          "type": "number"
        },
        "d3": {
          "value": -0.6,
          "type": "number"
        },
        "d4": {
          "value": -0.6,
          "type": "number"
        },
        "d5": {
          "value": -0.5,
          "type": "number"
        }
      },
      "paragraph-spacing": {
        "d1": {
          "value": "{space.12}",
          "type": "number"
        },
        "d2": {
          "value": "{space.10}",
          "type": "number"
        },
        "d3": {
          "value": "{space.9}",
          "type": "number"
        },
        "d4": {
          "value": "{space.8}",
          "type": "number"
        },
        "d5": {
          "value": "{space.7}",
          "type": "number"
        }
      }
    }
  }
}
""".data(using: .utf8)!
