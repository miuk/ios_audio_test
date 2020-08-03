//
//  DataProvider.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/01.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation

class DataProvider : ObservableObject, AudioInUpdater {
    
    @Published var data: [Double] = []

    func update(_ data: [Double]) {
        DispatchQueue.global().async {
            let cdata = self.convert(data)
            DispatchQueue.main.async {
                self.data = cdata
            }
        }
    }

    func convert(_ data: [Double]) -> [Double] {
        return data
    }
}
