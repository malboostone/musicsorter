<div align="center">
  <img src="musicsorter.png" alt="Music Sorter Logo" width="128" />
  <h1>Music Sorter</h1>
  <p><strong>Triez facilement et automatiquement votre bibliothèque musicale pour Plex.</strong></p>
</div>

---

**Music Sorter** est un utilitaire graphique natif pour Linux Mint (et autres distributions Ubuntu/Debian) permettant de trier automatiquement vos fichiers audio `.mp3` et `.flac` en lisant leurs métadonnées intégrées.

Initialement conçu sous PowerShell, ce script a été entièrement réécrit en **Python** avec **GTK 3** pour offrir une interface moderne, performante et parfaitement intégrée au bureau Linux.

## ✨ Fonctionnalités

- **🔍 Tri par Métadonnées** : Extrait l'Artiste et l'Album des tags ID3 (MP3) ou Vorbis (FLAC) via `mutagen`.
- **📂 Organisation compatible Plex** : Déplace les fichiers dans la structure `Destination / Artiste / Album / Fichier`.
- **🚀 Exécution asynchrone** : Le tri s'effectue en arrière-plan avec une barre de progression fluide.
- **🎨 Interface Moderne** : Design soigné GTK 3 avec thème sombre personnalisé (CSS).
- **⚙️ Configuration Intelligente** : Auto-détection et import automatique du fichier `config.json` au démarrage.
- **🌐 Support Partage Réseau (SMB)** : Gère les points de montage distants inaccessibles aux copies avancées de métadonnées Posix.

## 📦 Installation (Linux Mint / Debian / Ubuntu)

La méthode la plus simple est d'utiliser le paquet Debian `.deb` fourni dans les Releases.

1. Téléchargez le dernier `.deb` depuis la page **[Releases](../../releases/latest)**.
2. Double-cliquez dessus ou exécutez la commande suivante dans le terminal :

```bash
sudo dpkg -i musicsorter_*_all.deb
sudo apt-get install -f   # Si des dépendances sont manquantes
```

Une fois installé, lancez **Music Sorter** depuis le menu de vos applications (catégorie Son et Vidéo / Utilitaires).

## 🪟 Installation (Windows)
1. Téléchargez l'archive `.zip` correspondant à votre langue (**`Windows_Francais.zip`** ou **`Windows_English.zip`**) depuis la page **[Releases](../../releases/latest)**.
2. Extrayez l'intégralité du dossier sur votre ordinateur.
3. Lancez simplement le fichier `.exe` contenu à l'intérieur. L'icône (`logo.ico`) et la bibliothèque (`TagLibSharp.dll`) sont déjà inclus et doivent impérativement rester dans le même dossier que l'exécutable. Aucune installation supplémentaire n'est requise.

## 🛠️ Compilation Manuelle / Développement

Cloner le dépôt et construire le paquet soi-même :

```bash
git clone https://github.com/votre-pseudo/musicsorter.git
cd musicsorter
bash build-deb.sh
sudo dpkg -i musicsorter_1.0.0_all.deb
```

### Dépendances requises

```bash
sudo apt install python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 python3-mutagen
```

## 📜 Licence

Développé par **Maël FOUCAUD**. Libre d'utilisation.
