# Declare/set all script variables
# Create Timestamp
$TimeStamp = Get-Date -Format 'hh-mm-ss'
$Date = Get-Date -Format 'dd.MM.yyyy'

# Query PMS default Locations
$PlexUninstallPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$PlexUninstallKey = Get-ChildItem -Path $PlexUninstallPaths -ErrorAction SilentlyContinue |
Get-ItemProperty -ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -match 'Plex Media Server' }

$global:InstallLocation = $PlexUninstallKey.InstallLocation
$global:PlexData = "$env:LOCALAPPDATA\Plex Media Server\Plug-in Support\Databases"
$global:PlexDBPrefix = "com.plexapp.plugins.library"
$global:PlexDBFileExtensions = @('db', 'db-wal', 'db-shm', 'blobs.db', 'blobs.db-wal', 'blobs.db-shm')
$global:PlexSQL = $InstallLocation + 'Plex SQLite.exe'
$global:DBtmp = "$PlexData\dbtmp"
$global:TmpFile = "$DBtmp\results.tmp"
$global:PMSservice = 'Plex Media Server'
$global:PlexDBDamaged = $false
$global:PlexDBChecked = $false

# Check if Logfile is present, if not - create it.
if (!(Test-Path "$PlexData\PlexDBRepair.log")){
    New-Item -Path "$PlexData\PlexDBRepair.log" -Force -ErrorAction SilentlyContinue | Out-Null
}

function WriteOutput($Message, $Type) {
    $TimeStamp = (Get-Date -Format 'hh:mm:ss tt')
    $Color = 'White'
    switch ($Type) {
        'Error' {
            $output = " [Error] -- $Message"
            $Color = 'Red'
        }
        'Warning' {
            $output = " [Warning] -- $Message"
            $Color = 'Yellow'
        }
        'Information' {
            $output = " [Information] -- $Message"
        }
        Default {
            $output = " -- $Message"
        }
    }
    $output = ($TimeStamp + $output)
    Write-Host "     $output" -ForegroundColor $Color 
    $output | Out-File -FilePath "$PlexData\PlexDBRepair.log" -Append
}
function Write-MainMenu {
    Clear-Host
   
    $title = @"
   __________________________________________________________________________________________
    _    _      _                            _                                                 
   | |  | |    | |                          | |                                                
   | |  | | ___| | ___ ___  _ __ ___   ___  | |_ ___                                           
   | |/\| |/ _ \ |/ __/ _ \| '_ ` _ \ / _ \ | __/ _ \                                          
   \  /\  /  __/ | (_| (_) | | | | | |  __/ | || (_) |                                         
    \/  \/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/                                          
                                                                                               
                                                                                               
   ______ _          __________________                 _        _____  _     _____ _          
   | ___ \ |         |  _  \ ___ \ ___ \               (_)      /  __ \| |   |_   _| |         
   | |_/ / | _____  _| | | | |_/ / |_/ /___ _ __   __ _ _ _ __  | /  \/| |     | | | |         
   |  __/| |/ _ \ \/ / | | | ___ \    // _ \ '_ \ / _` | | '__| | |    | |     | | | |         
   | |   | |  __/>  <| |/ /| |_/ / |\ \  __/ |_) | (_| | | |    | \__/\| |_____| |_|_|         
   \_|   |_|\___/_/\_\___/ \____/\_| \_\___| .__/ \__,_|_|_|     \____/\_____/\___/(_)         
                                           | |                                                 
   ________________________________________|_|________________________________________________
"@
   
    Write-Host -ForegroundColor DarkYellow $title

    # while ($true) {
    $MenuOptions = @"
     1 - Stop      - Stop Plex Media Server.
     2 - Start     - Start Plex Media Server.
     3 - Automatic - Database check, repair/optimize, and reindex in one step.
     4 - Check     - Perform integrity check of database.
     5 - Vacuum    - Remove empty space from database.
     6 - Repair    - Repair/Optimize databases.
     7 - Reindex   - Rebuild database database indexes.
     8 - Import    - Import watch history from another database independent of Plex. (risky)
     9 - Replace   - Replace current databases with newest usable backup copy. (interactive)
    10 - Show      - Show logfile.
    11 - Status    - Report status of Plex Media Server. (run-state and databases)
    12 - Undo      - Undo last successful command.
    99 - Exit      - Exit this program.
"@
    Write-Host $MenuOptions
}
function Stop-PlexMediaServer {
    $PMSexe = Get-PlexProcess
    if ($PMSexe) {
        WriteOutput -Message 'Stopping Plex...'
        $null = $PMSexe | Stop-Process -Force
        Start-Sleep 5
        IncrementCompletedSteps
    }
    else {
        WriteOutput -Message 'Plex is not running.'
        IncrementCompletedSteps
    }
}
function Start-PlexMediaServer {
    $Executable = "$($InstallLocation)Plex Media Server.exe"
    if (Get-PlexProcess) {
        WriteOutput -Message 'Plex is already running.'
    }
    elseif (Test-Path -Path $Executable) {
        WriteOutput -Message 'Starting Plex...'
        & $Executable
    }
    else {
        WriteOutput -Message 'Cannot find Plex Media Server executable.'
    }
}
function Invoke-DirectorySwitch {
    # Switching to PlexData dir
    Set-Location $PlexData
    IncrementCompletedSteps
}
function Invoke-ProvisioningTmpFiles {
    # Creating Folder if not present
    if (!(Test-Path $DBtmp -ErrorAction SilentlyContinue)){
        New-Item -ItemType Directory "dbtmp"
    }
    # Deleteing tmp File if present
    if (Test-Path $TmpFile -ErrorAction SilentlyContinue){
        Remove-Item $TmpFile -Force -Confirm:$false
    }
    IncrementCompletedSteps
}
function Invoke-ExportDBs {
    WriteOutput "Exporting Main DB"

    # Execute the command
    try {
        Write-Output ".dump" | & $PlexSQL "$PlexData\com.plexapp.plugins.library.db" | Out-File "$DBtmp\library.sql_$TimeStamp"
    }
    catch {
        WriteOutput "ERROR:  Cannot export Main DB.  Aborting."
        pause
        Exit 1
    }

    WriteOutput "Exporting Blobs DB"

    # Execute the command
    try {
        Write-Output ".dump" | & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db" | Out-File "$DBtmp\blobs.sql_$TimeStamp"
    }
    catch {
        WriteOutput "ERROR:  Cannot export Blobs DB.  Aborting."
        pause
        Exit 1
    }

    WriteOutput "Exporting Complete..."
    IncrementCompletedSteps
}
function Invoke-CreateNewDBs {
    WriteOutput "Creating Main DB..."

    # Execute the command
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PlexSQL
        $psi.Arguments = "`"$PlexData\com.plexapp.plugins.library.db_$TimeStamp`""
        $psi.RedirectStandardInput = $true
        $psi.UseShellExecute = $false

        $process = [System.Diagnostics.Process]::Start($psi)
        (Get-Content "$DBtmp\library.sql_$TimeStamp") | ForEach-Object { $process.StandardInput.WriteLine($_) }
        $process.StandardInput.Close()
        $process.WaitForExit()
    }
    catch {
        WriteOutput "ERROR:  Cannot create Main DB.  Aborting."
        pause
        Exit 1
    }

    # Now Verify created DB
    WriteOutput "Verifying Main DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "PRAGMA integrity_check(1)"| Out-File $TmpFile
    }
    catch {
        WriteOutput "ERROR: Main DB verificaion failed. Exiting."
        pause
        Exit 1
    }

    if ((Get-Content $TmpFile) -ne 'ok'){
        WriteOutput "ERROR: Main DB verificaion failed. Exiting."
        pause
        Exit 1
    }
    Else {
        WriteOutput "Main DB verification successful..."
    }

    WriteOutput "Creating Blobs DB..."

    # Execute the command
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $PlexSQL
        $psi.Arguments = "`"$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp`""
        $psi.RedirectStandardInput = $true
        $psi.UseShellExecute = $false

        $process = [System.Diagnostics.Process]::Start($psi)
        (Get-Content "$DBtmp\blobs.sql_$TimeStamp") | ForEach-Object { $process.StandardInput.WriteLine($_) }
        $process.StandardInput.Close()
        $process.WaitForExit()
    }
    catch {
        WriteOutput "ERROR: Cannot create Blobs DB.  Aborting."
        pause
        Exit 1
    }

    # Now Verify created Blobs DB
    WriteOutput "Verifying Blobs DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "PRAGMA integrity_check(1)"| Out-File $TmpFile
    }
    catch {
        WriteOutput "ERROR: Blobs DB verificaion failed. Exiting."
        pause
        Exit 1
    }
    if ((Get-Content $TmpFile) -ne 'ok'){
        WriteOutput "ERROR: Blobs DB verificaion failed. Exiting."
        pause
        Exit 1
    }
    Else {
        WriteOutput "Blobs DB verification successful..."
        WriteOutput "Import and verification complete..."
    }
    IncrementCompletedSteps
}
function IncrementCompletedSteps {
    $global:CompletedSteps++
}
function GetCompletionPercentage {
    [math]::Round(($global:CompletedSteps / $TotalSteps) * 100)
}
function Automatic($serviceName) {
    $CompletedSteps = 0
    $TotalSteps = 7

    WriteOutput -Message "====== Session begins. ($Date) ======"

    Stop-PlexMediaServer
    Invoke-DirectorySwitch
    Invoke-ProvisioningTmpFiles
    Invoke-ExportDBs
    Invoke-CreateNewDBs
    Invoke-PlexDBReindex
    Invoke-PlexDBImport
    if (GetCompletionPercentage -eq '100'){
        WriteOutput -Message 'Starting Plex Media Server now...'
        Start-PlexMediaServer
        WriteOutput -Message '====== Session completed. ======'
    }
    Else {
        WriteOutput -Message 'Please check Logfile before starting Plex...'
        WriteOutput -Message "====== Not Completed - $(GetCompletionPercentage) %. ======" -Type Warning
    }
}
function Test-PlexDatabase ([string]$Path) {
    # Confirm the DB exists
    if (Test-Path $Path) {
        # Run integrity check on the database
        $Results = & $PlexSQL $Path 'PRAGMA integrity_check(1)'
        if ($Results -eq 'ok') {
            WriteOutput -Message "Check complete. $($Path | Split-Path -Leaf) is OK."
            return $true
        }
        else {
            WriteOutput -Message "Check complete. $($Path | Split-Path) is damaged."
            return $false
        }
    }
    else {
        WriteOutput -Message "$Path does not exist!"
        return $false
    }
}
function Invoke-PlexDBCheck([switch]$Force) {
    # Check integrity of the Plex databases.
    # If all pass, set the 'PlexDBChecked' flag
    # Only force recheck if flag given
    if ($Force.Present) {
        $global:PlexDBChecked = $false
    }
    if ($global:PlexDBChecked) {
        WriteOutput -Message 'Check already completed.'
        do {
            $response = (Read-Host 'Check again? - (Y)es/(N)o').Substring(0, 1).ToLower()
        } while ($response -notin ('y', 'n'))
        if ($response = 'y') {
            $global:PlexDBChecked = $false
        }
    }
    # Do we need to check
    if (-not($global:PlexDBChecked)) {
        # Clear flags
        $global:PlexDBDamaged = $false
        $global:PlexDBChecked = $false
        WriteOutput -Message 'Checking the PMS databases'
        # Check main database
        foreach ($database in ("$PlexData\$PlexDBPrefix.db", "$PlexData\$PlexDBPrefix.blobs.db")) {
            if (-not(Test-PlexDatabase -Path $database)) {
                $global:PlexDBDamaged = $true
            }
        }
        # Update checked flag
        $global:PlexDBChecked = $true
    }
}
function Test-FreeSpace {
    $TotalDatabaseSize = 0
    $FreeSpace = (Get-Volume (Split-Path -Path $env:LOCALAPPDATA -Qualifier).Replace(':', '')).SizeRemaining
    $PlexDBFileExtensions | ForEach-Object { $TotalDatabaseSize += (Get-Item -Path "$PlexData\$PlexDBPrefix.$_").Length }
    return ($FreeSpace -gt $TotalDatabaseSize)
}
function Invoke-PlexDBBackup {
    if (Test-FreeSpace) {
        WriteOutput -Message "Backup current databases with '-BACKUP-$TimeStamp' timestamp."
        $null = New-Item -Path $DBtmp -ItemType Directory -Force -ErrorAction SilentlyContinue
        $dbFiles = @('db', 'db-wal', 'db-shm', 'blobs.db', 'blobs.db-wal', 'blobs.db-shm')
        $dbFiles | ForEach-Object { Copy-Item -Path "$PlexData\$PlexDBPrefix.$_" -Destination "$DBtmp\$PlexDBPrefix.$_-BACKUP-$TimeStamp" }
    }
    else {
        throw 'Not enough free space left on drive!'
    }
}
function Invoke-RestoreFromBackup($T) {
    $fileNames = 'db', 'db-wal', 'db-shm', 'blobs.db', 'blobs.db-wal', 'blobs.db-shm'
    foreach ($i in $fileNames) {
        if (Test-Path "$PlexData\$PlexDBPrefix.$i") {
            Remove-Item "$PlexData\$PlexDBPrefix.$i" 
        }
        if (Test-Path "$DBtmp\$PlexDBPrefix.$i-BACKUP-$T") {
            Move-Item "$DBtmp\$PlexDBPrefix.$i-BACKUP-$T" "$PlexData\$PlexDBPrefix.$i" 
        }
    }
}
function Invoke-PlexDBVacuum {
    # Check databases before Vacuuming if not previously checked
    if (-not ($global:PlexDBChecked)) {
        Invoke-PlexDBCheck
    }
    # If damaged, exit
    if ($global:PlexDBDamaged) {
        WriteOutput -Message 'Databases are damaged. Vacuum operation not available. Please repair or replace first.' -Type Warning
        # Invoke-PlexDBRepair
        return 1
    }
    else {
        # Make a backup
        WriteOutput -Message 'Backing up databases'
        try {
            Invoke-PlexDBBackup
        }
        catch {
            WriteOutput -Message 'Backup creation failed. Cannot continue.' -Type Error
            throw
        }
    }
    # Start vacuuming
    foreach ($database in ("$PlexData\$PlexDBPrefix.db", "$PlexData\$PlexDBPrefix.blobs.db")) {
        $Result = $null
        $SizeStart = [math]::Round(((Get-Item -Path $database).Length / 1MB), 2)
        WriteOutput -Message "Vacuuming '$(Split-Path $database -Leaf)'..."
        $Result = & "$PlexSQL" $database 'VACUUM;' # This doesn't seem to produce any output unless there is an error. ???
        if ($Result) {
            WriteOutput -Message "Vaccuming '$(Split-Path $database -Leaf)' failed. Error code $Result from Plex SQLite" -Type Error
            #Invoke-RestoreFromBackup "$TimeStamp"
        }
        else {
            $SizeFinish = [math]::Round(((Get-Item -Path $database).Length / 1MB), 2)
            WriteOutput -Message "'$(Split-Path $database -Leaf)' - Vacuum complete."
            WriteOutput -Message "Starting size: $($SizeStart)MB"
            WriteOutput -Message "Size now:      $($SizeFinish)MB."
            #SetLast 'Vacuum' "$TimeStamp"
        }
    }
}
function Invoke-PlexDBRepair ([string]$Path) {
    # If the databases haven't been checked, run the check
    if (-not($global:PlexDBChecked)) {
        Invoke-PlexDBCheck
    }
    if ($global:PlexDBDamaged) {
        # Backup databases before running the compare
        try {
            Invoke-PlexDBBackup
        }
        catch {
            WriteOutput -Message "Could not backup databases. $_"
            break
        }
        Write-Host "Running repair on database $databaseName"
        # Repair code goes here
    }
    else {
        WriteOutput -Message 'Database not damaged. Repair not necessary.'
    }
}
function Invoke-PlexDBReindex {
    WriteOutput "Reindexing Main DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "REINDEX;"
    }
    catch {
        WriteOutput "ERROR: Main DB Reindex failed. Exiting."
        pause
        Exit 1
    }

    WriteOutput "Reindexing Blobs DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "REINDEX;"
    }
    catch {
        WriteOutput "ERROR: Blobs DB Reindex failed. Exiting."
        pause
        Exit 1
    }

    WriteOutput "Reindexing complete..."
    IncrementCompletedSteps
}
function Invoke-PlexDBImport {
    WriteOutput "Moving current DBs to DBTMP and making new databases active..."

    # Moving files

    Move-Item "$PlexData\com.plexapp.plugins.library.db" "$DBtmp\com.plexapp.plugins.library.db_$TimeStamp" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Move-Item "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "$PlexData\com.plexapp.plugins.library.db"-Force -Confirm:$false -ErrorAction SilentlyContinue

    Move-Item "$PlexData\com.plexapp.plugins.library.blobs.db" "$DBtmp\com.plexapp.plugins.library.blobs.db_$TimeStamp" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Move-Item "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "$PlexData\com.plexapp.plugins.library.blobs.db" -Force -Confirm:$false -ErrorAction SilentlyContinue
    IncrementCompletedSteps
}
function Invoke-PlexDBReplace {
    param (
        [string]$filePath,
        [string]$searchString,
        [string]$replaceString
    )
    # Placeholder function, replace with actual replace function code
    Write-Host "Replacing text in file $filePath"
}
function Get-LogFile {
    if (Test-Path "$PlexData\PlexDBRepair.log") {
        Get-Content -Path "$PlexData\PlexDBRepair.log"
    }
    else {
        Write-Host "     [Error] -- Cannot find '$PlexData\PlexDBRepair.log'" -ForegroundColor Red
    }
}
function Get-PlexProcess {
    Get-Process 'Plex Media Server' -ErrorAction SilentlyContinue
}
function Undo {
    # Placeholder function, replace with actual undo function code
    Write-Host 'Undoing last action'
}

if ($InstallLocation -and (Test-Path "$PlexData\$PlexDBPrefix.db")) {
    # Let's begin
    do {
        Write-MainMenu
        $selection = Read-Host 'Enter a command #'
        Clear-Host
        # Test to see if the selection is a database function and if Plex is running.
        # If both are true, set the selection to 13, which will inform the user to stop Plex.
        if (($selection -in 3..9) -and (Get-PlexProcess)) {
            $selection = 13
        }
        switch ($selection) {
            1 { Stop-PlexMediaServer }
            2 { Start-PlexMediaServer }
            3 {
                Invoke-PlexDBCheck -Force
                Invoke-PlexDBRepair
                Invoke-PlexDBReindex
            }
            4 { Invoke-PlexDBCheck }
            5 { Invoke-PlexDBVacuum }
            6 { Invoke-PlexDBRepair }
            7 { Invoke-PlexDBReindex }
            8 { Invoke-PlexDBImport }
            9 { Invoke-PlexDBReplace }
            10 { Get-Logfile }
            11 { WriteOutput -Message "Plex is running: $(if (Get-PlexProcess){'True'}else{'False'})"11 }
            12 { Invoke-PlexDBUndo }
            # Plex Running
            13 { Write-Host 'Plex is running. Please stop it before running any database operations.' }
            99 { Write-Host 'Good-bye!'; exit }
            Default { Write-Host 'Invalid input.' -ForegroundColor Red }
        }
        Write-Host "`n"
        Pause
    } while ($selection -ne 99)
}
else {
    if (-not($InstallLocation)) {
        Write-Host 'Could not locate Plex installation directory.' -ForegroundColor Red
    }
    if (-not(Test-Path "$PlexData\$PlexDBPrefix.db")) {
        Write-Host "Could not locate Plex '$PlexDBPrefix.db'" -ForegroundColor Red
    }
    Write-Host 'You may have to modify the variables at top of the script.' -ForegroundColor Red
}
