#!/bin/bash -e

_DATE=$(date +%Y-%m-%d)
_MIRROR_NAME="exawind-${_DATE}"
_MIRROR="s3://cache2.e4s.io/exawind/${_DATE}"
_SIGNING_KEY=~/keys/e4s.new.priv

[[ ! -d "$_DATE" ]] && mkdir "$_DATE"
cd "$_DATE"

# copy environments for compiler and for exawind products
cp ../compiler-spack.yaml ../exawind-spack.yaml .

# clone spack if not done already
[[ ! -d spack ]] && git clone https://github.com/eugeneswalker/spack --branch exawind --depth 2

# capture spack commit
(
 cd spack
 git rev-parse HEAD~1 >> ../spack-commit.txt
)

# activate spack
. spack/share/spack/setup-env.sh

# install compiler environment
cp compiler-spack.yaml spack.yaml
spack -e . concretize -f | tee compiler-dag.txt
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
time spack -e . install --no-cache -j16
_GCC=$(spack -e . location -i gcc)

# register compiler with spack
cp exawind-spack.yaml spack.yaml
spack -e . compiler add "${_GCC}" 
spack -e . concretize -f | tee exawind-dag.txt
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
time spack -e . install --no-cache -j16

spack mirror add "${_MIRROR_NAME}" "${_MIRROR}"

spack gpg trust "${_SIGNING_KEY}"

cp ../secrets.env .
. ./secrets.env
cp ../cache-all.sh .
time ./cache-all.sh "${_MIRROR_NAME}"
spack buildcache update-index -d "${_MIRROR}" --keys

mc cp spack-commit.txt llnl/cache2.e4s.io/exawind/${_DATE}/
