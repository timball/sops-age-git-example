# git + sops + age + secrets

#### --timball@gmail.com
#### Sun  9 Jul 21:41:48 EDT 2023

## overview
We are trying to setup a repo with sane password storage and not be a big PITA to use. 
While it is debatable if we want to upload passwords to a git repot at all, we can
all agree that we should never upload unencrypted passwords. 

In these examples we'll be using `sops` and `age` to do the encryption. We wrote some bash scripts
to run as git filters such that on the local filesystem files can be decrypted
and will automatically be encrypted before being committed.

git commits and diffs should work as expected. 
All secrets stored in git will be encrypted, but the local copies will be in clear text if you have the right key

We admit that using Hashicorp Vault, AWS KMS, or GCP KMS would be the better way to go, but this is for a quick and dirty. Maybe next repo I do is how to set this up w/ a cloud based secrets manager.

## setup
0. `git init` a repo or however you want to create a repo

1. Create an `age` key, and export the public-key and make sure to put
`age-key.txt` into `.gitignore` add public key to repo. NOTICE! This means that
the `secrets/age-key.txt` needs to be distributed out of band.
```sh
    $ age-keygen -o secrets/age-key.txt
    $ age-keygen -y -o secrets/public-age-keys.txt secrets/age-key.txt
    $ echo "secrets/age-key.txt" >> .gitignore
    $ git add secrets/public-age-keys.txt
    $ git commit -m "add public key to secrets/"
```

2. Copy scripts into a `bin/` directory and add to repo
```sh
    $ mkdir bin
    $ wget https://raw.githubusercontent.com/timball/sops-test/main/bin/encrypt.sh -o bin/encrypt.sh
    $ wget https://raw.githubusercontent.com/timball/sops-test/main/bin/decrypt.sh -o bin/decrypt.sh
    $ chmod +x bin/*.sh
    $ git add bin/*.sh
    $ git commit -m "add encrypt/decrypt sops filters scripts" 
```

3. add configs to git. This creates a filter named `sop`. The `%f` allows the
script to recieve the filename. This has to done to repo each time it's checked out
```sh
    $ git config --local filter.sops.smudge $(pwd)/bin/decrypt.sh %f
    $ git config --local filter.sops.clean $(pwd)/bin/encrypt.sh %f
    $ git config --local filter.sops.required true
```

4. setup `.gitattributes` for the files that need it
```sh
    $ echo 'secrets.json filter=sops' > .gitattributes
    $ git add .gitattributes
    $ git commit -m "add sops filter to secret.json in .gitattributes"
```

5. add files and make sure that the in-line secrets are enumerated in
`secrets/secrets.regex`. right now it is just one line that sops
--encrypted-regex uses to decide what fields need to encrypted.
```sh
    $ echo "passwd|API" > secrets/secrets.regex
    $ git add secrets/secrets.regex
    $ git add secrets.json
    $ git commit -m "add secrets.json and update secrets.regex"
```


## key rotation
:shrug: https://technotim.live/posts/rotate-sops-encryption-keys/
1. seems to rotate keys on a local repo that has secrets files decrypted all one has to do is create a new key and public key file
```sh
    $ age-keygen -o secrets/age-key.txt
    $ age-keygen -y -o secrets/public-age-keys.txt secrets/age-key.txt
    $ touch <secrets file>
```

## git diff
https://github.com/getsops/sops#showing-diffs-in-cleartext-in-git
### the following didn't work and is preserved for future fiddling. As is `git diff` will spit still useful information.

1. for each file that you need a sops differ modify .gitattributes accordingly. name "sopsdiffer" is arbitrary
```
    example.yaml diff=sopsdiffer
```
2. set a git config for the differ
```sh
    $ git config diff.sopsdiffer.textconv "sops -d"
```

3. test 
```sh
    $ git diff example.yaml
```

## caveats
`sops` can in-line encrypt secrets for ini, yaml, json, env files. All other files
will be completely encrypted. 

you need to update .gitattributes w/ files you want to encrypt

you need to update secrets/secrets.regex w/ the individual regex parts you need
need to encrypt

remeber that item #3 git config must be done for each checked out repo

## appendix and non-throw-away-notes
### testing SOPS w/ gnupg. DO NOT USE .gnupg, it will make your brain bleed.

https://blog.gitguardian.com/a-comprehensive-guide-to-sops/

1. create a gnupg key w/ no password
2. create a ~/.sops.yaml 
3. edit/encrypte whole files w/ `sops <filename>`
4. do bits of file w/ `sops --encrypt --in-place --encrypted-regex 'passwd|APIKEY' example.yaml`
5. still need to figure out how to deal w/ this at deploy time? `sops -d <file>`
6. maybe don't use gnupg and use `age` instead 
7. enc and decrypt using git pre-commit hooks for push and pull to make this automagic?
    - https://github.com/yuvipanda/pre-commit-hook-ensure-sops

WANTS:
pre-commit
if $secret-file is new than $enc-file pass $secret-file thru `sop` and update $enc-file

post-merge
if $enc-file is newer than $secret-file then decrypt w/ `sop`

git status ignores files that have .enc. versions 
aka if foo.enc.yaml exists then ignore example.yaml


### use SOPS + age 
https://technotim.live/posts/secret-encryption-sops/

https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html
