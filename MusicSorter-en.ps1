# Music Sorter - International Version (Stable)
# Developed by Maël FOUCAUD with the help of ChatGPT o4-mini-high

# 1. Load Dependencies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms

# Handle Directory properly
if ($null -ne $PSScriptRoot -and $PSScriptRoot -ne "") {
    $scriptDir = $PSScriptRoot
} else {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrEmpty($scriptDir)) { $scriptDir = Get-Location }
}

# 2. DLL Loading Logic
$dllName = "TagLibSharp.dll"
$dllPath = Join-Path $scriptDir $dllName
$dllLoaded = $false

if (Test-Path $dllPath) {
    try {
        Add-Type -Path $dllPath
        $dllLoaded = $true
    } catch { 
        [System.Windows.MessageBox]::Show("Error loading TagLibSharp.dll: $($_.Exception.Message)")
    }
}

# 3. Configuration Logic
$configPath = Join-Path $scriptDir "config.json"
function Load-Config {
    if (Test-Path $configPath) { return Get-Content $configPath -Raw | ConvertFrom-Json }
    return @{ SourceFolder = ""; DestinationFolder = "" }
}
function Save-Config($src, $dest) {
    @{ SourceFolder = $src; DestinationFolder = $dest } | ConvertTo-Json | Set-Content $configPath
}

# 4. Utility Functions
function Clean-Name($name) {
    if ([string]::IsNullOrWhiteSpace($name)) { return "Unknown" }
    $invalidChars = [IO.Path]::GetInvalidFileNameChars()
    $s = [string]$name
    foreach ($char in $invalidChars) { $s = $s.Replace($char, "_") }
    return $s.Trim()
}

# 5. UI Definition (XAML) - FIXED
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

        <TextBlock Grid.Row="0" VerticalAlignment="Center">Source folder:</TextBlock>
        <TextBox x:Name="SourceTextBox" Grid.Row="0" Grid.Column="1" Margin="10,5" Height="25" VerticalContentAlignment="Center"/>
        <Button x:Name="BrowseSource" Content="..." Grid.Row="0" Grid.Column="2" Width="40" Height="25"/>

        <TextBlock Grid.Row="1" VerticalAlignment="Center">Target folder:</TextBlock>
        <TextBox x:Name="DestinationTextBox" Grid.Row="1" Grid.Column="1" Margin="10,5" Height="25" VerticalContentAlignment="Center"/>
        <Button x:Name="BrowseDestination" Content="..." Grid.Row="1" Grid.Column="2" Width="40" Height="25"/>

        <StackPanel Grid.Row="2" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,15">
            <Button x:Name="ImportBtn" Content="Import config" Width="120" Height="30" Margin="5,0"/>
            <Button x:Name="ExportBtn" Content="Export config" Width="120" Height="30" Margin="5,0"/>
            <Button x:Name="StartBtn" Content="Start sorting" Width="120" Height="30" Margin="5,0"/>
        </StackPanel>

        <TextBox x:Name="LogBox" Grid.Row="3" Grid.ColumnSpan="3" IsReadOnly="True" AcceptsReturn="True" 
                 VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" Background="#F9F9F9" Padding="10" FontFamily="Consolas"/>
    </Grid>
</Window>
"@

# Interface Parsing
$window = [Windows.Markup.XamlReader]::Parse($XamlString)
$SourceTextBox = $window.FindName("SourceTextBox")
$DestinationTextBox = $window.FindName("DestinationTextBox")
$LogBox = $window.FindName("LogBox")

# Initial Text
$LogBox.Text = @"
🎶 Music Sorter 🎶
• Sorts .mp3 and .flac files only.
• Organized by Artist and Album (Plex compatible).
• Developed by Maël FOUCAUD with the help of ChatGPT o4-mini-high.

🛠️ How to use it:
1) Select source and target folders.
2) Click 'Start sorting' to move files into Target/Artist/Album.
3) Follow the progress here.

⚙️ Config:
- 'Import config' loads paths from config.json.
- 'Export config' saves current paths.
-----------------------------------------------------------------------
"@

if (-not $dllLoaded) {
    $LogBox.AppendText("`r`n❌ ERROR: TagLibSharp.dll not found in: $scriptDir`r`n")
}

# 6. Events Logic
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
    $LogBox.AppendText("`r`n✔ Configuration loaded.`r`n")
})

$window.FindName("ExportBtn").Add_Click({
    Save-Config $SourceTextBox.Text $DestinationTextBox.Text
    $LogBox.AppendText("`r`n✔ Configuration saved.`r`n")
})

$window.FindName("StartBtn").Add_Click({
    $src = $SourceTextBox.Text
    $dest = $DestinationTextBox.Text

    if (!(Test-Path $src) -or !(Test-Path $dest)) {
        [System.Windows.MessageBox]::Show("Please select valid folders.")
        return
    }

    $LogBox.AppendText("`r`n🚀 Starting sort...`r`n")
    
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
            $LogBox.AppendText("✔ Moved: $($_.Name)`r`n")
        } catch {
            $LogBox.AppendText("❌ Error: $($_.Name) - $($_.Exception.Message)`r`n")
        }
        [System.Windows.Forms.Application]::DoEvents()
    }
    $LogBox.AppendText("`r`n🎉 Done!`r`n")
})

$window.ShowDialog() | Out-Null