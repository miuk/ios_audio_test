//
//  ContentView.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/07/26.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: SingleToneView()) {
                    Text("Single Tone")
                }
                NavigationLink(destination: AudioInView()) {
                    Text("Audio In")
                }
            }
        .navigationBarTitle(Text("Audio Test"))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
