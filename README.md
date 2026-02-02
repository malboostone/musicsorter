# 🎵 MusicSorter.exe

**Author** : Maël FOUCAUD  
**Purpose** : Automatically sort your audio files (.mp3 / .flac) by Artist and Album for seamless integration into Plex.

---

## 🎬 App Preview

<img width="677" height="585" alt="image" src="https://github.com/user-attachments/assets/2b8f361e-e954-4128-854d-0343090b5908" />

---

## ⚙️ Features

1. **Format Filtering**  
   - Only processes `.mp3` and `.flac` files.  
2. **Automated Organization**  
   - Reads ID3 metadata (TagLibSharp) to extract Artist and Album tags..  
   - Automatically creates the folder structure: Destination\Artist\Album.  
   - Moves each track to its respective location.
3. **Graphical User Interface (GUI)**  
   - Simple WinForms/WPF window running via PowerShell (no console).
   - Source and Target folder pickers, Import/Export config buttons.
   - Real-time log area enhanced with emojis for tracking.
4. **Configuration Management**  
   - `config.json` stores your SourceFolder and DestinationFolder paths.
   - Import/Export to easily reuse your settings.

---

## 💡 Note on "Vibe-Coding"
This project is "vibe-coded" using ChatGPT (o4-mini-high). I don't claim to provide professional-grade software; I'm simply sharing a tool I use daily to organize my music collection in case it helps someone else. It is provided for free, and the original .ps1 script is available in the repo for full transparency.

---

## 🚀 Usage

```powershell
# Place MusicSorter.exe, logo.ico, and TagLibSharp.dll in the same folder
.\MusicSorter.exe




