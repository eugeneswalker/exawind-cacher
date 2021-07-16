#!/bin/bash -e

_DATE="${1}"
_MIRROR_ROOT=https://cachce2.e4s.io
_MIRROR="${_MIRROR_ROOT}/exawind/${_DATE}"

[[ ! -f spack-commit.txt ]] \
 && wget ${_MIRROR}/spack-commit.txt

[[ ! -d spack ]] && git clone https://github.com/spack/spack
(cd spack && git checkout $(cat ../spack-commit.txt))

. spack/share/spack/setup-env.sh

[[ ! -f compiler-spack.yaml ]] \
 && wget ${_MIRROR}/compiler-spack.yaml

[[ ! -f exawind-spack.yaml ]] \
 && wget ${_MIRROR}/exawind-spack.yaml

cp compiler-spack.yaml spack.yaml
spack -e . mirror add exawind ${_MIRROR}
spack buildcache keys -it
time spack -e . concretize -f
time spack -e . install --cache-only
COMPILER=$(spack -e . location -i gcc)

cp exawind-spack.yaml spack.yaml
spack -e . mirror add exawind ${_MIRROR}
spack -e . compiler add "${COMPILER}"

time spack -e . concretize -f
time spack -e . install --cache-only
