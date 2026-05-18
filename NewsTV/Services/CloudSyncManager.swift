//
//  CloudSyncManager.swift
//  NewsTV
//
//  Manages iCloud sync for settings and preferences
//  Created by Jordan Koch on 2026-01-30.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import CloudKit

@MainActor
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isAvailable = false

    private lazy var container: CKContainer = {
        CKContainer(identifier: "iCloud.com.jordankoch.NewsTV")
    }()
    private let recordType = "UserSettings"
    #if os(tvOS)
    private let deviceId = UUID().uuidString  // Use persistent storage for real device ID
    #else
    private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    #endif

    private init() {
        checkAvailability()
    }

    // MARK: - Availability

    func checkAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.isAvailable = status == .available
                if let error = error {
                    self?.syncError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Settings Sync

    func syncSettings() async {
        guard SettingsManager.shared.settings.enableiCloudSync else { return }
        guard isAvailable else { return }

        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        do {
            // Try to fetch existing settings from cloud
            let cloudSettings = try await fetchSettingsFromCloud()

            if let cloud = cloudSettings {
                // Merge settings - prefer more recent
                let localDate = lastSyncDate ?? .distantPast
                let cloudDate = cloud.lastUpdated

                if cloudDate > localDate {
                    // Cloud is newer - apply cloud settings
                    applyCloudSettings(cloud.settings)
                } else {
                    // Local is newer - push to cloud
                    try await pushSettingsToCloud()
                }
            } else {
                // No cloud settings - push local
                try await pushSettingsToCloud()
            }

            lastSyncDate = Date()

        } catch {
            syncError = error.localizedDescription
            print("Settings sync error: \(error)")
        }
    }

    private func fetchSettingsFromCloud() async throws -> (settings: NewsTVSettings, lastUpdated: Date)? {
        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: "settings-\(deviceId)")

        do {
            let record = try await database.record(for: recordID)

            guard let data = record["settingsData"] as? Data,
                  let settings = try? JSONDecoder().decode(NewsTVSettings.self, from: data),
                  let lastUpdated = record["lastUpdated"] as? Date else {
                return nil
            }

            return (settings, lastUpdated)
        } catch {
            // Record doesn't exist
            return nil
        }
    }

    private func pushSettingsToCloud() async throws {
        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: "settings-\(deviceId)")
        let record = CKRecord(recordType: recordType, recordID: recordID)

        let settings = SettingsManager.shared.settings
        let data = try JSONEncoder().encode(settings)

        record["settingsData"] = data
        record["lastUpdated"] = Date()
        record["deviceId"] = deviceId

        try await database.save(record)
    }

    private func applyCloudSettings(_ settings: NewsTVSettings) {
        SettingsManager.shared.settings = settings
    }

    // MARK: - Audio Progress Sync

    func syncAudioProgress(_ progress: AudioBriefingProgress) async {
        guard SettingsManager.shared.settings.enableiCloudSync else { return }
        guard isAvailable else { return }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: "audio-progress-\(progress.briefingId.uuidString)")
        let record = CKRecord(recordType: "AudioProgress", recordID: recordID)

        record["briefingId"] = progress.briefingId.uuidString
        record["currentIndex"] = progress.currentIndex
        record["currentPosition"] = progress.currentPosition
        record["lastUpdated"] = progress.lastUpdated
        record["deviceId"] = progress.deviceId

        do {
            try await database.save(record)
        } catch {
            print("Audio progress sync error: \(error)")
        }
    }

    func fetchAudioProgress(for briefingId: UUID) async -> AudioBriefingProgress? {
        guard SettingsManager.shared.settings.enableiCloudSync else { return nil }
        guard isAvailable else { return nil }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: "audio-progress-\(briefingId.uuidString)")

        do {
            let record = try await database.record(for: recordID)

            guard let currentIndex = record["currentIndex"] as? Int,
                  let currentPosition = record["currentPosition"] as? Double,
                  let lastUpdated = record["lastUpdated"] as? Date,
                  let deviceId = record["deviceId"] as? String else {
                return nil
            }

            return AudioBriefingProgress(
                briefingId: briefingId,
                currentIndex: currentIndex,
                currentPosition: currentPosition,
                lastUpdated: lastUpdated,
                deviceId: deviceId
            )

        } catch {
            return nil
        }
    }

    // MARK: - Preference Profile Sync

    func syncPreferenceProfile() async {
        guard SettingsManager.shared.settings.enableiCloudSync else { return }
        guard isAvailable else { return }

        let database = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: "preference-profile")
        let record = CKRecord(recordType: "PreferenceProfile", recordID: recordID)

        let profile = PersonalizationEngine.shared.profile

        do {
            let data = try JSONEncoder().encode(profile)
            record["profileData"] = data
            record["lastUpdated"] = Date()
            try await database.save(record)
        } catch {
            print("Profile sync error: \(error)")
        }
    }
}

// Extension for AudioBriefingProgress memberwise init
extension AudioBriefingProgress {
    init(briefingId: UUID, currentIndex: Int, currentPosition: TimeInterval, lastUpdated: Date, deviceId: String) {
        self.briefingId = briefingId
        self.currentIndex = currentIndex
        self.currentPosition = currentPosition
        self.lastUpdated = lastUpdated
        self.deviceId = deviceId
    }
}
