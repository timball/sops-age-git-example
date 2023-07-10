#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${scriptDir}/.." || exit 1

export SOPS_AGE_KEY_FILE=${scriptDir}/../secrets/age-key.txt

# figure outfile type by extension
filename=$(basename -- ${1})
ext=${filename##*.}

exec 3<<< "$(cat $1)"

types="yaml json ini env"
for i in "${types[@]}"; do
    if [[ $i =~ ${ext} ]]; then
        sops --decrypt --age ${SOPS_AGE_KEY_FILE} --input-type ${ext} --output-type ${ext} /dev/fd/3
    else
        sops --decrypt --age ${SOPS_AGE_KEY_FILE} /dev/fd/3
    fi
done
