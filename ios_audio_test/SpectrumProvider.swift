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
    
    override func convert(_ src: [Float]) -> [Float] {
        
        let spec = fft.fft((0 ..< src.count).map { (i) -> Double in Double(src[i])} )
        let dst = spec.map { (x) -> Float in return (x > 0) ? Float(log10(x)) * 20 : 0 }
        return dst
    }
    
    func changeSize(_ n: Int) {
        fft.changeSize(n)
    }
}
