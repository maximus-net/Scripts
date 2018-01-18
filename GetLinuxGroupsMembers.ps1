$LinuxGroups = Get-ADGroup -Filter * | Where-Object {$_.name -like "*Linux*"}

foreach($Group in $LinuxGroups)

{
Get-ADGroupMember -Identity $Group | select @{Expression={$Group};Label="Group Name"},samaccountname | Export-Csv C:\temp\$Group.txt -NoTypeInformation
}