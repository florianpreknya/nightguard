//
//  Colors.swift
//  nightguard
//
//  Created by Florian Preknya on 2/1/19.
//  Copyright © 2019 private. All rights reserved.
//

import UIKit

/// Definition of all the colors used in the app
extension UIColor {
    
    struct App {
        
        // Phone app colors
        #if os(iOS)
        
        // Preferences/Alarms screen colors
        struct Preferences {
            static let text = UIColor.white
            static let detailText = UIColor.lightGray
            static let placeholderText = UIColor.lightGray
            static let headerText = UIColor.gray
            static let footerText = UIColor.gray
            static let background = UIColor(netHex: 0x171717)
            static let rowBackground = UIColor(netHex: 0x1C1C1E)
            static let selectedRowBackground = UIColor(netHex: 0x313131)
            static let separator = UIColor(netHex: 0x3F3F3F)
            static let tint = UIColor.white //UIColor(netHex: 0xFE9500)
        }
        
        #endif
        
        struct Loop {
            static let fresh = UIColor(red: 76 / 255, green: 217 / 255, blue: 100 / 255, alpha: 1)
            static let aging = UIColor(red: 1, green: 204 / 255, blue: 0, alpha: 1)
            static let stale = UIColor(red: 1, green: 59 / 255, blue: 48 / 255, alpha: 1)
            static let unknown = UIColor(red: 198 / 255, green: 199 / 255, blue: 201 / 255, alpha: 1)
        }
    }
}
