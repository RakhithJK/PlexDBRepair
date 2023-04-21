##################
# Variable Start #
##################

# Create Timestamp
$TimeStamp = Get-Date -Format 'hh-mm-ss'
$Date = Get-Date -Format 'dd.MM.yyyy'

# Query PMS default Locations
$InstallLocation = ((Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -ErrorAction SilentlyContinue | Get-ItemProperty -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Plex Media Server' })).InstallLocation
$PlexData = "$env:LOCALAPPDATA\Plex Media Server\Plug-in Support\Databases"
$PlexDBPath = "$PlexData\com.plexapp.plugins.library.db"
$PlexSQL = $InstallLocation + "Plex SQLite.exe"
$DBtmp = "$PlexData\dbtmp"
$TmpFile = "$DBtmp\results.tmp"
$PMSservice = "Plex Media Server"

################
# Variable End #
################
function WriteOutput($output, $Type) {
    if ($Type -eq 'Error') {
        $output = " [Error] -- " + $output
        $out = '    ' + $(Get-Date -Format 'hh:mm:ss tt') + $output
        Write-Host $out -ForegroundColor Red
    }
    elseif ($Type -eq 'Information') {
        $output = " [Information] -- " + $output
        $out = '    ' + $(Get-Date -Format 'hh:mm:ss tt') + $output
        Write-Host $out
    }
    elseif ($Type -eq 'Warning') {
        $output = " [Warning] -- " + $output
        $out = '    ' + $(Get-Date -Format 'hh:mm:ss tt') + $output
        Write-Host $out -ForegroundColor Yellow
    }
    Else {
        $output = " -- " + $output
        $out = '    ' + $(Get-Date -Format 'hh:mm:ss tt') + $output
        Write-Host $out
    }
    $log = $(Get-Date -Format 'hh:mm:ss tt') + $output
    Add-Content -Path "$PlexData\PlexDBRepair.log" -Value $log
}

function Show-RetroUI {
    $title = @"
    ██████╗ ██╗     ███████╗██╗  ██╗██████╗ ██████╗ ██████╗ ███████╗██████╗  █████╗ ██╗██████╗ 
    ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██║██╔══██╗
    ██████╔╝██║     █████╗   ╚███╔╝ ██║  ██║██████╔╝██████╔╝█████╗  ██████╔╝███████║██║██████╔╝
    ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██║  ██║██╔══██╗██╔══██╗██╔══╝  ██╔═══╝ ██╔══██║██║██╔══██╗
    ██║     ███████╗███████╗██╔╝ ██╗██████╔╝██████╔╝██║  ██║███████╗██║     ██║  ██║██║██║  ██║
    ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝                                                                                                                                                                   
"@
    Write-Host -ForegroundColor DarkYellow $title
    Write-Host -ForegroundColor Yellow "    -------------------------------------------------------------------------------------------`n"
    Write-Host -ForegroundColor Green "                                  Welcome to PlexDBRepair CLI!`n"
    Write-Host -ForegroundColor Yellow "    -------------------------------------------------------------------------------------------`n"

    while ($true) {
        Write-Host "    1 - 'stop'      - Stop PMS"
        Write-Host "    2 - 'automatic' - database check, repair/optimize, and reindex in One step."
        Write-Host "    3 - 'check'     - Perform integrity check of database"
        Write-Host "    4 - 'vacuum'    - Remove empty space from database"
        Write-Host "    5 - 'repair'    - Repair/Optimize  databases"
        Write-Host "    6 - 'reindex'   - Rebuild database database indexes"
        Write-Host "    7 - 'start'     - Start PMS"
        Write-Host "    8 - 'import'    - Import watch history from another database independent of Plex. (risky)"
        Write-Host "    9 - 'replace'   - Replace current databases with newest usable backup copy (interactive)"
        Write-Host "   10 - 'show'      - Show logfile"
        Write-Host "   11 - 'status'    - Report status of PMS (run-state and databases)"
        Write-Host "   12 - 'undo'      - Undo last successful command"
        Write-Host "   99 - 'exit'`n"

        $choice = Read-Host "   Enter your choice"

        switch ($choice) {
            '1' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; stopPMS -serviceName $PMSservice }
            '2' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; automatic -serviceName $PMSservice }
            '3' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; check -Force $true }
            '4' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; vacuum }
            '5' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; repair }
            '6' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; reindex }
            '7' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; startPMS }
            '8' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; import }
            '9' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; replace }
            '10' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; show }
            '11' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; status }
            '12' { Write-Host "`n   You chose Option $choice`n" -ForegroundColor Magenta; undo }
            '99' { 
                Write-Host "`n   Exiting...`n" -ForegroundColor Red
                return
            }                                                                                    
            default { Write-Host "`n   Invalid choice. Please choose again.`n" -ForegroundColor Red }
        }
    }
}

# Stop service function
function stopPMS {
    param (
        [string]$serviceName
    )
    # Look for PMS exe and kill it
    $PMSexe = Get-Process $serviceName -ErrorAction SilentlyContinue
    if ($PMSexe) {
        WriteOutput "Killing PMS exe..."
        Stop-Process $PMSexe.id -Confirm:$false -Force
        sleep 5
    }
    Else {
        WriteOutput "Plex is not running..."
    }
}

# Set service to automatic start function
function Automatic($serviceName) {
    WriteOutput "====== Session begins. ($Date) ======"

    # Look for PMS exe and kill it
    $PMSexe = Get-Process $serviceName -ErrorAction SilentlyContinue
    if ($PMSexe) {
        WriteOutput "Killing PMS exe..."
        Stop-Process $PMSexe.id -Confirm:$false -Force
        sleep 5
        $PMSexe = Get-Process $serviceName -ErrorAction SilentlyContinue
        if (!($PMSexe)) {
            WriteOutput "Plex killed sucessfully. Starting now..."
        }
    }
    Else {
        WriteOutput "Plex is not running. Starting now..."
    }

    # Switching to PlexData dir
    Set-Location $PlexData

    # Creating Folder if not present
    if (!(Test-Path $DBtmp -ErrorAction SilentlyContinue)) {
        WriteOutput "Creating tmp folder..."
        New-Item -ItemType Directory "dbtmp"
    }
    # Deleteing tmp File if present
    if (Test-Path $TmpFile -ErrorAction SilentlyContinue) {
        WriteOutput "Removing tmp files..."
        Remove-Item $TmpFile -Force -Confirm:$false
    }
    WriteOutput "Exporting Main DB"

    # Execute the command
    try {
        Write-Output ".dump" | & $PlexSQL "$PlexData\com.plexapp.plugins.library.db" | Out-File "$DBtmp\library.sql_$TimeStamp"
    }
    catch {
        WriteOutput "Cannot export Main DB.  Aborting." -Type Error
        pause
    }

    WriteOutput "Exporting Blobs DB"

    # Execute the command
    try {
        Write-Output ".dump" | & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db" | Out-File "$DBtmp\blobs.sql_$TimeStamp"
    }
    catch {
        WriteOutput "Cannot export Blobs DB.  Aborting." -Type Error
        pause
    }

    # Now create new databases from SQL statements
    WriteOutput "Exporting Complete..."
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
        WriteOutput "Cannot create Main DB.  Aborting." -Type Warning
        pause
    }

    # Now Verify created DB
    WriteOutput "Verifying Main DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "PRAGMA integrity_check(1)" | Out-File $TmpFile
    }
    catch {
        WriteOutput "Main DB verificaion failed. Exiting." -Type Error
        pause
    }

    if ((Get-Content $TmpFile) -ne 'ok') {
        WriteOutput "Main DB verificaion failed. Exiting." -Type Error
        pause
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
        WriteOutput "Cannot create Blobs DB.  Aborting." -Type Error
        pause
    }

    # Now Verify created Blobs DB
    WriteOutput "Verifying Blobs DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "PRAGMA integrity_check(1)" | Out-File $TmpFile
    }
    catch {
        WriteOutput "Blobs DB verificaion failed. Exiting." -Type Error
        pause
    }
    if ((Get-Content $TmpFile) -ne 'ok') {
        WriteOutput "Blobs DB verificaion failed. Exiting." -Type Error
        pause
    }
    Else {
        WriteOutput "Blobs DB verification successful..."
        WriteOutput "Import and verification complete..."
    }

    WriteOutput "Reindexing Main DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "REINDEX;"
    }
    catch {
        WriteOutput "Main DB Reindex failed. Exiting." -Type Error
        pause
    }

    WriteOutput "Reindexing Blobs DB..."

    # Execute the command
    try {
        & $PlexSQL "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "REINDEX;"
    }
    catch {
        WriteOutput "Blobs DB Reindex failed. Exiting." -Type Error
        pause
    }

    WriteOutput "Reindexing complete..."
    WriteOutput "Moving current DBs to DBTMP and making new databases active..."

    # Moving files

    Move-Item "$PlexData\com.plexapp.plugins.library.db" "$DBtmp\com.plexapp.plugins.library.db_$TimeStamp" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Move-Item "$PlexData\com.plexapp.plugins.library.db_$TimeStamp" "$PlexData\com.plexapp.plugins.library.db"-Force -Confirm:$false -ErrorAction SilentlyContinue

    Move-Item "$PlexData\com.plexapp.plugins.library.blobs.db" "$DBtmp\com.plexapp.plugins.library.blobs.db_$TimeStamp" -Force -Confirm:$false -ErrorAction SilentlyContinue
    Move-Item "$PlexData\com.plexapp.plugins.library.blobs.db_$TimeStamp" "$PlexData\com.plexapp.plugins.library.blobs.db" -Force -Confirm:$false -ErrorAction SilentlyContinue

    WriteOutput "Database repair/rebuild/reindex completed..."
    WriteOutput "Starting Plex Media Server now..."
    Start-Process "$InstallLocation\Plex Media Server.exe" -InformationAction SilentlyContinue
    WriteOutput "====== Session completed. ======"
}

function CheckDB($path) {
    # Confirm the DB exists
    if (-not (Test-Path $path)) {
        WriteOutput "$path does not exist." -Type Error
        return 1
    }
    
    # Now check database for corruption
    $Result = & $PLEX_SQLITE $path "PRAGMA integrity_check(1)"
    if ($Result -eq "ok") {
        return 0
    }
    else {
        $global:SQLerror = $Result -replace ".*code "
        return 1
    }
}

# Check file system function
function Check($Force) {
    # Check given database file integrity

    # Check each of the databases. If all pass, set the 'CheckedDB' flag
    # Only force recheck if flag given

    # Check if not checked or forced
    $NeedCheck = 0
    if ($global:CheckedDB -eq 0) { $NeedCheck = 1 }
    if ($global:CheckedDB -eq 1 -and $Force -eq $true) { $NeedCheck = 1 }

    # Do we need to check
    if ($NeedCheck -eq 1) {

        # Clear Damaged flag
        $global:Damaged = 0
        $global:CheckedDB = 0

        # Info
        WriteOutput "Checking the PMS databases"

        # Check main DB
        if (CheckDB "$PlexData\$CPPL.db") {
            WriteOutput "Check complete. PMS main database is OK."
            WriteOutput "Check $CPPL.db - PASS"
        }
        else {
            WriteOutput "Check complete. PMS main database is damaged."
            WriteOutput "Check $CPPL.db - FAIL ($SQLerror)"
            $global:Damaged = 1
        }

        # Check blobs DB
        if (CheckDB "$PlexData\$CPPL.blobs.db") {
            WriteOutput "Check complete. PMS blobs database is OK."
            WriteOutput "Check $CPPL.blobs.db - PASS"
        }
        else {
            WriteOutput "Check complete. PMS blobs database is damaged."
            WriteOutput "Check $CPPL.blobs.db - FAIL ($SQLerror)"
            $global:Damaged = 1
        }

        # Yes, we've now checked it
        $global:CheckedDB = 1
    }

    if ($global:Damaged -eq 0) { $global:CheckedDB = 1 }

    # return status
    return $global:Damaged
}
function MakeBackups {
    WriteOutput "Backup current databases with '-BACKUP-$TimeStamp' timestamp."
    $Result = $null
    $dbFiles = @("db", "db-wal", "db-shm", "blobs.db", "blobs.db-wal", "blobs.db-shm")
    foreach ($file in $dbFiles) {
        $Result = DoBackup "$PlexData\$CPPL.$file" "$DBTMP\$CPPL.$file-BACKUP-$TimeStamp"
        return $Result 
    }
}
function RestoreSaved($T) {
    $fileNames = "db", "db-wal", "db-shm", "blobs.db", "blobs.db-wal", "blobs.db-shm"

    foreach ($i in $fileNames) {
        if (Test-Path "$PlexData\$CPPL.$i") { Remove-Item "$PlexData\$CPPL.$i" }
        if (Test-Path "$DBTMP\$CPPL.$i-BACKUP-$T") { Move-Item "$DBTMP\$CPPL.$i-BACKUP-$T" "$PlexData\$CPPL.$i" }
    }
}
# Vacuum function
function Vacuum {
    # Check databases before Indexing if not previously checked
    if (-not (CheckDB "Vacuum ")) {
        $Damaged = 1
        $Fail = 1
    }

    # If damaged, exit
    if ($Damaged -eq 1) {
        WriteOutput "Databases are damaged. Vacuum operation not available.  Please repair or replace first." -Type Warning
        return 1
    }

    # Make a backup
    Output "Backing up databases"
    if (-not (MakeBackups "Vacuum ")) {
        WriteOutput "Backup creation failed.  Cannot continue." -Type Error
        $Fail = 1
        return 1
    }
    else {
        WriteOutput "Vacuum  - MakeBackups - PASS"
    }

    # Start vacuuming
    WriteOutput "Vacuuming main database"
    $SizeStart = [math]::Round(((Get-Item -Path "$PlexData\$CPPL.db").Length / 1MB), 2)
    # Vacuum it
    & "$PLEX_SQLITE" $CPPL.db 'VACUUM;'
    $Result = $?

    if (SQLiteOK $Result) {
        $SizeFinish = [math]::Round(((Get-Item -Path "$PlexData\$CPPL.db").Length / 1MB), 2)
        WriteOutput "Vacuuming main database successful..."
        WriteOutput "Starting size: $($SizeStart)MB"
        WriteOutput "Size now:      $($SizeFinish)MB."
    }
    else {
        WriteOutput "Vaccuming main database failed. Error code $Result from Plex SQLite" -Type Error
        $Fail = 1
    }

    WriteOutput "Vacuuming blobs database"
    $SizeStart = [math]::Round(((Get-Item -Path "$PlexData\$CPPL.blobs.db").Length / 1MB), 2)

    # Vacuum it
    & "$PLEX_SQLITE" $CPPL.blobs.db 'VACUUM;'
    $Result = $?

    if (SQLiteOK $Result) {
        $SizeFinish = [math]::Round(((Get-Item -Path "$PlexData\$CPPL.blobs.db").Length / 1MB), 2)
        WriteOutput "Vacuuming blobs database successful..."
        WriteOutput "Starting size: $($SizeStart)MB"
        WriteOutput "Size now:      $($SizeFinish)MB."
    }
    else {
        WriteOutput "Vaccuming blobs database failed. Error code $Result from Plex SQLite" -Type Error
        $Fail = 1
    }

    if ($Fail -eq 0) {
        WriteOutput "Vacuum complete."
        SetLast "Vacuum" "$TimeStamp"
    }
    else {
        WriteOutput "Vacuum failed." -Type Error
        RestoreSaved "$TimeStamp"
    }

}

# Repair function
function Repair {
    param (
        [string]$databaseName
    )
    # Placeholder function, replace with actual repair function code
    Write-Host "Running repair on database $databaseName"
}

# Reindex function
function Reindex {
    param (
        [string]$databaseName
    )
    # Placeholder function, replace with actual reindex function code
    Write-Host "Running reindex on database $databaseName"
}

# Start service function
function startPMS {
    param (
        [string]$serviceName
    )
    Start-Service -Name $serviceName
}

# Import function
function Import {
    param (
        [string]$filePath
    )
    # Placeholder function, replace with actual import function code
    Write-Host "Importing data from file $filePath"
}

# Replace function
function Replace {
    param (
        [string]$filePath,
        [string]$searchString,
        [string]$replaceString
    )
    # Placeholder function, replace with actual replace function code
    Write-Host "Replacing text in file $filePath"
}

# Show function
function Show {
    param (
        [string]$filePath
    )
    # Placeholder function, replace with actual show function code
    Write-Host "Showing data from file $filePath"
}

# Status function
function Status {
    param (
        [string]$serviceName
    )
    Get-Service -Name $serviceName
}

# Undo function
function Undo {
    # Placeholder function, replace with actual undo function code
    Write-Host "Undoing last action"
}

if ($InstallLocation) {
    Write-Host "Plex Media Server is installed..."
    Write-Host "Testing DB Path now..." -ForegroundColor Cyan
    if (Test-Path $PlexDBPath) {
        Write-Host "Found DB" -ForegroundColor Green
        $CanRun = $true
    }
}
if ($CanRun) {
    Show-RetroUI
}
Else {
    Write-Host "Could not locate DB, maybe you have to modify Variables at top of the Script..." -ForegroundColor Red
}
