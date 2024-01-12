--[[
	desc: TABLE, a lib that encapsulate table function.
	author: Musoucrow
	since: 2018-3-14
	alter: 2018-12-14
]]
--

local function _PrivateTips()
    assert(nil, "The table is const.")
end

local _TABLE = {} ---@class Lib.TABLE

---@param a table
---@param b table
function _TABLE.Paste(a, b) --Paste the contents of a to b.
    for k, v in pairs(a) do
        b[k] = v
    end
end

---@param tab table
---@param separationString string @default=""
function _TABLE.Print(tab, separationString)
    separationString = separationString or ""

    for k, v in pairs(tab) do
        print(separationString .. k .. ": " .. tostring(v))

        if (type(v) == "table") then
            _TABLE.Print(v, separationString .. "    ")
        end
    end
end

---@param tab table
function _TABLE.PrintKeyList(tab)
    for k, v in pairs(tab) do
        print(k .. ": " .. tostring(v))
    end
end

---@param tab table
function _TABLE.Clear(tab)
    for k in pairs(tab) do
        tab[k] = nil
    end
end

---@param object table
---@param table table @Clone object's container, default={}
---@return table
function _TABLE.Clone(object, table)
    local lookup_table = {}
    local function _copy(objectTmp)
        if type(objectTmp) ~= "table" then
            return objectTmp
        elseif lookup_table[objectTmp] then
            return lookup_table[objectTmp]
        end

        local new_table = table or {}
        lookup_table[objectTmp] = new_table

        for key, value in pairs(objectTmp) do
            new_table[_copy(key)] = _copy(value)
        end

        return setmetatable(new_table, getmetatable(objectTmp))
    end

    return _copy(object, table)
end

---深度拷贝Table
---@param obj table
---@return table
function _TABLE.DeepClone(obj)
    local InTable = {};
    local function Func(obj)
        if type(obj) ~= "table" then   --判断表中是否有表
            return obj;
        end
        local NewTable = {};  --定义一个新表
        InTable[obj] = NewTable;  --若表中有表，则先把表给InTable，再用NewTable去接收内嵌的表
        for k,v in pairs(obj) do  --把旧表的key和Value赋给新表
            NewTable[Func(k)] = Func(v);
        end
        return setmetatable(NewTable, getmetatable(obj))--赋值元表
    end
    return Func(obj) --若表中有表，则把内嵌的表也复制了
  end

function _TABLE.LightClone(tab)
    local new = {}

    for k, v in pairs(tab) do
        new[k] = v
    end

    return new
end

---@param tab table
---@param agent table
---@return table
function _TABLE.NewAgent(tab, agent)
    local agent = agent or {}
    local mt = { __index = tab }
    setmetatable(agent, mt)

    for k, v in pairs(tab) do
        if (type(v) == "table") then
            agent[k] = _TABLE.NewAgent(v)
        end
    end

    return agent
end

---@param tab table
function _TABLE.NewConst(tab)
    local tabMt = getmetatable(tab)

    if (not tabMt) then
        tabMt = {}
        setmetatable(tab, tabMt)
    end

    local const = tabMt.__const

    if (not const) then
        const = {}
        tabMt.__const = const

        local constMt = {
            __index = tab,
            __newindex = _PrivateTips,
            __const = const
        }

        setmetatable(const, constMt)
    end

    for k, v in pairs(tab) do
        if (type(v) == "table") then
            tab[k] = _TABLE.NewConst(v)
        end
    end

    return const
end

---@param tab table
---@return number
function _TABLE.Len(tab)
    local meta = getmetatable(tab)

    if (meta and meta.__index) then
        return #meta.__index
    else
        return #tab
    end
end

---@generic T: table, K, V
---@param tab table
---@return fun(table: table<K, V>, index?: K):K, V
---@return T
function _TABLE.Pairs(tab)
    local meta = getmetatable(tab)

    if (meta and meta.__index) then
        return pairs(meta.__index)
    else
        return pairs(tab)
    end
end

---@param agent table
---@param allowBase boolean
---@return table
function _TABLE.GetOrigin(agent, allowBase)
    while (true) do
        local metatable = getmetatable(agent)

        if (metatable and metatable.__index and (not allowBase or (allowBase and not metatable.__base))) then
            agent = metatable.__index
        else
            return agent
        end
    end
end

---@param value obj @Except function and userdata.
---@param key string @It don't need in active using.
---@param scope string @It don't need in active using.
function _TABLE.Deserialize(value, key, scope) --Table to string.
    local tp = type(value)
    local key_str

    if (key and type(key) == "string") then
        key_str = "['" .. tostring(key) .. "']"
    end

    if (tp == "table") then
        local list = {}
        local isFirst = not scope

        if (isFirst) then
            list[1] = "return {\n"
            scope = ""
        elseif (not key or type(key) == "number") then
            list[1] = scope .. "{\n"
        else
            list[1] = scope .. key_str .. " = {\n"
        end

        for k, v in pairs(value) do
            list[#list + 1] = _TABLE.Deserialize(v, k, scope .. "	")
        end

        if (isFirst) then
            list[#list + 1] = "}"
        else
            list[#list + 1] = scope .. "},\n"
        end

        return table.concat(list)
    elseif (tp == "string") then
        if (not scope and not key) then
            return "return [[" .. value .. "]]"
        elseif (key_str) then
            return scope .. key_str .. [[ = "]] .. value .. [["]] .. ",\n"
        else
            return scope .. [["]] .. value .. [["]] .. ",\n"
        end
    elseif (tp == "number") then
        if (not scope and not key) then
            return "return " .. value
        elseif (type(key) == "string") then
            return scope .. key_str .. " = " .. value .. ",\n"
        else
            return scope .. value .. ",\n"
        end
    elseif (tp == "boolean") then
        if (not scope and not key) then
            return "return " .. value
        elseif (key_str) then
            return scope .. key_str .. " = " .. tostring(value) .. ",\n"
        else
            return scope .. tostring(value) .. ",\n"
        end
    end
end

---@param value obj @Except function and userdata.
---@param key string @It don't need in active using.
---@param scope string @It don't need in active using.
function _TABLE.Deserialize_Compressed(value, key, scope)
    local tp = type(value)
    local key_str

    if (key and type(key) == "string") then
        key_str = "['" .. tostring(key) .. "']"
    end

    if (tp == "table") then
        local list = {}
        local isFirst = not scope

        if (isFirst) then
            list[1] = "return {"
            scope = ""
        elseif (not key or type(key) == "number") then
            list[1] = scope .. "{"
        else
            list[1] = scope .. key_str .. "={"
        end

        for k, v in pairs(value) do
            list[#list + 1] = _TABLE.Deserialize_Compressed(v, k, scope)
        end

        if (isFirst) then
            list[#list + 1] = "}"
        else
            list[#list + 1] = scope .. "},"
        end

        return table.concat(list)
    elseif (tp == "string") then
        if (not scope and not key) then
            return "return [[" .. value .. "]]"
        elseif (key_str) then
            return scope .. key_str .. [[="]] .. value .. [["]] .. ","
        else
            return scope .. [["]] .. value .. [["]] .. ","
        end
    elseif (tp == "number") then
        if (not scope and not key) then
            return "return " .. value
        elseif (type(key) == "string") then
            return scope .. key_str .. "=" .. value .. ","
        else
            return scope .. value .. ","
        end
    elseif (tp == "boolean") then
        if (not scope and not key) then
            return "return " .. value
        elseif (key_str) then
            return scope .. key_str .. "=" .. tostring(value) .. ","
        else
            return scope .. tostring(value) .. ","
        end
    end
end

---@param a table
---@param b table
---@return boolean
function _TABLE.CompareKey(a, b)
    local ca = 0
    local cb = 0

    for k in pairs(a) do
        ca = ca + 1
    end

    for k in pairs(b) do
        cb = cb + 1
    end

    if (ca ~= cb) then
        return false
    end

    for k in pairs(a) do
        if (b[k] == nil) then
            return false
        end
    end

    return true
end

---@param keys table<string, boolean>
---@return function
---@return bolean
function _TABLE.NewCdataPairs(keys)
    local function _Pairs(tab, key)
        local nk = next(keys, key)
        local nv

        if (nk) then
            nv = tab[nk]
        end

        return nk, nv
    end

    return function(tab)
        return _Pairs, tab
    end
end

---@param tab table
---@param pos number
function _TABLE.Pop(tab, pos)
    pos = pos or 1

    local v = tab[pos]
    table.remove(tab, pos)

    return v
end

return _TABLE
