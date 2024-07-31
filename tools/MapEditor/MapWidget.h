#pragma once

#include "Model.h"

#include <QWidget>
#include <QPaintEvent>
#include <QMenu>

enum ViewType {
    Far,
    Near,
    Floor,
    Obj,
    Effect,
    Actor
};

struct DrawingSpriteInfoStruct {
    SpriteInfoStruct SpriteInfo;
    MapLayerSpriteInfoStruct LayerSpriteInfo;
    uint Id = 0;
    QImage Img;
    QRect Rect;
    bool operator==(const DrawingSpriteInfoStruct &b)
    {
        return this->Id == b.Id;
    }
    bool operator!=(const DrawingSpriteInfoStruct &b)
    {
        return this->Id != b.Id;
    }
};

class MapWidget : public QWidget
{
    Q_OBJECT
public:
    MapWidget(QWidget *parent = nullptr, Model *model = nullptr);
    ~MapWidget();

    void SetViewTypeList(QList<ViewType> viewTypeList);
    void SetPlacingViewType(ViewType type);
    void SetPlacingDrawingSpriteVisible(bool visible);
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
    void loadDrawingSpriteInfoList(ViewType viewType);
    void loadAllLayersDrawingSpriteInfoList();
    void updateRectOfDrawingSprite(DrawingSpriteInfoStruct &drawingSpriteInfo);
    void updateRectOfAllDrawingSprites();
    void drawDrawingSpriteInfoList(QPainter &painter, ViewType viewType);
    DrawingSpriteInfoStruct findHoveringDrawingSpriteInfo(ViewType viewType, const QPoint &curserPos);
    void findHoveringDrawingSpriteInfoInAllSprites(const QPoint &curserPos);
    void addDrawingSpriteInfo(const QPoint &cursorPos);
    void removeDrawingSpriteInfo(QList<DrawingSpriteInfoStruct> drawingSpriteInfoList);
    uint creatNewId();
    DrawingSpriteInfoStruct *getDrawingSpriteInfoById(uint id);
    void updateDrawingSpriteInfoToMap(const DrawingSpriteInfoStruct &drawingSpriteInfo);
    void updateDrawingSpritePosToMap(uint id, int x, int y);
    void finishMovingDrawingSprite(const QPoint &cursorPos);

private:
    Model *m_model;
    bool m_isMovingMap;
    QPoint m_originMousePos;
    int m_lastXOffset;
    int m_lastYOffset;
    int m_xOffset;
    int m_yOffset;
    QMap<ViewType, QList<DrawingSpriteInfoStruct>> m_mapOfViewTypeToDrawingSpriteInfoList;
    DrawingSpriteInfoStruct m_lastHoveringDrawingSpriteInfo;
    DrawingSpriteInfoStruct m_hoveringDrawingSpriteInfo;
    QList<ViewType> m_viewTypeList;
    ViewType m_placingViewType;
    bool m_needShowPlacingDrawingSprite;
    DrawingSpriteInfoStruct m_placingDrawingSpriteInfo;
    QMenu *m_menu;
    DrawingSpriteInfoStruct m_movingDrawingSpriteInfo;
};
