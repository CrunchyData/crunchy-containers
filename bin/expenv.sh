#!/bin/sh

# Copyright 2017 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Usage
#$ cat inputfile | expenv.sh > outputfile
#$ expenv.sh -f inputfile > outputfile
#$ expenv.sh < inputfile > outputfile
#$ expenv.sh -i -f inputfile // Replace inplace

while getopts ":if:" opt; do
  case $opt in
    f)
      useFile=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    i)
      inPlace=true
      ;;
  esac
done

if [ -n "$inPlace" ] && [ -z "$useFile" ]; then
 echo "Error: Option -i depends on option -f" >&2
fi

if [ -n "$inPlace" ]; then 
  tmpFile=`mktemp`
fi

# Eval each line and redirect to tmpFile if set, otherwise to process stdout
while read -r line; do
  eval "echo $line" >> "${tmpFile:-/proc/${$}/fd/1}"
done < "${useFile:-/proc/${$}/fd/0}"

# Overwrite file
if [ -n "$inPlace" ]; then 
  mv -- $tmpFile $useFile
fi

