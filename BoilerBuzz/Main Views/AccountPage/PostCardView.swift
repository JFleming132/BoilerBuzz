import SwiftUI

struct PostCardView: View {
    let event: Event
    
    var body: some View {
        NavigationLink(destination: EventDetailView(event: event)) {
            EventCardView(event: event)
        }
        .buttonStyle(PlainButtonStyle())
    }
}