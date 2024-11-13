#!/bin/bash

# 获取版本号
read -p "version: " version
if [[ "" == $version ]] || [[ "\n" == $version ]]
then
    version=0.1.5
fi

pkgName=dfqo
pkgVer=${version}
buildDirPath=buildDir
buildBranch=diy_dev/0.1

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
 
 
### 安卓打包
cd androidBuildEnv/
java -jar ./apktool_2.9.3.jar d -s ./love2d.apk 
# 装载数据
cp AndroidManifest.xml apktool.yml love2d/ -rf
mkdir -p love2d/assets
cp ../../$fileName love2d/assets/game.love
# 打包
java -jar ./apktool_2.9.3.jar b -o 1.apk ./love2d
# 签名
jarsigner -verbose -keystore ccc.keystore -signedjar ./1_signed.apk ./1.apk release
# 将文件移至项目目录
mv ./1_signed.apk ../../${pkgName}_${pkgVer}.apk -f

 cd ../..
 rm -rf $buildDirPath
