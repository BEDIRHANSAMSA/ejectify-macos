//
//  ActivityController.swift
//  Ejectify
//
//  Created by Niels Mouthaan on 24/11/2020.
//

import AppKit

class ActivityController {
    
    private var unmountedVolumes: [ExternalVolume] = []
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default.removeObserver(self)
        
        for option in Preference.UnmountWhen.allOptions {
            guard Preference.unmountWhenOptions.contains(option.rawValue) else { continue }
            
            switch option {
            case .screensaverStarted:
                addScreensaverObservers()
            case .screenIsLocked:
                addScreenLockObservers()
            case .screensStartedSleeping:
                addScreenSleepObservers()
            case .systemStartsSleeping:
                addSystemSleepObservers()
            }
        }
    }
    
    private func addScreensaverObservers() {
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(unmountVolumes),
            name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"),
            object: nil
        )
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(mountVolumes),
            name: NSNotification.Name(rawValue: "com.apple.screensaver.didstop"),
            object: nil
        )
    }
    
    private func addScreenLockObservers() {
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(unmountVolumes),
            name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"),
            object: nil
        )
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(mountVolumes),
            name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"),
            object: nil
        )
    }
    
    private func addScreenSleepObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(unmountVolumes),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(mountVolumes),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }
    
    private func addSystemSleepObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(unmountVolumes),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(mountVolumes),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    @objc func unmountVolumes() {
        let currentlyMounted = ExternalVolume.mountedVolumes().filter { $0.enabled }
        unmountedVolumes.append(contentsOf: currentlyMounted.filter { !unmountedVolumes.contains($0) })
        
        currentlyMounted.forEach { volume in
            volume.unmount(force: Preference.forceUnmount)
        }
    }
    
    @objc func mountVolumes() {
        let delaySeconds = Preference.mountAfterDelay ? 5 : 0
        let deadline = DispatchTime.now() + DispatchTimeInterval.seconds(delaySeconds)
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            guard let self = self else { return }
            
            let volumesToMount = self.unmountedVolumes.filter { 
                !ExternalVolume.mountedVolumes().contains($0)
            }
            volumesToMount.forEach { $0.mount() }
            
            self.unmountedVolumes.removeAll(where: { volume in
                ExternalVolume.mountedVolumes().contains(volume)
            })
        }
    }
}
