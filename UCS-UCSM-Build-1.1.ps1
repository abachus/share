
#Import Required Modules
Import-Module Cisco.UCSManager -ErrorAction SilentlyContinue

#Global Variables
$ucsm1 = "10.1.12.204"
$ucsuser = "admin"
$ucspass = "C1sco123!"

#Login to UCS
Write-Host "UCS: Logging into UCS Domain $ucs"
#Set-UCS
$ucspasswd = ConvertTo-SecureString $ucspass -AsPlainText -Force
$ucscreds = New-Object System.management.automation.pscredential ($ucsuser, $ucspasswd)
$ucslogin = Connect-UCS -Credential $ucscreds -Name $ucsm1

#Create Maintenance Policies

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsCpmaintMaintPolicy -ModifyPresent -name default -policyOwner local -uptimeDisr 'user-ack' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsCpmaintMaintPolicy -ModifyPresent -name userack -policyOwner local -uptimeDisr 'user-ack' 


#Create Power Cap Policy

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsPowerPolicy -ModifyPresent -fanSpeed performance -name 'No-CAP' -policyOwner local -prio 'no-cap' 

#Create ext-mgmt-IP-pool
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsIpPool -ModifyPresent  -AssignmentOrder "sequential" -Descr "" -ExtManaged "internal" -Guid "00000000-0000-0000-0000-000000000000" -IsNetBIOSEnabled "disabled" -Name "ext-mgmt" -PolicyOwner "local" -SupportsDHCP "disabled"
$mo_1 = $mo | Add-UcsIpPoolBlock -ModifyPresent -DefGw "10.4.120.1" -From "10.4.120.10" -PrimDns "10.10.10.10" -SecDns "10.10.10.11" -Subnet "255.255.255.0" -To "10.4.120.100"
Complete-UcsTransaction

#Configure QoS System Class

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsQosPolicy -ModifyPresent -name Platinum -policyOwner local 
$mo_1 = $mo | Add-UcsVnicEgressPolicy -ModifyPresent -burst '10240' -hostControl none -prio platinum -rate 'line-rate' 

#Create VLANs

Get-UcsLanCloud | Add-UcsVlan -ModifyPresent  -CompressionType "included" -DefaultNet "no" -Id 10 -McastPolicyName "" -Name "10-hostmgmt" -PolicyOwner "local" -Sharing "none"

Get-UcsLanCloud | Add-UcsVlan -ModifyPresent  -CompressionType "included" -DefaultNet "no" -Id 11 -McastPolicyName "" -Name "11-vmotion" -PolicyOwner "local" -Sharing "none" 

Get-UcsLanCloud | Add-UcsVlan -ModifyPresent  -CompressionType "included" -DefaultNet "no" -Id 12 -McastPolicyName "" -Name "12-vmdata" -PolicyOwner "local" -Sharing "none" 

Get-UcsLanCloud | Add-UcsVlan -ModifyPresent  -CompressionType "included" -DefaultNet "yes" -Id 1 -McastPolicyName "" -Name "default" -PolicyOwner "local" -Sharing "none" 

#Create UUID Pools 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsUuidSuffixPool -ModifyPresent -assignmentOrder sequential -descr 'for UUID pool of domain 5B' -name 'FI05B-UUID-POOL' -policyOwner local -prefix '4EDCE4EC-7BCF-11E8' 
$mo_1 = $mo | Add-UcsUuidSuffixBlock -ModifyPresent -from '0000-5B0000000001' -to '0000-5B0000000100' 

#Create MAC Pools

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsMacPool -ModifyPresent -assignmentOrder sequential -descr 'for vNic 4 on Fabric B - HDFS' -name 'Fab-B4-MAC-POOL' -policyOwner local 
$mo_1 = $mo | Add-UcsMacMemberBlock -ModifyPresent -from '00:25:B5:5B:B4:00' -to '00:25:B5:5B:B4:FF' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsMacPool -ModifyPresent -assignmentOrder sequential -descr 'for vNic 0 on Fabric A - mgmt' -name 'Fab-A0-MAC-POOL' -policyOwner local 
$mo_1 = $mo | Add-UcsMacMemberBlock -ModifyPresent -from '00:25:B5:5B:A0:00' -to '00:25:B5:5B:A0:FF' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsMacPool -ModifyPresent -assignmentOrder sequential -descr 'for vNic 1 on Fabric A - ingest' -name 'Fab-A1-MAC-POOL' -policyOwner local 
$mo_1 = $mo | Add-UcsMacMemberBlock -ModifyPresent -from '00:25:B5:5B:A1:00' -to '00:25:B5:5B:A1:FF' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsMacPool -ModifyPresent -assignmentOrder sequential -descr 'for vNic 2 on Fabric A - query internal' -name 'Fab-A2-MAC-POOL' -policyOwner local 
$mo_1 = $mo | Add-UcsMacMemberBlock -ModifyPresent -from '00:25:B5:5B:A2:00' -to '00:25:B5:5B:A2:FF' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsMacPool -ModifyPresent -assignmentOrder sequential -descr 'for vNic 3 on Fabric A - query external' -name 'Fab-A3-MAC-POOL' -policyOwner local 
$mo_1 = $mo | Add-UcsMacMemberBlock -ModifyPresent -from '00:25:B5:5B:A3:00' -to '00:25:B5:5B:A3:FF'

#Create vNIC Templates

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsVnicTemplate -ModifyPresent -cdnSource 'vnic-name' -descr 'for HDFS' -identPoolName 'Fab-B4-MAC-POOL' -mtu '9000' -name 'vNIC-4-B' -policyOwner local -qosPolicyName Platinum -redundancyPairType none -statsPolicyName default -switchId 'B-A' -target adaptor -templType 'updating-template' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsVnicTemplate -ModifyPresent -cdnSource 'vnic-name' -descr 'for query internal' -identPoolName 'Fab-A2-MAC-POOL' -mtu '1500' -name 'vNIC-2-A' -policyOwner local -redundancyPairType none -statsPolicyName default -switchId 'A-B' -target adaptor -templType 'updating-template' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsVnicTemplate -ModifyPresent -cdnSource 'vnic-name' -descr 'for query external' -identPoolName 'Fab-A3-MAC-POOL' -mtu '1500' -name 'vNIC-3-A' -policyOwner local -redundancyPairType none -statsPolicyName default -switchId 'A-B' -target adaptor -templType 'updating-template' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsVnicTemplate -ModifyPresent -cdnSource 'vnic-name' -descr 'for management' -identPoolName 'Fab-A0-MAC-POOL' -mtu '1500' -name 'vNIC-0-A' -policyOwner local -redundancyPairType none -statsPolicyName default -switchId 'A-B' -target adaptor -templType 'updating-template' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsVnicTemplate -ModifyPresent -cdnSource 'vnic-name' -descr 'for Ingest' -identPoolName 'Fab-A1-MAC-POOL' -mtu '1500' -name 'vNIC-1-A' -policyOwner local -redundancyPairType none -statsPolicyName default -switchId 'A-B' -target adaptor -templType 'updating-template' 


#Create Storage Disk Groups

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "01-02-raid1" -PolicyOwner "local" -RaidLevel "mirror"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 1 -SpanId "unspecified"
$mo_2 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 2 -SpanId "unspecified"
$mo_3 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "platform-default" -Security "no" -StripSize "platform-default" -WriteCachePolicy "platform-default"
Complete-UcsTransaction -Force


Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "03-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 3 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "04-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 4 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "05-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 5 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "06-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 6 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "07-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 7 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "08-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 8 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "09-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 9 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "10-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 10 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "11-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 11 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "12-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 12 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "13-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 13 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force


Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsLogicalStorageDiskGroupConfigPolicy -ModifyPresent  -Descr "" -Name "14-RAID0" -PolicyOwner "local" -RaidLevel "stripe"
$mo_1 = $mo | Add-UcsLogicalStorageLocalDiskConfigRef -ModifyPresent -Role "normal" -SlotNum 14 -SpanId "unspecified"
$mo_2 = $mo | Set-UcsLogicalStorageVirtualDriveDef -AccessPolicy "platform-default" -DriveCache "platform-default" -IoPolicy "platform-default" -ReadPolicy "read-ahead" -Security "no" -StripSize "1024KB" -WriteCachePolicy "write-back-good-bbu"
Complete-UcsTransaction -Force

#Create Storage Profiles

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsLogicalStorageProfile -ModifyPresent -name 'HD-Master' -policyOwner local 
$mo_1 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '03-raid0' -lunMapType 'non-shared' -name '03-data' -order 'not-applicable' -size '1850' 
$mo_2 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '04-raid0' -lunMapType 'non-shared' -name '04-data' -order 'not-applicable' -size '1850' 
$mo_3 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '01-02-raid1' -lunMapType 'non-shared' -name '01-os' -order 'not-applicable' -size '1750' 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsLogicalStorageProfile -ModifyPresent -name 'HD-Worker' -policyOwner local 
$mo_1 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '11-raid0' -lunMapType 'non-shared' -name '11-data' -order 'not-applicable' -size '1850' 
$mo_2 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '10-raid0' -lunMapType 'non-shared' -name '10-data' -order 'not-applicable' -size '1850' 
$mo_3 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '13-raid0' -lunMapType 'non-shared' -name '13-data' -order 'not-applicable' -size '1850' 
$mo_4 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '03-raid0' -lunMapType 'non-shared' -name '03-data' -order 'not-applicable' -size '1850' 
$mo_5 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '12-raid0' -lunMapType 'non-shared' -name '12-data' -order 'not-applicable' -size '1850' 
$mo_6 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '04-raid0' -lunMapType 'non-shared' -name '04-data' -order 'not-applicable' -size '1850' 
$mo_7 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '05-raid0' -lunMapType 'non-shared' -name '05-data' -order 'not-applicable' -size '1850' 
$mo_8 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '14-raid0' -lunMapType 'non-shared' -name '14-data' -order 'not-applicable' -size '1850' 
$mo_9 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '06-raid0' -lunMapType 'non-shared' -name '06-data' -order 'not-applicable' -size '1850' 
$mo_10 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '07-raid0' -lunMapType 'non-shared' -name '07-data' -order 'not-applicable' -size '1850' 
$mo_11 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '08-raid0' -lunMapType 'non-shared' -name '08-data' -order 'not-applicable' -size '1850' 
$mo_12 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '09-raid0' -lunMapType 'non-shared' -name '09-data' -order 'not-applicable' -size '1850' 
$mo_13 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '01-02-raid1' -lunMapType 'non-shared' -name '01-os' -order 'not-applicable' -size '1750' 


$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsLogicalStorageProfile -ModifyPresent -name 'HD-Nifi' -policyOwner local 
$mo_1 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '01-02-raid1' -lunMapType 'non-shared' -name '01-os' -order 'not-applicable' -size '1750' 


$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsLogicalStorageProfile -ModifyPresent -name 'HD-Edge' -policyOwner local 
$mo_1 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '11-raid0' -lunMapType 'non-shared' -name '11-data' -order 'not-applicable' -size '1850' 
$mo_2 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '10-raid0' -lunMapType 'non-shared' -name '10-data' -order 'not-applicable' -size '1850' 
$mo_3 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '13-raid0' -lunMapType 'non-shared' -name '13-data' -order 'not-applicable' -size '1850' 
$mo_4 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '03-raid0' -lunMapType 'non-shared' -name '03-data' -order 'not-applicable' -size '1850' 
$mo_5 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '12-raid0' -lunMapType 'non-shared' -name '12-data' -order 'not-applicable' -size '1850' 
$mo_6 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '04-raid0' -lunMapType 'non-shared' -name '04-data' -order 'not-applicable' -size '1850' 
$mo_7 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '05-raid0' -lunMapType 'non-shared' -name '05-data' -order 'not-applicable' -size '1850' 
$mo_8 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '14-raid0' -lunMapType 'non-shared' -name '14-data' -order 'not-applicable' -size '1850' 
$mo_9 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '06-raid0' -lunMapType 'non-shared' -name '06-data' -order 'not-applicable' -size '1850' 
$mo_10 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '07-raid0' -lunMapType 'non-shared' -name '07-data' -order 'not-applicable' -size '1850' 
$mo_11 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '08-raid0' -lunMapType 'non-shared' -name '08-data' -order 'not-applicable' -size '1850' 
$mo_12 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '09-raid0' -lunMapType 'non-shared' -name '09-data' -order 'not-applicable' -size '1850' 
$mo_13 = $mo | Add-UcsLogicalStorageDasScsiLun -ModifyPresent -adminState online -autoDeploy 'auto-deploy' -deferredNaming no -expandToAvail no -fractionalSize '0' -localDiskPolicyName '01-02-raid1' -lunMapType 'non-shared' -name '01-os' -order 'not-applicable' -size '1750' 

#Create Boot Policy

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsBootPolicy -ModifyPresent -bootMode legacy -enforceVnicName yes -name 'local-lun' -policyOwner local -rebootOnUpdate no 
$mo_1 = $mo | Add-UcsLsbootVirtualMedia -ModifyPresent -access 'read-only-remote' -lunId '0' -order '2' 
$mo_2 = $mo | Add-UcsLsbootStorage -ModifyPresent -order '1' 
$mo_2_1 = $mo_2 | Add-UcsLsbootLocalStorage -ModifyPresent 
$mo_2_1_1 = $mo_2_1 | Add-UcsLsbootLocalHddImage -ModifyPresent -order '1' 

#Create Bios Policy


$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsBiosPolicy -ModifyPresent -descr 'for BIOS policy for Hadoop' -name 'HD-BIOS' -policyOwner local -rebootOnUpdate no 
$mo_1 = $mo | Get-UcsBiosVfUSBSystemIdlePowerOptimizingSetting | Set-UcsBiosVfUSBSystemIdlePowerOptimizingSetting -Force -vpUSBIdlePowerOptimizing 'platform-default' 
$mo_2 = $mo | Get-UcsBiosVfIntelTrustedExecutionTechnology | Set-UcsBiosVfIntelTrustedExecutionTechnology -Force -vpIntelTrustedExecutionTechnologySupport 'platform-default' 
$mo_3 = $mo | Get-UcsBiosVfIntegratedGraphicsApertureSize | Set-UcsBiosVfIntegratedGraphicsApertureSize -Force -vpIntegratedGraphicsApertureSize 'platform-default' 
$mo_4 = $mo | Get-UcsBiosVfIntelVirtualizationTechnology | Set-UcsBiosVfIntelVirtualizationTechnology -Force -vpIntelVirtualizationTechnology disabled 
$mo_5 = $mo | Get-UcsBiosVfOSBootWatchdogTimerTimeout | Set-UcsBiosVfOSBootWatchdogTimerTimeout -Force -vpOSBootWatchdogTimerTimeout 'platform-default' 
$mo_6 = $mo | Get-UcsBiosVfSelectMemoryRASConfiguration | Set-UcsBiosVfSelectMemoryRASConfiguration -Force -vpSelectMemoryRASConfiguration 'maximum-performance' 
$mo_7 = $mo | Get-UcsBiosVfProcessorEnergyConfiguration | Set-UcsBiosVfProcessorEnergyConfiguration -Force -vpEnergyPerformance performance -vpPowerTechnology performance 
$mo_8 = $mo | Get-UcsBiosVfConsistentDeviceNameControl | Set-UcsBiosVfConsistentDeviceNameControl -Force -vpCDNControl 'platform-default' 
$mo_9 = $mo | Get-UcsBiosOSBootWatchdogTimerTimeoutPolicy | Set-UcsBiosOSBootWatchdogTimerTimeoutPolicy -Force -vpOSBootWatchdogTimerPolicy 'platform-default' 
$mo_10 = $mo | Get-UcsBiosVfEnhancedPowerCappingSupport 
$mo_11 = $mo | Get-UcsBiosVfCPUHardwarePowerManagement | Set-UcsBiosVfCPUHardwarePowerManagement -Force -vpCPUHardwarePowerManagement 'platform-default' 
$mo_12 = $mo | Get-UcsBiosEnhancedIntelSpeedStep | Set-UcsBiosEnhancedIntelSpeedStep -Force -vpEnhancedIntelSpeedStepTech enabled 
$mo_13 = $mo | Get-UcsBiosVfPCILOMPortsConfiguration | Set-UcsBiosVfPCILOMPortsConfiguration -Force -vpPCIe10GLOM2Link 'platform-default' 
$mo_14 = $mo | Get-UcsBiosVfUSBFrontPanelAccessLock | Set-UcsBiosVfUSBFrontPanelAccessLock -Force -vpUSBFrontPanelLock 'platform-default' 
$mo_15 = $mo | Get-UcsBiosVfIntelEntrySASRAIDModule | Set-UcsBiosVfIntelEntrySASRAIDModule -Force -vpSASRAID 'platform-default' -vpSASRAIDModule 'platform-default' 
$mo_16 = $mo | Get-UcsBiosVfRedirectionAfterBIOSPOST | Set-UcsBiosVfRedirectionAfterBIOSPOST -Force -vpRedirectionAfterPOST 'platform-default' 
$mo_17 = $mo | Get-UcsBiosVfMemoryMappedIOAbove4GB | Set-UcsBiosVfMemoryMappedIOAbove4GB -Force -vpMemoryMappedIOAbove4GB 'platform-default' 
$mo_18 = $mo | Get-UcsBiosVfQPILinkFrequencySelect | Set-UcsBiosVfQPILinkFrequencySelect -Force -vpQPILinkFrequencySelect 'platform-default' 
$mo_19 = $mo | Get-UcsBiosHyperThreading | Set-UcsBiosHyperThreading -Force -vpIntelHyperThreadingTech enabled 
$mo_20 = $mo | Get-UcsBiosVfEnergyPerformanceTuning | Set-UcsBiosVfEnergyPerformanceTuning -Force -vpPwrPerfTuning 'platform-default' 
$mo_21 = $mo | Get-UcsBiosVfProcessorPrefetchConfig | Set-UcsBiosVfProcessorPrefetchConfig -Force -vpAdjacentCacheLinePrefetcher enabled -vpDCUIPPrefetcher enabled -vpDCUStreamerPrefetch enabled -vpHardwarePrefetcher enabled 
$mo_22 = $mo | Get-UcsBiosVfMaxVariableMTRRSetting | Set-UcsBiosVfMaxVariableMTRRSetting -Force -vpProcessorMtrr 'platform-default' 
$mo_23 = $mo | Get-UcsBiosVfPCISlotOptionROMEnable | Set-UcsBiosVfPCISlotOptionROMEnable -Force -vpPCIeSlotHBAOptionROM 'platform-default' -vpPCIeSlotMLOMOptionROM 'platform-default' -vpPCIeSlotN1OptionROM 'platform-default' -vpPCIeSlotN2OptionROM 'platform-default' -vpPCIeSlotSASOptionROM 'platform-default' -vpSlot10State 'platform-default' -vpSlot1State 'platform-default' -vpSlot2State 'platform-default' -vpSlot3State 'platform-default' -vpSlot4State 'platform-default' -vpSlot5State 'platform-default' -vpSlot6State 'platform-default' -vpSlot7State 'platform-default' -vpSlot8State 'platform-default' -vpSlot9State 'platform-default' 
$mo_24 = $mo | Get-UcsBiosVfUEFIOSUseLegacyVideo | Set-UcsBiosVfUEFIOSUseLegacyVideo -Force -vpUEFIOSUseLegacyVideo 'platform-default' 
$mo_25 = $mo | Get-UcsBiosVfInterleaveConfiguration | Set-UcsBiosVfInterleaveConfiguration -Force -vpChannelInterleaving 'platform-default' -vpMemoryInterleaving 'platform-default' -vpRankInterleaving 'platform-default' 
$mo_26 = $mo | Get-UcsBiosVfFrequencyFloorOverride | Set-UcsBiosVfFrequencyFloorOverride -Force -vpFrequencyFloorOverride enabled 
$mo_27 = $mo | Get-UcsBiosIntelDirectedIO | Set-UcsBiosIntelDirectedIO -Force -vpIntelVTDATSSupport 'platform-default' -vpIntelVTDCoherencySupport 'platform-default' -vpIntelVTDInterruptRemapping 'platform-default' -vpIntelVTDPassThroughDMASupport 'platform-default' -vpIntelVTForDirectedIO 'platform-default' 
$mo_28 = $mo | Get-UcsBiosVfMaximumMemoryBelow4GB | Set-UcsBiosVfMaximumMemoryBelow4GB -Force -vpMaximumMemoryBelow4GB 'platform-default' 
$mo_29 = $mo | Get-UcsBiosVfResumeOnACPowerLoss | Set-UcsBiosVfResumeOnACPowerLoss -Force -vpResumeOnACPowerLoss 'platform-default' 
$mo_30 = $mo | Get-UcsBiosVfTrustedPlatformModule | Set-UcsBiosVfTrustedPlatformModule -Force -vpTrustedPlatformModuleSupport 'platform-default' 
$mo_31 = $mo | Get-UcsBiosVfOutOfBandManagement | Set-UcsBiosVfOutOfBandManagement -Force -vpComSpcrEnable 'platform-default' 
$mo_32 = $mo | Get-UcsBiosVfOSBootWatchdogTimer | Set-UcsBiosVfOSBootWatchdogTimer -Force -vpOSBootWatchdogTimer 'platform-default' 
$mo_33 = $mo | Get-UcsBiosVfUSBPortConfiguration | Set-UcsBiosVfUSBPortConfiguration -Force -vpPort6064Emulation 'platform-default' -vpUSBPortFront 'platform-default' -vpUSBPortInternal 'platform-default' -vpUSBPortKVM 'platform-default' -vpUSBPortRear 'platform-default' -vpUSBPortSDCard 'platform-default' -vpUSBPortVMedia 'platform-default' 
$mo_34 = $mo | Get-UcsBiosVfWorkloadConfiguration | Set-UcsBiosVfWorkloadConfiguration -Force -vpWorkloadConfiguration 'platform-default' 
$mo_35 = $mo | Get-UcsBiosVfDDR3VoltageSelection | Set-UcsBiosVfDDR3VoltageSelection -Force -vpDDR3VoltageSelection 'platform-default' 
$mo_36 = $mo | Get-UcsBiosVfUCSMBootModeControl 
$mo_37 = $mo | Get-UcsBiosTurboBoost | Set-UcsBiosTurboBoost -Force -vpIntelTurboBoostTech enabled 
$mo_38 = $mo | Get-UcsBiosVfPackageCStateLimit | Set-UcsBiosVfPackageCStateLimit -Force -vpPackageCStateLimit 'c1' 
$mo_39 = $mo | Get-UcsBiosVfTPMPendingOperation 
$mo_40 = $mo | Get-UcsBiosVfDRAMClockThrottling | Set-UcsBiosVfDRAMClockThrottling -Force -vpDRAMClockThrottling performance 
$mo_41 = $mo | Get-UcsBiosVfPSTATECoordination | Set-UcsBiosVfPSTATECoordination -Force -vpPSTATECoordination 'hw-all' 
$mo_42 = $mo | Get-UcsBiosVfCoreMultiProcessing | Set-UcsBiosVfCoreMultiProcessing -Force -vpCoreMultiProcessing all 
$mo_43 = $mo | Get-UcsBiosVfSerialPortAEnable | Set-UcsBiosVfSerialPortAEnable -Force -vpSerialPortAEnable 'platform-default' 
$mo_44 = $mo | Get-UcsBiosVfProcessorC3Report | Set-UcsBiosVfProcessorC3Report -Force -vpProcessorC3Report disabled 
$mo_45 = $mo | Get-UcsBiosVfProcessorC7Report | Set-UcsBiosVfProcessorC7Report -Force -vpProcessorC7Report disabled 
$mo_46 = $mo | Get-UcsBiosVfProcessorC6Report | Set-UcsBiosVfProcessorC6Report -Force -vpProcessorC6Report disabled 
$mo_47 = $mo | Get-UcsBiosExecuteDisabledBit | Set-UcsBiosExecuteDisabledBit -Force -vpExecuteDisableBit 'platform-default' 
$mo_48 = $mo | Get-UcsBiosVfFrontPanelLockout | Set-UcsBiosVfFrontPanelLockout -Force -vpFrontPanelLockout 'platform-default' 
$mo_49 = $mo | Get-UcsBiosVfIntegratedGraphics | Set-UcsBiosVfIntegratedGraphics -Force -vpIntegratedGraphics 'platform-default' 
$mo_50 = $mo | Get-UcsBiosVfDirectCacheAccess | Set-UcsBiosVfDirectCacheAccess -Force -vpDirectCacheAccess enabled 
$mo_51 = $mo | Get-UcsBiosVfConsoleRedirection | Set-UcsBiosVfConsoleRedirection -Force -vpBaudRate 'platform-default' -vpConsoleRedirection 'platform-default' -vpFlowControl 'platform-default' -vpLegacyOSRedirection 'platform-default' -vpPuttyKeyPad 'platform-default' -vpTerminalType 'platform-default' 
$mo_52 = $mo | Get-UcsBiosVfPCISlotLinkSpeed | Set-UcsBiosVfPCISlotLinkSpeed -Force -vpPCIeSlot10LinkSpeed 'platform-default' -vpPCIeSlot1LinkSpeed 'platform-default' -vpPCIeSlot2LinkSpeed 'platform-default' -vpPCIeSlot3LinkSpeed 'platform-default' -vpPCIeSlot4LinkSpeed 'platform-default' -vpPCIeSlot5LinkSpeed 'platform-default' -vpPCIeSlot6LinkSpeed 'platform-default' -vpPCIeSlot7LinkSpeed 'platform-default' -vpPCIeSlot8LinkSpeed 'platform-default' -vpPCIeSlot9LinkSpeed 'platform-default' 
$mo_53 = $mo | Get-UcsBiosVfAssertNMIOnSERR | Set-UcsBiosVfAssertNMIOnSERR -Force -vpAssertNMIOnSERR 'platform-default' 
$mo_54 = $mo | Get-UcsBiosVfAssertNMIOnPERR | Set-UcsBiosVfAssertNMIOnPERR -Force -vpAssertNMIOnPERR 'platform-default' 
$mo_55 = $mo | Get-UcsBiosVfIOENVMe1OptionROM | Set-UcsBiosVfIOENVMe1OptionROM -Force -vpIOENVMe1OptionROM 'platform-default' 
$mo_56 = $mo | Get-UcsBiosVfIOENVMe2OptionROM | Set-UcsBiosVfIOENVMe2OptionROM -Force -vpIOENVMe2OptionROM 'platform-default' 
$mo_57 = $mo | Get-UcsBiosVfIOESlot1OptionROM | Set-UcsBiosVfIOESlot1OptionROM -Force -vpIOESlot1OptionROM 'platform-default' 
$mo_58 = $mo | Get-UcsBiosVfIOESlot2OptionROM | Set-UcsBiosVfIOESlot2OptionROM -Force -vpIOESlot2OptionROM 'platform-default' 
$mo_59 = $mo | Get-UcsBiosVfIOEMezz1OptionROM | Set-UcsBiosVfIOEMezz1OptionROM -Force -vpIOEMezz1OptionROM 'platform-default' 
$mo_60 = $mo | Get-UcsBiosVfBootOptionRetry | Set-UcsBiosVfBootOptionRetry -Force -vpBootOptionRetry 'platform-default' 
$mo_61 = $mo | Get-UcsBiosVfUSBConfiguration | Set-UcsBiosVfUSBConfiguration -Force -vpXHCIMode 'platform-default' 
$mo_62 = $mo | Get-UcsBiosVfDramRefreshRate | Set-UcsBiosVfDramRefreshRate -Force -vpDramRefreshRate '1x' 
$mo_63 = $mo | Get-UcsBiosVfProcessorCState | Set-UcsBiosVfProcessorCState -Force -vpProcessorCState disabled 
$mo_64 = $mo | Get-UcsBiosVfSBNVMe1OptionROM | Set-UcsBiosVfSBNVMe1OptionROM -Force -vpSBNVMe1OptionROM 'platform-default' 
$mo_65 = $mo | Get-UcsBiosVfSBMezz1OptionROM | Set-UcsBiosVfSBMezz1OptionROM -Force -vpSBMezz1OptionROM 'platform-default' 
$mo_66 = $mo | Get-UcsBiosVfOnboardGraphics | Set-UcsBiosVfOnboardGraphics -Force -vpOnboardGraphics 'platform-default' 
$mo_67 = $mo | Get-UcsBiosVfOptionROMEnable 
$mo_68 = $mo | Get-UcsBiosVfPOSTErrorPause | Set-UcsBiosVfPOSTErrorPause -Force -vpPOSTErrorPause 'platform-default' 
$mo_69 = $mo | Get-UcsBiosVfAllUSBDevices | Set-UcsBiosVfAllUSBDevices -Force -vpAllUSBDevices 'platform-default' 
$mo_70 = $mo | Get-UcsBiosVfUSBBootConfig | Set-UcsBiosVfUSBBootConfig -Force -vpLegacyUSBSupport 'platform-default' -vpMakeDeviceNonBootable 'platform-default' 
$mo_71 = $mo | Get-UcsBiosVfOnboardStorage | Set-UcsBiosVfOnboardStorage -Force -vpOnboardSCUStorageSupport 'platform-default' 
$mo_72 = $mo | Get-UcsBiosVfCPUPerformance | Set-UcsBiosVfCPUPerformance -Force -vpCPUPerformance enterprise 
$mo_73 = $mo | Get-UcsBiosVfSIOC1OptionROM | Set-UcsBiosVfSIOC1OptionROM -Force -vpSIOC1OptionROM 'platform-default' 
$mo_74 = $mo | Get-UcsBiosVfSIOC2OptionROM | Set-UcsBiosVfSIOC2OptionROM -Force -vpSIOC2OptionROM 'platform-default' 
$mo_75 = $mo | Get-UcsBiosVfACPI10Support | Set-UcsBiosVfACPI10Support -Force -vpACPI10Support 'platform-default' 
$mo_76 = $mo | Get-UcsBiosLvDdrMode | Set-UcsBiosLvDdrMode -Force -vpLvDDRMode 'performance-mode' 
$mo_77 = $mo | Get-UcsBiosVfScrubPolicies | Set-UcsBiosVfScrubPolicies -Force -vpDemandScrub disabled -vpPatrolScrub disabled 
$mo_78 = $mo | Get-UcsBiosVfMirroringMode | Set-UcsBiosVfMirroringMode -Force -vpMirroringMode 'platform-default' 
$mo_79 = $mo | Get-UcsBiosVfQPISnoopMode | Set-UcsBiosVfQPISnoopMode -Force -vpQPISnoopMode 'platform-default' 
$mo_80 = $mo | Get-UcsBiosNUMA | Set-UcsBiosNUMA -Force -vpNUMAOptimized enabled 
$mo_81 = $mo | Get-UcsBiosVfProcessorCMCI | Set-UcsBiosVfProcessorCMCI -Force -vpProcessorCMCI 'platform-default' 
$mo_82 = $mo | Get-UcsBiosVfPCHSATAMode 
$mo_83 = $mo | Get-UcsBiosVfLocalX2Apic | Set-UcsBiosVfLocalX2Apic -Force -vpLocalX2Apic auto 
$mo_84 = $mo | Get-UcsBiosVfProcessorC1E | Set-UcsBiosVfProcessorC1E -Force -vpProcessorC1E disabled 
$mo_85 = $mo | Get-UcsBiosVfVGAPriority | Set-UcsBiosVfVGAPriority -Force -vpVGAPriority 'platform-default' 
$mo_86 = $mo | Get-UcsBiosVfASPMSupport | Set-UcsBiosVfASPMSupport -Force -vpASPMSupport 'platform-default' 
$mo_88 = $mo | Get-UcsBiosVfSparingMode | Set-UcsBiosVfSparingMode -Force -vpSparingMode 'platform-default' 
$mo_89 = $mo | Get-UcsBiosVfTPMSupport 
$mo_90 = $mo | Get-UcsBiosVfFRB2Timer | Set-UcsBiosVfFRB2Timer -Force -vpFRB2Timer 'platform-default' 
$mo_91 = $mo | Get-UcsBiosVfPCIROMCLP | Set-UcsBiosVfPCIROMCLP -Force -vpPCIROMCLP 'platform-default' 
$mo_92 = $mo | Get-UcsBiosVfQuietBoot | Set-UcsBiosVfQuietBoot -Force -vpQuietBoot 'platform-default' 
$mo_93 = $mo | Get-UcsBiosVfAltitude | Set-UcsBiosVfAltitude -Force -vpAltitude 'platform-default' 

#Create Service Profiles


$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsServiceProfile -ModifyPresent -biosProfileName 'HD-BIOS' -bootPolicyName 'local-LUN' -extIPPoolName 'ext-mgmt' -extIPState none -hostFwPolicyName 'Hadoop-Baseline' -identPoolName 'FI05B-UUID-POOL' -maintPolicyName 'USER-ACK' -name 'SPT-HD-Worker' -policyOwner local -powerPolicyName default -resolveRemote yes -statsPolicyName default -type 'updating-template' -uuid derived 
$mo_1 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '5' 
$mo_2 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '4' 
$mo_3 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '3' 
$mo_4 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '2' 
$mo_5 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '1' 
$mo_6 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '08-data' 
$mo_7 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '09-data' 
$mo_8 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '04-data' 
$mo_9 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '05-data' 
$mo_10 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '14-data' 
$mo_11 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '06-data' 
$mo_12 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '07-data' 
$mo_13 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '11-data' 
$mo_14 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '10-data' 
$mo_15 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '13-data' 
$mo_16 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '03-data' 
$mo_17 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '12-data' 
$mo_18 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '01-os' 
$mo_19 = $mo | Add-UcsLogicalStorageProfileBinding -ModifyPresent -storageProfileName 'HD-Worker' 
$mo_20 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-B4-MAC-POOL' -mtu '9000' -name 'vNIC-4-B' -nwTemplName 'vNIC-4-B' -order '5' -qosPolicyName Platinum -statsPolicyName default -switchId 'B-A' 
$mo_21 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A2-MAC-POOL' -mtu '1500' -name 'vNIC-2-A' -nwTemplName 'vNIC-2-A' -order '3' -statsPolicyName default -switchId 'A-B' 
$mo_22 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A3-MAC-POOL' -mtu '1500' -name 'vNIC-3-A' -nwTemplName 'vNIC-3-A' -order '4' -statsPolicyName default -switchId 'A-B' 
$mo_23 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A0-MAC-POOL' -mtu '1500' -name 'vNIC-0-A' -nwTemplName 'vNIC-0-A' -order '1' -statsPolicyName default -switchId 'A-B' 
$mo_24 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A1-MAC-POOL' -mtu '1500' -name 'vNIC-1-A' -nwTemplName 'vNIC-1-A' -order '2' -statsPolicyName default -switchId 'A-B' 
$mo_25 = $mo | Add-UcsVnicDefBeh -ModifyPresent -action none -policyOwner local -type vhba 
$mo_26 = $mo | Add-UcsVnicConnDef -ModifyPresent -lanConnPolicyName 'HD-Connectivity' 
$mo_27 = $mo | Add-UcsVnicFcNode -ModifyPresent -addr 'pool-derived' -identPoolName 'node-default' 
$mo_28 = $mo | Get-UcsMoKvCfgHolder | Set-UcsMoKvCfgHolder -Force -fileTxAdminState enabled 
$mo_29 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '4' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_30 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '3' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_31 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '2' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_32 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '1' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_33 = $mo | Get-UcsServerPower | Set-UcsServerPower -Force -state up 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsServiceProfile -ModifyPresent -biosProfileName 'HD-BIOS' -bootPolicyName 'local-LUN' -descr 'This service profile template is for Hadoop Master node. ' -extIPPoolName 'ext-mgmt' -extIPState none -hostFwPolicyName 'Hadoop-Baseline' -identPoolName 'FI05B-UUID-POOL' -maintPolicyName 'USER-ACK' -name 'SPT-HD-Master' -policyOwner local -powerPolicyName default -resolveRemote yes -statsPolicyName default -type 'updating-template' -uuid derived 
$mo_1 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '5' 
$mo_2 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '4' 
$mo_3 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '3' 
$mo_4 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '2' 
$mo_5 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '1' 
$mo_6 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '04-data' 
$mo_7 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '03-data' 
$mo_8 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '01-os' 
$mo_9 = $mo | Add-UcsLogicalStorageProfileBinding -ModifyPresent -storageProfileName 'HD-Master' 
$mo_10 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-B4-MAC-POOL' -mtu '9000' -name 'vNIC-4-B' -nwTemplName 'vNIC-4-B' -order '5' -qosPolicyName Platinum -statsPolicyName default -switchId 'B-A' 
$mo_11 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A2-MAC-POOL' -mtu '1500' -name 'vNIC-2-A' -nwTemplName 'vNIC-2-A' -order '3' -statsPolicyName default -switchId 'A-B' 
$mo_12 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A3-MAC-POOL' -mtu '1500' -name 'vNIC-3-A' -nwTemplName 'vNIC-3-A' -order '4' -statsPolicyName default -switchId 'A-B' 
$mo_13 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A0-MAC-POOL' -mtu '1500' -name 'vNIC-0-A' -nwTemplName 'vNIC-0-A' -order '1' -statsPolicyName default -switchId 'A-B' 
$mo_14 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A1-MAC-POOL' -mtu '1500' -name 'vNIC-1-A' -nwTemplName 'vNIC-1-A' -order '2' -statsPolicyName default -switchId 'A-B' 
$mo_15 = $mo | Add-UcsVnicDefBeh -ModifyPresent -action none -policyOwner local -type vhba 
$mo_16 = $mo | Add-UcsVnicConnDef -ModifyPresent -lanConnPolicyName 'HD-Connectivity' 
$mo_17 = $mo | Add-UcsVnicFcNode -ModifyPresent -addr 'pool-derived' -identPoolName 'node-default' 
$mo_18 = $mo | Get-UcsMoKvCfgHolder | Set-UcsMoKvCfgHolder -Force -fileTxAdminState enabled 
$mo_19 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '4' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_20 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '3' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_21 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '2' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_22 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '1' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_23 = $mo | Get-UcsServerPower | Set-UcsServerPower -Force -state up 


$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsServiceProfile -ModifyPresent -biosProfileName 'HD-BIOS' -bootPolicyName 'local-LUN' -extIPPoolName 'ext-mgmt' -extIPState none -hostFwPolicyName 'Hadoop-Baseline' -identPoolName 'FI05B-UUID-POOL' -maintPolicyName 'USER-ACK' -name 'SPT-HD-Nifi' -policyOwner local -powerPolicyName default -resolveRemote yes -statsPolicyName default -type 'updating-template' -uuid derived 
$mo_1 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '5' 
$mo_2 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '4' 
$mo_3 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '3' 
$mo_4 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '2' 
$mo_5 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '1' 
$mo_6 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '01-os' 
$mo_7 = $mo | Add-UcsLogicalStorageProfileBinding -ModifyPresent -storageProfileName 'HD-Nifi' 
$mo_8 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-B4-MAC-POOL' -mtu '9000' -name 'vNIC-4-B' -nwTemplName 'vNIC-4-B' -order '5' -qosPolicyName Platinum -statsPolicyName default -switchId 'B-A' 
$mo_9 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A2-MAC-POOL' -mtu '1500' -name 'vNIC-2-A' -nwTemplName 'vNIC-2-A' -order '3' -statsPolicyName default -switchId 'A-B' 
$mo_10 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A3-MAC-POOL' -mtu '1500' -name 'vNIC-3-A' -nwTemplName 'vNIC-3-A' -order '4' -statsPolicyName default -switchId 'A-B' 
$mo_11 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A0-MAC-POOL' -mtu '1500' -name 'vNIC-0-A' -nwTemplName 'vNIC-0-A' -order '1' -statsPolicyName default -switchId 'A-B' 
$mo_12 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A1-MAC-POOL' -mtu '1500' -name 'vNIC-1-A' -nwTemplName 'vNIC-1-A' -order '2' -statsPolicyName default -switchId 'A-B' 
$mo_13 = $mo | Add-UcsVnicDefBeh -ModifyPresent -action none -policyOwner local -type vhba 
$mo_14 = $mo | Add-UcsVnicConnDef -ModifyPresent -lanConnPolicyName 'HD-Connectivity' 
$mo_15 = $mo | Add-UcsVnicFcNode -ModifyPresent -addr 'pool-derived' -identPoolName 'node-default' 
$mo_16 = $mo | Get-UcsMoKvCfgHolder | Set-UcsMoKvCfgHolder -Force -fileTxAdminState enabled 
$mo_17 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '4' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_18 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '3' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_19 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '2' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_20 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '1' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_21 = $mo | Get-UcsServerPower | Set-UcsServerPower -Force -state up 

$obj = Get-UcsOrg -Dn "org-root"
$mo = $obj | Add-UcsServiceProfile -ModifyPresent -biosProfileName 'HD-BIOS' -bootPolicyName 'local-LUN' -extIPPoolName 'ext-mgmt' -extIPState none -hostFwPolicyName 'Hadoop-Baseline' -identPoolName 'FI05B-UUID-POOL' -maintPolicyName 'USER-ACK' -name 'SPT-HD-Edge' -policyOwner local -powerPolicyName default -resolveRemote yes -statsPolicyName default -type 'updating-template' -uuid derived 
$mo_1 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '5' 
$mo_2 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '4' 
$mo_3 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '3' 
$mo_4 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '2' 
$mo_5 = $mo | Get-UcsLsVConAssign | Set-UcsLsVConAssign -Force -adminHostPort ANY -adminVcon '1' -order '1' 
$mo_6 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '08-data' 
$mo_7 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '09-data' 
$mo_8 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '04-data' 
$mo_9 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '05-data' 
$mo_10 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '14-data' 
$mo_11 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '06-data' 
$mo_12 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '07-data' 
$mo_13 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '11-data' 
$mo_14 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '10-data' 
$mo_15 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '13-data' 
$mo_16 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '03-data' 
$mo_17 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '12-data' 
$mo_18 = $mo | Get-UcsStorageVirtualDriveRef -adminState online -lunItemName '01-os' 
$mo_19 = $mo | Add-UcsLogicalStorageProfileBinding -ModifyPresent -storageProfileName 'HD-Edge' 
$mo_20 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-B4-MAC-POOL' -mtu '9000' -name 'vNIC-4-B' -nwTemplName 'vNIC-4-B' -order '5' -qosPolicyName Platinum -statsPolicyName default -switchId 'B-A' 
$mo_21 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A2-MAC-POOL' -mtu '1500' -name 'vNIC-2-A' -nwTemplName 'vNIC-2-A' -order '3' -statsPolicyName default -switchId 'A-B' 
$mo_22 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A3-MAC-POOL' -mtu '1500' -name 'vNIC-3-A' -nwTemplName 'vNIC-3-A' -order '4' -statsPolicyName default -switchId 'A-B' 
$mo_23 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A0-MAC-POOL' -mtu '1500' -name 'vNIC-0-A' -nwTemplName 'vNIC-0-A' -order '1' -statsPolicyName default -switchId 'A-B' 
$mo_24 = $mo | Add-UcsVnic -ModifyPresent -adaptorProfileName Linux -addr derived -adminHostPort ANY -adminVcon '1' -cdnPropInSync yes -cdnSource 'vnic-name' -identPoolName 'Fab-A1-MAC-POOL' -mtu '1500' -name 'vNIC-1-A' -nwTemplName 'vNIC-1-A' -order '2' -statsPolicyName default -switchId 'A-B' 
$mo_25 = $mo | Add-UcsVnicDefBeh -ModifyPresent -action none -policyOwner local -type vhba 
$mo_26 = $mo | Add-UcsVnicConnDef -ModifyPresent -lanConnPolicyName 'HD-Connectivity' 
$mo_27 = $mo | Add-UcsVnicFcNode -ModifyPresent -addr 'pool-derived' -identPoolName 'node-default' 
$mo_28 = $mo | Get-UcsMoKvCfgHolder | Set-UcsMoKvCfgHolder -Force -fileTxAdminState enabled 
$mo_29 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '4' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_30 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '3' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_31 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '2' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_32 = $mo | Add-UcsFabricVCon -ModifyPresent -fabric NONE -id '1' -instType manual -placement physical -select all -share shared -transport "ethernet","fc" 
$mo_33 = $mo | Get-UcsServerPower | Set-UcsServerPower -Force -state up 
