/// Process asset name
public protocol AssetNameProcessable {
    
    var nameReplaceRegexp: String? { get }
    var nameValidateRegexp: String? { get }
    var nameStyle: NameStyle? { get }
    
    func isNameValid(_ name: String) -> Bool
    func normalizeName(_ name: String, style: NameStyle) -> String
}

public extension AssetNameProcessable {
    
    func isNameValid(_ name: String) -> Bool {
        if let regexp = nameValidateRegexp {
            return name.range(of: regexp, options: .regularExpression) != nil
        } else {
            return true
        }
    }
    
    func normalizeName(_ name: String, style: NameStyle) -> String {
        switch style {
        case .camelCase:
            return name.lowerCamelCased()
        case .snakeCase:
            return name.snakeCased()
        }
    }
}

public protocol AssetsProcessable: AssetNameProcessable {
    associatedtype AssetType: Asset
    typealias ProcessingPairResult = Result<[AssetPair<AssetType>], ErrorGroup>
    typealias ProcessingResult = Result<[AssetType], ErrorGroup>
    
    var platform: Platform { get }
    
    func process(baseProject: [AssetType], targetProject: [AssetType]?) -> ProcessingPairResult
    func process(assets: [AssetType]) -> ProcessingResult
}

public struct ColorsProcessor: AssetsProcessable {
    public typealias AssetType = Color
    
    public let platform: Platform
    public let nameValidateRegexp: String?
    public let nameReplaceRegexp: String?
    public let nameStyle: NameStyle?
    
    public init(platform: Platform, nameValidateRegexp: String?, nameReplaceRegexp: String?, nameStyle: NameStyle?) {
        self.platform = platform
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
    }
}

public struct ImagesProcessor: AssetsProcessable {
    public typealias AssetType = ImagePack

    public let platform: Platform
    public let nameValidateRegexp: String?
    public let nameReplaceRegexp: String?
    public let nameStyle: NameStyle?
    
    public init(platform: Platform, nameValidateRegexp: String? = nil, nameReplaceRegexp: String? = nil, nameStyle: NameStyle?) {
        self.platform = platform
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
    }
}

public extension AssetsProcessable {

    func process(baseProject: [AssetType], targetProject: [AssetType]?) -> ProcessingPairResult {
        if let targetProject = targetProject {
            return validateAndMakePairs(
                baseProject: normalizeAssetName(assets: baseProject),
                targetProject: normalizeAssetName(assets: targetProject)
            )
        } else {
            return validateAndMakePairs(
                light: normalizeAssetName(assets: baseProject)
            )
        }
    }
    
    func process(assets: [AssetType]) -> ProcessingResult {
        let assets = normalizeAssetName(assets: assets)
        return validateAndProcess(assets: assets)
    }
    
    private func validateAndProcess(assets: [AssetType]) -> ProcessingResult {
        var errors = ErrorGroup()

        // foundDuplicate
        var set: Set<AssetType> = []
        assets.forEach { asset in

            // badName
            if !isNameValid(asset.name) {
                errors.all.append(AssetsValidatorError.badName(name: asset.name))
            }

            switch set.insert(asset) {
            case (true, _):
                break // ok
            case (false, let oldMember): // already exists
                errors.all.append(AssetsValidatorError.foundDuplicate(assetName: oldMember.name))
            }
        }

        if !errors.all.isEmpty {
            return .failure(errors)
        }
        
        let assets = set
            .sorted { $0.name < $1.name }
            .filter { $0.platform == nil || $0.platform == platform }
            .map { asset -> AssetType in
                var newAsset = asset
                if let replaceRegExp = nameReplaceRegexp, let regexp = nameValidateRegexp {
                    newAsset.name = self.replace(newAsset.name, matchRegExp: regexp, replaceRegExp: replaceRegExp)
                }
                if let style = nameStyle {
                    newAsset.name = self.normalizeName(newAsset.name, style: style)
                }
                return newAsset
            }
        
        return .success(assets)
    }
    
    private func replace(_ name: String, matchRegExp: String, replaceRegExp: String) -> String {
        let result = name.replace(matchRegExp) { array in
            replaceRegExp.replace(#"\$(\d)"#) {
                let index = Int($0[1])!
                return array[index]
            }
        }
        
        return result
    }

    private func validateAndMakePairs(light: [AssetType]) -> ProcessingPairResult {
        var errors = ErrorGroup()

        // foundDuplicate
        var lightSet: Set<AssetType> = []
        light.forEach { asset in

            // badName
            if !isNameValid(asset.name) {
                errors.all.append(AssetsValidatorError.badName(name: asset.name))
            }

            switch lightSet.insert(asset) {
            case (true, _):
                break // ok
            case (false, let oldMember): // already exists
                errors.all.append(AssetsValidatorError.foundDuplicate(assetName: oldMember.name))
            }
        }

        if !errors.all.isEmpty {
            return .failure(errors)
        }

        let pairs = makeSortedAssetPairs(lightSet: lightSet)
        return .success(pairs)
    }

    private func validateAndMakePairs(
        baseProject: [AssetType],
        targetProject: [AssetType]
    ) -> ProcessingPairResult {
        var errors = ErrorGroup()

        // 1. countMismatch
        if baseProject.count != targetProject.count {
            errors.all.append(AssetsValidatorError.countMismatch(light: baseProject.count, dark: targetProject.count))
        }

        // 2. foundDuplicate
        var baseProjectSet: Set<AssetType> = []
        baseProject.forEach { asset in

            // badName
            if !isNameValid(asset.name) {
                errors.all.append(AssetsValidatorError.badName(name: asset.name))
            }

            switch baseProjectSet.insert(asset) {
            case (true, _):
                break // ok
            case (false, let oldMember): // already exists
                errors.all.append(AssetsValidatorError.foundDuplicate(assetName: oldMember.name))
            }
        }

        var targetProjectSet: Set<AssetType> = []
        targetProject.forEach { asset in
            switch targetProjectSet.insert(asset) {
            case (true, _):
                break // ok
            case (false, let oldMember): // already exists
                errors.all.append(AssetsValidatorError.foundDuplicate(assetName: oldMember.name))
            }
        }

        // 3. lightAssetNotFoundInDarkPalette

        let baseProjectElements = baseProjectSet.subtracting(targetProjectSet)
        if !baseProjectElements.isEmpty {
            errors.all.append(AssetsValidatorError.lightAssetsNotFoundInDarkPalette(assets: baseProjectElements.map { $0.name }))
        }

        // 4. darkAssetNotFoundInLightPalette
        let targetProjectElements = targetProjectSet.subtracting(baseProjectSet)
        if !targetProjectElements.isEmpty {
            errors.all.append(AssetsValidatorError.darkAssetsNotFoundInLightPalette(assets: targetProjectElements.map { $0.name }))
        }

        // 5. descriptionMismatch
        baseProjectSet.forEach { asset in
            if let platform = asset.platform {
                let target = targetProjectSet.first(where: { $0.name == asset.name })
                if target?.platform != platform {
                    errors.all.append(AssetsValidatorError.descriptionMismatch(
                        assetName: asset.name,
                        light: platform.rawValue,
                        dark: target?.platform?.rawValue ?? "")
                    )
                }
            }
        }

        if !errors.all.isEmpty {
            return .failure(errors)
        }

        if !targetProjectSet.isEmpty {
            return .success(makeSortedAssetPairs(lightSet: targetProjectSet))
        }

        return .success(makeSortedAssetPairs(lightSet: baseProjectSet))
    }
    
    private func makeSortedAssetPairs(lightSet: Set<AssetType>) -> [AssetPair<Self.AssetType>] {
        return lightSet
            .sorted { $0.name < $1.name }
            .filter { $0.platform == nil || $0.platform == platform }
            .map { lightAsset -> AssetPair<AssetType> in

                var newLightAsset = lightAsset

                if let replaceRegExp = nameReplaceRegexp, let regexp = nameValidateRegexp {
                    newLightAsset.name = self.replace(newLightAsset.name, matchRegExp: regexp, replaceRegExp: replaceRegExp)
                }
                
                if let style = nameStyle {
                    newLightAsset.name = self.normalizeName(newLightAsset.name, style: style)
                }

                return AssetPair(light: newLightAsset, dark: nil)
            }
    }

    private func makeSortedAssetPairs(
        lightSet: Set<AssetType>,
        darkSet: Set<AssetType>) -> [AssetPair<Self.AssetType>] {

        let lightColors = lightSet
            .filter { $0.platform == platform || $0.platform == nil }
            .sorted { $0.name < $1.name }

        let darkColors = darkSet
            .filter { $0.platform == platform || $0.platform == nil }
            .sorted { $0.name < $1.name }

        let zipResult = zip(lightColors, darkColors)

        return zipResult
            .map { lightAsset, darkAsset in

                var newLightAsset = lightAsset
                var newDarkAsset = darkAsset

                if let replaceRegExp = nameReplaceRegexp, let regexp = nameValidateRegexp {
                    newLightAsset.name = self.replace(newLightAsset.name, matchRegExp: regexp, replaceRegExp: replaceRegExp)
                    newDarkAsset.name = self.replace(newDarkAsset.name, matchRegExp: regexp, replaceRegExp: replaceRegExp)
                }
                
                if let style = nameStyle {
                    newLightAsset.name = self.normalizeName(newLightAsset.name, style: style)
                    newDarkAsset.name = self.normalizeName(newDarkAsset.name, style: style)
                }

                return AssetPair(light: newLightAsset, dark: newDarkAsset)
            }
    }
    
    /// Normalizes asset name by replacing "/" with "_" and by removing duplication (e.g. "color/color" becomes "color"
    private func normalizeAssetName(assets: [AssetType]) -> [AssetType] {
        assets.map { asset -> AssetType in
            
            var renamedAsset = asset
            renamedAsset.name = renamedAsset.name.replacingOccurrences(of: "/", with: "_")

            return renamedAsset
        }
    }
}
