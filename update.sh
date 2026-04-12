#!/usr/bin/env bash
# ============================================
# update.sh — Met à jour GymTracker sur ton iPhone
# ============================================
# Usage : ./update.sh
#
# Ce script :
# 1. Recompile l'app
# 2. Génère le .ipa
# 3. Lance un mini serveur web
# 4. T'affiche l'URL à ouvrir sur ton iPhone
#
# Quand c'est installé, fais Ctrl+C pour quitter.
# ============================================

set -euo pipefail
cd "$(dirname "$0")"

echo ""
echo "🏗  Compilation en cours..."
echo ""

./build-ipa.sh

IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "IP-INTROUVABLE")

echo ""
echo "============================================"
echo ""
echo "📱  Sur ton iPhone, ouvre Safari et va sur :"
echo ""
echo "    http://$IP:8080/GymTracker.ipa"
echo ""
echo "    Puis : Télécharger → Ouvrir avec AltStore"
echo ""
echo "============================================"
echo ""
echo "⏳  Serveur en attente... (Ctrl+C quand c'est installé)"
echo ""

cd build
python3 -m http.server 8080
