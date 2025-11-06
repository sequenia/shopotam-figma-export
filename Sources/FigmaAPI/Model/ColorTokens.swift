//
//  File.swift
//  shopotam-figma-export
//
//  Created by Ivan Mikhailovskii on 30.10.2025.
//

import Foundation
import Utils

// MARK: - Main Container
public struct ColorTokens: Codable {
    public let stateActive: StateActive
    public let stateFocus: StateFocus
    public let stateRest: StateRest
    public let rolesLight: RolesLight

    enum CodingKeys: String, CodingKey {
        case stateActive = "State/Active"
        case stateFocus = "State/Focus"
        case stateRest = "State/Rest"
        case rolesLight = "Roles/Light"
    }
}

// MARK: - Roles Light
public struct RolesLight: Codable {
    public let role: Role

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(Role.self, forKey: .role)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
    }

    enum CodingKeys: String, CodingKey {
        case role
    }
}

// MARK: - Role
public struct Role: Codable {
    public let primary: ColorRole
    public let surface: SurfaceRole
    public let extended: ExtendedRole
    public let secondary: ColorRole
    public let tertiary: ColorRole
    public let addition: ColorRole
    public let success: ColorRole
    public let error: ColorRole
    public let warning: ColorRole
    public let info: ColorRole
    public let accent: ColorRole
    public let vibecolor: Vibecolor

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        primary = try container.decode(ColorRole.self, forKey: .primary)
        surface = try container.decode(SurfaceRole.self, forKey: .surface)
        extended = try container.decode(ExtendedRole.self, forKey: .extended)
        secondary = try container.decode(ColorRole.self, forKey: .secondary)
        tertiary = try container.decode(ColorRole.self, forKey: .tertiary)
        addition = try container.decode(ColorRole.self, forKey: .addition)
        success = try container.decode(ColorRole.self, forKey: .success)
        error = try container.decode(ColorRole.self, forKey: .error)
        warning = try container.decode(ColorRole.self, forKey: .warning)
        info = try container.decode(ColorRole.self, forKey: .info)
        accent = try container.decode(ColorRole.self, forKey: .accent)
        vibecolor = try container.decode(Vibecolor.self, forKey: .vibecolor)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(primary, forKey: .primary)
        try container.encode(surface, forKey: .surface)
        try container.encode(extended, forKey: .extended)
        try container.encode(secondary, forKey: .secondary)
        try container.encode(tertiary, forKey: .tertiary)
        try container.encode(addition, forKey: .addition)
        try container.encode(success, forKey: .success)
        try container.encode(error, forKey: .error)
        try container.encode(warning, forKey: .warning)
        try container.encode(info, forKey: .info)
        try container.encode(accent, forKey: .accent)
        try container.encode(vibecolor, forKey: .vibecolor)
    }

    enum CodingKeys: String, CodingKey {
        case primary, surface, extended, secondary, tertiary, addition
        case success, error, warning, info, accent, vibecolor
    }
}

// MARK: - Color Role
public struct ColorRole: Codable {
    public let core: TokenData
    public let on: TokenData?
    public let container: ColorContainer?
    public let dim: TokenData?
    public let chroma: TokenData?
    public let onDim: TokenData?
    public let angle: TokenData?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        core = try container.decode(TokenData.self, forKey: .core)
        on = try container.decodeIfPresent(TokenData.self, forKey: .on)
        self.container = try container.decodeIfPresent(ColorContainer.self, forKey: .container)
        dim = try container.decodeIfPresent(TokenData.self, forKey: .dim)
        chroma = try container.decodeIfPresent(TokenData.self, forKey: .chroma)
        onDim = try container.decodeIfPresent(TokenData.self, forKey: .onDim)
        angle = try container.decodeIfPresent(TokenData.self, forKey: .angle)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(core, forKey: .core)
        try container.encodeIfPresent(on, forKey: .on)
        try container.encodeIfPresent(self.container, forKey: .container)
        try container.encodeIfPresent(dim, forKey: .dim)
        try container.encodeIfPresent(chroma, forKey: .chroma)
        try container.encodeIfPresent(onDim, forKey: .onDim)
        try container.encodeIfPresent(angle, forKey: .angle)
    }

    enum CodingKeys: String, CodingKey {
        case core, on, container, dim, chroma
        case onDim = "on-dim"
        case angle
    }
}

// MARK: - Color Container
public struct ColorContainer: Codable {
    public let core: TokenData?
    public let onHigh: TokenData?
    public let dim: TokenData?
    public let chroma: TokenData?
    public let on: TokenData?
    public let onLow: TokenData?
    public let onLowest: TokenData?
    public let onHighest: TokenData?
    public let base: TokenData?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.core = try container.decodeIfPresent(TokenData.self, forKey: .core)
        onHigh = try container.decodeIfPresent(TokenData.self, forKey: .onHigh)
        dim = try container.decodeIfPresent(TokenData.self, forKey: .dim)
        chroma = try container.decodeIfPresent(TokenData.self, forKey: .chroma)
        on = try container.decodeIfPresent(TokenData.self, forKey: .on)
        onLow = try container.decodeIfPresent(TokenData.self, forKey: .onLow)
        onLowest = try container.decodeIfPresent(TokenData.self, forKey: .onLowest)
        onHighest = try container.decodeIfPresent(TokenData.self, forKey: .onHighest)
        base = try container.decodeIfPresent(TokenData.self, forKey: .base)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(core, forKey: .core)
        try container.encodeIfPresent(onHigh, forKey: .onHigh)
        try container.encodeIfPresent(dim, forKey: .dim)
        try container.encodeIfPresent(chroma, forKey: .chroma)
        try container.encodeIfPresent(on, forKey: .on)
        try container.encodeIfPresent(onLow, forKey: .onLow)
        try container.encodeIfPresent(onLowest, forKey: .onLowest)
        try container.encodeIfPresent(onHighest, forKey: .onHighest)
        try container.encodeIfPresent(base, forKey: .base)
    }

    enum CodingKeys: String, CodingKey {
        case core
        case onHigh = "on-high"
        case dim, chroma, on
        case onLow = "on-low"
        case onLowest = "on-lowest"
        case onHighest = "on-highest"
        case base
    }
}

// MARK: - Surface Role
public struct SurfaceRole: Codable {
    public let surface: TokenData?
    public let dim: TokenData?
    public let bright: TokenData?
    public let container: SurfaceContainer?
    public let onHighest: TokenData?
    public let onHigh: TokenData?
    public let on: TokenData?
    public let onLow: TokenData?
    public let transparent: TokenData?
    public let chromatic: SurfaceChromatic?
    public let onLowest: TokenData?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.surface = try container.decodeIfPresent(TokenData.self, forKey: .surface)
        dim = try container.decodeIfPresent(TokenData.self, forKey: .dim)
        bright = try container.decodeIfPresent(TokenData.self, forKey: .bright)
        self.container = try container.decodeIfPresent(SurfaceContainer.self, forKey: .container)
        onHighest = try container.decodeIfPresent(TokenData.self, forKey: .onHighest)
        onHigh = try container.decodeIfPresent(TokenData.self, forKey: .onHigh)
        on = try container.decodeIfPresent(TokenData.self, forKey: .on)
        onLow = try container.decodeIfPresent(TokenData.self, forKey: .onLow)
        transparent = try container.decodeIfPresent(TokenData.self, forKey: .transparent)
        chromatic = try container.decodeIfPresent(SurfaceChromatic.self, forKey: .chromatic)
        onLowest = try container.decodeIfPresent(TokenData.self, forKey: .onLowest)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(surface, forKey: .surface)
        try container.encodeIfPresent(dim, forKey: .dim)
        try container.encodeIfPresent(bright, forKey: .bright)
        try container.encodeIfPresent(self.container, forKey: .container)
        try container.encodeIfPresent(onHighest, forKey: .onHighest)
        try container.encodeIfPresent(onHigh, forKey: .onHigh)
        try container.encodeIfPresent(on, forKey: .on)
        try container.encodeIfPresent(onLow, forKey: .onLow)
        try container.encodeIfPresent(transparent, forKey: .transparent)
        try container.encodeIfPresent(chromatic, forKey: .chromatic)
        try container.encodeIfPresent(onLowest, forKey: .onLowest)
    }

    enum CodingKeys: String, CodingKey {
        case surface, dim, bright, container
        case onHighest = "on-highest"
        case onHigh = "on-high"
        case on
        case onLow = "on-low"
        case transparent, chromatic
        case onLowest = "on-lowest"
    }
}

// MARK: - Surface Container
public struct SurfaceContainer: Codable {
    public let lowest: TokenData?
    public let low: TokenData?
    public let container: TokenData?
    public let high: TokenData?
    public let highest: TokenData?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lowest = try container.decodeIfPresent(TokenData.self, forKey: .lowest)
        low = try container.decodeIfPresent(TokenData.self, forKey: .low)
        self.container = try container.decodeIfPresent(TokenData.self, forKey: .container)
        high = try container.decodeIfPresent(TokenData.self, forKey: .high)
        highest = try container.decodeIfPresent(TokenData.self, forKey: .highest)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(lowest, forKey: .lowest)
        try container.encodeIfPresent(low, forKey: .low)
        try container.encodeIfPresent(self.container, forKey: .container)
        try container.encodeIfPresent(high, forKey: .high)
        try container.encodeIfPresent(highest, forKey: .highest)
    }

    enum CodingKeys: String, CodingKey {
        case lowest, low, container, high, highest
    }
}

// MARK: - Surface Chromatic
public struct SurfaceChromatic: Codable {
    public let start: TokenData?
    public let midStart: TokenData?
    public let midEnd: TokenData?
    public let end: TokenData?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decodeIfPresent(TokenData.self, forKey: .start)
        midStart = try container.decodeIfPresent(TokenData.self, forKey: .midStart)
        midEnd = try container.decodeIfPresent(TokenData.self, forKey: .midEnd)
        end = try container.decodeIfPresent(TokenData.self, forKey: .end)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(start, forKey: .start)
        try container.encodeIfPresent(midStart, forKey: .midStart)
        try container.encodeIfPresent(midEnd, forKey: .midEnd)
        try container.encodeIfPresent(end, forKey: .end)
    }

    enum CodingKeys: String, CodingKey {
        case start
        case midStart = "mid-start"
        case midEnd = "mid-end"
        case end
    }
}

// MARK: - Extended Role
public struct ExtendedRole: Codable {
    public let inverse: ExtendedInverse?
    public let shadow: ExtendedShadow?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inverse = try container.decodeIfPresent(ExtendedInverse.self, forKey: .inverse)
        shadow = try container.decodeIfPresent(ExtendedShadow.self, forKey: .shadow)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(inverse, forKey: .inverse)
        try container.encodeIfPresent(shadow, forKey: .shadow)
    }

    enum CodingKeys: String, CodingKey {
        case inverse, shadow
    }
}

// MARK: - Extended Inverse
public struct ExtendedInverse: Codable {
    public let surface: TokenData?
    public let onSurface: TokenData?
    public let primary: TokenData?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        surface = try container.decodeIfPresent(TokenData.self, forKey: .surface)
        onSurface = try container.decodeIfPresent(TokenData.self, forKey: .onSurface)
        primary = try container.decodeIfPresent(TokenData.self, forKey: .primary)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(surface, forKey: .surface)
        try container.encodeIfPresent(onSurface, forKey: .onSurface)
        try container.encodeIfPresent(primary, forKey: .primary)
    }

    enum CodingKeys: String, CodingKey {
        case surface
        case onSurface = "on-surface"
        case primary
    }
}

// MARK: - Extended Shadow
public struct ExtendedShadow: Codable {
    public let opacity1: TokenData?
    public let opacity2: TokenData?
    public let opacity3: TokenData?
    public let shadowColor: TokenData?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        opacity1 = try container.decodeIfPresent(TokenData.self, forKey: .opacity1)
        opacity2 = try container.decodeIfPresent(TokenData.self, forKey: .opacity2)
        opacity3 = try container.decodeIfPresent(TokenData.self, forKey: .opacity3)
        shadowColor = try container.decodeIfPresent(TokenData.self, forKey: .shadowColor)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(opacity1, forKey: .opacity1)
        try container.encodeIfPresent(opacity2, forKey: .opacity2)
        try container.encodeIfPresent(opacity3, forKey: .opacity3)
        try container.encodeIfPresent(shadowColor, forKey: .shadowColor)
    }

    enum CodingKeys: String, CodingKey {
        case opacity1, opacity2, opacity3
        case shadowColor = "shadow-color"
    }
}

// MARK: - Vibecolor
public struct Vibecolor: Codable {
    public let gray: ColorRole?
    public let zinc: ColorRole?
    public let neutral: ColorRole?
    public let red: ColorRole?
    public let stone: ColorRole?
    public let orange: ColorRole?
    public let amber: ColorRole?
    public let yellow: ColorRole?
    public let green: ColorRole?
    public let emerald: ColorRole?
    public let teal: ColorRole?
    public let cyan: ColorRole?
    public let sky: ColorRole?
    public let blue: ColorRole?
    public let indigo: ColorRole?
    public let violet: ColorRole?
    public let purple: ColorRole?
    public let fuchsia: ColorRole?
    public let pink: ColorRole?
    public let rose: ColorRole?
    public let lime: ColorRole?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gray = try container.decodeIfPresent(ColorRole.self, forKey: .gray)
        zinc = try container.decodeIfPresent(ColorRole.self, forKey: .zinc)
        neutral = try container.decodeIfPresent(ColorRole.self, forKey: .neutral)
        red = try container.decodeIfPresent(ColorRole.self, forKey: .red)
        stone = try container.decodeIfPresent(ColorRole.self, forKey: .stone)
        orange = try container.decodeIfPresent(ColorRole.self, forKey: .orange)
        amber = try container.decodeIfPresent(ColorRole.self, forKey: .amber)
        yellow = try container.decodeIfPresent(ColorRole.self, forKey: .yellow)
        green = try container.decodeIfPresent(ColorRole.self, forKey: .green)
        emerald = try container.decodeIfPresent(ColorRole.self, forKey: .emerald)
        teal = try container.decodeIfPresent(ColorRole.self, forKey: .teal)
        cyan = try container.decodeIfPresent(ColorRole.self, forKey: .cyan)
        sky = try container.decodeIfPresent(ColorRole.self, forKey: .sky)
        blue = try container.decodeIfPresent(ColorRole.self, forKey: .blue)
        indigo = try container.decodeIfPresent(ColorRole.self, forKey: .indigo)
        violet = try container.decodeIfPresent(ColorRole.self, forKey: .violet)
        purple = try container.decodeIfPresent(ColorRole.self, forKey: .purple)
        fuchsia = try container.decodeIfPresent(ColorRole.self, forKey: .fuchsia)
        pink = try container.decodeIfPresent(ColorRole.self, forKey: .pink)
        rose = try container.decodeIfPresent(ColorRole.self, forKey: .rose)
        lime = try container.decodeIfPresent(ColorRole.self, forKey: .lime)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(gray, forKey: .gray)
        try container.encodeIfPresent(zinc, forKey: .zinc)
        try container.encodeIfPresent(neutral, forKey: .neutral)
        try container.encodeIfPresent(red, forKey: .red)
        try container.encodeIfPresent(stone, forKey: .stone)
        try container.encodeIfPresent(orange, forKey: .orange)
        try container.encodeIfPresent(amber, forKey: .amber)
        try container.encodeIfPresent(yellow, forKey: .yellow)
        try container.encodeIfPresent(green, forKey: .green)
        try container.encodeIfPresent(emerald, forKey: .emerald)
        try container.encodeIfPresent(teal, forKey: .teal)
        try container.encodeIfPresent(cyan, forKey: .cyan)
        try container.encodeIfPresent(sky, forKey: .sky)
        try container.encodeIfPresent(blue, forKey: .blue)
        try container.encodeIfPresent(indigo, forKey: .indigo)
        try container.encodeIfPresent(violet, forKey: .violet)
        try container.encodeIfPresent(purple, forKey: .purple)
        try container.encodeIfPresent(fuchsia, forKey: .fuchsia)
        try container.encodeIfPresent(pink, forKey: .pink)
        try container.encodeIfPresent(rose, forKey: .rose)
        try container.encodeIfPresent(lime, forKey: .lime)
    }

    enum CodingKeys: String, CodingKey {
        case gray, zinc, neutral, red, stone, orange, amber, yellow, green
        case emerald, teal, cyan, sky, blue, indigo, violet, purple
        case fuchsia, pink, rose, lime
    }
}

// MARK: - State Rest
public struct StateRest: Codable {
    public let button: Button
    public let focusSelection: FocusSelection
    public let formControl: FormControl
    public let checkRadio: CheckRadio
    public let listControl: ListControl
    public let navButton: NavButton
    public let segmentedButton: SegmentedButton
    public let tab: Tab
    public let badge: Badge
    public let range: Range
    public let link: Link
    public let overhung: Overhung
    public let opacity: Opacity
    public let areabutton: Areabutton
    public let rating: Rating
    public let variation: Variation
    public let list: List
    public let tsarButton: TsarButton
    public let tsarCheckRadio: TsarCheckRadio

    enum CodingKeys: String, CodingKey {
        case button
        case focusSelection = "focus-selection"
        case formControl = "form-control"
        case checkRadio = "check-radio"
        case listControl = "list-control"
        case navButton = "nav-button"
        case segmentedButton = "segmented-button"
        case tab
        case badge
        case range
        case link
        case overhung
        case opacity
        case areabutton
        case rating
        case variation
        case list
        case tsarButton = "tsar-button"
        case tsarCheckRadio = "tsar-check-radio"
    }
}

// MARK: - State Focus
public struct StateFocus: Codable {
    public let button: Button
    public let focusSelection: FocusSelection
    public let formControl: FormControl
    public let checkRadio: CheckRadio
    public let listControl: ListControl
    public let navButton: NavButton
    public let segmentedButton: SegmentedButton
    public let tab: Tab
    public let badge: Badge
    public let range: Range
    public let link: Link
    public let overhung: Overhung
    public let opacity: Opacity
    public let areabutton: Areabutton
    public let rating: Rating
    public let variation: Variation
    public let list: List
    public let tsarButton: TsarButton
    public let tsarCheckRadio: TsarCheckRadio

    enum CodingKeys: String, CodingKey {
        case button
        case focusSelection = "focus-selection"
        case formControl = "form-control"
        case checkRadio = "check-radio"
        case listControl = "list-control"
        case navButton = "nav-button"
        case segmentedButton = "segmented-button"
        case tab
        case badge
        case range
        case link
        case overhung
        case opacity
        case areabutton
        case rating
        case variation
        case list
        case tsarButton = "tsar-button"
        case tsarCheckRadio = "tsar-check-radio"
    }
}

// MARK: - State Active
public struct StateActive: Codable {
    public let button: Button
    public let focusSelection: FocusSelection
    public let formControl: FormControl
    public let checkRadio: CheckRadio
    public let listControl: ListControl
    public let navButton: NavButton
    public let segmentedButton: SegmentedButton
    public let tab: Tab
    public let badge: Badge
    public let range: Range
    public let link: Link
    public let overhung: Overhung
    public let opacity: Opacity
    public let areabutton: Areabutton
    public let rating: Rating
    public let variation: Variation
    public let list: List
    public let tsarButton: TsarButton
    public let tsarCheckRadio: TsarCheckRadio

    enum CodingKeys: String, CodingKey {
        case button
        case focusSelection = "focus-selection"
        case formControl = "form-control"
        case checkRadio = "check-radio"
        case listControl = "list-control"
        case navButton = "nav-button"
        case segmentedButton = "segmented-button"
        case tab
        case badge
        case range
        case link
        case overhung
        case opacity
        case areabutton
        case rating
        case variation
        case list
        case tsarButton = "tsar-button"
        case tsarCheckRadio = "tsar-check-radio"
    }
}

// MARK: - Token Data Structure
public struct TokenData: Codable {
    public let value: StringOrNumber
    public let type: String

    enum CodingKeys: String, CodingKey {
        case value, type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        if let stringValue = try? container.decode(String.self, forKey: .value) {
            if stringValue.first == "{", !stringValue.contains("opacity") {
                let resultValue = ColorСomparisonUtils.instance.getColorValue(for: stringValue)
                value = .string(resultValue)
            } else {
                value = .string(stringValue)
            }
        } else if let numberValue = try? container.decode(Double.self, forKey: .value) {
            value = .number(numberValue)
        } else {
            throw DecodingError.typeMismatch(
                StringOrNumber.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or Double for value"
                )
            )
        }
    }
}

// MARK: - Button
public struct Button: Codable {
    public let primary: ButtonVariant
    public let ghost: ButtonVariant
    public let addition: ButtonVariant
    public let secondary: ButtonVariant
    public let tertiary: ButtonVariant
    public let contrast: ButtonVariant
    public let clean: ButtonVariant
}

public struct ButtonVariant: Codable {
    public let bg: TokenData
    public let border: TokenData
    public let color: TokenData
    public let chroma: TokenData
    public let groupBorder: TokenData
    public let groupColor: TokenData

    enum CodingKeys: String, CodingKey {
        case bg, border, color, chroma
        case groupBorder = "group-border"
        case groupColor = "group-color"
    }
}

// MARK: - Focus Selection
public struct FocusSelection: Codable {
    public let outline: TokenData
    public let outlineVariant: TokenData
    public let outlineShow: TokenData

    enum CodingKeys: String, CodingKey {
        case outline, outlineVariant, outlineShow
    }
}

// MARK: - Form Control
public struct FormControl: Codable {
    public let `default`: FormControlVariant
    public let success: FormControlVariant
    public let error: FormControlVariant
    public let light: FormControlVariant
    public let ghost: FormControlVariant
    public let autofill: FormControlVariant
    public let secondary: FormControlVariant
}

public struct FormControlVariant: Codable {
    public let bg: TokenData
    public let border: TokenData
    public let color: TokenData
    public let chroma: TokenData
    public let icon: TokenData
    public let chevrone: TokenData
    public let dim: TokenData
    public let placehold: TokenData
}

// MARK: - Check Radio
public struct CheckRadio: Codable {
    public let selected: CheckRadioVariant
    public let unselected: CheckRadioVariant
}

public struct CheckRadioVariant: Codable {
    public let bg: TokenData
    public let border: TokenData
    public let chroma: TokenData
    public let color: TokenData
    public let handle: TokenData
}

// MARK: - List Control
public struct ListControl: Codable {
    public let label: TokenData
    public let bg: TokenData
    public let border: TokenData
}

// MARK: - Nav Button
public struct NavButton: Codable {
    public let selectedTransparent: NavButtonVariant
    public let unselected: NavButtonVariant
    public let selected: NavButtonVariant

    enum CodingKeys: String, CodingKey {
        case selectedTransparent = "selected-transparent"
        case unselected
        case selected
    }
}

public struct NavButtonVariant: Codable {
    public let bg: TokenData
    public let color: TokenData
    public let chevrone: TokenData
    public let border: TokenData
}

// MARK: - Segmented Button
public struct SegmentedButton: Codable {
    public let unselected: SegmentedButtonVariant
    public let selected: SegmentedButtonVariant
    public let conteiner: SegmentedContainer
    public let selectedContrast: SegmentedButtonVariant

    enum CodingKeys: String, CodingKey {
        case unselected, selected, conteiner
        case selectedContrast = "selected-contrast"
    }
}

public struct SegmentedButtonVariant: Codable {
    public let bg: TokenData
    public let chroma: TokenData
    public let border: TokenData
    public let color: TokenData
}

public struct SegmentedContainer: Codable {
    public let bg: TokenData
    public let chroma: TokenData
    public let angle: TokenData
}

// MARK: - Tab
public struct Tab: Codable {
    public let selected: TabVariant
    public let unselected: TabVariant
}

public struct TabVariant: Codable {
    public let bg: TokenData
    public let border: TokenData
    public let color: TokenData
}

// MARK: - Badge
public struct Badge: Codable {
    public let market: BadgeMarket
    public let state: BadgeState
    public let system: BadgeSystem
}

public struct BadgeMarket: Codable {
    public let percent: BadgeVariant
    public let sale: BadgeVariant
    public let new: BadgeVariant
    public let brand: BadgeVariant
}

public struct BadgeState: Codable {
    public let delivered: BadgeVariant
    public let inprogress: BadgeVariant
    public let new: BadgeVariant
    public let paid: BadgeVariant
    public let cancelled: BadgeVariant
    public let paidclient: BadgeVariant
}

public struct BadgeSystem: Codable {
    public let info: BadgeVariant
    public let success: BadgeVariant
    public let warning: BadgeVariant
    public let error: BadgeVariant
    public let accent: BadgeVariant
    public let secondary: BadgeVariant
    public let ghost: BadgeVariant
}

public struct BadgeVariant: Codable {
    public let bg: TokenData
    public let chroma: TokenData
    public let border: TokenData
    public let color: TokenData
}

// MARK: - Range
public struct Range: Codable {
    public let `default`: RangeVariant
    public let container: TokenData
    public let light: RangeVariant
    public let bg: TokenData
    public let chroma: TokenData
}

public struct RangeVariant: Codable {
    public let bg: TokenData
    public let chroma: TokenData
    public let border: TokenData
}

// MARK: - Link
public struct Link: Codable {
    public let `default`: TokenData
    public let muted: TokenData
    public let contrast: TokenData
    public let accent: TokenData
    public let heading: TokenData
}

// MARK: - Overhung
public struct Overhung: Codable {
    public let primary: OverhungVariant
    public let secondary: OverhungVariant
}

public struct OverhungVariant: Codable {
    public let bg: TokenData
    public let chroma: TokenData
    public let border: TokenData
    public let color: TokenData
}

// MARK: - Opacity
public struct Opacity: Codable {
    public  let control: OpacityControl
    public  let content: OpacityContent
    public  let chevrone: OpacityChevrone
    public  let overhung: OpacityOverhung
}

public struct OpacityControl: Codable {
    public let disabled: TokenData
    public let enabled: TokenData
}

public struct OpacityContent: Codable {
    public let handleOpacity: TokenData
    public let placeholder: TokenData
    public let textareaHandle: TokenData

    enum CodingKeys: String, CodingKey {
        case handleOpacity = "handle-opacity"
        case placeholder
        case textareaHandle = "textarea-handle"
    }
}

public struct OpacityChevrone: Codable {
    public let expand: TokenData
    public let shrink: TokenData
}

public struct OpacityOverhung: Codable {
    public let secondary: TokenData
}

// MARK: - Areabutton
public struct Areabutton: Codable {
    public let `default`: TokenData
    public let muted: TokenData
    public let contrast: TokenData
}

// MARK: - Rating
public struct Rating: Codable {
    public let selected: RatingVariant
    public let unselected: RatingVariant
}

public struct RatingVariant: Codable {
    public let bg: TokenData
    public let chroma: TokenData
    public let border: TokenData
    public let color: TokenData
}

// MARK: - Variation
public struct Variation: Codable {
    public let selected: VariationVariant
    public let unselected: VariationVariant
    public let intemedian: VariationVariant
}

public struct VariationVariant: Codable {
    public let bg: TokenData
    public let border: TokenData
    public let color: TokenData
    public let chroma: TokenData
}

// MARK: - List
public struct List: Codable {
    public let selected: ListVariant
    public let unselected: ListVariant
    public let unselectedTransparent: ListVariant
    public let unselectedActual: ListVariant
    public let selectedSecondary: ListVariant

    enum CodingKeys: String, CodingKey {
        case selected, unselected
        case unselectedTransparent = "unselected-transparent"
        case unselectedActual = "unselected-actual"
        case selectedSecondary = "selected-secondary"
    }
}

public struct ListVariant: Codable {
    public let description: TokenData?
    public let iconCheck: TokenData?
    public let bg: TokenData
    public let border: TokenData
    public let color: TokenData
    public let chevrone: TokenData?
    public let placehold: TokenData?

    enum CodingKeys: String, CodingKey {
        case description, bg, border, color, chevrone, placehold
        case iconCheck = "icon-check"
    }
}

// MARK: - Tsar Button
public struct TsarButton: Codable {
    public let rich: ButtonVariant
    public let faded: ButtonVariant
    public let outline: ButtonVariant
}

// MARK: - Tsar Check Radio
public struct TsarCheckRadio: Codable {
    public let rich: CheckRadioVariant
    public let faded: CheckRadioVariant
    public let outline: CheckRadioVariant
}

