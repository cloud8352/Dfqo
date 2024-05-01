#!/bin/sh

pkgName=dfqo
pkgVer=0.1.5
buildDirPath=buildDir
buildBranch=origin/diy

rm -rf $buildDirPath
#mkdir $buildDirPath

git init $buildDirPath

git push $buildDirPath $buildBranch

cd $buildDirPath
git checkout $buildBranch
git log -n 1
rm -rf .git

fileName=${pkgName}_${pkgVer}.zip
rm $filePath
7z a -tzip -r ../$fileName *
 
 
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
