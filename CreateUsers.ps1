Import-Module ActiveDirectory



import-csv 'C:\PS Templates\newUsers.csv' | ForEach-Object {
    $password = (ConvertTo-SecureString -AsPlainText "Welkom123" -Force)
    $path = "OU="+$_.path+",DC=Local,DC=com"
    $i = 1
    $domain = $env:userdnsdomain
    $username = $_.firstname.Substring(0, $i) + $_.lastname
    $email = $username + "@Fonteyn.com"

    DO
    {
        if ($(GET-ADUser -Filter {SamAccountName -eq $username})) {
        Write-Host "WARNING: Login Name" $username "already exists!!" -ForegroundColor:Green
        $i++
        $username = $_.firstname.Substring(0, $i) + $_.lastname
        Write-Host "Changing Login Name to" $username -ForegroundColor:Green
        $taken = $True
        } else {
            $taken = $False
        }
    } Until ($taken -eq $False)

    New-ADUser -Name $username -GivenName $_.firstname -Surname $_.lastname -EmailAddress $email -ChangePasswordAtLogon $True -SamAccountName $username -UserPrincipalName $username@$domain -AccountPassword $password -Enabled $True -Path $path
    Add-ADGroupMember -Identity $_.group -Members $username
}

# Change user group.
import-csv 'C:\PS Templates\group.csv' | ForEach-Object {Add-ADGroupMember -Identity $_.groupname -Members $_.username}
import-csv 'C:\PS Templates\removeGroup.csv' | ForEach-Object {Remove-ADGroupMember -Identity $_.groupname -Members $_.username -Confirm:$False}

Clear-Content "C:\PS Templates\*"

"Username,Groupname" | Out-File 'C:\PS Templates\group.csv' -Append
"Username,Groupname" | Out-File 'C:\PS Templates\removeGroup.csv' -Append
"Firstname,Lastname,Group,Path" | Out-File 'C:\PS Templates\newUsers.csv' -Append