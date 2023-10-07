#!/bin/sh

# 添加链接库搜索路径
export LOVE_LAUNCHER_LOCATION=love2d
export LD_LIBRARY_PATH="${LOVE_LAUNCHER_LOCATION}/lib/x86_64-linux-gnu:${LOVE_LAUNCHER_LOCATION}/usr/bin:${LOVE_LAUNCHER_LOCATION}/usr/lib:${LOVE_LAUNCHER_LOCATION}/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
/sbin/ldconfig -p | grep -q libstdc++ || export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${LOVE_LAUNCHER_LOCATION}/libstdc++/"

# 运行
exec ${LOVE_LAUNCHER_LOCATION}/usr/bin/love ./ debug