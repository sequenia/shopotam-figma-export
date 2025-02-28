import Foundation
import FigmaExportCore
import Stencil

final public class XcodeTypographyExporter {

    public init() {}
    
    public func exportStyles(
        _ textStyles: [TextStyle], folderURL: URL, version: Int?) throws -> [FileContents] {

        switch version {
        case 1:
            return try Version1.configureStyles(textStyles, folderURL: folderURL)

        case 2:
            return try Version2.configureStyles(textStyles, folderURL: folderURL)

        default:
            return try DefaultVersion.configureStyles(textStyles, folderURL: folderURL)
        }
    }

    public func exportComponents(
        textStyles: [TextStyle], componentsDirectory: URL, version: Int?) throws -> [FileContents] {

        switch version {
        case 1:
            return try Version1.configureComponents(textStyles, folderURL: componentsDirectory)

        case 2:
            return []

        default:
            return try DefaultVersion.configureComponents(textStyles, folderURL: componentsDirectory)
        }
    }
    
    static func makeFileContents(data: String, directoryURL: URL, fileName: String) throws -> FileContents {
        let data = data.data(using: .utf8)!
        let fileURL = URL(string: fileName)!
        let destination = Destination(directory: directoryURL, file: fileURL)
        return FileContents(destination: destination, data: data)
    }
}
