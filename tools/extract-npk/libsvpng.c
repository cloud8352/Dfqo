// C文件
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "svpng.inc"

/* 所有注册给Lua的C函数具有
 *  * "typedef int (*lua_CFunction) (lua_State *L);"的原型。
 *   */

static int savePNG(lua_State *L)
{
    // 参数1
    size_t len = 0;
    const char* filePath = luaL_checklstring(L, 1, &len);
    // printf("filePath= %s\n", filePath);

    // 参数2
    int w = luaL_checkint(L, 2);
    // printf("w= %d\n", w);

    // 参数3
    int h = luaL_checkint(L, 3);
    // printf("h= %d\n", h);

    //// 参数4
    // 检验第4个参数是否为lua表格型
    if (!lua_istable(L, 4)) {
        printf("savePNG() input parameter4 type is error, must be lua table");
	    lua_pushboolean(L, 0); // 函数返参入栈，传给调用者
        return 1; /* number of results */
    }

    int imgDataLength = h * w * 4;
    unsigned char imgData[imgDataLength];
    for (int i = 1; i <= imgDataLength; i++) {
        lua_rawgeti(L, 4, i);
        imgData[i - 1] = lua_tointeger(L, -1); // 把上一个内容出栈
        lua_pop(L, 1);
    }

    // 参数获取完成，执行实际c函数
    FILE* fp = fopen(filePath, "wb");
    if (NULL == fp) {
        printf("%s open failed!", filePath);

	    lua_pushboolean(L, 0);
        return 1;
    }
    svpng(fp, w, h, imgData, 1);

    fclose(fp);

    // 执行结束，返回结果
    lua_pushboolean(L, 1);
    return 1;  /* number of results */
}

static const struct luaL_Reg libsvpng[] = {
    {"savePNG", savePNG},
    {NULL, NULL}
};

extern int luaopen_libsvpng(lua_State* L)
{
    luaL_register(L, "libsvpng", libsvpng);
    return 1;
}