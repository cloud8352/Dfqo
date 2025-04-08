#!/bin/bash

# 获取版本号
read -p "version: " version
if [[ "" == $version ]] || [[ "\n" == $version ]]
then
    version=0.1.5
fi

pkgName=Dfqo
pkgVer=${version}
buildDirPath=buildDir
buildBranch=$(git branch --show-current)

rm -rf $buildDirPath
#mkdir $buildDirPath

git init $buildDirPath

git push $buildDirPath $buildBranch

cd $buildDirPath
git checkout $buildBranch
git log -n 1
rm -rf .git

cp -rf ../asset .
cp -rf ../config/asset ./config/

fileName=${pkgName}_${pkgVer}.zip
filePath=../$fileName
rm $filePath
7z a -tzip -r $filePath * -x!androidBuildEnv

cd ..
rm -rf $buildDirPath
