Import-Module ActiveDirectory

Get-ADUser -Filter * -SearchBase "OU=Service Accounts,DC=picotrading,DC=com" -ResultPageSize 0 -Properties CN,lastLogonTimestamp | Select-Object CN,@{n="lastLogonDate";e={[datetime]::FromFileTime($_.lastLogonTimestamp)}} > c:\temp\lastlogon.txt

