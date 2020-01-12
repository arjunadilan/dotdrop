#!/usr/bin/env bash
# author: deadc0de6 (https://github.com/deadc0de6)
# Copyright (c) 2017, deadc0de6
#
# test jinja2 functions from func_file
# returns 1 in case of error
#

# exit on first error
set -e

# all this crap to get current path
rl="readlink -f"
if ! ${rl} "${0}" >/dev/null 2>&1; then
  rl="realpath"

  if ! hash ${rl}; then
    echo "\"${rl}\" not found !" && exit 1
  fi
fi
cur=$(dirname "$(${rl} "${0}")")

#hash dotdrop >/dev/null 2>&1
#[ "$?" != "0" ] && echo "install dotdrop to run tests" && exit 1

#echo "called with ${1}"

# dotdrop path can be pass as argument
ddpath="${cur}/../"
[ "${1}" != "" ] && ddpath="${1}"
[ ! -d ${ddpath} ] && echo "ddpath \"${ddpath}\" is not a directory" && exit 1

export PYTHONPATH="${ddpath}:${PYTHONPATH}"
bin="python3 -m dotdrop.dotdrop"

echo "dotdrop path: ${ddpath}"
echo "pythonpath: ${PYTHONPATH}"

# get the helpers
source ${cur}/helpers

echo -e "$(tput setaf 6)==> RUNNING $(basename $BASH_SOURCE) <==$(tput sgr0)"

################################################################
# this is the test
################################################################

# the dotfile source
tmps=`mktemp -d --suffix='-dotdrop-tests' || mktemp -d`
mkdir -p ${tmps}/dotfiles
# the dotfile destination
tmpd=`mktemp -d --suffix='-dotdrop-tests' || mktemp -d`
#echo "dotfile destination: ${tmpd}"
func_file=`mktemp`
func_file2=`mktemp`

# create the config file
cfg="${tmps}/config.yaml"

cat > ${cfg} << _EOF
config:
  backup: true
  create: true
  dotpath: dotfiles
  func_file:
  - ${func_file}
  - ${func_file2}
dotfiles:
  f_abc:
    dst: ${tmpd}/abc
    src: abc
profiles:
  p1:
    dotfiles:
    - f_abc
_EOF
#cat ${cfg}

cat << _EOF > ${func_file}
def func1(something):
  if something:
    return True
  return False
_EOF

cat << _EOF > ${func_file2}
def func2(inp):
  return not inp
_EOF

# create the dotfile
echo "this is the test dotfile" > ${tmps}/dotfiles/abc

# test imported function
echo "{%@@ if func1(True) @@%}" >> ${tmps}/dotfiles/abc
echo "this should exist" >> ${tmps}/dotfiles/abc
echo "{%@@ endif @@%}" >> ${tmps}/dotfiles/abc

echo "{%@@ if not func1(False) @@%}" >> ${tmps}/dotfiles/abc
echo "this should exist too" >> ${tmps}/dotfiles/abc
echo "{%@@ endif @@%}" >> ${tmps}/dotfiles/abc

echo "{%@@ if func2(True) @@%}" >> ${tmps}/dotfiles/abc
echo "nope" >> ${tmps}/dotfiles/abc
echo "{%@@ endif @@%}" >> ${tmps}/dotfiles/abc

echo "{%@@ if func2(False) @@%}" >> ${tmps}/dotfiles/abc
echo "yes" >> ${tmps}/dotfiles/abc
echo "{%@@ endif @@%}" >> ${tmps}/dotfiles/abc

# install
cd ${ddpath} | ${bin} install -f -c ${cfg} -p p1 -V

#cat ${tmpd}/abc

grep '^this should exist$' ${tmpd}/abc >/dev/null
grep '^this should exist too$' ${tmpd}/abc >/dev/null
grep '^yes$' ${tmpd}/abc >/dev/null
set +e
grep '^nope$' ${tmpd}/abc >/dev/null && exit 1
set -e

## CLEANING
rm -rf ${tmps} ${tmpd} ${func_file} ${func_file2}

echo "OK"
exit 0