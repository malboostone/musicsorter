# Charger la DLL TagLib
Add-Type -Path "C:\Windows\TagLibSharp.2.3.0\lib\net462\TagLibSharp.dll"

# Charger les assemblies WPF
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml

# Détermination du dossier du script
$scriptFile = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($scriptFile)) { $scriptDir = (Get-Location).Path } else { $scriptDir = Split-Path -Parent $scriptFile }

# Chemin de configuration
$configPath = Join-Path $scriptDir "config.json"
if (-not (Test-Path $configPath)) {
    @{ SourceFolder = ""; DestinationFolder = "" } |
        ConvertTo-Json | Set-Content $configPath -Encoding UTF8
}

# Fonctions utilitaires
function Clean-Name($name) {
    $s = [string]$name
    foreach ($char in [IO.Path]::GetInvalidFileNameChars()) { $s = $s -replace [Regex]::Escape($char), "_" }
    return $s.Trim()
}
function Load-Config() { ConvertFrom-Json (Get-Content $configPath -Raw) }
function Save-Config($cfg) { $cfg | ConvertTo-Json | Set-Content $configPath -Encoding UTF8 }

function Sort-Music($sourceFolder, $destinationRoot, $logBox) {
    $extensions = @('.mp3', '.flac')
    Get-ChildItem -Path $sourceFolder -Recurse -File |
      Where-Object { $extensions -contains $_.Extension.ToLower() } |
      ForEach-Object {
        try {
            $tag = [TagLib.File]::Create($_.FullName).Tag
            $artist = $tag.FirstAlbumArtist; if (-not $artist) { $artist = $tag.FirstPerformer }; if (-not $artist) { $artist = 'Inconnu' }
            $album  = $tag.Album;            if (-not $album)  { $album  = 'Sans Album' }
            $aDir = Clean-Name $artist
            $alDir = Clean-Name $album
            $target = Join-Path $destinationRoot $aDir
            $albumPath = Join-Path $target $alDir
            if (-not (Test-Path $albumPath)) { New-Item -ItemType Directory -Path $albumPath -Force | Out-Null }
            $dest = Join-Path $albumPath $_.Name
            Move-Item -Path $_.FullName -Destination $dest -Force
            $logBox.AppendText("✔ Déplacé : $($_.Name) → $albumPath`r`n")
        } catch {
            $logBox.AppendText("⚠ Erreur sur $($_.Name) : $_`r`n")
        }
        # Laisser l'UI réagir
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{},[System.Windows.Threading.DispatcherPriority]::Background)
      }
    $logBox.AppendText("`r`n🎉 Tri terminé !`r`n")
}

# XAML de l'interface WPF
$XamlString = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Music Sorter"
        Height="550" Width="650"
        FontFamily="Segoe UI Emoji"
        FontSize="12">
  <Grid Margin="10">
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

    <TextBlock Grid.Row="0" Grid.Column="0" VerticalAlignment="Center">Dossier source:</TextBlock>
    <TextBox x:Name="SourceTextBox" Grid.Row="0" Grid.Column="1" Margin="5,2"/>
    <Button x:Name="BrowseSource" Content="Parcourir..." Grid.Row="0" Grid.Column="2" Margin="5,2" Width="90"/>

    <TextBlock Grid.Row="1" Grid.Column="0" VerticalAlignment="Center">Dossier cible:</TextBlock>
    <TextBox x:Name="DestinationTextBox" Grid.Row="1" Grid.Column="1" Margin="5,2"/>
    <Button x:Name="BrowseDestination" Content="Parcourir..." Grid.Row="1" Grid.Column="2" Margin="5,2" Width="90"/>

    <StackPanel Grid.Row="2" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10">
      <Button x:Name="ImportConfig" Content="Importer config" Width="110" Margin="0,0,5,0"/>
      <Button x:Name="ExportConfig" Content="Exporter config" Width="110" Margin="0,0,5,0"/>
      <Button x:Name="StartSort" Content="Lancer le tri" Width="110"/>
    </StackPanel>

    <TextBox x:Name="LogBox"
             Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="3" Margin="0,5"
             IsReadOnly="True"
             AcceptsReturn="True"
             VerticalScrollBarVisibility="Auto"
             TextWrapping="Wrap"
             FontFamily="Segoe UI Emoji"
             FontSize="12"/>
  </Grid>
</Window>
'@

# Charger le XAML et initialiser la fenêtre
# Utiliser Parse pour charger directement depuis la chaîne
$window = [Windows.Markup.XamlReader]::Parse($XamlString)

# Définir manuellement l'icône de la fenêtre
$iconFile = Join-Path $scriptDir 'logo.ico'
if (Test-Path $iconFile) {
    try {
        $uri = New-Object System.Uri($iconFile, [System.UriKind]::Absolute)
        $bitmap = [System.Windows.Media.Imaging.BitmapFrame]::Create($uri)
        $window.Icon = $bitmap
    } catch {
        Write-Host "⚠ Impossible de charger l'icône depuis $iconFile : $_"
    }
} else {
    Write-Host "⚠ logo.ico introuvable dans $scriptDir"
}
[xml]$XamlXml = $XamlString
$reader = New-Object System.Xml.XmlNodeReader($XamlXml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Récupération des contrôles reste inchangée...

# Affichage de la fenêtre
$window.ShowDialog() | Out-Null
$window.ShowDialog() | Out-Null