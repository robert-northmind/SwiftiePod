//
//  ContentView.swift
//  ExampleIosApp
//
//  Created by Robert Magnusson on 16.02.26.
//

import SwiftUI
import SwiftiePod

// MARK: - App UI

let pod = SwiftiePod()

struct ContentView: View {
    @State private var viewModel = pod.resolve(viewModelProvider)
    
    var body: some View {

        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("SwiftiePod Example")
                .font(.title2)
            Text(viewModel.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
