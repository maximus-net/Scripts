#V1.0
#Functional script with error logic
############### AD GROUP GLOBAL VARIABLES ########################
$global:Administrative             = 'Administrative'          
$global:RSAUsers                   = 'RSA Users'                       
$global:Compliance                 = 'Compliance'              
$global:VDIUsers                   = 'VDI Users'                       
$global:HR                         = 'HR'                          
$global:managementGS               = 'management-GS'             
$global:BDaccountingGS             = 'BD-accounting-GS'            
$global:BDcomplianceGS             = 'BD-compliance-GS'            
$global:BDlegalGS                  = 'BD-legal-GS'             
$global:BDclientserviceGS          = 'BD-clientservice-GS'  
$global:BDtechnologyGS             = 'BD-technology-GS'
$global:PicoLYNC                   = 'Pico-LYNC' 
$global:office365provision         = 'office365provision'
$global:employeesGS                = 'employees-GS'
$global:PicoCHI                    = 'Pico-CHI'
$global:PicoNYC                    = 'Pico-NYC'
$global:VDInycGS                   = 'VDInyc-GS'
$global:FolderRedirectionUKGS      = 'FolderRedirectionUK-GS'
$global:VDIukGS                    = 'VDIuk-GS'
$global:VDIchiGS                   = 'VDIchi-GS'
#Variables to fill in user information
$global:company                    = 'Pico Quantitative Trading'
#-------------------------------------------------------------
#The script will not work with out this
Import-Module ActiveDirectory

# Windows always wants to close the CLI if a script errors out:< We use this prompt, followed by the actual error, to give the user a chance to read what went wrong.
function error_prompt { Read-Host -Prompt "The script stopped executing. The above error occurred. Press Enter to exit."}


#This doesn't seem to work :( 
#Checking to see if the file containing the user info exists
#$FileExists = Test-Path $file 
#If ($FileExists -eq $False) 
#{
#Write-Host "User file does not exist"
#error_prompt
#exit
#}
#if ($FileExists -eq $True){continue}

#We change the format in the csv file so powershell will understand the data.
$users = convertfrom-csv ((gc ".\newusers_import.csv") -replace ",'", ',"' -replace "',", '",')
#This line is useless. Why do I have it in here?
#$file = "C:\Users\gmastrokostas.admin\Documents\scripts\onboard.csv"


#The loop starts where we read the information from the CSV file
foreach ($User in $users)            
{            
    #Variables used by the New-ADuser command. The new-ADuser command creates an AD account.
    $Firstname       = $User.Firstname            
    $Lastname        = $User.Lastname             
    $Password        = $User.Password
    $displayname     = $User.Firstname  +"."+ $User.Lastname
    $name            = $User.Firstname  +" "+ $User.Lastname 
    $OU              = $User.OU.Replace('-',',')           
    $Password        = $User.Password

    #Variables used by the Set-ADUser command. The Set-ADuser command adds informational data (title, job, department, etc)
    $Department      = $User.Department
    
    #In case the user name in the CSV file already exists in the PICO AD, the script will skip that name and move on to the next one in the CSV file
    $getuser         = Get-ADUser -Filter {Name -eq $name} | select -expand name
    if ($getuser -eq  $name) {continue}
    
    #Try to add new user and department attempt .....
    try
    {
    New-ADUser -Name $name -SamAccountName $displayname -DisplayName $name -userPrincipalName $displayname@picotrading.com -givenName $Firstname  -Surname $Lastname -Path $OU   -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -ChangePasswordAtLogon $false -PasswordNeverExpires $false -Enabled $true
    Set-ADUser        -Identity $displayname -Department $Department
    }

    # ....if we cannot add the new user/data then we write on a log file the error and notify the user on the CLI
    catch
    {
    Write-Output "ERROR: User" $displayname " could not be created in Active Directory. Check for format errors in CSV file or permissions of your account -- Stopping script" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    write-host   "ERROR:  User" $displayname " could not be created in Active Directory. Check for format errors in CSV file or permissions of your account -- Stopping script"
    #Prompt the user about the error before  Windows closes the CLI
    error_prompt
    #Script gets killed
    exit
    }

    #Try to edit special attributes for user ....
    try
    {
    Set-ADUser -Id $displayname -Add @{
               proxyAddresses = 'sip:'  + $displayname + '@picotrading.com'                  
            }  
    Set-ADUser -Id $displayname -Add @{
               proxyAddresses = 'SMTP:' + $displayname + '@picotrading.com'
            }
    Set-ADUser -Id $displayname -Add @{
               "msRTCSIP-PrimaryUserAddress" = 'sip:' + $displayname + '@picotrading.com'
            }
    }
    #.... If that cannot be done then we write on a log file the error and notify the user on the CLI 
    catch
    {
    Write-Output "ERROR: User " $displayname  " Problem setting msRTCSIP-PrimaryUserAddress and proxyaddress Special Attributes. Please check. -- Stopping script" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    Write-Output "Status of AD Account: Account has been created. Group membership and Attribute manipulation has not been completed "  | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    write-host   "ERROR: User " $displayname  " Problem setting msRTCSIP-PrimaryUserAddress and proxyaddress Special Attributes. Please check. -- Stopping script"
    write-host   "Status of AD Account: Account has been created. Group membership and Attribute manipulation has not been completed "
   #Prompt the user about the error before  Windows closes the CLI
    error_prompt
    #Script gets killed
    exit
    }

    #We are adding the users to the default groups. These are groups everyone belongs to.
    try
    {
    Add-ADGroupMember -Identity $PicoLYNC           -Member $displayname
    Add-ADGroupMember -Identity $office365provision -Member $displayname
    Add-ADGroupMember -Identity $employeesGS        -Member $displayname
    }
    # ...if we cannot add users to the default groups then we write on a log file the error and notify the user on the CLI
    catch
    {
    Write-Output "ERROR: User " $displayname " User Created - Special Attributes added but Problem assigning to Default groups Please check. -- Stopping script" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    Write-Output "Status of AD Account: Account has been created. Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set. User has not been assigned to any groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    write-host  "ERROR: User " $displayname " User Created - Special Attributes added but Problem assigning to Default groups Please check. -- Stopping script"
    wrote-host  "Status of AD Account: Account has been created. Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set. User has not been assigned to any groups"
    #Prompt the user about the error before  Windows closes the CLI
    error_prompt
    exit
    }
#-----------------------------------------------------------------------------------------------------

#Try to add the user to the proper groups according to geographical locations according to the information in the CSV file.
try
{
   if (write-output $OU |  select-string 'Chicago'){
    Add-ADGroupMember -Identity $PicoCHI                -Member  $displayname
    Add-ADGroupMember -Identity $VDIchiGS               -Member  $displayname
    Set-ADUser        -Identity $displayname  -city "Chicago"   -Office "Chicago" -email $displayname@picotrading.com 
    Write-Output $displayname
    Write-Output $name
   }
   }
# ....if we cannot add users to groups according to geographical location then we write on a log file the error and notify the user on the CLI
   catch
   {
    Write-Output $displayname " Problem assigning to Chicago groups. -- Stopping script" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    Write-Output $displayname " Status of AD Account: User Created - Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set - user has been assigned to default groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    write-output $displayname " User has Not been assigned to the Chicago groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"

    Write-host $displayname " Problem assigning to Chicago groups. -- Stopping script" 
    Write-host $displayname " Status of AD Account: User Created - Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set - user has been assigned to default groups" 
    write-host $displayname " User has Not been assigned to the Chicago groups" 
    error_prompt

    exit
    }
#Try to add the user to the proper groups according to geographical locations according to the information in the CSV file.
#We assign the Brazilian employees to the Chicago OU(s)
try
{
   if (write-output $OU |  select-string 'Brazil'){
    Add-ADGroupMember -Identity $PicoCHI                -Member  $displayname
    Add-ADGroupMember -Identity $VDIchiGS               -Member  $displayname
    Set-ADUser        -Identity $displayname  -city "Brazil"   -Office "Brazil" -email $displayname@picotrading.com  -company $global:company 
    Write-Output $displayname
    Write-Output $name
   }
 }
 # ....if we cannot add users to groups according to geographical location then we write on a log file the error and notify the user on the CLI
 catch
   {
     Write-Output $displayname " Problem assigning to Brazil groups. -- Stopping script" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    Write-Output $displayname " Status of AD Account: User Created - Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set - user has been assigned to default groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    write-output $displayname " User has Not been assigned to the Brazil groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"

    Write-host $displayname " Problem assigning to Brazil groups. -- Stopping script" 
    Write-host $displayname " Status of AD Account: User Created - Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set - user has been assigned to default groups" 
    write-host $displayname " User has Not been assigned to the Brazil groups" 
    error_prompt

    exit
    }
#Try to add the user to the proper groups according to geographical locations according to the information in the CSV file.
try
{
  if (write-output $OU |  select-string 'New York'){
   Add-ADGroupMember -Identity $PicoNYC            -Member  $displayname
   Add-ADGroupMember -Identity $VDInycGS           -Member  $displayname
   Set-ADUser        -Identity $displayname -city "NYC"   -Office "NYC"  -email $displayname@picotrading.com  -company $global:company  
   Write-Output $displayname
   Write-Output $name
   }
 }
# ....if we cannot add users to groups according to geographical location then we write on a log file the error and notify the user on the CLI
 catch
   {
    Write-Output $displayname " Problem assigning to New York groups. -- Stopping script" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    Write-Output $displayname " Status of AD Account: User Created - Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set - user has been assigned to default groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    write-output $displayname " User has Not been assigned to the New York groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"

    Write-host $displayname " Problem assigning to New York groups. -- Stopping script" 
    Write-host $displayname " Status of AD Account: User Created - Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set - user has been assigned to default groups" 
    write-host $displayname " User has Not been assigned to the New York groups" 

    error_prompt

    exit
    }
#Try to add the user to the proper groups according to geographical locations according to the information in the CSV file.
try
{
  if (write-output $OU |  select-string 'London'){
   Add-ADGroupMember -Identity $FolderRedirectionUKGS            -Member  $displayname
   Add-ADGroupMember -Identity $VDIukGS                          -Member  $displayname
   Set-ADUser        -Identity $displayname -city "London"  -Office "London"  -email $displayname@picotrading.com  -company $global:company 
   Write-Output $displayname
   Write-Output $name
   }  
}
# ....if we cannot add users to groups according to geographical location then we write on a log file the error and notify the user on the CLI
catch
   {
    Write-Output $displayname " Problem assigning to London groups. -- Stopping script" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    Write-Output $displayname " Status of AD Account: User Created - Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set - user has been assigned to default groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"
    write-output $displayname " User has Not been assigned to the London groups" | out-file -Append "error-log $(get-date -f yyyy-MM-dd).log"

    Write-host $displayname " Problem assigning to London groups. -- Stopping script" 
    Write-host $displayname " Status of AD Account: User Created - Attributes msRTCSIP-PrimaryUserAddress and proxyaddress have been set - user has been assigned to default groups" 
    write-host $displayname " User has Not been assigned to the London groups" 
    error_prompt
    exit
    }
Write-host "-------------------------------------------------------" | out-file -Append "addedUers_log $(get-date -f yyyy-MM-dd).txt"
get-aduser -identity $displayname   | select name | out-file -Append "addedUers_log $(get-date -f yyyy-MM-dd).txt"
get-aduser -identity $displayname   | select-object distinguishedname | out-file -Append "addedUers_log $(get-date -f yyyy-MM-dd).txt"
get-ADPrincipalGroupMembership $displayname | select name | out-file -Append "addedUers_log $(get-date -f yyyy-MM-dd).txt"
Write-host "-------------------------------------------------------" | out-file -Append "addedUers_log $(get-date -f yyyy-MM-dd).txt"
}