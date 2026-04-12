import Foundation
import SwiftData

/// Manages daily automatic backups of the SwiftData store to the app's Documents folder.
/// Documents/ is exposed via UIFileSharingEnabled, so backups appear in Files →
/// "Sur mon iPhone" → GymTracker, and via the Finder when the iPhone is plugged into a Mac.
enum AutoBackupService {

    private static let rootFolderName = "GymTracker Backups"
    private static let backupsFolderName = "Sauvegardes"
    private static let safetyFolderName = "Sécurité"
    private static let lastBackupKey = "lastAutoBackupDate"
    private static let cloudBookmarkKey = "cloudBackupFolderBookmark"
    private static let maxBackupsToKeep = 30

    // MARK: - Public API

    /// Performs an automatic backup if none has been done today. Safe to call from app launch.
    /// Also copies to the user's chosen iCloud Drive folder if configured.
    static func runDailyBackupIfNeeded(context: ModelContext) {
        let lastDate = UserDefaults.standard.object(forKey: lastBackupKey) as? Date
        if let last = lastDate, Calendar.current.isDateInToday(last) {
            return
        }
        do {
            let url = try performBackup(context: context, automatic: true)
            UserDefaults.standard.set(Date(), forKey: lastBackupKey)
            try pruneOldBackups()
            copyToCloudFolder(url)
        } catch {
            print("⚠️ Auto-backup failed: \(error.localizedDescription)")
        }
    }

    /// Forces a backup right now (called from the manual button in Settings).
    @discardableResult
    static func backupNow(context: ModelContext) throws -> URL {
        let url = try performBackup(context: context, automatic: false)
        UserDefaults.standard.set(Date(), forKey: lastBackupKey)
        try pruneOldBackups()
        copyToCloudFolder(url)
        return url
    }

    // MARK: - Cloud Folder (security-scoped bookmark)

    /// Saves a user-chosen folder URL as a security-scoped bookmark.
    /// Call this once when the user picks a folder via the document picker.
    static func setCloudFolder(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if let data = try? url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            UserDefaults.standard.set(data, forKey: cloudBookmarkKey)
        }
    }

    /// Returns the saved cloud folder URL, or nil if not configured.
    static func cloudFolderURL() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: cloudBookmarkKey) else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        if isStale {
            // Re-save if stale
            setCloudFolder(url)
        }
        return url
    }

    /// Whether a cloud backup folder is configured.
    static var isCloudFolderConfigured: Bool {
        cloudFolderURL() != nil
    }

    /// Removes the saved cloud folder bookmark.
    static func clearCloudFolder() {
        UserDefaults.standard.removeObject(forKey: cloudBookmarkKey)
    }

    /// Whether the last cloud sync succeeded. UI can read this to show a warning.
    static var lastCloudSyncFailed: Bool {
        UserDefaults.standard.bool(forKey: "lastCloudSyncFailed")
    }

    /// Copies a backup file to the user's chosen cloud folder, inside a "Sauvegardes" subfolder.
    private static func copyToCloudFolder(_ localURL: URL) {
        guard let folderURL = cloudFolderURL() else { return }
        guard folderURL.startAccessingSecurityScopedResource() else {
            UserDefaults.standard.set(true, forKey: "lastCloudSyncFailed")
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let cloudBackups = folderURL.appendingPathComponent(backupsFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: cloudBackups, withIntermediateDirectories: true)

        let target = cloudBackups.appendingPathComponent(localURL.lastPathComponent)
        do {
            try? FileManager.default.removeItem(at: target)
            try FileManager.default.copyItem(at: localURL, to: target)
            UserDefaults.standard.set(false, forKey: "lastCloudSyncFailed")
            pruneFolder(cloudBackups, keep: 10)
        } catch {
            UserDefaults.standard.set(true, forKey: "lastCloudSyncFailed")
            print("⚠️ Cloud sync failed: \(error.localizedDescription)")
        }
    }

    private static func pruneFolder(_ folder: URL, keep: Int) {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let sorted = urls
            .filter { $0.pathExtension.lowercased() == "json" }
            .sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return d1 > d2
            }
        for old in sorted.dropFirst(keep) {
            try? FileManager.default.removeItem(at: old)
        }
    }

    /// Returns the list of existing backup files, newest first.
    static func listBackups() -> [BackupFile] {
        guard let folder = backupsFolderURL() else { return [] }
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return urls
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap { url -> BackupFile? in
                let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                let date = values?.contentModificationDate ?? Date.distantPast
                let size = values?.fileSize ?? 0
                return BackupFile(url: url, date: date, sizeBytes: size)
            }
            .sorted { $0.date > $1.date }
    }

    static func deleteBackup(_ backup: BackupFile) throws {
        try FileManager.default.removeItem(at: backup.url)
    }

    /// Root: Documents/GymTracker Backups/
    static func rootFolderURL() -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = documents.appendingPathComponent(rootFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    /// Documents/GymTracker Backups/Sauvegardes/
    static func backupsFolderURL() -> URL? {
        guard let root = rootFolderURL() else { return nil }
        let folder = root.appendingPathComponent(backupsFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    /// Documents/GymTracker Backups/Sécurité/
    static func safetyFolderURL() -> URL? {
        guard let root = rootFolderURL() else { return nil }
        let folder = root.appendingPathComponent(safetyFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static var lastBackupDate: Date? {
        UserDefaults.standard.object(forKey: lastBackupKey) as? Date
    }

    // MARK: - Private

    @discardableResult
    private static func performBackup(context: ModelContext, automatic: Bool) throws -> URL {
        guard let folder = backupsFolderURL() else {
            throw NSError(domain: "AutoBackup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Documents folder unavailable"])
        }

        // Build the JSON payload using the existing exporter, which already handles every model.
        let tempURL = try DataExportService.exportAll(context: context)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmm"
        let prefix = automatic ? "auto" : "manual"
        let filename = "GymTracker-\(prefix)-\(formatter.string(from: Date()))-\(timeFormatter.string(from: Date())).json"
        let target = folder.appendingPathComponent(filename)

        // Move the temp file into the Backups folder.
        if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
        }
        try FileManager.default.moveItem(at: tempURL, to: target)
        return target
    }

    /// Returns the latest backup URL (for sharing via the share sheet).
    static var latestBackupURL: URL? {
        listBackups().first?.url
    }

    /// Creates a safety backup BEFORE wiping data. Saved in a dedicated "Sécurité" subfolder
    /// both locally and on iCloud Drive so it's never mixed up with daily auto-backups.
    @discardableResult
    static func safetyBackup(context: ModelContext) throws -> URL {
        guard let safetyFolder = safetyFolderURL() else {
            throw NSError(domain: "AutoBackup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Dossier inaccessible"])
        }

        let tempURL = try DataExportService.exportAll(context: context)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let filename = "GymTracker-SECURITE-\(formatter.string(from: Date())).json"
        let localTarget = safetyFolder.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: localTarget)
        try FileManager.default.moveItem(at: tempURL, to: localTarget)

        // Copy to iCloud Drive → Sécurité/
        if let cloudFolder = cloudFolderURL() {
            if cloudFolder.startAccessingSecurityScopedResource() {
                defer { cloudFolder.stopAccessingSecurityScopedResource() }
                let cloudSafety = cloudFolder.appendingPathComponent(safetyFolderName, isDirectory: true)
                try? FileManager.default.createDirectory(at: cloudSafety, withIntermediateDirectories: true)
                let cloudTarget = cloudSafety.appendingPathComponent(filename)
                try? FileManager.default.removeItem(at: cloudTarget)
                try? FileManager.default.copyItem(at: localTarget, to: cloudTarget)
            }
        }

        return localTarget
    }

    private static func pruneOldBackups() throws {
        let backups = listBackups()
        guard backups.count > maxBackupsToKeep else { return }
        for backup in backups.dropFirst(maxBackupsToKeep) {
            try? FileManager.default.removeItem(at: backup.url)
        }
    }
}

// MARK: - BackupFile

struct BackupFile: Identifiable, Hashable {
    var id: URL { url }
    let url: URL
    let date: Date
    let sizeBytes: Int

    var filename: String { url.lastPathComponent }
    var isAutomatic: Bool { filename.hasPrefix("auto") }

    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
    }
}
