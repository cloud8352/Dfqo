--[[
	desc: StartGameWindow class.
	author: keke <243768648@qq.com>
]]
--

local Util = require("util.Util")

local Label = require("UI.Label")
local ComboBox = require("UI.ComboBox")
local PushButton = require("UI.PushButton")
local WindowManager = require("UI.WindowManager")

local ResourceLib = require("lib.resource")
local MusicLib = require("lib.music")

local Window = require("UI.Window")

---@class StartGameWindow
local StartGameWindow = require("core.class")(Window)

---@param model UiModel
function StartGameWindow:Ctor(model)
    Window.Ctor(self)

    self.model = model

    --- 角色选择界面
    self:SetTitleBarVisible(false)
    self:SetSize(Util.GetWindowWidth(), Util.GetWindowHeight())

    -- 设置背景
    local bgLabel = Label.New(self)
    self.bgLabel = bgLabel
    local actorSelectBgLabelHeight = 500 * Util.GetWindowWidth() / 800
    bgLabel:SetSize(Util.GetWindowWidth(), actorSelectBgLabelHeight)
    bgLabel:SetIconSize(Util.GetWindowWidth(), actorSelectBgLabelHeight)
    -- actorSelectBgLabel:SetPosition(0, (Util.GetWindowHeight() - actorSelectBgLabelHeight) / 3)
    bgLabel:SetIconSpriteDataPath("ui/ActorSelect/Bg2")

    -- 背景音乐
    local musicData = ResourceLib.NewMusic("CharacterSelectStage")
    MusicLib.Play(musicData, true)

    -- 
    local centralContentBgWindow = Window.New()
    self.centralContentBgWindow = centralContentBgWindow
    centralContentBgWindow:SetIsNormalWidget(true)
    centralContentBgWindow:SetTitleBarVisible(false)

    local actorSelectLabel = Label.New(self)
    self.actorSelectLabel = actorSelectLabel
    local actorSelectLabelWidth = 180 * Util.GetWindowSizeScale()
    local actorSelectLabelHeight = 35 * Util.GetWindowSizeScale()
    actorSelectLabel:SetText("请选择角色：")
    actorSelectLabel:SetSize(actorSelectLabelWidth, actorSelectLabelHeight)
    actorSelectLabel:SetPosition(Util.GetWindowWidth() / 2 - actorSelectLabelWidth / 2,
        Util.GetWindowHeight() / 2 - actorSelectLabelHeight)

    local actorSelectComboBox = ComboBox.New(self)
    self.actorSelectComboBox = actorSelectComboBox
    local actorSelectComboBoxWidth = 200 * Util.GetWindowSizeScale()
    local actorSelectComboBoxHeight = 35 * Util.GetWindowSizeScale()
    actorSelectComboBox:SetSize(actorSelectComboBoxWidth, actorSelectComboBoxHeight)
    actorSelectComboBox:SetPosition(Util.GetWindowWidth() / 2 - actorSelectComboBoxWidth / 2,
        Util.GetWindowHeight() / 2)

    -- load Actor Simple Path List
    for _, simplePath in pairs(self.model:GetActorSimplePathList()) do
        if simplePath == "duelist/player" then
            simplePath = "[存档]"
        end
        actorSelectComboBox:AppendItemWithText(simplePath)
    end

    -- startGameBtn
    local startGameBtn = PushButton.New(self)
    self.startGameBtn = startGameBtn
    startGameBtn:SetClickedSoundSourceByPath("asset/sound/ui/BtnClicked2.wav")
    startGameBtn:SetText("开始游戏")
    local startGameBtnWidth = 100 * Util.GetWindowSizeScale()
    local startGameBtnHeight = 40 * Util.GetWindowSizeScale()
    startGameBtn:SetSize(startGameBtnWidth, startGameBtnHeight)
    startGameBtn:SetPosition(Util.GetWindowWidth() / 2 - startGameBtnWidth / 2,
        Util.GetWindowHeight() / 2 + actorSelectComboBoxHeight + 20 * Util.GetWindowSizeScale())

    -- 设置中央内容背景窗口
    local startGameBgLabelWidth = 300 * Util.GetWindowSizeScale()
    local startGameBgLabelHeight = actorSelectLabelHeight +
        actorSelectComboBoxHeight + startGameBtnHeight + 80 * Util.GetWindowSizeScale()
    centralContentBgWindow:SetSize(startGameBgLabelWidth, startGameBgLabelHeight)
    centralContentBgWindow:SetPosition(Util.GetWindowWidth() / 2 - startGameBgLabelWidth / 2,
        Util.GetWindowHeight() / 2 - 60 * Util.GetWindowSizeScale())

    --- connection
    self.startGameBtn:MocConnectSignal(self.startGameBtn.Signal_BtnClicked, self)
end

function StartGameWindow:Update(dt)
    if false == Window.IsVisible(self) then
        return
    end

    self.bgLabel:Update(dt)
    self.centralContentBgWindow:Update(dt)
    self.actorSelectLabel:Update(dt)
    self.actorSelectComboBox:Update(dt)
    self.startGameBtn:Update(dt)

    Window.Update(self, dt)
end

function StartGameWindow:Draw()
    if false == Window.IsVisible(self) then
        return
    end
    Window.Draw(self)

    self.bgLabel:Draw()
    self.centralContentBgWindow:Draw()
    self.actorSelectLabel:Draw()
    self.actorSelectComboBox:Draw()
    self.startGameBtn:Draw()
end

--- 连接信号
---@param signal function
---@param obj Object
function StartGameWindow:MocConnectSignal(signal, receiver)
    Window.MocConnectSignal(self, signal, receiver)
end

---@param signal function
function StartGameWindow:GetReceiverListOfSignal(signal)
    return Window.GetReceiverListOfSignal(self, signal)
end

---@param name string
function StartGameWindow:SetObjectName(name)
    Window.SetObjectName(self, name)
end

function StartGameWindow:GetObjectName()
    return Window.GetObjectName(self)
end

function StartGameWindow:GetParentWindow()
    return Window.GetParentWindow(self)
end

function StartGameWindow:GetPosition()
    return Window.GetPosition(self)
end

function StartGameWindow:SetPosition(x, y)
    Window.SetPosition(self, x, y)
end

---@param w int
---@param h int
function StartGameWindow:SetSize(w, h)
    local width = math.floor(w)
    local height = math.floor(h)
    Window.SetSize(self, width, height)
end

---@return integer, integer
function StartGameWindow:GetSize()
    return Window.GetSize(self)
end

function StartGameWindow:IsSizeChanged()
    return Window.IsSizeChanged(self)
end

function StartGameWindow:SetEnable(enable)
    Window.SetEnable(self, enable)
end

--- 是否可见
---@return boolean visible
function StartGameWindow:IsVisible()
    return Window.IsVisible(self)
end

--- 设置是否可见
---@param visible boolean
function StartGameWindow:SetVisible(visible)
    Window.SetVisible(self, visible)
end

---@param sprite Graphics.Drawable.Sprite
function StartGameWindow:SetBgSprite(sprite)
    Window.SetBgSprite(self, sprite)
end

function StartGameWindow:GetBgSprite()
    return Window.GetBgSprite(self)
end

--- 检查是否包含坐标。
--- 由窗管调用
---@param x number
---@param y number
---@return boolean
function StartGameWindow:CheckPoint(x, y)
    return Window.CheckPoint(self, x, y)
end

--- 设置标题栏是否可见
---@param visible boolean
function StartGameWindow:SetTitleBarVisible(visible)
    Window.SetTitleBarVisible(self, visible)
end

---@return boolean
function StartGameWindow:IsInMoving()
    return Window.IsInMoving(self)
end

function StartGameWindow:SetIsInMoving(moving)
    Window.SetIsInMoving(self, moving)
end

--- 获取窗口所处层数。
--- 由窗管调用
---@return number layerIndex
function StartGameWindow:GetWindowLayerIndex()
    return Window.GetWindowLayerIndex(self)
end

--- 设置窗口所处层数。
--- 由窗管调用
---@param layerIndex number
function StartGameWindow:SetWindowLayerIndex(layerIndex)
    Window.SetWindowLayerIndex(self, layerIndex)
end

function StartGameWindow:SetIsTipToolWindow(is)
    Window.SetIsTipToolWindow(self, is)
end

---@return boolean isTipToolWindow
function StartGameWindow:IsTipToolWindow()
    return Window.IsTipToolWindow(self)
end

---@param is boolean
function StartGameWindow:SetIsWindowStayOnTopHint(is)
    Window.SetIsWindowStayOnTopHint(self, is)
end

---@return boolean isWindowStayOnTopHint
function StartGameWindow:IsWindowStayOnTopHint()
    return Window.IsWindowStayOnTopHint(self)
end

---@param widget Widget
function StartGameWindow:SetContentWidget(widget)
    Window.SetContentWidget(self, widget)
end

---@param isVisible boolean
function StartGameWindow:SetTitleBarIsBackgroundVisible(isVisible)
    Window.SetTitleBarIsBackgroundVisible(self, isVisible)
end

---@param path string
function StartGameWindow:SetTitleBarIconPath(path)
    Window.SetTitleBarIconPath(self, path)
end

--- 设置窗口为普通控件，脱离窗管管理
---@param is boolean
function StartGameWindow:SetIsNormalWidget(is)
    Window.SetIsNormalWidget(self, is)
end

--- slots

---@param x int
---@param y int
function StartGameWindow:OnRequestMoveWindow(x, y)
    Window.OnRequestMoveWindow(self)
end

function StartGameWindow:OnRequestCloseWindow()
    Window.OnRequestCloseWindow(self)
end

---@param sender PushButton 被电击的按钮对象
function StartGameWindow:Slot_BtnClicked(sender)
    if self.startGameBtn == sender then
        local index = self.actorSelectComboBox:GetCurrentIndex()
        if index > 0 then
            self.model:StartGame(index)
            self:Signal_GameStarted()
        end
    end
end

--- signals

function StartGameWindow:Signal_WindowClosed()
    Window.Signal_WindowClosed(self)
end

function StartGameWindow:Signal_GameStarted()
    print("StartGameWindow:Signal_GameStarted()")
    local receiverList = self:GetReceiverListOfSignal(self.Signal_GameStarted)
    if receiverList == nil then
        return
    end

    for _, receiver in pairs(receiverList) do
        ---@type function
        local func = receiver.Slot_GameStarted
        if func == nil then
            goto continue
        end

        func(receiver, self)

        ::continue::
    end
end

return StartGameWindow
