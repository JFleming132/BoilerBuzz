import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Toggle("Dark Mode", isOn: $isDarkMode)
                    .onChange(of: isDarkMode) { oldValue, newValue in
                        applyTheme(isDarkMode: newValue)
                    }
            }
            
            // You can add more appearance-related settings here if needed
            Section(header: Text("Other Appearance Settings")) {
                Text("Add more appearance options here")
            }
        }
        .navigationTitle("Appearance")
        .onAppear {
            applyTheme(isDarkMode: isDarkMode)
        }
    }
    
    private func applyTheme(isDarkMode: Bool) {
        // This function applies the theme system-wide
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
}

struct AppearanceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppearanceSettingsView()
        }
    }
}
