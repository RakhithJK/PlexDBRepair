# PlexDBRepair

[![GitHub issues](https://img.shields.io/github/issues/ChuckPa/PlexDBRepair.svg?style=flat)](https://github.com/ChuckPa/PlexDBRepair/issues)
[![Release](https://img.shields.io/github/release/ChuckPa/PlexDBRepair.svg?style=flat)](https://github.com/ChuckPa/PlexDBRepair/releases/latest)
[![Download latest release](https://img.shields.io/github/downloads/ChuckPa/PlexDBRepair/latest/total.svg)](https://github.com/ChuckPa/PlexDBRepair/releases/latest)
[![Download total](https://img.shields.io/github/downloads/ChuckPa/PlexDBRepair/total.svg)](https://github.com/ChuckPa/PlexDBRepair/releases)
[![master](https://img.shields.io/badge/master-stable-green.svg?maxAge=2592000)]('')
![Maintenance](https://img.shields.io/badge/Maintained-Yes-green.svg)

# Introduction

DBRepair provides database repair and maintenance for the most common  Plex Media Server database problems.
It is a simple menu-driven utility with a command line backend.

DBRepair is run from a command line (terminal or ssh/putty session) which has sufficient privilege to read/write the databases (minimum).
If sufficient privleges exist (root), and supported by the environment, the options to start and stop PMS are presented as well.
(Some envionments require DBRepair to run as the 'root' user.)

## Situations and errors commonly seen include:

        1. Searching is sluggish
        2. Database is malformed / damaged / corrupted
        3. Database has bloated from media addition or changes
        4. Damaged indexes damaged

## Functions provided

 The utility accepts command names.
 Command names may be upper/lower case and may also be abbreviated (4 character minimum).

 The following commands (or their number), listed in alphabetical order,  are accepted as input.
```
   AUTO(matic)  - Automatically check, repair/optimize, and reindex the databases in one step.
   CHEC(k)      - Check the main and blob databases integrity
   EXIT         - Exit the utility
   IMPO(rt)     - Import viewstate / watch history from another database
   REIN(dex)    - Rebuild the database indexes
   REPL(ace)    - Replace the existing databases with a PMS-generated backup
   SHOW         - Show the log file
   STAR(t)      - Start PMS (not available on all platforms)
   STOP         - Stop PMS  (not available on all platforms)
   UNDO         - UNDO the last operation
   VACU(um)     - Vacuum the databases
```

### The menu

  The menu gives you the option to enter either a 'command number' or the 'command name/abbreviation'.
  For clarity, each command's name is 'quoted'.

```
      Plex Media Server Database Repair Utility (_host_configuration_name_)
                       Version v1.02.00

  Select

    1 - 'stop'      - Stop PMS.
    2 - 'automatic' - Check, Repair/Optimize, and Reindex Database in one step.
    3 - 'check'     - Perform integrity check of database.
    4 - 'vacuum'    - Remove empty space from database without optimizing.
    5 - 'repair'    - Repair/Optimize databases.
    6 - 'reindex'   - Rebuild database database indexes.
    7 - 'start'     - Start PMS

    8 - 'import'    - Import watch history from another database independent of Plex. (risky).
    9 - 'replace'   - Replace current databases with newest usable backup copy (interactive).
   10 - 'show'      - Show logfile.
   11 - 'status'    - Report status of PMS (run-state and databases).
   12 - 'undo'      - Undo last successful command.

   42 - 'ignore'    - Ignore duplicate/constraint errors.

   88 - 'update'    - Check for updates.
   99 - 'quit'      - Quit immediately.  Keep all temporary files.
        'exit'      - Exit with cleanup options.

  Enter command # -or- command name (4 char min) :



## Hosts currently supported

        1. Apple (MacOS)
        2. ASUSTOR
        3. Docker containers via 'docker exec' command (inside the running container environment)
           - Plex,inc.
           - Linuxserver.io
           - BINHEX
           - HOTIO
           - Podman (libgpod)
        4. Linux workstation & server
        5. Netgear (OS5 Linux-based systems)
        6. QNAP (QTS & QuTS)
        7. Synology (DSM 6 & DSM 7)
        8. Western Digital (OS5)
```
 # Installation

    Where to place the utility varies from host to host.
    Please use this table as a reference.

    Some hosts will not be listed here by name (e.g. Unraid, Proxmox).
    They will likely be supported by the container/VM PMS runs in.

```
    Vendor             | Shared folder name  |  Recommended directory
    -------------------+---------------------+------------------------------------------
    Apple              | Downloads           |  ~/Downloads
    Arch Linux         | N/A                 |  Anywhere
    ASUSTOR            | Public              |  /volume1/Public
    binhex             | N/A                 |  Container root (adjacent /config)
    Docker             | N/A                 |  Container root (adjacent /config)
    Hotio              | N/A                 |  Container root (adjacent /config)
    Linux (wkstn/svr)  | N/A                 |  Anywhere
    Netgear (ReadyNAS) | "your_choice"       |  "/data/your_choice"
    QNAP (QTS/QuTS)    | Public              |  /share/Public
    Synology (DSM 6)   | Plex                |  /volume1/Plex             (change volume as required)
    Synology (DSM 7)   | PlexMediaServer     |  /volume1/PlexMediaServer  (change volume as required)
    Western Digital    | Public              |  /mnt/HD/HD_a2/Public      (Does not support 'MyCloudHome' series)
```

### General installation and usage instructions

        1. Open your browser to https://github.com/ChuckPa/PlexDBRepair/releases/latest
        2. Download the source code (tar.gz or ZIP) file

        3. Knowing the file name will always be of the form 'PlexDBRepair-X.Y.Z.tar.gz'
           --  where X.Y.Z is the release number.  Use the real values in place of X, Y, and Z.
        4. Place the tar.gz file in the appropriate directory on the system you'll use it.
        5. Open a command line session (usually Terminal or SSH)
        6. Elevate privilege level to root (sudo) if needed.
        7. Extract the utility from the tar or zip file
        8. 'cd' into the extraction directory
        9. Give DBRepair.sh 'execute' permission  (chmod +x)
       10. Invoke ./DBRepair.sh




###   EXAMPLE:  To install & launch on Synology DSM 6 / DSM 7

        cd /volume1/Plex    # use /volume1/PlexMediaServer on DSM 7
        sudo bash
        tar xf PlexDBRepair-x.y.z.tar.gz
        cd PlexDBRepair-x.y.z
        chmod +x DBRepair.sh
        ./DBRepair.sh

###    EXAMPLE: Using DBRepair inside containers (manual start/stop included)

#### (Select containers allow stopping/starting PMS from the menu.  See menu for details)

        sudo docker exec -it plex /bin/bash

        # extract from downloaded version file name then cd into directory
        tar xf PlexDBRepair-1.0.0.tar.gz
        cd PlexDBRepair-1.0.0
        chmod +x DBRepair.sh
        ./DBRepair.sh
```
###    EXAMPLE:  Using DBRepair on regular Linux native host (Workstation/Server)
```
        sudo bash
        cd /path/to/DBRepair.tar
        tar xf PlexDBRepair-1.0.0.tar.gz
        cd PlexDBRepair-1.0.0
        chmod +x DBRepair.sh
        ./DBRepair.sh stop auto start exit
```

###    EXAMPLE: Using DBRepair from the command line on MacOS (on the administrator account)
```
        osascript -e 'quit app "Plex Media Server"'
        cd ~/Downloads
        tar xvf PlexDBRepai PlexDBRepair-1.0.0.tar.gz
        cd PlexDBRepair-1.0.0

        chmod +x DBRepair.sh
        ./DBRepair.sh



## Typical usage

This utility can only operate on PMS when PMS is in the stopped state.
If PMS is running when you startup the utility,  it will tell you.

These examples

  A. The most common usage will be the "Automatic" function.

    Automatic mode is where DBRepair determines which steps are needed to make your database run optimally.
    For most users, Automatic is equivalent to 'Check, Repair, Reindex'.
    This repairs minor damage, vacuums out all the unused records, and rebuilds search indexes in one step.

  B. Database is malformed  (Backups of  com.plexapp.plugins.library.db and com.plexap.plugins.library.blobs.db available)
     Note: You may attempt "Repair" sequence

    1. (3)  Check   - Confirm either main or blobs database is damaged
    2. (9)  Replace - Use the most recent valid backup -- OR -- (5) Repair.  Check date/time stamps for best action.
                    -- If Replace fails, use Repair (5)
                    -- (Replace can fail if the database has been damaged for a long time.)
    3. (6)  Reindex - Generate new indexes so PMS doesn't need to at startup
    4. (99) Exit

  C. Database is malformed - No Backups
    1. (3)  Check   - Confirm either main or blobs database is damaged
    2. (5)  Repair  - Salavage as much as possible from the databases and rebuild them into a usable database.
    3. (6)  Reindex - Generate new indexes so PMS doesn't need to at startup
    4. (99) Exit

  C. Database sizes excessively large when compared to amount of media indexed (item count)
    1. (3)  Check   - Make certain both databases are fully intact  (repair if needed)
    2. (4)  Vacuum  - Instruct SQLite to rebuild its tables and recover unused space.
    3. (6)  Reindex - Rebuild Indexes.
    4. (99) Exit

  D. User interface has become 'sluggish' as more media was added
    1. (3)  Check   - Confirm there is no database damage
    2. (5)  Repair  - You are not really repairing.  You are rebuilding the DB in perfect sorted order.
    3. (6)  Reindex - Rebuild Indexes.
    4. (99) Exit

  E. Undo
    Undo is a special case where you need the utility to backup ONE step.
    This is rarely needed.  The only time you might want/need to backup one step is if Replace leaves you worse off
    than you were before. In this case, UNDO then Repair.  Undo can only undo the single most-recent action.
    (Note: In a future release, you will be able to 'undo' every action taken until the DBs are in their original state)

Special considerations:

    1. As stated above, this utility requires PMS to be stopped in order to do what it does.
    2. - This utility CAN sit at the menu prompt with PMS running.
       - You did a few things and want to check BEFORE exiting the utility
       - If you don't like how it worked out,
        -- STOP PMS
        -- UNDO the last action and do something else
        -- OR do more things to the databases
    3. When satisfied,  Exit the utility.
       - There is no harm in keeping the database temp files (except for space used)
       - ALL database temps are named with date-time stamps in the name to avoid confusion.
    4. The Logfile ('show' command) shows all actions performed WITH timestamp so you can locate
       intermediate databases if desired for special / manual recovery cases.

Attention:

  The behavior of command "99" is different than command "Exit"
  This is intentional.

  "99" is the "Get out now,  Keep all intermediate/temp files.
   --  This is for when DB operations keep getting worse and you don't know what to do.
       "99" is an old 'Get Smart' TV series reference where agent 99 would try to save agent 86 from harm.

  "99" was originally going to be "Quit immediately save all files" but development feedback
  resulted in this configuration

  "Exit" is the preferred method to leave.

  "Quit" was desired instead of "99" but there are those who didn't understand the difference or references.

  If community feedback wants both "Quit. save temps" and "Exit, delete temps", behavior is easily changed.

  Also please be aware the script understands interactive versus scripted mode.



## Scripting support

  Certain platforms don't provide for each command line access.
  To support those products,  this utility can be operated by adding command line arguments.

  Another use of this feature is to automate Plex Database maintenance44
  ( Stop Plex,  Run this sequence,  Start Plex ) at a time when the server isn't busy


  The command line arguments are the same as if typing at the menu.

  Example:   ./DBRepair.sh  stop auto start exit

  This executes:   Stop PMS,  Automatic (Check, Repair, Reindex), Start PMS, and Exit commands


## Exiting

  When exiting,  you will be asked whether to keep the interim temp files created during this session.
  If you've encountered any difficulties or aren't sure what to do,  don't delete them.
  You'll be able to ask in the Plex forums about what to do.  Be prepared to present the log file to them.


## Sample interactive session

  This is a typical manual session if you aren't sure what to do and want the tool to decide.



```
bash-4.4# #=======================================================================================================
bash-4.4# ./DBRepair.sh



      Plex Media Server Database Repair Utility (Ubuntu 20.04.6 LTS)
                       Version v1.02.00


Select

  1 - 'stop'      - Stop PMS.
  2 - 'automatic' - Check, Repair/Optimize, and Reindex Database in one step.
  3 - 'check'     - Perform integrity check of database.
  4 - 'vacuum'    - Remove empty space from database without optimizing.
  5 - 'repair'    - Repair/Optimize databases.
  6 - 'reindex'   - Rebuild database database indexes.
  7 - 'start'     - Start PMS

  8 - 'import'    - Import watch history from another database independent of Plex. (risky).
  9 - 'replace'   - Replace current databases with newest usable backup copy (interactive).
 10 - 'show'      - Show logfile.
 11 - 'status'    - Report status of PMS (run-state and databases).
 12 - 'undo'      - Undo last successful command.

 42 - 'ignore'    - Ignore duplicate/constraint errors.

 88 - 'update'    - Check for updates.
 99 - 'quit'      - Quit immediately.  Keep all temporary files.
      'exit'      - Exit with cleanup options.

Enter command # -or- command name (4 char min) :  1

Stopping PMS.
Stopped PMS.

Select

  1 - 'stop'      - Stop PMS.
  2 - 'automatic' - Check, Repair/Optimize, and Reindex Database in one step.
  3 - 'check'     - Perform integrity check of database.
  4 - 'vacuum'    - Remove empty space from database without optimizing.
  5 - 'repair'    - Repair/Optimize databases.
  6 - 'reindex'   - Rebuild database database indexes.
  7 - 'start'     - Start PMS

  8 - 'import'    - Import watch history from another database independent of Plex. (risky).
  9 - 'replace'   - Replace current databases with newest usable backup copy (interactive).
 10 - 'show'      - Show logfile.
 11 - 'status'    - Report status of PMS (run-state and databases).
 12 - 'undo'      - Undo last successful command.

 42 - 'ignore'    - Ignore duplicate/constraint errors.

 88 - 'update'    - Check for updates.
 99 - 'quit'      - Quit immediately.  Keep all temporary files.
      'exit'      - Exit with cleanup options.

Enter command # -or- command name (4 char min) : auto


Checking the PMS databases
Check complete.  PMS main database is OK.
Check complete.  PMS blobs database is OK.

Exporting current databases using timestamp: 2023-02-25_16.15.11
Exporting Main DB
Exporting Blobs DB
Successfully exported the main and blobs databases.  Proceeding to import into new databases.
Importing Main DB.
Importing Blobs DB.
Successfully imported data from SQL files.
Verifying databases integrity after importing.
Verification complete.  PMS main database is OK.
Verification complete.  PMS blobs database is OK.
Saving current databases with '-BKUP-2023-02-25_16.15.11'
Making imported databases active
Import complete. Please check your library settings and contents for completeness.
Recommend:  Scan Files and Refresh all metadata for each library section.

Backing up of databases
Backup current databases with '-BKUP-2023-02-25_16.20.41' timestamp.
Reindexing main database
Reindexing main database successful.
Reindexing blobs database
Reindexing blobs database successful.
Reindex complete.
Automatic Check,Repair/optimize,Index successful.

Select

  1 - 'stop'      - Stop PMS.
  2 - 'automatic' - Check, Repair/Optimize, and Reindex Database in one step.
  3 - 'check'     - Perform integrity check of database.
  4 - 'vacuum'    - Remove empty space from database without optimizing.
  5 - 'repair'    - Repair/Optimize databases.
  6 - 'reindex'   - Rebuild database database indexes.
  7 - 'start'     - Start PMS

  8 - 'import'    - Import watch history from another database independent of Plex. (risky).
  9 - 'replace'   - Replace current databases with newest usable backup copy (interactive).
 10 - 'show'      - Show logfile.
 11 - 'status'    - Report status of PMS (run-state and databases).
 12 - 'undo'      - Undo last successful command.

 42 - 'ignore'    - Ignore duplicate/constraint errors.

 88 - 'update'    - Check for updates.
 99 - 'quit'      - Quit immediately.  Keep all temporary files.
      'exit'      - Exit with cleanup options.

Enter command # -or- command name (4 char min) : start

Starting PMS.
Started PMS

Select

  1 - 'stop'      - Stop PMS.
  2 - 'automatic' - Check, Repair/Optimize, and Reindex Database in one step.
  3 - 'check'     - Perform integrity check of database.
  4 - 'vacuum'    - Remove empty space from database without optimizing.
  5 - 'repair'    - Repair/Optimize databases.
  6 - 'reindex'   - Rebuild database database indexes.
  7 - 'start'     - Start PMS

  8 - 'import'    - Import watch history from another database independent of Plex. (risky).
  9 - 'replace'   - Replace current databases with newest usable backup copy (interactive).
 10 - 'show'      - Show logfile.
 11 - 'status'    - Report status of PMS (run-state and databases).
 12 - 'undo'      - Undo last successful command.

 42 - 'ignore'    - Ignore duplicate/constraint errors.

 88 - 'update'    - Check for updates.
 99 - 'quit'      - Quit immediately.  Keep all temporary files.
      'exit'      - Exit with cleanup options.

Enter command # -or- command name (4 char min) : stat


Status report: Sat Feb 25 04:38:50 PM EST 2023
  PMS is running.
  Databases are OK.


Select

  1 - 'stop'      - Stop PMS.
  2 - 'automatic' - Check, Repair/Optimize, and Reindex Database in one step.
  3 - 'check'     - Perform integrity check of database.
  4 - 'vacuum'    - Remove empty space from database without optimizing.
  5 - 'repair'    - Repair/Optimize databases.
  6 - 'reindex'   - Rebuild database database indexes.
  7 - 'start'     - Start PMS

  8 - 'import'    - Import watch history from another database independent of Plex. (risky).
  9 - 'replace'   - Replace current databases with newest usable backup copy (interactive).
 10 - 'show'      - Show logfile.
 11 - 'status'    - Report status of PMS (run-state and databases).
 12 - 'undo'      - Undo last successful command.

 42 - 'ignore'    - Ignore duplicate/constraint errors.

 88 - 'update'    - Check for updates.
 99 - 'quit'      - Quit immediately.  Keep all temporary files.
      'exit'      - Exit with cleanup options.

Enter command # -or- command name (4 char min) : exit

Ok to remove temporary databases/workfiles for this session? (Y/N) ? y
Are you sure (Y/N) ? y
Deleting all temporary work files.
bash-4.4#

```

## Sample (typical) scripted session (e.g.  via 'cron')

```
root@lizum:/sata/plex/Plex Media Server/Plug-in Support/Databases# ./DBRepair.sh stop check auto start exit



      Plex Media Server Database Repair Utility (Ubuntu 20.04.5 LTS)
                       Version v1.0.0


[2023-03-05 18.53.49] Stopping PMS.
[2023-03-05 18.53.49] Stopped PMS.

[2023-03-05 18.53.49] Checking the PMS databases
[2023-03-05 18.54.22] Check complete.  PMS main database is OK.
[2023-03-05 18.54.22] Check complete.  PMS blobs database is OK.

[2023-03-05 18.54.22] Automatic Check,Repair,Index started.
[2023-03-05 18.54.22]
[2023-03-05 18.54.22] Checking the PMS databases
[2023-03-05 18.54.56] Check complete.  PMS main database is OK.
[2023-03-05 18.54.56] Check complete.  PMS blobs database is OK.
[2023-03-05 18.54.56]
[2023-03-05 18.54.56] Exporting current databases using timestamp: 2023-03-05_18.54.22
[2023-03-05 18.54.56] Exporting Main DB
[2023-03-05 18.55.30] Exporting Blobs DB
[2023-03-05 18.55.33] Successfully exported the main and blobs databases.  Proceeding to import into new databases.
[2023-03-05 18.55.33] Importing Main DB.
[2023-03-05 18.57.04] Importing Blobs DB.
[2023-03-05 18.57.05] Successfully imported SQL data.
[2023-03-05 18.57.05] Verifying databases integrity after importing.
[2023-03-05 18.57.40] Verification complete.  PMS main database is OK.
[2023-03-05 18.57.40] Verification complete.  PMS blobs database is OK.
[2023-03-05 18.57.40] Saving current databases with '-BACKUP-2023-03-05_18.54.22'
[2023-03-05 18.57.40] Making repaired databases active
[2023-03-05 18.57.40] Repair complete. Please check your library settings and contents for completeness.
[2023-03-05 18.57.40] Recommend:  Scan Files and Refresh all metadata for each library section.
[2023-03-05 18.57.40]
[2023-03-05 18.57.40] Backing up of databases
[2023-03-05 18.57.40] Backup current databases with '-BACKUP-2023-03-05_18.57.40' timestamp.
[2023-03-05 18.57.41] Reindexing main database
[2023-03-05 18.58.17] Reindexing main database successful.
[2023-03-05 18.58.17] Reindexing blobs database
[2023-03-05 18.58.17] Reindexing blobs database successful.
[2023-03-05 18.58.17] Reindex complete.
[2023-03-05 18.58.17] Automatic Check, Repair/optimize, & Index successful.

[2023-03-05 18.58.17] Starting PMS.
[2023-03-05 18.58.17] Started PMS

root@lizum:/sata/plex/Plex Media Server/Plug-in Support/Databases#

```

======================
```

```
## Logfile

  The logfile (DBRepair.log) keeps track of all commands issues and their status (PASS/FAIL) with timestamp.
  This can be useful when recovering from an interrupted session because temporary files are timestamped.


```
2023-02-25 16.14.39 - ============================================================
2023-02-25 16.14.39 - Session start: Host is Synology (DSM 7)
2023-02-25 16.14.56 - StopPMS  - PASS
2023-02-25 16.16.06 - Check   - Check com.plexapp.plugins.library.db - PASS
2023-02-25 16.16.06 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.16.06 - Check   - PASS
2023-02-25 16.17.20 - Repair  - Export databases - PASS
2023-02-25 16.19.52 - Repair  - Import - PASS
2023-02-25 16.20.41 - Repair  - Verify main database - PASS (Size: 399MB/399MB).
2023-02-25 16.20.41 - Repair  - Verify blobs database - PASS (Size: 1MB/1MB).
2023-02-25 16.20.41 - Repair  - Move files - PASS
2023-02-25 16.20.41 - Repair  - PASS
2023-02-25 16.20.41 - Repair  - PASS
2023-02-25 16.20.46 - Reindex - MakeBackup com.plexapp.plugins.library.db - PASS
2023-02-25 16.20.46 - Reindex - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.20.46 - Reindex - MakeBackup - PASS
2023-02-25 16.21.34 - Reindex - Reindex: com.plexapp.plugins.library.db - PASS
2023-02-25 16.21.35 - Reindex - Reindex: com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.21.35 - Reindex - PASS
2023-02-25 16.21.35 - Reindex - PASS
2023-02-25 16.21.35 - Auto    - PASS
2023-02-25 16.38.35 - StartPMS  - PASS
2023-02-25 16.38.57 - Exit    - Delete temp files.
2023-02-25 16.38.58 - Session end.
2023-02-25 16.38.58 - ============================================================
2023-02-25 16.40.10 - ============================================================
2023-02-25 16.40.10 - Session start: Host is Synology (DSM 7)
2023-02-25 16.40.27 - StopPMS  - PASS
2023-02-25 16.42.23 - Check   - Check com.plexapp.plugins.library.db - PASS
2023-02-25 16.42.24 - Check   - Check com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.42.24 - Check   - PASS
2023-02-25 16.43.39 - Repair  - Export databases - PASS
2023-02-25 16.46.10 - Repair  - Import - PASS
2023-02-25 16.46.58 - Repair  - Verify main database - PASS (Size: 399MB/399MB).
2023-02-25 16.46.58 - Repair  - Verify blobs database - PASS (Size: 1MB/1MB).
2023-02-25 16.46.59 - Repair  - Move files - PASS
2023-02-25 16.46.59 - Repair  - PASS
2023-02-25 16.46.59 - Repair  - PASS
2023-02-25 16.47.03 - Reindex - MakeBackup com.plexapp.plugins.library.db - PASS
2023-02-25 16.47.03 - Reindex - MakeBackup com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.47.03 - Reindex - MakeBackup - PASS
2023-02-25 16.47.52 - Reindex - Reindex: com.plexapp.plugins.library.db - PASS
2023-02-25 16.47.52 - Reindex - Reindex: com.plexapp.plugins.library.blobs.db - PASS
2023-02-25 16.47.52 - Reindex - PASS
2023-02-25 16.47.52 - Reindex - PASS
2023-02-25 16.47.52 - Auto    - PASS
2023-02-25 16.48.04 - StartPMS  - PASS
2023-02-25 16.48.05 - Exit    - Delete temp files.
2023-02-25 16.48.05 - Session end.

```

# Command Reference:

### Automatic

  Automatic provides automated processing of most checks and repairs.  (Check, Repair/Resequence, Index)
  In its current state,  it will not automatically replace a damaged database from a backup (future)

  It will not stop PMS as not all systems support stopping PMS from within this tool.

### Check

  Checks the integrity of the Plex main and blobs databases.

### Exit

  Exits the utility and removes all temporary database files created during processing.
  To save all intermediate databases,  use the 'Quit' command.

### Ignore / Honor

  Toggle the state (ON/OFF) of the IGNORE flag. When ON, Duplicates and UNIQUE constraint errors will be ignored.
  Caution is advised as other errors will be ignored during initial processing.

  In ALL cases,  DBRepair will never allow a bad database to be created.

### Import

  Imports (raw) watch history from another PMS database without ability to check validity
  ( This can have side effects of "negative watch count" being displayed.   Caution is advised. )


### Reindex

  Rebuilds the database indexes after an import, repair, or replace operation.
  These indexes are used by PMS for searching (both internally and your typed searches)

### Repair

  Extracts/recovers all the usable data from the existing databases into text (SQL ascii) form.
  Repair then creates new SQLite-valid databases from the extracted/recovered data.

  The side effect of this process is a fully defragmented database (optimal for Plex use).

  100% validity/usability by Plex  is not guaranteed as the tool cannot validate each individual
  record contained in the database.  It can only validate at the SQLite level.

  In most cases, Repair is the preferred option as the records extracted are only those SQLite deemed valid.

### Replace

  Looks through the list of available PMS backups.

  Starting with the most recent PMS backup,
    1.  Check the both db files
    2.  If valid, offer as a replacement choice
    3.  If accepted (Y/N question) then use as the replacement
        else advance to the next available backup
    4.  Upon completion, validate one final time.

### Quit

   Exits the utility but leaves the temporary databases intact (useful for making exhaustive backups)

### Show

  Shows the activity log.  The activity log is date/time stamped of all activity.

### Start

  On platform environments which support it, and when invoked by the 'root' user, the tool can start PMS.
  If not the 'root' user or on a platform which doesn't support it, "Not available" will be indicated.

### Stop

  On platform environments which support it,  and when invoked by the 'root' user,  the tool can stop PMS.
  If not the 'root' user or on a platform which doesn't support it, "Not available" will be indicated.

  PMS must be in the stopped state in order to operate on the database files.

#### Stopping / Starting in Containers  (Special Considerations)

  Stopping/starting PMS in containers depends on the container execution control mechanism

  Some images are designed with an "Always Running" philosophy and do not allow the tool to stop/
  start PMS while under program control.

  In these image types,  the only mechanism,  subject to time constraints of any health check,
  is to type:  kill -15 $(pidof 'Plex Media Server')
  at the container command line prior to invoking DBRepair.sh and waiting for PMS to shutdown.

  After DB tasks are completed, and you've exited the container,  restart it normally through
  your normal 'docker start' mechanism.

### Undo

  Undo allows you to "Undo" the last Import, Repair, Replace, or Vacuum command.
  At present, it only allows the ONE most recent operation.
  (Future will support undoing more actions)

### Vacuum

  Instructs SQLite to remove the empty/deleted records and gaps from the databases.
  This is most beneficial after deleting whole library sections.

###
