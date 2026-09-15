//
//  ContentView.swift
//  camera ai
//
//  Created by vdt on 15/9/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = ScanViewModel()

    var body: some View {
        HomeView(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
