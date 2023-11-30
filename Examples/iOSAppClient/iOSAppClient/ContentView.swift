//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import SwiftUI

struct ContentView: View {
    
    let client = GreetingClient()
    
    @State
    var message: String = "Hello, world!"
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(message)
            Button("Refresh") {
                Task {
                    let name = "Stranger \((1...10).randomElement()!)"
                    message = try await client.getGreeting(name: name)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
