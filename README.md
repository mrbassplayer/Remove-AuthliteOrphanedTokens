# Remove-AuthliteOrphanedTokens
This PowerShell script is for users of Authlite. It is to help reclaim licenses for tokens assigned to a user who has left the company. At the time of writing this, Authlite doesn't have this functionality natively, so I put this together.

The logic behind the script is that it collects all the tokens Authlite has. It then checks the samaccountname in AD to see if that user is still active. If it is not, it will purge the "s OTP tokens, and return Yubikey and physical OTP tokens back to an "unassigned" state. 

This script has never done me wrong, but it stresses me out every time I run it. So, I still recommend that you step through this script slowly the first time.
