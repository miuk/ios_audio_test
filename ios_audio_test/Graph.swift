//
//  Graph.swift
//  ios_audio_test
//
//  Created by Kenji Miura on 2020/07/31.
//  Copyright © 2020 Kenji Miura. All rights reserved.
//

import SwiftUI

struct Graph: UIViewRepresentable {
    
    @Binding var values: [Double]
    var minValue: Double = -1.0
    var maxValue: Double = 1.0

    func makeUIView(context: Context) -> GraphView {
        let view = GraphView()
        return view
    }
    
    func updateUIView(_ graph: GraphView, context: Context) {
        graph.values = values
        graph.minValue = minValue
        graph.maxValue = maxValue
        graph.setNeedsDisplay()
    }
}

struct Graph_Previews: PreviewProvider {
    @State static var values: [Double] = [0.0, 0.1, 0.2, 0.3, 0.4, 1.0, 1.0, 0.5, 0.5, 0.0]
    static var previews: some View {
        Graph(values: $values)
    }
}
