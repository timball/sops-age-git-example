#!/bin/bash
#
# based on https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html
#
# --timball@gmail.com
#
# Sun  9 Jul 21:32:40 EDT 2023

# make sure we exist
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${scriptDir}/.." || exit 1

## fields to encrypt regex
REGEX=$(cat ${scriptDir}/../secrets/secrets.regex)

# which key are we using?
export SOPS_AGE_RECIPIENTS=$(<${scriptDir}/../secrets/public-age-keys.txt)
## this does enc in-place
#sops --encrypt --age ${SOPS_AGE_RECIPIENTS} --encrypted-regex "^(passwd|APIKEY)$" --in-place ${1}

# figure outfile type by extension
# sops only deals w/ YAML, JSON, ENV, and INI
filename=$(basename $1)
ext=${filename##*.}

# open ${1} as fd3 bc stuff is coming in stdin but also bc of git rm file might not exist?
exec 3<<< "$(cat $1)"

# if it's a ft that sops understands
types="yaml json ini env"
for i in "${types[@]}"; do 
    if [[ $i =~ ${ext} ]]; then 
        # a file that sops knows about
        sops --encrypt --age ${SOPS_AGE_RECIPIENTS} --encrypted-regex ${REGEX} --input-type ${ext} --output-type ${ext} /dev/fd/3
    else
        sops --encrypt --age ${SOPS_AGE_RECIPIENTS} /dev/fd/3
    fi
done 
