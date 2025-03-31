//
//  NotificationCenterView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 3/26/25.
//


import SwiftUI

struct NotificationCenterView: View {
    var body: some View {
        NavigationView {
            List {
                // Replace with dynamic notifications later.
                Text("No notifications yet.")
            }
            .navigationTitle("Notifications")
        }
    }
}

struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationCenterView()
    }
}
 
