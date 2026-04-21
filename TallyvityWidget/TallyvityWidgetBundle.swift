//
//  TallyvityWidgetBundle.swift
//  TallyvityWidget
//
//  Created by Elia Salerno on 21.04.2026.
//

import WidgetKit
import SwiftUI

@main
struct TallyvityWidgetBundle: WidgetBundle {
    var body: some Widget {
        TallyvityWidget()
        TallyvityWidgetControl()
        TallyvityWidgetLiveActivity()
    }
}
