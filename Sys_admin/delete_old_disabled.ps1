$OU = "OU=Disabled Users,DC={domain},DC=com"
$Days = 90
$OutputFile = "C:\Path\to\file\OldAccountsDeleted_$CurretnDate.csv"

# 90 days ago
$DateLimit = (Get-Date).AddDays(-$Days)

# Find disabled users 
$DisabledUsers = Get-ADUser -Filter {Enabled -eq $false -and LastLogonDate -lt $DateLimit} -SearchBase $OU -Property SamAccountName, Name, LastLogonDate, whenChanged

# CSV fike
$DisabledUsers | Select-Object SamAccountName, Name, LastLogonDate, whenChanged | Export-Csv -Path $OutputFile -NoTypeInformation

# Delete 
$DisabledUsers | ForEach-Object {
    Remove-ADUser -Identity $_.DistinguishedName -Confirm:$false
}

Write-Output "Disabled users have been exported to $OutputFile and deleted from Active Directory."
