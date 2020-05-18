#Version 2 of Vasp2Visual with general functions.
function Read-BigFile{
    <#
    .DESCRIPTION
    Returns a range of lines from a big file. Use Get-Content for small files.
    StremReader requires Absolute path.
    .EXAMPLE
        Read-BigFile -AbsPath E:\Research\Current\pDOS.txt -StopIndex 5
        You can use -StartIndex to provide a range to read.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory="True",ValueFromPipeline=$true)][String]$AbsPath,
        [Parameter()][int]$StartIndex =0,
        [Parameter()][int]$StopIndex=0
    )
    [System.IO.StreamReader] $reader = New-Object  -TypeName 'System.IO.StreamReader' -ArgumentList ($AbsPath, $false);
    [String] $line = $null;
    [Int32] $currentIndex = 0;

    try{
        while($currentIndex -le $StopIndex){
            $line = $reader.ReadLine()
            if ($null -ne $line -and $currentIndex -ge $StartIndex){
                $line
            }
            $currentIndex++
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
        $x=Read-BigFile -AbsPath E:\Research\Current\pDOS.txt -StopIndex 5
        Write-BigStream -StreamArray $x -AbsFilePath E:\Research\Current\new.txt
        Write-BigStream -StreamArray $x -AbsFilePath E:\Research\Current\new.txt -AsOneLine

        Oneline file is good for using in python numpy.reshape() function, which can not read file
        if there are lines with empty entries.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory="True",ValueFromPipeline=$true)][array]$StreamArray,
        [Parameter(Mandatory="True")]$AbsFilePath,
        [Parameter()][switch]$AsOneLine
    )
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

Export-ModuleMember -Function 'Read-BigFile'
Export-ModuleMember -Function 'Write-BigStream'