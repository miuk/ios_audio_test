//
//  SingleTone.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/07/26.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import SwiftUI

struct SingleToneView: View {

    @State var volume = 0.5
    @State var frequency = 440.0
    @State var octave = 0
    @State var soundOn = false

    let notes = Notes()
    @State var note = "A"
    @State var lastOctave = 0
    let audioPlay = AudioPlay()

    var body: some View {
        VStack {
            HStack {
                Text("Volume")
                Text("\(volume)")
                Spacer()
            }
            Slider(value: Binding(
                get: {
                    self.volume
                },
                set: { (newValue) in
                    self.volume = newValue
                    self.audioPlay.changeVolume(value: newValue)
                }), in: 0...1)
            HStack {
                Text("Frequency")
                Text("\(frequency)")
                Spacer()
            }
            Slider(value: Binding(
                get: {
                    self.frequency
                },
                set: { (newValue) in
                    self.frequency = newValue
                    self.audioPlay.frequency = Float32(newValue)
                }), in: 100...10000)
            HStack {
                Spacer()
                ForEach(0..<notes.blackNotes.count) { i in
                    Button(action: {
                        self.onClick(note: self.notes.blackNotes[i])
                    }) {
                        Text(self.notes.blackNotes[i])
                    }
                    Spacer()
                }
            }
            HStack {
                Spacer()
                ForEach(0..<notes.whiteNotes.count) { i in
                    Button(action: {
                        self.onClick(note: self.notes.whiteNotes[i])
                    }) {
                        Text(self.notes.whiteNotes[i])
                    }
                    Spacer()
                }
            }
            HStack {
                Text("Octave")
                Picker(selection: $octave, label: Text("Octave")) {
                    Text("-2").tag(-2)
                    Text("-1").tag(-1)
                    Text("0").tag(0)
                    Text("+1").tag(1)
                    Text("+2").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onReceive([self.octave].publisher.first()) { (value) in
                    if self.lastOctave != value {
                        self.lastOctave = value
                        self.changeFrequency()
                    }
                }
Spacer()
            }
            Button(action: {
                self.soundOn.toggle()
                if (self.soundOn) {
                    self.audioPlay.frequency = Float(self.frequency)
                    self.audioPlay.changeVolume(value: self.volume)
                    self.audioPlay.start()
                } else {
                    self.audioPlay.stop()
                }
            }) {
                Text("ON")
            }

            Spacer()
        }
    }
    
    func onClick(note: String) {
        self.note = note
        changeFrequency()
    }
    
    func changeFrequency() {
        frequency = notes.calcFrequency(note, octave)
        audioPlay.frequency = Float(frequency)
        print("changeFrequency \(frequency)")
    }
}

struct SingleTone_Previews: PreviewProvider {
    static var previews: some View {
        SingleToneView()
    }
}
