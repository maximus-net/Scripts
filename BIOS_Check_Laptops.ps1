Get-ADComputer -Filter * -SearchBase "OU=CorpLaptops,OU=PicoComputers,DC=picotrading,DC=com" | Select-Object -ExpandProperty Name |
foreach {
if (Test-Connection $_ -Count 1 -Quiet)
    {
    Get-WmiObject -Class Win32_BIOS -ComputerName $_
    Get-WmiObject -Class Win32_ComputerSystem -ComputerName $_
    }
    Else { Add-Content -value $_ C:\temp\LaptopsOffline.txt }
}
