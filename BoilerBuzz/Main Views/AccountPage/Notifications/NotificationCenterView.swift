//
//  NotificationCenterView.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 3/26/25.
//


import SwiftUI

struct NotificationCenterView: View {
    @EnvironmentObject var notificationManager: NotificationManager

    var body: some View {
        NavigationView {
            List {
                if notificationManager.notifications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray.opacity(0.6))
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("You'll see updates here if you have notifications on in the settings.")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(notificationManager.notifications) { notification in
                        NotificationRow(notification: notification)
                            .swipeActions {
                                Button(role: .destructive) {
                                    notificationManager.removeNotification(notification)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !notificationManager.notifications.isEmpty {
                        Button("Clear All") {
                            notificationManager.clearNotifications()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if notificationManager.notifications.contains(where: { !$0.isRead }) {
                        Button("Mark All Read") {
                            notificationManager.markAllAsRead()
                        }
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    @EnvironmentObject var notificationManager: NotificationManager
    var notification: NotificationItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .transition(.opacity)
                }
            }
            
            Text(notification.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(notification.date, style: .time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 6)
        .padding(.horizontal)
        .background(notification.isRead ? Color(.systemGray6) : Color(.systemBlue).opacity(0.1))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                notificationManager.markAsRead(notification)
            }
        }
    }
}