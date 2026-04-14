import SwiftUI
import SwiftData

struct BackupsListView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var backups: [BackupFile] = []
    @State private var shareItem: ExportURLItem?
    @State private var pendingRestore: BackupFile?
    @State private var resultMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if backups.isEmpty {
                    ContentUnavailableView {
                        Label("Aucune sauvegarde", systemImage: "tray")
                    } description: {
                        Text("Les sauvegardes automatiques apparaîtront ici dès demain.")
                    }
                } else {
                    Section {
                        ForEach(backups) { backup in
                            backupRow(backup)
                        }
                    } footer: {
                        Text("Tu peux aussi accéder à ces fichiers depuis l'app Files iOS → Sur mon iPhone → GymTracker → Backups, ou en branchant ton iPhone à un Mac.")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Sauvegardes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .task { reload() }
            .sheet(item: $shareItem) { item in
                ShareSheet(url: item.url)
            }
            .confirmationDialog(
                "Restaurer cette sauvegarde\u{00A0}?",
                isPresented: Binding(
                    get: { pendingRestore != nil },
                    set: { if !$0 { pendingRestore = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Fusionner avec les données actuelles") {
                    if let backup = pendingRestore {
                        restore(backup, replaceAll: false)
                    }
                }
                Button("Remplacer tout", role: .destructive) {
                    if let backup = pendingRestore {
                        restore(backup, replaceAll: true)
                    }
                }
                Button("Annuler", role: .cancel) {
                    pendingRestore = nil
                }
            } message: {
                if let backup = pendingRestore {
                    Text("Sauvegarde du \(backup.date.formatted(date: .abbreviated, time: .shortened))")
                }
            }
            .alert("Restauration", isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(resultMessage ?? "")
            }
        }
    }

    private func backupRow(_ backup: BackupFile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: backup.isAutomatic ? "clock.arrow.circlepath" : "hand.tap.fill")
                .foregroundStyle(backup.isAutomatic ? theme.color.accent : .orange)
                .frame(width: 32, height: 32)
                .background((backup.isAutomatic ? theme.color.accent : .orange).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(backup.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(backup.isAutomatic ? "Auto" : "Manuel") · \(backup.sizeString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button {
                    pendingRestore = backup
                } label: {
                    Label("Restaurer", systemImage: "arrow.counterclockwise")
                }
                Button {
                    shareItem = ExportURLItem(url: backup.url)
                } label: {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    delete(backup)
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Options de la sauvegarde")
        }
        .padding(.vertical, 4)
    }

    private func reload() {
        backups = AutoBackupService.listBackups()
    }

    private func restore(_ backup: BackupFile, replaceAll: Bool) {
        do {
            try DataExportService.importAll(from: backup.url, into: context, replaceAll: replaceAll)
            resultMessage = "Restauration réussie ! 🎉"
        } catch {
            resultMessage = "Échec\u{00A0}: \(error.localizedDescription)"
        }
        pendingRestore = nil
    }

    private func delete(_ backup: BackupFile) {
        try? AutoBackupService.deleteBackup(backup)
        reload()
    }
}
