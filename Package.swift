//
//  File.swift
//  
//
//  Created by Semen Kologrivov on 20.01.2023.
//

import UIKit
import SQExtensions

public class SQCoreGraphics: NSObject {

    @objc
    public func icBack() -> UIImage {
        guard let icon = UIImage(
            named: "icBack",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icBack not found in resources")
        }

        return icon
    }

    @objc
    public func icClose() -> UIImage {
        guard let icon = UIImage(
            named: "icClose",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icClose not found in resources")
        }

        return icon
    }

    @objc
    public func icCheckboxUnchecked() -> UIImage {
        guard let icon = UIImage(
            named: "icCheckboxUnchecked",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icCheckboxUnchecked not found in resources")
        }

        return icon
    }

    @objc
    public func icCheckboxChecked() -> UIImage {
        guard let icon = UIImage(
            named: "icCheckboxChecked",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icCheckboxChecked not found in resources")
        }

        return icon
    }

    @objc
    public func icCheck() -> UIImage {
        guard let icon = UIImage(
            named: "icCheck",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icCheck not found in resources")
        }

        return icon
    }

    @objc
    public func icDropdownPrimary() -> UIImage {
        guard let icon = UIImage(
            named: "icDropdownPrimary",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icDropdownPrimary not found in resources")
        }

        return icon
    }
    
    @objc
    public func icDropdownSecondary() -> UIImage {
        guard let icon = UIImage(
            named: "icDropdownSecondary",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icDropdownSecondary not found in resources")
        }

        return icon
    }

    @objc
    public func icClear() -> UIImage {
        guard let icon = UIImage(
            named: "icClear",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icClear not found in resources")
        }

        return icon
    }

    @objc
    public func icArrowRight() -> UIImage {
        guard let icon = UIImage(
            named: "icArrowRight",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icArrowRight not found in resources")
        }

        return icon
    }

    @objc
    public func icMinusDefault() -> UIImage {
        guard let icon = UIImage(
            named: "icMinusDefault",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icMinusDefault not found in resources")
        }

        return icon
    }

    @objc
    public func icMinusDisable() -> UIImage {
        guard let icon = UIImage(
            named: "icMinusDisable",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icMinusDisable not found in resources")
        }

        return icon
    }

    @objc
    public func icPlusDefault() -> UIImage {
        guard let icon = UIImage(
            named: "icPlusDefault",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icPlusDefault not found in resources")
        }

        return icon
    }

    @objc
    public func icPlusDisable() -> UIImage {
        guard let icon = UIImage(
            named: "icPlusDisable",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icPlusDisable not found in resources")
        }

        return icon
    }
    
    @objc
    public func icListSettings() -> UIImage {
        guard let icon = UIImage(
            named: "icListSettings",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icListSettings not found in resources")
        }

        return icon
    }

    @objc
    public func icArrowRightMini() -> UIImage {
        guard let icon = UIImage(
            named: "icArrowRightMini",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icArrowRightMini not found in resources")
        }

        return icon
    }

    @objc
    public func icHeartElipse() -> UIImage {
        guard let icon = UIImage(
            named: "icHeartElipse",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icHeartElipse not found in resources")
        }

        return icon
    }

    @objc
    public func icRadioUnselected() -> UIImage {
        guard let icon = UIImage(
            named: "icRadioUnselected",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icRadioUnselected not found in resources")
        }

        return icon
    }

    @objc
    public func icRadioSelected() -> UIImage {
        guard let icon = UIImage(
            named: "icRadioSelected",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icRadioSelected not found in resources")
        }

        return icon
    }

    @objc
    public func icRadioDisabled() -> UIImage {
        guard let icon = UIImage(
            named: "icRadioDisabled",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icRadioDisabled not found in resources")
        }

        return icon
    }

    @objc
    public func icBackElipse() -> UIImage {
        guard let icon = UIImage(
            named: "icBackElipse",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icBackElipse not found in resources")
        }

        return icon
    }

    @objc
    public func icCloseElipse() -> UIImage {
        guard let icon = UIImage(
            named: "icCloseElipse",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icCloseElipse not found in resources")
        }

        return icon
    }
    
    @objc
    public func icHandler() -> UIImage {
        guard let icon = UIImage(
            named: "icHandler",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icHandler not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icMore() -> UIImage {
        guard let icon = UIImage(
            named: "icMore",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icMore not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icFavoriteSelected() -> UIImage {
        guard let icon = UIImage(
            named: "icFavoriteSelected",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icFavoriteSelected not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icFavoriteUnselected() -> UIImage {
        guard let icon = UIImage(
            named: "icFavoriteUnselected",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icFavoriteUnselected not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icDelete() -> UIImage {
        guard let icon = UIImage(
            named: "icDelete",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icDelete not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func imgHeaderLogo() -> UIImage {
        guard let icon = UIImage(
            named: "imgHeaderLogo",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("imgHeaderLogo not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func imgSplashLogoLarge() -> UIImage {
        guard let icon = UIImage(
            named: "imgSplashLogoLarge",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("imgSplashLogoLarge not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func imgSplashLogoSmall() -> UIImage {
        guard let icon = UIImage(
            named: "imgSplashLogoSmall",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("imgSplashLogoSmall not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icMarkUnselected() -> UIImage {
        guard let icon = UIImage(
            named: "icMarkUnselected",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icMarkUnselected not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icMarkSelected() -> UIImage {
        guard let icon = UIImage(
            named: "icMarkSelected",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icMarkSelected not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icCluster() -> UIImage {
        guard let icon = UIImage(
            named: "icCluster",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icCluster not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icUserPosition() -> UIImage {
        guard let icon = UIImage(
            named: "icUserPosition",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icUserPosition not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icLocation() -> UIImage {
        guard let icon = UIImage(
            named: "icLocation",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icLocation not found in resources")
        }
        
        return icon
    }
    
    @objc
    public func icCloseMini() -> UIImage {
        guard let icon = UIImage(
            named: "icCloseMini",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icCloseMini not found in resources")
        }

        return icon
    }
    
//    @objc
//    public func icNotification() -> UIImage {
//        guard let icon = UIImage(
//            named: "icNotification",
//            in: .main,
//            compatibleWith: nil
//        ) else {
//            fatalError("icNotification not found in resources")
//        }
//
//        return icon
//    }
    
    @objc
    public func icNotificationMini() -> UIImage {
        guard let icon = UIImage(
            named: "icNotificationMini",
            in: .main,
            compatibleWith: nil
        ) else {
            fatalError("icNotificationMini not found in resources")
        }

        return icon
    }

}

extension SQCoreGraphics: BundleAppearance {

    public func invalidResources() -> [String] {
        SQCoreGraphics.sq.getAllMethods()
            .filter({ $0 != "init" })
            .filter({ functionName in
                UIImage(
                    named: functionName,
                    in: .main,
                    compatibleWith: nil
                ) == nil
            })
    }
}
