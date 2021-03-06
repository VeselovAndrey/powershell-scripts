# How to install a PowerShell module

1. Open PowerShell profile file. You can find is by checking ```$PROFILE``` variable. E.g. ```code $PROFILE``` to open PowerShell profile using Visual Studio Code.

2. Add following line to load module on every PowerShell start:
```ps
Import-Module "[Module file name with full path].psm1" -DisableNameChecking
``` 
"-DisableNameChecking" can be required because some function names starts with unapproved verbs like "Pull".

3. Restart PowerShell.

# PowerShell scripts

At this time this repository contains only 1 PowerShell module:

## Update-GitRepositories.psm1
This module contains 3 PowerShell functions to update all git repositories in the specified or current folder:
* Fetch-GitRepos - fetches all repositories.
* Pull-GitRepos - pull all repositories.
* Optimize-GitRepos - optimizes all repositories.

Every function has ```-Help``` available.