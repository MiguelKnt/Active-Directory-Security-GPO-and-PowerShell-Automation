# Decommission Active Directory User Accounts

# Import Active Directory module
Import-Module ActiveDirectory

# Define variables
$OUPath = "OU=Disabled Accounts,DC=YourDomain,DC=com"  # Path to Disabled Accounts OU (update with your domain)
$LogFile = "C:\Logs\DecommissionLog.txt"              # Log file path

# Ensure the log directory exists
if (-not (Test-Path -Path "C:\Logs")) {
    New-Item -ItemType Directory -Path "C:\Logs"
}

# Create the Disabled Accounts OU if it doesn't exist
$OUExists = Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $OUPath} -ErrorAction SilentlyContinue
if (-not $OUExists) {
    Write-Host "The Disabled Accounts OU doesn't exist. Creating it now..."
    New-ADOrganizationalUnit -Name "Disabled Accounts" -Path "DC=YourDomain,DC=com"  # Replace with your domain
    Add-Content -Path $LogFile -Value "[$(Get-Date)] INFO: Disabled Accounts OU created."
} else {
    Add-Content -Path $LogFile -Value "[$(Get-Date)] INFO: Disabled Accounts OU already exists."
}

# Prompt for the username to decommission
$User = Read-Host "Enter the logon name (SamAccountName) of the account to decommission"
$User = $User.Trim()  # Remove any leading/trailing spaces
Write-Host "DEBUG: Logon name entered - $User"

# Check if the user exists in Active Directory
try {
    $ADUser = Get-ADUser -Identity $User -ErrorAction Stop

    if ($ADUser) {
        Write-Host "DEBUG: User found - $($ADUser.DistinguishedName)"
        Add-Content -Path $LogFile -Value "[$(Get-Date)] DEBUG: User found - $($ADUser.DistinguishedName)"
        
        # Store current distinguished name for debugging
        $UserDN = $ADUser.DistinguishedName
        Write-Host "DEBUG: Current DN of user - $UserDN"
        Add-Content -Path $LogFile -Value "[$(Get-Date)] DEBUG: Current DN of user - $UserDN"

        # Disable the user account
        Disable-ADAccount -Identity $ADUser.SamAccountName
        Add-Content -Path $LogFile -Value "[$(Get-Date)] SUCCESS: User $User has been disabled."
        Write-Host "SUCCESS: User $User has been disabled."

        # Move the user to the Disabled Accounts OU
        try {
            Write-Host "DEBUG: Moving $UserDN to $OUPath"
            Add-Content -Path $LogFile -Value "[$(Get-Date)] DEBUG: Moving $UserDN to $OUPath"

            Move-ADObject -Identity $UserDN -TargetPath $OUPath -ErrorAction Stop

            Add-Content -Path $LogFile -Value "[$(Get-Date)] SUCCESS: User $User has been moved to the Disabled Accounts OU."
            Write-Host "SUCCESS: User $User has been moved to the Disabled Accounts OU."
        } catch {
            Write-Host "ERROR: Failed to move user $User to the Disabled Accounts OU."
            Write-Host "DEBUG: Possible issues - Insufficient permissions, invalid TargetPath, or existing object in target OU."
            Add-Content -Path $LogFile -Value "[$(Get-Date)] ERROR: Failed to move user $User to the Disabled Accounts OU. $_"
        }
    }
} catch {
    Write-Host "ERROR: User $User not found or an error occurred."
    Add-Content -Path $LogFile -Value "[$(Get-Date)] ERROR: User $User not found or an error occurred: $_"
}

# Keep the window open after script execution
Read-Host "Press Enter to exit"
