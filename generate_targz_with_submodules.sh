#!/bin/bash -e

##########################################################
#
# Generates a compressed tarball (tar.gz) of an entire
# git super-project, including submodules.
#
# - Can checkout any commit-ish (commit/tag/branch)
# - Removes .git-specific files
#
# Sample Result:
#  irods-master.tar.gz
#
##########################################################

# setup
PROJECTNAME=irods
REPOURL=https://github.com/irods/irods.git

# parameter
if [ $# -eq 1 ] ; then
  COMMITISH=$1
else
  COMMITISH=master
fi

# prepare the working space
ORIGINALPWD=$( pwd )
SCRIPTNAME=$( basename "$0" )
TMPDIR=$( mktemp -d "/tmp/$SCRIPTNAME.XXXXXX" )
SOURCEDIR=$TMPDIR/$PROJECTNAME-$COMMITISH
ARCHIVEFILE=$PROJECTNAME-$COMMITISH.tar.gz
mkdir -p $SOURCEDIR
git clone --recursive $REPOURL $SOURCEDIR
cd $SOURCEDIR
git checkout $COMMITISH
git submodule init
git submodule update
git clean -xffd

# build and gather archive
cd $SOURCEDIR/..
tar czf $ARCHIVEFILE --exclude .git --exclude .gitignore --exclude .gitmodules --exclude .gitattributes $PROJECTNAME-$COMMITISH
mv $ARCHIVEFILE $ORIGINALPWD

# return, clean up, and show results
cd $ORIGINALPWD
rm -rf $TMPDIR
ls -al $ARCHIVEFILE

# done
exit 0
