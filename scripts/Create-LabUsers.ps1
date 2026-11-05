<#
.SYNOPSIS
    Bulk-creates Active Directory users from a CSV for the AD home lab.
.DESCRIPTION
    Creates department OUs and security groups if missing, then creates each
    user in their department OU and adds them to the matching group.
    Run on the domain controller as a Domain Admin.
.EXAMPLE
    .\Create-LabUsers.ps1 -CsvPath .\users.csv
#>
param(
    [string]$CsvPath = ".\users.csv"
)

Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName
$domainDNS = (Get-ADDomain).DNSRoot

# Lab-only default password; users must change it at first logon.
$defaultPassword = Read-Host -AsSecureString "Enter the initial password for new lab users"

# Make sure the Groups OU exists
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Groups'" -SearchBase $domainDN -SearchScope OneLevel)) {
    New-ADOrganizationalUnit -Name "Groups" -Path $domainDN
    Write-Host "Created OU: Groups"
}
$groupsOU = "OU=Groups,$domainDN"

$users = Import-Csv -Path $CsvPath

foreach ($u in $users) {
    $dept = $u.Department
    $deptOU = "OU=$dept,$domainDN"
    $groupName = "SG-$dept"

    # Department OU
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$dept'" -SearchBase $domainDN -SearchScope OneLevel)) {
        New-ADOrganizationalUnit -Name $dept -Path $domainDN
        Write-Host "Created OU: $dept"
    }

    # Department security group
    if (-not (Get-ADGroup -Filter "Name -eq '$groupName'")) {
        New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -Path $groupsOU
        Write-Host "Created group: $groupName"
    }

    # Username: first initial + last name, lowercase (e.g., jsmith)
    $sam = ($u.FirstName.Substring(0,1) + $u.LastName).ToLower()

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Host "Skipped (already exists): $sam" -ForegroundColor Yellow
        continue
    }

    New-ADUser `
        -Name "$($u.FirstName) $($u.LastName)" `
        -GivenName $u.FirstName `
        -Surname $u.LastName `
        -SamAccountName $sam `
        -UserPrincipalName "$sam@$domainDNS" `
        -Title $u.Title `
        -Department $dept `
        -Path $deptOU `
        -AccountPassword $defaultPassword `
        -ChangePasswordAtLogon $true `
        -Enabled $true

    Add-ADGroupMember -Identity $groupName -Members $sam
    Write-Host "Created user: $sam ($dept) and added to $groupName" -ForegroundColor Green
}

Write-Host "`nDone. Users per department:"
$users | Group-Object Department | ForEach-Object { Write-Host "  $($_.Name): $($_.Count)" }
