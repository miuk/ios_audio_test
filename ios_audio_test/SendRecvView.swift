//
//  SendRecvView.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/04.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import SwiftUI

struct SendRecvView: View {
    
    @State var myHost = ""
    @State var myPort = ""
    @State var peerHost = ""
    @State var peerPort = ""
    @State var bStart = false
    
    private let sendRecv = SendRecv()
    private let audioIn = AudioIn()
    private let audioPlay = AudioPlay(8000)
    
    private let userDefaults = UserDefaults.standard
    
    var body: some View {
        VStack {
            HStack {
                Text("My host")
                Text("\(myHost)")
                Text("port")
                TextField("port", text: $myPort)
                Spacer()
            }
            HStack {
                Text("Peer host")
                TextField("host", text: $peerHost)
                Text("port")
                TextField("port", text: $peerPort)
                Spacer()
            }
            Button(action: {
                if self.bStart {
                    self.stop()
                } else {
                    self.start()
                }
            }) {
                Text(self.bStart ? "Stop" : "Start")
            }
            Spacer()
        }
        .onAppear {
            self.myHost = self.sendRecv.getMyIPv4Address()
            self.peerHost = self.userDefaults.object(forKey: "PeerHost") as! String
            self.peerPort = self.userDefaults.object(forKey: "PeerPort") as! String
            self.myPort = self.userDefaults.object(forKey: "MyPort") as! String
        }
    }
 
    init() {
        audioIn.changeSampleRate(8000)
        audioIn.changeSamplePeriodMSec(20)
        audioIn.addUpdater(sendRecv)
        audioPlay.setDataProvider(sendRecv)
        userDefaults.register(defaults: ["PeerHost": ""])
        userDefaults.register(defaults: ["PeerPort": ""])
        userDefaults.register(defaults: ["MyPort": ""])
    }
    
    private func start() {
        let ret = sendRecv.start(peerHost, peerPort, myPort)
        if ret.isEmpty {
            audioIn.start()
            audioPlay.start()
            userDefaults.set(peerHost, forKey: "PeerHost")
            userDefaults.set(peerPort, forKey: "PeerPort")
            userDefaults.set(myPort, forKey: "MyPort")
            bStart = true
        } else {
            myHost = ret
        }
    }
    
    private func stop() {
        audioIn.stop()
        sendRecv.stop()
        audioPlay.stop()
        bStart = false
    }
}

struct SendRecvView_Previews: PreviewProvider {
    static var previews: some View {
        SendRecvView()
    }
}
