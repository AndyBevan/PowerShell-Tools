<#
.TODO
1. Remove the defaults
2. It's very noisy - switch out 

.PARAMETER RootPath
    The root directory where the folder to be renamed is located. This should be the parent
    directory of the old folder name.

.PARAMETER OldNamespacePrefix
    The name of the folder that you want to rename. The function will check for the existence 
    of this folder under the RootPath.

.PARAMETER NewNamespacePrefix
    The new name that you want to give to the folder. If the OldNamespacePrefix exists, the folder 
    will be renamed to this new name.

.EXAMPLE
    .\RenameSolutionNamespacesAndFixFolders.ps1 -RootPath "C:\Projects\TestProject" -OldNamespacePrefix "OldProject" -NewNamespacePrefix "NewProject"
    
    This will rename the folder 'OldProject' located in 'C:\Projects' to 'NewProject'.

.NOTES
    Ensure that you have the necessary permissions to rename folders in the specified RootPath.
    This function does not recursively rename subfolders, it only operates on the top-level folder
    specified by OldNamespacePrefix.

.LINK
    https://docs.microsoft.com/en-us/powershell/scripting/samples/sample-scripts-for-powershell
#>


[CmdletBinding(SupportsShouldProcess)]
# Parameters
param (
    [string]$SolutionFilePath,
    [string]$OldNamespacePrefix,
    [string]$NewNamespacePrefix
)

# Function to update the .sln file
function Update-SolutionFile {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$SlnFilePath,
        [string]$OldNamespacePrefix,
        [string]$NewNamespacePrefix
    )
    Write-Host ("Updating Solution Files")

    if (!(Test-Path $SlnFilePath)) {
        Write-Host "The solution file '$SlnFilePath' does not exist."
        return
    }

    # Read the content of the .sln file
    $slnContent = Get-Content -Path $SlnFilePath

    # Update the folder names in the .sln file
    $updatedContent = $slnContent -replace [regex]::Escape($OldNamespacePrefix), $NewNamespacePrefix

    # Write the updated content back to the .sln file
    if ($PSCmdlet.ShouldProcess($SlnFilePath, "Update namespace from '$OldNamespacePrefix' to '$NewNamespacePrefix'")) {
        Set-Content -Path $SlnFilePath -Value $updatedContent   
    }
}

function Rename-Files {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [string]$RootPath,
        [string]$OldNamespacePrefix,
        [string]$NewNamespacePrefix
    )
    Write-Host ("Renaming Files")

    # Step 2: Get the list of files to rename in the directory
    $filesToRename = Get-ChildItem -Path $RootPath -File -Filter "$OldNamespacePrefix*" -Recurse

    # Step 3: Rename each file found
    foreach ($file in $filesToRename) {
        $newFileName = $file.Name -replace "^$OldNamespacePrefix", $NewNamespacePrefix
        $newFilePath = Join-Path -Path $file.DirectoryName -ChildPath $newFileName

        # Step 4: Check if the renaming should proceed
        if ($PSCmdlet.ShouldProcess($file.FullName, "Rename file to '$newFilePath'")) {
            Rename-Item -Path $file.FullName -NewName $newFilePath
            Write-Verbose "Renamed '$($file.FullName)' to '$newFilePath'"
        } else {
            Write-Verbose "Rename operation for '$($file.FullName)' was skipped."
        }
    }

    # Inform if no files were found
    if ($filesToRename.Count -eq 0) {
        Write-Host "No files prefixed with '$OldNamespacePrefix' found in '$directory'."
    }
}

# Example usage
# Rename-Files -SlnFilePath "C:\Path\To\YourSolution.sln" -OldNamespacePrefix "OldNamespace" -NewNamespacePrefix "NewNamespace" -WhatIf


# Function to rename folders with support for -WhatIf and -Confirm, based on namespace prefixes
function Rename-Folders {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$RootPath,
        [string]$OldNamespacePrefix,
        [string]$NewNamespacePrefix
    )
    Write-Host ("Renaming Folders")
    # Define the array of folders to exclude
    $excludeFolders = @(".vs")

    # Get folders to rename, excluding those that are in the exclusion list
    $foldersToRename = Get-ChildItem -Path $RootPath -Directory -Filter "$OldNamespacePrefix*" -Recurse

    # Filter the unfiltered folders to exclude those in the exclusion array
    $foldersToRenameFiltered = $foldersToRename | Where-Object {
        $excludeMatch = $false
        foreach ($exclude in $excludeFolders) {
            if ($_.FullName -match "\\$exclude\\") {
                $excludeMatch = $true
                break
            }
        }
        return -not $excludeMatch
    }

    # Check if any matching folders were found
    if ($foldersToRenameFiltered.Count -eq 0) {
        Write-Host "No folders found with the prefix '$OldNamespacePrefix'."
        return
    }

    # Loop through each folder and rename it
    foreach ($folder in $foldersToRename) {
        # Construct the new folder name by replacing the OldNamespacePrefix with NewNamespacePrefix
        $newFolderName = $folder.Name -replace [regex]::Escape($OldNamespacePrefix), $NewNamespacePrefix

        # Define the full new path for the renamed folder
        $newFolderPath = Join-Path -Path $folder.Parent.FullName -ChildPath $newFolderName

        # Check if the folder should be renamed (WhatIf/Confirm support)
        if ($PSCmdlet.ShouldProcess("$($folder.FullName)", "Renaming to $newFolderPath")) {
            Rename-Item -Path $folder.FullName -NewName $newFolderPath
            Write-Host "Renamed folder '$($folder.FullName)' to '$newFolderPath'."
        }
    }
}

function Update-NamespaceInFiles {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$RootPath,                   # Root path to search for files
        [string]$OldNamespacePrefix,         # Old namespace prefix to find
        [string]$NewNamespacePrefix          # New namespace prefix to replace with
    )
    Write-Host ("Updating Namespaces In Files")

    # Hard-coded array of file extensions to search for.  (Done as an array to allow for easy customization for specific use cases)
    $fileExtensions = @("*.*")

    # Step 1: Loop through each file extension
    foreach ($extension in $fileExtensions) {
        # Step 2: Get all files with the specified extension
        $filesToUpdate = Get-ChildItem -Path $RootPath -File -Filter $extension -Recurse

        # Step 3: Process each file found
        foreach ($file in $filesToUpdate) {
            # Step 4: Read the content of the file
            $fileContent = Get-Content -Path $file.FullName -Raw

            # Step 5: Replace occurrences of OldNamespacePrefix with NewNamespacePrefix
            $updatedContent = $fileContent -replace [regex]::Escape($OldNamespacePrefix), $NewNamespacePrefix

            # Step 6: Check if any changes were made and update the file if so
            if ($fileContent -ne $updatedContent) {
                if ($PSCmdlet.ShouldProcess($file.FullName, "Update namespace from '$OldNamespacePrefix' to '$NewNamespacePrefix'")) {
                    # Write the updated content back to the file
                    Set-Content -Path $file.FullName -Value $updatedContent
                    Write-Verbose "Updated namespace in '$($file.FullName)'"
                } else {
                    Write-Verbose "Update operation for '$($file.FullName)' was skipped."
                }
            } else {
                Write-Verbose "No changes needed for '$($file.FullName)'."
            }
        }

        # Step 7: Inform if no files were found for the extension
        if ($filesToUpdate.Count -eq 0) {
            Write-Host "No files with extension '$extension' found in '$RootPath'."
        }
    }
}

function Remove-BuildFolders {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$RootPath                  # The root directory where the search begins
    )
    Write-Host ("Removing Old Build Folders")

    # Array of folder names to remove
    $foldersToRemove = "bin", "obj"

    # Step 1: Loop through each folder name in the array
    foreach ($folder in $foldersToRemove) {
        # Step 2: Find all directories matching the folder name under the RootPath
        $folders = Get-ChildItem -Path $RootPath -Directory -Recurse | Where-Object { $_.Name -in $foldersToRemove }

        # Step 3: Process each folder found
        foreach ($folderToDelete in $folders) {
            if ($PSCmdlet.ShouldProcess($folderToDelete.FullName, "Remove folder '$($folderToDelete.FullName)'")) {
                # Step 4: Remove the folder
                Remove-Item -Path $folderToDelete.FullName -Recurse -Force
                Write-Host "Removed folder '$($folderToDelete.FullName)'"
            } else {
                Write-Host "Skipped removing folder '$($folderToDelete.FullName)'"
            }
        }

        # Inform if no matching folders were found
        if ($folders.Count -eq 0) {
            Write-Host "No '$folder' folders found in '$RootPath'."
        }
    }
}

# Example usage
# Remove-SpecifiedFolders -RootPath "C:\Path\To\YourProject" -WhatIf


# Example usage
# Update-NamespaceInFiles -RootPath "C:\Path\To\YourDirectory" -OldNamespacePrefix "OldNamespace" -NewNamespacePrefix "NewNamespace" -WhatIf


# Example usage
# Update-NamespaceInFiles -RootPath "C:\Path\To\YourDirectory" -OldNamespacePrefix "OldNamespace" -NewNamespacePrefix "NewNamespace" -FileExtensions "*.cs", "*.txt" -WhatIf


# Main script logic
Write-Host "Starting the renaming process..."
$RootPath = Split-Path -Parent $SolutionFilePath

# Rename folders
Rename-Folders -RootPath $RootPath -OldNamespacePrefix $OldNamespacePrefix -NewNamespacePrefix $NewNamespacePrefix

# Update .sln file
Update-SolutionFile -SlnFilePath $SolutionFilePath -OldNamespacePrefix $OldNamespacePrefix -NewNamespacePrefix $NewNamespacePrefix
Rename-Files -RootPath $RootPath -OldNamespacePrefix $OldNamespacePrefix -NewNamespacePrefix $NewNamespacePrefix

# Update File Contents
Update-NamespaceInFiles -RootPath $RootPath -OldNamespacePrefix $OldNamespacePrefix -NewNamespacePrefix $NewNamespacePrefix

# Remove any old build folders
Remove-BuildFolders -RootPath $RootPath

Write-Host "Renaming process completed."
