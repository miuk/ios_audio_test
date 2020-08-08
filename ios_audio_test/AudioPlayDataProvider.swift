//
//  AudioPlayDataProvider.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/05.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation

protocol AudioPlayDataProvider {
    func getAudioPlayData(_ buffer: UnsafeMutablePointer<Float>, _ len: UInt32)
}
