--[[
	desc: StartGameWindow class.
	author: keke <243768648@qq.com>
]]
--

local Window = require("UI.Window")
local Util = require("util.Util")
local Common = require("UI.ui_common")

local Label = require("UI.Label")
local ComboBox = require("UI.ComboBox")
local PushButton = require("UI.PushButton")
local WindowManager = require("UI.WindowManager")
local VideoWidget = require("UI.VideoWidget")
local LineEdit = require("UI.LineEdit")

local ResourceLib = require("lib.resource")
local AspectCmpt = require("actor.component.aspect")
local MusicLib = require("lib.music")
local ResMgr = require("actor.resmgr")
local Graphics = require("lib.graphics")
local TableLib = require("lib.table")
local StringLib = require("lib.string")

---@class StartGameWindow : Window
local StartGameWindow = require("core.class")(Window)

local StartPageBgImgPath = "ui/ActorSelect/Bg2"
local ActorSelectPageBgImgPath = "ui/ActorSelect/Bg"

local DisabledImgPath = "ui/PushButton/Rectangle/Disabled"
local HoveringImgPath = "ui/PushButton/Rectangle/Hovering"
local NormalImgPath = "ui/PushButton/Rectangle/Normal"
local PressingImgPath = "ui/PushButton/Rectangle/Pressing"

---@enum StartGameWindow.PageEnum
local PageEnum = {
    Start = 1,
    ActorSelect = 2,
    ActorCreate = 3
}

---@class StartGameWindow.ActorWidgetStruct
---@field ActorPath string
---@field Job int JobEnum
---@field AspectCmpt ctor.Component.Aspect
---@field Btn PushButton
---@field NameLabel Label
local ActorWidgetStruct = {
    ActorPath = "",
    Job = Common.JobEnum.Other,
    ---@type Actor.Component.Aspect
    AspectCmpt = nil,
    ---@type PushButton
    Btn = nil,
    NameLabel = nil
}

---@return StartGameWindow.ActorWidgetStruct
local function newActorWidget()
    return TableLib.DeepClone(ActorWidgetStruct)
end

---@param btn PushButton
local function initBtnImgPaths(btn)
    btn:SetDisabledSpriteDataPath(DisabledImgPath)
    btn:SetHoveringSpriteDataPath(HoveringImgPath)
    btn:SetNormalSpriteDataPath(NormalImgPath)
    btn:SetPressingSpriteDataPath(PressingImgPath)
end

---@param model UiModel
function StartGameWindow.Create(model)
    -- 用于定义构造函数，解释使用，不做实际用途
    -- 使用class模块后，实际会调用Ctor函数
    return StartGameWindow.New(model)
end

---@param model UiModel
function StartGameWindow:Ctor(model)
    Window.Ctor(self)

    local windowSizeScale = Util.GetWindowSizeScale()
    self.model = model
    self.pageType = PageEnum.Start

    self.selectedUserActorPath = ""
    self.selectedJobActorPath = ""

    --- 角色选择界面
    self:SetTitleBarVisible(false)
    self:SetSize(Util.GetWindowWidth(), Util.GetWindowHeight())

    -- 设置背景
    local bgLabel = Label.New(self)
    self.bgLabel = bgLabel
    bgLabel:SetIconSpriteDataPath(StartPageBgImgPath)
    local iconImgDimensionsW, iconImgDimensionsH = bgLabel:GetIconSpriteImgDimensions()
    local actorSelectBgLabelHeight = iconImgDimensionsH * Util.GetWindowWidth() / iconImgDimensionsW
    bgLabel:SetSize(Util.GetWindowWidth(), actorSelectBgLabelHeight)
    bgLabel:SetIconSize(Util.GetWindowWidth(), actorSelectBgLabelHeight)

    -- 
    local centralContentBgWindow = Window.New()
    self.centralContentBgWindow = centralContentBgWindow
    centralContentBgWindow:SetIsNormalWidget(true)
    centralContentBgWindow:SetTitleBarVisible(false)
    local centralContentBgW = 300 * windowSizeScale
    local centralContentBgH = 185 * windowSizeScale
    centralContentBgWindow:SetSize(centralContentBgW, centralContentBgH)
    centralContentBgWindow:SetPosition(Util.GetWindowWidth() / 2 - centralContentBgW / 2,
        Util.GetWindowHeight() / 2 - centralContentBgH / 2 + 110 * windowSizeScale)

    local centralContentBgX, centralContentBgY = centralContentBgWindow:GetPosition()
    -- actor select btn
    local actorSelectBtn = PushButton.Create(self)
    self.actorSelectBtn = actorSelectBtn
    initBtnImgPaths(actorSelectBtn)
    actorSelectBtn:SetText("选择角色")
    local widgetW = 262 * Util.GetWindowSizeScale()
    local widgetH = 40 * Util.GetWindowSizeScale()
    actorSelectBtn:SetSize(widgetW, widgetH)
    actorSelectBtn:SetPosition(centralContentBgX + centralContentBgW / 2 - widgetW / 2,
        centralContentBgY + 20 * windowSizeScale)
    local actorSelectBtnW, actorSelectBtnH = actorSelectBtn:GetSize()
    local actorSelectBtnX, actorSelectBtnY = actorSelectBtn:GetPosition()
    -- settingsBtn
    local settingsBtn = PushButton.Create(self)
    self.settingsBtn = settingsBtn
    initBtnImgPaths(settingsBtn)
    settingsBtn:SetText("设置")
    local widgetW = 262 * windowSizeScale
    local widgetH = 40 * windowSizeScale
    settingsBtn:SetSize(widgetW, widgetH)
    settingsBtn:SetPosition(centralContentBgX + centralContentBgW / 2 - widgetW / 2,
        actorSelectBtnY + actorSelectBtnH + 10 * Util.GetWindowSizeScale())

    local _, settingsBtnH = settingsBtn:GetSize()
    local _, settingsBtnY = settingsBtn:GetPosition()
    -- aboutBtn
    local aboutBtn = PushButton.Create(self)
    self.aboutBtn = aboutBtn
    initBtnImgPaths(aboutBtn)
    aboutBtn:SetText("关于")
    local widgetW = 262 * windowSizeScale
    local widgetH = 40 * windowSizeScale
    aboutBtn:SetSize(widgetW, widgetH)
    aboutBtn:SetPosition(centralContentBgX + centralContentBgW / 2 - widgetW / 2,
        settingsBtnY + settingsBtnH + 10 * Util.GetWindowSizeScale())


    -- actor select page
    ---@type table<int, StartGameWindow.ActorWidgetStruct>
    self.actorWidgetList = {}

    -- goBack btn
    local goBackBtn = PushButton.Create(self)
    self.goBackBtn = goBackBtn
    goBackBtn:SetText("返回")
    local widgetW = 100 * windowSizeScale
    local widgetH = 40 * windowSizeScale
    goBackBtn:SetSize(widgetW, widgetH)
    goBackBtn:SetPosition(30 * windowSizeScale,
        Util.GetWindowHeight() - widgetH - 30 * windowSizeScale)

    -- actor create btn
    local actorCreateBtn = PushButton.Create(self)
    self.actorCreateBtn = actorCreateBtn
    actorCreateBtn:SetText("创建角色")
    local widgetW = 100 * windowSizeScale
    local widgetH = 40 * windowSizeScale
    actorCreateBtn:SetSize(widgetW, widgetH)
    actorCreateBtn:SetPosition(190 * windowSizeScale,
        Util.GetWindowHeight() - widgetH - 30 * windowSizeScale)

    -- startGameBtn
    local startGameBtn = PushButton.Create(self)
    self.startGameBtn = startGameBtn
    startGameBtn:SetClickedSoundSourceByPath("asset/sound/ui/BtnClicked2.wav")
    startGameBtn:SetText("开始游戏")
    local widgetW = 120 * windowSizeScale
    local widgetH = 40 * windowSizeScale
    startGameBtn:SetSize(widgetW, widgetH)
    startGameBtn:SetPosition(Util.GetWindowWidth() / 2 - widgetW / 2,
        Util.GetWindowHeight() - widgetH - 30 * windowSizeScale)

    --- 角色创建页面
    ---@type table<int, StartGameWindow.ActorWidgetStruct>
    self.jobActorWidgetList = {}

    local videoWidget = VideoWidget.Create(self)
    self.jobSkillVideoWidget = videoWidget
    local widgetW = 600 * windowSizeScale
    local widgetH = widgetW * 4 / 7
    videoWidget:SetSize(widgetW, widgetH)
    videoWidget:SetPosition(650 * windowSizeScale, 30 * windowSizeScale)

    local videoWidgetX, videoWidgetY = videoWidget:GetPosition()
    local videoWidgetW, videoWidgetH = videoWidget:GetSize()
    local jobIntroLabel = Label.Create(self)
    self.jobIntroLabel = jobIntroLabel
    local widgetW = 600 * windowSizeScale
    local widgetH = 100 * windowSizeScale
    jobIntroLabel:SetSize(widgetW, widgetH)
    jobIntroLabel:SetPosition(650 * windowSizeScale, videoWidgetY + videoWidgetH + 30 * windowSizeScale)
    jobIntroLabel:SetAlignments({ Label.AlignmentFlag.AlignLeft, Label.AlignmentFlag.AlignTop })
    jobIntroLabel:SetIconSpriteDataPath(NormalImgPath)
    jobIntroLabel:SetIconSize(widgetW, widgetH)

    local nameLabel = Label.Create(self)
    self.nameLabel = nameLabel
    nameLabel:SetText("名称：")
    nameLabel:SetSize(50 * windowSizeScale, 35 * windowSizeScale)

    local nameLineEdit = LineEdit.Create(self)
    self.nameLineEdit = nameLineEdit
    nameLineEdit:SetText("player1")
    nameLineEdit:SetSize(120 * windowSizeScale, 35 * windowSizeScale)

    local nameConfirmBtn = PushButton.Create(self)
    self.nameConfirmBtn = nameConfirmBtn
    nameConfirmBtn:SetText("确定")
    nameConfirmBtn:SetSize(80 * windowSizeScale, 35 * windowSizeScale)

    local nameLabelW, nameLabelH = nameLabel:GetSize()
    local nameLineEditW, nameLineEditH = nameLineEdit:GetSize()
    local nameConfirmBtnW, nameConfirmBtnH = nameConfirmBtn:GetSize()
    nameConfirmBtn:SetPosition(Util.GetWindowWidth() / 2 - nameConfirmBtnW / 2, 
        Util.GetWindowHeight() - 30 * windowSizeScale - nameConfirmBtnH)
    local nameConfirmBtnX, nameConfirmBtnY = nameConfirmBtn:GetPosition()
    nameLabel:SetPosition(Util.GetWindowWidth() / 2 - nameLabelW / 2 - nameLineEditW / 2,
        nameConfirmBtnY - 5 * windowSizeScale - nameLabelH)
    local nameLabelX, nameLabelY = nameLabel:GetPosition()
    nameLineEdit:SetPosition(nameLabelX + nameLabelW, nameLabelY)

    --- connection
    self.actorSelectBtn:MocConnectSignal(self.actorSelectBtn.Signal_BtnClicked, self)
    self.goBackBtn:MocConnectSignal(self.goBackBtn.Signal_BtnClicked, self)
    self.actorCreateBtn:MocConnectSignal(self.actorCreateBtn.Signal_BtnClicked, self)
    self.startGameBtn:MocConnectSignal(self.startGameBtn.Signal_BtnClicked, self)
    self.nameConfirmBtn:MocConnectSignal(self.nameConfirmBtn.Signal_BtnClicked, self)
    self.model:MocConnectSignal(self.model.Signal_RequestSetUiGameState, self)

    --- post init
    self:loadActorWidgetList()
    self:loadJobActorWidgetList()
    self:setPage(PageEnum.Start)
end

function StartGameWindow:Update(dt)
    if false == Window.IsVisible(self) then
        return
    end

    self.bgLabel:Update(dt)
    self.centralContentBgWindow:Update(dt)
    self.actorSelectBtn:Update(dt)
    self.settingsBtn:Update(dt)
    self.aboutBtn:Update(dt)

    for _, widget in pairs(self.actorWidgetList) do
        widget.Btn:Update(dt)
        widget.NameLabel:Update(dt)
    end
    self.goBackBtn:Update(dt)
    self.actorCreateBtn:Update(dt)
    self.startGameBtn:Update(dt)

    for _, widget in pairs(self.jobActorWidgetList) do
        widget.Btn:Update(dt)
        widget.NameLabel:Update(dt)
    end

    self.jobSkillVideoWidget:Update(dt)
    self.jobIntroLabel:Update(dt)
    self.nameLabel:Update(dt)
    self.nameLineEdit:Update(dt)
    self.nameConfirmBtn:Update(dt)

    Window.Update(self, dt)
end

function StartGameWindow:Draw()
    if false == Window.IsVisible(self) then
        return
    end
    Window.Draw(self)

    self.bgLabel:Draw()
    self.centralContentBgWindow:Draw()
    self.actorSelectBtn:Draw()
    self.settingsBtn:Draw()
    self.aboutBtn:Draw()

    if self.pageType == PageEnum.ActorSelect then
        for _, widget in pairs(self.actorWidgetList) do
            widget.Btn:Draw()
            widget.AspectCmpt.layer:Draw()
            widget.NameLabel:Draw()
        end
    end
    self.goBackBtn:Draw()
    self.actorCreateBtn:Draw()
    self.startGameBtn:Draw()

    if self.pageType == PageEnum.ActorCreate then
        for _, widget in pairs(self.jobActorWidgetList) do
            widget.Btn:Draw()
            widget.AspectCmpt.layer:Draw()
            widget.NameLabel:Draw()
        end
    end

    -- video
    self.jobSkillVideoWidget:Draw()

    self.jobIntroLabel:Draw()
    self.nameLabel:Draw()
    self.nameLineEdit:Draw()
    self.nameConfirmBtn:Draw()
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

function StartGameWindow:GetContentWidget()
    return Window.GetContentWidget(self)
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

---@param sender Obj
function StartGameWindow:Slot_BtnClicked(sender)
    if self.actorSelectBtn == sender then
        self:setPage(PageEnum.ActorSelect)
    end

    if self.goBackBtn == sender then
        if self.pageType == PageEnum.ActorCreate then
            self:setPage(PageEnum.ActorSelect)
        elseif self.pageType == PageEnum.ActorSelect then
            self:setPage(PageEnum.Start)
        end
    end

    if self.actorCreateBtn == sender then
        self:setPage(PageEnum.ActorCreate)

        local noSuffixFileName = self.model:NewAUserActorConfigNoSuffixFileName()
        self.nameLineEdit:SetText(noSuffixFileName)
    end

    if self.nameConfirmBtn == sender then
        local name = self.nameLineEdit:GetText()
        self.model:CreateUserActor(self.selectedJobActorPath, name)

        self:loadActorWidgetList()
        self:setPage(PageEnum.ActorSelect)
    end

    if self.startGameBtn == sender then
        if self.selectedUserActorPath ~= "" then
            self:setPage(PageEnum.Start)
            self.model:StartGame(self.selectedUserActorPath)
            self:Signal_GameStarted()
        end
    end

    local widget = self:findInActorWidgetList(sender)
    if widget.Btn ~= nil then
        for _, widget in pairs(self.actorWidgetList) do
            widget.Btn:SetForcePressed(false)
        end

        widget.Btn:SetForcePressed(true)
        self.selectedUserActorPath = widget.ActorPath
    end

    local widget = self:findInJobActorWidgetList(sender)
    if widget.Btn ~= nil then
        for _, widget in pairs(self.jobActorWidgetList) do
            widget.Btn:SetForcePressed(false)
        end

        widget.Btn:SetForcePressed(true)
        self.selectedJobActorPath = widget.ActorPath

        -- video
        local video = self.model:GetJobIntroVideo(widget.Job)
        self.jobSkillVideoWidget:SetVideo(video)
        self.jobSkillVideoWidget:Rewind()
        self.jobSkillVideoWidget:Play()

        -- Label
        self.jobIntroLabel:SetText(Common.MapOfJobToIntroStr[widget.Job])
    end
end


---@param sender Obj
---@param state int GameState
function StartGameWindow:Slot_RequestSetUiGameState(sender, state)
    if state == Common.GameState.ActorSelect then
        self:loadActorWidgetList()
        self:loadJobActorWidgetList()
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


--- private functions

function StartGameWindow:loadActorWidgetList()
    for _, widget in pairs(self.actorWidgetList) do
        widget.Btn:MocDisconnectSignal(nil, nil)
    end
    self.actorWidgetList = {}
    local windowSizeScale = Util.GetWindowSizeScale()
    local colCount = Common.UserActorPageColCount

    local userActorList = self.model:GetUserActorList()

    local widgetW = 150 * windowSizeScale
    local widgetH = 200 * windowSizeScale
    for i, actor in pairs(userActorList) do
        local actorWidget = newActorWidget()
        actorWidget.ActorPath = actor.Data.path
        actorWidget.Job = actor.identity.Job

        local actorBtn = PushButton.Create(self)
        initBtnImgPaths(actorBtn)
        actorBtn:SetSize(widgetW, widgetH)
        local col = math.fmod(i - 1, colCount)
        local row = math.floor((i - 1) / colCount)
        actorBtn:SetPosition(85 * windowSizeScale + col * widgetW + 
            col * 10 * windowSizeScale,
            100 * windowSizeScale + row * widgetH + row * 10 * windowSizeScale)
        actorWidget.Btn = actorBtn

        local actorBtnW, actorBtnH = actorBtn:GetSize()
        local actorBtnX, actorBtnY = actorBtn:GetPosition()
        actor.transform.position:Set(actorBtnX + actorBtnW / 2, 
            actorBtnY + actorBtnH - 40 * windowSizeScale, 0)
        actor.transform.positionTick = true
        actor.transform.scale:Set(windowSizeScale, windowSizeScale)
        actor.transform.scaleTick = true
        actorWidget.AspectCmpt = actor.aspect

        local nameLabel = Label.Create(self)
        actorWidget.NameLabel = nameLabel
        nameLabel:SetText(actor.identity.name)
        nameLabel:SetSize(widgetW, 35 * windowSizeScale)
        nameLabel:SetPosition(actorBtnX, actorBtnY + actorBtnH - 35 * windowSizeScale)
        table.insert(self.actorWidgetList, actorWidget)

        actorBtn:MocConnectSignal(actorBtn.Signal_BtnClicked, self)
    end
end

---@param btn PushButton
function StartGameWindow:findInActorWidgetList(btn)
    for _, widget in pairs(self.actorWidgetList) do
        if btn == widget.Btn then
            return widget
        end
    end

    return newActorWidget()
end

function StartGameWindow:loadJobActorWidgetList()
    -- 清空职业角色列表
    for _, widget in pairs(self.jobActorWidgetList) do
        widget.Btn:MocDisconnectSignal(nil, nil)
    end
    self.jobActorWidgetList = {}
    -- 将职业接受视频设置为空
    self.jobSkillVideoWidget:SetVideo(nil)
    local windowSizeScale = Util.GetWindowSizeScale()
    local colCount = Common.JobActorPageColCount

    local jobActorList = self.model:GetJobActorList()

    local widgetW = 150 * windowSizeScale
    local widgetH = 200 * windowSizeScale
    for i, actor in pairs(jobActorList) do
        local actorWidget = newActorWidget()
        actorWidget.ActorPath = actor.Data.path
        actorWidget.Job = actor.identity.Job

        local actorBtn = PushButton.Create(self)
        initBtnImgPaths(actorBtn)
        actorBtn:SetSize(widgetW, widgetH)
        local col = math.fmod(i - 1, colCount)
        local row = math.floor((i - 1) / colCount)
        actorBtn:SetPosition(20 * windowSizeScale + col * widgetW + 
            col * 10 * windowSizeScale,
            20 * windowSizeScale + row * widgetH + row * 10 * windowSizeScale)
        actorWidget.Btn = actorBtn

        local actorBtnW, actorBtnH = actorBtn:GetSize()
        local actorBtnX, actorBtnY = actorBtn:GetPosition()
        actor.transform.position:Set(actorBtnX + actorBtnW / 2, 
            actorBtnY + actorBtnH - 40 * windowSizeScale, 0)
        actor.transform.positionTick = true
        actor.transform.scale:Set(windowSizeScale, windowSizeScale)
        actor.transform.scaleTick = true
        actorWidget.AspectCmpt = actor.aspect
        
        local nameLabel = Label.Create(self)
        actorWidget.NameLabel = nameLabel
        nameLabel:SetText(actor.identity.name)
        nameLabel:SetSize(widgetW, 35 * windowSizeScale)
        nameLabel:SetPosition(actorBtnX, actorBtnY + actorBtnH - 35 * windowSizeScale)
        table.insert(self.jobActorWidgetList, actorWidget)

        actorBtn:MocConnectSignal(actorBtn.Signal_BtnClicked, self)
    end
end

---@param btn PushButton
function StartGameWindow:findInJobActorWidgetList(btn)
    for _, widget in pairs(self.jobActorWidgetList) do
        if btn == widget.Btn then
            return widget
        end
    end

    return newActorWidget()
end

---@param type int PageEnum
function StartGameWindow:setPage(type)
    self.pageType = type
    self.centralContentBgWindow:SetVisible(false)
    self.actorSelectBtn:SetVisible(false)
    self.settingsBtn:SetVisible(false)
    self.aboutBtn:SetVisible(false)
    for _, widget in pairs(self.actorWidgetList) do
        widget.Btn:SetVisible(false)
    end
    self.goBackBtn:SetVisible(false)
    self.actorCreateBtn:SetVisible(false)
    self.startGameBtn:SetVisible(false)

    for _, widget in pairs(self.jobActorWidgetList) do
        widget.Btn:SetVisible(false)
    end
    self.jobSkillVideoWidget:SetVisible(false)
    self.jobSkillVideoWidget:Rewind()
    self.jobSkillVideoWidget:Pause()
    self.jobIntroLabel:SetVisible(false)
    self.nameLabel:SetVisible(false)
    self.nameLineEdit:SetVisible(false)
    self.nameConfirmBtn:SetVisible(false)
    self.model:ResumeMusic()

    if type == PageEnum.Start then
        self.centralContentBgWindow:SetVisible(true)
        self.actorSelectBtn:SetVisible(true)
        self.settingsBtn:SetVisible(true)
        self.aboutBtn:SetVisible(true)

        self.bgLabel:SetIconSpriteDataPath(StartPageBgImgPath)
    elseif type == PageEnum.ActorSelect then
        for _, widget in pairs(self.actorWidgetList) do
            widget.Btn:SetVisible(true)
        end
        self.goBackBtn:SetVisible(true)
        self.actorCreateBtn:SetVisible(true)
        self.startGameBtn:SetVisible(true)

        self.bgLabel:SetIconSpriteDataPath(ActorSelectPageBgImgPath)
    elseif type == PageEnum.ActorCreate then
        for _, widget in pairs(self.jobActorWidgetList) do
            widget.Btn:SetVisible(true)
        end
        self.goBackBtn:SetVisible(true)
        self.jobSkillVideoWidget:SetVisible(true)
        self.jobSkillVideoWidget:Play()
        self.jobIntroLabel:SetVisible(true)
        self.nameLabel:SetVisible(true)
        self.nameLineEdit:SetVisible(true)
        self.nameConfirmBtn:SetVisible(true)

        self.bgLabel:SetIconSpriteDataPath(ActorSelectPageBgImgPath)

        self.model:PauseMusic()
    end

    --- 更新背景尺寸
    local iconImgDimensionsW, iconImgDimensionsH = self.bgLabel:GetIconSpriteImgDimensions()
    local actorSelectBgLabelHeight = iconImgDimensionsH * Util.GetWindowWidth() / iconImgDimensionsW
    self.bgLabel:SetSize(Util.GetWindowWidth(), actorSelectBgLabelHeight)
    self.bgLabel:SetIconSize(Util.GetWindowWidth(), actorSelectBgLabelHeight)
    if type == PageEnum.ActorSelect or type == PageEnum.ActorCreate then
        self.bgLabel:SetPosition(0, -100 * Util.GetWindowSizeScale())
    end
end

return StartGameWindow
