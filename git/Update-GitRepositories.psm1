# (c) 2022 Andrey Veselov.
# Released under MIT License.
# https://github.com/VeselovAndrey/powershell-scripts

# This module contains 3 PowerShell functions to update all git repositories in the specified or current folder:
# * Fetch-GitRepos
# * Pull-GitRepos
# * Optimize-GitRepos
# Prerequisite: git command line tool available.

# Core function to do repository updates.
function UpdateAllGitRepos {
    param (
        [string] $Path,
        [string] $PreparationAction = $null,
        [string] $PreparationActionParams = $null,
        [string] $Action,
        [string] $ActionParams = $null,
        [string] $CompletionAction = $null,
        [string] $CompletionActionParams = $null,
        [string] $IncludeBranches = $null,        
        [switch] $ScanSubdirectories = $false,
        [switch] $ShowBranchName = $false,
        [switch] $Version = $false,
        [switch] $MuteFinalMessage = $false
    )

    if ($Version) {
        "1.4.0"
        return;
    }
    
    $textColor = "DarkYellow"
    $gitTextColor = "DarkGray"
    $successTextColor = "Green"
    $warningTextColor = "Yellow"
    $titleColor = "White"
    $titleBgColor = "Black"
    $originalTextColor = $Host.UI.RawUI.ForegroundColor 

    $Host.UI.RawUI.ForegroundColor = $gitTextColor;

    $folders = Get-ChildItem -Path $Path -Directory
    $startLocation = Get-Location
 
    foreach ($currentFolder in $folders) {
        $hasGit = (Get-ChildItem -Force -Directory $currentFolder -Filter ".git").Count -gt 0

        if ($hasGit -eq $true) {
            Set-Location $currentFolder
            $originalBranchName = git symbolic-ref --short HEAD
            
            Write-Host "Updating $currentFolder..." -ForegroundColor $titleColor -BackgroundColor $titleBgColor

            # Check current branch for changes...
            $gitStatus = git status -suno
            if ($gitStatus.Length -ne 0) {
                Write-Host "Current branch '$originalBranchName' has uncommitted changes. Operation skipped. Moving to next repository..." -ForegroundColor $warningTextColor
                ""
                continue;
            }

            # Build branches list...
            $branchesList = $null;
            if (-not [string]::IsNullOrEmpty($IncludeBranches)) {
                $branchesList = "$originalBranchName,$IncludeBranches";
            }
            else {
                $branchesList = $originalBranchName; 
            }
            
            if (-not [string]::IsNullOrEmpty($PreparationAction)) {
                git $PreparationAction $PreparationActionParams
            }

            $branches = $branchesList.Split(",") | ForEach-Object -Process { $_.Trim() } | Get-Unique -AsString

            # Executing operation on every branch in the list...
            foreach ($branchName in $branches) {
                $currentBranchName = git symbolic-ref --short HEAD

                if ($branchName -ne $currentBranchName) {
                    Write-Host "Switching to branch: $branchName" -ForegroundColor $textColor
                    git switch $branchName --quiet
                
                    if ($LASTEXITCODE -ne 0) {
                        Write-Host "Can't switch to '$branchName' branch. Possibly it's not exist or was not checkout into current local repository." -ForegroundColor $warningTextColor
                        continue;
                    }
                }

                if ($ShowBranchName) {
                    Write-Host "Updating branch: $branchName" -ForegroundColor $textColor
                }

                git $Action $ActionParams              
            }

            # Switch back to original branch...
            $finalBranchName = git symbolic-ref --short HEAD
            if ($originalBranchName -ne $finalBranchName) {
                Write-Host "Switching back to branch: $originalBranchName" -ForegroundColor DarkYellow
                git switch $originalBranchName --quiet
            }

            if (-not [string]::IsNullOrEmpty($CompletionAction)) {        
                git $CompletionAction $CompletionActionParams
            }

            ""
        }
        elseif ($ScanSubdirectories -eq $true) {
            $subPath = $Path + "\" + $currentFolder.Name

            UpdateAllGitRepos `
                -Path:$subPath `
                -PreparationAction:$PreparationAction `
                -PreparationActionParams:$PreparationActionParams `
                -Action:$Action `
                -ActionParams:$ActionParams `
                -CompletionAction:$CompletionAction `
                -CompletionActionParams:$CompletionActionParams `
                -IncludeBranches:$IncludeBranches `
                -ScanSubdirectories:$ScanSubdirectories `
                -ShowBranchName:$ShowBranchName  `
                -Version:$Version `
                -MuteFinalMessage:$true
        }
    }

    Set-Location $startLocation

    if ($MuteFinalMessage -eq $false) {
        Write-Host "Operation completed." -ForegroundColor $successTextColor
    }

    $Host.UI.RawUI.ForegroundColor = $originalTextColor;
}

# Provides functionality to write help information.
function Write-Help {
    param (
        [string] $Name,
        [string] $TopLine,
        [switch] $EnableIncludeBranches = $false,
        [string] $HelpUrl = $null
    )

    $cmdLine = "$Name [-Path <string>] "
    if ($EnableIncludeBranches) { $cmdLine += "[-IncludeBranches <string>] " }
    $cmdLine += "[-Params <string>] [-Help]"

    "TOPIC"
    "`t Git tools"
    ""
    "SHORT DESCRIPTION"
    Write-Host "`t $TopLine" -ForegroundColor Green
    ""
    "SYNTAX"
    "`t $cmdLine"
    ""
    "PARAMETERS"
    "`t -Path - specifies the folder to search for repositories. Current folder will be used if this parameter is not specified."

    if ($EnableIncludeBranches) {
        "`t -IncludeBranches - specifies comma separated list of branches to update. This option will be ignored if currently selected branch have uncommitted changes."  
    }
    "`t -ScanSubdirectories - scans all subdirectories for additional git repositories if set to true."      
    "`t -Params - specifies any additional GIT parameters to execute. E.g. '-Params --prune'."
    
    if ($HelpUrl -ne $null) {
        "`t`t See following page for list of available GIT parameters."
        Write-Host "`t`t $HelpUrl" -ForegroundColor Blue
    }

    "`t -Help - shows this help."
}

# Fetches all git repositories.
function Fetch-GitRepos {
    param (
        [string] $Path = $null,
        [string] $Params = $null, 
        [switch] $ScanSubdirectories = $false,
        [switch] $Help = $false,
        [switch] $Version = $false
    )

    if ($Help) {
        Write-Help "Fetch-GitRepos" "Fetching all GIT repositories located in the current or the specified folder." "https://git-scm.com/docs/git-fetch"
        return;
    }

    if ($Version) {
        UpdateAllGitRepos -Version
        return;
    }

    if (!$Path) { $Path = Get-Location }
    Write-Host "Fetching all GIT repositories in folder $Path" -ForegroundColor Green
    ""
    UpdateAllGitRepos `
        -Path:$Path `
        -ActionParams fetch `
        -Params:$Params `
        -ScanSubdirectories:$ScanSubdirectories
}

# Pulls all git repositories.
function Pull-GitRepos {
    param (
        [string] $Path = $null,
        [string] $IncludeBranches = $null,
        [string] $Params = $null,
        [switch] $ScanSubdirectories = $false,
        [switch] $Help = $false,
        [switch] $Version = $false
    )

    if ($Help) {
        Write-Help "Pull-GitRepos" "Pulling all GIT repositories located in the current or the specified folder." "https://git-scm.com/docs/git-pull" -EnableIncludeBranches
        return;
    }

    if ($Version) {
        UpdateAllGitRepos -Version
        return;
    }
    
    if (!$Path) { $Path = Get-Location }
    Write-Host "Pulling all GIT repositories in folder $Path" -ForegroundColor Green
    ""
    UpdateAllGitRepos -Path:$Path `
        -PreparationAction fetch `
        -PreparationActionParams:$Params `
        -Action merge `
        -IncludeBranches:$IncludeBranches `
        -ShowBranchName `
        -ScanSubdirectories:$ScanSubdirectories
}

# Optimizes (git gc) all git repositories.
function Optimize-GitRepos {
    param (
        [string] $Path = $null,
        [string] $Params = $null,
        [switch] $ScanSubdirectories = $false,
        [switch] $Help = $false,
        [switch] $Version = $false
    )
    
    if ($Help) {
        Write-Help "Optimize-GitRepos" "Cleanup unnecessary files and optimize all GIT repositories located in the current or the specified folder." "https://git-scm.com/docs/git-gc"
        return;
    }

    if ($Version) {
        UpdateAllGitRepos -Version
        return;
    }

    if (!$Path) { $Path = Get-Location }
    Write-Host "Optimizing all GIT repositories in folder $Path" -ForegroundColor Green
    ""
    UpdateAllGitRepos `
        -Path:$Path `
        -Action 'gc' `
        -ActionParams:$Params `
        -IncludeBranches:$IncludeBranches `
        -ScanSubdirectories:$ScanSubdirectories
}

Export-ModuleMember -Function Fetch-GitRepos
Export-ModuleMember -Function Pull-GitRepos
Export-ModuleMember -Function Optimize-GitRepos