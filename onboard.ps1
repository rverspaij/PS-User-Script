# Import ActiveDirectory module
Import-Module ActiveDirectory

# Define variables
$csvFilePath = "C:\Users\newusers.csv"
$OUPath = "OU=Users,DC=test,DC=com"
$password = ConvertTo-SecureString -String "Password123" -AsPlainText -Force

# Import CSV file and loop through each row
Import-Csv $csvFilePath | ForEach-Object {
    $firstName = $_.FirstName
    $lastName = $_.LastName
    $i = 1
    $username = $_.FirstName.Substring(0, $i) + $_.LastName
    $email = $username + "test.com"
    $gpoName = $_.GPO

    # Check if user already exists in Active Directory
    DO
    {
        if (Get-ADUser -Filter {samaccountname -eq $username}) {
            Write-Host "WARNING: Login Name" $username "already exists!!" -ForegroundColor:Red
            $i++
            $username = $_.FirstName.Substring(0, $i) + $_.LastName
            Write-Host "Changing Login Name to" $username -ForegroundColor:Green
            $taken = $True
        } else {
            $taken = $False
        }
    } Until ($taken -eq $False)
    
    # Create new user object
    $userParams = @{
        GivenName = $firstName
        Surname = $lastName
        Name = "$firstName $lastName"
        DisplayName = "$lastName, $firstName"
        SamAccountName = $username
        UserPrincipalName = "$username@test.com"
        EmailAddress = $email
        AccountPassword = $password
        Enabled = $true
        Path = $OUPath
        ChangePasswordAtLogon = $True
    }
    New-ADUser @userParams -PassThru | Set-ADAccountPassword -NewPassword $password -Reset

    # Add user to appropriate security group via Group Policy Object
    $gpo = Get-GPO -Name $gpoName
    if ($gpo) {
        $groupName = "test\$($gpo.DisplayName) Users"
        Add-GPGroupMember -Name $gpo.DisplayName -Group $groupName -Member $username
    } else {
        Write-Warning "GPO $gpoName not found."
    }
}