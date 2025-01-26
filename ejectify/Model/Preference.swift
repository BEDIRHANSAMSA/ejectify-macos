//
//  Option.swift
//  Ejectify
//
//  Created by Niels Mouthaan on 27/11/2020.
//

import Foundation
import LaunchAtLogin

class Preference {
    
    enum UnmountWhen: Int, CaseIterable {
        case screensaverStarted = 0
        case screenIsLocked = 1
        case screensStartedSleeping = 2
        case systemStartsSleeping = 3
        
        static var allOptions: [UnmountWhen] = [.screensaverStarted, .screenIsLocked, .screensStartedSleeping, .systemStartsSleeping]
    }
    
    static var launchAtLogin: Bool {
        get {
            return LaunchAtLogin.isEnabled
        }
        set {
            LaunchAtLogin.isEnabled = newValue
        }
    }
    
    private static var userDefaultsKeyUnmountWhen = "preference.unmountWhenOptions"
    static var unmountWhenOptions: Set<Int> {
        get {
            let array = UserDefaults.standard.array(forKey: userDefaultsKeyUnmountWhen) as? [Int] ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: userDefaultsKeyUnmountWhen)
            UserDefaults.standard.synchronize()
            AppDelegate.shared.activityController?.startMonitoring()
        }
    }
    
    private static var userDefaultsKeyForceUnmount = "preference.forceUnmount"
    static var forceUnmount: Bool {
        get {
            return UserDefaults.standard.bool(forKey: userDefaultsKeyForceUnmount)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKeyForceUnmount)
            UserDefaults.standard.synchronize()
        }
    }
    
    private static var userDefaultsKeyMountAfterDelay = "preference.mountAfterDelay"
    static var mountAfterDelay: Bool {
        get {
            return UserDefaults.standard.bool(forKey: userDefaultsKeyMountAfterDelay)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKeyMountAfterDelay)
            UserDefaults.standard.synchronize()
        }
    }
}
