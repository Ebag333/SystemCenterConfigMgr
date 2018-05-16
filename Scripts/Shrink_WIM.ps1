param(
[Parameter(Mandatory=$True)]
[String]$SourceImage,
[Parameter(Mandatory=$True)]
[String]$MountDir,
[Parameter(Mandatory=$True)]
[String]$DestinationImage,
[Parameter(Mandatory=$True)]
[String]$WinVersion,
[Parameter(Mandatory=$False)]
[String]$UpdatePath
)

#Command line usage ex:
# Shrink_WIM.ps1 -SourceImage "c:\install.wim" -MountDir "C:\wim" -DestinationImage "c:\install-new.wim" -WinVersion "Windows 10 Enterprise" -UpdatePath "c:\windows10.0-kb4103721-x64.msu"

#Index names available as of 1803:
# Windows 10 Education, Windows 10 Education N, Windows 10 Enterprise, Windows 10 Enterprise N, Windows 10 Pro, Windows 10 Pro N, Windows 10 Pro Education, Windows 10 Pro Education N, Windows 10 Pro for Workstations, Windows 10 Pro N for Workstations

#Get all indexes
$img_indexes = Get-WindowsImage -ImagePath $SourceImage

#Create loop to remove indexes until we are left with one.
do {
    #Loop through each index and remove the index if it is not the designated edition.
    foreach ($img_index in $img_indexes) {
        if ($img_index.ImageName -ne $WinVersion) {
        Remove-WindowsImage -ImagePath $SourceImage -Index $img_index.ImageIndex
        #Break out of the for loop, as we need to refresh the index list. The indexes re-order once one is removed.
        break
        }
    }
    #Refresh the index list.
    $img_indexes = Get-WindowsImage -ImagePath $SourceImage
} until ($img_indexes.Count -eq 1)

#Mount .wim for dism actions. Do not open this directory in Explorer while the script is running.
Mount-WindowsImage -Path $MountDir -ImagePath $SourceImage -Index 1
#Add update package to .wim if specified.
if ($UpdatePath){Start-Process DISM.exe -Argumentlist "/Image:$MountDir /Add-Package /PackagePath:$UpdatePath" -NoNewWindow -Wait}
#Cleanup .wim
Start-Process DISM.exe -Argumentlist "/Image:$MountDir /Cleanup-Image /StartComponentCleanup /ResetBase" -NoNewWindow -Wait
#Unmount .wim and save changes.
Dismount-WindowsImage -Path $MountDir -Save
#Export .wim to optimize size.
Export-WindowsImage -SourceImagePath $SourceImage -SourceIndex 1 -DestinationImagePath $DestinationImage -CompressionType max