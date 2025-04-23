# ----------------------------------------------------------------------------------
#									load configuration
# ----------------------------------------------------------------------------------

function loadnavigationconfiguration {# (Internal) Load the configuration settings from the PSD1 file.
# Detect whether the module is under PowerShell or WindowsPowerShell
$script:baseModulePath = if ($PSVersionTable.PSEdition -eq 'Core') {"$env:USERPROFILE\Documents\Powershell\Modules\Navigation"} else {"$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Navigation"}

$script:configPath = Join-Path $baseModulePath "Navigation.Configuration.psd1"; if (!(Test-Path $configPath)) {throw "Config file not found at $configPath"}
$script:config = Import-PowerShellDataFile -Path $configPath

# Pull config values into variables
$script:GotoLogPath = Join-Path $baseModulePath $ExecutionContext.InvokeCommand.ExpandString($config.GotoLogPath)
$script:GotoCachePath = Join-Path $baseModulePath $ExecutionContext.InvokeCommand.ExpandString($config.GotoCachePath)
$script:GotoSearchRoots = $config.GotoSearchRoots
$script:GotoSearchExclusions = $config.GotoSearchExclusions
$script:GotoCacheMaxAge = $config.GotoCacheMaxAge
$script:GotoCacheMaxMatches = $config.GotoCacheMaxMatches
$script:RecursionDepth = $config.RecursionDepth
$script:GotoCacheSize = $config.GotoCacheSize
$script:BookmarkFilePath = Join-Path $baseModulePath $ExecutionContext.InvokeCommand.ExpandString($config.BookmarkFilePath)
$script:LocationsPath = Join-Path $baseModulePath $ExecutionContext.InvokeCommand.ExpandString($config.LocationsPath)}
loadnavigationconfiguration

# ----------------------------------------------------------------------------------
#									navigation help function
# ----------------------------------------------------------------------------------

function tableofcontents {clear-host
Write-Host -ForegroundColor Yellow "`n-------------------------------------------------------------------`n`t`t`tNavigation Help`n-------------------------------------------------------------------`n"
Write-Host "1. License"
Write-Host "2. Introduction"
Write-Host "3. Location(s)"
Write-Host "4. Bookmark(s)"
Write-Host "5. Goto"
Write-Host "6. Recent(s)"
Write-Host "7. AutoComplete Cache"
Write-Host "8. ViewGotoCache"
Write-Host "9. Installation"
Write-Host "10. Configuration"
Write-Host "11. Disclaimer"
Write-Host "Q. Quit"
Write-Host -ForegroundColor Yellow "-------------------------------------------------------------------`n"}

function navigation {# Help screen for this module
tableofcontents
do {$choice = Read-Host "`nEnter a number to view help or Q to quit"
switch ($choice.ToLower()) {
'1' {clear-host; tableofcontents; Write-Host @"
MIT License

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
"@ -ForegroundColor White}
'2' {clear-host; tableofcontents; Write-Host @"
Introduction:

This module was created in response to my desire to make navigating within PowerShell on Windows much more convenient, by adding additional functionality to speed up many command line interactions. Yes, it has been designed with Windows in mind and while a lot of the features will likely work on xNix based systems as well, they have not been tested and I have no idea how well they would work. Some features, like the Explorer functionality, will obviously not work at all outside of Windows.

This started as a simple goto function that allowed me to quickly navigate to any directory on my computer, regardless of which drive it was located on, without having to memorize entire paths or navigate up and down several directories. As anyone who has worked in a shell for any length of time knows, the pain of navigation is real and often entails a lot of change directory commands, followed by listing the directory structure, the another change directory, and so on.

That becomes very cumbersome and so, this project began with simple origins, but kept growing into a larger, far more comprehensive package until now, it is a full suite of navigational tools that helps beginners and power users alike move around within PowerShell much quicker than they normally can; faster even than using Windows Explorer.

-------------------------------------------------------------------
Basic functionality overview:

Location(s) allows you to save and manage "macros" that will navigate to a directory simply by typing it's name and these can either be saved per user session, or permanently, using a persistent file mechanism. Typing "Documents" for example, can take you directly to your documents folder without having to type the entire path or even remembering how deep inside a directory path that location may exist.

Bookmark(s) similarly allows you to navigate to directories with much greater ease. The difference is that this feature presents you with a menu of options that you configure and you simply select a number to hop to that location. This is useful when you have directories of many similar names or names that might overlap with commands and so forth.

Goto was the original function that started this project. It allows a user to jump to a location without having to navigate up and down multiple directories in order to get there. This feature now uses a directory cache and autocompletion features in order to make it exponentially faster. The timer feature will demonstrate just how fast it can be. I have 30k directories saved in my Goto cache and yet, navigating to directories I want to jump to can take under a second and PowerShell can find them in just milliseconds. This is the powerhouse of the package.

Recent(s) allows you to interact with the directories you have previously jumped to using the Goto feature, thereby allowing you to jump back to recent directories with much greater ease.

AutoComplete Cache is the background functionality that creates and maintains the folder cache and provides the autocompletion capabilities.

ViewGotoCache is a bit more obscure, but is interesting for the technical fans. It allows you to interact with the folder cache and display some interesting statistics about it. This has limited functionality, but is somewhat useful and fun for those that care.

Bonus feature: Bookmark(s), Goto and Recent(s) also allow you the option to open the directories you choose in an Explorer window.
"@ -ForegroundColor White}
'3' {clear-host; tableofcontents; Write-Host @"
Location(s):

Location or Locations, if you choose the alias, allows you to dynamically create functions that will redirect you, through means of the set-location command, to any directory you choose, simply by typing it's name. You can either make them on the fly, so that they are only relevant for your current PowerShell session, or you can save them to a file, such that they are loaded everytime you run the locations command without any parameters. I recommend adding this command to the end of your PowerShell profile, so that you have all of your favourite folders ready for you at the launch of every session.

This function is one of the last ones developed and has so many features that I had to create it's own help menu. Here is how you use it:

Parameter:		Purpose:
_____			If you run location(s) without any parameters, it will read the locations.log file and create commands from all of the paths you have saved there.
help			This presents a screen with all of the features.
this/current		Creates a function for the current path, relevant for the current session only.
any valid path		Entering any path, tests that path and creates a function for the that folder if valid.
add			Asks you for a path, (defaults to current) tests and creates it, saving it to the file for repeated use.
del(ete)		This presents a menu of all items currently active and allows you to remove them.
re(move)		This presents a menu of all items in the locations file and allows you to remove them.
expunge			This allows you to delete all entries in the locations file, but asks you for confirmation before proceeding.
get			This presents a list of all functions created by this command, during the current session.
file/default		This will simply list all of the entries in the locations file, also indicating broken paths.

-------------------------------------------------------------------
Example usage:

In the example below I navigate to the desktop using a function created by the locations command used without parameters at session load time. As you can see, this function, named for the folder to which it directs you took me there simply by typing the folder name. Next, I create a temporary directory and navigate to it for the purposes of this demonstration. Then I create a function for the current directory, delete the directory and run the location(s) command using the file option to see that the location is now listed as "(missing)", since the path is now broken.

	C:\> desktop
	C:\Users\Schvenn\Desktop> md blarg; sl blarg; locations add
	Enter the full path to add ["C:\Users\Schvenn\Desktop\blarg"]:

	Alias 'blarg' created and saved for 'c:\users\schvenn\desktop\blarg'

		`$env:USERPROFILE\desktop
		`$env:USERPROFILE\documents
		`$env:USERPROFILE\documents\powershell\modules
		c:\users\schvenn\desktop\blarg

	C:\Users\Schvenn\Desktop\blarg> cd ..; remove-item blarg
	C:\Users\Schvenn\Desktop> locations file

		`$env:USERPROFILE\desktop
		`$env:USERPROFILE\documents
		`$env:USERPROFILE\documents\powershell\modules
		c:\users\schvenn\desktop\blarg (missing)

"@ -ForegroundColor White}
'4' {clear-host; tableofcontents; Write-Host @"
Bookmark(s):

You may not always want to create folder functions. So, having a navigation list ready is useful, which is why bookmark(s) exist. There is an alias of course, for the alternate spelling. Here is how you use it:

Parameter:		Purpose:
_____			Running it without a parameter presents you with a menu of your saved bookmarks for immediate navigation.
invalid input		By typing something invalid, the function will provide you with a list of acceptable parameters.
list/get		This presents you a list of your bookmarks, without any required interaction.
add			This allows you to add valid paths to the bookmarks file.
this/current		This will add the current path to the bookmarks file.
expunge			This will delete everything in the bookmarks file, but with a confirmation before proceeding.
re(move)			This allows you to remove items from the bookmarks file, identifying broken paths.
explore(r)		This presents a menu of your bookmarks, but opens an Explorer window, as well as navigating to your chosen option.
justexplore(r)		This will present a menu of your bookmarks, but only open an Explorer window of the chosen option, without navigating there.

-------------------------------------------------------------------
Example usage:

As you can see below, I created a bookmark for the blarg directory, removed that directory and opened the bookmarks again, such that the function now correctly indicates the bookmark is no longer valid.

C:\Users\Schvenn\Desktop> md blarg; sl blarg; bookmark this

	C:\Users\Schvenn\Desktop\blarg added.
	...

C:\Users\Schvenn\Desktop\blarg> cd ..; remove-item blarg; bookmarks

	Saved bookmarks:
	...
	4: D:\Users\Schvenn\Documents\Powershell\Modules
	5: C:\Users\Schvenn\Desktop\blarg (missing)
"@ -ForegroundColor White}
'5' {clear-host; tableofcontents; Write-Host @"
Goto:

This was the original function and is the most complex in design, but simplest to use. As such, it only accepts two options, a valid path and the optional explorer switch:

	C:\Users\Schvenn\Desktop\blarg> goto documents explorer

You must provide Goto with the name of a folder, at which point, it will search your folder cache, created by the Autocomplete function below and either navigate there, or present you with options to choose from, before navigation. If the folder name or partial string that you provide has too many matches, Goto will tell you to be more specific.

The optional explorer switch will open an Explorer window at the selected location, as well as navigating there.

That is it. This function is designed to be simple and seamless, but wait! There's more! This is where the autocompletion feature comes into play. The first time you use it, PowerShell will take a few minutes to scan the directories you configured and populate its folder cache, after which, you can use TAB to take advantage of this feature. Consider for example, a situation wherein you only know part of the folder name. Type Goto, followed by the part of the folder name that you do know and start using TAB and Shift-TAB to cycle through all the possible options, before selecting the folder you require. This is where the power of this tool becomes immediately evident.

The only other feature to be aware of is the selection history. Every time you use Goto, it will save the directories to which you navigated to in its history file. By default the history is set to 25 entries, but you can configure this to a different size, if you wish. This history cache is used by the next feature, Recent(s).
"@ -ForegroundColor White}
'6' {clear-host; tableofcontents; Write-Host @"
Recent(s):

This function uses the history logs of GoTo. So, the larger you make this cache, the default is 25 entries, the more useful it will likely become. Here are its features:

Parameter:		Purpose:
_____			By providing no parameters, Recent(s) will present you a menu of the most recent directories to which you navigated with Goto, for quick return.
list/get		This will simply list the Goto history, without the option to navigate.
clear			This will delete the Goto history, but only after a confirmation prompt.
re(move)		This will provide you with a menu of the Goto history and allow you to remove specific entries, useful for maintaining temporary navigation priority.
explore(r)		This presents a menu of the Goto history, but opens an Explorer window, as well as navigating to your chosen option.
"@ -ForegroundColor White}
'7' {clear-host; tableofcontents; Write-Host @"
AutoComplete Cache:

This set of functions creates the autocompletion feature for Goto, via the command line. It also builds the folder cache and loads it into memory, which is why it's so fast in helping you find your folders. There is nothing here with which the user needs to interact.
"@ -ForegroundColor White}
'8' {clear-host; tableofcontents; Write-Host @"
ViewGotoCache:

This last minute addition is a feature I added more out of curiousity and troubleshooting than anything else, but I found it useful, so I've added it to the package, because I believe it does provide some benefits. Here is how you use it:

Parameter:		Purpose:
_____			By providing no parameters, ViewGotoCache will generate a screen of statistics about the folder cache, with an option for you to view the entire cache, if you so choose.
recreate/refresh	This feature will rebuild the foldercache on demand. By default, this is only done every 5 days, adjustable via the configuration file. This option provides no visual output by default

-------------------------------------------------------------------
Here is what you can expect to see:

GotoCache: C:\Users\Schvenn\Documents\Powershell\Modules\Navigation\FolderCache.json

 89 Non-English Entries:
--------------------------

  D:\\Users\\Schvenn\\Audio\\Mystery Cri  D:\\Users\\Schvenn\\Audio\\Mystery Cri  D:\\Users\\Schvenn\\Audio\\Tammy\\Auth
  ...

File size: 2,187,621 bytes      Total entries: 25718    Last modified time: 4/21/25 11:25:41 AM
Average length: 80      Median: 75      Shortest: 24    Longest: 167
Longest name:   D:\\Users\\Schvenn\\...\\In the Midst of Civilized Europe꞉ The Pogroms of 1918-1921 & the Onset of the Holocaust

Do you want to view the entire contents of the file? (y/n):

As you can see above, you get file details; file size, number of entries and last refresh date, as well as entry information, average and median length of folder names, shortest and longest folder name, as well as the actual longest folder name.

The non-English entries table and count helps you to find folder names that may have non-standard characters, such as diacritics. I have excluded only a few: ꞉“”. Those may look like a colon and standard quotation characters, but they are not. Many multimedia files use those characters in order to enable more convenient file naming for values that would otherwise be considered reserved characters.

-------------------------------------------------------------------
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
"@ -ForegroundColor White}
'9' {clear-host; tableofcontents; Write-Host @"
Installation:

Simply copy the Navigation Module folder contained in the installation package to your PowerShell Modules path.
I also recommend adding the following lines into your PowerShell profile, usually called: Microsoft.PowerShell_profile.ps1

	impo Navigation

At the bottom of the profile, after all other entries, you can also add the following line in order to initialize any immediate navigation directories you have saved at the start of every session:

	locations

-------------------------------------------------------------------

This package includes the following files:

License.txt 			- Legal declaration of MIT license.
Read.me				- Text version of this help .
Navigation.psm1			- The main module.
Navigation.psd1			- The standard PowerShell module manifest. I keep this separate for safety's sake.
Navigation.Configuration.psd1	- Configuration file that you customize. This is the only file you should need to manually adjust.

Additional files will be populated the first time you use specific features:

FolderCache.json 		- The cache created by the AutoComplete function, also used by the Goto function for fast navigation.
Bookmarks.log 			- A list of all folder booksmarks you've created for fast navigation.
Locations.log 			- A list of all the immediate navigation directories you have saved.
History.log 			- A list of the most recent directories you have navigated to using Goto functionality, also used by the Recents function for quick return.
"@ -ForegroundColor White}
'10' {clear-host; tableofcontents; Write-Host @"
Configuration:

Once you have the package installed, you will need to modify the Navigation.Configuration.psd1 file.
Simply open it in any text editor like Notepad and edit the fields to meet your needs:

@{GotoLogPath = "History.log"
GotoCachePath = "FolderCache.json"
GotoSearchRoots = @("C:\Users","D:\Users","E:")
GotoSearchExclusions = @("`$RECYCLE.BIN","RecycleBin")
GotoCacheMaxAge = 5
GotoCacheMaxMatches = 10
RecursionDepth = 6
GotoCacheSize = 25
BookmarkFilePath = "Bookmarks.log"
LocationsPath = "Locations.log"}

The filenames won't likely need to be renamed, unless you're particularly fussy.

You might want to add or change the GotoSearchRoots in order to define what drives and root pathways you'd like the folder cache to contain. Keep in mind that the more directories you add, the harder it will be to narrow in on your desired location with autocompletion. If you have many directories of the same or similar names in a particular path, this may also make it more difficult to find them, unless you limit your search roots appropriately. You can add and remove entries here. There is no set number.

The GotoCacheMaxAge tells the module how often to refresh the directory listing. Since it takes a few minutes to find all folders and create the cache and since your computer's entire directory structure is not something that would likely change dramatically from day to day, a larger number is likely sufficient. This is measured in days and the default is set to 5.

RecursionDepth can greatly impact performance and effective searches, as well. This number denotes how many directories deep the functions should search, as well as how big the cache should be. I wouldn't recommend going much deeper than 6 and for most people, 4 is likely a better number; striking the balance between performance and completeness.

GotoCacheSize sets the number of recent directory hops to keep in the history. This is used by the Recent(s) functionality.
"@ -ForegroundColor White}
'11' {clear-host; tableofcontents; Write-Host @"
Disclaimer:

Use at your own risk. There is no warranty of any kind, implied or otherwise. I know of nothing here that could possibly cause any disruption, but I'm not going to be held liable for any use or misuse of this package.

This software and the authour are not affliated with any organization. I made this package for my personal use, but feel like it could be useful to others, so I'm sharing it. Do not abuse it.
"@ -ForegroundColor White}
'q'  {clear-host}
default {clear-host; tableofcontents; Write-Host "`nInvalid option. Try again." -ForegroundColor Red}}} while ($choice.ToLower() -ne 'q'), ""}

# ----------------------------------------------------------------------------------
#									locations function
# ----------------------------------------------------------------------------------

$LocationsPath = $script:LocationsPath

function getlocations {# (Internal) Display all active locations paths.
""; Get-Command -Type Function | Where-Object {($_.Definition -match '^Set-Location') -and ($_.Name -notmatch '^(.:|cd..?)$')} | ForEach-Object {Write-Host -ForegroundColor Cyan $_.Name}; ""}

function locations ($Path) {# Creates functions for easy navigation to specific paths.

# Load locations file.
if (!$Path) {Write-Host -ForegroundColor Cyan "`nDefault locations set:"; Get-Content $LocationsPath | ForEach-Object {$line=$_.Trim();if($line){$expanded=$ExecutionContext.InvokeCommand.ExpandString($line);if(Test-Path $expanded){$full=(Resolve-Path -LiteralPath $expanded).Path; $leaf=(Split-Path $full -Leaf).ToLower();$funcBody="`nfunction global:$leaf {Set-Location `"$full`"}";Invoke-Expression $funcBody;Write-Host "$leaf -> $full"}else{Write-Host -ForegroundColor DarkGray "Skipped missing path: $expanded"}}};""}

# Provide valid options
elseif ($Path -match "(?i)^help$") {Write-Host -ForegroundColor Cyan "`nValid options:"; Write-host -ForegroundColor Yellow "this/current" -NoNewLine; Write-host -ForegroundColor White " - add the current directory path, for this session only"; Write-host -ForegroundColor Yellow "valid path" -NoNewLine; Write-host -ForegroundColor White " - any valid directory path; for this session only"; Write-host -ForegroundColor Yellow "add" -NoNewLine; Write-host -ForegroundColor White " - add an entry to the file"; Write-host -ForegroundColor Yellow "remove" -NoNewLine; Write-host -ForegroundColor White " - select an entry to delete from the file"; Write-host -ForegroundColor Yellow "expunge" -NoNewLine; Write-host -ForegroundColor White " - delete all locations saved in the file"; Write-host -ForegroundColor Yellow "get" -NoNewLine; Write-host -ForegroundColor White " - show all currently created location shortcuts"; Write-host -ForegroundColor Yellow "file" -NoNewLine; Write-host -ForegroundColor White " - entries in the file`n"}

# Add the current directory for this session only.
elseif ($Path -match "(?i)^(this|current)$") {$full=(Get-Location).Path; $leaf=(Split-Path $full -Leaf).ToLower();$funcBody="function global:$leaf {Set-Location `"$full`"}"; Invoke-Expression $funcBody; Write-Host -ForegroundColor Yellow "`nAlias '$leaf' created for '$full'"; getlocations}

# Add a new destination to the file.
elseif ($Path -match "(?i)^add$") {$current=(Get-Location).Path; $newPath=Read-Host "Enter the full path to add [`"$current`"]"; if (!$newPath) {$newPath=$current}; $expanded=$ExecutionContext.InvokeCommand.ExpandString($newPath); if (Test-Path $expanded) {$full=((Resolve-Path -LiteralPath $expanded).Path).ToLower(); $leaf=(Split-Path $full -Leaf).ToLower(); $funcBody="function global:$leaf {Set-Location `"$full`"}"; Invoke-Expression $funcBody; $existing=Get-Content $LocationsPath -ErrorAction SilentlyContinue; if($existing -contains $full) {Write-Host -ForegroundColor Cyan "`nAlias '$leaf' already exists for '$full'`n"} else {Add-Content -Path $LocationsPath -Value $full; Write-Host -ForegroundColor Yellow "`nAlias '$leaf' created and saved for '$full'`n"}; GC $LocationsPath;""} else {Write-Host -ForegroundColor Red "`nInvalid path entered: $expanded`n"}}

# Delete an alias created during this session.
elseif ($Path -match "(?i)^del(ete)?$") {""; $funcs=(Get-Command -Type Function | Where-Object {($_.Definition -match '^Set-Location') -and ($_.Name -notmatch '^(.:|cd..?)$')}); if(-not $funcs) {Write-Host -ForegroundColor Red "`nNo session aliases to delete.`n"; return}; $funcs|ForEach-Object -Begin{$i=1}-Process {Write-Host -NoNewline -ForegroundColor Cyan "$i. "; Write-Host -ForegroundColor White $_.Name; $i++}; $choice=Read-Host "`nEnter the number of the alias to delete"; if ($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $funcs.Count) {$target=$funcs[$choice-1].Name; Remove-Item "function:$target" -Force -ErrorAction SilentlyContinue; Remove-Item "function:global:$target" -Force -ErrorAction SilentlyContinue; Write-Host -ForegroundColor Yellow "`nAlias '$target' removed from session.`n"} else {Write-Host -ForegroundColor Red "`nInvalid selection.`n"}}

# Remove an entry from the file.
elseif ($Path -match "(?i)^rem(ove)?$") {$entries=Get-Content $LocationsPath;if(-not $entries){Write-Host -ForegroundColor Red "`nNo entries to remove.`n";return};$invalid=$entries|Where-Object{!(Test-Path ($ExecutionContext.InvokeCommand.ExpandString($_)))};if($invalid){Write-Host "`nThe following paths no longer exist:`n";$invalid|ForEach-Object{Write-Host -ForegroundColor DarkGray $_};$prune=Read-Host "`nRemove these from the list? (y/n)";if($prune -match '^(y|yes)$'){$entries=$entries|Where-Object {$_ -notin $invalid};Set-Content -Path $LocationsPath -Value $entries;Write-Host -ForegroundColor Yellow "`nRemoved invalid paths.`n"}};$entries|ForEach-Object -Begin{$i=1}-Process{Write-Host "$i. $_";$i++};$choice=Read-Host "`nEnter the number of the path to remove";if($choice -match '^\d+$' -and $choice -gt 0 -and $choice -le $entries.Count){$updated=$entries|Where-Object {$_ -ne $entries[$choice-1]};Set-Content -Path $LocationsPath -Value $updated;Write-Host -ForegroundColor Yellow "`nRemoved entry: $($entries[$choice-1])`n"}else{Write-Host -ForegroundColor Red "`nInvalid selection.`n"}}

# Remove all entries from the file.
elseif ($Path -match "(?i)^expunge$") {""; GC $LocationsPath; ""; Write-Host -ForegroundColor Red -NoNewLine "Are you sure you want to delete all entries in the locations file? "; $confirm=Read-Host "(y/n)"; if($confirm -match '^(y|yes)$'){Clear-Content $LocationsPath; Write-Host -ForegroundColor Red "`nAll entries removed from locations file.`n"} else{Write-Host -ForegroundColor DarkGray "`nExpunge cancelled.`n"}}

# List all entries that exist in the file.
elseif ($Path -match "(?i)^(file|default)$") {""; Get-Content $LocationsPath | ForEach-Object {if ($_ -match '\S') {$expanded=$ExecutionContext.InvokeCommand.ExpandString($_.Trim());$color=if(Test-Path $expanded){'White'}else{'DarkGray'};Write-Host -ForegroundColor $color "$_$(if($color -eq 'DarkGray'){' (missing)'})"}}; ""}

# List all entries that have been created this session.
elseif ($Path -match "(?i)^(get|list)$") {getlocations}

# Add the path indicated to the current session.
elseif (Test-Path $Path) {$full=(Resolve-Path -LiteralPath $Path).Path; $leaf=(Split-Path $full -Leaf).ToLower();$funcBody="function global:$leaf {Set-Location `"$full`"}";Invoke-Expression $funcBody;Write-Host -ForegroundColor Yellow "`nAlias '$leaf' created for '$full'"; getlocations}

# Error capture for invalid paths.
else {Write-Host -ForegroundColor Red "`nInvalid path: $Path`n"}}
sal -name locations -value location

# ----------------------------------------------------------------------------------
#									bookmark function
# ----------------------------------------------------------------------------------

$BookmarkFilePath = $script:BookmarkFilePath 

function bookmark ($mode) {# Use saved bookmarks to navigate or remove entries
Write-Host -ForegroundColor yellow "`n-------------------------------------------------------------------`n`t`t`tBookmarks:`n-------------------------------------------------------------------"

# Validate input.
if (($mode) -and ($mode -notmatch "(?i)^(list|get|add|this|current|just(explorer?)?|expunge|rem(ove)?|explorer?)$")) {Write-Host -ForegroundColor cyan -NoNewLine "`nInvalid option.`nValid options: "; Write-Host -ForegroundColor yellow "add/this/expunge/remove/explorer/justexplorer`n";return}

# Check if bookmarks file exists and has content.
if (!(Test-Path $BookmarkFilePath) -or !(Get-Content $BookmarkFilePath | Where-Object {$_ -match '\S'})) {Write-Host -ForegroundColor red "No bookmarks available.`n"; return}

# List entries.
if ($mode -match "(?i)^(list|get)$") {Write-Host -ForegroundColor cyan "`nSaved bookmarks:`n"; Get-Content $BookmarkFilePath; Write-Host ""; return}

# Add an entry.
if ($mode -match "(?i)^add(new)?$") {$response=(Read-Host "`nPath").trim(); if (!(Test-Path $response)) {Write-Host -ForegroundColor red "Path does not exist.`n"; return}; $resolved=(Get-Item $response).FullName; if ((Get-Content $BookmarkFilePath) -notcontains $resolved) {Add-Content $BookmarkFilePath $resolved; Write-Host -ForegroundColor green "`nAdded: $resolved"; gc $BookmarkFilePath} else {Write-Host -ForegroundColor yellow "`n$resolved already exists."}; ""; return}

# Add current.
if ($mode -match "(?i)^(current|this)$") {$this=(Get-Location).Path; if (!(Get-Content $BookmarkFilePath | Select-String -SimpleMatch $this)) {Add-Content $BookmarkFilePath $this; Write-Host -ForegroundColor green "`n$this added."}; gc $BookmarkFilePath; ""; return}

# Clear the bookmarks.
if ($mode -match "(?i)^expunge$") {""; Get-Content $BookmarkFilePath | Select-Object -Unique; ""; font red; [string]$confirm = Read-Host "Are you sure you want to clear all bookmarks? (y/n)"; font white; if ($confirm -ne 'y') {Write-Host -ForegroundColor yellow "Canceled.`n"; return}; Clear-Content $BookmarkFilePath; Write-Host -ForegroundColor green "Bookmarks cleared.`n"; return}

# Load and filter unique bookmarks.
$lines = Get-Content $BookmarkFilePath | Select-Object -Unique; $validity=@(); Write-Host -ForegroundColor cyan "`nSaved bookmarks:`n"; for ($i=0; $i -lt $lines.Count; $i++) {$exists=Test-Path $lines[$i]; $validity+=$exists; $color = if ($exists) {'white'} else {'darkgray'}; Write-Host -ForegroundColor cyan -NoNewLine "$($i+1):"; Write-Host -ForegroundColor $color (" $($lines[$i])" + ($(if(-not $exists){" (missing)"} else{""})))}

# If in remove mode, offer to delete non-existent paths.
if ($mode -match "(?i)^rem(ove)?$") {if ($validity -contains $false) {$nonexistent = @(); for ($i=0; $i -lt $lines.Count; $i++) {if (-not $validity[$i]) {$nonexistent += $lines[$i]}} 
$response = Read-Host "`nRemove all non-existent entries? (y/n)"; if ($response -match '^[Yy]$') {$lines = $lines | Where-Object {Test-Path $_}; Set-Content -Path $BookmarkFilePath -Value $lines}}
[int]$selection = Read-Host "`nSelect a bookmark to remove by number, 1 to $($lines.Count)"; if ($selection -lt 1 -or $selection -gt $lines.Count) {Write-Host -ForegroundColor red "Invalid entry. Exiting.`n"; return}; $lines = $lines | Where-Object {$_ -ne $lines[$selection - 1]}; Set-Content -Path $BookmarkFilePath -Value $lines; Write-Host -ForegroundColor green "Bookmark removed.`n"; return}

# Ask for selection to navigate to.
[int]$selection = Read-Host "`nSelect a location by number, 1 to $($lines.Count)"; if ($selection -lt 1 -or $selection -gt $lines.Count) {Write-Host -ForegroundColor red "Invalid entry. Exiting.`n"; return}; $destination = $lines[$selection - 1]; if (!(Test-Path $destination)) {Write-Host -ForegroundColor red "Selected path does not exist.`n"; return}; if ($mode -notmatch "(?i)^just(explorer?)?$") {sl $destination}; if($mode -match "(?i)^(just(explorer?)?|explorer?)$") {Start-Process explorer.exe $destination}; ""; return}
sal -name bookmarks -value bookmark

# ----------------------------------------------------------------------------------
#									goto function
# ----------------------------------------------------------------------------------

$GotoSearchRoots = $script:GotoSearchRoots; $GotoCacheMaxAge = $script:GotoCacheMaxAge; $script:GotoCacheMaxMatches; $RecursionDepth = $script:RecursionDepth; $GotoCacheSize = $script:GotoCacheSize


function goto ($location,$explorer) {# Custom-recursive directory search, case-insensitive, with autocomplete, history and max depth.
$originalLocation = $Location.ToLowerInvariant(); $matches = @(); $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Iterate through all entries in the cache and filter early
$matches = $GotoFolders | Where-Object {$leaf = ($_ -split '\\')[-1].ToLowerInvariant(); $leaf -like "*$($originalLocation)*"} | ForEach-Object {[PSCustomObject]@{Path = $_; Rel  = $_.Substring($_.IndexOf($root) + $root.Length + 1)}}

# Provide performance feedback
$stopwatch.Stop(); if ($stopwatch.Elapsed.TotalSeconds -gt 0) {Write-Host -ForegroundColor green -NoNewLine "`nThis search took "; Write-Host -ForegroundColor red -NoNewLine ("{0:N3}" -f $stopwatch.Elapsed.TotalSeconds); Write-Host -ForegroundColor green " seconds to complete."}

# If there are more than the set number of matches, attempt to limit to first 4 directory levels.
if ($matches.Count -gt $GotoCacheMaxMatches) {$earlyMatches = $matches | Where-Object {($_.Rel -split '\\').Count -le 4}
if ($earlyMatches.Count -le $GotoCacheMaxMatches) {$matches = $earlyMatches}
else {Write-Host -ForegroundColor cyan -NoNewLine "There are "; Write-Host -ForegroundColor red -NoNewLine "$($matches.Count)"; Write-Host -ForegroundColor cyan -NoNewLine " options matching the pattern `""; Write-Host -ForegroundColor red -NoNewLine "`*$originalLocation`*"; Write-Host -ForegroundColor cyan "`" as a parent directory. Please refine your search.`n"; return}}

# Provide options if more than one match exists.
if ($matches.Count -gt 1) {write-host -ForegroundColor cyan "Multiple matches found:`n"; for ($i = 0; $i -lt $matches.Count; $i++) {write-host -ForegroundColor cyan -NoNewLine "$($i + 1):"; Write-Host -ForegroundColor white " $($matches[$i].Rel)"}; [int]$selection = Read-Host "`nSelect a location by number, 1 to $($matches.Count)";  if ($selection -lt 1 -or $selection -gt $matches.Count) {Write-Host -ForegroundColor red "Invalid entry. Exiting.`n"; break} else {$match = $matches[$selection - 1]}}

# Set the option if only one match exists.
elseif ($matches.Count -eq 1) {$match = $matches[0]}

# Return an error if no match exists.
else {Write-Host -ForegroundColor cyan -NoNewLine "A `""; Write-Host -ForegroundColor red -NoNewLine "*$originalLocation*"; Write-Host -ForegroundColor cyan -NoNewLine "`" directory pattern cannot be found under parent paths: "; for ($i = 0; $i -lt $GotoSearchRoots.Count; $i++) {Write-Host -NoNewLine -ForegroundColor yellow $GotoSearchRoots[$i]; if ($i -lt $GotoSearchRoots.Count - 1) {Write-Host -NoNewLine -ForegroundColor cyan ", "}}; Write-Host -ForegroundColor cyan ".`n"; return}

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

# Validate input.
if (($mode) -and ($mode -notmatch "(?i)^(list|get|clear|rem(ove)?|explorer?)$")) {Write-Host -ForegroundColor yellow -NoNewLine "`nInvalid option.`nValid options: "; Write-Host -ForegroundColor cyan "list/clear/remove/explorer`n";return}

# Check if previous selections file exists and has content.
if (!(Test-Path $GotoLogPath) -or !(Get-Content $GotoLogPath | Where-Object {$_ -match '\S'})) {Write-Host -ForegroundColor yellow "No previous selection is available.`n"; return}

# List entries.
if ($mode -match "(?i)^(list|get)$") {Write-Host -ForegroundColor cyan "`nPreviously selected locations:`n"; Get-Content $GotoLogPath; Write-Host ""; return}

# Clear the logs.
if ($mode -match "(?i)^clear$") {""; Get-Content $GotoLogPath | Select-Object -Unique; ""; [string]$confirm = Read-Host "Are you sure you want to clear all saved selections? (y/n)"; if ($confirm -ne 'y') {Write-Host -ForegroundColor yellow "Canceled.`n"; return}; Clear-Content $GotoLogPath; Write-Host -ForegroundColor green "Last selections cleared.`n"; return}

# Load and filter unique selections.
$lines = Get-Content $GotoLogPath | Select-Object -Unique; $validity=@(); Write-Host -ForegroundColor cyan "`nPreviously selected locations:`n"; for ($i=0; $i -lt $lines.Count; $i++) {$exists=Test-Path $lines[$i]; $validity+=$exists; $color = if ($exists) {'white'} else {'darkgray'}; Write-Host -ForegroundColor cyan -NoNewLine "$($i+1):"; Write-Host -ForegroundColor $color (" $($lines[$i])" + ($(if(-not $exists){" (missing)"} else{""})))}

# If in remove mode, offer to delete non-existent paths.
if ($mode -match "(?i)^rem(ove)?$") {if ($validity -contains $false) {$nonexistent = @(); for ($i=0; $i -lt $lines.Count; $i++) {if (-not $validity[$i]) {$nonexistent += $lines[$i]}} 
$response = Read-Host "`nRemove all non-existent entries? (y/n)"; if ($response -match '^[Yy]$') {$lines = $lines | Where-Object {Test-Path $_}; Set-Content -Path $GotoLogPath -Value $lines}}
[int]$selection = Read-Host "`nSelect an entry to remove by number, 1 to $($lines.Count)"; if ($selection -lt 1 -or $selection -gt $lines.Count) {Write-Host -ForegroundColor red "Invalid entry. Exiting.`n"; return}; $lines = $lines | Where-Object {$_ -ne $lines[$selection - 1]}; Set-Content -Path $GotoLogPath -Value $lines; Write-Host -ForegroundColor green "Entry removed.`n"; return}

# Ask for selection to navigate to.
[int]$selection = Read-Host "`nSelect a location by number, 1 to $($lines.Count)"; if ($selection -lt 1 -or $selection -gt $lines.Count) {Write-Host -ForegroundColor red "Invalid entry. Exiting.`n"; return}; $destination = $lines[$selection - 1]; if (!(Test-Path $destination)) {Write-Host -ForegroundColor red "Selected path does not exist."; return}; sl $destination; if($mode -match "(?i)^explorer?$") {Start-Process explorer.exe $destination}; return}
sal -name recents -value recent

# ----------------------------------------------------------------------------------
#									autocomplete cache
# ----------------------------------------------------------------------------------

$GotoCachePath = $script:GotoCachePath; $GotoSearchExclusions = $script:GotoSearchExclusions;

function Get-GotoCache {if (Test-Path $GotoCachePath) {try {return Get-Content $GotoCachePath -Raw | ConvertFrom-Json} catch {return @()}} return @()}

function Start-GotoCacheRefreshJob {Start-Job -ScriptBlock {try {Write-Host -ForegroundColor Yellow "`nCache refresh job started."; $folders = foreach ($root in $using:GotoSearchRoots) {Write-Host "`nSearching: $root " -NoNewLine; $collected = @($root)

# Recursively get subdirectories up to max depth
$subdirs = Get-ChildItem -Path $root -Recurse -Directory -Force -ErrorAction SilentlyContinue | Where-Object {($_.FullName.Substring($root.Length+1)).Split('\').Count -le $using:RecursionDepth}

# Filter exclusions and build list
$collected += $subdirs | ForEach-Object {try {$folderName = $_.Name; if ($using:GotoSearchExclusions -contains $folderName.Substring(0, [Math]::Min($folderName.Length, 12))) {Write-Host  -ForegroundColor Red "Excluding: $($_.FullName) " -NoNewLine} else {$_.FullName}} catch {Write-Host -ForegroundColor Red "." -NoNewLine}}; $collected}

$folders = $folders | Sort-Object -Unique; Write-Host "`nFolders found: $($folders.Count)" -ForegroundColor Green; $folders | ConvertTo-Json | Set-Content -Encoding UTF8 $using:GotoCachePath; Write-Host -ForegroundColor Green "Cache file updated: " -NoNewLine; Write-Host -ForegroundColor Yellow "$using:GotoCachePath`n"} catch {Write-Host -ForegroundColor Red "Error during cache refresh: $_"}} | Out-Null; ""}

# Check cache freshness
$refreshNeeded = $true; if (Test-Path $GotoCachePath) {$lastWrite = (Get-Item $GotoCachePath).LastWriteTime; if (((Get-Date) - $lastWrite).TotalMinutes -lt $GotoCacheMaxAge) {$refreshNeeded = $false}}

# Start refresh if needed
if ($refreshNeeded) {Start-GotoCacheRefreshJob}

# Load existing cache into memory
$Global:GotoFolders = Get-GotoCache

# Register autocompletion
Register-ArgumentCompleter -CommandName goto -ParameterName location -ScriptBlock {param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters); $Global:GotoFolders | Where-Object {$_ -like "*$wordToComplete*"} | Sort-Object -Unique | ForEach-Object {[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)}}

# ----------------------------------------------------------------------------------
#									view goto folder cache
# ----------------------------------------------------------------------------------

function viewgotocache ($refresh) {# View details about the Goto folder cache.
$columnWidth = 40; $columnIndex = 0; $entryLengths = @(); $longestLine = ""; $longestLength = 0

# Force a refresh
if ($refresh -match "(?i)^re(create|fresh)$") {Start-GotoCacheRefreshJob; return}

# Calculations and evaluations.
gc $GotoCachePath | % {$cleanEntry = $_ -replace '[",\[\]]',''; if ($cleanEntry) {$entryLengths += $cleanEntry.Length}}; $fileInfo = gi $GotoCachePath; $totalEntries = $entryLengths.Count; $averageLength = [math]::Round(($entryLengths | Measure-Object -Average).Average, 1); $medianLength = [math]::Round(($entryLengths | Sort-Object | Select-Object -Skip ([math]::Floor(($entryLengths.Count-1)/2)) -First 1), 1); $shortestLength = ($entryLengths | Measure-Object -Minimum).Minimum; $longestLength = ($entryLengths | Measure-Object -Maximum).Maximum; $fileSize = "{0:N0}" -f $fileInfo.Length; $lastModified = $fileInfo.LastWriteTime; $nonEnglishEntries = @(); gc $GotoCachePath | % {$entry = $_ -replace '[",\[\]]',''; if ($entry -match '[^\x00-\x7F]' -and $entry -notmatch '[꞉“”]' -and $entry) {$nonEnglishEntries += $entry}}

# Display non-English table.
Write-Host -ForegroundColor Cyan "`nGotoCache: " -NoNewLine; Write-Host -ForegroundColor Yellow $GotoCachePath; if ($nonEnglishEntries.Count -gt 0) {Write-Host -ForegroundColor Yellow "`n"$nonEnglishEntries.Count -NoNewLine; Write-Host " Non-English Entries:`n--------------------------`n" -ForegroundColor Cyan; $columnIndex = 0; $nonEnglishEntries | % {$displayEntry = $_.Substring(0, [Math]::Min($columnWidth, $_.Length)); if ($displayEntry.Length -gt $columnWidth) {$displayEntry += '...'}; $columnIndex++; if ($columnIndex % 4 -ne 3) {Write-Host ("{0,-$columnWidth}" -f $displayEntry) -NoNewline} else {Write-Host $displayEntry}}; ""}

# Display stats table.
Write-Host "`nFile size: " -ForegroundColor Cyan -NoNewline; Write-Host "$fileSize bytes" -ForegroundColor Yellow -NoNewline; Write-Host "`tTotal entries: " -ForegroundColor Cyan -NoNewline; Write-Host $totalEntries -ForegroundColor Yellow -NoNewline; Write-Host "`tLast modified time: " -ForegroundColor Cyan -NoNewline; Write-Host $lastModified -ForegroundColor Yellow; Write-Host "Average length: " -ForegroundColor Cyan -NoNewline; Write-Host $averageLength -ForegroundColor Yellow -NoNewline; Write-Host "`tMedian: " -ForegroundColor Cyan -NoNewline; Write-Host $medianLength -ForegroundColor Yellow -NoNewline; Write-Host "`tShortest: " -ForegroundColor Cyan -NoNewline; Write-Host $shortestLength -ForegroundColor Yellow -NoNewLine; Write-Host "`tLongest: " -ForegroundColor Cyan -NoNewline; Write-Host $longestLength" " -ForegroundColor Yellow; Write-Host "Longest name: " -ForegroundColor Cyan -NoNewline; gc $GotoCachePath | ForEach-Object {if ($_ -and $_.Length -gt $longestLength) {$longestLength = $_.Length; $longestLine = $_ -replace '[",\[\]]',''}}; Write-Host $longestLine; ""

# Prompt to display entire file.
$viewAll = Read-Host -Prompt "`e[36mDo you want to view the entire contents of the file? (y/n)`e[0m"; if ($viewAll -match '^(?i)y') {""; $columnIndex = 0; gc $GotoCachePath | % {$cleanEntry = $_ -replace '[",\[\]]',''; if ($cleanEntry.Length -gt $columnWidth) {$cleanEntry = $cleanEntry.Substring(0,$columnWidth-3) + '...'}; if ($columnIndex++ % 4 -ne 3) {Write-Host ("{0,-$columnWidth}" -f $cleanEntry) -NoNewline} else {Write-Host $cleanEntry}}}; ""}
sal -name gotocache -value viewgotocache

# ----------------------------------------------------------------------------------
#									Define External Availability
# ----------------------------------------------------------------------------------

Export-ModuleMember -Function navigation,bookmark,locations,goto,recent,viewgotocache -Alias bookmarks,recents,jumpto,gotocache

Write-Host -ForegroundColor Yellow "`nType `"Navigation`" at the command prompt to open the help file for this module and all of its features. "; Write-Host -ForegroundColor Cyan "Copyright © 2025 Craig Plath"
