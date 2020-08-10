//
//  SendRecv.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/08/04.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import Foundation

class SendRecv : AudioInUpdater, AudioPlayDataProvider {

    var udpsocket: UnsafeMutablePointer<context>?
    private var recvBuffer = [Float]()
    private let lock = NSLock()

    let callback: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<Int16>?, Int32) -> Void = {
        (ref, data, len) in
        if let ref_unwrapped = ref {
            let o:SendRecv = unsafeBitCast(ref_unwrapped, to: SendRecv.self)
            o.received(data, len)
        }
    }
    
    func getMyIPv4Address() -> String {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return "" }
        guard let firstAddr = ifaddr else { return "" }
        var wifi_ip = ""
        var mobile_ip = ""
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily != UInt8(AF_INET) {
                continue
            }
            let ifname = String(cString: interface.ifa_name)
            var addr = interface.ifa_addr.pointee
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count),
                        nil, socklen_t(0), NI_NUMERICHOST)
            let address = String(cString: hostname)
            switch ifname {
            case "en0":
                wifi_ip = address
            case "pdp_ip0":
                mobile_ip = address
            default:
                break
            }
        }
        freeifaddrs(ifaddr)
        return wifi_ip.isEmpty ? mobile_ip : wifi_ip
    }
    
    func start(_ peerHost: String, _ strPeerPort: String, _ strMyPort: String) -> String {
        guard let peerPort = Int32(strPeerPort) else { return "wrong peer port" }
        guard let myPort = Int32(strMyPort) else { return "wrong my port" }
        guard let sock = openUDPSocket(peerHost, peerPort, myPort) else { return "socket open failed" }
        udpsocket = sock
        let ref: UnsafeMutableRawPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        registerCallback(sock, callback, ref)
        return ""
    }
    
    func stop() {
        closeUDPSocket(udpsocket)
        udpsocket = nil
    }

    func update(_ data: [Float]) {
        let s = (0 ..< data.count).map { (i) -> Int16 in
            let value = data[i]
            if value >= 1.0 {
                return 32767
            } else if value <= -1.0 {
                return -32768
            } else {
                return Int16(value * 32767.0)
            }
        }
        let p = UnsafePointer<Int16>(s)
        sendUDPDatagram(udpsocket, p, Int32(s.count))
    }
 
    func received(_ data: UnsafePointer<Int16>?, _ len: Int32) {
        //print("callback \(len)")
        if let d = data {
            lock.lock()
            recvBuffer.append(contentsOf: (0 ..< Int(len)).map { (i) -> Float in Float(d[i]) / 32767.0})
            lock.unlock()
        }
    }

    func getAudioPlayData(_ buffer: UnsafeMutablePointer<Float>, _ len: UInt32) {
        lock.lock()
        let len2 = recvBuffer.count > len ? Int(len) : recvBuffer.count
        for i in 0 ..< len2 {
            buffer[i] = recvBuffer[i]
        }
        for i in len2 ..< Int(len) {
            buffer[i] = 0
        }
        recvBuffer.removeSubrange(0 ..< len2)
        lock.unlock()
        //print("getAudioPlayData \(len), \(len2)")
    }
}
