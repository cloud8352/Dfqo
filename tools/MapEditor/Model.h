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
    QString ImgPath;
    int OX = 0;
    int OY = 0;
    ColliderInfoGroupStruct ColliderInfoGroup;
    SpriteInfoStruct() {}
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
    bool IsEnemy = false;
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
    int Camp = 1; // 1=we, 2=enemy
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
public:
    explicit Model(QObject *parent = nullptr);
    void LoadItems();
    void LoadMap(const QString &mapFilePath);
    void LoadMapBySimplePath(const QString &simplePath);

    inline const QMap<QString, SpriteInfoStruct> &GetMapOfTagToSpriteInfo() {
        return m_mapOfTagToSpriteInfo;
    }
    inline const MapInfoStruct &GetMapInfo() { return m_mapInfo; }
    inline void SetMapInfo(const MapInfoStruct &mapInfo) { m_mapInfo = mapInfo; };
    void OpenMap();
    void SaveMap();
    void SaveMapAs();

private:
    void loadSpriteInfosFromeImgFile(const QString &imgFileRelativePath);
    void loadSpriteInfosFromeCfgFile(const QString &spriteConfigFileRelativePath);
    void saveMapInfoToFile(const QString &filePath);
    QString getMapFilePathByFileDlg();

private:
    QString m_mapFilePath;
    QMap<QString, SpriteInfoStruct> m_mapOfTagToSpriteInfo;
    MapInfoStruct m_mapInfo;
};

#endif // MODEL_H
