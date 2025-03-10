//
//  MapView.swift
//  BoilerBuzz
//
//  Created by user269394 on 2/7/25.
//

import SwiftUI
import EventKit
import UIKit

struct CalendarViewComponent: UIViewRepresentable {
    let interval = DateInterval(start: .distantPast, end: .distantFuture)
    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = Calendar(identifier: .gregorian)
        view.availableDateRange = interval
        return view
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        
    }
}

struct CalendarView: View {
    var body: some View {
        CalendarViewComponent()
    }
}

struct CalendarView_Previews : PreviewProvider {
    static var previews: some View{
        CalendarView()
    }
}
