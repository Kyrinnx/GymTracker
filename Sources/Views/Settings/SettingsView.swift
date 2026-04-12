import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @AppStorage("userName") private var userName: String = ""
    // Workout reminders
    @AppStorage("remindersEnabled") private var remindersEnabled: Bool = false
    @AppStorage("reminderHour") private var reminderHour: Int = 18
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0
    @AppStorage("reminderWeekdays") private var reminderWeekdaysRaw: String = "2,4,6"

    @State private var notifService = NotificationService.shared
    @State private var showResetOnboarding = false
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    // Data export / import
    @State private var exportURL: URL?
    @State private var showImporter = false
    @State private var importMessage: String?
    @State private var showImportConfirm = false
    @State private var pendingImportURL: URL?
    @State private var showWipeConfirm = false
    @State private var showBackupsList = false
    @State private var lastBackupDisplay: String = ""
    @State private var showFolderPicker = false
    @State private var cloudFolderConfigured = AutoBackupService.isCloudFolderConfigured

    private let weekdayLabels: [(Int, String)] = [
        (2, "L"), (3, "M"), (4, "M"), (5, "J"), (6, "V"), (7, "S"), (1, "D")
    ]

    private var selectedWeekdays: Set<Int> {
        Set(reminderWeekdaysRaw.split(separator: ",").compactMap { Int($0) })
    }

    private func setWeekdays(_ days: Set<Int>) {
        reminderWeekdaysRaw = days.sorted().map(String.init).joined(separator: ",")
    }

    var body: some View {
        @Bindable var tm = theme
        NavigationStack {
            List {
                // MARK: - Profil
                Section("Profil") {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(theme.color.accent)
                        TextField("Prénom", text: $userName)
                            .textInputAutocapitalization(.words)
                    }
                }

                // MARK: - Apparence
                Section("Apparence") {
                    Picker("Mode", selection: $tm.mode) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Thème de couleur") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 14) {
                        ForEach(ThemeColor.allCases) { color in
                            themeColorButton(color)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // MARK: - Aperçu
                Section("Aperçu") {
                    themePreview
                }

                // MARK: - Notifications
                Section {
                    Toggle(isOn: Binding(
                        get: { remindersEnabled },
                        set: { newValue in
                            remindersEnabled = newValue
                            Task { await applyReminderSettings() }
                        }
                    )) {
                        Label("Rappels de séance", systemImage: "bell.fill")
                    }
                    if remindersEnabled {
                        DatePicker(
                            "Heure",
                            selection: Binding(
                                get: {
                                    var c = DateComponents()
                                    c.hour = reminderHour
                                    c.minute = reminderMinute
                                    return Calendar.current.date(from: c) ?? Date()
                                },
                                set: { newDate in
                                    let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    reminderHour = c.hour ?? 18
                                    reminderMinute = c.minute ?? 0
                                    Task { await applyReminderSettings() }
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Jours")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                ForEach(weekdayLabels, id: \.0) { day, label in
                                    weekdayPill(day: day, label: label)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if remindersEnabled && !notifService.isAuthorized {
                        Text("Autorise les notifications dans Réglages iOS pour recevoir tes rappels.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                // MARK: - Sauvegardes
                Section {
                    // iCloud status — en premier pour que ce soit visible
                    if cloudFolderConfigured {
                        HStack {
                            Image(systemName: AutoBackupService.lastCloudSyncFailed ? "exclamationmark.icloud.fill" : "checkmark.icloud.fill")
                                .foregroundStyle(AutoBackupService.lastCloudSyncFailed ? .orange : .green)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AutoBackupService.lastCloudSyncFailed ? "Sync iCloud en erreur" : "iCloud Drive activé")
                                    .font(.subheadline.bold())
                                Text(AutoBackupService.lastCloudSyncFailed ? "Reconfigure le dossier ci-dessous" : "Tes données sont sauvegardées dans le cloud")
                                    .font(.caption)
                                    .foregroundStyle(AutoBackupService.lastCloudSyncFailed ? .orange : .secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.icloud.fill")
                                .foregroundStyle(.red)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("iCloud Drive non configuré")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.red)
                                Text("Si tu supprimes l'app, tes données seront perdues !")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button {
                            showFolderPicker = true
                        } label: {
                            Label("Configurer iCloud Drive", systemImage: "icloud.and.arrow.up.fill")
                        }
                        .tint(theme.color.accent)
                    }

                    // Dernière sauvegarde
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(theme.color.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dernière sauvegarde")
                                .font(.subheadline)
                            Text(lastBackupDisplay.isEmpty ? "Jamais" : lastBackupDisplay)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button {
                        do {
                            _ = try AutoBackupService.backupNow(context: context)
                            refreshLastBackupDisplay()
                            importMessage = AutoBackupService.isCloudFolderConfigured ? "Sauvegardé en local + iCloud Drive ✅" : "Sauvegardé en local ✅\n\nConfigure iCloud Drive pour sécuriser tes données."
                        } catch {
                            importMessage = "Échec de la sauvegarde : \(error.localizedDescription)"
                        }
                    } label: {
                        Label("Sauvegarder maintenant", systemImage: "tray.and.arrow.down.fill")
                    }
                    Button {
                        showBackupsList = true
                    } label: {
                        Label("Voir toutes les sauvegardes", systemImage: "list.bullet.rectangle")
                    }
                    if cloudFolderConfigured {
                        Button(role: .destructive) {
                            AutoBackupService.clearCloudFolder()
                            cloudFolderConfigured = false
                        } label: {
                            Label("Désactiver iCloud Drive", systemImage: "xmark.icloud")
                        }
                    }
                } header: {
                    Text("Sauvegardes")
                } footer: {
                    if cloudFolderConfigured {
                        Text("Chaque jour à l'ouverture de l'app, une sauvegarde est créée et copiée dans ton dossier iCloud Drive automatiquement.")
                            .font(.caption)
                    } else {
                        Text("Configure iCloud Drive pour ne jamais perdre tes données, même si tu supprimes l'app.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                // MARK: - Données
                Section {
                    Button {
                        exportData()
                    } label: {
                        Label("Partager une sauvegarde", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showImporter = true
                    } label: {
                        Label("Importer un fichier", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        showResetOnboarding = true
                    } label: {
                        Label("Refaire l'onboarding", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        showWipeConfirm = true
                    } label: {
                        Label("Effacer toutes les données", systemImage: "trash")
                    }
                } header: {
                    Text("Données")
                } footer: {
                    Text("Tes données sont stockées localement. Pense à partager régulièrement une sauvegarde vers iCloud Drive ou AirDrop pour la garder en sécurité.")
                        .font(.caption)
                }

                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Fait avec")
                        Spacer()
                        Text("SwiftUI + Claude").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Réglages")
            .task {
                await notifService.refreshAuthorizationStatus()
                refreshLastBackupDisplay()
            }
            .sheet(isPresented: $showBackupsList) {
                BackupsListView()
            }
            .confirmationDialog(
                "Refaire l'onboarding ?",
                isPresented: $showResetOnboarding,
                titleVisibility: .visible
            ) {
                Button("Refaire", role: .destructive) {
                    onboardingCompleted = false
                }
                Button("Annuler", role: .cancel) {}
            }
            .confirmationDialog(
                "Effacer toutes les données ?",
                isPresented: $showWipeConfirm,
                titleVisibility: .visible
            ) {
                Button("Effacer (une sauvegarde de sécurité sera créée)", role: .destructive) {
                    safeWipe()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Une sauvegarde de sécurité sera enregistrée sur iCloud Drive et sur ton iPhone avant de tout effacer. Tu pourras restaurer plus tard si besoin.")
            }
            .sheet(item: $exportURL) { url in
                ShareSheet(url: url)
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportPick(result)
            }
            .confirmationDialog(
                "Importer ce fichier ?",
                isPresented: $showImportConfirm,
                titleVisibility: .visible
            ) {
                Button("Fusionner") {
                    if let url = pendingImportURL {
                        runImport(from: url, replaceAll: false)
                    }
                }
                Button("Remplacer tout", role: .destructive) {
                    if let url = pendingImportURL {
                        runImport(from: url, replaceAll: true)
                    }
                }
                Button("Annuler", role: .cancel) {
                    pendingImportURL = nil
                }
            } message: {
                Text("Fusionner ajoute les données au contenu existant. Remplacer efface tout d'abord.")
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerView { url in
                    AutoBackupService.setCloudFolder(url)
                    cloudFolderConfigured = true
                    // Copy latest backup immediately
                    if let latest = AutoBackupService.latestBackupURL {
                        // Trigger a copy by re-running backup
                        try? AutoBackupService.backupNow(context: context)
                        refreshLastBackupDisplay()
                    }
                    importMessage = "Sync iCloud Drive activée ✅\nLes prochains backups seront copiés automatiquement."
                }
            }
            .alert("Import", isPresented: Binding(
                get: { importMessage != nil },
                set: { if !$0 { importMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importMessage ?? "")
            }
        }
    }

    // MARK: - Export / Import

    private func exportData() {
        do {
            let url = try DataExportService.exportAll(context: context)
            exportURL = url
        } catch {
            importMessage = "Échec de l'export : \(error.localizedDescription)"
        }
    }

    private func handleImportPick(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            pendingImportURL = url
            showImportConfirm = true
        case .failure(let error):
            importMessage = "Lecture impossible : \(error.localizedDescription)"
        }
    }

    private func runImport(from url: URL, replaceAll: Bool) {
        do {
            try DataExportService.importAll(from: url, into: context, replaceAll: replaceAll)
            importMessage = "Import réussi ! 🎉"
            refreshLastBackupDisplay()
        } catch {
            importMessage = "Échec de l'import : \(error.localizedDescription)"
        }
        pendingImportURL = nil
    }

    private func safeWipe() {
        do {
            // 1. Safety backup in dedicated "Sécurité" folder (local + iCloud Drive)
            _ = try AutoBackupService.safetyBackup(context: context)
            // 2. Wipe all data
            try DataExportService.wipeAll(context: context)
            refreshLastBackupDisplay()
            importMessage = "Données effacées ✅\n\nUne sauvegarde de sécurité a été créée dans :\n• iPhone : Fichiers → GymTracker → Sécurité\n• iCloud Drive → ton dossier → Sécurité\n\nPour restaurer : Réglages → Données → Importer un fichier"
        } catch {
            importMessage = "Échec : \(error.localizedDescription)"
        }
    }

    private func refreshLastBackupDisplay() {
        guard let date = AutoBackupService.lastBackupDate else {
            lastBackupDisplay = ""
            return
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "fr_FR")
        lastBackupDisplay = formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Weekday Pill

    private func weekdayPill(day: Int, label: String) -> some View {
        let isOn = selectedWeekdays.contains(day)
        return Button {
            var current = selectedWeekdays
            if isOn { current.remove(day) } else { current.insert(day) }
            setWeekdays(current)
            Task { await applyReminderSettings() }
        } label: {
            Text(label)
                .font(.caption.bold())
                .frame(width: 32, height: 32)
                .background(isOn ? theme.color.accent : Color.secondary.opacity(0.15))
                .foregroundStyle(isOn ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func applyReminderSettings() async {
        guard remindersEnabled else {
            await notifService.cancelAllWorkoutReminders()
            return
        }
        await notifService.requestAuthorization()
        guard notifService.isAuthorized else { return }
        await notifService.scheduleWorkoutReminders(
            weekdays: selectedWeekdays,
            hour: reminderHour,
            minute: reminderMinute
        )
    }

    // MARK: - Theme Color Button
    private func themeColorButton(_ color: ThemeColor) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) { theme.color = color }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 50, height: 50)
                    if theme.color == color {
                        Image(systemName: "checkmark")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }
                }
                Text(color.label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.color == color ? color.accent : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Theme Preview
    private var themePreview: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.color.gradient)
                    .frame(height: 44)
                    .overlay {
                        Text("Bouton principal")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.color.accent.opacity(0.12))
                    .frame(height: 44)
                    .overlay {
                        Text("Secondaire")
                            .font(.subheadline.bold())
                            .foregroundStyle(theme.color.accent)
                    }
            }
            HStack(spacing: 8) {
                ForEach(["Pecs", "Dos", "Bras"], id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(theme.color.accent.opacity(0.1))
                        .foregroundStyle(theme.color.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - URL Identifiable shim for sheet(item:)

extension URL: Identifiable {
    public var id: String { absoluteString }
}

// MARK: - ShareSheet wrapper around UIActivityViewController

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Folder Picker (for choosing iCloud Drive backup folder)

struct FolderPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.directoryURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents") // default to iCloud Drive root
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
