Import-Module ActiveDirectory
cd AD:

$MemberList = New-Item -Type file -Force “C:\Scripts\GroupMembers.csv”

Import-Csv “C:\scripts\grps.csv” | ForEach-Object {
	$GName = $_.Samaccountname
	$group = Get-ADGroup $GName
	$group.Name | Out-File $MemberList -Encoding Unicode -Append
		foreach ($member in Get-ADGroupMember $group) {$member.SamaccountName | Out-File $MemberList -Encoding Unicode -Append}
$nl = [Environment]::NewLine | Out-File $MemberList -Encoding ASCII -Append
}

