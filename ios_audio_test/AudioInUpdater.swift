//
//  AudioInUpdater.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/07/31.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation

protocol AudioInUpdater {
    func update(_ data: [Double])
}
