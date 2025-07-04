import Foundation
import FigmaExportCore

final public class AndroidColorExporter {

    private let outputDirectory: URL
    private let fileName: URL?

    public init(outputDirectory: URL) {
        self.outputDirectory = outputDirectory
        self.fileName = nil
    }

    public init(
        outputDirectory: URL,
        fileName: URL?
    ) {
        self.outputDirectory = outputDirectory
        self.fileName = fileName
    }

    public func export(colorPairs: [AssetPair<Color>]) -> [FileContents] {
        let lightFile = makeColorsFile(colorPairs: colorPairs, dark: false)
        var result = [lightFile]

        if colorPairs.first?.dark != nil {
            let darkFile = makeColorsFile(colorPairs: colorPairs, dark: true)
            result.append(darkFile)
        }

        let properties = self.generateProperties(colorPairs: colorPairs)
        let dataClassDark = self.createDataClassDark(colorPairs: colorPairs)
        let dataClassLight = self.createDataClassLight(colorPairs: colorPairs)
        let darkValues = self.darkColorSystem(colorPairs: colorPairs)
        let lightValues = self.lightColorSystem(colorPairs: colorPairs)

        let resultFile = """
        // -------------------------------------------------------------------------------------------------
        //                  THIS IS A GENERATED FILE. DO NOT EDIT THIS FILE MANUALLY.
        //                  ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN.
        // -------------------------------------------------------------------------------------------------

        package com.shopotam.app.ui.theme

        import androidx.compose.runtime.Immutable
        import androidx.compose.runtime.staticCompositionLocalOf
        import androidx.compose.ui.graphics.Color

        /**
         * Палитра цветов приложения
         */
        @Immutable
        sealed interface ColorSystem {
        \(properties)
        \(dataClassDark)
        \(dataClassLight)
        }

        val LocalColorSystem = staticCompositionLocalOf<ColorSystem> {
            error("ColorSystem is not provided")
        }

        fun createColorSystem(isSystemInDarkTheme: Boolean): ColorSystem {
            return when (isSystemInDarkTheme) {
                true -> createDarkColorSystem()
                false -> createLightColorSystem()
            }
        }

        /**
         * Значение цвета в hex требует формат в виде: "0xAARRGGBB"
         */
        private fun createLightColorSystem() = ColorSystem.Light(
        \(lightValues)
        )
        
        /**
         * Значение цвета в hex требует формат в виде: "0xAARRGGBB"
         */
        private fun createDarkColorSystem() = ColorSystem.Dark(
        \(darkValues)
        )
        """
        return result
    }

    public func exportCompose(
        colorPairs: [AssetPair<Color>]
    ) -> FileContents {
        let properties = self.generateProperties(colorPairs: colorPairs)
        let dataClassDark = self.createDataClassDark(colorPairs: colorPairs)
        let dataClassLight = self.createDataClassLight(colorPairs: colorPairs)
        let darkValues = self.darkColorSystem(colorPairs: colorPairs)
        let lightValues = self.lightColorSystem(colorPairs: colorPairs)

        let resultFile = """
        // -------------------------------------------------------------------------------------------------
        //                  THIS IS A GENERATED FILE. DO NOT EDIT THIS FILE MANUALLY.
        //                  ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN.
        // -------------------------------------------------------------------------------------------------

        package com.shopotam.app.ui.theme

        import androidx.compose.runtime.Immutable
        import androidx.compose.runtime.staticCompositionLocalOf
        import androidx.compose.ui.graphics.Color

        /**
         * Палитра цветов приложения
         */
        @Immutable
        sealed interface ColorSystem {
        \(properties)
        \(dataClassDark)
        \(dataClassLight)
        }

        val LocalColorSystem = staticCompositionLocalOf<ColorSystem> {
            error("ColorSystem is not provided")
        }

        fun createColorSystem(isSystemInDarkTheme: Boolean): ColorSystem {
            return when (isSystemInDarkTheme) {
                true -> createDarkColorSystem()
                false -> createLightColorSystem()
            }
        }

        /**
         * Значение цвета в hex требует формат в виде: "0xAARRGGBB"
         */
        private fun createLightColorSystem() = ColorSystem.Light(
        \(lightValues)
        )
        
        /**
         * Значение цвета в hex требует формат в виде: "0xAARRGGBB"
         */
        private fun createDarkColorSystem() = ColorSystem.Dark(
        \(darkValues)
        )
        """

        return FileContents(
            destination: Destination(
                directory: outputDirectory,
                file: fileName!
            ),
            data: Data(resultFile.utf8)
        )
    }

    private func generateProperties(colorPairs: [AssetPair<Color>]) -> String {
        var result = ""

        colorPairs.forEach {
            result += "    val \($0.light.name): Color\n"
        }

        return result
    }

    private func createDataClassDark(colorPairs: [AssetPair<Color>]) -> String {
        var resultClass = "    data class Dark(\n"
        colorPairs.forEach({
            resultClass += "        override val \($0.dark?.name ?? ""): Color,\n"
        })
        resultClass += "    ) : ColorSystem\n"

        return resultClass

    }

    private func createDataClassLight(colorPairs: [AssetPair<Color>])  -> String {
        var resultClass = "    data class Light(\n"
        colorPairs.forEach({
            resultClass += "        override val \($0.light.name): Color,\n"
        })
        resultClass += "    ) : ColorSystem\n"

        return resultClass
    }

    private func lightColorSystem(colorPairs: [AssetPair<Color>]) -> String {
        var result = ""
        colorPairs.forEach({
            result += "    \($0.light.name) = Color(\($0.light.rgbToHex() ?? "")),\n"
        })

        return result
    }

    private func darkColorSystem(colorPairs: [AssetPair<Color>]) -> String {
        var result = ""
        colorPairs.forEach({
            result += "    \($0.dark!.name) = Color(\($0.dark!.rgbToHex() ?? "")),\n"
        })

        return result
    }

    private func makeColorsFile(colorPairs: [AssetPair<Color>], dark: Bool) -> FileContents {
        let contents = prepareColorsDotXMLContents(colorPairs, dark: dark)
        
        let directoryURL = outputDirectory.appendingPathComponent(dark ? "values-night" : "values")
        let fileURL = URL(string: "colors.xml")!
        
        return FileContents(
            destination: Destination(directory: directoryURL, file: fileURL),
            data: contents
        )
    }
    
    private func prepareColorsDotXMLContents(_ colorPairs: [AssetPair<Color>], dark: Bool) -> Data {
        let resources = XMLElement(name: "resources")
        let xml = XMLDocument(rootElement: resources)
        xml.version = "1.0"
        xml.characterEncoding = "utf-8"
        
        colorPairs.forEach { colorPair in
            if dark, colorPair.dark == nil { return }
            let name = dark ? colorPair.dark!.name : colorPair.light.name
            let hex = dark ? colorPair.dark!.hex : colorPair.light.hex
            let colorNode = XMLElement(name: "color", stringValue: hex)
            colorNode.addAttribute(XMLNode.attribute(withName: "name", stringValue: name) as! XMLNode)
            resources.addChild(colorNode)
        }
        
        return xml.xmlData(options: .nodePrettyPrint)
    }
}

private extension Color {
    func doubleToHex(_ double: Double) -> String {
        String(format: "%02X", arguments: [Int((double * 255).rounded())])
    }

    var hex: String {
        let rr = doubleToHex(red)
        let gg = doubleToHex(green)
        let bb = doubleToHex(blue)
        var result = "0x"
        if alpha != 1.0 {
            let aa = doubleToHex(alpha)
            result.append(aa)
        }

        result += "\(rr)\(gg)\(bb)"
        return result
    }

    func rgbToHex() -> String? {
        guard red >= 0 && red <= 255,
              green >= 0 && green <= 255,
              blue >= 0 && blue <= 255 else {
            return nil
        }
        return String(format: "0xFF%02X%02X%02X", Int(alpha), Int(red), Int(green), Int(blue))
    }
}
