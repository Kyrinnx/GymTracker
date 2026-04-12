# Installer GymTracker sur ton iPhone (gratuit, via AltStore)

## Vue d'ensemble

- **Coût** : 0 €
- **Durée d'install** : ~20 min la première fois, ensuite 1 min par mise à jour
- **Renouvellement** : automatique tous les 7 jours via AltServer (Mac sur le même WiFi)
- **Données** : 100 % locales sur ton iPhone, sauvegardes auto quotidiennes sur iCloud Drive

---

## Prérequis

- Un Mac avec [AltServer](https://altstore.io) installé
- [AltStore](https://altstore.io) installé sur ton iPhone (via USB la première fois)
- [Xcode](https://developer.apple.com/xcode/) et [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Étape 1 — Compiler le .ipa

```bash
./build-ipa.sh
```

Le script régénère le projet Xcode, compile en mode unsigned, et emballe le `.ipa` dans `build/GymTracker.ipa`.

## Étape 2 — Installer via AltStore

**Méthode A — Drag & drop** : glisse `build/GymTracker.ipa` sur l'icône AltServer dans la barre de menus → Install with AltStore → ton iPhone.

**Méthode B — AirDrop** : envoie le `.ipa` via AirDrop → ouvre avec AltStore.

**Méthode C — WiFi** : lance `./update.sh`, puis ouvre l'URL affichée dans Safari sur l'iPhone → Ouvrir avec AltStore.

## Mises à jour

Si le repo est configuré sur GitHub avec une AltStore Source :

```bash
./release.sh 1.x.0 "Description de la mise à jour"
```

AltStore détectera la nouvelle version automatiquement.

## Sauvegardes

L'app crée chaque jour une sauvegarde JSON automatique. Si iCloud Drive est configuré dans les réglages de l'app, les sauvegardes sont copiées dans le cloud.

Pour restaurer : Réglages → Données → Importer un fichier.

## En cas de problème

| Problème | Solution |
|----------|----------|
| L'app expire | AltStore → Refresh All (Mac + iPhone sur le même WiFi) |
| AltServer ne voit pas l'iPhone | Vérifier le même WiFi + iTunes WiFi sync activé |
| Le .ipa ne s'installe pas | AltStore a une limite de 3 apps par Apple ID gratuit |
| Build échoue | `xcodegen generate` puis `open GymTracker.xcodeproj` dans Xcode |
