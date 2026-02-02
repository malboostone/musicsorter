# Music Sorter - Version Française (Stable)
# Développé par Maël FOUCAUD avec l'aide de ChatGPT o4-mini-high

# 1. Chargement des dépendances
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms

# Détection du dossier robuste pour ps2exe
$currentModule = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
if ($currentModule -like "*powershell*") {
    # On est dans l'éditeur ou console PS
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = Get-Location }
} else {
    # On est dans l'EXE compilé
    $scriptDir = Split-Path -Parent $currentModule
}

# Vérification finale du chemin
if ($null -eq $scriptDir) { $scriptDir = "." }

# 2. Chargement robuste de la DLL
$dllName = "TagLibSharp.dll"
$dllPath = Join-Path $scriptDir $dllName
$dllLoaded = $false

if (Test-Path $dllPath) {
    try {
        Add-Type -Path $dllPath
        $dllLoaded = $true
    } catch { 
        [System.Windows.MessageBox]::Show("Erreur lors du chargement de TagLibSharp.dll : $($_.Exception.Message)")
    }
}

# 3. Logique de Configuration
$configPath = Join-Path $scriptDir "config.json"
function Load-Config {
    if (Test-Path $configPath) { return Get-Content $configPath -Raw | ConvertFrom-Json }
    return @{ SourceFolder = ""; DestinationFolder = "" }
}
function Save-Config($src, $dest) {
    @{ SourceFolder = $src; DestinationFolder = $dest } | ConvertTo-Json | Set-Content $configPath
}

# 4. Fonctions Utilitaires
function Clean-Name($name) {
    if ([string]::IsNullOrWhiteSpace($name)) { return "Inconnu" }
    $invalidChars = [IO.Path]::GetInvalidFileNameChars()
    $s = [string]$name
    foreach ($char in $invalidChars) { $s = $s.Replace($char, "_") }
    return $s.Trim()
}

# 5. Définition de l'interface (XAML)
$XamlString = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Music Sorter" Height="600" Width="700" FontFamily="Segoe UI Emoji" FontSize="13">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" VerticalAlignment="Center">Dossier source :</TextBlock>
        <TextBox x:Name="SourceTextBox" Grid.Row="0" Grid.Column="1" Margin="10,5" Height="25" VerticalContentAlignment="Center"/>
        <Button x:Name="BrowseSource" Content="..." Grid.Row="0" Grid.Column="2" Width="40" Height="25"/>

        <TextBlock Grid.Row="1" VerticalAlignment="Center">Dossier cible :</TextBlock>
        <TextBox x:Name="DestinationTextBox" Grid.Row="1" Grid.Column="1" Margin="10,5" Height="25" VerticalContentAlignment="Center"/>
        <Button x:Name="BrowseDestination" Content="..." Grid.Row="1" Grid.Column="2" Width="40" Height="25"/>

        <StackPanel Grid.Row="2" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,15">
            <Button x:Name="ImportBtn" Content="Importer config" Width="120" Height="30" Margin="5,0"/>
            <Button x:Name="ExportBtn" Content="Exporter config" Width="120" Height="30" Margin="5,0"/>
            <Button x:Name="StartBtn" Content="Lancer le tri" Width="120" Height="30" Margin="5,0"/>
        </StackPanel>

        <TextBox x:Name="LogBox" Grid.Row="3" Grid.ColumnSpan="3" IsReadOnly="True" AcceptsReturn="True" 
                 VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" Background="#F9F9F9" Padding="10" FontFamily="Consolas"/>
    </Grid>
</Window>
"@

# Analyse de l'interface
$window = [Windows.Markup.XamlReader]::Parse($XamlString)
$SourceTextBox = $window.FindName("SourceTextBox")
$DestinationTextBox = $window.FindName("DestinationTextBox")
$LogBox = $window.FindName("LogBox")

# Texte Initial
$LogBox.Text = @"
🎶 Music Sorter 🎶
• Trie uniquement les fichiers .mp3 et .flac.
• Organisé par Artiste et Album (compatible Plex).
• Développé par Maël FOUCAUD avec l'aide de ChatGPT o4-mini-high.

🛠️ Comment l'utiliser :
1) Sélectionnez les dossiers source et cible.
2) Cliquez sur 'Lancer le tri' pour déplacer les fichiers dans Cible/Artiste/Album.
3) Suivez la progression ici.

⚙️ Config :
- 'Importer config' charge les chemins depuis config.json.
- 'Exporter config' sauvegarde les chemins actuels.
-----------------------------------------------------------------------
"@

if (-not $dllLoaded) {
    $LogBox.AppendText("`r`n❌ ERREUR : TagLibSharp.dll introuvable dans : $scriptDir`r`n")
}

# 6. Logique des évènements
$window.FindName("BrowseSource").Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") { $SourceTextBox.Text = $dlg.SelectedPath }
})

$window.FindName("BrowseDestination").Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") { $DestinationTextBox.Text = $dlg.SelectedPath }
})

$window.FindName("ImportBtn").Add_Click({
    $cfg = Load-Config
    $SourceTextBox.Text = $cfg.SourceFolder
    $DestinationTextBox.Text = $cfg.DestinationFolder
    $LogBox.AppendText("`r`n✔ Configuration chargée.`r`n")
})

$window.FindName("ExportBtn").Add_Click({
    Save-Config $SourceTextBox.Text $DestinationTextBox.Text
    $LogBox.AppendText("`r`n✔ Configuration sauvegardée.`r`n")
})

$window.FindName("StartBtn").Add_Click({
    $src = $SourceTextBox.Text
    $dest = $DestinationTextBox.Text

    if (!(Test-Path $src) -or !(Test-Path $dest)) {
        [System.Windows.MessageBox]::Show("Veuillez sélectionner des dossiers valides.")
        return
    }

    $LogBox.AppendText("`r`n🚀 Lancement du tri...`r`n")
    
    Get-ChildItem -Path $src -Recurse -File -Include *.mp3, *.flac | ForEach-Object {
        try {
            $file = [TagLib.File]::Create($_.FullName)
            $rawArtist = $file.Tag.FirstAlbumArtist
            if ([string]::IsNullOrWhiteSpace($rawArtist)) { $rawArtist = $file.Tag.FirstPerformer }
            
            $artist = Clean-Name $rawArtist
            $album = Clean-Name $file.Tag.Album
            
            $targetPath = Join-Path $dest (Join-Path $artist $album)
            if (!(Test-Path $targetPath)) { New-Item -ItemType Directory -Path $targetPath -Force | Out-Null }
            
            Move-Item -Path $_.FullName -Destination (Join-Path $targetPath $_.Name) -Force
            $LogBox.AppendText("✔ Déplacé : $($_.Name)`r`n")
        } catch {
            $LogBox.AppendText("❌ Erreur : $($_.Name) - $($_.Exception.Message)`r`n")
        }
        [System.Windows.Forms.Application]::DoEvents()
    }
    $LogBox.AppendText("`r`n🎉 Terminé !`r`n")
})

$window.ShowDialog() | Out-Null