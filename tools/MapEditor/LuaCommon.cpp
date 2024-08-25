#include "LuaCommon.h"
#include "Calculator.h"

#include <QtDebug>
#include <QDir>
#include <QFileInfo>

const QString &LuaReturnStr = "return";
const int LuaReturnStrLength = LuaReturnStr.length();

enum LuaVariableType {
    Base,
    Table,
    Array
};

QJsonArray strToJsonArray(const QString &arrayStr);
QJsonObject strToJsonObj(const QString &tableStr);

// 去除字符串开头和结尾引号
QString simplifyStr(const QString &str)
{
    QString retStr = str;
    if (str.startsWith("\"")) {
        if (str.endsWith("\"")) {
            return retStr.mid(1, retStr.length() - 2);
        } else {
            return retStr;
        }
    }

    if (str.startsWith("'")) {
        if (str.endsWith("'"))  {
            return retStr.mid(1, retStr.length() - 2);
        } else {
            return retStr;
        }
    }

    if (str.startsWith("[\'")) {
        if (str.endsWith("\']"))  {
            return retStr.mid(2, retStr.length() - 4);
        } else {
            return retStr;
        }
    }

    return retStr;
}

QVariant getVariantFromStr(const QString &str)
{
    QVariant retVar;
    if ("true" == str) {
        retVar.setValue(true);
        return retVar;
    }
    if ("false" == str) {
        retVar.setValue(false);
        return retVar;
    }
    //    if (str.contains("\"") || str.contains())
    for (const QChar &chr : str) {
        if (chr == "." || chr == "+" || chr == "-" || chr == "*" || chr == "/") {
            continue;
        }

        if (!chr.isDigit()) {
            QString strTmp = simplifyStr(str);
            retVar.setValue(strTmp);
            return retVar;
        }
    }

    double value = Calculator::Calculate(str);

    retVar.setValue(value);
    return retVar;
}

LuaVariableType getLuaVarType(const QString &str)
{
    if (!str.startsWith("{")) {
        return Base;
    }
    const QJsonObject jsonObj = strToJsonObj(str);

    return jsonObj.keys().contains("") ? Array : Table;
}

QJsonValue strToJsonValue(const QString &str)
{
    LuaVariableType type = getLuaVarType(str);
    if (LuaVariableType::Base == type) {
        const QVariant &var = getVariantFromStr(str);
        return var.toJsonValue();
    } else if (LuaVariableType::Table == type) {
        const QJsonObject jsonObjTmp = strToJsonObj(str);
        return QJsonValue(jsonObjTmp);
    } else if (LuaVariableType::Array == type) {
        const QJsonArray &jsonArrayTmp = strToJsonArray(str);
        return QJsonValue(jsonArrayTmp);
    }

    qCritical() << Q_FUNC_INFO << "unknown lua variable type:" << str;
    return QJsonValue();
}

// 例如：{a,{x=-13,y1=-8,z=0,w=26,y2=16,h=83}}
QJsonArray strToJsonArray(const QString &arrayStr)
{
    QJsonArray retJsonArray;

    QString contentStr = arrayStr;
    contentStr = contentStr.mid(1, contentStr.length() - 2);

    QString unitStr;
    int braceCount = 0;
    for (const QChar &chr : contentStr) {
        if (
            (chr == "{" && unitStr.size() && unitStr.back() != "\\") ||
            (chr == "{" && unitStr.isEmpty())
            ) {
            braceCount++;
            unitStr += chr;

            continue;
        }

        if (
            (chr == "}" && unitStr.size() && unitStr.back() != "\\") ||
            (chr == "}" && unitStr.isEmpty())
            ) {
            braceCount--;
            unitStr += chr;

            continue;
        }

        if (braceCount) {
            unitStr += chr;
            continue;
        }

        if (chr == ',') {
            const QJsonValue &jsonValue = strToJsonValue(unitStr);
            retJsonArray.append(jsonValue);

            unitStr.clear();
            continue;
        }
        unitStr += chr;
    }
    if (!unitStr.isEmpty()) {
        const QJsonValue &jsonValue = strToJsonValue(unitStr);
        retJsonArray.append(jsonValue);

        unitStr.clear();
    }

    // qDebug() << Q_FUNC_INFO << retJsonArray;
    return retJsonArray;
}

// 例如：{ox=25,oy=136,collider={damage={a,{x=-13,y1=-8,z=0,w=26,y2=16,h=83}}}}
QJsonObject strToJsonObj(const QString &tableStr)
{
    QJsonObject retJsonObj;

    QString contentStr = tableStr;
    contentStr = contentStr.mid(1, contentStr.length() - 2);

    QString unitStr;
    QString keyStr;
    int braceCount = 0;
    for (const QChar &chr : contentStr) {
        if (
            (chr == "{" && unitStr.size() && unitStr.back() != "\\") ||
            (chr == "{" && unitStr.isEmpty())
            ) {
            braceCount++;
            unitStr += chr;

            continue;
        }

        if (
            (chr == "}" && unitStr.size() && unitStr.back() != "\\") ||
            (chr == "}" && unitStr.isEmpty())
            ) {
            braceCount--;
            unitStr += chr;

            continue;
        }

        if (braceCount) {
            unitStr += chr;
            continue;
        }

        if (chr == "=") {
            keyStr = unitStr;
            unitStr.clear();

            continue;
        }
        if (chr == ',') {
            const QJsonValue &jsonValue = strToJsonValue(unitStr);
            keyStr = simplifyStr(keyStr);
            retJsonObj.insert(keyStr, jsonValue);

            keyStr.clear();
            unitStr.clear();
            continue;
        }
        unitStr += chr;
    }
    if (!unitStr.isEmpty()) {
        const QJsonValue &jsonValue = strToJsonValue(unitStr);
        keyStr = simplifyStr(keyStr);
        retJsonObj.insert(keyStr, jsonValue);

        keyStr.clear();
        unitStr.clear();
    }

    // qDebug() << Q_FUNC_INFO << retJsonObj;
    return retJsonObj;
}

///////////////////////////////////////

QString jsonArrayToStr(const QJsonArray &jsonArray, QString lineBlank);
QString jsonObjToStr(const QJsonObject &jsonObj, QString lineBlank);


QString jsonArrayToStr(const QJsonArray &jsonArray, QString lineBlank = "")
{
    QString retStr = "{\n";
    const QString &contentLineBlank = lineBlank + "    ";
    QJsonArray::const_iterator cIter = jsonArray.constBegin();
    for (; cIter != jsonArray.constEnd(); cIter++) {
        QString valueStr;
        if (cIter->isObject()) {
            valueStr = jsonObjToStr(cIter->toObject(), contentLineBlank);
        } else if (cIter->isArray()) {
            valueStr = jsonArrayToStr(cIter->toArray(), contentLineBlank);
        } else if (cIter->isString()) {
            valueStr = QString("\"%1\"").arg(cIter->toVariant().toString());
        } else {
            valueStr = cIter->toVariant().toString();
        }
        retStr += QString("%1%2,\n").arg(contentLineBlank).arg(valueStr);
    }

    retStr += lineBlank + "}";

    return retStr;
}

QString jsonObjToStr(const QJsonObject &jsonObj, QString lineBlank = "")
{
    QString retStr = "{\n";
    const QString &contentLineBlank = lineBlank + "    ";
    QJsonObject::const_iterator cIter = jsonObj.constBegin();
    for (; cIter != jsonObj.constEnd(); cIter++) {
        QString valueStr;
        if (cIter->isObject()) {
            valueStr = jsonObjToStr(cIter.value().toObject(), contentLineBlank);
        } else if (cIter->isArray()) {
            valueStr = jsonArrayToStr(cIter.value().toArray(), contentLineBlank);
        } else if (cIter->isString()) {
            valueStr = QString("\"%1\"").arg(cIter->toVariant().toString());
        }  else {
            valueStr = cIter.value().toVariant().toString();
        }
        retStr += QString("%1%2 = %3,\n").arg(contentLineBlank).arg(cIter.key()).arg(valueStr);
    }

    retStr += lineBlank + "}";

    return retStr;
}

namespace Lua {

QJsonObject LuaStrToJsonObj(const QString &luaStr)
{
    QString contentStr = luaStr;
    contentStr.remove(" ").remove("\n").remove("\r").remove("\t");

    int luaReturnStrIndex = contentStr.indexOf(LuaReturnStr);
    contentStr = contentStr.mid(luaReturnStrIndex + LuaReturnStrLength,
                                contentStr.length() - luaReturnStrIndex - LuaReturnStrLength);
    // qDebug() << Q_FUNC_INFO << contentStr;

    const QJsonObject &jsonObj = strToJsonObj(contentStr);

    return jsonObj;
}

QJsonArray LuaStrToJsonArray(const QString &luaStr)
{
    QString contentStr = luaStr;
    contentStr.remove(" ").remove("\n").remove("\r").remove("\t");

    int luaReturnStrIndex = contentStr.indexOf(LuaReturnStr);
    contentStr = contentStr.mid(luaReturnStrIndex + LuaReturnStrLength,
                                contentStr.length() - luaReturnStrIndex - LuaReturnStrLength);
    // qDebug() << Q_FUNC_INFO << contentStr;

    const QJsonArray &jsonArray = strToJsonArray(contentStr);

    return jsonArray;
}

QString JsonObjToLuaStr(const QJsonObject &jsonObj)
{
    QString retStr = "return " + jsonObjToStr(jsonObj);
    return retStr;
}
}
