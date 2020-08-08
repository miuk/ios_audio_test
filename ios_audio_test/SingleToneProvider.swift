//
//  SingleToneProvider.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/05.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation

class SingleToneProvider : AudioPlayDataProvider {
    
    var sampleRate = 44100.0
    var frequency = 440.0
    private var frame = 0
    
    func getAudioPlayData(_ buffer: UnsafeMutablePointer<Float>, _ len: UInt32) {
        for i in 0 ..< Int(len) {
            buffer[i] = Float(sin(Double(frame) * frequency * 2.0 * .pi / sampleRate))
            frame += 1
        }
    }
    
    
}
