import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ThemeManager.self) private var theme
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @State private var cloudFolderConfigured = AutoBackupService.isCloudFolderConfigured
    @State private var showFolderPicker = false

    var body: some View {
        Group {
            if onboardingCompleted {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .overlay {
            if onboardingCompleted && !cloudFolderConfigured {
                cloudSetupOverlay
            }
        }
        .task {
            AutoBackupService.runDailyBackupIfNeeded(context: context)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                AutoBackupService.runDailyBackupIfNeeded(context: context)
                cloudFolderConfigured = AutoBackupService.isCloudFolderConfigured
            }
        }
    }

    // MARK: - iCloud Setup Overlay (for existing users)

    private var cloudSetupOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "icloud.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(theme.color.accent)

                VStack(spacing: 12) {
                    Text("Configure ta sauvegarde")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("Pour protéger tes données, choisis un dossier iCloud Drive. Tes sauvegardes seront copiées automatiquement.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                Spacer()

                Button {
                    showFolderPicker = true
                } label: {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up.fill")
                        Text("Configurer iCloud Drive")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .transition(.opacity)
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerView { url in
                AutoBackupService.setCloudFolder(url)
                withAnimation(.spring) {
                    cloudFolderConfigured = true
                }
                // Copy latest backup immediately
                try? AutoBackupService.backupNow(context: context)
            }
        }
    }
}
