# GymTracker — Contexte pour Claude

## Le projet

App iOS de suivi musculation, nutrition et jeûne intermittent. Développée en SwiftUI + SwiftData, installée via AltStore (Free Apple ID, pas de Developer Program payant).

**Utilisateur** : Quentin — fait de la muscu, suit sa nutrition et son jeûne. Veut des solutions simples et autonomes. Parle français. Préfère qu'on fasse tout d'un coup sans demander confirmation.

## Contraintes techniques

- **Free Apple ID** : pas de CloudKit, Live Activity, Widget
- **Stockage 100% local** SwiftData (`cloudKitDatabase: .none`)
- **HealthKit activé** : sync nutrition (macros, eau) + poids/masse grasse vers l'app Santé (toggle dans Settings, `@AppStorage("healthKitEnabled")`)
- **Installation via AltStore** : re-sign auto tous les 7 jours via AltServer WiFi
- **Entitlements** : HealthKit uniquement
- **XcodeGen** : le projet est généré depuis `project.yml`, pas de `.xcodeproj` à modifier à la main
- **Bug Xcode 26** : `clang -v -E -dM` pend parfois au build. Workaround dans `build-ipa.sh`
- **DerivedData** : toujours dans `/tmp` pour éviter les corruptions disk I/O

## Architecture

```
Sources/
├── App/            → GymTrackerApp, RootView, ContentView (5 onglets)
├── Models/         → SwiftData models (WorkoutSession, MealEntry, FastingSession, etc.)
├── Views/
│   ├── Home/       → HomeView, ExerciseLibraryView
│   ├── Nutrition/  → NutritionView, FoodSearchView, BarcodeScannerView, NutritionSettingsView
│   ├── Records/    → RecordsView (progrès, poids, PRs, 1RM)
│   ├── History/    → HistoryView
│   ├── Session/    → SessionView, ExercisePickerView
│   ├── Settings/   → SettingsView, BackupsListView, TemplateListView, TemplateEditorView
│   ├── Fasting/    → FastingView
│   ├── Onboarding/ → OnboardingView
│   └── Components/ → BodyMapView
├── Services/       → AutoBackupService, DataExportService, NotificationService, HealthKitService
├── Theme/          → AppTheme (ThemeManager, 6 couleurs)
└── Shared/         → (vide, était pour Live Activity)
```

## Relations SwiftData (optionnelles pour compat CloudKit futur)

- `WorkoutSession.exercises: [ExerciseEntry]?` → accès via `.exercisesArray`
- `ExerciseEntry.sets: [WorkoutSet]?` → accès via `.setsArray`
- `CustomTemplate.exercises: [CustomTemplateExercise]?` → accès via `.exercisesArray`
- Tous les champs ont des defaults pour migration

## Workflow de mise à jour

```bash
cd ~/Desktop/ANTIGRAVITY/GymTracker
./update.sh   # compile + sert le .ipa + affiche l'URL Safari
```
iPhone Safari → URL → Ouvrir avec AltStore. Ctrl+C sur Mac quand c'est installé.

## Sauvegardes

- Auto quotidien dans `Documents/GymTracker Backups/Sauvegardes/`
- Copie auto vers iCloud Drive (dossier configuré par l'utilisateur via security-scoped bookmark)
- Backup de sécurité dans `Sécurité/` avant chaque effacement de données
- Export/Import JSON complet dans Réglages

## À chaque nouvelle session

Quand Quentin revient avec une demande, commence par :

1. **Vérifier que le projet compile** : `cd ~/Desktop/ANTIGRAVITY/GymTracker && xcodegen generate && xcodebuild ...`
2. **Lire les fichiers modifiés récemment** si pertinent
3. **Appliquer les changements demandés**
4. **Rebuild le .ipa** à la fin si des fichiers Swift ont changé
5. **Ne jamais ajouter** de capabilities payantes (CloudKit, Live Activity, Widget) — HealthKit est gratuit et déjà intégré
6. **Mettre à jour ce fichier CLAUDE.md** si l'architecture, les contraintes, les conventions ou la liste des améliorations changent. Ce fichier doit toujours refléter l'état actuel du projet.

## Points connus à améliorer

- [ ] Body map (mannequin) : les shapes sont basiques, à refaire plus stylé
- [ ] Scanner code-barres : codé mais écran noir possible sur certains appareils (fix UIViewControllerRepresentable fait mais pas testé)
- [ ] Presets rapides nutrition : l'ancienne version en avait, la nouvelle n'en a plus
- [ ] Le `.ipa` contient un `__preview.dylib` inutile en Debug (pas grave mais ajoute du poids)
- [ ] Pas de graphe d'évolution des macros/calories dans le temps
- [ ] Pas de mode sombre dédié pour la nutrition (suit le thème global)
- [ ] Possibilité d'ajouter un mode "Repas" (sauvegarder un repas complet en favori, pas juste un aliment)

## Conventions

- Tout en **français** dans l'UI (accents compris)
- Pas de emoji dans le code sauf si l'utilisateur le demande
- Tester le build avant de proposer une mise à jour
- Ne pas créer de fichiers README/docs sauf demandé
- Utiliser `exercisesArray` / `setsArray` pour accéder aux relations optionnelles
- Les `@AppStorage` keys sont en camelCase anglais (ex: `calGoal`, `waterGoalMl`, `fastingMethod`)
