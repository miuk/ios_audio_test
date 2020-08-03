//
//  AudioIn.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/07/26.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import SwiftUI

struct AudioInView: View {
    
    @State var bAudioIn = false
    @State var msg = ""
    @State var sampleRate = 8000
    @State var samplePeriodMSec = 100
    @ObservedObject var wave = DataProvider()
    @ObservedObject var spectrum = SpectrumProvider()
    @State var lastSampleRate = 8000
    @State var lastSamplePeriodMSec = 100
    
    let audioIn = AudioIn()
    
    var body: some View {
        VStack {
            Graph(values: $wave.data, minValue: -1.0, maxValue: 1.0)
                .frame(height: 200)
            Graph(values: $spectrum.data, minValue: -15.0, maxValue: 0.0)
                .frame(height: 200)
            HStack {
                Text("Rate")
                Picker("8k", selection: $sampleRate) {
                    Text("8k").tag(8000)
                    Text("16k").tag(16000)
                    Text("32k").tag(32000)
                    Text("44.1k").tag(44100)
                    Text("48k").tag(48000)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onReceive([self.sampleRate].publisher.first()) { (value) in
                    if self.lastSampleRate != value {
                        self.lastSampleRate = value
                        self.changeSampleRate()
                    }
                }
                Spacer()
            }
            HStack {
                Text("Size (ms)")
                Picker("100", selection: $samplePeriodMSec) {
                    Text("10").tag(10)
                    Text("20").tag(20)
                    Text("50").tag(50)
                    Text("100").tag(100)
                }
                .pickerStyle(SegmentedPickerStyle())
                .onReceive([self.samplePeriodMSec].publisher.first()) { (value) in
                    if self.lastSamplePeriodMSec != value {
                        self.lastSamplePeriodMSec = value
                        self.changeSamplePeriodMSec()
                    }
                }
                Spacer()
            }
            Button(action: {
                if (self.bAudioIn) {
                    self.audioIn.stop()
                    self.bAudioIn = false
                } else {
                    self.audioIn.start()
                    self.bAudioIn = true
                }
            }) { Text("ON") }
            Text("\(msg)")
            Spacer()
        }
    }
    
    init() {
        audioIn.changeSampleRate(sampleRate)
        audioIn.changeSamplePeriodMSec(samplePeriodMSec)
        spectrum.changeSize(AudioIn.calcSampleNumPoints(sampleRate, samplePeriodMSec))
        audioIn.addUpdater(wave)
        audioIn.addUpdater(spectrum)
    }
    
    func changeSampleRate() {
        audioIn.changeSampleRate(sampleRate)
    }
    
    func changeSamplePeriodMSec() {
        audioIn.changeSamplePeriodMSec(samplePeriodMSec)
        spectrum.changeSize(AudioIn.calcSampleNumPoints(sampleRate, samplePeriodMSec))
    }
}

struct AudioIn_Previews: PreviewProvider {
    static var previews: some View {
        AudioInView()
    }
}
