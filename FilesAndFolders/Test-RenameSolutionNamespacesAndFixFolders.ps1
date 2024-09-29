# Define paths and parameters
$sourcePath = "C:\DevGit\Test-Rename-Script\Morg.FunctionalTestWithLocalStack\"
$solutionFileName = "Morg.LocalStack.Sample.sln"
$destinationPath = "C:\DevGit\Test-Rename-Script\Morg.FunctionalTestWithLocalStack - Copy"
$OldNamespacePrefix = "Morg.LocalStack.Sample"
$NewNamespacePrefix = "Dullahan.LocalStack.Sample"

# Step 1: Copy the test folder to a new location
Write-Host "Copying folder from '$sourcePath' to '$destinationPath'..."
Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
Write-Host "Folder copy completed."

# Step 2: Run the RenameSolutionNamespacesAndFixFolders script
$solutionFilePath = Join-Path $destinationPath $solutionFileName
Write-Host "Solution File Path: $solutionFilePath"

Write-Host "Running RenameSolutionNamespacesAndFixFolders script..."
.\RenameSolutionNamespacesAndFixFolders.ps1 -SolutionFilePath $solutionFilePath -OldNamespacePrefix $OldNamespacePrefix -NewNamespacePrefix $NewNamespacePrefix -Verbose #-WhatIf

# Remove -WhatIf to apply the changes instead of simulating them
