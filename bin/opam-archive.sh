#!/bin/sh

set -uex

if [[ $# -eq 3 ]] ; then
    echo 'Usage: $0 BASEURL OPAM_REPO_GIT_SHA'
    exit 2
fi

BASEURL=$1
OPAM_REPO_GIT_SHA=$2

cd /www
# Checkout a specific commit as supplied by ocurrent-deployer pipeline.
git clone https://github.com/ocaml/opam-repository.git --single-branch --branch master opam-repository &&
    cd opam-repository &&
    git checkout ${OPAM_REPO_GIT_SHA} &&
    cd ..

mv opam-repository/* .
mv opam-repository/.git .
rm -rf opam-repository

# Overwrite 'repo' file, and dispatch all non-standard versions
cat <<EOF >repo
opam-version: "2.0"
browse: "https://${BASEURL}/pkg/"
upstream: "https://github.com/ocaml/opam-repository/tree/master/"
redirect: [
  "https://${BASEURL}/1.1" { opam-version < "1.2" }
  "https://${BASEURL}/1.2.0" { opam-version < "1.2.2" }
  "https://${BASEURL}/1.2.2" { opam-version < "2.0~" }
]
EOF
opam admin cache --link=archives ./cache
opam admin index --minimal-urls-txt
