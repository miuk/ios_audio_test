//
//  SpectrumProvider.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/02.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation

class SpectrumProvider : DataProvider {
    
    var fft = FFT(512)
    var count = 0
    
    override func convert(_ src: [Double]) -> [Double] {
        count += 1
        let spec = fft.fft(src)
        let dst = spec.map { (x) -> Double in return (x > 0) ? log10(x) * 20 : 0 }
        return dst
    }
    
    func changeSize(_ n: Int) {
        fft.changeSize(n)
    }
}
