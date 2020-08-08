//
//  AudioPlay.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/07/26.
//  Copyright © 2020 Kenji Miura. All rights resrved.
//

import Foundation
import AVFoundation

class AudioPlay {
    
    private var auGraph: AUGraph?
    private var remoteIOUnit: AudioUnit?
    private var mixerUnit: AudioUnit?

    private var sampleRate = 44100
    private var bPlaying = false
    private var dataProvider: AudioPlayDataProvider?

    /// 初期化
    init (_ sampleRate: Int) {
        self.sampleRate = sampleRate
        prepareAudioUnit()
    }

    func setDataProvider(_ value: AudioPlayDataProvider) {
        dataProvider = value
    }

    /// Audio Unitを使用する準備をする
    func prepareAudioUnit() {
        
        // AUGraph を準備
        NewAUGraph(&auGraph)
        AUGraphOpen(auGraph!)
        
        // RemoteIO AudioUnitのAudioComponentDescriptionを作成
        var acd = AudioComponentDescription()
        acd.componentType = kAudioUnitType_Output // カテゴリの指定
        acd.componentSubType = kAudioUnitSubType_RemoteIO // 名前の指定
        acd.componentManufacturer = kAudioUnitManufacturer_Apple // ベンダー名
        acd.componentFlags = 0 // 使用しない
        acd.componentFlagsMask = 0 // 使用しない
        
        // AUGraph に Remote IO のノードを追加する
        var remoteIONode: AUNode = 0
        AUGraphAddNode(auGraph!, &acd, &remoteIONode)
        
        // MultiChannelMixer の AudioComponentDescriptionを作成
        acd.componentType = kAudioUnitType_Mixer
        acd.componentSubType = kAudioUnitSubType_MultiChannelMixer

        // AUGraph に MultiChannelMixer のノードを追加する
        var mixerNode: AUNode = 0
        AUGraphAddNode(auGraph!, &acd, &mixerNode)

        // AURenderCallbackStruct構造体の作成
        let ref: UnsafeMutableRawPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var callbackStruct: AURenderCallbackStruct = AURenderCallbackStruct(
            inputProc: renderCallback, // コールバック関数の名前
            inputProcRefCon: ref // コールバック関数内で参照するデータ
        )

        // コールバック関数の設定
        AUGraphSetNodeInputCallback(auGraph!, mixerNode, 0, &callbackStruct)

        // ASBDの作成
        var asbd = AudioStreamBasicDescription()

        asbd.mSampleRate = Float64(sampleRate) // サンプリングレートの指定
        asbd.mFormatID = kAudioFormatLinearPCM // フォーマットID (リニアPCMを指定)
        asbd.mFormatFlags = kAudioFormatFlagIsFloat // フォーマットフラグの指定 (Float32形式)
        asbd.mChannelsPerFrame = 1 // チャンネル指定 (モノラル)
        asbd.mBytesPerPacket = UInt32(MemoryLayout<Float32>.size) // １パケットのバイト数
        asbd.mBytesPerFrame = UInt32(MemoryLayout<Float32>.size) // 1フレームのバイト数
        asbd.mFramesPerPacket = 1 // 1パケットのフレーム数
        asbd.mBitsPerChannel = UInt32(8 * MemoryLayout<UInt32>.size) // 1チャンネルのビット数
        asbd.mReserved = 0 // 使用しない

        // RemoteIO AudioUnitにASBDを設定
        AUGraphNodeInfo(auGraph!, remoteIONode, nil, &remoteIOUnit)
        AudioUnitSetProperty(
            remoteIOUnit!, // 対象のAudio Unit
            kAudioUnitProperty_StreamFormat, // 設定するプロパティ
            kAudioUnitScope_Input, // 入力スコープ
            0, // 出力バス
            &asbd, // プロパティに設定する値
            UInt32(MemoryLayout.size(ofValue: asbd)) // 値のデータサイズ
        )
        
        // Mixer AudioUnit に ASBD を設定
        AUGraphNodeInfo(auGraph!, mixerNode, nil, &mixerUnit)
        AudioUnitSetProperty(
            mixerUnit!, // 対象のAudio Unit
            kAudioUnitProperty_StreamFormat, // 設定するプロパティ
            kAudioUnitScope_Input, // 入力スコープ
            0, // 出力バス
            &asbd, // プロパティに設定する値
            UInt32(MemoryLayout.size(ofValue: asbd)) // 値のデータサイズ
        )

        // mixerNode (バス:0) から remoteIONode (バス:0) に接続
        AUGraphConnectNodeInput(auGraph!, mixerNode, 0, remoteIONode, 0)
        
        // AUGraph を初期化
        AUGraphInitialize(auGraph!)
    }
    
    func play(inNumberFrames: UInt32, ioData: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        // チャンネルの数分のAudioBuffer参照の取り出し
        let abl = UnsafeMutableAudioBufferListPointer(ioData)
        // フレーム数分のメモリキャパシティ
        let capacity = Int(abl[0].mDataByteSize) / MemoryLayout<Float>.size
        // バッファに値を書き込む
        if let buffer: UnsafeMutablePointer<Float> = abl[0].mData?.bindMemory(to: Float.self, capacity: capacity) {
            if let dp = dataProvider {
                dp.getAudioPlayData(buffer, inNumberFrames)
            }
        }

        return noErr

    }

    // コールバック関数
    let renderCallback: AURenderCallback = {(
        inRefCon: UnsafeMutableRawPointer,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrames: UInt32,
        ioData: UnsafeMutablePointer<AudioBufferList>?
    ) -> OSStatus in
        let my:AudioPlay = Unmanaged<AudioPlay>.fromOpaque(inRefCon).takeUnretainedValue()
        return my.play(inNumberFrames:inNumberFrames, ioData:ioData!)
    }

    /// 再生スタート
    func start() {
        if bPlaying {
            return
        }
        AUGraphStart(auGraph!)
        bPlaying = true
    }

    /// 再生ストップ
    func stop() {
        if !bPlaying {
            return
        }
        AUGraphStop(auGraph!)
        bPlaying = false
    }

    /// Audio Unitの破棄
    func dispose() {
        stop()
        AUGraphUninitialize(auGraph!)
        AUGraphClose(auGraph!)
        DisposeAUGraph(auGraph!)
    }

    func changeVolume(value: Double) {
        AudioUnitSetParameter(mixerUnit!
                            , kMultiChannelMixerParam_Volume
                            , kAudioUnitScope_Output
                            , 0
                            , AudioUnitParameterValue(value)
                            , 0)
    }
}

