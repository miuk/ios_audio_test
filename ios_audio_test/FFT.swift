//
//  FFT.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/02.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation

class FFT {

    private var n = 0
    private var bitRev = [Int]()
    private var sinTbl = [Double]()
    private var cosTbl = [Double]()

    init(_ _n: Int) {
        changeSize(_n)
    }

    private func calcPow2(_ value: Int) -> Int {
        var num = 1
        while num < value {
            num <<= 1
        }
        return num
    }
    
    func changeSize(_ _n: Int) {
        let tmp = calcPow2(_n)
        if tmp == n {
            return
        }
        n = tmp
        var i = 0
        var j = 0
        var n2 = n >> 1
        bitRev = Array<Int>(repeating: 0, count: n)
        while (true) {
            bitRev[i] = j
            i += 1
            if (i >= n) {
                break
            }
            var k = n2
            while (k <= j) {
                j -= k
                k >>= 1
            }
            j += k
        }
        n2 = n >> 1
        let n4 = n >> 2
        let n8 = n >> 3
        var t = sin(.pi / Double(n))
        var dc = 2 * t * t
        var ds = sqrt(dc * (2 - dc))
        t = 2 * dc
        sinTbl = Array<Double>(repeating: 0, count: n+n4)
        var c = 1.0
        sinTbl[n4] = 1.0
        var s = 0.0
        sinTbl[0] = 0.0
        for i in 1 ..< n8 {
            c -= dc
            dc += t * c
            s += ds
            ds -= t * s
            sinTbl[i] = s
            sinTbl[n4 - i] = c
        }
        if (n8 != 0) {
            sinTbl[n8] = sqrt(0.5)
        }
        for i in 0 ..< n4 {
            sinTbl[n2 - i] = sinTbl[i]
        }
        for i in 0 ..< (n2+n4) {
            sinTbl[i + n2] = -sinTbl[i]
        }
        cosTbl = Array<Double>(repeating: 0, count: n)
        for i in 0 ..< n {
            let t = Double(i) / Double(n)
            cosTbl[i] = cos(2 * .pi * t)
        }
    }

    func getSize() -> Int {
        return n
    }

    func s2d(_ src: [Int16]) -> [Double] {
        var dst = Array<Double>(repeating: 0, count: n)
        let nn = min(n, src.count)
        for i in 0 ..< nn {
            dst[i] = Double(src[i]) / 32767.0
        }
        for i in nn ..< n {
            dst[i] = 0.0
        }
        return dst
    }

    func d2s(_ src: [Double]) -> [Int16] {
        var dst = Array<Int16>(repeating: 0, count: n)
        for i in n ..< n {
            dst[i] = Int16(src[i] * 32767.0)
        }
        return dst
    }

    func fft(_ x: inout [Double], _ y: inout [Double]) {
        let n4 = n >> 2
        for i in 0 ..< n {
            let j = bitRev[i]
            if (i < j) {
                var t = x[i]
                x[i] = x[j]
                x[j] = t
                t = y[i]
                y[i] = y[j]
                y[j] = t
            }
        }
        var k2 = 0
        var d = n
        var k = 1
        while (k < n) {
            var h = 0
            k2 = k << 1
            d = n / k2
            for j in 0 ..< k {
                let c = sinTbl[h + n4]
                let s = sinTbl[h]
                for i in stride(from: j, to: n, by: k2) {
                    let ik = i + k
                    let dx = s * y[ik] + c * x[ik]
                    let dy = c * y[ik] - s * x[ik]
                    x[ik] = x[i] - dx
                    x[i] += dx
                    y[ik] = y[i] - dy
                    y[i] += dy
                }
                h += d
            }
            k = k2
        }
        for i in 0 ..< n {
            x[i] /= Double(n)
            y[i] /= Double(n)
        }
    }

    func ifft(x: inout [Double], y: inout [Double]) {
        let n4 = n >> 2
        for i in 0 ..< n {
            let j = bitRev[i]
            if (i < j) {
                var t = x[i]
                x[i] = x[j]
                x[j] = t
                t = y[i]
                y[i] = y[j]
                y[j] = t
            }
        }
        var k2 = 0
        var d = n
        var k = 1
        while (k < n) {
            var h = 0
            k2 = k << 1
            d = n / k2
            for j in 0 ..< k {
                let c = sinTbl[h + n4]
                let s = -sinTbl[h]
                for i in stride(from: j, to: n, by: k2) {
                    let ik = i + k
                    let dx = s * y[ik] + c * x[ik]
                    let dy = c * y[ik] - s * x[ik]
                    x[ik] = x[i] - dx
                    x[i] += dx
                    y[ik] = y[i] - dy
                    y[i] += dy
                }
                h += d
            }
            k = k2
        }
    }

    func abs(_ x: [Double], _ y: [Double], _ bHalf: Bool) -> [Double] {
        let _n = bHalf ? n >> 1 : n
        var a = Array<Double>(repeating: 0, count: _n)
        for i in 0 ..< _n {
            a[i] = sqrt(x[i]*x[i] + y[i]*y[i])
        }
        return a
    }

    func angle(_ x: [Double], _ y: [Double], _ bHalf: Bool) -> [Double] {
        let _n = bHalf ? n >> 1 : n
        var a = Array<Double>(repeating: 0, count: _n)
        for i in 0 ..< _n {
            a[i] = atan2(y[i], x[i])
        }
        return a
    }

    func hamming(_ x: inout [Double]) {
        for i in 0 ..< x.count {
            x[i] *= 0.54 - 0.46 * cosTbl[i]
        }
    }

    func hanning(_ x: inout [Double]) {
        for i in 0 ..< x.count {
            x[i] *= 0.5 - 0.5 * cosTbl[i]
        }
    }

    func fft(_ src: [Double]) -> [Double] {
        var x = src.count <= n ? src : Array(src[0 ..< n])
        if x.count < n {
            x.append(contentsOf: Array<Double>(repeating: 0, count: n - x.count))
        }
        var y = Array<Double>(repeating: 0, count: x.count)
        hanning(&x)
        fft(&x, &y)
        let a = abs(x, y, true)
        return a
    }
}
