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
    @State var errorMessage: String?
    //I want an init function to load ALL event data, not just dates
    //I want to then parse them into the datecomponent arrays
    //and display views of their posts when selected
    //shouldn't be too hard!
    init() {
        fetchEvents()
    }
    
    var body: some View {
        CalendarView()
            .decorating(parseEvents(events: events))

    }
    private func parseEvents(events: ([Event])) -> Set<DateComponents> {
        var DateComponentsArray: [DateComponents] = []
        let decoder = JSONDecoder()
        for event in events {
            DateComponentsArray.append(
                Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: event.date)
            )
        }
        return Set(DateComponentsArray)
    }
    private func fetchEvents() {
        guard let url = URL(string: "http://localhost:3000/api/home/events") else {
            errorMessage = "Invalid API URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
                print("🚀 API Response:\n\(jsonString)")
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970 //  Decode timestamps correctly
                
                let fetchedEvents = try decoder.decode([Event].self, from: data)
                DispatchQueue.main.async {
                    self.events = fetchedEvents.filter { $0.date >= Date() }
                    self.errorMessage = nil
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
