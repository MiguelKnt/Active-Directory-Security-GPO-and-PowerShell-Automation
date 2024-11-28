# Define a function to prompt the user for input and return the value
function Get-UserInput {
    param (
        [string]$Prompt
    )
    $input = Read-Host $Prompt
    return $input
}

# Function to list OUs from Active Directory
function Get-OrganizationalUnits {
    $OUs = Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName
    return $OUs
}

# Prompt for the domain (user input instead of fixed value)
$domain = Get-UserInput "Enter your domain (e.g., example.com)"
Write-Host "Using domain: $domain"

# Get the list of available OUs in Active Directory
$OUs = Get-OrganizationalUnits

# Display the OUs and prompt the user to select one
Write-Host "Available Organizational Units (OUs):"
for ($i = 0; $i -lt $OUs.Length; $i++) {
    Write-Host "$($i + 1). $($OUs[$i])"
}

# Prompt for the OU selection
$ouChoice = $null
do {
    $ouChoice = Read-Host "Choose the Organizational Unit by entering the corresponding number (1-$($OUs.Length))"
} while ($ouChoice -lt 1 -or $ouChoice -gt $OUs.Length)

$selectedOU = $OUs[$ouChoice - 1]
Write-Host "You selected the Organizational Unit: $selectedOU"

# Prompt for user details
$firstName = Get-UserInput "Enter the first name"
$lastName = Get-UserInput "Enter the last name"
$phone = Get-UserInput "Enter the phone number"
$email = Get-UserInput "Enter the email address"

# Generate the username (first initial + last name)
$username = "$($firstName.Substring(0, 1))$($lastName)"
$upn = "$username@$domain"

# Ensure the Name parameter is properly set for New-ADUser
$name = "$firstName $lastName"

# Create the new user in Active Directory
try {
    New-ADUser -SamAccountName $username ` 
               -UserPrincipalName $upn ` 
               -GivenName $firstName ` 
               -Surname $lastName ` 
               -Name $name ` 
               -DisplayName "$firstName $lastName" ` 
               -EmailAddress $email ` 
               -OfficePhone $phone ` 
               -Enabled $true ` 
               -AccountPassword (ConvertTo-SecureString -AsPlainText 'ComplexP@ssw0rd!' -Force) ` 
               -Path $selectedOU

    Write-Host "User $firstName $lastName created successfully in OU: $selectedOU!"
} catch {
    Write-Host "Error creating user: $_"
}

# Prevent PowerShell window from closing automatically
$host.ui.PromptForChoice("Process Complete", "The script has completed. Would you like to exit?", [System.Management.Automation.Host.ChoiceDescription[]]@(
    [System.Management.Automation.Host.ChoiceDescription]::new("Yes"),
    [System.Management.Automation.Host.ChoiceDescription]::new("No")
), 0)
