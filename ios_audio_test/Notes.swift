//
//  Notes.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/02.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation

class Notes {

    let blackNotes = ["C#", "#D", "F#", "G#", "A#"]
    let whiteNotes = ["C", "D", "E", "F", "G", "A", "B", "C2"]
    let noteIndexMap: [String:Int] = [
        "C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4,
        "F#": -3, "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2, "C2": 3
        ]

    func calcFrequency(_ note: String, _ octave: Int) -> Double {
        let base = 440.0 * pow(2.0, Double(octave))
        guard let idx = noteIndexMap[note] else { return 0 }
        let freq = base * pow(pow(2.0, Double(idx)), 1.0 / 12.0)
        return freq
    }

}
