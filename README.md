# 🎵 MusicSorter.exe

**Auteur** : Maël FOUCAUD  
**But** : Trier automatiquement vos fichiers audio (.mp3 / .flac) par artiste et album pour une intégration facile dans Plex.

---

## 🎬 Aperçu de l'application

![github](https://github.com/user-attachments/assets/59cb473b-4bb5-424f-b697-b9343026592d)


## ⚙️ Fonctionnalités

1. **Filtres de formats**  
   - Ne traite que les fichiers `.mp3` et `.flac`.  
2. **Organisation automatique**  
   - Lit les métadonnées ID3 (TagLibSharp) pour extraire l’artiste et l’album.  
   - Crée, si nécessaire, l’arborescence `Destination\Artiste\Album`.  
   - Déplace chaque piste au bon emplacement.  
3. **Interface graphique**  
   - Simple fenêtre WinForms sous PowerShell (sans console).  
   - Sélecteurs de dossier source et cible, boutons Import/Export de config.  
   - Zone de log enrichie d’emojis pour le suivi en temps réel.  
4. **Gestion de la configuration**  
   - `config.json` sauvegarde vos chemins SourceFolder et DestinationFolder.  
   - Importer/Exporter pour réutiliser vos réglages facilement.  

---

## 🚀 Usage

```powershell
# Placez MusicSorter.exe, logo.ico et TagLibSharp.dll dans le même dossier
.\MusicSorter.exe
