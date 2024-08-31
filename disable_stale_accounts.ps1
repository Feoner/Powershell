$Days = 90
$DisabledOU = "OU=Disabled Users,DC={domain},DC=com"
$DisabledUsersGroup = "Disabled_Users"

# 90 days ago
$DateLimit = (Get-Date).AddDays(-$Days)

# Get the PrimaryGroupToken of the "Disabled Users" group
$DisabledUsersGroupID = (Get-ADGroup -Filter {Name -eq $DisabledUsersGroup}).PrimaryGroupToken

# No log in for 90 days
$StaleUsers = Get-ADUser -Filter {LastLogonDate -lt $DateLimit -and Enabled -eq $true} -Property SamAccountName, Name, LastLogonDate, MemberOf, DistinguishedName, PrimaryGroupID

foreach ($User in $StaleUsers) {
    Disable-ADAccount -Identity $User.SamAccountName
    
    # Set the primary group to "Disabled_Users"
    Set-ADUser -Identity $User.SamAccountName -PrimaryGroupID $DisabledUsersGroupID
    
    # Remove user from all groups
    $Groups = Get-ADUser $User.SamAccountName -Property MemberOf | Select-Object -ExpandProperty MemberOf
    foreach ($Group in $Groups) {
        Remove-ADGroupMember -Identity $Group -Members $User.SamAccountName -Confirm:$false
    }
    
    # Move OU
    Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU

    Write-Output "User $($User.Name) has been disabled, set to primary group 'Disabled Users', removed from all other groups, and moved to the Disabled Users OU."
}
