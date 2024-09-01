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
    return love.filesystem.exists(path)
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

---@param dirPath string
---@param fileName string
---@param str string 数据
---@return boolean, string succeed errMsg
function _FILE.WriteFile(dirPath, fileName, str)
    local errMsg = ""
    -- 如果目录不存在，就创建
    local absoluteDirPath = dirPath
    local dirPathStrPrefix = string.sub(dirPath, 1, 1)
    if dirPathStrPrefix ~= "/" then
        absoluteDirPath = _FILE.getSaveDirectory() .. "/" .. dirPath
    end
    if not _FILE.Exists(absoluteDirPath) then
        local ok = _FILE.MkDir(dirPath)
        if not ok then
            errMsg = dirPath .. " dir make failed!"
            print("_FILE.WriteFile(dirPath, fileName, str)", errMsg)
            return false, errMsg
        end
    end

    -- 以绝对路径创建文件
    local filePath = absoluteDirPath .. fileName

    local suffix = string.sub(absoluteDirPath, -1)
    if suffix ~= "/" then
        filePath = absoluteDirPath .. "/" .. fileName
    end

    local file = io.open(filePath, "w")
    if (not file) then
        errMsg = filePath .. " open failed!"
        print("_FILE.WriteFile(dirPath, fileName, str)", errMsg)
        return false, errMsg
    end

    file:write(str)
    file:close()

    return true, ""
end

---@param path string
---@return table
function _FILE.ReadScript(path)
    return loadstring(_FILE.ReadFile(path))()
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
