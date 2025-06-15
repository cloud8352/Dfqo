--[[
    desc: FILE, a lib that encapsulate file function.
    author: Musoucrow
    since: 2018-3-15
    alter: 2019-9-28
]]--

local _FILE = {} ---@class Lib.FILE

---@return string
function _FILE.getSaveDirectory()
    return love.filesystem.getSaveDirectory()
end

---@param path string
---@return bool
function _FILE.Exists(path)
    local info = love.filesystem.getInfo(path)
    return info ~= nil
end

---@param path string
---@return bool
function _FILE.MkDir(path)
    return love.filesystem.createDirectory(path)
end

---@param path string @It is a full path
---@return string
function _FILE.ReadExternalFile(path)
    local file = io.open(path, "rb")

    if (not file) then
        return
    end

    local content = file:read("*a")
    file:close()

    return content
end

---@param path string
---@return string
function _FILE.ReadFile(path)
    if not _FILE.Exists(path) then
        print("_FILE.ReadFile() ", "file not exists, ", path)
    end
    return love.filesystem.read(path)
end

---@param filePath string
---@param str string 数据
---@return boolean, string succeed errMsg
function _FILE.WriteFile(filePath, str)
    local stringLib = require("lib.string")
    local succeed = true
    local errMsg = ""
    local dirPath = stringLib.ToDirectory(filePath)
    -- 如果目录不存在，就创建
    if not _FILE.Exists(dirPath) then
        local ok = _FILE.MkDir(dirPath)
        if not ok then
            errMsg = dirPath .. " dir make failed!"
            print("_FILE.WriteFile(filePath, str)", errMsg)
            return false, errMsg
        end
    end

    succeed, errMsg = love.filesystem.write(filePath, str)
    return succeed, errMsg
end

---@param path string
---@return table
function _FILE.ReadScript(path)
    return loadstring(_FILE.ReadFile(path))()
end

---@param filePath string
---@return boolean, string succeed errMsg
function _FILE.Delete(filePath)
    local succeed = true
    local errMsg = ""

    if not _FILE.Exists(filePath) then
        succeed = false
        errMsg = filePath .. " not exists!"
        return succeed, errMsg
    end

    succeed, errMsg = love.filesystem.remove(filePath)
    return succeed, errMsg
end

---@param path string
---@param decoder FileDecoder @file, base64
---@return FileData
function _FILE.NewFileData(path, decoder)
    return love.filesystem.newFileData(_FILE.ReadFile(path), path, decoder)
end

---@param dirPath string
---@return table<int, string> fileNameList
function _FILE.ListDirectoryItems(dirPath)
    return love.filesystem.getDirectoryItems(dirPath)
end

return _FILE
