//
//  MapView.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/7/25.
//

import SwiftUI
import EventKit
import UIKit
import CalendarView

struct CalendarViewPage: View {
    var RSVPEvents : Set<DateComponents> = [DateComponents(day:16)]
    var promotedEvents : Set<DateComponents> = [DateComponents(day:18)]
    
    //I want an init function to load ALL event data, not just dates
    //I want to then parse them into the datecomponent arrays
    //and display views of their posts when selected
    //shouldn't be too hard!
    
    var body: some View {
        CalendarView()
            .decorating(RSVPEvents)
            .decorating(promotedEvents, systemImage: "star")
    }
}

#Preview {
    CalendarViewPage()
}
