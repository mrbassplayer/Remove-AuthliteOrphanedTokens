# Clear variables
$searchresults = $users = @()

# Pull token data from Authlite
$domdn = Get-ADDomain | select -ExpandProperty DistinguishedName
$keys  = "LDAP://CN=AuthLiteKeys,DC=AuthLite," + $domdn

$searcher            = New-Object adsisearcher
$searcher.SearchRoot = $keys
$searcher.PageSize   = 1000
$results             = $searcher.FindAll()

# Collect usernames from above tokens
ForEach($result in $results) {

   $key = [ADSI]$result.Path
   ForEach($item in $key) {

      $users += $item.collectiveAuthLiteUserName
   }
}

# Exclude unassigned (e.g. "none") tokens and remove duplicate usernames
$users = $users | where {$_ -ne "none"} | sort | select -Unique

# Check AD for user object. Any users with a value of NULL go into $searchresults
$searchresults = foreach ($testuser in $users) {
   $User = Get-ADUser -Filter {(samaccountname -eq $testuser)}
   If ($user -eq $Null) { "$testuser" }
}

# Display list of users the script thinks are NOT in AD but ARE in Authlite
$searchresults

# These essentially "Pause" the script. Handy for evaluating the results before any action is performed. Remove # to use.
#            $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
#            $HOST.UI.RawUI.Flushinputbuffer()

# Remove deleted Active Directory users from Authlite. Either by deleting the entry or unassigning the token/Yubikey
ForEach($result in $results) {

   $key = [ADSI]$result.Path
   ForEach($item in $key) {

      # Is the token a "hard token" or Yubikey. If so, UNASSIGN IT.
      foreach ($searchresult in $searchresults) {
         if (($item.collectiveAuthLiteUserName      -eq   $searchresult -and
              $item.collectiveAuthLiteTokenType     -eq   "1")          -or
             ($item.collectiveAuthLiteUsername      -eq   $searchresult -and
              $item.collectiveAuthLiteDescriptiveID -like "hyper*")) {

            Write-host $item.collectiveAuthLiteUsername " " $item.collectiveAuthLiteTokenType " " $item.collectiveAuthLiteDescriptiveID -NoNewline
            Write-Host " << should be unassigned" -ForegroundColor Yellow
#            $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
#            $HOST.UI.RawUI.Flushinputbuffer()

            $item.collectiveAuthLiteUsername.Remove("$($item.collectiveAuthLiteUsername)")
            $item.collectiveAuthLiteDomain.Remove("$($item.collectiveAuthLiteDomain)")
            $item.SetInfo()

#            $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
#            $HOST.UI.RawUI.Flushinputbuffer()
         }
         # Is the token a "soft Token". If so, DELETE IT.
         elseif ($item.collectiveAuthLiteUserName -eq $searchresult) {

            Write-Host $item.collectiveAuthLiteUsername " " $item.collectiveAuthLiteTokenType " " $item.collectiveAuthLiteDescriptiveID -NoNewline
            write-host " << should be deleted" -ForegroundColor White -BackgroundColor DarkRed
#            $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
#            $HOST.UI.RawUI.Flushinputbuffer()

            $item.psbase.DeleteTree()

#            $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
#            $HOST.UI.RawUI.Flushinputbuffer()
         }
      }
   }
}
