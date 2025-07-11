@{ModuleVersion = '1.3'
RootModule = 'Navigation.psm1'

PrivateData = @{GotoLogPath = "History.log"
GotoCachePath = "FolderCache.json.gz"
GotoSearchRoots = @("C:\Users","D:\Users","E:")
GotoSearchExclusions = @("`$RECYCLE.BIN","RecycleBin")
GotoCacheMaxAge = 5
GotoCacheMaxMatches = 10
RecursionDepth = 4
GotoCacheSize = 25
BookmarkFilePath = "Bookmarks.log"
LocationsPath = "Locations.log"}}
