# Sets the Working Folder and Time Stamp Variables
$USB_drive = (Get-WmiObject Win32_Volume -Filter 'label = "VDA"').name
$folderDateTime = (get-date).ToString('d-M-y HHmmss')
cd ..
$userDir = $USB_drive + 'Reports\VDA_1_' + $folderDateTime
$fileSaveDir = New-Item  ($userDir) -ItemType Directory 
$date = get-date


# Creates the Base Report HTML file
$style = "<style> table{Margin: 0px 0px 0px 4px;Border: 1px solid rgb(190, 190, 190);
Font-Family: Tahoma;Font-Size: 12pt;Background-Color: rgb(252, 252, 252);width: 100%;
}tr:hover td {Background-Color: rgb(0, 0, 0);Color: rgb(255, 255, 255);tr:nth-child(even){Background-Color: rgb(242, 242, 242);
} td{Vertical-Align: Top;Padding: 1px 4px 1px 4px;}th{Text-Align: Left;Color: rgb(150, 150, 220);Padding: 1px 4px 1px 4px;
}#body {padding:50px;font-family: Helvetica; font-size: 12pt; border: 10px solid black;background-color:white;height:100%;overflow:auto;}#left{float:left;
background-color:#C0C0C0;width:45%;height:260px;border: 4px solid black;padding:10px;margin:10px;overflow:scroll;}#right{background-color:#C0C0C0;float:right;width:45%;height:260px;
border: 4px solid black;padding:10px;margin:10px;overflow:scroll;}#center{background-color:#C0C0C0;width:98%;height:300px;border: 4px solid black;padding:10px;overflow:scroll;margin:10px;} </style>"
$Report = ConvertTo-Html -Title 'VDA-1 Report' -Head $style > $fileSaveDir'/VDA-1.html'
$Report = $Report + "<div id=body><h1>VAST  VDA-1 Report</h1><hr size=2><br><h3> Examination on: $Date </h3><br>"


# Sets Variables for Information
$SysCpu = Get-WmiObject Win32_Processor | Select Name
$Cpu = $SysCpu.Name 
$Host_Name = (Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty name)
$OS = (Get-WmiObject Win32_OperatingSystem -computername $env:COMPUTERNAME ).caption
$Ram = (Get-WmiObject Win32_PhysicalMemory | measure-object Capacity -sum).sum/1gb
$SysSerialNo = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $env:COMPUTERNAME)
$SerialNo = $SysSerialNo.SerialNumber
$UserInfo = Get-WmiObject -class Win32_UserAccount -namespace root/CIMV2 | Where-Object {$_.Name -eq $env:UserName}| Select AccountType,SID,PasswordRequired
$UserType = $UserInfo.AccountType
$UserSid = $UserInfo.SID

# ADDS Computer Information to HTML Report
$Report = $Report + "
<div id=body><h2>Computer Information</h2><br>
<table>
<tr><td>Host Name: </td><td>$Host_Name</td></tr>
<tr><td>Operating System: </td><td>$os</td></tr>
<tr><td>Serial Number: </td><td>$SerialNo</td></tr>
<tr><td>Processor: </td><td>$Cpu</td></tr>
<tr><td>System RAM: :</td><td>$Ram GB</td></tr>
</table><br>" 

# ADDs User Infomration to Report
$Report = $Report + "
<h2>User Information</h2><br>
<table>
<tr><td>User Name: </td><td>$env:USERNAME</td></tr>
<tr><td>Account Type: </td><td>$UserType</td></tr></tr>
<tr><td>User SID: </td><td>$UserSID</td></tr></table><br>"

# ADDs Active Network Cards
$Report = $Report + "<h2>Network Information</h2><br>"
$Report = $Report + (Get-WmiObject Win32_NetworkAdapterConfiguration -filter 'IPEnabled= True'|
 Select Description,DNSHostname, @{Name='IP Address ';Expression={$_.IPAddress}}, MACAddress | ConvertTo-Html)

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
    }
    
    # Output object
    New-Object -TypeName PSObject -Property $properties
}
$netstat_html = $netstat_format | ConvertTo-Html

$Report = $Report + "<h2>Active Network Connections</h2><br>"


$Report = $Report + $netstat_html


# ADDs Established TCP Connections (Windows 10, Windows PowerShell 5.0, Windows Server 2016)
#$Report = $Report + "<h2>Established TCP Connections</h2><br>"
#$NetTCP = (Get-NetTCPConnection –State Established |Select State,CreationTime,OwningProcess,LocalAddress,LocalPort,RemoteAddress,RemotePort | ConvertTo-Html)
#$Report = $Report + "$NetTCP"

#$Report = $Report + "<h2>Established TCP Connections Netstat</h2><br>"
#$netE = netstat -ano
#$net_F = @{Expression={$_.P2};Label="Proto"},@{Expression={$_.P3};Label="Local Address"},@{Expression={$_.P4};Label="Foreign Address"},@{Expression={$_.P5};Label="State"},@{Expression={$_.P6};Label="PID"}
#$netE_F = $netE[3..$netE.count] | ConvertFrom-String | select p2,p3,p4,p5,p6  | where p5 -eq 'established'| Select-Object $t | ConvertTo-Html
#$Report = $Report + "$netE_F"

# ADDs Running Services
$Report = $Report + "<h2>Running Services</h2><br>"
$Report = $Report + (Get-Service | Where-Object {$_.status -eq "running"} |
Select Name, DisplayName,Status,ServiceType,StartType |ConvertTo-Html)


# ADDs Running Processes
$Report = $Report + "<h2>Running Processes</h2><br>"
$Report = $Report + (Get-Process |Select Name, Id, Path| ConvertTo-Html)


# Finalizes Table
$Report = $Report + '</table></div>'

# Saves the File to Drive
$Report >> $fileSaveDir'/VDA-1.html'

# Display on Screen
cd $fileSaveDir
Invoke-Item .\VDA-1.html