#include "Model.h"

//静态图片	config\asset\sprite
//          asset\image\map
//动态图片	config\asset\frameani
//人物    config\actor\instance

#include <QtDebug>
#include <QDir>
#include <QFileInfo>

const QString &GameRootPath = "../..";

QFileInfoList listDirFilePath(const QString &path)
{
    QFileInfoList retList;

    QDir dir(path);
    const QFileInfoList &fileInfoList = dir.entryInfoList(QDir::Filter::Files |
                                                          QDir::Filter::Dirs |
                                                          QDir::Filter::NoDotAndDotDot |
                                                          QDir::Filter::NoSymLinks);

    for (const QFileInfo &info : fileInfoList) {
        if (info.isDir()) {
            const QFileInfoList &infoList = listDirFilePath(info.filePath());
            retList.append(infoList);
            continue;
        }

        if (info.isFile()) {
            retList.append(info);
            continue;
        }
    }

    return retList;
}

Model::Model(QObject *parent)
    : QObject(parent)
{
}

SpriteInfoStruct getSpriteInfoFromFile(const QString &path)
{
    SpriteInfoStruct retInfo;

    QFile f(path);
    if (!f.open(QIODevice::OpenModeFlag::ReadOnly)) {
        qCritical() << Q_FUNC_INFO << path << "open failed!";
        return retInfo;
    }

    QString contentStr = f.readAll().trimmed();
    f.close();

    const QJsonObject &jsonObj = Lua::LuaStrToJsonObj(contentStr);
    // 装载数值
    retInfo.OX = jsonObj.value("ox").toInt();
    retInfo.OY = jsonObj.value("oy").toInt();
    QList<ColliderInfoStruct> &damageColliderInfoList = retInfo.ColliderInfoGroup.DamageColliderInfoList;
    if (jsonObj.keys().contains("collider")) {
        const QJsonObject &colliderInfoGroupJsonObj = jsonObj.value("collider").toObject();
        if (colliderInfoGroupJsonObj.keys().contains("damage")) {
            const QJsonArray &damageColliderInfoJsonArray = colliderInfoGroupJsonObj.value("damage").toArray();
            for (const QJsonValue &jsonValue : damageColliderInfoJsonArray) {
                const QJsonObject &colliderInfoJsonObj = jsonValue.toObject();
                ColliderInfoStruct colliderInfo;
                colliderInfo.X = colliderInfoJsonObj.value("x").toInt();
                colliderInfo.Y1 = colliderInfoJsonObj.value("y1").toInt();
                colliderInfo.Z = colliderInfoJsonObj.value("z").toInt();
                colliderInfo.W = colliderInfoJsonObj.value("w").toInt();
                colliderInfo.Y2 = colliderInfoJsonObj.value("y2").toInt();
                colliderInfo.H = colliderInfoJsonObj.value("h").toInt();

                damageColliderInfoList.append(colliderInfo);
            }
        }
    }

    return retInfo;
}

void Model::loadSpriteInfosFromeImgFile(const QString &imgFileRelativePath)
{
    const QString &imgRootDirPath = QString("%1/%2").arg(GameRootPath).arg("asset/image");
    const QString &imgRootDirAbsPath = QFileInfo(imgRootDirPath).absoluteFilePath();
    const int imgRootDirAbsPathStrLength = imgRootDirAbsPath.length();
    const QString &imgDirAbsPath = QString("%1/%2").arg(imgRootDirAbsPath).arg(imgFileRelativePath);

    const QString &ImgFileSuffixStr = ".png";
    const int ImgFileSuffixStrLength = ImgFileSuffixStr.length();

    const QFileInfoList &imgFileInfoList = listDirFilePath(imgDirAbsPath);
    for (const QFileInfo &info : imgFileInfoList) {
        // 提取出 tag
        QString tag = info.absoluteFilePath();
        tag = tag.mid(imgRootDirAbsPathStrLength + 1,
                      tag.length() - imgRootDirAbsPathStrLength - ImgFileSuffixStrLength - 1);

        SpriteInfoStruct spriteInfo;
        spriteInfo.Tag = tag;
        spriteInfo.ImgPath = info.absoluteFilePath();

        m_mapOfTagToSpriteInfo.insert(tag, spriteInfo);
    }
}

void Model::loadSpriteInfosFromeCfgFile(const QString &spriteConfigFileRelativePath)
{
    const QString &GameRootDirAbsPath = QFileInfo(GameRootPath).absoluteFilePath();
    const QString &spriteRootDirAbsPath = QString("%1/%2").arg(GameRootDirAbsPath).arg("config/asset/sprite");
    const int spriteRootDirAbsPathStrLength = spriteRootDirAbsPath.length();
    const QString &spriteDirAbsPath = QString("%1/%2").arg(spriteRootDirAbsPath).arg(spriteConfigFileRelativePath);

    const QString &SpriteCfgFileSuffixStr = ".cfg";
    const int SpriteCfgFileSuffixStrLength = SpriteCfgFileSuffixStr.length();

    QMap<QString, QString> mapOfTagToSpriteCfgFilePath;
    const QFileInfoList &spriteFileInfoList = listDirFilePath(spriteDirAbsPath);
    for (const QFileInfo &info : spriteFileInfoList) {
        // 提取出 tag
        QString tag = info.absoluteFilePath();
        tag = tag.mid(spriteRootDirAbsPathStrLength + 1,
                    tag.length() - spriteRootDirAbsPathStrLength - SpriteCfgFileSuffixStrLength - 1);

        mapOfTagToSpriteCfgFilePath.insert(tag, info.absoluteFilePath());
    }

    QMap<QString, QString>::const_iterator cIt = mapOfTagToSpriteCfgFilePath.constBegin();
    for (; cIt != mapOfTagToSpriteCfgFilePath.constEnd(); cIt++) {
        SpriteInfoStruct spriteInfo = getSpriteInfoFromFile(cIt.value());
        spriteInfo.Tag = cIt.key();
        spriteInfo.ImgPath = QString("%1/%2/%3.png").arg(GameRootDirAbsPath)
                                .arg("asset/image").arg(cIt.key());
        QFileInfo fInfo(spriteInfo.ImgPath);
        if(!fInfo.exists()) {
            continue;
        }

       m_mapOfTagToSpriteInfo.insert(cIt.key(), spriteInfo);
    }
}

void Model::saveMapInfoToFile(const QString &filePath)
{
    QJsonObject jsonObj;

    // init
    jsonObj.insert("init", QJsonObject());

    // scope
    const MapScopeInfoStruct &scopeInfo = m_mapInfo.ScopeInfo;
    QJsonObject scopeInfoJsonObj;
    scopeInfoJsonObj.insert("wv", scopeInfo.WV);
    scopeInfoJsonObj.insert("x", scopeInfo.X);
    scopeInfoJsonObj.insert("uv", scopeInfo.UV);
    scopeInfoJsonObj.insert("w", scopeInfo.W);
    scopeInfoJsonObj.insert("y", scopeInfo.Y);
    scopeInfoJsonObj.insert("hv", scopeInfo.HV);
    scopeInfoJsonObj.insert("h", scopeInfo.H);
    scopeInfoJsonObj.insert("dv", scopeInfo.DV);
    jsonObj.insert("scope", scopeInfoJsonObj);

    // base info
    const MapBaseInfoStruct &baseInfo = m_mapInfo.BaseInfo;
    QJsonObject baseInfoJsonObj;
    baseInfoJsonObj.insert("width", baseInfo.Width);
    baseInfoJsonObj.insert("height", baseInfo.Height);
    baseInfoJsonObj.insert("horizon", baseInfo.Horizon);
    baseInfoJsonObj.insert("isTown", baseInfo.IsTown);
    baseInfoJsonObj.insert("bgm", baseInfo.Bgm);
    baseInfoJsonObj.insert("name", baseInfo.Name);
    baseInfoJsonObj.insert("theme", baseInfo.Theme);
    baseInfoJsonObj.insert("bgs", baseInfo.Bgs);
    jsonObj.insert("info", baseInfoJsonObj);

    // map path gate inf list
    const QList<MapPathGateInfoStruct> &pathGateInfoList = m_mapInfo.PathGateInfoList;
    QJsonArray pathGateInfoListJsonArray;
    for (const MapPathGateInfoStruct &info : pathGateInfoList) {
       QJsonObject pathGateInfoJsonObj;
       pathGateInfoJsonObj.insert("IsBossGatePath", info.IsBossGatePath);
       QString dirStr;
       if (info.Direction == Up) {
            dirStr = "up";
       } else if (info.Direction == Down) {
            dirStr = "down";
       } else if (info.Direction == Left) {
            dirStr = "left";
       } else {
            dirStr = "right";
       }
       pathGateInfoJsonObj.insert("Direction", dirStr);
       pathGateInfoJsonObj.insert("IsEntrance", info.IsEntrance);

       pathGateInfoListJsonArray.append(pathGateInfoJsonObj);
    }
    jsonObj.insert("pathGateInfoList", pathGateInfoListJsonArray);

    // gate map
    const MapGateMapInfoStruct gateMapInfo = m_mapInfo.GateMapInfo;
    QJsonObject gateMapInfoJsonObj;
    gateMapInfoJsonObj.insert("up", gateMapInfo.Up);
    gateMapInfoJsonObj.insert("down", gateMapInfo.Down);
    gateMapInfoJsonObj.insert("left", gateMapInfo.Left);
    gateMapInfoJsonObj.insert("right", gateMapInfo.Right);
    jsonObj.insert("gateMap", gateMapInfoJsonObj);

    //// layer info
    const MapLayerInfoStruct &layerInfo = m_mapInfo.LayerInfo;
    QJsonObject layerInfoJsonObj;
    // function
    auto layerSpriteInfoListToJsonArray = [=](const QList<MapLayerSpriteInfoStruct> &layerSpriteInfoList) {
        QJsonArray layerSpriteInfoJsonArray;
        for (const MapLayerSpriteInfoStruct &info : layerSpriteInfoList) {
            QJsonObject layerSpriteInfoJsonObj;
            layerSpriteInfoJsonObj.insert("id", info.Id);
            // 地图 sprite 标签需要去掉开头的"map/"
            const QString &mapSpriteTag = info.SpriteTag.right(info.SpriteTag.length() - 4);
            layerSpriteInfoJsonObj.insert("sprite", mapSpriteTag);
            layerSpriteInfoJsonObj.insert("x", info.X);
            layerSpriteInfoJsonObj.insert("y", info.Y);
            layerSpriteInfoJsonArray.append(layerSpriteInfoJsonObj);
        }

        return layerSpriteInfoJsonArray;
    };

    // far layer info
    const QList<MapLayerSpriteInfoStruct> &farLayerSpriteInfoList = layerInfo.FarLayerSpriteInfoList;
    const QJsonArray &farLayerSpriteInfoJsonArray = layerSpriteInfoListToJsonArray(farLayerSpriteInfoList);
    layerInfoJsonObj.insert("far", farLayerSpriteInfoJsonArray);

    // near layer info
    const QList<MapLayerSpriteInfoStruct> &nearLayerSpriteInfoList = layerInfo.NearLayerSpriteInfoList;
    const QJsonArray &nearLayerSpriteInfoJsonArray = layerSpriteInfoListToJsonArray(nearLayerSpriteInfoList);
    layerInfoJsonObj.insert("near", nearLayerSpriteInfoJsonArray);

    // floor layer info
    const QList<MapLayerSpriteInfoStruct> &floorLayerSpriteInfoList = layerInfo.FloorLayerSpriteInfoList;
    const QJsonArray &floorLayerSpriteInfoJsonArray = layerSpriteInfoListToJsonArray(floorLayerSpriteInfoList);
    layerInfoJsonObj.insert("floor", floorLayerSpriteInfoJsonArray);

    // obj layer info
    const QList<MapLayerSpriteInfoStruct> &objLayerSpriteInfoList = layerInfo.ObjLayerSpriteInfoList;
    const QJsonArray &objLayerSpriteInfoJsonArray = layerSpriteInfoListToJsonArray(objLayerSpriteInfoList);
    layerInfoJsonObj.insert("object", objLayerSpriteInfoJsonArray);

    // effect layer info
    const QList<MapLayerSpriteInfoStruct> &effectLayerSpriteInfoList = layerInfo.EffectLayerSpriteInfoList;
    const QJsonArray &effectLayerSpriteInfoJsonArray = layerSpriteInfoListToJsonArray(effectLayerSpriteInfoList);
    layerInfoJsonObj.insert("effect", effectLayerSpriteInfoJsonArray);

    jsonObj.insert("layer", layerInfoJsonObj);

    //// actor list
    const QList<MapActorInfoStruct> &actorInfoList = m_mapInfo.ActorInfoList;
    QJsonArray actorInfoListJsonArray;
    for (const MapActorInfoStruct &info : actorInfoList) {
        QJsonObject actorInfoJsonObj;
        actorInfoJsonObj.insert("path", info.Path);
        actorInfoJsonObj.insert("x", info.X);
        actorInfoJsonObj.insert("y", info.Y);

        // path gate params
        QJsonObject portPosJsonObj;
        portPosJsonObj.insert("x", info.PortPos.X);
        portPosJsonObj.insert("y", info.PortPos.Y);
        actorInfoJsonObj.insert("portPosition", portPosJsonObj);
        actorInfoJsonObj.insert("pathgateEnable", info.PathGateEnable);
        actorInfoJsonObj.insert("isEntrance", info.IsEntrance);

        // dulist params
        actorInfoJsonObj.insert("direction", info.Direction);
        actorInfoJsonObj.insert("camp", info.Camp);
        QJsonObject dulistJsonObj;
        dulistJsonObj.insert("isEnemy", info.DulistInfo.IsEnemy);
        actorInfoJsonObj.insert("dulist", dulistJsonObj);

        actorInfoListJsonArray.append(actorInfoJsonObj);
    }
    jsonObj.insert("actor", actorInfoListJsonArray);

    // write
    const QString &contentStr = Lua::JsonObjToLuaStr(jsonObj);
    QFile f(filePath);
    if (!f.open(QIODevice::OpenModeFlag::WriteOnly)) {
       qCritical() << Q_FUNC_INFO << m_mapFilePath << "open failed";
       return;
    }

    f.write(contentStr.toUtf8());
    f.close();
}

QString Model::getMapFilePathByFileDlg()
{
    const QString &localDataDirPath = QStandardPaths::writableLocation(QStandardPaths::StandardLocation::GenericDataLocation);

    QString defaultFilePath = QString("%1/love/com.ccc.dfqo/config/map/instance/1.cfg").arg(localDataDirPath);

    QFileInfo fInfo(defaultFilePath);
    QDir dir = fInfo.dir();
    if (!dir.exists()) {
       dir.mkpath(dir.absolutePath());
    }

    QString filePath = QFileDialog::getSaveFileName(nullptr, "保存地图", defaultFilePath, "*.cfg");
    return filePath;
}

void Model::LoadItems()
{
    // 1. 静态图片 config\asset\sprite 或 asset\image\map
    loadSpriteInfosFromeImgFile("map");
    loadSpriteInfosFromeCfgFile("actor/article");
    loadSpriteInfosFromeCfgFile("map");
}

void Model::LoadMap(const QString &mapFilePath)
{
    QFile f(mapFilePath);
    if (!f.open(QIODevice::OpenModeFlag::ReadOnly)) {
       qCritical() << Q_FUNC_INFO << mapFilePath << "open failed!";
       return;
    }

    QString contentStr = f.readAll().trimmed();
    f.close();

    const QJsonObject &jsonObj = Lua::LuaStrToJsonObj(contentStr);

    // qDebug() << Q_FUNC_INFO << jsonObj;

    if (!jsonObj.contains("scope")) {
       qCritical() << Q_FUNC_INFO << "map data is error";
       return;
    }
    const QJsonObject &scopeJsonObj = jsonObj.value("scope").toObject();
    MapScopeInfoStruct &scopeInfo = m_mapInfo.ScopeInfo;
    scopeInfo.WV = scopeJsonObj.value("wv").toInt();
    scopeInfo.X = scopeJsonObj.value("x").toInt();
    scopeInfo.UV = scopeJsonObj.value("uv").toInt();
    scopeInfo.W = scopeJsonObj.value("w").toInt();
    scopeInfo.Y = scopeJsonObj.value("y").toInt();
    scopeInfo.HV = scopeJsonObj.value("hv").toInt();
    scopeInfo.H = scopeJsonObj.value("h").toInt();
    scopeInfo.DV = scopeJsonObj.value("dv").toInt();

    if (!jsonObj.contains("info")) {
       qCritical() << Q_FUNC_INFO << "map data is error";
       return;
    }
    const QJsonObject &baseInfoJsonObj = jsonObj.value("info").toObject();
    MapBaseInfoStruct &baseInfo = m_mapInfo.BaseInfo;
    baseInfo.Width = baseInfoJsonObj.value("width").toInt();
    baseInfo.Height = baseInfoJsonObj.value("height").toInt();
    baseInfo.Horizon = baseInfoJsonObj.value("horizon").toInt();
    baseInfo.IsTown = baseInfoJsonObj.value("isTown").toBool();
    baseInfo.Bgm = baseInfoJsonObj.value("bgm").toString();
    baseInfo.Name = baseInfoJsonObj.value("name").toString();
    baseInfo.Theme = baseInfoJsonObj.value("theme").toString();
    baseInfo.Bgs = baseInfoJsonObj.value("bgs").toString();

    if (!jsonObj.contains("pathGateInfoList")) {
        qCritical() << Q_FUNC_INFO << "map data is error";
        return;
    }
    const QJsonArray &pathGateInfoListJsonArray = jsonObj.value("pathGateInfoList").toArray();
    QList<MapPathGateInfoStruct> &pathGateInfoList = m_mapInfo.PathGateInfoList;
    for (const QJsonValue &jsonValue : pathGateInfoListJsonArray) {
        const QJsonObject &pathGateInfoJsonObj = jsonValue.toObject();

        MapPathGateInfoStruct pathGateInfo;
        pathGateInfo.IsBossGatePath = pathGateInfoJsonObj.value("IsBossGatePath").toBool();
        const QString &dirStr = pathGateInfoJsonObj.value("Direction").toString();
        PathGateDirection dir = Left;
        if ("up" == dirStr) {
            dir = Up;
        } else if ("down" == dirStr) {
            dir = Down;
        } else if ("left" == dirStr) {
            dir = Left;
        } else if ("right" == dirStr) {
            dir = Right;
        }
        pathGateInfo.Direction = dir;

        pathGateInfo.IsEntrance = pathGateInfoJsonObj.value("IsEntrance").toBool();

        pathGateInfoList.append(pathGateInfo);
    }

    // gateMap
    if (!jsonObj.contains("gateMap")) {
        qCritical() << Q_FUNC_INFO << "map data is error";
        return;
    }
    const QJsonObject &gateMapInfoJsonObj = jsonObj.value("gateMap").toObject();
    MapGateMapInfoStruct &gateMapInfo = m_mapInfo.GateMapInfo;
    gateMapInfo.Up = gateMapInfoJsonObj.value("up").toBool();
    gateMapInfo.Down = gateMapInfoJsonObj.value("Down").toBool();
    gateMapInfo.Left = gateMapInfoJsonObj.value("Left").toBool();
    gateMapInfo.Right = gateMapInfoJsonObj.value("Right").toBool();

    // layer
    if (!jsonObj.contains("layer")) {
        qCritical() << Q_FUNC_INFO << "map data is error";
        return;
    }
    const QJsonObject &layerInfoJsonObj = jsonObj.value("layer").toObject();
    MapLayerInfoStruct &layerInfo = m_mapInfo.LayerInfo;

    auto loadLayerSpriteInfoList = [&layerInfoJsonObj]
        (QList<MapLayerSpriteInfoStruct> &infoList,const QString &layerKey) {
        const QJsonArray &layerSpriteInfoListJsonArray = layerInfoJsonObj.value(layerKey).toArray();
        for (const QJsonValue &jsonValue : layerSpriteInfoListJsonArray) {
            const QJsonObject &layerSpriteInfoJsonObj = jsonValue.toObject();

            MapLayerSpriteInfoStruct layerSpriteInfo;
            layerSpriteInfo.Id = layerSpriteInfoJsonObj.value("id").toInt();
            layerSpriteInfo.X = layerSpriteInfoJsonObj.value("x").toInt();
            layerSpriteInfo.Y = layerSpriteInfoJsonObj.value("y").toInt();
            layerSpriteInfo.SpriteTag = "map/" + layerSpriteInfoJsonObj.value("sprite").toString();

            infoList.append(layerSpriteInfo);
        }
    };

    loadLayerSpriteInfoList(layerInfo.FarLayerSpriteInfoList, "far");
    loadLayerSpriteInfoList(layerInfo.NearLayerSpriteInfoList, "near");
    loadLayerSpriteInfoList(layerInfo.FloorLayerSpriteInfoList, "floor");
    loadLayerSpriteInfoList(layerInfo.ObjLayerSpriteInfoList, "object");
    loadLayerSpriteInfoList(layerInfo.EffectLayerSpriteInfoList, "effect");

    // actor
    if (!jsonObj.contains("actor")) {
        qCritical() << Q_FUNC_INFO << "map data is error";
        return;
    }
    QList<MapActorInfoStruct> &actorInfoList = m_mapInfo.ActorInfoList;
    const QJsonArray &actorInfoListJsonArray = jsonObj.value("actor").toArray();
    for (const QJsonValue &jsonValue : actorInfoListJsonArray) {
        const QJsonObject &actorInfoJsonObj = jsonValue.toObject();
        MapActorInfoStruct actorInfo;
        actorInfo.Path = actorInfoJsonObj.value("path").toString();
        actorInfo.X = actorInfoJsonObj.value("x").toInt();
        actorInfo.Y = actorInfoJsonObj.value("y").toInt();
        // path gate params
        if (actorInfoJsonObj.keys().contains("portPosition")) {
            const QJsonObject &portPosJsonObj = actorInfoJsonObj.value("portPosition").toObject();
            actorInfo.PortPos.X = portPosJsonObj.value("x").toInt();
            actorInfo.PortPos.Y = portPosJsonObj.value("y").toInt();
        }
        if (actorInfoJsonObj.keys().contains("pathgateEnable")) {
            actorInfo.PathGateEnable = actorInfoJsonObj.value("pathgateEnable").toBool();
        }
        if (actorInfoJsonObj.keys().contains("isEntrance")) {
            actorInfo.IsEntrance = actorInfoJsonObj.value("isEntrance").toBool();
        }
        // dulist params
        if (actorInfoJsonObj.keys().contains("direction")) {
            actorInfo.Direction = actorInfoJsonObj.value("direction").toInt();
        }
        if (actorInfoJsonObj.keys().contains("camp")) {
            actorInfo.Camp = actorInfoJsonObj.value("camp").toInt();
        }
        if (actorInfoJsonObj.keys().contains("dulist")) {
            const QJsonObject &dulistJsonObj = actorInfoJsonObj.value("dulist").toObject();
            actorInfo.DulistInfo.IsEnemy = dulistJsonObj.value("isEnemy").toBool();
        }

        actorInfoList.append(actorInfo);
    }

    m_mapFilePath = mapFilePath;
}

void Model::LoadMapBySimplePath(const QString &simplePath)
{
    const QString &mapRootDirPath = QString("%1/%2").arg(GameRootPath).arg("config/map/instance");
    const QString &mapRootDirAbsPath = QFileInfo(mapRootDirPath).absoluteFilePath();
    const QString &mapFileAbsPath = QString("%1/%2.cfg").arg(mapRootDirAbsPath).arg(simplePath);

    LoadMap(mapFileAbsPath);
}

void Model::OpenMap()
{
    QString mapFilePath = getMapFilePathByFileDlg();
    if (mapFilePath.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "not select map file path";
        return;
    }

    LoadMap(mapFilePath);
}

void Model::SaveMap()
{
    saveMapInfoToFile(m_mapFilePath);
}

void Model::SaveMapAs()
{
    QString savingFilePath = getMapFilePathByFileDlg();
    if (savingFilePath.isEmpty()) {
        qDebug() << Q_FUNC_INFO << "not select saving file path";
        return;
    }

    saveMapInfoToFile(savingFilePath);
    m_mapFilePath = savingFilePath;
}
