##############################################################################################
#     ____________  __ _    _                               __          _ __    __         
#    / ____/ ___/ |/ /(_)  (_)___ ___  ____ _____ ____     / /_  __  __(_) /___/ /__  _____
#   / __/  \__ \|   # /  / / __ `__ \/ __ `/ __ `/ _ \   / __ \/ / / / / / __  / _ \/ ___/
#  / /___ ___/ /   |/ /  / / / / / / / /_/ / /_/ /  __/  / /_/ / /_/ / / / /_/ /  __/ /    
# /_____#____/_/|_/_/  /_/_/ /_/ /_/\__,_/\__, /\___/  /_.___/\__,_/_/_/\__,_/\___/_/     
#                                         /____/                                           
##############################################################################################
# Author: Jonas Werner
# GitHub URL: https://github.com/jonas-werner/custom-esxi-iso-with-network-drivers
# Video: https://youtu.be/DbqZI1V6TK4
# Version: 0.8
##############################################################################
# Prerequisites
# Only needs to be executed once, not every time an image is built
# Must be Administrator to execute prerequisites
# Need to manually update the desired image name and network driver versions manually
#
# Per VMware PowerCLI Compatibility Matrixes at https://developer.vmware.com/docs/17472/-compatibility-matrix/powercli1300-compat-matrix.html#install-prereq
# Must install Python 3.7 and the following packages: six,psutil,lxml,pyopenssl by running the following:
#
# choco install python37
# python -m pip install -U pip
# pip install six psutil lxml pyopenssl
#

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# Check if the VMware.PowerCLI module is imported
if (-not (Get-Module -Name VMware.PowerCLI)) {
  Install-Module -Name VMware.PowerCLI -SkipPublisherCheck
}

##############################################################################

##############################################################################
# Get the base ESXi image
##############################################################################
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false

# Set the path to the ython 3.7 executable (this specific version is required per VMware PowerCLI Compatibility Matrixes)
# You may have to manually change the python.exe path, but this is the path that chocolately installs it to by default
Set-PowerCLIConfiguration -PythonPath "c:\python37\python.exe" -Scope User

# Fetch ESXi image depot
Add-EsxSoftwareDepot https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml

# List avilable profiles if desired (show what images are available for download)
#Get-EsxImageProfile

# Download desired image
Export-ESXImageProfile -ImageProfile "ESXi-8.0b-21203435-standard" -ExportToBundle -filepath ESXi-8.0b-21203435-standard.zip

# Remove the depot
Remove-EsxSoftwareDepot https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml

# Add default ESXi image files to installation media
Add-EsxSoftwareDepot .\ESXi-8.0b-21203435-standard.zip


##############################################################################
# Download additional drivers (can be done via browser too, either is fine) 
##############################################################################

# Get community network driver
# VMware Fling URL: https://flings.vmware.com/community-networking-driver-for-esxi
Invoke-WebRequest -Uri https://download3.vmware.com/software/vmw-tools/community-network-driver/Net-Community-Driver_1.2.7.0-1vmw.700.1.0.15843807_19480755.zip -OutFile Net-Community-Driver_1.2.7.0-1vmw.700.1.0.15843807_19480755.zip

# Get USB NIC driver
# VMware Fling URL: https://flings.vmware.com/usb-network-native-driver-for-esxi
Invoke-WebRequest -Uri https://download3.vmware.com/software/vmw-tools/USBNND/ESXi800-VMKUSB-NIC-FLING-61054763-component-20826251.zip -OutFile ESXi800-VMKUSB-NIC-FLING-61054763-component-20826251.zip

##############################################################################
# Add the additional drivers
##############################################################################

# Add community network driver
Add-EsxSoftwareDepot .\Net-Community-Driver_1.2.7.0-1vmw.700.1.0.15843807_19480755.zip

# Add USB NIC driver
Add-EsxSoftwareDepot .\ESXi800-VMKUSB-NIC-FLING-61054763-component-20826251.zip


##############################################################################
# Create new installation media profile and add the additional drivers to it
##############################################################################

# Create new, custom profile
New-EsxImageProfile -CloneProfile "ESXi-8.0b-21203435-standard" -name "ESXi-8.0b-21203435-standard-Net-Drivers" -Vendor "jonamiki.com"

# Optionally remove existing driver package (example for ne1000)
#Remove-EsxSoftwarePackage -ImageProfile "ESXi-8.0b-21203435-standard-Net-Drivers" -SoftwarePackage "ne1000"

# Add community network driver package to custom profile
Add-EsxSoftwarePackage -ImageProfile "ESXi-8.0b-21203435-standard-Net-Drivers" -SoftwarePackage "net-community"

# Add USB NIC driver package to custom profile
Add-EsxSoftwarePackage -ImageProfile "ESXi-8.0b-21203435-standard-Net-Drivers" -SoftwarePackage "vmkusb-nic-fling"

##############################################################################
# Export the custom profile to ISO
##############################################################################
Export-ESXImageProfile -ImageProfile "ESXi-8.0b-21203435-standard-Net-Drivers" -ExportToIso -filepath ESXi-8.0b-21203435-standard-Net-Drivers.iso
