import Foundation
import FigmaExportCore
import FigmaAPI

final public class XcodeSpaceTokensExporter {
    private let outputDirectory: URL
    private let fileName: URL?

    public init(
        outputDirectory: URL,
        fileName: URL?
    ) {
        self.outputDirectory = outputDirectory
        self.fileName = fileName
    }

    public func makeSpaceTokensFile(
        _ spaceTokens: SpaceTokens,
        roundedCategory: RoundedCategory
    ) -> FileContents {
        let content = self.createContent(
            spaceTokens: spaceTokens,
            roundedCategory: roundedCategory
        )

        return FileContents(
            destination: Destination(
                directory: outputDirectory,
                file: fileName!
            ),
            data: Data(content.utf8)
        )
    }

    private func createContent(
        spaceTokens: SpaceTokens,
        roundedCategory: RoundedCategory
    ) -> String {
        var content = "import UIKit\n\nstruct SpaceTokens {\n\n"
        content += "    static let market = Market()\n"
        content += "    static let cms = Cms()\n"
        content += "    static let rounded = Rounded()\n\n"
        content += self.createClassMarket(market: spaceTokens.layoutMobile.layout.market!)
        content += self.createCMSClass(cms: spaceTokens.layoutMobile.layout.cms!)
        content += self.createRoundedCategory(roundedCategory: roundedCategory)
        content += self.createSpaceAlias(spaceValue: spaceTokens.spaceValue)
        content += "}"

        return content
    }

    func createRoundedCategory(roundedCategory: RoundedCategory) -> String {
        var content = "    struct Rounded {\n"
        roundedCategory.borderRadius?.keys.forEach { key in
            guard let value = roundedCategory.borderRadius?[key]?.value else { return }

            content += "        let borderRadius\(key.upperCamelCased()): CGFloat = \(value)\n"
        }

        roundedCategory.outline?.keys.forEach { key in
            guard let value = roundedCategory.outline?[key]?.value else { return }

            content += "        let outline\(key.upperCamelCased()): CGFloat = \(value)\n"
        }

        roundedCategory.conteiner2?.keys.forEach { key in
            guard let value = roundedCategory.conteiner2?[key]?.value else { return }

            content += "        let conteiner2\(key.upperCamelCased()): CGFloat = \(value)\n"
        }

        roundedCategory.conteiner4?.keys.forEach { key in
            guard let value = roundedCategory.conteiner4?[key]?.value else { return }

            content += "        let conteiner4\(key.upperCamelCased()): CGFloat = \(value)\n"
        }

        roundedCategory.conteiner6?.keys.forEach { key in
            guard let value = roundedCategory.conteiner6?[key]?.value else { return }

            content += "        let conteiner6\(key.upperCamelCased()): CGFloat = \(value)\n"
        }

        roundedCategory.bg1?.keys.forEach { key in
            guard let value = roundedCategory.bg1?[key]?.value else { return }

            content += "        let bg1\(key.upperCamelCased()): CGFloat = \(value)\n"
        }

        content += "    }\n\n"
        return content
    }

    private func createSpaceAlias(spaceValue: SpaceValue) -> String {
        var content = "    struct Alias {\n"
        spaceValue.space.keys.forEach { key in
            let value = spaceValue.space[key]?.value
            content += "        static let space\(key.replacingOccurrences(of: ",", with: "_")): CGFloat = \(value ?? 0)\n"
        }
        content += "    }\n"
        return content
    }

    private func createClassMarket(market: LayoutCategory.Market) -> String {
        guard let block = market.block else { return "" }

        var content = "    struct Market {\n\n"
        content += """
                struct Block {
                    let gap: CGFloat
                    let top: CGFloat
                }
        
                struct ProductCard {
                    let gap: CGFloat
                    let top: CGFloat
                    let pragraph: CGFloat
                }
            
                struct Card {
                    let sliderMin: CGFloat
                    let sliderMax: CGFloat
                    let listingMin: CGFloat
                    let listingMax: CGFloat
                }
                
                struct Paragraph {
                    let top: CGFloat
                }
                
                struct Form {
                    let top: CGFloat
                    let gap: CGFloat
                    let groupGap: CGFloat
                }
                
                struct Section {
                    let side: CGFloat
                    let largeMax: CGFloat
                    let top: CGFloat
                    let bottom: CGFloat
                    let smallMax: CGFloat
                    let sideCms: CGFloat
                }
        
                let block = Block(
                    gap: Alias.\(block.gap?.resolvedValueKey() ?? ""), 
                    top: Alias.\(block.top?.resolvedValueKey() ?? "")
                )
                
                let productCard = ProductCard(
                    gap: Alias.\(market.productcard?.gap?.resolvedValueKey() ?? ""),
                    top: Alias.\(market.productcard?.top?.resolvedValueKey() ?? ""),
                    pragraph: Alias.\(market.productcard?.pragraph?.resolvedValueKey() ?? "")
                )
                
                let card = Card(
                    sliderMin: \(market.card?.sliderMin?.value ?? .zero),
                    sliderMax: \(market.card?.sliderMax?.value ?? .zero),
                    listingMin: \(market.card?.listingMin?.value ?? .zero),
                    listingMax: \(market.card?.listingMax?.value ?? .zero)
                )
            
                let paragraph = Paragraph(
                    top: Alias.\(market.paragraph?.top?.resolvedValueKey() ?? "")
                )
                
                let form = Form(
                    top: Alias.\(market.form?.top?.resolvedValueKey() ?? ""),
                    gap: Alias.\(market.form?.gap?.resolvedValueKey() ?? ""),
                    groupGap: Alias.\(market.form?.groupGap?.resolvedValueKey() ?? "")
                )
            
                let section = Section (
                    side: Alias.\(market.section?.side?.resolvedValueKey() ?? ""),
                    largeMax: \(market.section?.largeMax?.value ?? .zero),
                    top: Alias.\(market.section?.top?.resolvedValueKey() ?? ""),
                    bottom: Alias.\(market.section?.bottom?.resolvedValueKey() ?? ""),
                    smallMax: \(market.section?.smallMax?.value ?? .zero),
                    sideCms: Alias.\(market.section?.sideCms?.resolvedValueKey() ?? "")
                )
            }\n\n
        """
        return content
    }

    private func createCMSClass(cms: LayoutCategory.Cms) -> String {
        var content = "    struct Cms {\n\n"
        content += """
                struct Card {
                    let cardMin: CGFloat
                    let cardMax: CGFloat
                }

                struct Section {
                    let largeMax: CGFloat
                    let smallMax: CGFloat
                    let side: CGFloat
                    let gap: CGFloat
                    let top: CGFloat
                    let bottom: CGFloat
                }

                let card = Card (
                    cardMin: \(cms.card?.cardMin?.value ?? .zero),
                    cardMax: \(cms.card?.cardMax?.value ?? .zero)
                )

                let section = Section (
                    largeMax: \(cms.section?.largeMax?.value ?? .zero),
                    smallMax: \(cms.section?.smallMax?.value ?? .zero),
                    side: Alias.\(cms.section?.side?.resolvedValueKey() ?? ""),
                    gap: Alias.\(cms.section?.gap?.resolvedValueKey() ?? ""),
                    top: Alias.\(cms.section?.top?.resolvedValueKey() ?? ""),
                    bottom: Alias.\(cms.section?.bottom?.resolvedValueKey() ?? "")
                )

                let gap = Alias.\(cms.gap?.resolvedValueKey() ?? "")
                let side = Alias.\(cms.side?.resolvedValueKey() ?? "")
                let top = Alias.\(cms.top?.resolvedValueKey() ?? "")
                let max = \(cms.max?.value ?? .zero)
                let sideEditor = Alias.\(cms.sideEditor?.resolvedValueKey() ?? "")
                let bottom = Alias.\(cms.bottom?.resolvedValueKey() ?? "")
            }\n\n
        """

        return content
    }
}
