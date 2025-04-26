🎵 MusicSorter.exe

Auteur : Maël FOUCAUD
But : Trier automatiquement vos fichiers audio (.mp3 / .flac) par artiste et album pour une intégration facile dans Plex.

🖼️ Aperçu de l'application



![github](https://github.com/user-attachments/assets/59cb473b-4bb5-424f-b697-b9343026592d)

⚙️ Fonctionnalités

Filtres de formats

Ne traite que les fichiers .mp3 et .flac.

Organisation automatique

Lit les métadonnées ID3 (TagLibSharp) pour extraire l’artiste et l’album.

Crée, si nécessaire, l’arborescence Destination/Artiste/Album.

Déplace chaque piste au bon emplacement.

Interface graphique

Fenêtre WinForms sous PowerShell (sans console).

Sélecteurs de dossier source et cible, boutons Import/Export de config.

Zone de log enrichie d’emojis pour le suivi en temps réel.

Gestion de la configuration

config.json sauvegarde vos chemins SourceFolder et DestinationFolder.

Importer/Exporter pour réutiliser vos réglages facilement.

🚀 Usage

# Placez MusicSorter.exe et TagLibSharp.dll dans le même dossier
.\MusicSorter.exe

Sélectionnez le dossier source contenant vos fichiers audio.

Sélectionnez le dossier cible où créer les répertoires Artiste/Album.

Cliquez sur “Lancer le tri” et suivez la progression dans la zone de debug.

🔧 Personnalisation

Formats supportés : modifiez la variable $extensions dans le script pour ajouter d’autres types.

Police de log : changez Segoe UI Emoji pour une autre police supportant les emojis.

Icône : remplacez logo.ico pour personnaliser l’icône de la fenêtre.
