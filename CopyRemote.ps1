#run this script to download selected files and directory trees from remote sever into windows directory.
bash -c "rsync -avz --include '*/' --include={'*.xml','OUTCAR'} --exclude='*' username@server:/directory/to/download /Destination/directory"
#use above command without 'bash -c' in linux.
