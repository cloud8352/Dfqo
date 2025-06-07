--[[
	desc: ArticleWithBuff, a system of article which has some buff.
	author: keke
]]--

local _ASPECT = require("actor.service.aspect")

local _Base = require("actor.system.base")
local Attack = require("actor.gear.attack")

local AspectSrv = require("actor.service.aspect")
local BuffSrv = require("actor.service.buff")

---@class Actor.System.Article.ArticleWithBuff : Actor.System
local ArticleWithBuff = require("core.class")(_Base)

---@param attackerEntity Actor.Entity
---@param attack Actor.Gear.Attack
---@param enemy Actor.Entity
local function onHit(attackerEntity, attack, enemy)
    local article = attackerEntity.article_ArticleWithBuff
    for _, buffData in pairs(article.BuffDataList) do
        BuffSrv.AddBuff(enemy, buffData)
    end
end

function ArticleWithBuff:Ctor(upperEvent)
    _Base.Ctor(self, upperEvent, {
        article_ArticleWithBuff = true,
        aspect = true,
        identity = true,
        attributes = true,
        attacker = true,
    }, "ArticleWithBuff")
end

---@param entity Actor.Entity
function ArticleWithBuff:OnEnter(entity)
    local article = entity.article_ArticleWithBuff
    local collider = article.Collider
    local main = AspectSrv.GetPart(entity.aspect)
    if #collider:GetList() > 0 then
        main:SetCollider(collider)
    end
    local attack = Attack.Create(entity)
    article.Attack = attack

    ---@param attackTmp Actor.Gear.Attack
    ---@param enemy Actor.Entity
    local function onHitFunc(attackTmp, enemy)
        onHit(entity, attackTmp, enemy)
    end
    attack:Enter(article.AttackData, article.AttackValue, onHitFunc)
end

---@param entity Actor.Entity
function ArticleWithBuff:OnExit(entity)
    local article = entity.article_ArticleWithBuff
    article.Attack:Exit()
    article.Attack = nil
end

function ArticleWithBuff:Update(dt)
    for n = 1, self._list:GetLength() do
        local e = self._list:Get(n) ---@type Actor.Entity
        local article = e.article_ArticleWithBuff
        article.Attack:Update(dt)
    end
end

return ArticleWithBuff
