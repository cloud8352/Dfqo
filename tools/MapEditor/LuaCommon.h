#pragma once

#include <QObject>
#include <QMap>

#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>

namespace Lua {
QJsonObject LuaStrToJsonObj(const QString &luaStr);
QString JsonObjToLuaStr(const QJsonObject &jsonObj);
}
