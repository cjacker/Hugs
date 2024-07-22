#!/bin/bash

#keep silent
downloader="wget -q"

#verify_file_with_md5 <file> <md5sum>
#if file exists and md5sum matched, return 0
#otherwise, return 1

verify_file_with_md5()
{
  file=$1;
  md5=$2;

  if [ ! -f $file ]; then
     return 1
  fi
 
  filemd5=$(md5sum $file|awk '{print $1}')
  if [ $md5 == $filemd5 ]; then
     return 0
  else
     return 1
  fi
}

mkdir -p _download

#create dir, just in case.
mkdir -p packages

#download packages from hackage.haskell.org
while read line;
do 
  pkg=$(echo $line|awk -F' ' '{print $1}')
  pkg_name=$(echo $pkg|awk 'BEGIN{FS=OFS="-"}{NF--; print}')
  pkg_md5=$(echo $line|awk -F' ' '{print $2}')

  echo -n "Download $pkg : "
  #verify package if already exist.
  verify_file_with_md5 _download/$pkg.tar.gz $pkg_md5
  ret=$?

  #check ret value, if not 0, download the package.
  if [ "$ret" -eq 0 ]; then
     echo "[OK]"
  else
     $downloader http://hackage.haskell.org/package/$pkg/$pkg.tar.gz -O _download/$pkg.tar.gz
     verify_file_with_md5 _download/$pkg.tar.gz $pkg_md5
     retd=$?
     if [ $retd -eq 0 ]; then
        echo "[OK]"
     else
        echo "[FAILED]"
        exit 1
     fi
  fi

  #extract package
  echo -n "Extract $pkg : "
  rm -rf packages/$pkg_name
  mkdir -p packages/$pkg_name
  tar xf _download/$pkg.tar.gz -C packages/$pkg_name --strip-component=1
  ret_tar=$?
  if [ $ret_tar -eq 0 ]; then
     echo "[OK]"
  else
     echo "[FAILED]"
     exit 1
  fi
done <packages.list

#fix perms in case.
find packages -name configure|xargs chmod +x

#apply patches for packages.
cat patches/array-001-fix-clang-preprocess.patch|patch -p1 -d packages/array
cat patches/cabal-001-find-hsc2hs-and-cpphs-with-hugs-suffix.patch|patch -p1 -d packages/Cabal
cat patches/cabal-002-find-happy-with-hugs-suffix.patch|patch -p1 -d packages/Cabal
cat patches/directory-001-no-depend-on-unix.patch|patch -p1 -d packages/directory
cat patches/HGL-001-fix-with-new-base.patch|patch -p1 -d packages/HGL
cat patches/network-001-fix-ucred_struct.patch|patch -p1 -d packages/network
cat patches/network-002-fix-inline-link-issue.patch|patch -p1 -d packages/network
cat patches/process-001-make-most-func-works.patch|patch -p1 -d packages/process
cat patches/process-002-enable-base4-code-avoid-introduce-unix-to-bootlib.patch|patch -p1 -d packages/process
cat patches/process-003-add-bootlib-flag.patch|patch -p1 -d packages/process
cat patches/unix-001-add-c_rename.patch|patch -p1 -d packages/unix
cat patches/unix-002-fix-inline-link-issue.patch|patch -p1 -d packages/unix
cat patches/haxml-001-fix-hugs.patch|patch -p1 -d packages/HaXml
cat patches/GLUT-001-add-modifier-key.patch|patch -p1 -d packages/GLUT

#prepare alex sources.
cat patches/alex-001-use-cpphs-instead-ghc.patch|patch -p1 -d packages/alex
cat patches/alex-002-fix-main-to-match-hugs.patch|patch -p1 -d packages/alex
rm -rf packages/alex/src/Scan.x
rm -rf packages/alex/src/Scan.hs
rm -rf packages/alex/src/Parser.y
cp patches/alex/*.hs packages/alex/src


download_tool()
{
  tname=$1
  tver=$2
  tmd5=$3
  ttar=$1-$2.tar.gz

  echo -n "Download $tname : "
  #verify package if already exist.
  verify_file_with_md5 _download/$ttar $tmd5
  ret=$?
  #check ret value, if not 0, download the package.
  if [ "$ret" -eq 0 ]; then
     echo "[OK]"
  else
     $downloader http://hackage.haskell.org/package/$tname-$tver/$ttar -O _download/$ttar
     verify_file_with_md5 _download/$ttar $tmd5
     retd=$?
     if [ $retd -eq 0 ]; then
        echo "[OK]"
     else
        echo "[FAILED]"
        exit 1
     fi
  fi
  
  echo -n "Extract $tname : "
  rm -rf $tname
  mkdir -p $tname
  tar xf _download/$ttar -C $tname --strip-component=1
  ret_tar=$?
  if [ $ret_tar -eq 0 ]; then
     echo "[OK]"
  else
     echo "[FAILED]"
     exit 1
  fi
}

cpphs_ver=1.11
cpphs_md5=ece7f9a5335a8fd569f0b8c7153ecfaa
hsc2hs_ver=0.67.20061107
hsc2hs_md5=b94a0374eab368d8291134eb6a0c200a
happy_ver=1.18.4
happy_md5=614e3ef9623dbeefc4c8ca699912efb4


download_tool "cpphs" $cpphs_ver $cpphs_md5
download_tool "hsc2hs" $hsc2hs_ver $hsc2hs_md5
download_tool "happy" $happy_ver $happy_md5

#apply patch for hsc2hs
cat patches/hsc2hs-001-add-alignment-feature.patch|patch -p1 -d hsc2hs

#apply patch for happy
cat patches/happy-001-use-cpphs-hugs-to-generate-templates.patch|patch -p1 -d happy
cp patches/happy/*.hs happy/src/

#get base 4.0
pushd _download >/dev/null
echo -n "Fetch base-4.0 : "
rm -rf ./base
darcs get -t "6.10 branch has been forked" --repodir=./base http://darcs.haskell.org/packages/base >/dev/null 2>&1;
ret_darcs=$?
if [ $ret_darcs -eq 0 ]; then
   echo "[OK]"
else
   echo "[FAILED]"
   rm -rf base
   exit 1
fi
rm -rf ../packages/base
cp -r base ../packages
rm -rf ../packages/base/_darcs
popd >/dev/null

cat patches/base-001-check-gettimeofday.patch|patch -p1 -d packages/base
cat patches/base-002-fix-upstream-mistake.patch|patch -p1 -d packages/base
cat patches/base-003-fix-clang-preprocess.patch|patch -p1 -d packages/base
cat patches/base-004-utf8-to-ascii.patch|patch -p1 -d packages/base

find */ -name config.sub -exec cp config.sub '{}' \;
find */ -name config.guess -exec cp config.guess '{}' \;
