#!/bin/bash
# Script de construction du paquet .deb pour Music Sorter
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/debian-pkg"
VERSION="1.0.0"
PKG_NAME="musicsorter_${VERSION}_all"

echo "🔨 Construction du paquet $PKG_NAME.deb..."

# Nettoyage
rm -rf "$PKG_DIR/usr"
rm -f "$SCRIPT_DIR/${PKG_NAME}.deb"

# Création de l'arborescence
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/musicsorter"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$PKG_DIR/usr/share/pixmaps"

# Copie de l'application
cp "$SCRIPT_DIR/musicsorter.py" "$PKG_DIR/usr/share/musicsorter/musicsorter.py"

# Copie de l'icône
cp "$SCRIPT_DIR/musicsorter.png" "$PKG_DIR/usr/share/icons/hicolor/256x256/apps/musicsorter.png"
cp "$SCRIPT_DIR/musicsorter.png" "$PKG_DIR/usr/share/pixmaps/musicsorter.png"
cp "$SCRIPT_DIR/musicsorter.png" "$PKG_DIR/usr/share/musicsorter/musicsorter.png"

# Création du lanceur
cat > "$PKG_DIR/usr/bin/musicsorter" << 'EOF'
#!/bin/bash
exec python3 /usr/share/musicsorter/musicsorter.py "$@"
EOF
chmod 755 "$PKG_DIR/usr/bin/musicsorter"

# Copie du .desktop
cp "$SCRIPT_DIR/musicsorter.desktop" "$PKG_DIR/usr/share/applications/musicsorter.desktop"

# Permissions
chmod 755 "$PKG_DIR/DEBIAN"
find "$PKG_DIR/usr" -type d -exec chmod 755 {} \;
find "$PKG_DIR/usr" -type f -exec chmod 644 {} \;
chmod 755 "$PKG_DIR/usr/bin/musicsorter"
chmod 755 "$PKG_DIR/usr/share/musicsorter/musicsorter.py"

# Construction du .deb
dpkg-deb --build "$PKG_DIR" "$SCRIPT_DIR/${PKG_NAME}.deb"

echo ""
echo "✅ Paquet créé : $SCRIPT_DIR/${PKG_NAME}.deb"
echo ""
echo "Pour installer :"
echo "  sudo dpkg -i ${PKG_NAME}.deb"
echo "  sudo apt-get install -f   # si dépendances manquantes"
echo ""
echo "Pour désinstaller :"
echo "  sudo dpkg -r musicsorter"
