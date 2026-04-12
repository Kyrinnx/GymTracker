# Installer GymTracker sur ton iPhone (gratuit, via AltStore)

Guide complet pour installer GymTracker sur ton iPhone sans payer le Developer Program Apple.

## Vue d'ensemble

- **Coût** : 0 €
- **Durée d'install** : ~20 minutes la première fois, ensuite 1 minute par mise à jour
- **Renouvellement** : automatique tous les 7 jours via AltServer (Mac allumé sur le même WiFi de temps en temps)
- **Données** : 100 % locales sur ton iPhone, sauvegardes auto quotidiennes dans Files

---

## Étape 1 — Installer AltServer sur ton Mac

1. Va sur **https://altstore.io** → onglet **Downloads** → télécharge **AltServer for Mac**
2. Décompresse et glisse `AltServer.app` dans `/Applications`
3. Lance AltServer (icône losange ⬩ en haut à droite dans la barre de menus du Mac)
4. AltServer te demandera d'installer le **Mail Plug-in** (pour pouvoir détecter ton iPhone via USB la première fois) — accepte
5. Relance Mail.app, va dans **Mail → Settings → General → Manage Plug-ins** → coche **AltPlugin.mailbundle** → relance Mail

> Si l'option Mail Plug-in n'apparaît pas sous macOS récent, AltStore a aussi un mode « WireGuard » alternatif. Suis le guide officiel sur https://faq.altstore.io.

## Étape 2 — Installer AltStore sur ton iPhone

1. **Branche ton iPhone à ton Mac via USB** (uniquement pour cette première fois)
2. Sur ton iPhone, **fais confiance à ton Mac** quand le popup apparaît
3. Clique sur l'icône AltServer (losange) en haut à droite du Mac → **Install AltStore → [Ton iPhone]**
4. AltServer te demandera ton **Apple ID + mot de passe** :
   - **Utilise un Apple ID dédié** si tu peux (crée-en un sur appleid.apple.com), pas ton Apple ID principal — c'est plus safe niveau sécurité
   - Le mot de passe est utilisé localement par AltServer pour générer le certificat de signing, il ne quitte pas ton Mac
5. AltServer installe AltStore sur ton iPhone (~30 secondes)
6. Sur ton iPhone : **Réglages → Général → VPN et gestion d'appareils → ton Apple ID → Faire confiance**
7. Lance **AltStore** sur ton iPhone — tu devrais voir une interface vide

## Étape 3 — Générer le `.ipa` de GymTracker

Sur ton Mac, dans le terminal :

```bash
cd /Users/quentinjordao/Desktop/ANTIGRAVITY/GymTracker
./build-ipa.sh
```

Le script :
1. Régénère le projet Xcode depuis `project.yml`
2. Archive en mode Release sans signature
3. Emballe en `.ipa` dans `build/GymTracker.ipa`

> **Note** : Le script gère automatiquement un bug Xcode 26 qui faisait pendre le build. Si tu vois `ARCHIVE SUCCEEDED`, c'est bon.

## Étape 4 — Installer GymTracker via AltStore

**Méthode A — Drag & drop (le plus simple)**

1. Sur ton Mac, ouvre le Finder dans `build/`
2. Drag `GymTracker.ipa` sur l'icône AltServer (losange ⬩) dans la barre de menu
3. Choisis **Install with AltStore → [Ton iPhone]**
4. AltServer signe avec ton Apple ID et envoie sur ton iPhone (~30 sec)

**Méthode B — AirDrop**

1. AirDrop `build/GymTracker.ipa` vers ton iPhone
2. Sur ton iPhone, le file picker te demande comment l'ouvrir → choisis **AltStore**
3. AltStore re-signe et installe

L'app **GymTracker** apparaît sur ton écran d'accueil avec ton thème.

## Étape 5 — Configurer le refresh automatique

Sur ton iPhone, ouvre **AltStore → onglet My Apps** :
- GymTracker apparaît avec une date d'expiration (7 jours)
- AltStore va le re-signer **automatiquement** dès qu'il détecte AltServer sur le même WiFi
- Pour forcer un refresh manuel : tape **« Refresh All »** (le bouton rond en haut)

> **Tu n'as plus jamais besoin de rebrancher ton iPhone en USB** après cette première install. Tout passe par WiFi.

## Étape 6 — Mettre à jour l'app

Quand on modifie le code de GymTracker ensemble :

```bash
cd /Users/quentinjordao/Desktop/ANTIGRAVITY/GymTracker
./build-ipa.sh
```

Puis relance la méthode A ou B de l'étape 4.

**Tes données sont préservées** lors des mises à jour : iOS garde le conteneur SwiftData de l'app intact tant qu'AltStore reconnaît que c'est la même app (même bundle ID `com.quentin.gymtracker`).

---

## Sauvegardes automatiques

L'app crée chaque jour à l'ouverture une sauvegarde JSON dans :
**Files → Sur mon iPhone → GymTracker → Backups**

Les 30 dernières sont conservées. Tu peux :
- **Les voir / restaurer / partager** depuis Réglages → Sauvegardes automatiques → *Voir toutes les sauvegardes*
- **Les copier sur ton Mac** en branchant ton iPhone : Finder → ton iPhone → onglet Files → GymTracker
- **Les uploader sur iCloud Drive** depuis l'app Files iOS, en faisant glisser le fichier

### Workflow recommandé

1. Une fois par semaine, copie le dernier `.json` du dossier Backups vers iCloud Drive (manuel, mais ça sécurise tout)
2. Si jamais tu désinstalles l'app par erreur ou changes de tel : réinstalle via AltStore → Réglages → *Importer un fichier* → choisis ton JSON → Tout revient

---

## En cas de problème

**L'app expire pendant que je suis en vacances**
- L'app devient grisée et ne se lance plus
- Au retour, allume ton Mac avec AltServer, ouvre AltStore sur l'iPhone (même WiFi), tape *Refresh All*
- L'app se réactive en 30 sec avec **toutes tes données intactes**

**AltServer ne voit pas mon iPhone**
- Vérifie que les deux sont sur le même WiFi
- Vérifie que **iTunes WiFi sync** est activé : branche l'iPhone une fois, ouvre Finder → ton iPhone → coche *Show this iPhone when on Wi-Fi*

**Le `.ipa` ne s'installe pas**
- AltStore a une limite de **3 apps perso simultanées** par Apple ID gratuit
- Vérifie que tu n'en as pas déjà 3 installées
- Sinon supprime AltStore lui-même n'en compte pas dans la limite

**Build échoue avec une erreur Swift**
- Lance `xcodegen generate` puis ouvre le projet dans Xcode pour voir le souci avec un meilleur affichage : `open GymTracker.xcodeproj`

---

## Récap des fichiers

| Fichier | À quoi ça sert |
|---|---|
| `build-ipa.sh` | Génère le `.ipa` à installer dans AltStore |
| `release.sh` | (Optionnel) Publie une release sur GitHub pour AltStore Source |
| `AltStoreSource/source.json` | (Optionnel) Manifest pour auto-update via GitHub Pages |
| `build/GymTracker.ipa` | L'app empaquetée prête à installer |
| `Documents/Backups/*.json` (sur iPhone) | Sauvegardes auto quotidiennes de tes données |
