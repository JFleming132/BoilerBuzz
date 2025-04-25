
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
    @State var events : [Event] = []
    @State var rsvpEvents : [Event] = []
    @State var promotedEvents : [Event] = []
    @State var errorMessage: String?
    @State var selectedDates: [DateComponents] = [] //should only ever contain one element but is an array anyway? just trust me
    @State private var showingEventSheet: Bool = false
    var body: some View {
        VStack {
            CalendarView(selection: $selectedDates) //TODO: Make these decorations nicer and more noticable
                .decorating(
                    parseEvents(events: rsvpEvents),
                    systemImage: "star"
                )
                .decorating(
                    parseEvents(events: promotedEvents),
                    systemImage: "star.fill"
                )
                .onAppear(perform: fetchEvents)
                .onChange(of: selectedDates, { oldValue, newValue in
                    if !newValue.isEmpty {
                        showingEventSheet = true
                    }
                })
                .sheet(isPresented: $showingEventSheet, onDismiss: onSheetDismissed) {
                    let allEvents = rsvpEvents + promotedEvents
                    let selectedEvents = allEvents.filter{
                        sameDay(dc: selectedDates.first!, d: $0.date)
                    }
                    NavigationStack() {
                        VStack() {
                            //TODO: Add header to sheet that gives current selected date, which is selectedDates!
                            ForEach(selectedEvents) { e in
                                NavigationLink(destination: EventDetailView(event: e)) {
                                    EventCardView(event: e)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
        }
    }
    
    func sameDay(dc: DateComponents, d: Date) -> Bool {
        let dc1 = Calendar.current.dateComponents([.day, .year, .month], from: d)
        if (dc.year! == dc1.year) {
            if (dc.month! == dc1.month) {
                if (dc.day! == dc1.day) {
                    return true
                }
            }
        }
        return false
    }
    
    func onSheetDismissed() {
        selectedDates = []
    }
                          
    private func parseEvents(events: ([Event])) -> Set<DateComponents> {
        var DateComponentsArray: [DateComponents] = [] //will be returned, parsed
        for event in events { //for every event we fetched in init()
            DateComponentsArray.append( //add the date it contains to the array
                Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: event.date) //parse the date with built-in methods
            )
        }
        return Set(DateComponentsArray) //convert array to set for CalendarView()
    }
    
    private func fetchEvents() { //literally copied from Sophie's code
        guard let myUserId = UserDefaults.standard.string(forKey: "userId") else {
            print("My user ID not found")
            return
        }
        
        guard let url = URL(string: backendURL + "api/calendar/events?currentUserID=\(myUserId)") else {
            errorMessage = "Invalid API URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error fetching events: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }

            // Debug raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print(" API Response:\n\(jsonString)")
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970 //  Decode timestamps correctly
                
                let fetchedEvents = try decoder.decode([Event].self, from: data)
                DispatchQueue.main.async {
                    //All events that are promoted go in one array, all other events go in another
                    self.promotedEvents = fetchedEvents.filter { $0.promoted }
                    self.rsvpEvents = fetchedEvents.filter { !$0.promoted }
                    self.errorMessage = nil
                    print(promotedEvents)
                    print(rsvpEvents)
                }
                
                print("Successfully fetched events")
            } catch {
                print(" JSON Decoding Error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "JSON Decoding Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

#Preview {
    CalendarViewPage()
}

