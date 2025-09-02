# PowerShell Bullshit

PowerShell is the bastard son off object based shell programming (sure, let's make files into a string array!)

## We Love PowerShell

I paid for my daughters college with MS Exchange money, and you can't do Exchange really well without P-P-P-PowerShell!

## What Exactly is Going on Here?

This is where I put scripts I think are clever or my $PROFILE which is filled with little tools/functions I use on the regular, so if my computers are all destroyed I can still have my odd $PROFILE.

## Highlights
- `$PROFILE` with odd little functions (`touch`, `Get-Zulu`, `get-pass`, `Hash-Folder`…)
- Random scripts that solved a problem once and might again
- Zero guarantees, but it all works for me

### Test-Port.ps1
Because `Test-NetConnection` is nice, but it won’t touch UDP.  
This script does both TCP and UDP port checks, with timeouts and structured output.  
Useful when DNS is flaking or you need to verify a service that isn’t TCP.
