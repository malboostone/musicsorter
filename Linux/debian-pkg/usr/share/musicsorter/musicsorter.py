#!/usr/bin/env python3
# Music Sorter - Version Linux
# Développé par Maël FOUCAUD (converti depuis PowerShell)

import gi
gi.require_version("Gtk", "3.0")

import json
import os
import re
import shutil
import threading
from pathlib import Path

from gi.repository import Gtk, Gdk, GLib, Pango

import mutagen

APP_ID = "fr.musicsorter.app"
APP_VERSION = "1.0.0"
CONFIG_FILENAME = "config.json"


def get_config_paths():
    """Retourne la liste des chemins possibles pour config.json, par priorité."""
    paths = []
    # 1. ~/.config/musicsorter/config.json
    xdg = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    paths.append(os.path.join(xdg, "musicsorter", CONFIG_FILENAME))
    # 2. À côté du script (ou de l'exécutable installé)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    paths.append(os.path.join(script_dir, CONFIG_FILENAME))
    return paths


def load_config():
    """Charge la configuration depuis le premier config.json trouvé."""
    for path in get_config_paths():
        if os.path.isfile(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                return data, path
            except (json.JSONDecodeError, OSError):
                continue
    return {"SourceFolder": "", "DestinationFolder": ""}, None


def save_config(src, dest):
    """Sauvegarde la configuration dans ~/.config/musicsorter/config.json."""
    xdg = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    config_dir = os.path.join(xdg, "musicsorter")
    os.makedirs(config_dir, exist_ok=True)
    path = os.path.join(config_dir, CONFIG_FILENAME)
    data = {"SourceFolder": src, "DestinationFolder": dest}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    return path


def clean_name(name):
    """Nettoie un nom pour l'utiliser comme nom de dossier."""
    if not name or not name.strip():
        return "Inconnu"
    cleaned = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', str(name))
    return cleaned.strip() or "Inconnu"


def get_artist(audio):
    """Extrait l'artiste depuis les métadonnées audio (compatible MP3/FLAC/etc.)."""
    tags = audio.tags
    if tags is None:
        return None

    # MP3 (ID3)
    if hasattr(tags, 'getall'):
        for frame_id in ('TPE2', 'TPE1'):
            frames = tags.getall(frame_id)
            if frames:
                text = str(frames[0])
                if text.strip():
                    return text.strip()

    # FLAC / Vorbis / OGG
    for key in ('albumartist', 'artist', 'ALBUMARTIST', 'ARTIST'):
        if key in tags:
            val = tags[key]
            if isinstance(val, list) and val:
                if str(val[0]).strip():
                    return str(val[0]).strip()
            elif isinstance(val, str) and val.strip():
                return val.strip()

    # Fallback
    if hasattr(audio, 'get'):
        for key in ('albumartist', 'artist'):
            val = audio.get(key)
            if val and isinstance(val, list) and val[0].strip():
                return str(val[0]).strip()

    return None


def get_album(audio):
    """Extrait l'album depuis les métadonnées audio."""
    tags = audio.tags
    if tags is None:
        return None

    # MP3 (ID3) - TALB
    if hasattr(tags, 'getall'):
        frames = tags.getall('TALB')
        if frames:
            text = str(frames[0])
            if text.strip():
                return text.strip()

    # FLAC / Vorbis / OGG
    for key in ('album', 'ALBUM'):
        if key in tags:
            val = tags[key]
            if isinstance(val, list) and val:
                if str(val[0]).strip():
                    return str(val[0]).strip()
            elif isinstance(val, str) and val.strip():
                return val.strip()

    # Fallback
    if hasattr(audio, 'get'):
        val = audio.get('album')
        if val and isinstance(val, list) and val[0].strip():
            return str(val[0]).strip()

    return None


# ─── CSS personnalisé ───────────────────────────────────────────────

CSS = """
#main-window {
    background: #1a1a2e;
}

#app-title {
    font-size: 28px;
    font-weight: 800;
    color: #e94560;
    letter-spacing: 1px;
}

#app-subtitle {
    font-size: 12px;
    color: rgba(255, 255, 255, 0.45);
    letter-spacing: 0.5px;
}

#config-card {
    background: rgba(255, 255, 255, 0.04);
    border-radius: 16px;
    border: 1px solid rgba(255, 255, 255, 0.07);
    padding: 20px;
}

.field-label {
    color: rgba(255, 255, 255, 0.6);
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 1px;
}

.field-entry {
    background: rgba(0, 0, 0, 0.35);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    color: #ffffff;
    padding: 6px 12px;
    font-size: 13px;
    min-height: 22px;
}

.field-entry:focus {
    border-color: #e94560;
    box-shadow: 0 0 0 2px rgba(233, 69, 96, 0.15);
}

.browse-btn {
    background: rgba(233, 69, 96, 0.12);
    border: 1px solid rgba(233, 69, 96, 0.25);
    border-radius: 10px;
    color: #e94560;
    font-weight: 700;
    min-width: 42px;
    min-height: 36px;
    padding: 0 4px;
}

.browse-btn:hover {
    background: rgba(233, 69, 96, 0.22);
    border-color: #e94560;
}

.action-btn {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 12px;
    color: rgba(255, 255, 255, 0.75);
    font-weight: 600;
    font-size: 13px;
    padding: 8px 16px;
    min-height: 18px;
}

.action-btn:hover {
    background: rgba(255, 255, 255, 0.09);
    border-color: rgba(255, 255, 255, 0.18);
    color: #ffffff;
}

.start-btn {
    background-image: linear-gradient(135deg, #e94560, #c23152);
    border: none;
    border-radius: 12px;
    color: #ffffff;
    font-weight: 700;
    font-size: 14px;
    padding: 8px 26px;
    min-height: 18px;
    box-shadow: 0 4px 15px rgba(233, 69, 96, 0.25);
}

.start-btn:hover {
    background-image: linear-gradient(135deg, #ff5a7a, #e94560);
    box-shadow: 0 6px 20px rgba(233, 69, 96, 0.35);
}

.start-btn:disabled {
    opacity: 0.45;
}

#log-frame {
    background: rgba(0, 0, 0, 0.35);
    border-radius: 14px;
    border: 1px solid rgba(255, 255, 255, 0.05);
    padding: 12px;
}

#log-view, #log-view text {
    background: transparent;
    color: rgba(255, 255, 255, 0.82);
    font-family: "JetBrains Mono", "Fira Code", "Cascadia Code", "Consolas", monospace;
    font-size: 12px;
}

.progress-bar, .progress-bar trough {
    min-height: 5px;
    border-radius: 3px;
    background: rgba(255, 255, 255, 0.05);
}

.progress-bar trough progress {
    min-height: 5px;
    border-radius: 3px;
    background-image: linear-gradient(90deg, #e94560, #ff6b8a);
}

.status-label {
    color: rgba(255, 255, 255, 0.35);
    font-size: 11px;
}
"""


class MusicSorterWindow(Gtk.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_title("🎶 Music Sorter")
        self.set_default_size(780, 680)
        self.set_name("main-window")
        self.set_position(Gtk.WindowPosition.CENTER)
        self._sorting = False

        # Icône de la fenêtre
        icon_candidates = [
            os.path.join(os.path.dirname(os.path.abspath(__file__)), "musicsorter.png"),
            "/usr/share/musicsorter/musicsorter.png",
            "/usr/share/icons/hicolor/256x256/apps/musicsorter.png",
            "/usr/share/pixmaps/musicsorter.png",
        ]
        for icon_path in icon_candidates:
            if os.path.isfile(icon_path):
                try:
                    self.set_icon_from_file(icon_path)
                except Exception:
                    pass
                break

        # Layout principal
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_box.set_margin_start(24)
        main_box.set_margin_end(24)
        main_box.set_margin_top(16)
        main_box.set_margin_bottom(24)
        self.add(main_box)

        # ── Titre ──
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        title_box.set_margin_bottom(20)
        title_box.set_halign(Gtk.Align.CENTER)

        title = Gtk.Label(label="🎶  Music Sorter")
        title.set_name("app-title")
        title_box.pack_start(title, False, False, 0)

        subtitle = Gtk.Label(label="Triez votre musique par Artiste / Album — compatible Plex")
        subtitle.set_name("app-subtitle")
        title_box.pack_start(subtitle, False, False, 0)

        main_box.pack_start(title_box, False, False, 0)

        # ── Carte configuration ──
        config_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        config_card.set_name("config-card")
        config_card.set_margin_bottom(14)

        # Dossier source
        src_label = Gtk.Label(label="DOSSIER SOURCE", xalign=0)
        src_label.get_style_context().add_class("field-label")
        config_card.pack_start(src_label, False, False, 0)

        src_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.source_entry = Gtk.Entry()
        self.source_entry.set_hexpand(True)
        self.source_entry.set_placeholder_text("Sélectionner le dossier contenant votre musique…")
        self.source_entry.get_style_context().add_class("field-entry")
        src_row.pack_start(self.source_entry, True, True, 0)

        src_btn = Gtk.Button(label="…")
        src_btn.get_style_context().add_class("browse-btn")
        src_btn.connect("clicked", self._on_browse_source)
        src_row.pack_start(src_btn, False, False, 0)
        config_card.pack_start(src_row, False, False, 0)

        # Dossier destination
        dest_label = Gtk.Label(label="DOSSIER CIBLE", xalign=0)
        dest_label.get_style_context().add_class("field-label")
        config_card.pack_start(dest_label, False, False, 0)

        dest_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.dest_entry = Gtk.Entry()
        self.dest_entry.set_hexpand(True)
        self.dest_entry.set_placeholder_text("Sélectionner le dossier de destination…")
        self.dest_entry.get_style_context().add_class("field-entry")
        dest_row.pack_start(self.dest_entry, True, True, 0)

        dest_btn = Gtk.Button(label="…")
        dest_btn.get_style_context().add_class("browse-btn")
        dest_btn.connect("clicked", self._on_browse_dest)
        dest_row.pack_start(dest_btn, False, False, 0)
        config_card.pack_start(dest_row, False, False, 0)

        main_box.pack_start(config_card, False, False, 0)

        # ── Barre de boutons ──
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        btn_box.set_halign(Gtk.Align.CENTER)
        btn_box.set_margin_bottom(14)

        import_btn = Gtk.Button(label="📥  Importer config")
        import_btn.get_style_context().add_class("action-btn")
        import_btn.connect("clicked", self._on_import_config)
        btn_box.pack_start(import_btn, False, False, 0)

        export_btn = Gtk.Button(label="📤  Exporter config")
        export_btn.get_style_context().add_class("action-btn")
        export_btn.connect("clicked", self._on_export_config)
        btn_box.pack_start(export_btn, False, False, 0)

        self.start_btn = Gtk.Button(label="🚀  Lancer le tri")
        self.start_btn.get_style_context().add_class("start-btn")
        self.start_btn.connect("clicked", self._on_start_sort)
        btn_box.pack_start(self.start_btn, False, False, 0)

        main_box.pack_start(btn_box, False, False, 0)

        # ── Barre de progression ──
        self.progress = Gtk.ProgressBar()
        self.progress.get_style_context().add_class("progress-bar")
        self.progress.set_margin_bottom(4)
        main_box.pack_start(self.progress, False, False, 0)

        self.status_label = Gtk.Label(label="Prêt", xalign=0)
        self.status_label.get_style_context().add_class("status-label")
        self.status_label.set_margin_bottom(10)
        main_box.pack_start(self.status_label, False, False, 0)

        # ── Zone de log ──
        log_frame = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        log_frame.set_name("log-frame")

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)

        self.log_view = Gtk.TextView()
        self.log_view.set_name("log-view")
        self.log_view.set_editable(False)
        self.log_view.set_cursor_visible(False)
        self.log_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.log_view.set_left_margin(8)
        self.log_view.set_right_margin(8)
        self.log_view.set_top_margin(8)
        self.log_view.set_bottom_margin(8)
        self.log_buffer = self.log_view.get_buffer()

        scroll.add(self.log_view)
        log_frame.pack_start(scroll, True, True, 0)
        main_box.pack_start(log_frame, True, True, 0)

        # ── Message initial ──
        welcome = (
            "🎶 Music Sorter v{ver}\n"
            "• Trie les fichiers .mp3 et .flac\n"
            "• Organisation par Artiste/Album (compatible Plex)\n"
            "• Développé par Maël FOUCAUD\n"
            "\n"
            "🛠️ Comment l'utiliser :\n"
            "  1) Sélectionnez les dossiers source et cible\n"
            "  2) Cliquez sur « Lancer le tri »\n"
            "  3) Suivez la progression ici\n"
            "\n"
            "⚙️ Configuration :\n"
            "  • Import/Export manuels via les boutons\n"
            "  • Auto-import si config.json est détecté au lancement\n"
            "───────────────────────────────────────────────\n"
        ).format(ver=APP_VERSION)
        self.log_buffer.set_text(welcome)

        # ── Auto-import config ──
        self._auto_import_config()

        self.show_all()

    # ─── Auto-import ─────────────────────────────────────────────────

    def _auto_import_config(self):
        cfg, path = load_config()
        if path and (cfg.get("SourceFolder") or cfg.get("DestinationFolder")):
            self.source_entry.set_text(cfg.get("SourceFolder", ""))
            self.dest_entry.set_text(cfg.get("DestinationFolder", ""))
            self._log(f"✔ Configuration chargée automatiquement depuis :\n   {path}\n")
        else:
            self._log("ℹ Aucune configuration trouvée. Sélectionnez vos dossiers.\n")

    # ─── Logging ─────────────────────────────────────────────────────

    def _log(self, text):
        end_iter = self.log_buffer.get_end_iter()
        self.log_buffer.insert(end_iter, text + "\n")
        # Auto-scroll
        mark = self.log_buffer.create_mark(None, self.log_buffer.get_end_iter(), False)
        self.log_view.scroll_mark_onscreen(mark)
        self.log_buffer.delete_mark(mark)

    # ─── Sélection de dossiers ───────────────────────────────────────

    def _on_browse_source(self, btn):
        self._pick_folder("Sélectionner le dossier source", self.source_entry)

    def _on_browse_dest(self, btn):
        self._pick_folder("Sélectionner le dossier cible", self.dest_entry)

    def _pick_folder(self, title, entry):
        dialog = Gtk.FileChooserDialog(
            title=title,
            parent=self,
            action=Gtk.FileChooserAction.SELECT_FOLDER,
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OPEN, Gtk.ResponseType.OK,
        )
        # Préremplir avec le chemin actuel si existant
        current = entry.get_text()
        if current and os.path.isdir(current):
            dialog.set_current_folder(current)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            entry.set_text(dialog.get_filename())
        dialog.destroy()

    # ─── Import / Export config ──────────────────────────────────────

    def _on_import_config(self, btn):
        dialog = Gtk.FileChooserDialog(
            title="Importer un fichier config.json",
            parent=self,
            action=Gtk.FileChooserAction.OPEN,
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OPEN, Gtk.ResponseType.OK,
        )
        json_filter = Gtk.FileFilter()
        json_filter.set_name("Fichiers JSON")
        json_filter.add_pattern("*.json")
        dialog.add_filter(json_filter)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            path = dialog.get_filename()
            try:
                with open(path, "r", encoding="utf-8") as f:
                    cfg = json.load(f)
                self.source_entry.set_text(cfg.get("SourceFolder", ""))
                self.dest_entry.set_text(cfg.get("DestinationFolder", ""))
                self._log(f"✔ Configuration importée depuis : {path}")
            except (json.JSONDecodeError, OSError) as e:
                self._log(f"❌ Erreur lors de l'import : {e}")
        dialog.destroy()

    def _on_export_config(self, btn):
        src = self.source_entry.get_text()
        dest = self.dest_entry.get_text()
        path = save_config(src, dest)
        self._log(f"✔ Configuration sauvegardée dans : {path}")

    # ─── Tri des fichiers ────────────────────────────────────────────

    def _on_start_sort(self, btn):
        src = self.source_entry.get_text()
        dest = self.dest_entry.get_text()

        if not src or not os.path.isdir(src):
            self._show_error("Le dossier source est invalide ou n'existe pas.")
            return
        if not dest or not os.path.isdir(dest):
            self._show_error("Le dossier cible est invalide ou n'existe pas.")
            return

        self._sorting = True
        self.start_btn.set_sensitive(False)
        self.progress.set_fraction(0)
        self.status_label.set_text("Analyse en cours…")
        self._log("\n🚀 Lancement du tri…")

        # Sauvegarde automatique
        save_config(src, dest)

        thread = threading.Thread(target=self._sort_worker, args=(src, dest), daemon=True)
        thread.start()

    def _show_error(self, message):
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=message,
        )
        dialog.run()
        dialog.destroy()

    def _sort_worker(self, src, dest):
        """Thread de travail pour le tri."""
        audio_files = []
        for root, _, files in os.walk(src):
            for fname in files:
                if fname.lower().endswith(('.mp3', '.flac')):
                    audio_files.append(os.path.join(root, fname))

        total = len(audio_files)
        if total == 0:
            GLib.idle_add(self._log, "⚠ Aucun fichier .mp3 ou .flac trouvé dans le dossier source.")
            GLib.idle_add(self._sort_finished)
            return

        GLib.idle_add(self._log, f"📂 {total} fichier(s) audio trouvé(s).\n")

        moved = 0
        errors = 0
        for i, filepath in enumerate(audio_files, 1):
            fname = os.path.basename(filepath)
            try:
                audio = mutagen.File(filepath)
                if audio is None:
                    raise ValueError("Format non reconnu par mutagen")

                raw_artist = get_artist(audio)
                artist = clean_name(raw_artist)
                album = clean_name(get_album(audio))

                target_dir = os.path.join(dest, artist, album)
                os.makedirs(target_dir, exist_ok=True)

                target_path = os.path.join(target_dir, fname)
                try:
                    os.rename(filepath, target_path)
                except OSError:
                    # Fallback ultime pour SMB (gvfs) : copyfile ne copie QUE les données,
                    # aucune permission ou métadonnée POSIX qui causerait l'erreur 95.
                    shutil.copyfile(filepath, target_path)
                    os.remove(filepath)
                moved += 1

                GLib.idle_add(self._log, f"  ✔ {fname} → {artist}/{album}/")
            except Exception as e:
                errors += 1
                GLib.idle_add(self._log, f"  ❌ {fname} — {e}")

            fraction = i / total
            GLib.idle_add(self.progress.set_fraction, fraction)
            GLib.idle_add(
                self.status_label.set_text,
                f"Traitement : {i}/{total} ({int(fraction * 100)}%)"
            )

        GLib.idle_add(
            self._log,
            f"\n🎉 Terminé ! {moved} fichier(s) déplacé(s), {errors} erreur(s)."
        )
        GLib.idle_add(self._sort_finished)

    def _sort_finished(self):
        self._sorting = False
        self.start_btn.set_sensitive(True)
        self.progress.set_fraction(1.0)
        self.status_label.set_text("Terminé ✔")


class MusicSorterApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID)

    def do_activate(self):
        # Chargement du CSS
        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(CSS.encode('utf-8'))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        win = MusicSorterWindow(application=self)
        win.present()


def main():
    app = MusicSorterApp()
    app.run(None)


if __name__ == "__main__":
    main()
