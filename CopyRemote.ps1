$loc=Get-Location
bash -c "rsync -avz --include '*/' --include={'*.xml','OUTCAR'} --exclude={'*','*rela*'} asaboor@comet.sdsc.xsede.org:/home/asaboor/work/d_core_Interface/GaAs ."
ForEach($dir in $((Get-ChildItem -Recurse -Directory).FullName)){
    Set-Location $dir;
    Write-Host "$dir" -ForegroundColor Red
    Get-VaspProjection;
}
Set-Location $loc