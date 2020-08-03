//
//  GraphView.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/07/31.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import UIKit

class GraphView: UIView {
   
    var values = [Double]()
    var minValue: Double = 0.0
    var maxValue: Double = 1.0
    var color = UIColor.white
    var lineWidth = 1

    private var dataWidth = CGFloat(0)
    private var dataHeight = CGFloat(0)
    
    func calcPoint(idx: Int, value: Double) -> CGPoint {
        let x = CGFloat(idx) * frame.width / dataWidth
        let y = frame.height - (CGFloat(value - minValue) * frame.height / dataHeight)
        return CGPoint(x:x, y:y)
    }

    override func draw(_ rect: CGRect) {
        if values.count == 0 {
            return
        }
        let rect = UIBezierPath(rect: CGRect(x:0, y:0, width: frame.width, height: frame.height))
        UIColor.black.setFill()
        rect.fill()
        dataWidth = CGFloat(values.count)
        dataHeight = CGFloat(maxValue - minValue)
        if values.count > Int(frame.width * contentScaleFactor) {
            decimate()
            return
        }
        var lastPos = calcPoint(idx: 0, value: values[0])
        for (idx, value) in values.enumerated() {
            // Drawing continuous lines is heavy, so draw individual line segments.
            let graphPath = UIBezierPath()
            let pos = calcPoint(idx:idx, value:value)
            graphPath.move(to: lastPos)
            graphPath.addLine(to: pos)
            graphPath.lineWidth = CGFloat(lineWidth)
            color.setStroke()
            graphPath.stroke()
            graphPath.close()
            lastPos = pos
        }

    }

    func decimate() {
        // Thinning the drawing to one pixel in width
        let deltaX = 1.0 / contentScaleFactor
        //let deltaX = CGFloat(1.0)
        var lastPos = calcPoint(idx: 0, value: values[0])
        var minY = lastPos.y
        var maxY = lastPos.y
        for (idx, value) in values.enumerated() {
            let nextPos = calcPoint(idx: idx, value: value)
            if (nextPos.x - lastPos.x) > deltaX {
                let graphPath = UIBezierPath()
                graphPath.move(to: lastPos)
                let pos = CGPoint(x: nextPos.x, y: (minY + maxY) / 2.0)
                graphPath.addLine(to: pos)
                graphPath.lineWidth = CGFloat(lineWidth)
                color.setStroke()
                graphPath.stroke()
                graphPath.close()
                lastPos = pos
                minY = nextPos.y
                maxY = nextPos.y
            } else {
                if minY > nextPos.y {
                    minY = nextPos.y
                }
                if maxY < nextPos.y {
                    maxY = nextPos.y
                }
            }
        }
    }

}
