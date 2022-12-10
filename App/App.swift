//
//  App.swift
//  WidgetExamples
//
//  Created by Pawel Wiszenko on 15.10.2020.
//  Copyright © 2020 Pawel Wiszenko. All rights reserved.
//

import SwiftUI

@main
struct TransitWidget: App {
    @StateObject private var fetcher = TransitDataFetcher()
    
    var body: some Scene {
        return WindowGroup {
            NearbyStationView()
                .environmentObject(fetcher)
        }
    }
}
