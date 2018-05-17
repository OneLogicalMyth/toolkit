#!/bin/bash

#  Gets an open ports to host list from a gnmap output file
awk -F'[/ ]' '{h=$2; for(i=1;i<=NF;i++){if($i=="open"){print h,$(i-1)}}}' $1
