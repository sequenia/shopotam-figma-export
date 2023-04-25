import FigmaAPI
import FigmaExportCore
import Foundation

/// Loads colors from Figma
final class ColorsLoader {
    
    typealias Output = (light: [Color], dark: [Color]?)
    
    private let figmaClient: FigmaClient
    private let params: Params.Figma
    private let project: String?

    init(figmaClient: FigmaClient, params: Params.Figma, project: String?) {
        self.figmaClient = figmaClient
        self.params = params
        self.project = project
    }
    
    func load() throws -> (baseProjectColors: [Color], targetProjectColors: [Color]?) {
        guard let fileColorId = params.base.fileColorId else { fatalError("Specify the fileColorId") }
        let targetProjectIds = params.projects?.first(where: { $0.name == self.project })

        let baseProjectColors = try loadColors(fileId: fileColorId)
        let targetProjectColors = try targetProjectIds.map {
            guard let fileColorId = $0.fileColorId else { fatalError("Specify the fileColorId for target project") }

            return try loadColors(fileId: fileColorId)
        }

        return (baseProjectColors, targetProjectColors)
    }
    
    private func loadColors(fileId: String) throws -> [Color] {
        let styles = try loadStyles(fileId: fileId)
        
        guard !styles.isEmpty else {
            throw FigmaExportError.stylesNotFound
        }

        let sortedStyle = styles.filter { !$0.description.uppercased().contains("un use".uppercased()) }
        let nodeIds = sortedStyle.map { $0.nodeId }

        var nodeIdsResult = [[String]]()
        if nodeIds.joined().utf8.count > 3900 {
            nodeIdsResult = nodeIds.chunked(into: 150)

            var nodes = [NodeId: Node]()
            for nodeIds in nodeIdsResult {
                let result = try loadNodes(fileId: fileId, nodeIds: nodeIds)
                nodes.merge(result, uniquingKeysWith: { _, new in new })
            }

            return nodesAndStylesToColors(nodes: nodes, styles: styles)
        }

        let nodes = try loadNodes(fileId: fileId, nodeIds: nodeIds)
        return nodesAndStylesToColors(nodes: nodes, styles: styles)
    }
    
    /// Соотносит массив Style и Node чтобы получит массив Color
    private func nodesAndStylesToColors(nodes: [NodeId: Node], styles: [Style]) -> [Color] {
        return styles.flatMap { style -> [Color] in
            guard let node = nodes[style.nodeId] else { return [] }
            guard let fill = node.document.fills.first else { return [] }
            
            let name = style.name
            let platform = Platform(rawValue: style.description)
            if let color = fill.color {
                let alpha: Double = fill.opacity ?? color.a

                return [
                    Color(
                        name: name,
                        platform: platform,
                        red: color.r,
                        green: color.g,
                        blue: color.b,
                        alpha: alpha
                    )
                ]
            } else if let gradientStops = fill.gradientStops {
                return gradientStops.compactMap {
                    let color = $0.color
                    let alpha: Double = color.a

                    return Color(
                        name: "\(name) \($0.position)",
                        platform: platform,
                        red: color.r,
                        green: color.g,
                        blue: color.b,
                        alpha: alpha
                    )
                }
            }
            return []
        }
    }
    
    private func loadStyles(fileId: String) throws -> [Style] {
        let endpoint = StylesEndpoint(fileId: fileId)
        let styles = try figmaClient.request(endpoint)
        return styles.filter {
            $0.styleType == .fill && useStyle($0)
        }
    }
    
    private func useStyle(_ style: Style) -> Bool {
        guard !style.description.isEmpty else {
            return true // Цвет общий
        }
        return !style.description.contains("none")
    }
    
    private func loadNodes(fileId: String, nodeIds: [String]) throws -> [NodeId: Node] {
        let endpoint = NodesEndpoint(fileId: fileId, nodeIds: nodeIds)
        return try figmaClient.request(endpoint)
    }
}
