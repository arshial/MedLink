import SwiftUI
import UserNotifications
import Combine

// =========================================================
// FILE: FoundationApplicationApp.swift
// ACTION: MODIFY ROOT VIEW LOGIC
// PURPOSE: Show intro ONLY ON FIRST LAUNCH
// =========================================================

final class NotificationCenterDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // Show banner + sound while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}

@main
struct FoundationApplicationApp: App {
    @AppStorage("enableDarkMode") private var enableDarkMode = false
    @AppStorage("didShowMapIntro") private var didShowMapIntro = false

    @StateObject private var auth = AuthViewModel()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var notificationDelegate = NotificationCenterDelegate()

    var body: some Scene {
        WindowGroup {
            if didShowMapIntro {
                HomeView()
                    .environmentObject(homeVM)
                    .environmentObject(auth)
                    .preferredColorScheme(enableDarkMode ? .dark : .light)
                    .task {
                        // Ensure the view models are connected once.
                        if auth.homeViewModel == nil {
                            auth.homeViewModel = homeVM
                        }
                        // Set notification delegate so banners show in foreground
                        UNUserNotificationCenter.current().delegate = notificationDelegate
                    }
            } else {
                MapIntroView()
                    .preferredColorScheme(enableDarkMode ? .dark : .light)
                    .environmentObject(auth)
                    .environmentObject(homeVM)
                    .onAppear {
                        // If you want the intro to auto-dismiss after showing once,
                        // set didShowMapIntro = true when the user completes the intro.
                        // You might instead flip this in MapIntroView when the user taps "Continue".
                    }
                    .task {
                        // Set notification delegate so banners show in foreground
                        UNUserNotificationCenter.current().delegate = notificationDelegate
                    }
            }
        }
    }
}
