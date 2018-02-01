#!/bin/bash

echo "[*] Unzipping SureCheck .gz file"
gunzip $1

file=$(echo $1 | sed 's/\.gz//')
echo "[*] Processing file $file"

RHEL=$(grep "UNIX/Linux/RHEL" $file)
#FEDO=$(grep "UNIX/Linux/RHEL" $file)

if [ -z "$RHEL" ]
then
   echo "[-] RedHat script not detected nothing to do. Script extracted $RHEL"
else
   echo "[+] RedHat script detected replacing with a valid value"
   sed -i ':a;N;$!ba;s/\(----- SURECHECK-VALUE: PLATFORM-CAT-ETC-REDHAT-RELEASE -----\)\n[^\n]*/\1\nRed Hat Enterprise Linux Server release 6.5 \(Santiago\)/' $file
fi

gzip $file
echo "[*] All done!"
