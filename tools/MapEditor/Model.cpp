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

SpriteInfoStruct getSpriteInfoFromFile(const QString &tag, const QString &path)
{
    SpriteInfoStruct retInfo;
    retInfo.Tag = tag;

    QFile f(path);
    if (!f.open(QIODevice::OpenModeFlag::ReadOnly)) {
        qCritical() << Q_FUNC_INFO << path << "open failed!";
        return retInfo;
    }

    QString contentStr = f.readAll().trimmed();
    f.close();

    // whether is link
   const QString &LinkCfgFileBeginStr = "return \"";
   bool isLink = contentStr.startsWith(LinkCfgFileBeginStr);
   if (isLink) {
       contentStr.remove("\n").remove("\r").remove("\t");
       const QString &linkTag = contentStr.mid(LinkCfgFileBeginStr.length(),
                                             contentStr.length() - LinkCfgFileBeginStr.length() - 1);
       retInfo.LinkTag = linkTag;
       return retInfo;
   }

   QStringList tagPathList = tag.split("/");
   tagPathList.pop_back();
   const QString tagParentPath = tagPathList.join("/");

    // to json obj
    const QJsonObject &jsonObj = Lua::LuaStrToJsonObj(contentStr);
    // 装载数值
    retInfo.ImgPath = jsonObj.value("image").toString();
    retInfo.ImgPath = retInfo.ImgPath.replace("$0", tagParentPath);
    retInfo.ImgPath = retInfo.ImgPath.replace("$A", tag);

    retInfo.OX = jsonObj.value("ox").toInt();
    retInfo.OY = jsonObj.value("oy").toInt();

    if (jsonObj.keys().contains("color")) {
        const QJsonObject &colorInfoJsonObj = jsonObj.value("color").toObject();
        retInfo.ColorInfo.R = colorInfoJsonObj.value("r").toInt();
        retInfo.ColorInfo.G = colorInfoJsonObj.value("g").toInt();
        retInfo.ColorInfo.B = colorInfoJsonObj.value("b").toInt();
        retInfo.ColorInfo.A = colorInfoJsonObj.value("a").toInt();
    }

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

FrameAniInfoList getFrameAniInfoListFromFile(const QString &tag, const QString &path)
{
    FrameAniInfoList infoList;

    QFile f(path);
    if (!f.open(QIODevice::OpenModeFlag::ReadOnly)) {
        qCritical() << Q_FUNC_INFO << path << "open failed!";
        return infoList;
    }

    QString contentStr = f.readAll().trimmed();
    f.close();

    QStringList tagPathList = tag.split("/");
    tagPathList.pop_back();
    const QString tagParentPath = tagPathList.join("/");

    const QJsonArray &jsonArrray = Lua::LuaStrToJsonArray(contentStr);
    for (const QJsonValue &jsonValue : jsonArrray) {
        const QJsonObject &frameAniInfoJsonObj = jsonValue.toObject();
        FrameAniInfoStruct info;
        info.Sprite = frameAniInfoJsonObj.value("sprite").toString();
        info.Sprite = info.Sprite.replace("$0", tagParentPath);
        info.Sprite = info.Sprite.replace("$A", tag);
        info.Time = frameAniInfoJsonObj.value("time").toInt();

        infoList.append(info);
    }

    return infoList;
}

EquInfoStruct getEquInfoFromFile(const QString &tag, const QString &path)
{
    EquInfoStruct info;

    QFile f(path);
    if (!f.open(QIODevice::OpenModeFlag::ReadOnly)) {
        qCritical() << Q_FUNC_INFO << path << "open failed!";
        return info;
    }

    QString contentStr = f.readAll().trimmed();
    f.close();

    QStringList tagPathList = tag.split("/");
    tagPathList.pop_back();
    const QString tagParentPath = tagPathList.join("/");

    const QJsonObject &jsonObj = Lua::LuaStrToJsonObj(contentStr);
    const QJsonObject &nameJsonObj = jsonObj.value("name").toObject();
    if (nameJsonObj.keys().contains("cn")) {
        info.NameMap[CN] = nameJsonObj.value("cn").toString();
    }
    if (nameJsonObj.keys().contains("jp")) {
        info.NameMap[JP] = nameJsonObj.value("jp").toString();
    }
    if (nameJsonObj.keys().contains("kr")) {
        info.NameMap[KR] = nameJsonObj.value("kr").toString();
    }
    if (nameJsonObj.keys().contains("en")) {
        info.NameMap[EN] = nameJsonObj.value("en").toString();
    }

    info.Script = jsonObj.value("script").toString();
    info.Icon = jsonObj.value("icon").toString();
    info.Icon = info.Icon.replace("$0", tagParentPath);
    info.Icon = info.Icon.replace("$A", tag);

    info.Kind = jsonObj.value("kind").toString();
    info.SubKind = jsonObj.value("subKind").toString();

    // avatar path map
    const QJsonObject &avatarJsonObj = jsonObj.value("avatar").toObject();
    const QStringList &avatarPathKeys = avatarJsonObj.keys();
    QMap<AvatarType, QString> &mapOfAvatarTypeToSimplePath = info.MapOfAvatarTypeToSimplePath;
    // function
    auto loadSimplePath = [&avatarJsonObj, &avatarPathKeys, &mapOfAvatarTypeToSimplePath]
        (AvatarType type, const QString &pathKey) {
        if (avatarPathKeys.contains(pathKey)) {
            const QString &simplePath = avatarJsonObj.value(pathKey).toString();
            mapOfAvatarTypeToSimplePath.insert(type, simplePath);
        }
    };
    // load
    loadSimplePath(Belt, "belt");
    loadSimplePath(BeltB, "belt_b");
    loadSimplePath(BeltC, "belt_c");
    loadSimplePath(BeltD, "belt_d");
    loadSimplePath(BeltF, "belt_f");
    loadSimplePath(Cap, "cap");
    loadSimplePath(CapB, "cap_b");
    loadSimplePath(CapC, "cap_c");
    loadSimplePath(CapF, "cap_f");
    loadSimplePath(Coat, "coat");
    loadSimplePath(CoatB, "coat_b");
    loadSimplePath(CoatC, "coat_c");
    loadSimplePath(CoatD, "coat_d");
    loadSimplePath(CoatF, "coat_f");
    loadSimplePath(Eyes, "eyes");
    loadSimplePath(Face, "face");
    loadSimplePath(FaceB, "face_b");
    loadSimplePath(Hair, "hair");
    loadSimplePath(Neck, "neck");
    loadSimplePath(NeckB, "neck_b");
    loadSimplePath(NeckC, "neck_c");
    loadSimplePath(NeckD, "neck_d");
    loadSimplePath(NeckE, "neck_e");
    loadSimplePath(NeckX, "neck_x");
    loadSimplePath(NeckF, "neck_f");
    loadSimplePath(Pants, "pants");
    loadSimplePath(PantsB, "pants_b");
    loadSimplePath(PantsD, "pants_d");
    loadSimplePath(PantsF, "pants_f");
    loadSimplePath(Shoes, "shoes");
    loadSimplePath(ShoesB, "shoes_b");
    loadSimplePath(ShoesF, "shoes_f");
    loadSimplePath(Skin, "skin");
    loadSimplePath(Weapon, "weapon");
    loadSimplePath(WeaponB, "weapon_b");
    loadSimplePath(WeaponB1, "weapon_b1");
    loadSimplePath(WeaponB2, "weapon_b2");
    loadSimplePath(WeaponC1, "weapon_c1");
    loadSimplePath(WeaponC2, "weapon_c2");

    return info;
}

InstanceInfoStruct getInstanceInfoFromFile(const QString &tag, const QString &path)
{
    InstanceInfoStruct info;

    QFile f(path);
    if (!f.open(QIODevice::OpenModeFlag::ReadOnly)) {
        qCritical() << Q_FUNC_INFO << path << "open failed!";
        return info;
    }

    QString contentStr = f.readAll().trimmed();
    f.close();

    QStringList tagPathList = tag.split("/");
    tagPathList.pop_back();
    const QString tagParentPath = tagPathList.join("/");

    const QJsonObject &jsonObj = Lua::LuaStrToJsonObj(contentStr);
    //// aspect
    const QJsonObject &aspectJsonObj = jsonObj.value("aspect").toObject();
    AspectInfoStruct &aspectInfo = info.AspectInfo;
    aspectInfo.Type = aspectJsonObj.value("type").toString();
    aspectInfo.Path = aspectJsonObj.value("path").toString();
    aspectInfo.Path = aspectInfo.Path.replace("$0", tagParentPath);
    aspectInfo.Path = aspectInfo.Path.replace("$A", tag);
    aspectInfo.Order = aspectJsonObj.value("order").toInt();
    aspectInfo.HasShadow = aspectJsonObj.value("hasShadow").toBool();

    aspectInfo.Avatar = aspectJsonObj.value("avatar").toString();
    aspectInfo.Avatar = aspectInfo.Avatar.replace("$0", tagParentPath);
    aspectInfo.Avatar = aspectInfo.Avatar.replace("$A", tag);
    const QJsonObject &aspectCfgJsonObj = aspectJsonObj.value("config").toObject();
    if (aspectCfgJsonObj.keys().contains("skin")) {
        const QString &simplePath = aspectCfgJsonObj.value("skin").toString();
        aspectInfo.MapOfAvatarTypeToSimplePath.insert(Skin, simplePath);
    }
    if (aspectCfgJsonObj.keys().contains("eyes")) {
        const QString &simplePath = aspectCfgJsonObj.value("eyes").toString();
        aspectInfo.MapOfAvatarTypeToSimplePath.insert(Eyes, simplePath);
    }
    if (aspectCfgJsonObj.keys().contains("hat")) {
        const QString &simplePath = aspectCfgJsonObj.value("hat").toString();
        aspectInfo.MapOfAvatarTypeToSimplePath.insert(Hat, simplePath);
    }
    if (aspectCfgJsonObj.keys().contains("weapon")) {
        const QString &simplePath = aspectCfgJsonObj.value("weapon").toString();
        aspectInfo.MapOfAvatarTypeToSimplePath.insert(Weapon, simplePath);
    }

    // layer
    if (aspectJsonObj.keys().contains("layer")) {
        const QJsonValue &layerJsonValue = aspectJsonObj.value("layer");
        if (layerJsonValue.isArray()) {
            const QJsonArray &layersJsonArray = aspectJsonObj.value("layer").toArray();
            QList<AspectLayerInfoStruct> &layers = aspectInfo.LayerInfoList;
            for (const QJsonValue &jsonValue : layersJsonArray) {
                const QJsonObject &aspectLayerJsonObj = jsonValue.toObject();

                AspectLayerInfoStruct layerInfo;
                layerInfo.Name = aspectLayerJsonObj.value("name").toString();
                layerInfo.Type = aspectLayerJsonObj.value("type").toString();
                layerInfo.Path = aspectLayerJsonObj.value("path").toString();
                layerInfo.Path = layerInfo.Path.replace("$0", tagParentPath);
                layerInfo.Path = layerInfo.Path.replace("$A", tag);

                layers.append(layerInfo);
            }
        } else if (layerJsonValue.isObject()) {
            AspectLayerInfoStruct &layerInfo = aspectInfo.LayerInfo;
            const QJsonObject &layerJsonObj = aspectJsonObj.value("layer").toObject();
            layerInfo.Name = layerJsonObj.value("name").toString();
            layerInfo.Type = layerJsonObj.value("type").toString();
            layerInfo.Path = layerJsonObj.value("path").toString();
            layerInfo.Path = layerInfo.Path.replace("$0", tagParentPath);
            layerInfo.Path = layerInfo.Path.replace("$A", tag);
        }
    }

    //// equipments
    if (jsonObj.keys().contains("equipments")) {
        QMap<AvatarType, QString> &mapOfAvatarTypeToEquTag = info.MapOfAvatarTypeToEquTag;
        const QJsonObject &equsJsonObj = jsonObj.value("equipments").toObject();

        QString tag = equsJsonObj.value("defaultWeapon").toString();
        mapOfAvatarTypeToEquTag.insert(DefaultWeapon, tag);

        tag = equsJsonObj.value("weapon").toString();
        mapOfAvatarTypeToEquTag.insert(Weapon, tag);

        tag = equsJsonObj.value("belt").toString();
        mapOfAvatarTypeToEquTag.insert(Belt, tag);

        tag = equsJsonObj.value("cap").toString();
        mapOfAvatarTypeToEquTag.insert(Cap, tag);

        tag = equsJsonObj.value("coat").toString();
        mapOfAvatarTypeToEquTag.insert(Coat, tag);

        tag = equsJsonObj.value("face").toString();
        mapOfAvatarTypeToEquTag.insert(Face, tag);

        tag = equsJsonObj.value("hair").toString();
        mapOfAvatarTypeToEquTag.insert(Hair, tag);

        tag = equsJsonObj.value("neck").toString();
        mapOfAvatarTypeToEquTag.insert(Neck, tag);

        tag = equsJsonObj.value("pants").toString();
        mapOfAvatarTypeToEquTag.insert(Pants, tag);

        tag = equsJsonObj.value("shoes").toString();
        mapOfAvatarTypeToEquTag.insert(Shoes, tag);
    }

    return info;
}

Model::Model(QObject *parent)
    : QObject(parent)
{
}


void Model::loadSpriteInfosFromImgDir(const QString &imgDirRelativePath)
{
    const QString &imgRootDirPath = QString("%1/%2").arg(GameRootPath).arg("asset/image");
    const QString &imgRootDirAbsPath = QFileInfo(imgRootDirPath).absoluteFilePath();
    const int imgRootDirAbsPathStrLength = imgRootDirAbsPath.length();
    const QString &imgDirAbsPath = QString("%1/%2").arg(imgRootDirAbsPath).arg(imgDirRelativePath);

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

void Model::loadSpriteInfosFromCfgDir(const QString &spriteConfigDirRelativePath)
{
    const QString &GameRootDirAbsPath = QFileInfo(GameRootPath).absoluteFilePath();
    const QString &spriteRootDirAbsPath = QString("%1/%2").arg(GameRootDirAbsPath).arg("config/asset/sprite");
    const int spriteRootDirAbsPathStrLength = spriteRootDirAbsPath.length();
    const QString &spriteDirAbsPath = QString("%1/%2").arg(spriteRootDirAbsPath).arg(spriteConfigDirRelativePath);

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
        SpriteInfoStruct spriteInfo = getSpriteInfoFromFile(cIt.key(), cIt.value());
        if (spriteInfo.ImgPath.isEmpty()) {
            spriteInfo.ImgPath = QString("%1/%2/%3.png").arg(GameRootDirAbsPath)
                                .arg("asset/image").arg(cIt.key());
        } else {
            spriteInfo.ImgPath = QString("%1/%2/%3.png").arg(GameRootDirAbsPath)
                                .arg("asset/image").arg(spriteInfo.ImgPath);
        }
        QFileInfo fInfo(spriteInfo.ImgPath);
        // if(!fInfo.exists()) {
        //     continue;
        // }

       m_mapOfTagToSpriteInfo.insert(cIt.key(), spriteInfo);
    }

    // load link sprite info
    QMap<QString, SpriteInfoStruct>::iterator iter2 = m_mapOfTagToSpriteInfo.begin();
    for (; iter2 != m_mapOfTagToSpriteInfo.end(); iter2++) {
        SpriteInfoStruct &info = iter2.value();
        if (info.LinkTag.isEmpty()) {
            continue;
        }

        while(1) {
            info = m_mapOfTagToSpriteInfo.value(info.LinkTag);
            if (info.LinkTag.isEmpty()) {
                break;
            }
        }
    }

}

void Model::loadFrameAniInfosFromCfgDir(const QString &frameAniConfigDirRelativePath)
{
    const QString &GameRootDirAbsPath = QFileInfo(GameRootPath).absoluteFilePath();
    const QString &frameAniCfgRootDirAbsPath = QString("%1/%2").arg(GameRootDirAbsPath).arg("config/asset/frameani");
    const int frameAniCfgRootDirAbsPathStrLength = frameAniCfgRootDirAbsPath.length();
    const QString &frameAniCfgDirAbsPath = QString("%1/%2").arg(frameAniCfgRootDirAbsPath).arg(frameAniConfigDirRelativePath);

    const QString &FrameAniCfgFileSuffixStr = ".cfg";
    const int FrameAniCfgFileSuffixStrLength = FrameAniCfgFileSuffixStr.length();

    QMap<QString, QString> mapOfTagToFrameAniCfgFilePath;
    const QFileInfoList &frameAniCfgFileInfoList = listDirFilePath(frameAniCfgDirAbsPath);
    for (const QFileInfo &info : frameAniCfgFileInfoList) {
        // 提取出 tag
        QString tag = info.absoluteFilePath();
        tag = tag.mid(frameAniCfgRootDirAbsPathStrLength + 1,
                     tag.length() - frameAniCfgRootDirAbsPathStrLength - FrameAniCfgFileSuffixStrLength - 1);

        mapOfTagToFrameAniCfgFilePath.insert(tag, info.absoluteFilePath());
    }

    QMap<QString, QString>::const_iterator cIt = mapOfTagToFrameAniCfgFilePath.constBegin();
    for (; cIt != mapOfTagToFrameAniCfgFilePath.constEnd(); cIt++) {
        const FrameAniInfoList &infoList = getFrameAniInfoListFromFile(cIt.key(), cIt.value());

        m_mapOfTagToFrameAniInfoList.insert(cIt.key(), infoList);
    }
}

void Model::loadEquInfosFromCfgDir(const QString &equInfoCfgDirRelativePath)
{
    const QString &GameRootDirAbsPath = QFileInfo(GameRootPath).absoluteFilePath();
    const QString &equCfgRootDirAbsPath = QString("%1/%2").arg(GameRootDirAbsPath).arg("config/actor/equipment");
    const int equCfgRootDirAbsPathStrLength = equCfgRootDirAbsPath.length();
    const QString &equCfgDirAbsPath = QString("%1/%2").arg(equCfgRootDirAbsPath).arg(equInfoCfgDirRelativePath);

    const QString &EquCfgFileSuffixStr = ".cfg";
    const int EquCfgFileSuffixStrLength = EquCfgFileSuffixStr.length();

    QMap<QString, QString> mapOfTagToEquCfgFilePath;
    const QFileInfoList &equCfgFileInfoList = listDirFilePath(equCfgDirAbsPath);
    for (const QFileInfo &info : equCfgFileInfoList) {
        // 提取出 tag
        QString tag = info.absoluteFilePath();
        tag = tag.mid(equCfgRootDirAbsPathStrLength + 1,
                      tag.length() - equCfgRootDirAbsPathStrLength - EquCfgFileSuffixStrLength - 1);

        mapOfTagToEquCfgFilePath.insert(tag, info.absoluteFilePath());
    }

    QMap<QString, QString>::const_iterator cIt = mapOfTagToEquCfgFilePath.constBegin();
    for (; cIt != mapOfTagToEquCfgFilePath.constEnd(); cIt++) {
        const EquInfoStruct &equInfo = getEquInfoFromFile(cIt.key(), cIt.value());

        m_mapOfTagToEquInfo.insert(cIt.key(), equInfo);
    }
}

void Model::loadInstaceInfosFromCfgDir(const QString &instanceCfgDirRelativePath)
{
    const QString &GameRootDirAbsPath = QFileInfo(GameRootPath).absoluteFilePath();
    const QString &instanceCfgRootDirAbsPath = QString("%1/%2").arg(GameRootDirAbsPath)
                                                   .arg("config/actor/instance");
    const int instanceCfgRootDirAbsPathStrLength = instanceCfgRootDirAbsPath.length();
    const QString &instanceCfgDirAbsPath = QString("%1/%2").arg(instanceCfgRootDirAbsPath)
                                               .arg(instanceCfgDirRelativePath);

    const QString &InstanceCfgFileSuffixStr = ".cfg";
    const int InstanceCfgFileSuffixStrLength = InstanceCfgFileSuffixStr.length();

    QMap<QString, QString> mapOfTagToInstanceCfgFilePath;
    const QFileInfoList &instanceCfgFileInfoList = listDirFilePath(instanceCfgDirAbsPath);
    for (const QFileInfo &info : instanceCfgFileInfoList) {
        // 提取出 tag
        QString tag = info.absoluteFilePath();
        tag = tag.mid(instanceCfgRootDirAbsPathStrLength + 1,
                      tag.length() - instanceCfgRootDirAbsPathStrLength - InstanceCfgFileSuffixStrLength - 1);

        mapOfTagToInstanceCfgFilePath.insert(tag, info.absoluteFilePath());
    }

    QMap<QString, QString>::const_iterator cIt = mapOfTagToInstanceCfgFilePath.constBegin();
    for (; cIt != mapOfTagToInstanceCfgFilePath.constEnd(); cIt++) {
        const InstanceInfoStruct &info = getInstanceInfoFromFile(cIt.key(), cIt.value());

        m_mapOfTagToInstanceInfo.insert(cIt.key(), info);
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
    loadSpriteInfosFromImgDir("./");
    //    loadSpriteInfosFromeCfgFile("actor/article");
    loadSpriteInfosFromCfgDir("./");

    // 2. 帧动画，config/asset/frameani
    // tag: 文件路径中“config/asset/frameani/”之后的字符串
    loadFrameAniInfosFromCfgDir("./");


    // 3. 装备，config/actor/equipment
    // tag: 文件路径中“config/actor/equipment/”之后的字符串
    loadEquInfosFromCfgDir("./");

    // 4. 人物实例，config/actor/instance
    // tag: 文件路径中“config/actor/instance/”之后的字符串
    loadInstaceInfosFromCfgDir("./");
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
