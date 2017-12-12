#!/bin/bash -e

####################################################################
#  This script:
#  - downloads the source into SOURCEDIR
#  - checks out a particular commit
#  - configures and runs cmake and scan-build in TARGETDIR
#  - produces output in HTMLDIR
#
#  Example:
#  $ ./run_scanbuild.sh master ninja scanbuild
#
#  Results:
#  - scanbuild_20160331T133442_source
#  - scanbuild_20160331T133442_build
#  - scanbuild_20160331T133442_html
#
####################################################################

# usage
if [ "$#" != "4" ] ; then echo "Usage: $0 <repourl> <commitish> <make|ninja> <targetname>"; exit 1; fi

# configure
REPOURL=$1
COMMITISH=$2
if [ "$3" == "ninja" ] ; then USE_NINJA="1"; else USE_NINJA="0"; fi
TARGETNAME=$4

# prep
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )
NOW=$( date +"%Y%m%dT%H%M%S" )
SOURCEDIR=${SCRIPTPATH}/${TARGETNAME}_${NOW}_source
TARGETDIR=${SCRIPTPATH}/${TARGETNAME}_${NOW}_build
HTMLDIR=${SCRIPTPATH}/${TARGETNAME}_${NOW}_html

# source
git clone --recursive ${REPOURL} ${SOURCEDIR}
cd ${SOURCEDIR}
git checkout ${COMMITISH}
sed -i '/set(CMAKE_C_COMPILER/d' ${SOURCEDIR}/CMakeLists.txt
sed -i '/set(CMAKE_CXX_COMPILER/d' ${SOURCEDIR}/CMakeLists.txt

# target
mkdir -p ${TARGETDIR}

# environment
export PATH=/opt/irods-externals/clang3.8-0/bin:${PATH}
export PATH=/opt/irods-externals/cmake3.5.2-0/bin:${PATH}
export CC=clang
export CXX=clang++
export CCC_CC=${CC}
export CCC_CXX=${CXX}

# configure and compile
cd ${TARGETDIR}
if [ "${USE_NINJA}" == "1" ] ; then
  cmake -DCMAKE_C_COMPILER=`which ccc-analyzer` -DCMAKE_CXX_COMPILER=`which c++-analyzer` -GNinja ${SOURCEDIR}
  scan-build -o ${HTMLDIR} --use-analyzer `which clang` ninja
else
  cmake -DCMAKE_C_COMPILER=`which ccc-analyzer` -DCMAKE_CXX_COMPILER=`which c++-analyzer` ${SOURCEDIR}
  scan-build -o ${HTMLDIR} --use-analyzer `which clang` make -j`getconf _NPROCESSORS_ONLN`
fi
