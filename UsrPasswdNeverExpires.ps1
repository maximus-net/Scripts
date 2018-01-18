Import-Module ActiveDirectory

Search-ADAccount -PasswordNeverExpires -UsersOnly | Where-Object {$_.enabled -eq $true} | Select-Object Name,DistinguishedName | Export-Csv C:\temp\UsrPasswrdNeverExpire.csv