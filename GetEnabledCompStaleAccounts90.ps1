﻿Search-ADAccount -AccountInactive -Timespan 90 -ComputersOnly | Where-Object { $_.Enabled -eq $true } | Sort-Object LastlogonDate | Select-Object Name,DistinguishedName,LastlogonDate | Export-Csv C:\temp\CompAccnt90Days.csv