//
//  CalendarWidgetBundle.swift
//  CalendarWidget
//
//  Created by Taras Khanchuk on 04.02.2026.
//

import WidgetKit
import SwiftUI

@main
struct CalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalendarWidget()
        WeatherWidget()
    }
}
