//
//  StatusBarMenu.swift
//  Ejectify
//
//  Created by Niels Mouthaan on 21/11/2020.
//

import AppKit

class StatusBarMenu: NSMenu {
    
    private var volumes: [ExternalVolume]
    
    required init(coder: NSCoder) {
        volumes = ExternalVolume.mountedVolumes()
        super.init(coder: coder)
        updateMenu()
        listenForDiskNotifications()
    }
    
    init() {
        volumes = ExternalVolume.mountedVolumes()
        super.init(title: "Ejectify")
        updateMenu()
        listenForDiskNotifications()
    }
    
    private func listenForDiskNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(disksChanged), name: NSWorkspace.didRenameVolumeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(disksChanged), name: NSWorkspace.didMountNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(disksChanged), name: NSWorkspace.didUnmountNotification, object: nil)
    }
    
    @objc private func disksChanged() {
        volumes = ExternalVolume.mountedVolumes()
        updateMenu()
    }
    
    private func updateMenu() {
        self.removeAllItems()
        buildActionsMenu()
        buildVolumesMenu()
        buildPreferencesMenu()
        buildAppMenu()
    }
    
    private func buildActionsMenu() {
        
        // Title
        let titleItem = NSMenuItem(title: "Actions".localized, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        addItem(titleItem)
        
        // Unmount all
        let unmountAllItem = NSMenuItem(title: "Unmount all".localized, action: #selector(unmountAllClicked(menuItem:)), keyEquivalent: "")
        unmountAllItem.target = self
        addItem(unmountAllItem)
    }

    private func buildVolumesMenu() {
        addItem(NSMenuItem.separator())
        
        // Title
        let title = volumes.count == 0 ? "No volumes".localized : "Volumes".localized
        let titleItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        addItem(titleItem)
        
        // Volume items
        volumes.forEach { (volume) in
            let volumeItem = NSMenuItem(title: volume.name, action: #selector(volumeClicked(menuItem:)), keyEquivalent: "")
            volumeItem.target = self
            volumeItem.state = volume.enabled ? .on : .off
            volumeItem.representedObject = volume
            addItem(volumeItem)
        }
    }
    
    private func buildPreferencesMenu() {
        addItem(NSMenuItem.separator())
        
        // Title
        let titleItem = NSMenuItem(title: "Preferences".localized, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        addItem(titleItem)
        
        // Launch at login
        let launchAtLoginItem = NSMenuItem(title: "Launch at login".localized, action: #selector(launchAtLoginClicked(menuItem:)), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = Preference.launchAtLogin ? .on : .off
        addItem(launchAtLoginItem)
        
        // Unmount when menu
        let unmountWhenItem = NSMenuItem(title: "Unmount when".localized, action: nil, keyEquivalent: "")
        unmountWhenItem.submenu = buildUnmountWhenMenu()
        addItem(unmountWhenItem)
        
        // Force unmount
        let forceUnmountItem = NSMenuItem(title: "Force unmount".localized, action: #selector(forceUnmountClicked(menuItem:)), keyEquivalent: "")
        forceUnmountItem.target = self
        forceUnmountItem.state = Preference.forceUnmount ? .on : .off
        addItem(forceUnmountItem)
        
        // Mount after delay
        let mountAfterDelay = NSMenuItem(title: "Mount after delay".localized, action: #selector(mountAfterDelayClicked(menuItem:)), keyEquivalent: "")
        mountAfterDelay.target = self
        mountAfterDelay.state = Preference.mountAfterDelay ? .on : .off
        addItem(mountAfterDelay)
    }
    
    private func buildUnmountWhenMenu() -> NSMenu {
        let unmountWhenMenu = NSMenu(title: "Unmount when".localized)
        
        let options = [
            ("Screensaver started".localized, Preference.UnmountWhen.screensaverStarted.rawValue),
            ("Screen is locked".localized, Preference.UnmountWhen.screenIsLocked.rawValue),
            ("Display turned off".localized, Preference.UnmountWhen.screensStartedSleeping.rawValue),
            ("System starts sleeping".localized, Preference.UnmountWhen.systemStartsSleeping.rawValue)
        ]
        
        options.forEach { (title, value) in
            let menuItem = NSMenuItem(
                title: title,
                action: #selector(unmountWhenChanged(menuItem:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.state = Preference.unmountWhenOptions.contains(value) ? .on : .off
            menuItem.representedObject = value
            unmountWhenMenu.addItem(menuItem)
        }
        
        return unmountWhenMenu
    }
    
    private func buildAppMenu() {
        addItem(NSMenuItem.separator())
        
        // About
        let aboutItem = NSMenuItem(title: "About Ejectify".localized, action: #selector(aboutClicked), keyEquivalent: "")
        aboutItem.target = self
        addItem(aboutItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Ejectify".localized, action: #selector(quitClicked), keyEquivalent: "")
        quitItem.target = self
        addItem(quitItem)
    }

    @objc private func unmountAllClicked(menuItem: NSMenuItem) {
        volumes.filter { $0.enabled }
            .forEach { (volume) in
                volume.unmount(force: Preference.forceUnmount)
            }
        updateMenu()
    }

    @objc private func volumeClicked(menuItem: NSMenuItem) {
        guard let volume = menuItem.representedObject as? ExternalVolume else {
            return
        }
        volume.enabled = menuItem.state == .off ? true : false
        updateMenu()
    }
    
    @objc private func launchAtLoginClicked(menuItem: NSMenuItem) {
        Preference.launchAtLogin = menuItem.state == .off ? true : false
        updateMenu()
    }
    
    @objc private func unmountWhenChanged(menuItem: NSMenuItem) {
        guard let value = menuItem.representedObject as? Int else { return }
        
        var options = Preference.unmountWhenOptions
        if options.contains(value) {
            options.remove(value)
        } else {
            options.insert(value)
        }
        Preference.unmountWhenOptions = options
        updateMenu()
    }
    
    @objc private func forceUnmountClicked(menuItem: NSMenuItem) {
        Preference.forceUnmount = menuItem.state == .off ? true : false
        updateMenu()
    }
    
    @objc private func mountAfterDelayClicked(menuItem: NSMenuItem) {
        Preference.mountAfterDelay = menuItem.state == .off ? true : false
        updateMenu()
    }
    
    @objc private func aboutClicked() {
        NSWorkspace.shared.open(URL(string: "https://ejectify.app")!)
    }
    
    @objc private func quitClicked() {
        NSApplication.shared.terminate(self)
    }
}
