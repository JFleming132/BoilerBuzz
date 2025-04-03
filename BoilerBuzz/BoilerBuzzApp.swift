import SwiftUI
import GoogleMaps
import GooglePlaces

let primaryColor = Color.black
let secondaryColor = Color.gray
let tertiaryColor = Color.yellow
let bgColor = Color.black.opacity(0.7)

import UserNotifications


class AppDelegate: NSObject, UIApplicationDelegate {
    let notificationDelegate = NotificationDelegate()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }
}

@main
struct BoilerBuzzApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State var isLoggedIn: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var initialTab: Tab = .home
    @State private var deepLinkUserId: String? = nil
    @State private var deepLinkEventId: String? = nil

    // @StateObject private var notificationManager = NotificationManager()
    
    init() {
        SocketIOManager.shared.establishConnection()
        GMSServices.provideAPIKey(APIKeys.googleMapsAPIKey)
        GMSPlacesClient.provideAPIKey(APIKeys.googleMapsAPIKey)

        if CommandLine.arguments.contains("-UITestSkipLogin") {
            UserDefaults.standard.set("67bfc14a59159fbf803fc3bf", forKey: "userId")
            UserDefaults.standard.set(false, forKey: "isAdmin")
            self._isLoggedIn = State(initialValue: true)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    if let userId = deepLinkUserId {
                        ContentView(initialTab: .account, accountToView: userId, eventToView: nil)
                            .onAppear {
                                DispatchQueue.main.async {
                                    deepLinkUserId = nil
                                }
                            }
                    }
                    else if let eventId = deepLinkEventId {
                        ContentView(initialTab: .home, accountToView: nil, eventToView: eventId)
                            /*.onAppear {
                                DispatchQueue.main.async {
                                    deepLinkEventId = nil
                                }
                            }*/
                    }
                    else {
                        ContentView(initialTab: .home, accountToView: nil, eventToView: nil)
                    }
                } else {
                    LoginView(isLoggedIn: $isLoggedIn)
                }
            }
            .environmentObject(NotificationManager.shared)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NewNotification"))) { notification in
                if let unNotification = notification.object as? UNNotification {
                    let content = unNotification.request.content
                    print("📥 Global listener received: \(content.title)")

                    NotificationManager.shared.addNotification(
                        title: content.title,
                        message: content.body
                    )
                }
            }

            .onOpenURL { url in
                print("Received deep link: \(url)")
                isLoggedIn = false

                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let host = components.host,
                   let queryItems = components.queryItems {

                    if host.lowercased() == "account",
                       let idItem = queryItems.first(where: { $0.name.lowercased() == "id" }),
                       let userId = idItem.value {
                        deepLinkUserId = userId
                        initialTab = .account
                        print("Deep link userId: \(userId)")
                    } else if host.lowercased() == "event",
                              let idItem = queryItems.first(where: { $0.name.lowercased() == "id" }),
                              let eventId = idItem.value {
                        deepLinkEventId = eventId
                        initialTab = .home
                        print("Deep link eventId: \(eventId)")
                    }
                }
            }
        }
        .onChange(of: isDarkMode) { oldValue, newValue in
            setColorScheme(newValue)
        }
    }
    
    private func setColorScheme(_ isDark: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
}
