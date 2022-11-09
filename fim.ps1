
Write-Host ""
write-host "What would you like to do?"
Write-Host ""
write-host "     A). Collect new Baseline?"
write-host "     B). Begin monitoring files with saved Baseline?"
Write-Host ""

$response = Read-Host -Prompt "please enter 'A' or 'B'"
write-host ""

# A function that will grab a file path and calculate a hash on it.
# NOTE: make sure, on the command line, you are in the taregt file path. For me i used \User\User-name\Desktop\fim
Function calculate-file-hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
    # We will be using the SHA512 hashing alogrithm.
}


# A function that will check if baseline txt file already exists - removing redundancy if we "run" baseline
# more than once.
function erase-baseline-if-already-exists() {
    $baselineexists = test-path -path .\baseline.txt
    
    if ($baselineexists) {
        Remove-Item -Path .\baseline.txt
    }
}



# elseif statement, user has option A (calculate hash baseline); or
# option B (monitor files with saved hash baseline)

   # if user types option A - ToUpper uppercases 'a' - we are going to calculate
   # hash values and store them in Baseline.txt
if ($response -eq "A".ToUpper()) {
   # delete baseline.txt if already exists
   erase-baseline-if-already-exists

   # collect all files from target folder - make sure you are in ...\desktop\fim directory
   $files = Get-ChildItem -Path .\files
   
   # for each file, return file path and calculated the hash; and write to Baseline.txt
   foreach($f in $files) {
       $hash = calculate-file-hash $f.FullName 
       "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
   }
}
elseif ($response -eq "B".ToUpper()) {

    $fileHashDictionary = @{}
    #load file|hash from baseline.txt and store them in a dictionary - a data structure.
    $filePathsAndHashes = Get-Content -path .\baseline.txt

    # splits our file path into a key and hash vaules into values, within the dictionary. 
    foreach ($f in $filePathsAndHashes) {
         $fileHashDictionary.add($f.split("|")[0],$f.split("|")[1])   
    }
   

    # If user types in B, we begin (continously) monitoring files with saved Baseline.txt
    # infinite while loop that checks if file hash stay "true" - unchanged.
    while ($true) {
        Start-Sleep -Seconds 1
        
       $files = Get-ChildItem -Path .\files
   
       # for each file, return file path and calculated the hash; and write to Baseline.txt
       foreach($f in $files) {
           $hash = calculate-file-hash $f.FullName 
           # "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append  

           # Notify user if a new file is created.
           if ($fileHashDictionary[$hash.Path] -eq $null) {
               # A new file has been created!
               Write-Host "$($hash.Path) has been created!" -ForegroundColor Red
           }
           else {
          
                # Notify if a new file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    # the file has not changed
                }
                else {
                    # file has been compromised! - notify the user
                    Write-Host "$($hash.path) has changed! - code GREEN" -ForegroundColor GREEN

           }
           

                
           }
           
           
       }

           # for loop that checks no files have been deleted
           foreach ($key in $fileHashDictionary.Keys) {
               $baselinefileStillExists = Test-Path -Path $key
               if (-Not $baselinefileStillExists) {
                  # one of the baseline files must have been deleted, notify the user.
                  Write-Host "$($key) has been deleted! - code YELLOW" -foregroundcolor Yellow
            }
           }


    }
}
