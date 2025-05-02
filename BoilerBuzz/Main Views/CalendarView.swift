
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

enum CalendarMode: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
}

extension Date {
    /// Returns the start of week based on current calendar
    func startOfWeek(using calendar: Calendar = .current) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: comps) ?? self
    }
}

struct CalendarViewPage: View {

    // MARK: State
    @State private var rsvpEvents: [Event] = []
    @State private var promotedEvents: [Event] = []
    @State private var selectedDates: [DateComponents] = []
    @State private var selectedDate: DateComponents? = nil
    @State private var showingEventSheet = false
    @State private var viewMode: CalendarMode = .month
    @State private var weekStart: Date = Date().startOfWeek()

    var body: some View {
        VStack(spacing: 0) {
            // Toggle between Month / Week
            Picker("View Mode", selection: $viewMode) {
                ForEach(CalendarMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Choose the appropriate subview
            if viewMode == .month {
                monthView
            } else {
                weekView   // your existing weekView
            }
        }
        .onAppear(perform: fetchEvents)
    }

    // MARK: Month View
    private var monthView: some View {
        CalendarView(
            selection: $selectedDate
        )
        // RSVP’d in blue, large circle
        .decorating(
            parseEvents(rsvpEvents),
            systemImage: "circle.fill",
            color: .blue,
            size: .large
        )
        // Promoted in gold, large circle
        .decorating(
            parseEvents(promotedEvents),
            systemImage: "circle.fill",
            color: .yellow,
            size: .large
        )
        .onChange(of: selectedDate) { new in
            if new != nil {
                showingEventSheet = true
            }
        }
        .sheet(isPresented: $showingEventSheet, onDismiss: {
            selectedDate = nil
        }) {
            // Build the sheet only if a date is set
            if let comps = selectedDate,
               let date = Calendar.current.date(from: comps) {
                // Filter events for that day
                let all = rsvpEvents + promotedEvents
                let todays = all.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: date)
                }
                // Show your event list
                NavigationStack {
                    VStack(alignment: .leading) {
                        Text(date, style: .date)
                            .font(.headline)
                            .padding()
                        ScrollView {
                            ForEach(todays) { ev in
                                NavigationLink(destination: EventDetailView(event: ev)) {
                                    EventCardView(event: ev)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)

                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Week View
    private var weekView: some View {
        VStack(spacing: 8) {
            // Navigation Header
            HStack {
                Button { weekStart = Calendar.current.date(byAdding: .day, value: -7, to: weekStart)! } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(weekRangeTitle())
                    .font(.headline)
                Spacer()
                Button { weekStart = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)! } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Days List
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<7) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: weekStart)!
                        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        let eventsForDay = (rsvpEvents + promotedEvents).filter { ev in
                            let evComp = Calendar.current.dateComponents([.year, .month, .day], from: ev.date)
                            return evComp == comps
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            // Day Header
                            Text(dayHeader(for: date))
                                .font(.headline)
                                .padding(.horizontal)

                            // Event Cards
                            ForEach(eventsForDay) { ev in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(ev.promoted ? Color.yellow : Color.blue)
                                        .frame(width: 12, height: 12)
                                        .padding(.top, 6)

                                    EventCardView(event: ev)
                                        .padding(.trailing)
                                }
                                .onTapGesture {
                                    selectedDates = [comps]
                                    showingEventSheet = true
                                }
                            }

                            if eventsForDay.isEmpty {
                                Text("No events")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .sheet(isPresented: $showingEventSheet, onDismiss: { selectedDates = [] }) {
                eventSheet(for: selectedDates)
            }
        }
    }

    // MARK: - Event Sheet
    @ViewBuilder
    private func eventSheet(for comps: [DateComponents]) -> some View {
        if let first = comps.first,
           let date = Calendar.current.date(from: first) {
            let all = rsvpEvents + promotedEvents
            let filtered = all.filter { ev in
                let evComp = Calendar.current.dateComponents([.year, .month, .day], from: ev.date)
                return evComp == first
            }
            NavigationStack {
                VStack(alignment: .leading) {
                    Text(date, style: .date)
                        .font(.headline)
                        .padding()
                    ScrollView {
                        ForEach(filtered) { ev in
                            NavigationLink(destination: EventDetailView(event: ev)) {
                                EventCardView(event: ev)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }


    // MARK: - Helpers
    private func parseEvents(_ events: [Event]) -> Set<DateComponents> {
        Set(events.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.date) })
    }

    private func weekRangeTitle() -> String {
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return "\(fmt.string(from: weekStart)) – \(fmt.string(from: end))"
    }

    private func dayHeader(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: date)
    }
    
    private func fetchEvents() {
        guard let userId = UserDefaults.standard.string(forKey: "userId"),
              let url = URL(string: "http://54.146.194.154:3000/api/calendar/events?currentUserID=\(userId)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let tok = UserDefaults.standard.string(forKey: "authToken") {
            req.setValue("Bearer \(tok)", forHTTPHeaderField: "Authorization")
        }
        URLSession.shared.dataTask(with: req) { data, _, err in
            guard let data = data, err == nil else { return }
            do {
                let dec = JSONDecoder()
                dec.dateDecodingStrategy = .millisecondsSince1970
                let fetched = try dec.decode([Event].self, from: data)
                DispatchQueue.main.async {
                    self.rsvpEvents = fetched.filter { !$0.promoted }
                    self.promotedEvents = fetched.filter { $0.promoted }
                }
            } catch {}
        }.resume()
    }
}

#Preview {
    CalendarViewPage()
}

