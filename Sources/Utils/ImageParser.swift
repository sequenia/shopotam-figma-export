//
//  ImageParser.swift
//  shopotam-figma-export
//
//  Created by Ivan Mikhailovskii on 19.06.2025.
//
import FigmaExportCore

public class ImageParser {

    let jsonContent: [String: Any]

    public init(jsonContent: [String: Any]) {
        self.jsonContent = jsonContent
    }

    public func run() -> [ImagePack] {
        var svgImages = [ImagePack]()

        jsonContent.forEach { image in
            let name = image.key
            if let imageContent = image.value as? [String: Any] {

                if let smImages = imageContent["sm"] as? [String: Any] {
                    if let solid = smImages["solid"] as? String {
                        let value = solid.replacingOccurrences(
                            of: "currentColor",
                            with: "@color/defaultIconColor"
                        )
                        svgImages.append(
                            ImagePack.singleScale(
                                Image(
                                    name: "ic" + name.upperCamelCased() + "Sm" + "Solid",
                                    content: value.data(using: .utf8)!,
                                    format: "svg"
                                )
                            )
                        )
                    }

                    if let outline = smImages["outline"] as? String {
                        let value = outline.replacingOccurrences(
                            of: "currentColor",
                            with: "@color/defaultIconColor"
                        )
                        svgImages.append(
                            ImagePack.singleScale(
                                Image(
                                    name: "ic" + name.upperCamelCased() + "Sm" + "Outline",
                                    content: value.data(using: .utf8)!,
                                    format: "svg"
                                )
                            )
                        )
                    }
                }

                if let smImages = imageContent["lg"] as? [String: Any] {
                    if let solid = smImages["solid"] as? String {
                        let value = solid.replacingOccurrences(
                            of: "currentColor",
                            with: "@color/defaultIconColor"
                        )
                        svgImages.append(
                            ImagePack.singleScale(
                                Image(
                                    name: "ic" + name.upperCamelCased() + "Lg" + "Solid",
                                    content: value.data(using: .utf8)!,
                                    format: "svg"
                                )
                            )
                        )
                    }

                    if let outline = smImages["outline"] as? String {
                        let value = outline.replacingOccurrences(
                            of: "currentColor",
                            with: "@color/defaultIconColor"
                        )

                        svgImages.append(
                            ImagePack.singleScale(
                                Image(
                                    name: "ic" + name.upperCamelCased() + "Lg" + "Outline",
                                    content: value.data(using: .utf8)!,
                                    format: "svg"
                                )
                            )
                        )
                    }
                }
            }
        }

        return svgImages
    }
}
