$GroupList = Get-ADGroup -Filter * -Properties Name, DistinguishedName, `
        GroupCategory, GroupScope, whenCreated, whenChanged, member, `
        memberOf, Description |            
    Select-Object Name, DistinguishedName, GroupCategory, GroupScope, `
        whenCreated, whenChanged, member, memberOf, `
        Description, `
        @{name='MemberCount';expression={$_.member.count}}, `
        @{name='MemberOfCount';expression={$_.memberOf.count}}, `
        @{name='DaysSinceChange';expression=`
            {[math]::Round((New-TimeSpan $_.whenChanged).TotalDays,0)}} |            
    Sort-Object Name            
            
$GroupList |            
    Select-Object Name, Description, DistinguishedName, `
        GroupCategory, GroupScope, whenCreated, whenChanged, DaysSinceChange, `
        MemberCount, MemberOfCount |            
    Export-CSV .\GroupList.csv -NoTypeInformation