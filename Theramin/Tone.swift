//
//  Tone.swift
//  Theramin
//
//  Created by Andy Cho on 10/10/22.
//

import Foundation

/**
 * See here for reference for the frequencies:
 * https://pages.mtu.edu/~suits/notefreqs.html
 **/

enum Tone {
    case a4
    case a5
    case a6

    func frequency() -> Double {
        switch self {
        case .a4:
            return 440
        case .a5:
            return 880
        case .a6:
            return 1760
        }
    }
}
