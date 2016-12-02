Write-Host "Starting VDA-1 Collection at"  (get-date).ToString('HH:mm:ss')
cd ..

# Sets the Working Folder and Time Stamp Variables
$USB_drive = (Get-WmiObject Win32_Volume -Filter 'label = "VDA1"').name
$folderDateTime = (get-date).ToString('M-d-yyyy HHmmss')
$userDir = $USB_drive + 'Reports\VDA_1_' + $folderDateTime
$fileSaveDir = New-Item  ($userDir) -ItemType Directory 
$date = get-date
$C_User = [Environment]::UserName
$Host_Name = (Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty name)

# Creates the Base Report HTML file
$style = "
<style> table
{Margin: 0px 0px 0px 6px;Border: 1px solid rgb(190, 190, 190);Font-Family: Tahoma;Font-Size: 12pt;Background-Color: rgb(252, 252, 252);width: 100%;}
tr:hover td {Background-Color: rgb(0, 0, 0);Color: rgb(255, 255, 255);tr:nth-child(even){Background-Color: rgb(242, 242, 242);}
</style>"
$style1 = "
<style> table
{Margin: 0px 0px 0px 4px;Border: 1px solid rgb(190, 190, 190);Font-Family: Tahoma;Font-Size: 12pt;Background-Color: rgb(252, 252, 252);}
tr:hover td {Background-Color: rgb(0, 0, 0);Color: rgb(255, 255, 255);tr:nth-child(even){Background-Color: rgb(242, 242, 242);}
td{Vertical-Align: Top;Padding: 1px 4px 1px 4px;}
th{Text-Align: Left;Color: rgb(150, 150, 220);Padding: 1px 4px 1px 4px;}
#body {padding:50px;font-family: Helvetica; font-size: 12pt; border: 10px solid black;background-color:white;height:100%;overflow:auto;}
#left{float:left;background-color:#C0C0C0;width:45%;height:260px;border: 4px solid black;padding:10px;margin:10px;overflow:scroll;}
#right{background-color:#C0C0C0;float:right;width:45%;height:260px;border: 4px solid black;padding:10px;margin:10px;overflow:scroll;}
#center{background-color:#C0C0C0;width:98%;height:300px;border: 4px solid black;padding:10px;overflow:scroll;margin:10px;}
</style>"
$Report_Net = ConvertTo-Html -Title 'VDA-1 Network Report' -Body $style  > $fileSaveDir'/VDA_1_'$Host_Name'_Network_Info.html'
$Report_Com = ConvertTo-Html -Title 'VDA-1 Computer Report' -Body $style  > $fileSaveDir'/VDA_1_'$Host_Name'_Computer_Info.html'
$Report_Net = $Report_Net + "<div id=body><h1>VAST  VDA-1 &nbsp;&nbsp;&nbsp;&nbsp; $Host_Name &nbsp;&nbsp;&nbsp;   Network Information Report</h1><hr size=2><br><h3> Examination on: $Date </h3><h4> Running from User Account: $C_User </h4><br>"
$Report_Com = $Report_Com + "<div id=body><h1>VAST  VDA-1 &nbsp;&nbsp;&nbsp;&nbsp; $Host_Name &nbsp;&nbsp;&nbsp;   Computer Information Report</h1><hr size=2><br><h3> Examination on: $Date </h3><h4> Running from User Account: $C_User </h4><br>"



##############   Computer Report   #################

Write-Host "Collecting Computer Infomation at"  (get-date).ToString('HH:mm:ss')

# ADDS Computer Information to HTML Report
$Ram = @{ expression={[math]::Round($_.TotalPhysicalMemory / 1GB)}; label='Ram Install (GB) '}
$System_Info = Get-WMIObject Win32_ComputerSystem |Select Manufacturer,Model,Name,Domain ,$Ram  | ConvertTo-Html -As LIST 
$Report_Com = $Report_Com + "<h2>Computer Information</h2>"
$Report_Com = $Report_Com + $System_Info

# Bios Information
$SysBioVer = @{ expression={$_.SMBIOSBIOSVersion}; label='System Management BIOS Version'}
$Bios_info = Get-WmiObject win32_bios |Select Name,Manufacturer,Version,$SysBioVer,SerialNumber| ConvertTo-Html -As LIST
$Report_Com = $Report_Com + "<h2>Bios Infomation</h2>"
$Report_Com = $Report_Com + $Bios_Info

# CPU Infomation
$Report_Com = $Report_Com + "<h2>CPU Information</h2><br>"
$CPU_Info = Get-WmiObject Win32_Processor | Select-Object Manufacturer,Caption,Name,DeviceID,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,L2CacheSize,L3CacheSize  | ConvertTo-Html -As LIST
$Report_Com = $Report_Com + $CPU_Info

# Operating System Information
$Install = @{n="Installed Date";e={$_.ConvertToDateTime($_.InstallDate)}}
$LastBoot = @{n="Last Boot Up";e={$_.ConvertToDateTime($_.LastBootUpTime)}}
$Name_Com = @{ expression={$_.PSComputerName}; label='Computer Name'}
$System_OS = @{ expression={$_.name}; label='System OS'}

$OS_Info = Get-WmiObject Win32_OperatingSystem | Select $Name_Com,Manufacturer,$System_OS,OSArchitecture,RegisteredUser,
SerialNumber,$Install,BuildNumber,Version,$LastBoot,NumberOfUsers| ConvertTo-Html -As List
$Report_Com = $Report_Com + "<h2>Operating System Infomation</h2>"
$Report_Com = $Report_Com + $OS_Info


# ADDs User Infomration to Report
$User_Info = Get-WmiObject -class Win32_UserAccount| Select @{Expression={$_.name};Label = 'Name'}, AccountType, SID, PasswordRequired, LocalAccount, Status  | ConvertTo-Html
$Report_Com = $Report_Com + "<h2>User Information</h2><br>" + $User_Info

# Start Up Processes
#$Start_Up = Get-CimInstance Win32_StartupCommand | Select-Object Name, User, Command, Location | ConvertTo-Html
#$Report_Com = $Report_Com + "<h2>Start Up Processes</h2><br>" + $Start_Up

# ADDs Running Services
$Report_Com = $Report_Com + "<h2>Running Services</h2><br>"
$Report_Com = $Report_Com + (Get-Service | Where-Object {$_.status -eq "running"} |
Select Name, DisplayName,Status,ServiceType,StartType |ConvertTo-Html)


# ADDs Running Processes
$Report_Com = $Report_Com + "<h2>Running Processes</h2><br>"
$Report_Com = $Report_Com + (Get-Process |Select Name, Id, Path| ConvertTo-Html)


###############   Network Report    ################

Write-Host "Collecting Network Infomation at"  (get-date).ToString('HH:mm:ss')


# ADDs Active Network Cards
$Report_Net = $Report_Net + "<h2>Network Adapter Information</h2><br>"
$Report_Net = $Report_Net + (Get-WmiObject Win32_NetworkAdapterConfiguration -filter 'IPEnabled= True'|
 Select Description,DNSHostname, @{Name='IP Address ';Expression={$_.IPAddress}}, MACAddress | ConvertTo-Html)

#ADDs Network Shares
$Report_Net = $Report_Net + "<h2>Active Network Shares</h2><br>"
$netshare = get-WmiObject -class Win32_Share | Select name, Description, status, path, ClassPath, InstallDate | ConvertTo-Html
$Report_Net = $Report_Net + $netshare

# ADDs Active Network Connections
$netstat = netstat -ano
$netstat_data = $netstat[4..$netstat.count]
$netstat_format = FOREACH ($line in $netstat_data)
{
    
    # Remove the whitespace at the beginning on the line
    $line = $line -replace '^\s+', ''
    
    # Split on whitespaces characteres
    $line = $line -split '\s+'
    
    # Define Properties
    $properties = @{
        Protocol = $line[0]
        "Local Address IP" = ($line[1] -split ":")[0]
        "Local Port" = ($line[1] -split ":")[1]
        "Foreign Address IP" = ($line[2] -split ":")[0]
        "Foreign Port" = ($line[2] -split ":")[1]
        State = $line[3]
        PID = $line[4]
    }
    
    # Output object
    New-Object -TypeName PSObject -Property $properties
}
$netstat_html = $netstat_format | ConvertTo-Html
$Report_Net = $Report_Net + "<h2>Active Network Connections</h2><br>"
$Report_Net = $Report_Net + $netstat_html

##############    Final Steps    #################


# Finalizes Table
$Report_Net = $Report_Net + '</table></div>'
$Report_Com = $Report_Com + '</table></div>'

# Saves the File to Drive
$Report_Net >> $fileSaveDir'/VDA_1_'$Host_Name'_Network_Info.html'
$Report_Com >> $fileSaveDir'/VDA_1_'$Host_Name'_Computer_Info.html'


Write-Host "Finished Collection at"  (get-date).ToString('HH:mm:ss')
start-sleep 2

# Display on Screen
cd $fileSaveDir
Write-Host "Launching Reports"  (get-date).ToString('HH:mm:ss')

#Invoke-Item .\VDA_1*_Network_Info.html
Invoke-Item .\VDA_1*_Network_Info.html ; start-sleep 1 ; Invoke-Item .\VDA_1*_Computer_Info.html 

exit
