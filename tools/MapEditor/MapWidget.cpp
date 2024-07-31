#include "MapWidget.h"

#include <QPainter>
#include <QDebug>

MapWidget::MapWidget(QWidget *parent, Model *model)
    : QWidget(parent)
    , m_model(model)
    , m_isMovingMap(false)
    , m_lastXOffset(0)
    , m_lastYOffset(0)
    , m_xOffset(0)
    , m_yOffset(0)
    , m_placingViewType(Floor)
    , m_needShowPlacingDrawingSprite(false)
    , m_menu(nullptr)
{
    // pre data init
    m_viewTypeList = {Far, Near, Floor, Obj, Effect, Actor};

    // ui init
    setMouseTracking(true);
    setFocusPolicy(Qt::ClickFocus);

    m_menu = new QMenu(this);
    QAction *deleteAction = new QAction(this);
    deleteAction->setText("删除");
    m_menu->addAction(deleteAction);

    // connect
    connect(m_menu, &QMenu::triggered, this, [=](QAction *action) {
        if (action == deleteAction) {
            removeDrawingSpriteInfo({m_hoveringDrawingSpriteInfo});
            update();
        }
    });

    // post init
    loadAllLayersDrawingSpriteInfoList();
}

MapWidget::~MapWidget()
{
}

void MapWidget::SetViewTypeList(QList<ViewType> viewTypeList)
{
    m_viewTypeList = viewTypeList;
    update();
}

void MapWidget::SetPlacingViewType(ViewType type)
{
    m_placingViewType = type;
}

void MapWidget::SetPlacingDrawingSpriteVisible(bool visible)
{
    m_needShowPlacingDrawingSprite = visible;
    m_movingDrawingSpriteInfo.Id = 0;
}

void MapWidget::SetPlacingSpriteInfo(SpriteInfoStruct info)
{
    m_placingDrawingSpriteInfo.SpriteInfo = info;
    m_placingDrawingSpriteInfo.Img = QImage(info.ImgPath);
}

void MapWidget::mousePressEvent(QMouseEvent *event)
{
    QWidget::mousePressEvent(event);

    if (event->button() == Qt::MouseButton::RightButton) {
        m_isMovingMap = true;
        m_originMousePos = event->pos();
        m_lastXOffset = m_xOffset;
        m_lastYOffset = m_yOffset;
    }

    if  (event->button() == Qt::MouseButton::LeftButton) {
        // 没有正在放置元素，则开始移动元素
        if (m_needShowPlacingDrawingSprite == false) {
            if (m_movingDrawingSpriteInfo.Id == 0) {
                m_movingDrawingSpriteInfo = m_hoveringDrawingSpriteInfo;
                update();
            } else {
                finishMovingDrawingSprite(event->pos());
                m_movingDrawingSpriteInfo.Id = 0;
                update();
            }
        }
    }

}

void MapWidget::mouseReleaseEvent(QMouseEvent *event)
{
    QWidget::mouseReleaseEvent(event);
    if (event->button() == Qt::MouseButton::RightButton) {
        m_isMovingMap = false;

        if (m_originMousePos == event->pos()) {
            m_menu->move(QCursor::pos());
            m_menu->show();
        }
    }
    if (event->button() == Qt::MouseButton::LeftButton) {
        if (m_needShowPlacingDrawingSprite) {
            addDrawingSpriteInfo(event->pos());
            update();
        }
    }
}

void MapWidget::mouseMoveEvent(QMouseEvent *event)
{
    QWidget::mouseMoveEvent(event);

    if (m_isMovingMap) {
        m_xOffset = m_lastXOffset - m_originMousePos.x() + event->pos().x();
        m_yOffset = m_lastYOffset - m_originMousePos.y() + event->pos().y();

        updateRectOfAllDrawingSprites();

        update();
    } else {
        bool needUpdate = false;
        // 查找 悬停中的元素
        findHoveringDrawingSpriteInfoInAllSprites(event->pos());
        if (m_lastHoveringDrawingSpriteInfo != m_hoveringDrawingSpriteInfo) {
            needUpdate = true;
        }
        m_lastHoveringDrawingSpriteInfo = m_hoveringDrawingSpriteInfo;

        // 当存在待放置的元素时，需要更新画面
        if (m_needShowPlacingDrawingSprite) {
            needUpdate = true;
        }

        // 当存在待移动的元素时，需要更新画面
        if (m_movingDrawingSpriteInfo.Id != 0) {
            needUpdate = true;
        }

        // 是否需要更新画面
        if (needUpdate) {
            update();
        }
        // 发送鼠标处于地图中的坐标
        Q_EMIT SendMousePosInMap(event->pos().x() - m_xOffset, event->pos().y() - m_yOffset);
    }
}

void MapWidget::paintEvent(QPaintEvent *event)
{
    QWidget::paintEvent(event);

    QPainter painter(this);
    painter.setRenderHint(QPainter::RenderHint::Antialiasing, true);

    if (m_viewTypeList.contains(Far)) {
        drawDrawingSpriteInfoList(painter, Far);
    }
    if (m_viewTypeList.contains(Near)) {
        drawDrawingSpriteInfoList(painter, Near);
    }
    if (m_viewTypeList.contains(Floor)) {
        drawDrawingSpriteInfoList(painter, Floor);
    }
    if (m_viewTypeList.contains(Obj)) {
        drawDrawingSpriteInfoList(painter, Obj);
    }
    if (m_viewTypeList.contains(Effect)) {
        drawDrawingSpriteInfoList(painter, Effect);
    }
    if (m_viewTypeList.contains(Actor)) {
        drawDrawingSpriteInfoList(painter, Actor);
    }

    // hovering DrawingSprite
    if (m_hoveringDrawingSpriteInfo.Id != 0) {
        painter.save();
        QPen pen(QColor(0, 200, 30));
        pen.setWidth(2);
        painter.setPen(pen);
        painter.drawRect(m_hoveringDrawingSpriteInfo.Rect);

        painter.restore();
    }

    // 画 待放置的元素
    if (m_needShowPlacingDrawingSprite) {
        const SpriteInfoStruct &spriteInfo = m_placingDrawingSpriteInfo.SpriteInfo;
        const QImage &img = m_placingDrawingSpriteInfo.Img;

        const QPoint &cursorPos = mapFromGlobal(QCursor::pos());
        QRect rect(cursorPos.x() - spriteInfo.OX,
                   cursorPos.y() - spriteInfo.OY, img.width(), img.height());

        painter.drawImage(rect, img);
    }

    // 画 待移动的元素
    if (m_movingDrawingSpriteInfo.Id != 0) {
        const SpriteInfoStruct &spriteInfo = m_movingDrawingSpriteInfo.SpriteInfo;
        const QImage &img = m_movingDrawingSpriteInfo.Img;

        const QPoint &cursorPos = mapFromGlobal(QCursor::pos());
        QRect rect(cursorPos.x() - spriteInfo.OX,
                   cursorPos.y() - spriteInfo.OY, img.width(), img.height());

        painter.drawImage(rect, img);
    }

    // frame
    painter.save();
    QPen pen(QColor(100, 100, 100));
    pen.setWidth(1);
    painter.setPen(pen);
    painter.drawRect(event->rect());
    painter.restore();
}

void MapWidget::keyPressEvent(QKeyEvent *event)
{
    QWidget::keyPressEvent(event);

    if (event->key() == Qt::Key_Escape) {
        m_movingDrawingSpriteInfo.Id = 0;
        update();
    }

    if (event->key() == Qt::Key_Up) {
        uint id = m_movingDrawingSpriteInfo.Id;
        DrawingSpriteInfoStruct *info = getDrawingSpriteInfoById(id);
        if (info) {
            int x = info->LayerSpriteInfo.X;
            int y = info->LayerSpriteInfo.Y - 1;
            updateDrawingSpritePosToMap(id, x, y);
            update();
        }
    }
    if (event->key() == Qt::Key_Down) {
        uint id = m_movingDrawingSpriteInfo.Id;
        DrawingSpriteInfoStruct *info = getDrawingSpriteInfoById(id);
        if (info) {
            int x = info->LayerSpriteInfo.X;
            int y = info->LayerSpriteInfo.Y + 1;
            updateDrawingSpritePosToMap(id, x, y);
            update();
        }
    }
    if (event->key() == Qt::Key_Left) {
        uint id = m_movingDrawingSpriteInfo.Id;
        DrawingSpriteInfoStruct *info = getDrawingSpriteInfoById(id);
        if (info) {
            int x = info->LayerSpriteInfo.X - 1;
            int y = info->LayerSpriteInfo.Y;
            updateDrawingSpritePosToMap(id, x, y);
            update();
        }
    }
    if (event->key() == Qt::Key_Right) {
        uint id = m_movingDrawingSpriteInfo.Id;
        DrawingSpriteInfoStruct *info = getDrawingSpriteInfoById(id);
        if (info) {
            int x = info->LayerSpriteInfo.X + 1;
            int y = info->LayerSpriteInfo.Y;
            updateDrawingSpritePosToMap(id, x, y);
            update();
        }
    }
}

void MapWidget::loadDrawingSpriteInfoList(ViewType viewType)
{
    const MapInfoStruct &mapInfo = m_model->GetMapInfo();
    const QMap<QString, SpriteInfoStruct> &mapOfTagToSpriteInfo = m_model->GetMapOfTagToSpriteInfo();

    QList<MapLayerSpriteInfoStruct> layerSpriteInfoList;
    switch (viewType) {
    case Far:
        layerSpriteInfoList = mapInfo.LayerInfo.FarLayerSpriteInfoList;
        break;
    case Near:
        layerSpriteInfoList = mapInfo.LayerInfo.NearLayerSpriteInfoList;
        break;
    case Floor:
        layerSpriteInfoList = mapInfo.LayerInfo.FloorLayerSpriteInfoList;
        break;
    case Obj:
        layerSpriteInfoList = mapInfo.LayerInfo.ObjLayerSpriteInfoList;
        break;
    case Effect:
        layerSpriteInfoList = mapInfo.LayerInfo.EffectLayerSpriteInfoList;
        break;
    case Actor:
        break;
    default:
        break;
    }

    QList<DrawingSpriteInfoStruct> &drawingSpriteInfoList = m_mapOfViewTypeToDrawingSpriteInfoList[viewType];
    drawingSpriteInfoList.clear();
    for (const MapLayerSpriteInfoStruct &layerSpriteInfo : layerSpriteInfoList) {
        const SpriteInfoStruct &spriteInfo = mapOfTagToSpriteInfo.value(layerSpriteInfo.SpriteTag);
        QImage img(spriteInfo.ImgPath);

        DrawingSpriteInfoStruct drawingSpriteInfo;
        drawingSpriteInfo.SpriteInfo = spriteInfo;
        drawingSpriteInfo.LayerSpriteInfo = layerSpriteInfo;
        drawingSpriteInfo.Img = img;
        drawingSpriteInfo.Id = creatNewId();

        drawingSpriteInfoList.append(drawingSpriteInfo);
    }
}

void MapWidget::loadAllLayersDrawingSpriteInfoList()
{
    loadDrawingSpriteInfoList(Far);
    loadDrawingSpriteInfoList(Near);
    loadDrawingSpriteInfoList(Floor);
    loadDrawingSpriteInfoList(Obj);
    loadDrawingSpriteInfoList(Effect);

    updateRectOfAllDrawingSprites();
}

void MapWidget::updateRectOfDrawingSprite(DrawingSpriteInfoStruct &drawingSpriteInfo)
{
    const SpriteInfoStruct &spriteInfo = drawingSpriteInfo.SpriteInfo;
    const MapLayerSpriteInfoStruct &layerSpriteInfo = drawingSpriteInfo.LayerSpriteInfo;
    const QImage &img = drawingSpriteInfo.Img;
    drawingSpriteInfo.Rect = QRect(layerSpriteInfo.X - spriteInfo.OX + m_xOffset,
                                   layerSpriteInfo.Y - spriteInfo.OY + m_yOffset, img.width(), img.height());
}

void MapWidget::updateRectOfAllDrawingSprites()
{
    QMap<ViewType, QList<DrawingSpriteInfoStruct>>::Iterator iter =
        m_mapOfViewTypeToDrawingSpriteInfoList.begin();
    for (; iter != m_mapOfViewTypeToDrawingSpriteInfoList.end(); iter++) {
        QList<DrawingSpriteInfoStruct> &drawingSpriteInfoList = *iter;
        for (DrawingSpriteInfoStruct &drawingSpriteInfo : drawingSpriteInfoList) {
            updateRectOfDrawingSprite(drawingSpriteInfo);
        }
    }

    updateRectOfDrawingSprite(m_hoveringDrawingSpriteInfo);
}

void MapWidget::drawDrawingSpriteInfoList(QPainter &painter, ViewType viewType)
{
    QList<DrawingSpriteInfoStruct> &drawingSpriteInfoList = m_mapOfViewTypeToDrawingSpriteInfoList[viewType];
    for (const DrawingSpriteInfoStruct &drawingSpriteInfo : drawingSpriteInfoList) {
        if (drawingSpriteInfo.Id == m_movingDrawingSpriteInfo.Id) {
            painter.save();
            painter.setOpacity(0.7);
            painter.drawImage(drawingSpriteInfo.Rect, drawingSpriteInfo.Img);
            QColor color(50, 100, 255, 130);
            painter.fillRect(drawingSpriteInfo.Rect, color);

            painter.restore();
            continue;
        }
        painter.drawImage(drawingSpriteInfo.Rect, drawingSpriteInfo.Img);
    }
}

DrawingSpriteInfoStruct MapWidget::findHoveringDrawingSpriteInfo(ViewType viewType, const QPoint &curserPos)
{
    QList<DrawingSpriteInfoStruct> &drawingSpriteInfoList = m_mapOfViewTypeToDrawingSpriteInfoList[viewType];
    QList<DrawingSpriteInfoStruct>::reverse_iterator rIter = drawingSpriteInfoList.rbegin();
    for (; rIter != drawingSpriteInfoList.rend(); rIter++) {
        if (rIter->Rect.contains(curserPos)) {
            return *rIter;
        }
    }

    return DrawingSpriteInfoStruct();
}

void MapWidget::findHoveringDrawingSpriteInfoInAllSprites(const QPoint &curserPos)
{
    DrawingSpriteInfoStruct drawingSpriteInfo;

    if (m_viewTypeList.contains(Actor)) {
        drawingSpriteInfo = findHoveringDrawingSpriteInfo(Actor, curserPos);
    }
    if (drawingSpriteInfo.Id != 0) {
        m_hoveringDrawingSpriteInfo = drawingSpriteInfo;
        return;
    }

    if (m_viewTypeList.contains(Effect)) {
        drawingSpriteInfo = findHoveringDrawingSpriteInfo(Effect, curserPos);
    }
    if (drawingSpriteInfo.Id != 0) {
        m_hoveringDrawingSpriteInfo = drawingSpriteInfo;
        return;
    }

    if (m_viewTypeList.contains(Obj)) {
        drawingSpriteInfo = findHoveringDrawingSpriteInfo(Obj, curserPos);
    }
    if (drawingSpriteInfo.Id != 0) {
        m_hoveringDrawingSpriteInfo = drawingSpriteInfo;
        return;
    }

    if (m_viewTypeList.contains(Floor)) {
        drawingSpriteInfo = findHoveringDrawingSpriteInfo(Floor, curserPos);
    }
    if (drawingSpriteInfo.Id != 0) {
        m_hoveringDrawingSpriteInfo = drawingSpriteInfo;
        return;
    }

    if (m_viewTypeList.contains(Near)) {
        drawingSpriteInfo = findHoveringDrawingSpriteInfo(Near, curserPos);
    }
    if (drawingSpriteInfo.Id != 0) {
        m_hoveringDrawingSpriteInfo = drawingSpriteInfo;
        return;
    }

    if (m_viewTypeList.contains(Far)) {
        drawingSpriteInfo = findHoveringDrawingSpriteInfo(Far, curserPos);
    }
    if (drawingSpriteInfo.Id != 0) {
        m_hoveringDrawingSpriteInfo = drawingSpriteInfo;
        return;
    }

    m_hoveringDrawingSpriteInfo = DrawingSpriteInfoStruct();
}

void MapWidget::addDrawingSpriteInfo(const QPoint &cursorPos)
{
    QList<DrawingSpriteInfoStruct> &drawingSpriteInfoList =
        m_mapOfViewTypeToDrawingSpriteInfoList[m_placingViewType];

    m_placingDrawingSpriteInfo.Id = creatNewId();

    MapLayerSpriteInfoStruct &layerSpriteInfo = m_placingDrawingSpriteInfo.LayerSpriteInfo;
    layerSpriteInfo.SpriteTag = m_placingDrawingSpriteInfo.SpriteInfo.Tag;
    layerSpriteInfo.X = cursorPos.x() - m_xOffset;
    layerSpriteInfo.Y = cursorPos.y() - m_yOffset;

    updateRectOfDrawingSprite(m_placingDrawingSpriteInfo);

    drawingSpriteInfoList.append(m_placingDrawingSpriteInfo);
}

void MapWidget::removeDrawingSpriteInfo(QList<DrawingSpriteInfoStruct> drawingSpriteInfoList)
{
    QMap<ViewType, QList<DrawingSpriteInfoStruct>>::Iterator iter =
        m_mapOfViewTypeToDrawingSpriteInfoList.begin();
    for (; iter != m_mapOfViewTypeToDrawingSpriteInfoList.end(); iter++) {
        QList<DrawingSpriteInfoStruct> &drawingSpriteInfoListTmp = *iter;

        for (const DrawingSpriteInfoStruct &drawingSpriteInfo : drawingSpriteInfoList) {
            drawingSpriteInfoListTmp.removeAll(drawingSpriteInfo);
        }
    }
}

uint MapWidget::creatNewId()
{
    uint id = 1;
    while(1) {
        bool existSameId = false;
        QMap<ViewType, QList<DrawingSpriteInfoStruct>>::Iterator iter =
            m_mapOfViewTypeToDrawingSpriteInfoList.begin();
        for (; iter != m_mapOfViewTypeToDrawingSpriteInfoList.end(); iter++) {
            QList<DrawingSpriteInfoStruct> &drawingSpriteInfoList = *iter;

            for (const DrawingSpriteInfoStruct &drawingSpriteInfo : drawingSpriteInfoList) {
                // drawingSpriteInfoListTmp.removeAll(drawingSpriteInfo);
                if (id == drawingSpriteInfo.Id) {
                    existSameId = true;
                    break;
                }
            }

            if (existSameId) {
                break;
            }
        }

        if (!existSameId) {
            break;
        }

        id++;
    }

    return id;
}

DrawingSpriteInfoStruct *MapWidget::getDrawingSpriteInfoById(uint id)
{
    QMap<ViewType, QList<DrawingSpriteInfoStruct>>::Iterator iter =
        m_mapOfViewTypeToDrawingSpriteInfoList.begin();
    for (; iter != m_mapOfViewTypeToDrawingSpriteInfoList.end(); iter++) {
        QList<DrawingSpriteInfoStruct> &drawingSpriteInfoList = *iter;
        for (DrawingSpriteInfoStruct &drawingSpriteInfoTmp : drawingSpriteInfoList) {
            if (id == drawingSpriteInfoTmp.Id) {
                return &drawingSpriteInfoTmp;
            }
        }
    }

    return nullptr;
}

void MapWidget::updateDrawingSpriteInfoToMap(const DrawingSpriteInfoStruct &drawingSpriteInfo)
{
    DrawingSpriteInfoStruct *info = getDrawingSpriteInfoById(drawingSpriteInfo.Id);
    if (!info) {
        return;
    }

    // 更新数据
    *info = drawingSpriteInfo;
}

void MapWidget::updateDrawingSpritePosToMap(uint id, int x, int y)
{
    DrawingSpriteInfoStruct *info = getDrawingSpriteInfoById(id);
    if (!info) {
        return;
    }

    info->LayerSpriteInfo.X = x;
    info->LayerSpriteInfo.Y = y;
    updateRectOfDrawingSprite(*info);
}

void MapWidget::finishMovingDrawingSprite(const QPoint &cursorPos)
{
    updateDrawingSpritePosToMap(m_movingDrawingSpriteInfo.Id, cursorPos.x() - m_xOffset,
                                cursorPos.y() - m_yOffset);
}

