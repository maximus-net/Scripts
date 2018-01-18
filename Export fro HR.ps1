﻿Get-ADUser -Filter * -SearchBase "OU=PicoUsers,DC=picotrading,DC=com" -Properties DisplayName,EmailAddress,Title,department | where {$_.enabled -eq $true} |
Select-Object DisplayName,EmailAddress,Title,department | Export-Csv C:\temp\employees.csv