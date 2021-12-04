#Version 2 of Vasp2Visual with general functions.
function Read-BigFile{
    <#
    .DESCRIPTION
    Returns a range of lines from a big file. Use Get-Content for small files.
    StremReader requires Absolute path.
    .EXAMPLE
        Read-BigFile -FilePath E:/Research/Current/pDOS.txt -StopIndex 5
        You can use -StartIndex to provide a range to read.
    #>
    [CmdletBinding(DefaultParameterSetName='interval')]
    param (
        [Parameter(Mandatory="True",ValueFromPipeline=$true)][String]$FilePath,
        [Parameter(ParameterSetName='interval')][int]$StartIndex =0,
        [Parameter(ParameterSetName='interval')][int]$StopIndex=0,
        [Parameter(ParameterSetName='full')][switch]$ReadAll
    )
    $AbsPath = (Get-Item $FilePath).FullName
    [System.IO.StreamReader] $reader = New-Object  -TypeName 'System.IO.StreamReader' -ArgumentList ($AbsPath, $false);
    [String] $line = $null;
    [Int32] $currentIndex = 0;

    try{
        if($PSCmdlet.ParameterSetName -eq 'interval'){
            while($currentIndex -le $StopIndex){
                $line = $reader.ReadLine()
                if ($null -ne $line -and $currentIndex -ge $StartIndex){
                    $line
                }
                $currentIndex++
            }
        }elseif ($PSCmdlet.ParameterSetName -eq 'full'){
            While($null -ne ($eachLine=$reader.ReadLine())){
                $eachLine 
                }
        }
    }
    finally{
        $reader.Close();
    }
}

function Write-BigStream{
    <#
    .DESCRIPTION
    Writes a given array to a file either on one line or as given object.
    StremWriter requires Absolute path.
    .EXAMPLE
        $x=Read-BigFile -FilePath E:/Research/Current/pDOS.txt -StopIndex 5
        Write-BigStream -StreamArray $x -FilePath E:/Research/Current/new.txt
        Write-BigStream -StreamArray $x -FilePath E:/Research/Current/new.txt -AsOneLine

        Oneline file is good for using in python numpy.reshape() function, which can not read file
        if there are lines with empty entries.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory="True",ValueFromPipeline = $true)][array]$StreamArray,
        [Parameter(Mandatory="True")]$FilePath,
        [Parameter()][switch]$AsOneLine
    )
    $AbsFilePath = (Get-Item $FilePath).FullName
    $sw = New-Object System.IO.StreamWriter $AbsFilePath
    [array]$StreamArray=$StreamArray
    if($AsOneLine.IsPresent){
        foreach ($line in $StreamArray) {
            if($null -ne $line){
            $sw.Write($line)}          
        }
    }else{
        foreach ($line in $StreamArray) {
            if($null -ne $line){
            $sw.WriteLine($line)}
        }
    } 
    $sw.Close();
}

function Get-POSCAR {
    [CmdletBinding(DefaultParameterSetName='SITES')]
    Param(
        [Parameter(Position=0)]$Formula = 'GaAs',
        [Parameter(ParameterSetName='MPID')]$MP_ID,
        [Parameter(ParameterSetName='SITES')]$MaxSites,
        [Parameter()]$APIKey
    )
    $var_dict = "dict({})"
    if($PSBoundParameters.ContainsKey('MP_ID')){
        $var_dict = "dict(mp_id = '{0}')" -f $MP_ID
    }
    if($PSBoundParameters.ContainsKey('MaxSites')){
        $var_dict = "dict(max_sites = {0})" -f $MaxSites
    }
    if($PSBoundParameters.ContainsKey('APIKey')){
        $rep = $(",api_key = '{0}')" -f $APIKey)
        $var_dict = $var_dict.Replace(")", $rep) 
    }
    Write-Host "Use Pivotpy in Python for full functionality!" -ForegroundColor Yellow
    $py_str = "vd = {1}`nfrom pivotpy.api import download_structure`ngp = download_structure('{0}',**vd).poscars`n" -f $Formula, $var_dict
    $py_str += "import json`ns=json.dumps([{k:v for k,v in _g.to_dict().items() if 'write' not in k} for _g in gp])`nprint(s)"
    Write-Host $py_str
    # Run it finally Using Default python on System preferably.
    if($null -ne (Get-Command python3* -ErrorAction SilentlyContinue)){
        Write-Host ("Running using {0}" -f (python3 -V)) -ForegroundColor Green
        $json = $py_str | python3
        ConvertFrom-Json $json
    }elseif($null -ne (Get-Command python -ErrorAction SilentlyContinue)){
        Write-Host ("Running using {0}" -f (python -V)) -ForegroundColor Green
        $json = $py_str | python
        ConvertFrom-Json $json
    }elseif($null -ne (Get-Command pytnon2* -ErrorAction SilentlyContinue)){
        Write-Host ("Required Python >= 3.6, but {0} found, try upgrading Python." -f (python2 -V)) -ForegroundColor Red
    }else{
        Write-Host "Python Installation not found. Copy code below and run yourself or use '-SavePyFile'." -ForegroundColor Red
        Write-Host $py_str -ForegroundColor Yellow
    }
}

Export-ModuleMember -Function 'Read-BigFile'
Export-ModuleMember -Function 'Write-BigStream'
Export-ModuleMember -Function 'Get-POSCAR'