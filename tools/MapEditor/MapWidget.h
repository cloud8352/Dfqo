#pragma once

#include "Model.h"

#include <QWidget>
#include <QPaintEvent>
#include <QPainter>
#include <QMenu>

enum ViewTypeEnum {
    Far,
    Near,
    Floor,
    Obj,
    Effect,
    Actor
};

// 最小的的绘制单元
struct DrawingUnitStruct {
    int OX = 0;
    int OY = 0;
    QImage Img;
    QRect Rect;
    // todo: colliders ...
};

struct DrawingAvatarStruct {
    AvatarType Type = Skin;
    float DrawingPriority = 0.0; // 绘制优先级
    QList<DrawingUnitStruct> DrawingUnitList;
};

struct DrawingObjStruct {
    // origin infos
    MapLayerSpriteInfoStruct LayerSpriteInfo;
    MapActorInfoStruct MapActorInfo;
    // drawing infos
    uint Id = 0;
    ViewTypeEnum ViewType = Far;
    int X = 0;
    int Y = 0;
    QRect MainRect; // 主区域，用来代表实例的区域，判断鼠标属否在实例区域中
    QList<DrawingAvatarStruct> DrawingAvatarList;

    bool operator==(const DrawingObjStruct &b)
    {
        return this->Id == b.Id;
    }
    bool operator!=(const DrawingObjStruct &b)
    {
        return !(*this == b);
    }

    void UpdateRects(int mapXOffset, int mapYOffset) {
        MainRect = QRect();
        for (DrawingAvatarStruct &avatar : DrawingAvatarList) {
            for (DrawingUnitStruct &unit : avatar.DrawingUnitList) {
                unit.Rect = QRect(X - unit.OX + mapXOffset, Y - unit.OY + mapYOffset,
                                unit.Img.width(), unit.Img.height());
            }

            // 更新主区域
            if (Skin == avatar.Type) {
                for (DrawingUnitStruct &unit : avatar.DrawingUnitList) {
                    MainRect = MainRect.united(unit.Rect);
                }
            }
        }
    }

    void Draw(QPainter *painter) const {
        for (const DrawingAvatarStruct &avatar : DrawingAvatarList) {
            for (const DrawingUnitStruct &unit : avatar.DrawingUnitList) {
                painter->drawImage(unit.Rect, unit.Img);
            }
        }
    }
};

class MapWidget : public QWidget
{
    Q_OBJECT
public:
    MapWidget(QWidget *parent = nullptr, Model *model = nullptr);
    ~MapWidget();

    void SetViewTypeList(QList<ViewTypeEnum> viewTypeList);
    void SetPlacingViewType(ViewTypeEnum type);
    void SetPlacingSpriteInfo(SpriteInfoStruct info);

Q_SIGNALS:
    void SendMousePosInMap(int x, int y);

protected:
    void mousePressEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void paintEvent(QPaintEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;

private:
    DrawingObjStruct createDrawingObjFromLayerSpriteInfo(const ViewTypeEnum type,
        const MapLayerSpriteInfoStruct &layerSpriteInfo);
    DrawingObjStruct createDrawingObjFromMapActorInfo(const MapActorInfoStruct &actorInfo);
    void loadDrawingObjList(ViewTypeEnum viewType);
    void loadAllDrawingObj();
    void updateRectOfAllDrawingObj();
    void drawDrawingObjList(QPainter &painter, ViewTypeEnum viewType);
    DrawingObjStruct findHoveringDrawingObj(ViewTypeEnum viewType, const QPoint &curserPos);
    void findHoveringDrawingObjInAll(const QPoint &curserPos);
    void addDrawingObj(const QPoint &cursorPos);
    void removeDrawingObj(QList<DrawingObjStruct> drawingObjList);
    uint createId();
    DrawingObjStruct *getDrawingObjById(uint id);
    void updateToDrawingObj(const DrawingObjStruct &drawingObj);
    void setDrawingObjPos(uint id, int x, int y);
    void finishMovingDrawingObj(const QPoint &cursorPos);

private:
    Model *m_model;
    MapInfoStruct m_mapInfo;
    QMap<QString, SpriteInfoStruct> m_mapOfTagToSpriteInfo;
    QMap<QString, FrameAniInfoList> m_mapOfTagToFrameAniInfoList;
    QMap<QString, EquInfoStruct> m_mapOfTagToEquInfo;
    QMap<QString, InstanceInfoStruct> m_mapOfTagToInstanceInfo;
    bool m_isMovingMap;
    QPoint m_originMousePos;
    int m_lastXOffset;
    int m_lastYOffset;
    int m_xOffset;
    int m_yOffset;
    QMap<ViewTypeEnum, QList<DrawingObjStruct>> m_mapOfTypeToDrawingObjList;
    DrawingObjStruct m_lastHoveringDrawingObj;
    DrawingObjStruct m_hoveringDrawingObj;
    QList<ViewTypeEnum> m_viewTypeList;
    ViewTypeEnum m_placingViewType;
    DrawingObjStruct m_placingDrawingObj;
    QMenu *m_menu;
    DrawingObjStruct m_movingDrawingObj;
};
