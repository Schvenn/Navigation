@{RootModule = 'Navigation.psm1'
ModuleVersion = '1.3'
GUID = 'd2191924-feb7-4147-92bd-97c4283d11d4'
Author = 'Craig Plath'
CompanyName = 'Plath Consulting Incorporated'
Copyright = '© Craig Plath. All rights reserved.'
Description = 'PowerShell module to enhance CLI navigation with bookmarks, history, autocompletion and more.'
PowerShellVersion = '5.1'
FunctionsToExport = @('navigation', 'bookmark', 'locations', 'goto', 'recent', 'viewgotocache')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @('bookmarks', 'gotocache', 'jumpto', 'location', 'recents', 'speedial', 'speeddials')
FileList = @('Navigation.psm1')

PrivateData = @{PSData = @{Tags = @('navigation', 'bookmark', 'personalization', 'powershell', 'cache')
LicenseUri = 'https://github.com/Schvenn/Navigation/blob/main/LICENSE'
ProjectUri = 'https://github.com/Schvenn/Navigation'
ReleaseNotes = 'Improved help.'}

RecursionDepth = '4'
GotoCacheMaxAge = '5'
LocationsPath = 'Locations.log'
GotoSearchExclusions = '`$RECYCLE.BIN', 'RecycleBin'
GotoCacheMaxMatches = '10'
BookmarkFilePath = 'Bookmarks.log'
GotoSearchRoots = 'C:\Users', 'D:\Users', 'E:'
GotoLogPath = 'History.log'
GotoCacheSize = '25'
GotoCachePath = 'FolderCache.json.gz'}}
