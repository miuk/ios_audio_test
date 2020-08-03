//
//  AudioIn.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/07/27.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation
import AVFoundation
import AudioUnit

class AudioIn {
    
    private var audioUnit: AudioUnit?
    private var bufferList: AudioBufferList?

    private var sampleRate = 8000
    private var samplePeriodMSec = 100
    private var samplePeriodNumPoints = 0
    private var sampleBuffer = [Double]()
    private var bRecording = false
    
    private var updaters = [AudioInUpdater]()
    
    func addUpdater(_ updater: AudioInUpdater) {
        updaters.append(updater)
    }

    /// 初期化
    init () {
        samplePeriodNumPoints = AudioIn.calcSampleNumPoints(sampleRate, samplePeriodMSec)
        prepareAudioUnit()
    }

    func changeSampleRate(_ value: Int) {
        if value == sampleRate {
            return
        }
        let bStart = bRecording
        stop()
        AudioUnitUninitialize(audioUnit!)
        sampleRate = value
        samplePeriodNumPoints = AudioIn.calcSampleNumPoints(sampleRate, samplePeriodMSec)
        prepareAudioUnit()
        sampleBuffer = [Double]()
        if bStart {
            start()
        }
    }
    
    func changeSamplePeriodMSec(_ value: Int) {
        if value == samplePeriodMSec {
            return
        }
        samplePeriodMSec = value
        samplePeriodNumPoints = AudioIn.calcSampleNumPoints(sampleRate, samplePeriodMSec)
    }
    
    static func calcSampleNumPoints(_ sampleRate: Int, _ samplePeriodMSec: Int) -> Int {
        let value = sampleRate * samplePeriodMSec / 1000
        return value
    }
    
    func update(_ data: UnsafeMutablePointer<Float>, _ len: UInt32) {
        sampleBuffer.append(contentsOf: (0..<Int(len)).map { (i) -> Double in return Double(data[i]) })
        while sampleBuffer.count >= samplePeriodNumPoints {
            let dst = Array(sampleBuffer[0 ..< samplePeriodNumPoints])
            for updater in updaters {
                updater.update(dst)
            }
            sampleBuffer.removeSubrange(0 ..< samplePeriodNumPoints)
        }
    }
    /// Audio Unitを使用する準備をする
    func prepareAudioUnit() {
        
        // RemoteIO AudioUnitのAudioComponentDescriptionを作成
        var acd = AudioComponentDescription()
        acd.componentType = kAudioUnitType_Output // カテゴリの指定
        acd.componentSubType = kAudioUnitSubType_RemoteIO // 名前の指定
        acd.componentManufacturer = kAudioUnitManufacturer_Apple // ベンダー名
        acd.componentFlags = 0 // 使用しない
        acd.componentFlagsMask = 0 // 使用しない
        
        // Audio Component の定義を取得
        let component: AudioComponent! = AudioComponentFindNext(nil, &acd)
        // Audio Component をインスタンス化
        AudioComponentInstanceNew(component, &audioUnit)

        // RemoteIO のマイクを有効にする
        var enable: UInt32 = 1
        AudioUnitSetProperty(audioUnit!
                            , kAudioOutputUnitProperty_EnableIO
                            , kAudioUnitScope_Input
                            , 1 // Remote Input
                            , &enable
                            , UInt32(MemoryLayout<UInt32>.size))
        
        // マイクから取り出すデータフォーマット
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1) else { return }
        AudioUnitSetProperty(audioUnit!
                            , kAudioUnitProperty_StreamFormat
                            , kAudioUnitScope_Output
                            , 1 // Remote Input
                            , fmt.streamDescription
                            , UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        
        // AURenderCallbackStruct構造体の作成
        let ref: UnsafeMutableRawPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var callbackStruct: AURenderCallbackStruct = AURenderCallbackStruct(
            inputProc: recordingCallback, // コールバック関数の名前
            inputProcRefCon: ref // コールバック関数内で参照するデータ
        )

        // コールバック関数の設定
        AudioUnitSetProperty(audioUnit!
                            , kAudioOutputUnitProperty_SetInputCallback
                            , kAudioUnitScope_Global
                            , 1
                            , &callbackStruct
                            , UInt32(MemoryLayout<AURenderCallbackStruct>.size))

        // データ取り出しに使う AudioBufferList の設定
        bufferList = AudioBufferList(
            mNumberBuffers: 1
            , mBuffers: AudioBuffer(
                mNumberChannels: fmt.channelCount
                , mDataByteSize: fmt.streamDescription.pointee.mBytesPerFrame
                , mData: nil))
        
        AudioUnitInitialize(audioUnit!)
     }
    
    func record(
         ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
         inTimeStamp: UnsafePointer<AudioTimeStamp>,
         inBusNumber: UInt32,
         inNumberFrames: UInt32,
         ioData: UnsafeMutablePointer<AudioBufferList>?
    ) -> OSStatus {
        AudioUnitRender(audioUnit!, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList!)
        let inputDataPtr = UnsafeMutableAudioBufferListPointer(&bufferList!)
        let mBuffers: AudioBuffer = inputDataPtr[0]
        let bufferPtr = UnsafeMutableRawPointer(mBuffers.mData)
        if let bptr = bufferPtr {
            let dataArray = bptr.assumingMemoryBound(to: Float.self)
            update(dataArray, inNumberFrames)
        }
        return noErr
    }

    // コールバック関数
    let recordingCallback: AURenderCallback = {(
        inRefCon: UnsafeMutableRawPointer,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrames: UInt32,
        ioData: UnsafeMutablePointer<AudioBufferList>?
    ) -> OSStatus in
        let my:AudioIn = Unmanaged<AudioIn>.fromOpaque(inRefCon).takeUnretainedValue()
        return my.record(ioActionFlags: ioActionFlags, inTimeStamp: inTimeStamp, inBusNumber: inBusNumber, inNumberFrames: inNumberFrames, ioData: ioData)
    }

    /// 取り込みスタート
    func start() {
        if bRecording {
            return
        }
        AudioOutputUnitStart(audioUnit!)
        bRecording = true
    }

    /// 取り込みストップ
    func stop() {
        if !bRecording {
            return
        }
        AudioOutputUnitStop(audioUnit!)
        bRecording = false
    }

    /// Audio Unitの破棄
    func dispose() {
        stop()
        AudioUnitUninitialize(audioUnit!)
    }
}

