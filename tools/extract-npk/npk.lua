--功能：读取NPK资源相关
--作者：cloud
--修改时间：2019.1.19
--修改内容：NPK.extract_npk()中清空 NPK_Header.count
--          优化NPK.read_npk_img( imgname, npk_data) 函数，增加ARGB4444和ARGB1555贴图的处理办法
--4.0

local bit = require("bit")

local npk = {}

--=====NPK包格式============
local NPK_Header = 
{
    flag = "NeoplePack_Bill".."\0",  --[16] 文件标识 "NeoplePack_Bill"
    count = 0          --[4] 包内img文件的数目
}
 
local NPK_Index =
{
    offset = 0,    --[4] 文件的包内偏移量
    size = 0,    --[4] 文件的大小
    name = ""   --[256] 文件名
}

local decord_flag = "puchikon@neople dungeon and fighter DNF"  --[256]
--构造解密文件名用的decord_flag
local len = string.len(decord_flag) --39
--print(len)
for i = len + 1,255 do
  if (i - len) % 3 == 1 then 
    decord_flag = decord_flag..'D'
  elseif (i - len) % 3 == 2 then
    decord_flag = decord_flag..'N'
  elseif (i - len) % 3 == 0 then
    decord_flag = decord_flag..'F'
  end
    
  if i == 255 then
    decord_flag = decord_flag.."\0"
  end
end


--=========img文件格式==============
local NImgF_Header =  --占32个字节
{
	flag = "Neople Img File".."\0",  --[16]; // 文件标石"Neople Img File".."\0"
	index_size=0, --;	//[4] 索引表大小，以字节为单位
	unknown1=0,     --[4] 保留，4字节，为0
	version=2,      --[4] 版本号，IMGV2文件结构中的版本号为2。
	index_count=0,  --;//[4] 索引表数目
}

local NImgF_Index = {}
NImgF_Index.dwType = 0  --目前已知的类型有 0x0E(1555格式) 0x0F(4444格式) 0x10(8888格式) 0x11(指向型)
NImgF_Index.dwCompress = 0 -- 目前已知的类型有 0x06(zlib压缩) 0x05(未压缩)
NImgF_Index.width = 0        -- 宽度
NImgF_Index.height = 0       -- 高度
NImgF_Index.size = 0        -- 压缩时size为压缩后大小，未压缩时size为转换成8888格式时占用的内存大小
NImgF_Index.key_x = 0        -- X关键点，当前图片在整图中的X坐标
NImgF_Index.key_y = 0        -- Y关键点，当前图片在整图中的Y坐标
NImgF_Index.max_width = 0    -- 整图的宽度
NImgF_Index.max_height = 0   -- 整图的高度，有此数据是为了对齐精灵

--深度拷贝Table
function DeepCopy(obj)
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

--提取npk，
--入参：npk文件地址，string
--返回：table型：npkAbstract = {imgfile1 = {}, imgfile2 = {}, ...}；imgfile1 = {offset= 0, size =0}
function npk.getNpkAbstractFromFile(npkPath)
  local npkAbstract = {} --存放提取的npk信息-各img文件的offs和size
  local npkHeader = DeepCopy(NPK_Header)

  --读取npk
  local file = io.open(npkPath, "r")
  local dateStr = file:read("*a") -- 读取的数据字符
  file:close()

  if npkHeader.flag == string.sub(dateStr, 1, 16) then
    --读取img文件个数：16-20byte
    for i=1,4 do
      local count = string.sub(dateStr, 16+i, 16+i)
      npkHeader.count = npkHeader.count + string.byte(count)*(2^8)^(i-1)
    end
    print("npkHeader.count",npkHeader.count)-----------------------
    
    --提取npk中img数据信息，各img的偏移地址，大小，名称
    npkAbstract = npk.getNpkAbstractFromDateStr(npkPath, dateStr, npkHeader)
    --SHA256加密检验
    -- extract_npk_SHA256()
  elseif npkHeader.flag ~= string.sub(dateStr, 1, 16) then
    print("the pak is broken:check npkHeader.flag failed")
  end

  print("extract info of npk complete!")
  return npkAbstract
end

--提取npk中img数据信息，各img的偏移地址，大小，名称
--入参：npk文件地址，string
--返回：table型：npkAbstract = {imgfile1 = {}, imgfile2 = {}, ...}；imgfile1 = {offset= 0, size =0}
function npk.getNpkAbstractFromDateStr(npkPath, dateStr, npkHeader)
  local npkAbstract = {}

  for i = 0,npkHeader.count - 1 do
    local npkIndex = DeepCopy(NPK_Index)

    for j = 1,4 do
      local offsetStr = string.sub(dateStr, 20 + i*264 + j, 20 + i*264 + j)
      npkIndex.offset = npkIndex.offset + string.byte(offsetStr)*(2^8)^(j - 1)
      local sizeStr = string.sub(dateStr, 24 + i*264 + j, 24 + i*264 + j)
      npkIndex.size = npkIndex.size + string.byte(sizeStr)*(2^8)^(j - 1)
    end

    for j = 1,256 do
      local nameStr = string.sub(dateStr, 20 + i*264 + 8 + j, 20 + i*264 + 8 +j)
      local name = string.byte(nameStr)
      local decord_flag_str = string.sub(decord_flag, j, j)
      local decord_flag_byte = string.byte(decord_flag_str)

      --与名称解码标志按位异或
      name = bit.bxor(name, decord_flag_byte)
      nameStr = string.char(name)
      if nameStr == "\0" then  --文件路径名称读到0x00为止
        break
      end
      npkIndex.name = npkIndex.name..nameStr
    end
    npkAbstract[npkIndex.name] = {npkfile = npkPath, offset = npkIndex.offset, size = npkIndex.size}
  end

  return npkAbstract
end

function npk.outputImg(imgdir, imgName, imgDateStr)
  local outputDir = "output/img/"..imgdir
  local outputFilePath = outputDir.."/"..imgName..".png"
  local outputFile = io.open(outputFilePath, "w+")
  if nil == outputFile then
    os.execute("mkdir -p "..outputDir)
    outputFile = io.open(outputFilePath, "w+")
  end

  outputFile:write(imgDateStr)
  outputFile:close()
end

function npk.outputImgOffsetInfo(imgdir, fileName, ox, oy)
  local outputDir = "output/offsetInfo/"..imgdir
  local outputFilePath = outputDir.."/"..fileName..".cfg"
  local outputFile = io.open(outputFilePath, "w+")
  if nil == outputFile then
    os.execute("mkdir -p "..outputDir)
    outputFile = io.open(outputFilePath, "w+")
  end

  local content = string.format("return {\n    ox = %d,\n    oy = %d\n}", ox, oy)
  outputFile:write(content)
  outputFile:close()
end

local ImgInfo = {
  dwType=0,
  dwCompress=0,
  width=0,
  height=0,
  size=0,
  key_x=0,
  key_y=0,
  max_width=0,
  max_height=0,
  linksn=0,
  imgDataStr = ""
}

function npk.extractImgFromAbstract(imgName, imgAbstract)
  local succeed = false
  local errMsg = ""

  local imgInfoList = {}
  local img_start_adr = imgAbstract.offset --img文件开始的地址
  local npkPath = "" --所加载img所在的npk文件路径名称
  local nImgFHeader = DeepCopy(NImgF_Header)

  print("start read img", imgName)
  npkPath = imgAbstract.npkfile
  print("npkPath",npkPath)
  
  --读取npk
  local file = io.open(npkPath, "r")
  local dateStr = file:read("*a") -- 读取的数据字符
  file:close()
  
  print("img_start_adr",img_start_adr)
  local flag = string.sub(dateStr, img_start_adr + 1, img_start_adr + 16)
  
  if nImgFHeader.flag == flag then
   --如果img文件标志检验成功，读取img数据
   
   --======读取img头信息===========================
    for i = 1,4 do
      local index_size = string.sub(dateStr, img_start_adr + 16 + i, img_start_adr + 16 + i)
      nImgFHeader.index_size = nImgFHeader.index_size + string.byte(index_size)*(2^8)^(i - 1)
      
      local version = string.sub(dateStr, img_start_adr + 24 + i, img_start_adr + 24 + i)
      nImgFHeader.version = nImgFHeader.version + string.byte(version)*(2^8)^(i - 1)
      
      local index_count = string.sub(dateStr,img_start_adr + 28 + i,img_start_adr + 28 + i)
      nImgFHeader.index_count = nImgFHeader.index_count + string.byte(index_count)*(2^8)^(i - 1)
    end
    print("nImgFHeader.index_size", nImgFHeader.index_size)  -------------------------------------------------
    print("nImgFHeader.version", nImgFHeader.version)  -------------------------------------------------
    print("nImgFHeader.index_count", nImgFHeader.index_count)  -------------------------------------------------
    
    --============-end读取img头信息=================
    
    --创建存储img的空间，table型
    for i = 1,nImgFHeader.index_count do
      imgInfoList[i] = DeepCopy(ImgInfo)
    end
    
    --======读取贴图信息======================================
    local start_adr = img_start_adr + 32 --索引表首地址
    for i = 1, nImgFHeader.index_count do
      
      --根据当前贴图类型，读取信息
      for j = 1,4 do
        local dwType = string.sub(dateStr, start_adr + j, start_adr + j)
        imgInfoList[i].dwType = imgInfoList[i].dwType + string.byte(dwType)*(2^8)^(j - 1)
      end
      if imgInfoList[i].dwType ~= 17 then --非0x11(指向型)
        for j = 1,4 do
          local dwCompress = string.sub(dateStr, start_adr + 4 + j,start_adr + 4 + j)
          imgInfoList[i].dwCompress = imgInfoList[i].dwCompress + string.byte(dwCompress)*(2^8)^(j - 1)
          
          local width = string.sub(dateStr, start_adr + 8 + j,start_adr + 8 + j)
          imgInfoList[i].width = imgInfoList[i].width + string.byte(width)*(2^8)^(j - 1)
          
          local height = string.sub(dateStr, start_adr + 12 + j, start_adr + 12 + j)
          imgInfoList[i].height = imgInfoList[i].height + string.byte(height)*(2^8)^(j - 1)
          
          local size = string.sub(dateStr, start_adr + 16 + j, start_adr + 16 + j)
          imgInfoList[i].size = imgInfoList[i].size + string.byte(size)*(2^8)^(j - 1)
          
          local key_x = string.sub(dateStr, start_adr + 20 + j, start_adr + 20 + j)
          imgInfoList[i].key_x = imgInfoList[i].key_x + string.byte(key_x)*(2^8)^(j - 1)
          
          local key_y = string.sub(dateStr, start_adr + 24 + j, start_adr + 24 + j)
          imgInfoList[i].key_y = imgInfoList[i].key_y + string.byte(key_y)*(2^8)^(j - 1)
          
          local max_width = string.sub(dateStr, start_adr + 28 + j, start_adr + 28 + j)
          imgInfoList[i].max_width = imgInfoList[i].max_width + string.byte(max_width)*(2^8)^(j - 1)
          
          local max_height = string.sub(dateStr, start_adr + 32 + j, start_adr + 32 + j)
          imgInfoList[i].max_height = imgInfoList[i].max_height + string.byte(max_height)*(2^8)^(j - 1)
        end
        
        --根据当前贴图的类型，得出下一张贴图的地址
        start_adr = start_adr + 36
      elseif imgInfoList[i].dwType == 17 then --0x11,指向型
        --读取指向的序号
        for j = 1,4 do
          local linksn_temp = string.sub(dateStr, start_adr + 4 + j, start_adr + 4 + j)
          imgInfoList[i].linksn = imgInfoList[i].linksn + string.byte(linksn_temp)*(2^8)^(j - 1)
        end
        imgInfoList[i].linksn = imgInfoList[i].linksn + 1
        
        --根据当前贴图的类型，得出下一张贴图的地址
        start_adr = start_adr + 8
      end
      
    end
    --======end-读取贴图信息========================
   
    --======读取所有的贴图数据=====================
    --检查贴图数据首地址是否正确
    print("img_data start_adr",start_adr) ----------------------------------
    if start_adr == img_start_adr + 32 + nImgFHeader.index_size then
      --先读取非指向型贴图数据
      for i = 1,#imgInfoList do
        --读取当前贴图
        local img_data_string = string.sub(dateStr, start_adr + 1, start_adr + imgInfoList[i].size)
        if imgInfoList[i].dwType == 16 then --采用（ARGB8888）颜色系统
          --是否使用了zlib压缩
          if 6 == imgInfoList[i].dwCompress then  --使用zlib压缩
            imgInfoList[i].imgDateStr = img_data_string
          elseif 5 == imgInfoList[i].dwCompress then  --未压缩
            imgInfoList[i].imgDateStr = img_data_string
          end
          --下一数据地址
          start_adr = start_adr + imgInfoList[i].size
        elseif imgInfoList[i].dwType == 15 or imgInfoList[i].dwType == 14 then  --颜色系统为ARGB4444或ARGB1555的贴图不提取，取默认
          imgInfoList[i].imgDateStr = img_data_string
          --下一数据地址
          start_adr = start_adr + imgInfoList[i].size
        elseif imgInfoList[i].dwType == 17 then --0x11(指向型)
          --下一数据地址
          start_adr = start_adr + 0 --指向型，占用为0
        end
     
      end
      
      print("end address",start_adr)  ------------------------------------
      
    --读取完所有非指向型贴图后，读取所有指向型贴图
    for i = 1, nImgFHeader.index_count do
      if imgInfoList[i].dwType == 17 then --0x11(指向型)
        --链接指向的数据
        imgInfoList[i] = DeepCopy(imgInfoList[imgInfoList[i].linksn])
      end
    end

      print("read img complete!")
    elseif start_adr ~= img_start_adr + nImgFHeader.index_size then
      succeed = false
      errMsg = "img_data address is not correct"
      print(errMsg)
      return {succeed, errMsg}
    end
    --======end-读取所有的贴图数据======
    
  elseif nImgFHeader.flag ~= flag then
    succeed = false
    errMsg = "the pak is broken:check nImgFHeader.flag failed"
    print(errMsg)
    return {succeed, errMsg}
  end

  -- 提取图片文件及文件偏移信息
  for i = 1,#imgInfoList do
    npk.outputImg(imgName, i - 1, imgInfoList[i].imgDateStr)
    local ox = 232 - imgInfoList[i].key_x
    local oy = 333 - imgInfoList[i].key_y
    npk.outputImgOffsetInfo(imgName, i - 1, ox, oy)
  end

  succeed = true
  return {succeed, errMsg}
end

function npk.extractNPK(filePath)
  local npkAbstract = npk.getNpkAbstractFromFile(filePath)

  for imgPath,imgAbstract in pairs(npkAbstract) do
    npk.extractImgFromAbstract(imgPath, imgAbstract)
  end
end

return npk