# InstaFlow Pro v2.6 - English UI - Native WPF user interface for Windows PowerShell 5.1
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms
$bootstrap = Join-Path $PSScriptRoot 'Ensure_Tools.ps1'
if (Test-Path -LiteralPath $bootstrap) {
    & $bootstrap
    if ($LASTEXITCODE -ne 0) {
        [System.Windows.MessageBox]::Show('InstaFlow could not prepare its required runtime tools. Check your internet connection and run the app again.','InstaFlow Pro','OK','Error') | Out-Null
        exit 1
    }
}
[xml]$xaml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="InstaFlow Pro | Instagram &amp; YouTube" Width="1230" Height="840"
        MinWidth="1060" MinHeight="730" WindowStartupLocation="CenterScreen"
        Background="#0B0E19" Foreground="#F7F5FF" FontFamily="Segoe UI"
        FlowDirection="LeftToRight">
 <Window.Resources>
  <Style x:Key="SoftBtn" TargetType="Button">
   <Setter Property="Foreground" Value="#FAF8FF"/><Setter Property="FontSize" Value="13"/>
   <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Background" Value="#262C45"/>
   <Setter Property="BorderBrush" Value="#37415C"/><Setter Property="BorderThickness" Value="1"/>
   <Setter Property="Cursor" Value="Hand"/><Setter Property="Padding" Value="16,8"/>
   <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
      <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
       BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="11"
       Padding="{TemplateBinding Padding}"><ContentPresenter VerticalAlignment="Center" HorizontalAlignment="Center"/></Border>
      <ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.80"/></Trigger>
      <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.35"/></Trigger></ControlTemplate.Triggers>
   </ControlTemplate></Setter.Value></Setter>
  </Style>
  <Style x:Key="EditBox" TargetType="TextBox">
   <Setter Property="Background" Value="#12172A"/><Setter Property="Foreground" Value="#FFFFFF"/>
   <Setter Property="BorderBrush" Value="#3B4567"/><Setter Property="BorderThickness" Value="1"/>
   <Setter Property="FontSize" Value="14"/><Setter Property="Padding" Value="13,12"/>
   <Setter Property="CaretBrush" Value="#F5B3E0"/><Setter Property="VerticalContentAlignment" Value="Center"/>
  </Style>
  <Style TargetType="CheckBox"><Setter Property="Foreground" Value="#EDF0FF"/><Setter Property="FontSize" Value="13"/></Style>
  <Style TargetType="ComboBox"><Setter Property="Background" Value="#E7E9F4"/><Setter Property="Foreground" Value="#15192C"/><Setter Property="FontSize" Value="12"/><Setter Property="Padding" Value="4"/></Style>
 </Window.Resources>
 <Grid Margin="21,17,21,15">
  <Grid.RowDefinitions>
   <RowDefinition Height="Auto"/><RowDefinition Height="15"/>
   <RowDefinition Height="Auto"/><RowDefinition Height="13"/>
   <RowDefinition Height="Auto"/><RowDefinition Height="13"/>
   <RowDefinition Height="*"/><RowDefinition Height="12"/>
   <RowDefinition Height="Auto"/>
  </Grid.RowDefinitions>
  <Border Grid.Row="0" CornerRadius="19" Padding="20,15" BorderBrush="#57385F" BorderThickness="1">
   <Border.Background><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#5D2B74" Offset="0"/><GradientStop Color="#2B2759" Offset="0.5"/><GradientStop Color="#15213A" Offset="1"/></LinearGradientBrush></Border.Background>
   <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
    <StackPanel Grid.Column="0"><TextBlock Text="InstaFlow Pro" FontWeight="Bold" FontSize="28" FlowDirection="LeftToRight" HorizontalAlignment="Left"/>
     <TextBlock Text="Gallery and profiles | MP3/M4A audio | True 4K | Multi-connection downloads" Foreground="#DDD3F4" FontSize="13" Margin="0,4,0,0"/>
    </StackPanel>
    <Border Grid.Column="1" Background="#704071" CornerRadius="22" Padding="18,9" VerticalAlignment="Center" Margin="20,0,0,0">
     <TextBlock Text="V 2.6  ✦" FlowDirection="LeftToRight" Foreground="#FFE2F6" FontSize="13" FontWeight="Bold"/>
    </Border>
   </Grid>
  </Border>
  <Border Grid.Row="2" CornerRadius="16" Background="#161B2C" BorderBrush="#303854" BorderThickness="1" Padding="16,13">
   <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="12"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <TextBlock Grid.Row="0" Text="Enter an Instagram post, reel, story, profile, or YouTube link" FontSize="13" FontWeight="SemiBold" Foreground="#D4D5E7"/>
    <Grid Grid.Row="2"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="9"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
     <TextBox x:Name="UrlBox" Grid.Column="0" Style="{StaticResource EditBox}" FlowDirection="LeftToRight" HorizontalContentAlignment="Left" ToolTip="Full URL starting with https://..."/>
     <Button x:Name="PasteButton" Grid.Column="2" Content="Paste Link" Style="{StaticResource SoftBtn}"/>
     <Button x:Name="ScanButton" Grid.Column="4" Content="🔎  Scan Link" Background="#BC3C8C" BorderBrush="#F168B0" Style="{StaticResource SoftBtn}"/>
    </Grid>
   </Grid>
  </Border>
  <Border Grid.Row="4" CornerRadius="15" Background="#161B2C" Padding="15,12" BorderBrush="#303854" BorderThickness="1">
   <Grid>
    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="9"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <Grid Grid.Row="0">
     <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="8"/><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="24"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="8"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
     <TextBlock Grid.Column="0" Text="Save to:" VerticalAlignment="Center" Foreground="#BABFD6"/>
     <TextBox x:Name="FolderBox" Grid.Column="2" IsReadOnly="True" Style="{StaticResource EditBox}" FontSize="12" Padding="8,7" FlowDirection="LeftToRight"/>
     <Button x:Name="PickFolder" Grid.Column="4" Content="📂 Choose Folder" Style="{StaticResource SoftBtn}" Padding="11,7"/>
     <TextBlock Grid.Column="6" Text="Browser account:" VerticalAlignment="Center" Foreground="#BABFD6"/>
     <ComboBox x:Name="BrowserBox" Grid.Column="8" MinWidth="105" SelectedIndex="0" VerticalAlignment="Center" ToolTip="Browser where you are signed in to Instagram or YouTube">
      <ComboBoxItem Content="Firefox" Tag="firefox"/><ComboBoxItem Content="Chrome" Tag="chrome"/><ComboBoxItem Content="Edge" Tag="edge"/>
     </ComboBox>
    </Grid>
    <Grid Grid.Row="2">
     <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="8"/><ColumnDefinition Width="2*"/><ColumnDefinition Width="22"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="8"/><ColumnDefinition Width="1.1*"/><ColumnDefinition Width="22"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="8"/><ColumnDefinition Width="1*"/></Grid.ColumnDefinitions>
     <TextBlock Grid.Column="0" Text="Quality / output:" VerticalAlignment="Center" Foreground="#BABFD6"/>
     <ComboBox x:Name="QualityBox" Grid.Column="2" SelectedIndex="0" VerticalAlignment="Center" ToolTip="Output quality cannot exceed the quality available from the source">
      <ComboBoxItem Content="Best available quality (up to 4K/8K)" Tag="best"/>
      <ComboBoxItem Content="Up to 4K / 2160p" Tag="2160"/>
      <ComboBoxItem Content="Up to 1440p" Tag="1440"/>
      <ComboBoxItem Content="Up to 1080p" Tag="1080"/>
      <ComboBoxItem Content="Up to 720p" Tag="720"/>
      <ComboBoxItem Content="Audio only - MP3" Tag="audio_mp3"/>
      <ComboBoxItem Content="Audio only - M4A" Tag="audio_m4a"/>
     </ComboBox>
     <TextBlock Grid.Column="4" Text="Video container:" VerticalAlignment="Center" Foreground="#BABFD6"/>
     <ComboBox x:Name="ContainerBox" Grid.Column="6" SelectedIndex="0" VerticalAlignment="Center" ToolTip="MKV is more compatible with many 4K and 8K codecs">
      <ComboBoxItem Content="Auto / MKV" Tag="mkv"/><ComboBoxItem Content="MP4" Tag="mp4"/>
     </ComboBox>
     <TextBlock Grid.Column="8" Text="Image:" VerticalAlignment="Center" Foreground="#BABFD6"/>
     <ComboBox x:Name="ImageBox" Grid.Column="10" SelectedIndex="0" VerticalAlignment="Center">
      <ComboBoxItem Content="Original" Tag="original"/><ComboBoxItem Content="JPG" Tag="jpg"/><ComboBoxItem Content="PNG" Tag="png"/>
     </ComboBox>
    </Grid>
   </Grid>
  </Border>
  <Grid Grid.Row="6"><Grid.ColumnDefinitions><ColumnDefinition Width="1.13*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="0.87*"/></Grid.ColumnDefinitions>
   <Border Grid.Column="0" CornerRadius="16" BorderBrush="#333C59" BorderThickness="1" Background="#141929" Padding="14,12">
    <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="10"/><RowDefinition Height="*"/><RowDefinition Height="12"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
     <Grid Grid.Row="0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="8"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
      <TextBlock x:Name="CountText" Text="No link scanned yet" FontSize="15" FontWeight="Bold" VerticalAlignment="Center"/>
      <Button x:Name="SelectAll" Grid.Column="1" Content="Select All" Style="{StaticResource SoftBtn}" Padding="10,5" IsEnabled="False"/>
      <Button x:Name="SelectNone" Grid.Column="3" Content="Select None" Style="{StaticResource SoftBtn}" Padding="10,5" IsEnabled="False"/>
     </Grid>
     <ListView x:Name="MediaList" Grid.Row="2" Background="#101525" BorderThickness="0"
      Foreground="#F7F7FC" SelectionMode="Single" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
      <ListView.ItemContainerStyle><Style TargetType="ListViewItem"><Setter Property="HorizontalContentAlignment" Value="Stretch"/>
       <Setter Property="Padding" Value="2"/><Setter Property="Margin" Value="0,3"/>
       <Setter Property="Background" Value="#1C2436"/><Setter Property="BorderThickness" Value="0"/>
      </Style></ListView.ItemContainerStyle>
      <ListView.ItemTemplate><DataTemplate>
       <Grid Margin="4" MinHeight="78"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="8"/><ColumnDefinition Width="94"/><ColumnDefinition Width="12"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <CheckBox IsChecked="{Binding selected,Mode=TwoWay,UpdateSourceTrigger=PropertyChanged}" Grid.Column="0" VerticalAlignment="Center" Margin="8,0,2,0"/>
        <Border Grid.Column="2" Width="94" Height="74" Background="#272B42" CornerRadius="9" ClipToBounds="True">
         <Image Source="{Binding thumb, IsAsync=True}" Stretch="UniformToFill"/>
        </Border>
        <StackPanel Grid.Column="4" VerticalAlignment="Center" Margin="0,0,6,0">
         <TextBlock Text="{Binding title}" FontSize="12" FontWeight="SemiBold" MaxHeight="37" TextWrapping="Wrap" TextTrimming="CharacterEllipsis"/>
         <TextBlock Text="{Binding kind}" Foreground="#F094C6" Margin="0,8,0,0" FontSize="12"/>
        </StackPanel>
       </Grid>
      </DataTemplate></ListView.ItemTemplate>
     </ListView>
     <TextBlock Grid.Row="4" x:Name="SelectNote" Text="After scanning, select the images or videos you want."
      FontSize="11" Foreground="#919BB8" TextWrapping="Wrap"/>
    </Grid>
   </Border>
   <Border Grid.Column="2" CornerRadius="16" BorderBrush="#333C59" BorderThickness="1" Background="#141929" Padding="14,12">
    <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="12"/><RowDefinition Height="*"/><RowDefinition Height="10"/><RowDefinition Height="Auto"/><RowDefinition Height="8"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
     <TextBlock Text="Selected Item Preview" Grid.Row="0" FontWeight="Bold" FontSize="15"/>
     <Border Grid.Row="2" Background="#0C1120" BorderBrush="#313D5D" BorderThickness="1" CornerRadius="12" ClipToBounds="True">
      <Grid><Image x:Name="BigPreview" Stretch="Uniform"/>
       <MediaElement x:Name="VideoPlayer" LoadedBehavior="Manual" UnloadedBehavior="Stop" Stretch="Uniform" Visibility="Collapsed"/>
       <TextBlock x:Name="PreviewHint" Text="Click an image or video to preview it" Foreground="#858FAE" TextAlignment="Center" VerticalAlignment="Center" TextWrapping="Wrap" Margin="20"/>
      </Grid>
     </Border>
     <TextBlock x:Name="PreviewTitle" Grid.Row="4" FontSize="12" TextWrapping="Wrap" Foreground="#C5C9DE" MaxHeight="40"/>
     <Grid Grid.Row="6"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="9"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <Button x:Name="PlayButton" Grid.Column="0" Content="▶  Play / Preview" Style="{StaticResource SoftBtn}" IsEnabled="False"/>
      <Button x:Name="BrowserButton" Grid.Column="2" Content="Open Link" Style="{StaticResource SoftBtn}" IsEnabled="False"/>
     </Grid>
    </Grid>
   </Border>
  </Grid>
  <Border Grid.Row="8" Background="#161B2C" BorderBrush="#353D59" BorderThickness="1" CornerRadius="16" Padding="14,11">
   <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="8"/><RowDefinition Height="Auto"/><RowDefinition Height="10"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <Grid Grid.Row="0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
     <TextBlock x:Name="StatusText" Text="Ready for a link" FontWeight="SemiBold" FontSize="13" TextTrimming="CharacterEllipsis"/>
     <TextBlock x:Name="PercentText" Grid.Column="1" Text="0%" FlowDirection="LeftToRight" Foreground="#F292C2" FontWeight="Bold" FontSize="13"/>
    </Grid>
    <ProgressBar x:Name="Progress" Grid.Row="2" Height="8" Foreground="#E84EAA" Background="#252A41" Minimum="0" Maximum="100"/>
    <Grid Grid.Row="4"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="10"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="10"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="10"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
     <TextBlock x:Name="DetailsText" Grid.Column="0" Text="Only download files that you are authorized to access." VerticalAlignment="Center" Foreground="#949DB9" FontSize="11" TextWrapping="Wrap"/>
     <Button x:Name="OpenFolder" Grid.Column="2" Content="📂  Open Folder" Style="{StaticResource SoftBtn}"/>
     <Button x:Name="CancelButton" Grid.Column="4" Content="Cancel" Style="{StaticResource SoftBtn}" IsEnabled="False"/>
     <Button x:Name="DownloadButton" Grid.Column="6" Content="⬇  Download Selected" Background="#C23986" BorderBrush="#EC65AA" Style="{StaticResource SoftBtn}" IsEnabled="False"/>
     <Button x:Name="IDMButton" Grid.Column="8" Content="⚡ Fast 4K Download" Background="#164D76" BorderBrush="#3C83BC" Style="{StaticResource SoftBtn}" IsEnabled="False" ToolTip="Attempts a multi-connection download with aria2c and automatically falls back to the native downloader if needed. Quality and audio are preserved."/>
    </Grid>
   </Grid>
  </Border>
 </Grid>
</Window>
'@
try {
 $reader=New-Object System.Xml.XmlNodeReader($xaml)
 $window=[System.Windows.Markup.XamlReader]::Load($reader)
} catch {
 [System.Windows.MessageBox]::Show(('The user interface could not be loaded: '+$_.Exception.Message),'InstaFlow Pro')|Out-Null
 exit 1
}
foreach($n in @('UrlBox','PasteButton','ScanButton','FolderBox','PickFolder','QualityBox','ContainerBox','ImageBox','BrowserBox','CountText','SelectAll','SelectNone','MediaList','SelectNote','BigPreview','VideoPlayer','PreviewHint','PreviewTitle','PlayButton','BrowserButton','StatusText','PercentText','Progress','DetailsText','OpenFolder','CancelButton','DownloadButton','IDMButton')) {
 Set-Variable -Scope Script -Name $n -Value $window.FindName($n)
}
$script:folder = Join-Path $env:USERPROFILE 'Downloads'
$FolderBox.Text=$script:folder
$script:task=$null
$script:taskMode=''
$script:work=''
$script:previewItem=$null
$script:cancelled=$false
$script:data=New-Object System.Data.DataTable
[void]$script:data.Columns.Add('selected',[bool])
[void]$script:data.Columns.Add('title',[string])
[void]$script:data.Columns.Add('kind',[string])
[void]$script:data.Columns.Add('thumb',[string])
[void]$script:data.Columns.Add('url',[string])
[void]$script:data.Columns.Add('downloadUrl',[string])
[void]$script:data.Columns.Add('engine',[string])
[void]$script:data.Columns.Add('selectIndex',[int])
$MediaList.ItemsSource=$script:data.DefaultView
function Status([string]$heading,[string]$detail='') { $StatusText.Text=$heading; if($detail){$DetailsText.Text=$detail} }
function Percent([int]$p) {
 $p=[Math]::Min(100,[Math]::Max(0,$p))
 if($Progress.IsIndeterminate){return}
 $Progress.Value=$p; $PercentText.Text="$p%"
}
# Recompute enabled buttons after every scan and every checkbox change.
# v2.1 bug: Busy($false) ran before scan results were inserted, so these buttons
# remained disabled even when the table had selected media.
$script:isBusy=$false
function UpdateSelectionButtons {
 $n=$script:data.Rows.Count
 $count=0
 foreach($mediaRow in $script:data.Rows) {
  if($mediaRow.RowState -ne [System.Data.DataRowState]::Deleted -and $mediaRow['selected'] -eq $true){ $count++ }
 }
 $ready=((-not $script:isBusy) -and ($n -gt 0))
 $SelectAll.IsEnabled=$ready
 $SelectNone.IsEnabled=$ready
 $DownloadButton.IsEnabled=($ready -and ($count -gt 0))
 $IDMButton.IsEnabled=($ready -and ($count -gt 0))
 if($n -gt 0) {
  $SelectNote.Text=('Selected: '+$count+' of '+$n+' items. Check the items you want.')
 } elseif(-not $script:isBusy) {
  $SelectNote.Text='After scanning, select the images or videos you want.'
 }
}
function Busy([bool]$value) {
 $script:isBusy=$value
 foreach($control in @($UrlBox,$PasteButton,$ScanButton,$PickFolder,$QualityBox,$ContainerBox,$ImageBox,$BrowserBox)) {
  $control.IsEnabled= -not $value
 }
 UpdateSelectionButtons
 $CancelButton.IsEnabled=$value
}
$script:data.Add_ColumnChanged({
 param($sender,$args)
 if($args.Column.ColumnName -eq 'selected') { UpdateSelectionButtons }
})
function ValidLink([string]$raw) {
 $u=$null
 if (-not [Uri]::TryCreate($raw,[UriKind]::Absolute,[ref]$u)) {return $false}
 if ($u.Scheme -notin @('http','https')) {return $false}
 $h=$u.Host.ToLowerInvariant()
 return ($h -eq 'instagram.com' -or $h -eq 'www.instagram.com' -or $h -eq 'youtube.com' -or $h -eq 'www.youtube.com' -or $h -eq 'm.youtube.com' -or $h -eq 'music.youtube.com' -or $h -eq 'youtu.be')
}
function Launch([string]$mode,[hashtable]$settings) {
 try {
  $script:work=Join-Path $env:TEMP ('InstaFlowPro-'+[Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $script:work -Force | Out-Null
  $settings.mode=$mode;$settings.work=$script:work
  $jobFile=Join-Path $script:work 'job.json'
  $settings | ConvertTo-Json -Depth 18 | Set-Content -LiteralPath $jobFile -Encoding UTF8
  $worker=Join-Path $PSScriptRoot 'Worker.ps1'
  if(-not (Test-Path -LiteralPath $worker)){throw 'Worker.ps1 was not found.'}
  $script:cancelled=$false;$script:taskMode=$mode;$script:taskStarted=Get-Date
  $script:task=Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$worker+'"'),'-JobFile',('"'+$jobFile+'"')) -PassThru -WindowStyle Hidden
  Busy $true
  Percent 0
  $Progress.IsIndeterminate=($mode -eq 'scan')
  if($mode -eq 'scan'){Status 'Scanning and building the preview...' 'Please wait until the scan finishes.'}
  elseif($mode -eq 'download' -and $settings.accel){Status 'Downloading with acceleration and original quality...' 'If aria2c is unavailable or fails, the native downloader is tried automatically.'}
  else{Status 'Downloading selected files...' 'Videos are saved with their original audio when possible.'}
  $timer.Start()
 } catch {Busy $false; Status 'Execution error' $_.Exception.Message}
}
function Get-FastPreviewImage([string]$url,[object]$row) {
 if($url -notmatch '^https?://'){return $null}
 $curl=Get-Command curl.exe -ErrorAction SilentlyContinue
 if(-not $curl){return $null}
 $tmp=Join-Path $env:TEMP ('InstaFlowPreview-'+[Guid]::NewGuid().ToString('N')+'.img')
 try {
  $curlArgs=@('-4','--ssl-no-revoke','-L','-sS','--connect-timeout','3','--max-time','6','-o',$tmp,'--',$url)
  & $curl.Source @curlArgs 2>$null
  if($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmp)){return $null}
  if((Get-Item -LiteralPath $tmp).Length -lt 64){return $null}
  $pic=New-Object System.Windows.Media.Imaging.BitmapImage
  $pic.BeginInit()
  $pic.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
  $pic.UriSource=[Uri]::new($tmp)
  $pic.EndInit()
  $pic.Freeze()
  return $pic
 } catch {
  return $null
 } finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
 }
}
function Preview([object]$row) {
 try{$VideoPlayer.Stop()}catch{}
 $VideoPlayer.Visibility='Collapsed'
 $BigPreview.Source=$null;$BigPreview.Visibility='Visible'
 $script:previewItem=$null
 if($null -eq $row){$PreviewHint.Text='Click an image or video to preview it';$PreviewHint.Visibility='Visible';$PlayButton.IsEnabled=$false;$BrowserButton.IsEnabled=$false;return}
 $script:previewItem=$row
 $PreviewTitle.Text=[string]$row['title']
 $PreviewHint.Text='The preview image may be unavailable because of Instagram restrictions.'
 $PreviewHint.Visibility='Collapsed'
 $PlayButton.IsEnabled=$true;$BrowserButton.IsEnabled=$true
 $thumb=[string]$row['thumb']
 if($thumb -match '^https?://') {
  $pic=Get-FastPreviewImage $thumb $row
  if($pic){$BigPreview.Source=$pic}
  else {$PreviewHint.Visibility='Visible'}
 } elseif($thumb) {
  try {
   $pic=New-Object System.Windows.Media.Imaging.BitmapImage
   $pic.BeginInit();$pic.CacheOption='OnLoad';$pic.UriSource=[Uri]::new($thumb);$pic.EndInit();$pic.Freeze()
   $BigPreview.Source=$pic
  } catch {$PreviewHint.Visibility='Visible'}
 } else { $PreviewHint.Visibility='Visible' }
}
$MediaList.Add_SelectionChanged({
 if($MediaList.SelectedItem){Preview $MediaList.SelectedItem}
})
$PasteButton.Add_Click({try{$UrlBox.Text=[Windows.Clipboard]::GetText().Trim()}catch{Status 'Clipboard paste failed' 'Enter the link manually.'}})
$PickFolder.Add_Click({
 $dlg=New-Object System.Windows.Forms.FolderBrowserDialog
 $dlg.Description='Choose the folder where downloaded files will be saved'
 if(Test-Path -LiteralPath $script:folder){$dlg.SelectedPath=$script:folder}
 if($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){$script:folder=$dlg.SelectedPath;$FolderBox.Text=$script:folder}
 $dlg.Dispose()
})
$OpenFolder.Add_Click({
 if(-not(Test-Path -LiteralPath $script:folder)){New-Item -ItemType Directory -Force -Path $script:folder|Out-Null}
 Start-Process -FilePath explorer.exe -ArgumentList ('"'+$script:folder+'"')
})
$SelectAll.Add_Click({foreach($r in $script:data.Rows){$r['selected']=$true}})
$SelectNone.Add_Click({foreach($r in $script:data.Rows){$r['selected']=$false}})
$PlayButton.Add_Click({
 if($null -eq $script:previewItem){return}
 $remote=[string]$script:previewItem['url']
 $kind=[string]$script:previewItem['kind']
 if($kind -eq 'Image') {
  if($BigPreview.Source){$PreviewHint.Visibility='Collapsed'}
  return
 }
 if($remote -match '\.(mp4|m4v|mov)(?:\?|$)' -and $remote -match '^https?://') {
  try {
   $VideoPlayer.Source=[Uri]$remote
   $BigPreview.Visibility='Collapsed'
   $VideoPlayer.Visibility='Visible'
   $VideoPlayer.Play()
   Status 'Trying to play the preview...' 'If the video does not play, use Open Link.'
  }catch{Start-Process $remote}
 } else {
  $link=[string]$script:previewItem['downloadUrl']
  if($link -match '^https?://'){Start-Process $link}
 }
})
$BrowserButton.Add_Click({
 if($null -eq $script:previewItem){return}
 $u=[string]$script:previewItem['url']
 if($u -notmatch '^https?://'){$u=[string]$script:previewItem['downloadUrl']}
 if($u -match '^https?://'){Start-Process $u}
})
$ScanButton.Add_Click({
 $u=$UrlBox.Text.Trim()
 if(-not(ValidLink $u)){Status 'Invalid link' 'Enter an Instagram or YouTube URL starting with https://.';return}
 $script:data.Rows.Clear()
 UpdateSelectionButtons
 Preview $null
 $CountText.Text='Loading...'
 $SelectNote.Text='Fetching the media list...'
 Launch 'scan' @{url=$u;browser=[string]$BrowserBox.SelectedItem.Tag}
})
$UrlBox.Add_KeyDown({if($_.Key -eq 'Return' -and $ScanButton.IsEnabled){$ScanButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))}})
$DownloadButton.Add_Click({
 $checked=@()
 foreach($r in $script:data.Rows) {
  if($r['selected']) { $checked+=@{ title=[string]$r['title'];kind=[string]$r['kind'];url=[string]$r['url'];downloadUrl=[string]$r['downloadUrl'];engine=[string]$r['engine'];selectIndex=[int]$r['selectIndex'] } }
 }
 if($checked.Count -eq 0){Status 'Nothing selected' 'Select at least one item.';return}
 $quality=[string]$QualityBox.SelectedItem.Tag
 if($quality -like 'audio_*' -and @($checked | Where-Object {$_.kind -eq 'Image'}).Count -gt 0) {
  $ans=[System.Windows.MessageBox]::Show('Images do not contain audio and will be skipped in audio-only mode. Continue?','InstaFlow Pro',[System.Windows.MessageBoxButton]::YesNo)
  if($ans -ne [System.Windows.MessageBoxResult]::Yes){return}
 }
 Launch 'download' @{url=$UrlBox.Text.Trim();output=$script:folder;quality=$quality;container=[string]$ContainerBox.SelectedItem.Tag;imageFormat=[string]$ImageBox.SelectedItem.Tag;browser=[string]$BrowserBox.SelectedItem.Tag;items=$checked}
})
# Accelerated option uses yt-dlp for format selection and aria2c for downloading.
# Never hands expiring Googlevideo CDN URLs to IDM.
$IDMButton.Add_Click({
 $checked=@()
 foreach($r in $script:data.Rows) {
  if($r['selected']) {
   $checked+=@{ title=[string]$r['title'];kind=[string]$r['kind'];url=[string]$r['url'];downloadUrl=[string]$r['downloadUrl'];engine=[string]$r['engine'];selectIndex=[int]$r['selectIndex'] }
  }
 }
 if($checked.Count -eq 0){Status 'Nothing selected' 'Select at least one item.';return}
 $quality=[string]$QualityBox.SelectedItem.Tag
 if($quality -like 'audio_*' -and @($checked | Where-Object {$_.kind -eq 'Image'}).Count -gt 0) {
  $ans=[System.Windows.MessageBox]::Show('Images will be skipped in audio-only mode. Continue?','InstaFlow Pro',[System.Windows.MessageBoxButton]::YesNo)
  if($ans -ne [System.Windows.MessageBoxResult]::Yes){return}
 }
 Launch 'download' @{url=$UrlBox.Text.Trim();output=$script:folder;quality=$quality;container=[string]$ContainerBox.SelectedItem.Tag;imageFormat=[string]$ImageBox.SelectedItem.Tag;browser=[string]$BrowserBox.SelectedItem.Tag;items=$checked;accel=$true}
})
$CancelButton.Add_Click({
 $script:cancelled=$true
 if($script:task -and -not $script:task.HasExited){
  try{& taskkill.exe /T /F /PID $script:task.Id 1>$null 2>$null}catch{try{$script:task.Kill()}catch{}}
 }
 Status 'Operation cancelled' 'You can scan the link again.'
})
$timer=New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval=[TimeSpan]::FromMilliseconds(600)
$timer.Add_Tick({
 if($null -eq $script:task){return}
 if($script:taskMode -eq 'scan') {
  $elapsed=[int]((Get-Date)-$script:taskStarted).TotalSeconds
  $PercentText.Text=('Scan time: '+$elapsed+' seconds')
 }
 $stat=Join-Path $script:work 'status.json'
 # Read yt-dlp's reported transfer percentage when available.
 if($script:taskMode -eq 'download') {
  $transcript=Join-Path $script:work 'worker.log'
  if(Test-Path -LiteralPath $transcript) {
   try {
    $lines=@(Get-Content -LiteralPath $transcript -Tail 14 -ErrorAction SilentlyContinue)
    for($i=$lines.Count-1;$i -ge 0;$i--) {
     if([string]$lines[$i] -match '\[download\]\s+([0-9]+(?:\.[0-9]+)?)%') {
      $DetailsText.Text='Current file progress: '+$Matches[1]+'%'
      break
     }
    }
   } catch {}
  }
 }
 if(Test-Path -LiteralPath $stat){try{$s=Get-Content -LiteralPath $stat -Raw -Encoding UTF8|ConvertFrom-Json;Status ([string]$s.message);Percent ([int]$s.percent)}catch{}}
 if(-not $script:task.HasExited){return}
 $timer.Stop()
 $Progress.IsIndeterminate=$false
 $code=$script:task.ExitCode
 $script:task.Dispose();$script:task=$null
 Busy $false
 if($script:cancelled){$script:cancelled=$false;Percent 0;return}
 $file=Join-Path $script:work 'result.json'
 if(-not(Test-Path -LiteralPath $file)){Status 'Application error' 'The result file was not created. Check the application folder.';Percent 0;return}
 try{$res=Get-Content -LiteralPath $file -Raw -Encoding UTF8 |ConvertFrom-Json}catch{Status 'Error reading the result' $_.Exception.Message;return}
 if($script:taskMode -eq 'scan' -and $res.ok){
  $script:data.Rows.Clear()
  foreach($item in @($res.items)){
   $row=$script:data.NewRow()
   $row['selected']=$true;$row['title']=[string]$item.title;$row['kind']=[string]$item.kind
   $row['thumb']=[string]$item.thumb;$row['url']=[string]$item.url
   $row['downloadUrl']=[string]$item.downloadUrl;$row['engine']=[string]$item.engine;$row['selectIndex']=[int]$item.selectIndex
   $script:data.Rows.Add($row)
  }
  $CountText.Text=('Media found: '+$script:data.Rows.Count)
  # Refresh after population, not before; this enables Download for checked items.
  UpdateSelectionButtons
  if($script:data.Rows.Count -gt 0){$MediaList.SelectedIndex=0}
  Status 'Media list is ready' ([string]$res.message)
  Percent 100
 } elseif ($script:taskMode -eq 'download' -and ($res.ok -or $res.count -gt 0)) {
  Status 'Download completed' ([string]$res.message)
  Percent 100
 } else {
  Status 'Operation failed' ([string]$res.message)
  Percent 0
 }
})
$window.Add_Closing({
 try{$timer.Stop()}catch{}
 try{$VideoPlayer.Stop()}catch{}
 if($script:task -and -not $script:task.HasExited){try{& taskkill.exe /T /F /PID $script:task.Id 1>$null 2>$null}catch{try{$script:task.Kill()}catch{}}}
})
$icon=Join-Path $PSScriptRoot 'InstaFlow.ico'
if(Test-Path -LiteralPath $icon){try{$window.Icon=[System.Windows.Media.Imaging.BitmapFrame]::Create([Uri]::new($icon))}catch{}}
[void]$window.ShowDialog()