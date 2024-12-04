# ==========================================================================================================
#
# PS script to obtain the list of bitbucket branches for all repositories from a given project
# -----------------------------------------------------------------------------------
#
# Parameters to run this script
#
# 1. Provide the project key or name for the variable
# 2. Provide either the username or id or email address
# 3. Provide either the password or api token to authenticate
# 4. Provide your organisation's bitbucket base url
# ==========================================================================================================

# $ErrorActionPreference = "Stop"

$project = "<Bitbucket project key or name>" #Eg: project1234 or mybbproject
$baseUrl = "<Your org's bitbucket base url>" #Eg: https://myorg.bitbucket.com

$user = "<Your bitbucket user id or username or email address>"
$password = "<Password or api token to authenticate>" # API token is recommended as it takes away the issue of frequent password resets

# Forming credential object to invoke Bitbucket API
$pair = "$($user):$($password)"
$encodedCreds = [System.Text.Encoding]::UTF8.GetBytes($pair)
$encodedBase64 = [System.Convert]::ToBase64String($encodedCreds)
$basicAuthValue = "Basic $encodedBase64"
$authHeader = @{ Authorization = $basicAuthValue }

# Forming the url object
$bitbucketUrl = $baseUrl + "/rest/api/1.0/projects/" + $project + "/repos?limit=1000"

try {
    $repoRequest = Invoke-WebRequest -URI $bitbucketUrl -Method 'GET' -Headers $authHeader -ErrorAction Stop
} catch {
    Write-Host "`nAn error occurred while invoking the Bitbucket API." -f Red
    Write-Host "Error is --> $_" -f Red
    Write-Host "Aborting the execution here.`n" -f Red
    exit
}

try {
    $jsonObject = ConvertFrom-Json $repoRequest.Content
    $repoList = $jsonObject.values.name
    $repoCount = ($repoList | Measure-Object).count

    if(($null -eq $repoList) -or ($repoList -eq "") -or ($repoCount -eq 0)) {
        Write-Host "`n[$project] project has either 0 repositories or returned null or empty values.`n"
        Write-Host "Script exiting...`n"
        exit
    } elseif ($repoCount -gt 0) {
        Write-Host "`nTotal repo count in [$project] project is --> $repoCount"
        foreach ($repo in $repoList) {
			$getBranchesURL = $baseUrl + "/rest/api/1.0/projects/" + $project + "/repos/" + "$repo" + "/branches?limit=1000"
			
			$branchesRequest = Invoke-WebRequest -URI $getBranchesURL -Method 'GET' -Headers $authHeader -ErrorAction Stop
			$branchesJsonObject = ConvertFrom-Json $branchesRequest.Content
			$branchesCount = $branchesJsonObject.size
			$branchNamesList = $branchesJsonObject.values.displayId | Sort-Object
			$branchesCount = ($branchNamesList | Measure-Object).count
			
			if(($null -eq $branchNamesList) -or ($branchNamesList -eq "") -or ($branchesCount -eq 0)) {
				Write-Host "`n[$repo] repository has either 0 branches or returned null or empty values."
			} else if ($branchesCount -gt 0) {
				$exportCSVData = foreach ($branchName in $branchNamesList) {
					[PSCustomObject]@{
						Repository = $repo
						BranchName = $branchName
					}
				}
				$todayDate = Get-Date -Format "yyyy-MM-dd"
				$CSVFile = "C:\" + $project + "_Branch_List_" + $todayDate + ".csv"
				$exportCSVData | Export-CSV $CSVFile -Append -NoTypeInformation -Force
			}
		}
	Write-Host ""
    }
} catch {
    Write-Host "Error is --> $_" -f Red
}
