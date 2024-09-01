#ifndef MODEL_H
#define MODEL_H

#include "LuaCommon.h"

#include <QObject>
#include <QMap>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QStandardPaths>
#include <QFileDialog>
#include <QApplication>

enum FileDialogType {
    Save, Open
};

struct ColorInfoStruct {
    uchar R = 255;
    uchar G = 255;
    uchar B = 255;
    uchar A = 255;
};

struct ColliderInfoStruct
{
    int X = 0;
    int Y1 = 0;
    int Z = 0;
    int W = 0;
    int Y2 = 0;
    int H = 0;
    ColliderInfoStruct() {}
};

struct ColliderInfoGroupStruct
{
    QList<ColliderInfoStruct> DamageColliderInfoList;
    ColliderInfoGroupStruct() {}
};

struct SpriteInfoStruct
{
    QString Tag;
    QString LinkTag; // 链接的标签
    QString ImgPath;
    int OX = 0;
    int OY = 0;
    ColorInfoStruct ColorInfo;
    ColliderInfoGroupStruct ColliderInfoGroup;
    SpriteInfoStruct() {}
};

struct FrameAniInfoStruct {
    QString Sprite;
    int Time = 0;
};
typedef QList<FrameAniInfoStruct> FrameAniInfoList;

enum AvatarType {
    Belt,
    BeltB,
    BeltC,
    BeltD,
    BeltF,
    Cap,
    CapB,
    CapC,
    CapF,
    Coat,
    CoatB,
    CoatC,
    CoatD,
    CoatF,
    Eyes,
    Face,
    FaceB,
    Hair,
    Hat,
    Neck,
    NeckB,
    NeckC,
    NeckD,
    NeckE,
    NeckX,
    NeckF,
    Pants,
    PantsB,
    PantsD,
    PantsF,
    Shoes,
    ShoesB,
    ShoesF,
    Skin,
    DefaultWeapon,
    Weapon,
    WeaponB,
    WeaponB1,
    WeaponB2,
    WeaponC1,
    WeaponC2,
};

enum CountryType {
    CN,
    JP,
    KR,
    EN
};

struct EquInfoStruct {
    QMap<CountryType, QString> NameMap;
    QString Script;
    QString Icon;
    QString Kind;
    QString SubKind;
    QMap<AvatarType, QString> MapOfAvatarTypeToSimplePath; // 装扮简单路径 映射表
};

struct AspectLayerInfoStruct {
    QString Name;
    QString Type;
    QString Path;
};

struct AspectInfoStruct {
    QString Type;
    QString Path;
    int Order = 0;
    QString Avatar;
    QMap<AvatarType, QString> MapOfAvatarTypeToSimplePath; // 配置中config关键字对应的数据
    bool HasShadow = false;
    AspectLayerInfoStruct LayerInfo; // 结构参考于：config/actor/instance/bullet/swordman/dotarea.cfg
    QList<AspectLayerInfoStruct> LayerInfoList; // 结构参考于：config/actor/instance/article/lorien/pathgate/left.cfg
};

struct InstanceInfoStruct {
    AspectInfoStruct AspectInfo;
    QMap<AvatarType, QString> MapOfAvatarTypeToEquTag;
};

enum PathGateDirection {
    Up, Down, Left, Right
};

// 地图初始信息，目前还不清楚有哪些数据，但必须在地图信息中预留此结构体
struct MapInitInfoStruct {

};

struct MapScopeInfoStruct
{
    int WV = 0;
    int X = 0;
    int UV = -50;
    int W = 0;
    int Y = 0;
    int HV = 0;
    int H = 0;
    int DV = 0;
    MapScopeInfoStruct() {}
};

struct MapBaseInfoStruct
{
    int Width = 0;
    int Height = 0;
    int Horizon = 0;
    bool IsTown = false;
    QString Bgm;
    QString Name;
    QString Theme;
    QString Bgs;

    MapBaseInfoStruct() {}
};

struct MapPathGateInfoStruct
{
    bool IsBossGatePath = false;
    PathGateDirection Direction = Left;
    bool IsEntrance = false;

    MapPathGateInfoStruct() {}
};

struct MapGateMapInfoStruct
{
    bool Up = false;
    bool Down = false;
    bool Left = true;
    bool Right = false;

    MapGateMapInfoStruct() {}
};

struct MapLayerSpriteInfoStruct
{
    int Id = 0;
    int X = 0;
    int Y = 0;
    QString SpriteTag;

    MapLayerSpriteInfoStruct() {}
};

struct MapLayerInfoStruct {
    QList<MapLayerSpriteInfoStruct> FarLayerSpriteInfoList;
    QList<MapLayerSpriteInfoStruct> NearLayerSpriteInfoList;
    QList<MapLayerSpriteInfoStruct> FloorLayerSpriteInfoList;
    QList<MapLayerSpriteInfoStruct> ObjLayerSpriteInfoList;
    QList<MapLayerSpriteInfoStruct> EffectLayerSpriteInfoList;

    MapLayerInfoStruct() {}
};

/*
{
            ['path'] = "article/lorien/pathgate/left",
            ['x'] = 176,
            ['y'] = 450,
            ['portPosition'] = {
                ['y'] = 464,
                ['x'] = 272,
            },
            ['pathgateEnable'] = true,
            ['isEntrance'] = false,
}
*/
/*
{
            ['path'] = "duelist/tauArmy",
            ['x'] = 1040,
            ['y'] = 528,
            ['direction'] = 1,
            ['camp'] = 2,
            ['dulist'] = {
                ['isEnemy'] = true,
            },
}
*/

struct PosStruct {
    int X = 0;
    int Y = 0;
};

struct DulistInfoStruct {
    bool IsEnemy = true;
};

struct MapActorInfoStruct
{
    int X = 0;
    int Y = 0;
    QString Path;

    // path gate info
    PosStruct PortPos;
    bool PathGateEnable = false;
    bool IsEntrance = false;

    // dulist info
    int Direction = 1;
    int Camp = 2; // 1=we, 2=enemy
    DulistInfoStruct DulistInfo;

    MapActorInfoStruct() {}
};

struct MapInfoStruct
{
    MapInitInfoStruct InitInfo;
    MapScopeInfoStruct ScopeInfo;
    MapBaseInfoStruct BaseInfo;
    QList<MapPathGateInfoStruct> PathGateInfoList;
    MapGateMapInfoStruct GateMapInfo;
    MapLayerInfoStruct LayerInfo;
    QList<MapActorInfoStruct> ActorInfoList;

    MapInfoStruct() {}
};

class Model : public QObject
{
    Q_OBJECT
public:
    explicit Model(QObject *parent = nullptr);

    inline QString GetGameRootPath() { return m_gameRootPath; }
    void SetGameRootPath(const QString &path);

    void LoadItems();
    void LoadMap(const QString &mapFilePath);
    void LoadMapBySimplePath(const QString &simplePath);

    inline const QMap<QString, SpriteInfoStruct> &GetMapOfTagToSpriteInfo() {
        return m_mapOfTagToSpriteInfo;
    }
    inline const MapInfoStruct &GetMapInfo() { return m_mapInfo; }
    inline void SetMapInfo(const MapInfoStruct &mapInfo) { m_mapInfo = mapInfo; };

    inline const QMap<QString, FrameAniInfoList> &GetMapOfTagToFrameAniInfoList() {
        return m_mapOfTagToFrameAniInfoList;
    };
    inline const QMap<QString, EquInfoStruct> &GetMapOfTagToEquInfo() {
        return m_mapOfTagToEquInfo;
    };
    inline const QMap<QString, InstanceInfoStruct> &GetMapOfTagToInstanceInfo() {
        return m_mapOfTagToInstanceInfo;
    };

    void NewMap();
    void OpenMap();
    void SaveMap(const MapInfoStruct &mapInfo = MapInfoStruct());
    void SaveMapAs(const MapInfoStruct &mapInfo = MapInfoStruct());

Q_SIGNALS:
    void ItemsLoaded();
    void MapFilePathChanged(const QString &filePath);
    void MapLoaded();

private:
    void loadAppSettings();
    void saveAppSettings();
    void loadSpriteInfosFromImgDir(const QString &imgDirRelativePath);
    void loadSpriteInfosFromCfgDir(const QString &spriteConfigDirRelativePath);
    void loadFrameAniInfosFromCfgDir(const QString &frameAniConfigDirRelativePath);
    void loadEquInfosFromCfgDir(const QString &equInfoCfgDirRelativePath);
    void loadInstaceInfosFromCfgDir(const QString &instanceCfgDirRelativePath);
    void saveMapInfoToFile(const QString &filePath);
    QString getMapFilePathByFileDlg(FileDialogType dlgType);
    void setMapFilePath(const QString &filePath);

private:
    QString m_gameRootPath;
    QString m_mapFilePath;
    QMap<QString, SpriteInfoStruct> m_mapOfTagToSpriteInfo;
    QMap<QString, FrameAniInfoList> m_mapOfTagToFrameAniInfoList;
    QMap<QString, EquInfoStruct> m_mapOfTagToEquInfo;
    QMap<QString, InstanceInfoStruct> m_mapOfTagToInstanceInfo;
    MapInfoStruct m_mapInfo;
};

#endif // MODEL_H
