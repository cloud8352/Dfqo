#! /bin/bash
### 将Dfq的pkm文件转换称png文件的脚本
### 确保已安装 tacentview，安装方法见：https://github.com/bluescan/tacentview

inputDir="InputDir"
mkdir ${inputDir}

outputDir="OutputDir"
rm -rf ${outputDir}
mkdir ${outputDir}

cd ${inputDir}
pkmFilePathList=$(find . -type f -name "*.pkm")
for path in ${pkmFilePathList}; do
    ktxFilePath=${path%.pkm}.ktx
    echo ${ktxFilePath}
    mv ${path} ${ktxFilePath}
    tacentview -c --in ktx ${ktxFilePath} --out png
    rm ${ktxFilePath}
done

cd ..
mv -f ${inputDir}/* ${outputDir}/
echo "转换完成"
