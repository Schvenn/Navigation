# ----------------------------------------------------------------------------------
#									load configuration
# ----------------------------------------------------------------------------------

# Load the configuration settings from the PSD1 file.
function loadconfiguration {$script:powershell = Split-Path $profile; $script:baseModulePath = Join-Path $powershell "Modules\Navigation"; $script:configPath = Join-Path $baseModulePath "Navigation.psd1"

if (!(Test-Path $configPath)) {throw "Config file not found at $configPath"}

# Pull config values into variables
$script:config = Import-PowerShellDataFile -Path $configPath
$script:GotoLogPath = Join-Path $baseModulePath $config.privatedata.GotoLogPath
$script:GotoCachePath = Join-Path $baseModulePath $config.privatedata.GotoCachePath
$script:GotoSearchRoots = $config.privatedata.GotoSearchRoots
$script:GotoSearchExclusions = $config.privatedata.GotoSearchExclusions
$script:GotoCacheMaxAge = $config.privatedata.GotoCacheMaxAge
$script:GotoCacheMaxMatches = $config.privatedata.GotoCacheMaxMatches
$script:RecursionDepth = $config.privatedata.RecursionDepth
$script:GotoCacheSize = $config.privatedata.GotoCacheSize
$script:BookmarkFilePath = Join-Path $baseModulePath $config.privatedata.BookmarkFilePath
$script:LocationsPath = Join-Path $baseModulePath $config.privatedata.LocationsPath}
loadconfiguration

# ----------------------------------------------------------------------------------
#									navigation help function
# ----------------------------------------------------------------------------------

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

function navigation {# Inline help.
# Select content.
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)"); $selection = $null; $lines = @(); $wrappedLines = @(); $position = 0; $pageSize = 30; $inputBuffer = ""

function scripthelp ($section) {$pattern = "(?ims)^## ($([regex]::Escape($section)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}

# Display Table of Contents.
while ($true) {cls; Write-Host -f cyan "$(Get-ChildItem (Split-Path $PSCommandPath) | Where-Object { $_.FullName -ieq $PSCommandPath } | Select-Object -ExpandProperty BaseName) Help Sections:`n"

if ($sections.Count -gt 7) {$half = [Math]::Ceiling($sections.Count / 2)
for ($i = 0; $i -lt $half; $i++) {$leftIndex = $i; $rightIndex = $i + $half; $leftNumber  = "{0,2}." -f ($leftIndex + 1); $leftLabel   = " $($sections[$leftIndex].Groups[1].Value)"; $leftOutput  = [string]::Empty

if ($rightIndex -lt $sections.Count) {$rightNumber = "{0,2}." -f ($rightIndex + 1); $rightLabel  = " $($sections[$rightIndex].Groups[1].Value)"; Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel -n; $pad = 40 - ($leftNumber.Length + $leftLabel.Length)
if ($pad -gt 0) {Write-Host (" " * $pad) -n}; Write-Host -f cyan $rightNumber -n; Write-Host -f white $rightLabel}
else {Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel}}}

else {for ($i = 0; $i -lt $sections.Count; $i++) {Write-Host -f cyan ("{0,2}. " -f ($i + 1)) -n; Write-Host -f white "$($sections[$i].Groups[1].Value)"}}

# Display Header.
line yellow 100
if ($lines.Count -gt 0) {Write-Host  -f yellow $lines[0]}
else {Write-Host "Choose a section to view." -f darkgray}
line yellow 100

# Display content.
$end = [Math]::Min($position + $pageSize, $wrappedLines.Count)
for ($i = $position; $i -lt $end; $i++) {Write-Host -f white $wrappedLines[$i]}

# Pad display section with blank lines.
for ($j = 0; $j -lt ($pageSize - ($end - $position)); $j++) {Write-Host ""}

# Display menu options.
line yellow 100; Write-Host -f white "[↑/↓]  [PgUp/PgDn]  [Home/End]  |  [#] Select section  |  [Q] Quit  " -n; if ($inputBuffer.length -gt 0) {Write-Host -f cyan "section: $inputBuffer" -n}; $key = [System.Console]::ReadKey($true)

# Define interaction.
switch ($key.Key) {'UpArrow' {if ($position -gt 0) { $position-- }; $inputBuffer = ""}
'DownArrow' {if ($position -lt ($wrappedLines.Count - $pageSize)) { $position++ }; $inputBuffer = ""}
'PageUp' {$position -= 30; if ($position -lt 0) {$position = 0}; $inputBuffer = ""}
'PageDown' {$position += 30; $maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); if ($position -gt $maxStart) {$position = $maxStart}; $inputBuffer = ""}
'Home' {$position = 0; $inputBuffer = ""}
'End' {$maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); $position = $maxStart; $inputBuffer = ""}

'Enter' {if ($inputBuffer -eq "") {"`n"; return}
elseif ($inputBuffer -match '^\d+$') {$index = [int]$inputBuffer
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index; $pattern = "(?ims)^## ($([regex]::Escape($sections[$selection-1].Groups[1].Value)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $block = $match.Groups[1].Value.TrimEnd(); $lines = $block -split "`r?`n", 2
if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}}
$inputBuffer = ""}

default {$char = $key.KeyChar
if ($char -match '^[Qq]$') {"`n"; return}
elseif ($char -match '^\d$') {$inputBuffer += $char}
else {$inputBuffer = ""}}}}}

# ----------------------------------------------------------------------------------
#									locations function
# ----------------------------------------------------------------------------------

$LocationsPath = $script:LocationsPath

function getlocations {# (Internal) Display all active locations paths.
""; Get-Command -Type Function | Where-Object {($_.Definition -match '^Set-Location') -and ($_.Name -notmatch '^(.:|cd..?)$')} | ForEach-Object {Write-Host -f cyan $_.Name}; ""}

function locations ($path) {# Creates functions for easy navigation to specific paths.

if ($path) {Write-Host -f yellow "`n-------------------------------------------------------------------`n`t`t`tLocations:`n-------------------------------------------------------------------"}

# Load locations file.
if (!$path) {Write-Host -f cyan "`nDefault locations set:"; Get-Content $LocationsPath | ForEach-Object {$line=$_.Trim();if($line){$expanded=$ExecutionContext.InvokeCommand.ExpandString($line);if(Test-Path $expanded){$full=(Resolve-Path -LiteralPath $expanded).Path; $leaf=(Split-Path $full -Leaf).ToLower();$funcBody="`nfunction global:$leaf {Set-Location `"$full`"}";Invoke-Expression $funcBody;Write-Host "$leaf -> $full"}else{Write-Host -f darkgray "Skipped missing path: $expanded"}}};""; return}

# Provide valid options
elseif ($path -match "(?i)^help$") {Write-Host -f cyan "Valid options: " -n; Write-host -f yellow "current/valid path/add/remove/expunge/get/file`n"}

# Add the current directory for this session only.
elseif ($path -match "(?i)^(current)$") {$full=(Get-Location).Path; $leaf=(Split-Path $full -Leaf).ToLower();$funcBody="function global:$leaf {Set-Location `"$full`"}"; Invoke-Expression $funcBody; Write-Host -f yellow "`nAlias '$leaf' created for '$full'"; getlocations}

# Add a new destination to the file.
elseif ($path -match "(?i)^add$") {$current=(Get-Location).Path; $newPath=Read-Host "Enter the full path to add [`"$current`"]"; if (!$newPath) {$newPath=$current}; $expanded=$ExecutionContext.InvokeCommand.ExpandString($newPath); if (Test-Path $expanded) {$full=((Resolve-Path -LiteralPath $expanded).Path).ToLower(); $leaf=(Split-Path $full -Leaf).ToLower(); $funcBody="function global:$leaf {Set-Location `"$full`"}"; Invoke-Expression $funcBody; $existing=Get-Content $LocationsPath -ErrorAction SilentlyContinue; if($existing -contains $full) {Write-Host -f cyan "`nAlias '$leaf' already exists for '$full'`n"} else {Add-Content -Path $LocationsPath -Value $full; Write-Host -f yellow "`nAlias '$leaf' created and saved for '$full'`n"}; GC $LocationsPath;""} else {Write-Host -f red "`nInvalid path entered: $expanded`n"}}

# Delete an alias created during this session.
elseif ($path -match "(?i)^del(ete)?$") {""; $funcs=(Get-Command -Type Function | Where-Object {($_.Definition -match '^Set-Location') -and ($_.Name -notmatch '^(.:|cd..?)$')}); if(-not $funcs) {Write-Host -f red "`nNo session aliases to delete.`n"; return}; $funcs|ForEach-Object -Begin{$i=1}-Process {Write-Host -f cyan "$i. " -n; Write-Host -f white $_.Name; $i++}; $choice=Read-Host "`nEnter the number of the alias to delete"; if ($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $funcs.Count) {$target=$funcs[$choice-1].Name; Remove-Item "function:$target" -Force -ErrorAction SilentlyContinue; Remove-Item "function:global:$target" -Force -ErrorAction SilentlyContinue; Write-Host -f yellow "`nAlias '$target' removed from session.`n"} else {Write-Host -f red "`nInvalid selection.`n"}}

# Remove an entry from the file.
elseif ($path -match "(?i)^rem(ove)?$") {$entries=Get-Content $LocationsPath;if(-not $entries){Write-Host -f red "`nNo entries to remove.`n";return};$invalid=$entries|Where-Object{!(Test-Path ($ExecutionContext.InvokeCommand.ExpandString($_)))};if($invalid){Write-Host "`nThe following paths no longer exist:`n";$invalid|ForEach-Object{Write-Host -f darkgray $_};$prune=Read-Host "`nRemove these from the list? (y/n)";if($prune -match '^(y|yes)$'){$entries=$entries|Where-Object {$_ -notin $invalid};Set-Content -Path $LocationsPath -Value $entries;Write-Host -f yellow "`nRemoved invalid paths.`n"}};$entries|ForEach-Object -Begin{$i=1}-Process{Write-Host "$i. $_";$i++};$choice=Read-Host "`nEnter the number of the path to remove";if($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $entries.Count){$updated=$entries|Where-Object {$_ -ne $entries[$choice-1]};Set-Content -Path $LocationsPath -Value $updated;Write-Host -f yellow "`nRemoved entry: $($entries[$choice-1])`n"}else{Write-Host -f red "`nInvalid selection.`n"}}

# Remove all entries from the file.
elseif ($path -match "(?i)^expunge$") {""; GC $LocationsPath; ""; Write-Host -f red "Are you sure you want to delete all entries in the locations file? " -n; $confirm=Read-Host "(y/n)"; if($confirm -match '^(y|yes)$'){Clear-Content $LocationsPath; Write-Host -f red "`nAll entries removed from locations file.`n"} else{Write-Host -f darkgray "`nExpunge cancelled.`n"}}

# List all entries that exist in the file.
elseif ($path -match "(?i)^(file|default)$") {""; Get-Content $LocationsPath | ForEach-Object {if ($_ -match '\S') {$expanded=$ExecutionContext.InvokeCommand.ExpandString($_.Trim());$color=if(Test-Path $expanded){'White'}else{'DarkGray'};Write-Host -f $color "$_$(if($color -eq 'DarkGray'){' (missing)'})"}}; ""}

# List all entries that have been created this session.
elseif ($path -match "(?i)^(get|list)$") {getlocations}

# Add the path indicated to the current session.
elseif (Test-Path $path) {$full=(Resolve-Path -LiteralPath $path).Path; $leaf=(Split-Path $full -Leaf).ToLower();$funcBody="function global:$leaf {Set-Location `"$full`"}";Invoke-Expression $funcBody;Write-Host -f yellow "`nAlias '$leaf' created for '$full'"; getlocations}

# Error capture for invalid paths.
else {Write-Host -f red "`nInvalid path: $path`n"}}
sal -name location -value locations

# ----------------------------------------------------------------------------------
#									bookmark function
# ----------------------------------------------------------------------------------

$BookmarkFilePath = $script:BookmarkFilePath 

function bookmark ($mode) {# Use saved bookmarks to navigate or remove entries.
Write-Host -f yellow "`n-------------------------------------------------------------------`n`t`t`tBookmarks:`n-------------------------------------------------------------------"

# Validate input.
if (($mode) -and ($mode -notmatch "(?i)^(list|get|add|this|current|just(explorer?)?|expunge|rem(ove)?|explorer?|\d\d?)$")) {if ($mode -notmatch "(?i)^help") {Write-Host -f cyan "Invalid option."}
Write-Host -f cyan "Valid options: " -n; Write-Host -f yellow "add/this/expunge/remove/explorer/justexplorer/##/help"; Write-Host -f cyan "Numbered parameters represent speeddials for immediate naviation.`n";return}

# Check if bookmarks file exists and has content.
if (!(Test-Path $BookmarkFilePath) -or !(Get-Content $BookmarkFilePath | Where-Object {$_ -match '\S'})) {Write-Host -f red "No bookmarks available.`n"; return}

# Speeddial
if ($mode -match "^\d\d?$") {$SpeedDials = Get-Content $BookmarkFilePath; $index = [int]$mode - 1
if ($index -ge 0 -and $index -lt $SpeedDials.Count) {$SpeedDial = $SpeedDials[$index].Trim(); sl $SpeedDial; Write-Host -f green "`nsl $Speeddial`n"; return}
else {Write-Host -f cyan "`nInvalid bookmark number.`n"}}

# List entries.
if ($mode -match "(?i)^(list|get)$") {Write-Host -f cyan "`nSaved bookmarks:`n"; Get-Content $BookmarkFilePath; Write-Host ""; return}

# Add an entry.
if ($mode -match "(?i)^add(new)?$") {$response=(Read-Host "`nPath").trim(); if (!(Test-Path $response)) {Write-Host -f red "Path does not exist.`n"; return}; $resolved=(Get-Item $response).FullName; if ((Get-Content $BookmarkFilePath) -notcontains $resolved) {Add-Content $BookmarkFilePath $resolved; Write-Host -f green "`nAdded: $resolved"; gc $BookmarkFilePath} else {Write-Host -f yellow "`n$resolved already exists."}; ""; return}

# Add current.
if ($mode -match "(?i)^(current)$") {$current=(Get-Location).Path; if (!(Get-Content $BookmarkFilePath | Select-String -SimpleMatch $current)) {Add-Content $BookmarkFilePath $current; Write-Host -f green "`n$current added."}; gc $BookmarkFilePath; ""; return}

# Clear the bookmarks.
if ($mode -match "(?i)^expunge$") {""; Get-Content $BookmarkFilePath | Select-Object -Unique; ""; [console]::foregroundcolor = "red"; [string]$confirm = Read-Host "Are you sure you want to clear all bookmarks? (y/n)"; [console]::foregroundcolor = "white"; if ($confirm -ne 'y') {Write-Host -f yellow "Canceled.`n"; return}; Clear-Content $BookmarkFilePath; Write-Host -f green "Bookmarks cleared.`n"; return}

# Load and filter unique bookmarks.
$lines = Get-Content $BookmarkFilePath | Select-Object -Unique; $validity=@(); Write-Host -f cyan "`nSaved bookmarks:`n"; for ($i=0; $i -lt $lines.Count; $i++) {$exists=Test-Path $lines[$i]; $validity+=$exists; $color = if ($exists) {'white'} else {'darkgray'}; Write-Host -f cyan "$($i+1):" -n; Write-Host -f $color (" $($lines[$i])" + ($(if(-not $exists){" (missing)"} else{""})))}

# If in remove mode, offer to delete non-existent paths.
if ($mode -match "(?i)^rem(ove)?$") {if ($validity -contains $false) {$nonexistent = @(); for ($i=0; $i -lt $lines.Count; $i++) {if (-not $validity[$i]) {$nonexistent += $lines[$i]}} 
$response = Read-Host "`nRemove all non-existent entries? (y/n)"; if ($response -match '^[Yy]$') {$lines = $lines | Where-Object {Test-Path $_}; Set-Content -Path $BookmarkFilePath -Value $lines}}
[int]$selection = Read-Host "`nSelect a bookmark to remove by number, 1 to $($lines.Count)"; if ($selection -lt 1 -or $selection -gt $lines.Count) {Write-Host -f red "Invalid entry. Exiting.`n"; return}; $lines = $lines | Where-Object {$_ -ne $lines[$selection - 1]}; Set-Content -Path $BookmarkFilePath -Value $lines; Write-Host -f green "Bookmark removed.`n"; return}

# Ask for selection to navigate to.
[int]$selection = Read-Host "`nSelect a location by number, 1 to $($lines.Count)"; if ($selection -lt 1 -or $selection -gt $lines.Count) {Write-Host -f red "Invalid entry. Exiting.`n"; return}; $destination = $lines[$selection - 1]; if (!(Test-Path $destination)) {Write-Host -f red "Selected path does not exist.`n"; return}; if ($mode -notmatch "(?i)^just(explorer?)?$") {sl $destination}; if($mode -match "(?i)^(just(explorer?)?|explorer?)$") {Start-Process explorer.exe $destination}; ""; return}
sal -name bookmarks -value bookmark
sal -name speeddial -value bookmark -scope global
sal -name speedial -value bookmark -scope global

# ----------------------------------------------------------------------------------
#									goto function
# ----------------------------------------------------------------------------------

$GotoSearchRoots = $script:GotoSearchRoots; $GotoCacheMaxAge = $script:GotoCacheMaxAge; $script:GotoCacheMaxMatches; $RecursionDepth = $script:RecursionDepth; $GotoCacheSize = $script:GotoCacheSize


function goto ($location,$explorer) {# Custom-recursive directory search, case-insensitive, with autocomplete, history and max depth.
$originalLocation = $Location.ToLowerInvariant(); $matches = @(); $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host -f yellow "`n-------------------------------------------------------------------`n`t`t`tGoTo:`n-------------------------------------------------------------------"

# Iterate through all entries in the cache and filter early
$matches = $GotoFolders | Where-Object {$leaf = ($_ -split '\\')[-1].ToLowerInvariant(); $leaf -like "*$($originalLocation)*"} | ForEach-Object {[PSCustomObject]@{Path = $_; Rel  = $_.Substring($_.IndexOf($root) + $root.Length + 1)}}

# Provide performance feedback
$stopwatch.Stop(); if ($stopwatch.Elapsed.TotalSeconds -gt 0) {Write-Host -f green "This search took " -n; Write-Host -f red ("{0:N3}" -f $stopwatch.Elapsed.TotalSeconds) -n; Write-Host -f green " seconds to complete."}

# If there are more than the set number of matches, attempt to limit to first 4 directory levels.
if ($matches.Count -gt $GotoCacheMaxMatches) {$earlyMatches = $matches | Where-Object {($_.Rel -split '\\').Count -le 4}
if ($earlyMatches.Count -le $GotoCacheMaxMatches) {$matches = $earlyMatches}
else {Write-Host -f cyan "There are " -n; Write-Host -f red "$($matches.Count)" -n; Write-Host -f cyan " options matching the pattern `"" -n; Write-Host -f red "`*$originalLocation`*" -n; Write-Host -f cyan "`" as a parent directory. Please refine your search.`n"; return}}

# Provide options if more than one match exists.
if ($matches.Count -gt 1) {write-host -f cyan "Multiple matches found:`n"; for ($i = 0; $i -lt $matches.Count; $i++) {write-host -f cyan "$($i + 1):" -n; Write-Host -f white " $($matches[$i].Rel)"}; [int]$selection = Read-Host "`nSelect a location by number, 1 to $($matches.Count)";  if ($selection -lt 1 -or $selection -gt $matches.Count) {Write-Host -f red "Invalid entry. Exiting.`n"; break} else {$match = $matches[$selection - 1]}}

# Set the option if only one match exists.
elseif ($matches.Count -eq 1) {$match = $matches[0]}

# Return an error if no match exists.
else {Write-Host -f cyan "A `"" -n; Write-Host -f red "*$originalLocation*" -n; Write-Host -f cyan "`" directory pattern cannot be found under parent paths: " -n; for ($i = 0; $i -lt $GotoSearchRoots.Count; $i++) {Write-Host -f yellow $GotoSearchRoots[$i] -n; if ($i -lt $GotoSearchRoots.Count - 1) {Write-Host -f cyan ", " -n}}; Write-Host -f cyan ".`n"; return}

# Save last selection, dedup and trim to a set maximum.
$logEntry = $match.Rel; $existingEntries = @()
if (Test-Path $GotoLogPath) {$existingEntries = Get-Content $GotoLogPath | Where-Object {$_ -match '\S'} | Select-Object -Unique}
if (!(Test-Path $GotoLogPath) -or !($existingEntries -contains $logEntry)) {$updatedEntries = ,$logEntry + ($existingEntries | Where-Object {$_ -ne $logEntry}); $updatedEntries = $updatedEntries | Select-Object -First $GotoCacheSize; Set-Content -Path $GotoLogPath -Value $updatedEntries}

# Change to the selected directory
$destination = $match.Rel; sl $destination; if($explorer -match "(?i)^explorer?$") {Start-Process explorer.exe $destination}}
sal -name jumpto -value goto


# ----------------------------------------------------------------------------------
#									recent function
# ----------------------------------------------------------------------------------

$GotoLogPath = $script:GotoLogPath

function recent ($mode) {# Use recent goto commands for selecting a destination or removing entries.
Write-Host -f yellow "`n-------------------------------------------------------------------`n`t`t`tRecent:`n-------------------------------------------------------------------"
# Validate input.
if (($mode) -and ($mode -notmatch "(?i)^(list|get|clear|rem(ove)?|explorer?)$")) {if ($mode -notmatch "(?i)^help") {Write-Host -f cyan "`nInvalid option."}
Write-Host -f cyan "Valid options: " -n; Write-Host -f yellow "list/clear/remove/explorer/help`n";return}

# Check if previous selections file exists and has content.
if (!(Test-Path $GotoLogPath) -or !(Get-Content $GotoLogPath | Where-Object {$_ -match '\S'})) {Write-Host -f yellow "No previous selection is available.`n"; return}

# List entries.
if ($mode -match "(?i)^(list|get)$") {Write-Host -f cyan "`nPreviously selected locations:`n"; Get-Content $GotoLogPath; Write-Host ""; return}

# Clear the logs.
if ($mode -match "(?i)^clear$") {""; Get-Content $GotoLogPath | Select-Object -Unique; ""; [string]$confirm = Read-Host "Are you sure you want to clear all saved selections? (y/n)"; if ($confirm -ne 'y') {Write-Host -f yellow "Canceled.`n"; return}; Clear-Content $GotoLogPath; Write-Host -f green "Last selections cleared.`n"; return}

# Load and filter unique selections.
$lines = Get-Content $GotoLogPath | Select-Object -Unique; $validity=@(); Write-Host -f cyan "`nPreviously selected locations:`n"; for ($i=0; $i -lt $lines.Count; $i++) {$exists=Test-Path $lines[$i]; $validity+=$exists; $color = if ($exists) {'white'} else {'darkgray'}; Write-Host -f cyan "$($i+1):" -n; Write-Host -f $color (" $($lines[$i])" + ($(if(-not $exists){" (missing)"} else{""})))}

# If in remove mode, offer to delete non-existent paths.
if ($mode -match "(?i)^rem(ove)?$") {if ($validity -contains $false) {$nonexistent = @(); for ($i=0; $i -lt $lines.Count; $i++) {if (-not $validity[$i]) {$nonexistent += $lines[$i]}} 
$response = Read-Host "`nRemove all non-existent entries? (y/n)"; if ($response -match '^[Yy]$') {$lines = $lines | Where-Object {Test-Path $_}; Set-Content -Path $GotoLogPath -Value $lines}}
[int]$selection = Read-Host "`nSelect an entry to remove by number, 1 to $($lines.Count)"; if ($selection -lt 1 -or $selection -gt $lines.Count) {Write-Host -f red "Invalid entry. Exiting.`n"; return}; $lines = $lines | Where-Object {$_ -ne $lines[$selection - 1]}; Set-Content -Path $GotoLogPath -Value $lines; Write-Host -f green "Entry removed.`n"; return}

# Ask for selection to navigate to.
[int]$selection = Read-Host "`nSelect a location by number, 1 to $($lines.Count)"; if ($selection -lt 1 -or $selection -gt $lines.Count) {Write-Host -f red "Invalid entry. Exiting.`n"; return}; $destination = $lines[$selection - 1]; if (!(Test-Path $destination)) {Write-Host -f red "Selected path does not exist."; return}; sl $destination; if($mode -match "(?i)^explorer?$") {Start-Process explorer.exe $destination}; return}
sal -name recents -value recent

# ----------------------------------------------------------------------------------
#									autocomplete cache
# ----------------------------------------------------------------------------------

$GotoCachePath = $script:GotoCachePath; $GotoSearchExclusions = $script:GotoSearchExclusions;

function getgotocache {if (Test-Path $GotoCachePath) {try {$bytes = [IO.File]::ReadAllBytes($GotoCachePath); $ms = New-Object IO.MemoryStream(,$bytes); $gs = New-Object IO.Compression.GzipStream($ms, [IO.Compression.CompressionMode]::Decompress); $sr = New-Object IO.StreamReader($gs); return $sr.ReadToEnd() | ConvertFrom-Json}
catch {return @()}}
return @()}

function startgotocacherefresh {Start-Job -ScriptBlock {try {Write-Host -f yellow "`nCache refresh job started."; $folders = foreach ($root in $using:GotoSearchRoots) {Write-Host "`nSearching: $root " -n; $collected = @($root)

# Recursively get subdirectories up to max depth
$subdirs = Get-ChildItem -Path $root -Recurse -Directory -Force -ErrorAction SilentlyContinue | Where-Object {($_.FullName.Substring($root.Length+1)).Split('\').Count -le $using:RecursionDepth}

# Filter exclusions and build list
$collected += $subdirs | ForEach-Object {try {$folderName = $_.Name
if ($using:GotoSearchExclusions -contains $folderName.Substring(0, [Math]::Min($folderName.Length, 12))) {Write-Host -f red "Excluding: $($_.FullName) " -n}
else {$_.FullName}}
catch {Write-Host -f red "." -n}}
$collected}

$folders = $folders | Sort-Object -Unique; Write-Host "`nFolders found: $($folders.Count)" -f green

# Convert to JSON and compress
$json = $folders | ConvertTo-Json -Depth 3; $bytes = [System.Text.Encoding]::UTF8.GetBytes($json); $ms = New-Object IO.MemoryStream; $gz = New-Object IO.Compression.GzipStream($ms, [IO.Compression.CompressionMode]::Compress); $gz.Write($bytes, 0, $bytes.Length); $gz.Close(); [IO.File]::WriteAllBytes($using:GotoCachePath, $ms.ToArray())

Write-Host -f green "Cache file updated: " -n; Write-Host -f yellow "$using:GotoCachePath`n"}
catch {Write-Host -f red "Error during cache refresh: $_"}} | Out-Null; ""}

# Check cache freshness
$refreshNeeded = $true; if (Test-Path $GotoCachePath) {$lastWrite = (Get-Item $GotoCachePath).LastWriteTime; if (((Get-Date) - $lastWrite).TotalMinutes -lt $GotoCacheMaxAge) {$refreshNeeded = $false}}

# Start refresh if needed
if ($refreshNeeded) {startgotocacherefresh}

# Load existing cache into memory
$Global:GotoFolders = getgotocache

# Register autocompletion
Register-ArgumentCompleter -CommandName goto -ParameterName location -ScriptBlock {param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters); $Global:GotoFolders | Where-Object {$_ -like "*$wordToComplete*"} | Sort-Object -Unique | ForEach-Object {[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)}}

# ----------------------------------------------------------------------------------
#									view goto folder cache
# ----------------------------------------------------------------------------------

# View details about the Goto folder cache.
function viewgotocache ($refresh) {$columnWidth = 40; $columnIndex = 0; $entryLengths = @(); $longestLine = ""; $longestLength = 0

Write-Host -f yellow "`n-------------------------------------------------------------------`n`t`t`tViewGoToCache:`n-------------------------------------------------------------------"

# Force a refresh
if ($refresh -match "(?i)^re(create|fresh)$") {startgotocacherefresh; return}

# Load entries via getgotocache
$entries = getgotocache
if (-not $entries -or $entries.Count -eq 0) {Write-Host -f red "No entries found in cache."; return}

# Calculate stats
foreach ($entry in $entries) {$cleanEntry = $entry -replace '[",\[\]]',''
if ($cleanEntry) {$entryLengths += $cleanEntry.Length
if ($cleanEntry.Length -gt $longestLength) {$longestLength = $cleanEntry.Length; $longestLine = $cleanEntry}}}

$fileInfo = Get-Item $GotoCachePath; $totalEntries = $entryLengths.Count; $averageLength = [math]::Round(($entryLengths | Measure-Object -Average).Average, 1); $medianLength = [math]::Round(($entryLengths | Sort-Object | Select-Object -Skip ([math]::Floor(($entryLengths.Count-1)/2)) -First 1), 1); $shortestLength = ($entryLengths | Measure-Object -Minimum).Minimum; $fileSize = "{0:N0}" -f $fileInfo.Length; $lastModified = $fileInfo.LastWriteTime

# Detect non-English
$nonEnglishEntries = $entries | Where-Object {($_ -match '[^\x00-\x7F]') -and ($_ -notmatch '[꞉“”]') -and $_}

# Show non-English if present
Write-Host -f cyan "GotoCache: " -n; Write-Host -f yellow $GotoCachePath

if ($nonEnglishEntries.Count -gt 0) {Write-Host -f yellow "`n$($nonEnglishEntries.Count)" -n; Write-Host " Non-English Entries:`n--------------------------`n" -f cyan; 
$consoleWidth = [Console]::WindowWidth; $padding = 1; $columnWidth = [Math]::Floor(($consoleWidth - $padding) / 2)
$columnIndex = 0; $nonEnglishEntries | % {$displayEntry = $_.Substring(0, [Math]::Min($columnWidth, $_.Length))
if ($displayEntry.Length -gt $columnWidth) {$displayEntry += '...'}
$columnIndex++
if ($columnIndex % 2 -ne 0) {Write-Host ("{0,-$($columnWidth+1)}" -f $displayEntry) -n}
else {Write-Host $displayEntry}}; ""}

# Stats output
Write-Host "`nFile size: " -f cyan -n; Write-Host "$fileSize bytes" -f yellow -n
Write-Host "`tTotal entries: " -f cyan -n; Write-Host $totalEntries -f yellow -n
Write-Host "`tLast modified time: " -f cyan -n; Write-Host $lastModified -f yellow
Write-Host "Average length: " -f cyan -n; Write-Host $averageLength -f yellow -n
Write-Host "`tMedian: " -f cyan -n; Write-Host $medianLength -f yellow -n
Write-Host "`tShortest: " -f cyan -n; Write-Host $shortestLength -f yellow -n
Write-Host "`tLongest: " -f cyan -n; Write-Host "$longestLength " -f yellow
Write-Host "Longest name: " -f cyan -n; Write-Host $longestLine

# Prompt to view contents
Write-Host -f yellow "`nDo you want to view the entire contents of the file? (Y/N) " -n; $viewAll = Read-Host
if ($viewAll -match '^(?i)y') {$content = getgotocache
$searchHits = @(0..($content.Count - 1) | Where-Object {$content[$_] -match $pattern})
$currentSearchIndex = $searchHits | Where-Object {$_ -gt $pos} | Select-Object -First 1; $pos = $currentSearchIndex; $content = $content | ForEach-Object {wordwrap $_ $null} | ForEach-Object {$_ -split "`n"}
$pageSize = 44; $pos = 0; $script:fileName = [System.IO.Path]::GetFileName($script:file); $searchHits = @(); $currentSearchIndex = -1

function getbreakpoint {param($start); return [Math]::Min($start + $pageSize - 1, $content.Count - 1)}

function showpage {cls; $start = $pos; $end = getbreakpoint $start; $pageLines = $content[$start..$end]; $highlight = if ($searchTerm) {"$pattern"} else {$null}
foreach ($line in $pageLines) {if ($highlight -and $line -match $highlight) {$parts = [regex]::Split($line, "($highlight)")
foreach ($part in $parts) {if ($part -match "^$highlight$") {Write-Host -f black -b yellow $part -n}
else {Write-Host -f white $part -n}}; ""}
else {Write-Host -f white $line}}

# Pad with blank lines if this page has fewer than $pageSize lines
$linesShown = $end - $start + 1
if ($linesShown -lt $pageSize) {for ($i = 1; $i -le ($pageSize - $linesShown); $i++) {Write-Host ""}}}

# Main menu loop
$statusmessage = ""; $errormessage = ""; $searchmessage = "Search Commands"
while ($true) {showpage; $pageNum = [math]::Floor($pos / $pageSize) + 1; $totalPages = [math]::Ceiling($content.Count / $pageSize)
if ($searchHits.Count -gt 0) {$currentMatch = [array]::IndexOf($searchHits, $pos); if ($currentMatch -ge 0) {$searchmessage = "Match $($currentMatch + 1) of $($searchHits.Count)"}
else {$searchmessage = "Search active ($($searchHits.Count) matches)"}}

line yellow -double
if (-not $errormessage -or $errormessage.length -lt 1) {$middlecolour = "white"; $middle = $statusmessage} else {$middlecolour = "red"; $middle = $errormessage}
$left = "$([System.IO.Path]::GetFileName($script:GotoCachePath))".PadRight(57); $middle = "$middle".PadRight(44); $right = "(Page $pageNum of $totalPages)"
Write-Host -f white $left -n; Write-Host -f $middlecolour $middle -n; Write-Host -f cyan $right
$left = "Page Commands".PadRight(55); $middle = "| $searchmessage ".PadRight(34); $right = "| Exit Commands"
Write-Host -f yellow ($left + $middle + $right)
Write-Host -f yellow "[F]irst [N]ext [+/-]# Lines P[A]ge # [P]revious [L]ast | [<][S]earch[>] [#]Match [C]lear | [Q]uit " -n
$statusmessage = ""; $errormessage = ""; $searchmessage = "Search Commands"

function getaction {[string]$buffer = ""
while ($true) {$key = [System.Console]::ReadKey($true)
switch ($key.Key) {'LeftArrow' {return 'P'}
'UpArrow' {return 'U1L'}
'Backspace' {return 'P'}
'PageUp' {return 'P'}
'RightArrow' {return 'N'}
'DownArrow' {return 'D1L'}
'PageDown' {return 'N'}
'Enter' {if ($buffer) {return $buffer}
else {return 'N'}}
'Home' {return 'F'}
'End' {return 'L'}
default {$char = $key.KeyChar
switch ($char) {',' {return '<'}
'.' {return '>'}
{$_ -match '(?i)[B-Z]'} {return $char.ToString().ToUpper()}
{$_ -match '[A#\+\-\d]'} {$buffer += $char}
default {$buffer = ""}}}}}}

$action = getaction

switch ($action.ToString().ToUpper()) {'F' {$pos = 0}
'N' {$next = getbreakpoint $pos; if ($next -lt $content.Count - 1) {$pos = $next + 1}
else {$pos = [Math]::Min($pos + $pageSize, $content.Count - 1)}}
'P' {$pos = [Math]::Max(0, $pos - $pageSize)}
'L' {$lastPageStart = [Math]::Max(0, [int][Math]::Floor(($content.Count - 1) / $pageSize) * $pageSize); $pos = $lastPageStart}

'<' {$currentSearchIndex = ($searchHits | Where-Object {$_ -lt $pos} | Select-Object -Last 1)
if ($null -eq $currentSearchIndex -and $searchHits -ne @()) {$currentSearchIndex = $searchHits[-1]; $statusmessage = "Wrapped to last match."; $errormessage = $null}
$pos = $currentSearchIndex
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null}}
'S' {Write-Host -f green "`n`nKeyword to search forward from this point in the logs" -n; $searchTerm = Read-Host " "
if (-not $searchTerm) {$errormessage = "No keyword entered."; $statusmessage = $null; $searchTerm = $null; $searchHits = @(); continue}
$pattern = "(?i)$searchTerm"; $searchHits = @(0..($content.Count - 1) | Where-Object { $content[$_] -match $pattern })
if ($searchHits.Count -eq 0) {$errormessage = "Keyword not found in file."; $statusmessage = $null; $currentSearchIndex = -1}
else {$currentSearchIndex = $searchHits | Where-Object { $_ -gt $pos } | Select-Object -First 1
if ($null -eq $currentSearchIndex) {Write-Host -f green "No match found after this point. Jump to first match? (Y/N)" -n; $wrap = Read-Host " "
if ($wrap -match '^[Yy]$') {$currentSearchIndex = $searchHits[0]; $statusmessage = "Wrapped to first match."; $errormessage = $null}
else {$errormessage = "Keyword not found further forward."; $statusmessage = $null; $searchHits = @(); $searchTerm = $null}}
$pos = $currentSearchIndex}}
'>' {$currentSearchIndex = ($searchHits | Where-Object {$_ -gt $pos} | Select-Object -First 1)
if ($null -eq $currentSearchIndex -and $searchHits -ne @()) {$currentSearchIndex = $searchHits[0]; $statusmessage = "Wrapped to first match."; $errormessage = $null}
$pos = $currentSearchIndex
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null}}
'C' {$searchTerm = $null; $searchHits.Count = 0; $searchHits = @(); $currentSearchIndex = $null}

'Q' {cls; return}
'U1L' {$pos = [Math]::Max($pos - 1, 0)}
'D1L' {$pos = [Math]::Min($pos + 1, $content.Count - $pageSize)}

default {if ($action -match '^[\+\-](\d+)$') {$offset = [int]$action; $newPos = $pos + $offset; $pos = [Math]::Max(0, [Math]::Min($newPos, $content.Count - $pageSize))}

elseif ($action -match '^(\d+)$') {$jump = [int]$matches[1]
if (-not $searchHits -or $searchHits.Count -eq 0) {$errormessage = "No search in progress."; $statusmessage = $null; continue}
$targetIndex = $jump - 1
if ($targetIndex -ge 0 -and $targetIndex -lt $searchHits.Count) {$pos = $searchHits[$targetIndex]
if ($targetIndex -eq 0) {$statusmessage = "Jumped to first match."}
else {$statusmessage = "Jumped to match #$($targetIndex + 1)."}; $errormessage = $null}
else {$errormessage = "Match #$jump is out of range."; $statusmessage = $null}}

elseif ($action -match '^A(\d+)$') {$requestedPage = [int]$matches[1]
if ($requestedPage -lt 1 -or $requestedPage -gt $totalPages) {$errormessage = "Page #$requestedPage is out of range."; $statusmessage = $null}
else {$pos = ($requestedPage - 1) * $pageSize}}

else {$errormessage = "Invalid input."; $statusmessage = $null}}}}}
else {""}}

sal -name gotocache -value viewgotocache

# ----------------------------------------------------------------------------------
#									Define External Availability
# ----------------------------------------------------------------------------------

Export-ModuleMember -Function navigation, bookmark, locations, goto, recent, viewgotocache
Export-ModuleMember -Alias bookmarks, gotocache, jumpto, location, recents, speedial, speeddials

Write-Host -f yellow "`nType `"Navigation`" at the command prompt to open the help file for this module and all of its features. "; Write-Host -f cyan "Copyright © 2025 Craig Plath"

# ----------------------------------------------------------------------------------
#									Helptext
# ----------------------------------------------------------------------------------

<#
## Introduction
This module was created in response to my desire to make navigating within PowerShell on Windows much more convenient, by adding additional functionality to speed up many command line interactions. Yes, it has been designed with Windows in mind and while a lot of the features will likely work on xNix based systems as well, they have not been tested and I have no idea how well they would work. Some features, like the Explorer functionality, will obviously not work at all outside of Windows.

This started as a simple goto function that allowed me to quickly navigate to any directory on my computer, regardless of which drive it was located on, without having to memorize entire paths or navigate up and down several directories. As anyone who has worked in a shell for any length of time knows, the pain of navigation is real and often entails a lot of change directory commands, followed by listing the directory structure, the another change directory, and so on.

That becomes very cumbersome and so, this project began with simple origins, but kept growing into a larger, far more comprehensive package until now, it is a full suite of navigational tools that helps beginners and power users alike move around within PowerShell much quicker than they normally can; faster even than using Windows Explorer.

## Basic Functionality
Location(s) allows you to save and manage "macros" that will navigate to a directory simply by typing it's name and these can either be saved per user session, or permanently, using a persistent file mechanism.

Bookmark(s) similarly allows you to navigate to directories with much greater ease. The difference is that this feature presents you with a menu of options that you configure and you simply select a number to hop to that location.

Goto was the original function that started this project. It allows a user to jump to a location using a directory cache and autocompletion feature in order to make it exponentially faster. The timer feature will demonstrate just how fast it can be. I have 30k directories saved and yet, navigating to directories can take under a second.

Recent(s) allows you to interact with the directories you have previously jumped to using the Goto feature, thereby allowing you to jump back to recent directories with much greater ease.

AutoComplete Cache is the background functionality that creates and maintains the folder cache and provides the autocompletion capabilities.

ViewGotoCache is a bit more obscure, but is interesting for the technical fans. It allows you to interact with the folder cache and display some interesting statistics about it. This has limited functionality, but is somewhat useful and fun for those that care.

Bonus feature: Bookmark(s), Goto and Recent(s) also allow you the option to open the directories you choose in an Explorer window.
## Location
Location or Locations, if you choose the alias, allows you to dynamically create functions that will redirect you, through means of the set-location command, to any directory you choose, simply by typing it's name. You can either make them on the fly, so that they are only relevant for your current PowerShell session, or you can save them to a file, such that they are loaded everytime you run the locations command without any parameters.

Parameter:     Purpose:
_____          Load entries from the Locations.log file.
help           This help menu.
current        Creates a function for the current path, relevant for the current session only.
path           Tests the path and creates a function for the that folder if valid.
add            Asks you for a path, defaults to the current, tests and saves it if valid.
del(ete)       Removes saved locations from the Locations.log file.
re(move)       Removes saved locations from the Locations.log file.
expunge        Delete all entries from the Locations.log file.
get            Lists all locations relevant during the current session, including temporary.
file/default   Lists all locations in the Locations.log file.

## Location Usage
In the example below I navigate to the desktop using a function created by the locations command used without parameters at session load time. As you can see, this function, named for the folder to which it directs you took me there simply by typing the folder name. Next, I create a temporary directory and navigate to it for the purposes of this demonstration. Then I create a function for the current directory, delete the directory and run the location(s) command using the file option to see that the location is now listed as "(missing)", since the path is now broken.

	C:\> desktop
	C:\Users\Schvenn\Desktop> md blarg; sl blarg; locations add
	Enter the full path to add ["C:\Users\Schvenn\Desktop\blarg"]:

	Alias 'blarg' created and saved for 'c:\users\schvenn\desktop\blarg'

		`$home\desktop
		`$home\documents
		`$home\documents\powershell\modules
		c:\users\schvenn\desktop\blarg

	C:\Users\Schvenn\Desktop\blarg> cd ..; remove-item blarg
	C:\Users\Schvenn\Desktop> locations file

		`$home\desktop
		`$home\documents
		`$home\documents\powershell\modules
		c:\users\schvenn\desktop\blarg (missing)
## Bookmark
You may not always want to create folder functions. So, having a navigation list ready is useful, which is why bookmark(s) exist. There is an alias of course, for the alternate spelling. Here is how you use it:

Parameter:         Purpose:
_____              A menu will present your saved bookmarks for immediate navigation.
help               Provides valid command line options.
invalid value      Provides valid command line options.
list/get           List your bookmarks.
add                Add valid paths to the bookmarks file.
current            Add the current path to the bookmarks file.
expunge            Delete everything in the bookmarks file.
re(move)           Remove items from the bookmarks file, identifying broken paths.
explore(r)         Opens an Explorer window, as well as navigating to your chosen option.
justexplore(r)     Open an Explorer window, without navigating there.
## Bookmark Usage
As you can see below, I created a bookmark for the blarg directory, removed that directory and opened the bookmarks again, such that the function now correctly indicates the bookmark is no longer valid.

C:\Users\Schvenn\Desktop> md blarg; sl blarg; bookmark this

	C:\Users\Schvenn\Desktop\blarg added.
	...

C:\Users\Schvenn\Desktop\blarg> cd ..; remove-item blarg; bookmarks

	Saved bookmarks:
	...
	4: D:\Users\Schvenn\Documents\Powershell\Modules
	5: C:\Users\Schvenn\Desktop\blarg (missing)
## Goto
This was the original function and is the most complex in design, but simplest to use. As such, it only accepts two options, a valid path and the optional explorer switch:

	C:\Users\Schvenn\Desktop\blarg> goto documents explorer

You must provide Goto with the name of a folder, at which point, it will search your folder cache, created by the Autocomplete function below and either navigate there, or present you with options to choose from, before navigation. If the folder name or partial string that you provide has too many matches, Goto will tell you to be more specific.

The optional explorer switch will open an Explorer window at the selected location, as well as navigating there.

That is it. This function is designed to be simple and seamless, but wait! There's more! This is where the autocompletion feature comes into play. The first time you use it, PowerShell will take a few minutes to scan the directories you configured and populate its folder cache, after which, you can use TAB to take advantage of this feature. Consider for example, a situation wherein you only know part of the folder name. Type Goto, followed by the part of the folder name that you do know and start using TAB and Shift-TAB to cycle through all the possible options, before selecting the folder you require. This is where the power of this tool becomes immediately evident.

The only other feature to be aware of is the selection history. Every time you use Goto, it will save the directories to which you navigated to in its history file. By default the history is set to 25 entries, but you can configure this to a different size, if you wish. This history cache is used by the next feature, Recent(s).
## Recent
This function uses the history logs of GoTo. So, the larger you make this cache, the default is 25 entries, the more useful it will likely become. Here are its features:

Parameter:     Purpose:
_____          A menu will present the most recent Goto directories used, for quick return.
help           Provides valid command line options.
invalid value  Provides valid command line options.
list/get       List the Goto history, without the option to navigate.
clear          This will delete the Goto history, but only after a confirmation prompt.
re(move)       A menu of the Goto history will allow you to remove specific entries.
explore(r)     Also opens an Explorer window, as well as navigating to your chosen option.
## AutoComplete Cache
This set of functions creates the autocompletion feature for Goto, via the command line. It also builds the folder cache and loads it into memory, which is why it's so fast in helping you find your folders. There is nothing here with which the user needs to interact.
## ViewGotoCache
This is for those who really want to dig into the efficiencies of the module.

Parameter:           Purpose:
_____                ViewGotoCache will provide cache details with a view option.
recreate/refresh     This feature will rebuild the foldercache on demand, regardless of schedule.

Once the cache is populated, running ViewGotoCache will provide you summary details including: entries with non-English characters, file size, number of entries and last refresh date, as well as entry information, average and median length of folder names, shortest and longest folder name, as well as the actual longest folder name.

The non-English entries table and count helps you to find folder names that may have non-standard characters, such as diacritics. I have excluded only a few: ꞉“”. Those may look like a colon and standard quotation characters, but they are not. Many multimedia files use those characters in order to enable more convenient file naming for values that would otherwise be considered reserved characters.
## Viewing Gotocache Refresh
If you wish to see the progress of folder cache recreation when you utilize this feature, you will need to run a separate set of commands:

	Get-Job; Receive-Job -ID #

Get-Job is a standard PowerShell function that will present you a table of all background jobs currently running or complete. Use this to find the job ID number of your task; likely "1". Then run the Receive-Job ID command, another standard PowerShell function and provide it the number corresponding to the cache refresh. When you do so, you will likely be presented with output like the example below and while it make take several minutes to complete, the file will be written upon completion. Incidentally, the dots in the output represent folders that were skipped due to permissions issues.

C:\Users\Schvenn> Receive-Job -Id 1

	Cache refresh job started.

	Searching: C:\Users .......................................
	Searching: D:\Users
	Searching: E: Excluding: E:\$RECYCLE.BIN ...............
	Folders found: 25718
	Cache file updated: C:\Users\Schvenn\Documents\Powershell\Modules\Navigation\FolderCache.json
## Installation
Simply copy the Navigation Module folder contained in the installation package to your PowerShell Modules path.
I also recommend adding the following lines into your PowerShell profile, usually called: Microsoft.PowerShell_profile.ps1

	impo Navigation

At the bottom of the profile, after all other entries, you can also add the following line in order to initialize any immediate navigation directories you have saved at the start of every session:

	locations
## Module Contents
This package includes the following files:

File:                   Purpose:
Navigation.psd1         The standard PowerShell module manifest.
Navigation.psm1         The main module.

Additional files will be populated the first time you use specific features:

File:                   Purpose:
FolderCache.json.gz     The cache created by the AutoComplete function, used by the Goto function.
Bookmarks.log           Folder booksmarks you've created for fast navigation.
Locations.log           The immediate navigation directories you have saved.
History.log             The recent directories navigated to using Goto, used by Recent(s) function.
## Configuration
You can modify the Navigation.psd1 configuration file in any standard text editor.

@{GotoLogPath = "History.log"
GotoCachePath = "FolderCache.json.gz"
GotoSearchRoots = @("C:\Users","D:\Users","E:")
GotoSearchExclusions = @("`$RECYCLE.BIN","RecycleBin")
GotoCacheMaxAge = 5
GotoCacheMaxMatches = 10
RecursionDepth = 6
GotoCacheSize = 25
BookmarkFilePath = "Bookmarks.log"
LocationsPath = "Locations.log"}

Add or change the GotoSearchRoots in order to define what drives and root pathways you'd like the folder cache to contain.

The GotoCacheMaxAge represents the number of days should pass between scheduled cache refreshes. The default is set to 5.

RecursionDepth denotes how many directories deep the functions should search. I wouldn't recommend going higher than 6 and for most people, 4 is likely a better number; striking a balance between performance and completeness.

GotoCacheSize sets the number of directory hops to keep in the history for the Recent(s) function.
## License
Copyright © 2025 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
##>

