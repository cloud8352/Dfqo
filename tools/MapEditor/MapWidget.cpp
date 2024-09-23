#include "MapWidget.h"

#include <QPainter>
#include <QDebug>

// 精灵图片指针 资源池
static QMap<QString, QImage*> SpriteImgPtrPool;

void adjustImgByColor(QImage &image, const ColorInfoStruct &color) {
    float rPercent = float(color.R) / 255;
    float gPercent = float(color.G) / 255;
    float bPercent = float(color.B) / 255;
    float aPercent = float(color.A) / 255;
    for (int y = 0; y < image.height(); ++y) {
        for (int x = 0; x < image.width(); ++x) {
            QRgb color = image.pixel(x, y);
            // 调整颜色分量
            int red = qRed(color) * rPercent;
            int green = qGreen(color) * gPercent;
            int blue = qBlue(color) * bPercent;
            int alpha = qAlpha(color) * aPercent;

            // 重新合成颜色
            color = qRgba(red, green, blue, alpha);

            // 设置新的像素值
            image.setPixel(x, y, color);
        }
    }
}

MapWidget::MapWidget(QWidget *parent, Model *model)
    : QWidget(parent)
    , m_model(model)
    , m_currentMaxId(0)
    , m_isMovingMap(false)
    , m_lastXOffset(0)
    , m_lastYOffset(0)
    , m_xOffset(0)
    , m_yOffset(0)
    , m_placingViewType(Floor)
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

    m_mapSettingsDlg.setVisible(false);

    // connect
    connect(m_model, &Model::MapLoaded, this, &MapWidget::Reload);
    connect(m_menu, &QMenu::triggered, this, [=](QAction *action) {
        if (action == deleteAction) {
            removeDrawingObj({m_hoveringDrawingObj});
            update();
        }
    });

    // map settings dlg
    connect(&m_mapSettingsDlg, &MapSettingsDlg::MapBaseInfoChanged, this, [=](const MapBaseInfoStruct &info) {
        m_mapInfo.BaseInfo = info;
    });
    connect(&m_mapSettingsDlg, &MapSettingsDlg::MapScopeInfoChanged, this, [=](const MapScopeInfoStruct &info) {
        m_mapInfo.ScopeInfo = info;
    });
}

MapWidget::~MapWidget()
{
}

void MapWidget::SetViewTypeList(QList<ViewTypeEnum> viewTypeList)
{
    m_viewTypeList = viewTypeList;
    update();
}

void MapWidget::SetPlacingViewType(ViewTypeEnum type)
{
    m_placingViewType = type;
}

void MapWidget::SetPlacingSpriteInfoTag(const QString &tag)
{
    if (tag.isEmpty()) {
        m_placingDrawingObj.Id = 0;
        m_movingDrawingObj.Id = 0;
        return;
    }

    MapLayerSpriteInfoStruct layerInfo;
    layerInfo.SpriteTag = tag;
    m_placingDrawingObj = createDrawingObjFromLayerSpriteInfo(m_placingViewType, layerInfo);
}

void MapWidget::SetPlacingInstanceInfoTag(const QString &tag)
{
    if (tag.isEmpty()) {
        m_placingDrawingObj.Id = 0;
        m_movingDrawingObj.Id = 0;
        return;
    }

    MapActorInfoStruct actorInfo;
    actorInfo.Path = tag;
    m_placingDrawingObj = createDrawingObjFromMapActorInfo(actorInfo);
}

void MapWidget::OpenMapSettingsDlg()
{
    if (m_mapSettingsDlg.isVisible()) {
        return;
    }

    m_mapSettingsDlg.SetMapBaseInfo(m_mapInfo.BaseInfo);
    m_mapSettingsDlg.SetMapScopeInfo(m_mapInfo.ScopeInfo);
    m_mapSettingsDlg.show();
}

void MapWidget::SaveMap()
{
    const MapInfoStruct &mapInfo = toMapInfo();
    m_model->SaveMap(mapInfo);
}

void MapWidget::Reload()
{
    m_isMovingMap = false;
    m_lastXOffset = 0;
    m_lastYOffset = 0;
    m_xOffset = 0;
    m_yOffset = 0;
    m_lastHoveringDrawingObj.Id = 0;
    m_hoveringDrawingObj.Id = 0;
    m_viewTypeList = {Far, Near, Floor, Obj, Effect, Actor};
    m_placingViewType = Floor;
    m_placingDrawingObj.Id = 0;

    loadAllDrawingObj();

    update();
}

void MapWidget::NewMap()
{
    m_model->NewMap();

    Reload();
}

void MapWidget::SaveMapAs()
{
    const MapInfoStruct &mapInfo = toMapInfo();
    m_model->SaveMapAs(mapInfo);
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
        if (m_placingDrawingObj.Id == 0) {
            if (m_movingDrawingObj.Id == 0) {
                m_movingDrawingObj = m_hoveringDrawingObj;
                m_movingDrawingObj.X = event->pos().x();
                m_movingDrawingObj.Y = event->pos().y();
                m_movingDrawingObj.UpdateRects(0, 0);
                update();
            } else {
                finishMovingDrawingObj(event->pos());
                m_movingDrawingObj.Id = 0;
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
        if (m_placingDrawingObj.Id) {
            addDrawingObj(event->pos());
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

        updateRectOfAllDrawingObj();

        update();
    } else {
        bool needUpdate = false;
        // 查找 悬停中的元素
        findHoveringDrawingObjInAll(event->pos());
        if (m_lastHoveringDrawingObj != m_hoveringDrawingObj) {
            needUpdate = true;
        }
        m_lastHoveringDrawingObj = m_hoveringDrawingObj;

        // 当存在待放置的元素时，需要更新画面
        if (m_placingDrawingObj.Id) {
            m_placingDrawingObj.X = event->pos().x();
            m_placingDrawingObj.Y = event->pos().y();
            m_placingDrawingObj.UpdateRects(0, 0);
            needUpdate = true;
        }

        // 当存在待移动的元素时，需要更新画面
        if (m_movingDrawingObj.Id != 0) {
            m_movingDrawingObj.X = event->pos().x();
            m_movingDrawingObj.Y = event->pos().y();
            m_movingDrawingObj.UpdateRects(0, 0);
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
    painter.setRenderHint(QPainter::RenderHint::SmoothPixmapTransform, true);

    if (m_viewTypeList.contains(Far)) {
        drawDrawingObjList(painter, Far);
    }
    if (m_viewTypeList.contains(Near)) {
        drawDrawingObjList(painter, Near);
    }
    if (m_viewTypeList.contains(Floor)) {
        drawDrawingObjList(painter, Floor);
    }
    if (m_viewTypeList.contains(Obj)) {
        drawDrawingObjList(painter, Obj);
    }
    if (m_viewTypeList.contains(Effect)) {
        drawDrawingObjList(painter, Effect);
    }
    if (m_viewTypeList.contains(Actor)) {
        // drawdDrawingInstanceInfoList(painter);
        drawDrawingObjList(painter, Actor);
    }

    // hovering DrawingSprite
    if (m_hoveringDrawingObj.Id != 0) {
        painter.save();
        QPen pen(QColor(0, 200, 30));
        pen.setWidth(2);
        painter.setPen(pen);
        painter.drawRect(m_hoveringDrawingObj.MainRect);

        painter.restore();
    }

    // 画 待放置的元素
    if (m_placingDrawingObj.Id) {
        m_placingDrawingObj.Draw(&painter);
    }

    // 画 待移动的元素
    if (m_movingDrawingObj.Id > 0 && m_placingDrawingObj.Id == 0) {
        m_movingDrawingObj.Draw(&painter);
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
        m_movingDrawingObj.Id = 0;
        update();
    }

    if (event->key() == Qt::Key_Up) {
        uint id = m_movingDrawingObj.Id;
        DrawingObjStruct *obj = getDrawingObjById(id);
        if (obj) {
            int x = obj->LayerSpriteInfo.X;
            int y = obj->LayerSpriteInfo.Y - 1;
            setDrawingObjPos(id, x, y);
            update();
        }
    }
    if (event->key() == Qt::Key_Down) {
        uint id = m_movingDrawingObj.Id;
        DrawingObjStruct *obj = getDrawingObjById(id);
        if (obj) {
            int x = obj->LayerSpriteInfo.X;
            int y = obj->LayerSpriteInfo.Y + 1;
            setDrawingObjPos(id, x, y);
            update();
        }
    }
    if (event->key() == Qt::Key_Left) {
        uint id = m_movingDrawingObj.Id;
        DrawingObjStruct *obj = getDrawingObjById(id);
        if (obj) {
            int x = obj->LayerSpriteInfo.X - 1;
            int y = obj->LayerSpriteInfo.Y;
            setDrawingObjPos(id, x, y);
            update();
        }
    }
    if (event->key() == Qt::Key_Right) {
        uint id = m_movingDrawingObj.Id;
        DrawingObjStruct *obj = getDrawingObjById(id);
        if (obj) {
            int x = obj->LayerSpriteInfo.X + 1;
            int y = obj->LayerSpriteInfo.Y;
            setDrawingObjPos(id, x, y);
            update();
        }
    }
}

DrawingObjStruct MapWidget::createDrawingObjFromLayerSpriteInfo(const ViewTypeEnum type,
    const MapLayerSpriteInfoStruct &layerSpriteInfo)
{
    DrawingObjStruct drawingObj;
    drawingObj.LayerSpriteInfo = layerSpriteInfo;

    drawingObj.Id = createId();
    drawingObj.ViewType = type;
    drawingObj.X = layerSpriteInfo.X;
    drawingObj.Y = layerSpriteInfo.Y;

    // load drawing unit
    const QString &tag = layerSpriteInfo.SpriteTag;
    DrawingUnitStruct drawingUnit;

    if (!m_mapOfTagToSpriteInfo.contains(tag)) {
        return drawingObj;
    }
    const SpriteInfoStruct &spriteInfo = m_mapOfTagToSpriteInfo.value(tag);
    drawingUnit.OX = spriteInfo.OX;
    drawingUnit.OY = spriteInfo.OY;
    if (SpriteImgPtrPool.contains(tag)) {
        drawingUnit.Img = SpriteImgPtrPool.value(tag);
    } else {
        QImage *img = new QImage(spriteInfo.ImgPath);
        adjustImgByColor(*img, spriteInfo.ColorInfo);
        drawingUnit.Img = img;

        SpriteImgPtrPool.insert(tag, img);
    }

    // load drawing avatar
    DrawingAvatarStruct drawingAvatar;
    drawingAvatar.Type = Skin;
    // append drawing unit
    drawingAvatar.DrawingUnitList.append(drawingUnit);
    // append drawing avatar
    drawingObj.DrawingAvatarList.append(drawingAvatar);

    return drawingObj;
}

DrawingObjStruct MapWidget::createDrawingObjFromMapActorInfo(const MapActorInfoStruct &actorInfo)
{
    DrawingObjStruct drawingObj;
    drawingObj.ViewType = Actor;
    drawingObj.Id = createId();
    drawingObj.MapActorInfo = actorInfo;
    drawingObj.X = actorInfo.X;
    drawingObj.Y = actorInfo.Y;

    auto appendDrawingAvatar = [this, &drawingObj, &actorInfo]
        (AvatarType type, const QStringList &spriteTagList) {
        DrawingAvatarStruct drawingAvatar;
        for (const QString &spriteTag : spriteTagList) {
            // load drawing unit
            DrawingUnitStruct drawingUnit;
            const SpriteInfoStruct &spriteInfo = m_mapOfTagToSpriteInfo.value(spriteTag);
            drawingUnit.OX = spriteInfo.OX;
            drawingUnit.OY = spriteInfo.OY;
            QImage *img = new QImage(spriteInfo.ImgPath);
            adjustImgByColor(*img, spriteInfo.ColorInfo);
            if (actorInfo.Direction == -1) {
                *img = img->mirrored(true, false);
                drawingUnit.OX = img->width() - drawingUnit.OX;
            }
            drawingUnit.Img = img;

            // load drawing avatar
            drawingAvatar.Type = type;
            // append drawing unit
            drawingAvatar.DrawingUnitList.append(drawingUnit);
        }
        // append drawing avatar
        drawingObj.DrawingAvatarList.append(drawingAvatar);
    };

    if (!m_mapOfTagToInstanceInfo.contains(actorInfo.Path)) {
        return drawingObj;
    }
    const InstanceInfoStruct &instanceInfo = m_mapOfTagToInstanceInfo.value(actorInfo.Path);
    if (instanceInfo.AspectInfo.Type == "sprite") {
        const QString &spriteTag = "actor/" + instanceInfo.AspectInfo.Path;
        appendDrawingAvatar(Skin, {spriteTag});
    }
    if (instanceInfo.AspectInfo.Type == "frameani") {
        QString frameAniTag;
        if (instanceInfo.AspectInfo.Path.isEmpty()) {
            frameAniTag = "actor/" + instanceInfo.AspectInfo.Avatar + "/stay";
        } else {
            frameAniTag = "actor/" + instanceInfo.AspectInfo.Path;
        }
        const FrameAniInfoList &frameAniInfoList =
            m_mapOfTagToFrameAniInfoList.value(frameAniTag);
        if (frameAniInfoList.isEmpty()) {
            return drawingObj;
        }
        const FrameAniInfoStruct &frameAniInfo = frameAniInfoList.first();

        // 如果不存在装扮，则直接添加到显示列表
        if (instanceInfo.AspectInfo.Avatar.isEmpty()) {
            appendDrawingAvatar(Skin, {frameAniInfo.Sprite});
        } else {
            // 如果存在装扮
            // function
            auto getSimplePathAndAppendDrawingAvatar = [&](AvatarType type) {
                const QString &spriteSimplePath = instanceInfo.AspectInfo.MapOfAvatarTypeToSimplePath.value(type);
                if (spriteSimplePath.isEmpty()) {
                    return;
                }
                const QString &spriteTag = "actor/" + instanceInfo.AspectInfo.Avatar + "/" + spriteSimplePath + "/" + frameAniInfo.Sprite;
                appendDrawingAvatar(type, {spriteTag});
            };

            // skin avatar
            getSimplePathAndAppendDrawingAvatar(Skin);

            // hat
            getSimplePathAndAppendDrawingAvatar(Hat);

            // weapon
            getSimplePathAndAppendDrawingAvatar(Weapon);

            // equ ...
            const QMap<AvatarType, QString> &mapOfAvatarTypeToEquTag = instanceInfo.MapOfAvatarTypeToEquTag;
            for (QMap<AvatarType, QString>::const_iterator cIter = mapOfAvatarTypeToEquTag.cbegin();
                 cIter != mapOfAvatarTypeToEquTag.cend(); cIter++) {
                const QString &equTag =  cIter.value();
                const EquInfoStruct &equInfo = m_mapOfTagToEquInfo.value(equTag);
                const QMap<AvatarType, QString> &mapOfAvatarTypeToSimplePath = equInfo.MapOfAvatarTypeToSimplePath;
                for (QMap<AvatarType, QString>::const_iterator cIter2 = mapOfAvatarTypeToSimplePath.cbegin();
                     cIter2 != mapOfAvatarTypeToSimplePath.cend(); cIter2++) {

                    const QString &spriteSimplePath = cIter2.value();
                    if (spriteSimplePath.isEmpty()) {
                        continue;
                    }
                    const QString &spriteTag = "actor/" + instanceInfo.AspectInfo.Avatar + "/" + spriteSimplePath + "/" + frameAniInfo.Sprite;
                    appendDrawingAvatar(cIter2.key(), {spriteTag});
                }
            }

        }
    }

    //// aspect layer
    if (instanceInfo.AspectInfo.LayerInfo.Type == "sprite") {
        const QString &spriteTag = "actor/" + instanceInfo.AspectInfo.LayerInfo.Path;
        appendDrawingAvatar(Skin, {spriteTag});
    }
    if (instanceInfo.AspectInfo.LayerInfo.Type == "frameani") {

        QString frameAniTag = "actor/" + instanceInfo.AspectInfo.LayerInfo.Path;
        const FrameAniInfoList &frameAniInfoList =
            m_mapOfTagToFrameAniInfoList.value(frameAniTag);
        if (frameAniInfoList.isEmpty()) {
            return drawingObj;
        }
        const FrameAniInfoStruct &frameAniInfo = frameAniInfoList.first();
        const QString &spriteTag = frameAniInfo.Sprite;

        appendDrawingAvatar(Skin, {spriteTag});
    }
    if (!instanceInfo.AspectInfo.LayerInfoList.isEmpty()) {
        QStringList spriteTagList;
        for (const AspectLayerInfoStruct &layerInfo : instanceInfo.AspectInfo.LayerInfoList) {
            QString spriteTag;
            if (layerInfo.Type == "sprite") {
                spriteTag = "actor/" + layerInfo.Path;
            } else if (layerInfo.Type == "frameani") {
                QString frameAniTag = "actor/" + layerInfo.Path;
                const FrameAniInfoList &frameAniInfoList =
                    m_mapOfTagToFrameAniInfoList.value(frameAniTag);
                if (frameAniInfoList.isEmpty()) {
                    continue;
                }
                const FrameAniInfoStruct &frameAniInfo = frameAniInfoList.first();
                spriteTag = frameAniInfo.Sprite;
            } else {
                continue;
            }

            spriteTagList.append(spriteTag);
        }

        appendDrawingAvatar(Skin, spriteTagList);
    }

    return drawingObj;
}

void MapWidget::loadDrawingObjList(ViewTypeEnum viewType)
{
    QList<MapLayerSpriteInfoStruct> layerSpriteInfoList;
    switch (viewType) {
    case Far:
        layerSpriteInfoList = m_mapInfo.LayerInfo.FarLayerSpriteInfoList;
        break;
    case Near:
        layerSpriteInfoList = m_mapInfo.LayerInfo.NearLayerSpriteInfoList;
        break;
    case Floor:
        layerSpriteInfoList = m_mapInfo.LayerInfo.FloorLayerSpriteInfoList;
        break;
    case Obj:
        layerSpriteInfoList = m_mapInfo.LayerInfo.ObjLayerSpriteInfoList;
        break;
    case Effect:
        layerSpriteInfoList = m_mapInfo.LayerInfo.EffectLayerSpriteInfoList;
        break;
    case Actor:
        break;
    default:
        break;
    }

    QList<DrawingObjStruct> &drawingObjList = m_mapOfTypeToDrawingObjList[viewType];
    drawingObjList.clear();
    for (const MapLayerSpriteInfoStruct &layerSpriteInfo : layerSpriteInfoList) {
        DrawingObjStruct drawingObj = createDrawingObjFromLayerSpriteInfo(viewType, layerSpriteInfo);

        // append drawing obj
        drawingObjList.append(drawingObj);
    }

    if (viewType != Actor) {
        return;
    }

    const QList<MapActorInfoStruct> &actorInfoList = m_mapInfo.ActorInfoList;
    for (const MapActorInfoStruct &actorInfo : actorInfoList) {
        DrawingObjStruct drawingObj = createDrawingObjFromMapActorInfo(actorInfo);

        // append drawing obj
        drawingObjList.append(drawingObj);
    }
}

void MapWidget::loadAllDrawingObj()
{
    m_mapInfo = m_model->GetMapInfo();
    m_mapOfTagToSpriteInfo = m_model->GetMapOfTagToSpriteInfo();
    m_mapOfTagToFrameAniInfoList = m_model->GetMapOfTagToFrameAniInfoList();
    m_mapOfTagToEquInfo = m_model->GetMapOfTagToEquInfo();
    m_mapOfTagToInstanceInfo = m_model->GetMapOfTagToInstanceInfo();

    loadDrawingObjList(Far);
    loadDrawingObjList(Near);
    loadDrawingObjList(Floor);
    loadDrawingObjList(Obj);
    loadDrawingObjList(Effect);
    loadDrawingObjList(Actor);

    updateRectOfAllDrawingObj();
}

void MapWidget::updateRectOfAllDrawingObj()
{
    QMap<ViewTypeEnum, QList<DrawingObjStruct>>::Iterator iter =
        m_mapOfTypeToDrawingObjList.begin();
    for (; iter != m_mapOfTypeToDrawingObjList.end(); iter++) {
        QList<DrawingObjStruct> &drawingObjList = *iter;
        for (DrawingObjStruct &drawingObj : drawingObjList) {
            drawingObj.UpdateRects(m_xOffset, m_yOffset);
        }
    }

    m_hoveringDrawingObj.UpdateRects(m_xOffset, m_yOffset);
}

void MapWidget::drawDrawingObjList(QPainter &painter, ViewTypeEnum viewType)
{
    QList<DrawingObjStruct> &drawingObjList = m_mapOfTypeToDrawingObjList[viewType];
    for (const DrawingObjStruct &drawingObj : drawingObjList) {
        if (drawingObj.Id == m_movingDrawingObj.Id) {
            // save painter property
            qreal originOpacity = painter.opacity();

            painter.setOpacity(0.7);
            drawingObj.Draw(&painter);
            QColor color(50, 100, 255, 130);
            painter.fillRect(drawingObj.MainRect, color);

            // restore painter property
            painter.setOpacity(originOpacity);
            continue;
        }
        drawingObj.Draw(&painter);
    }
}

DrawingObjStruct MapWidget::findHoveringDrawingObj(ViewTypeEnum viewType, const QPoint &curserPos)
{
    QList<DrawingObjStruct> &drawingObjList = m_mapOfTypeToDrawingObjList[viewType];
    QList<DrawingObjStruct>::reverse_iterator rIter = drawingObjList.rbegin();
    for (; rIter != drawingObjList.rend(); rIter++) {
        if (rIter->MainRect.contains(curserPos)) {
            return *rIter;
        }
    }

    return DrawingObjStruct();
}

void MapWidget::findHoveringDrawingObjInAll(const QPoint &curserPos)
{
    DrawingObjStruct drawingObj;

    if (m_viewTypeList.contains(Actor)) {
        drawingObj = findHoveringDrawingObj(Actor, curserPos);
    }
    if (drawingObj.Id != 0) {
        m_hoveringDrawingObj = drawingObj;
        return;
    }

    if (m_viewTypeList.contains(Effect)) {
        drawingObj = findHoveringDrawingObj(Effect, curserPos);
    }
    if (drawingObj.Id != 0) {
        m_hoveringDrawingObj = drawingObj;
        return;
    }

    if (m_viewTypeList.contains(Obj)) {
        drawingObj = findHoveringDrawingObj(Obj, curserPos);
    }
    if (drawingObj.Id != 0) {
        m_hoveringDrawingObj = drawingObj;
        return;
    }

    if (m_viewTypeList.contains(Floor)) {
        drawingObj = findHoveringDrawingObj(Floor, curserPos);
    }
    if (drawingObj.Id != 0) {
        m_hoveringDrawingObj = drawingObj;
        return;
    }

    if (m_viewTypeList.contains(Near)) {
        drawingObj = findHoveringDrawingObj(Near, curserPos);
    }
    if (drawingObj.Id != 0) {
        m_hoveringDrawingObj = drawingObj;
        return;
    }

    if (m_viewTypeList.contains(Far)) {
        drawingObj = findHoveringDrawingObj(Far, curserPos);
    }
    if (drawingObj.Id != 0) {
        m_hoveringDrawingObj = drawingObj;
        return;
    }

    m_hoveringDrawingObj = DrawingObjStruct();
}

void MapWidget::addDrawingObj(const QPoint &cursorPos)
{
    if (m_placingDrawingObj.ViewType == Actor and
        m_placingViewType != Actor) {
        const QString &msg = "角色实例项 只能放置为 角色项，请将“放置为”设置为：角色项";
        qWarning() << Q_FUNC_INFO << msg;
        QMessageBox::warning(this, "放置错误", msg);
        return;
    }

    if (m_placingDrawingObj.ViewType != Actor and
        m_placingViewType == Actor) {
        const QString &msg = "精灵项 不可放置为 角色项，请将“放置为”设置为非角色项";
        qWarning() << Q_FUNC_INFO << msg;
        QMessageBox::warning(this, "放置错误", msg);
        return;
    }

    DrawingObjStruct drawingObj;
    QList<DrawingObjStruct> &drawingObjList =
        m_mapOfTypeToDrawingObjList[m_placingViewType];
    int x = cursorPos.x() - m_xOffset;
    int y = cursorPos.y() - m_yOffset;

    if (m_placingDrawingObj.ViewType == Actor) {
        MapActorInfoStruct actorInfo = m_placingDrawingObj.MapActorInfo;
        actorInfo.X = x;
        actorInfo.Y = y;
        drawingObj = createDrawingObjFromMapActorInfo(actorInfo);
    } else {
        MapLayerSpriteInfoStruct layerSpriteInfo = m_placingDrawingObj.LayerSpriteInfo;
        layerSpriteInfo.X = x;
        layerSpriteInfo.Y = y;
        drawingObj = createDrawingObjFromLayerSpriteInfo(m_placingViewType, layerSpriteInfo);
    }

    drawingObj.UpdateRects(m_xOffset, m_yOffset);
    drawingObjList.append(drawingObj);

    // 设置新添加的绘画对象为正在移动对象，以便使用方向键调整其位置
    m_movingDrawingObj = drawingObj;
}

void MapWidget::removeDrawingObj(QList<DrawingObjStruct> drawingObjList)
{
    QMap<ViewTypeEnum, QList<DrawingObjStruct>>::Iterator iter =
        m_mapOfTypeToDrawingObjList.begin();
    for (; iter != m_mapOfTypeToDrawingObjList.end(); iter++) {
        QList<DrawingObjStruct> &drawingObjListTmp = *iter;

        for (const DrawingObjStruct &drawingObj : drawingObjList) {
            drawingObjListTmp.removeAll(drawingObj);
        }
    }

    // id list
    for (const DrawingObjStruct &drawingObj : drawingObjList) {
        if (m_canUsedIdList.contains(drawingObj.Id)) {
            continue;
        }
        m_canUsedIdList.append(drawingObj.Id);
    }
}

uint MapWidget::createId()
{
    uint id;
    if (m_canUsedIdList.size()) {
        id = m_canUsedIdList.first();
        m_canUsedIdList.pop_front();
    } else {
        id = ++m_currentMaxId;
    }

    return id;
}

/*
uint MapWidget::createId()
{
    uint id = 1;
    while(1) {
        bool existSameId = false;
        QMap<ViewTypeEnum, QList<DrawingObjStruct>>::Iterator iter =
            m_mapOfTypeToDrawingObjList.begin();
        for (; iter != m_mapOfTypeToDrawingObjList.end(); iter++) {
            QList<DrawingObjStruct> &drawingObjList = *iter;

            for (const DrawingObjStruct &drawingObj : drawingObjList) {
                if (id == drawingObj.Id) {
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
*/

DrawingObjStruct *MapWidget::getDrawingObjById(uint id)
{
    QMap<ViewTypeEnum, QList<DrawingObjStruct>>::Iterator iter =
        m_mapOfTypeToDrawingObjList.begin();
    for (; iter != m_mapOfTypeToDrawingObjList.end(); iter++) {
        QList<DrawingObjStruct> &drawingObjList = *iter;
        for (DrawingObjStruct &drawingObjTmp : drawingObjList) {
            if (id == drawingObjTmp.Id) {
                return &drawingObjTmp;
            }
        }
    }

    return nullptr;
}

void MapWidget::updateToDrawingObj(const DrawingObjStruct &drawingObj)
{
    DrawingObjStruct *obj = getDrawingObjById(drawingObj.Id);
    if (!obj) {
        return;
    }

    // 更新数据
    *obj = drawingObj;
}

void MapWidget::setDrawingObjPos(uint id, int x, int y)
{
    DrawingObjStruct *obj = getDrawingObjById(id);
    if (!obj) {
        return;
    }

    if (obj->ViewType == Actor) {
        obj->MapActorInfo.X = x;
        obj->MapActorInfo.Y = y;
    } else {
        obj->LayerSpriteInfo.X = x;
        obj->LayerSpriteInfo.Y = y;
    }
    obj->X = x;
    obj->Y = y;
    obj->UpdateRects(m_xOffset, m_yOffset);
}

void MapWidget::finishMovingDrawingObj(const QPoint &cursorPos)
{
    setDrawingObjPos(m_movingDrawingObj.Id, cursorPos.x() - m_xOffset,
                     cursorPos.y() - m_yOffset);
}

MapInfoStruct MapWidget::toMapInfo()
{
    MapInfoStruct mapInfo = m_mapInfo;

    // map Layer Info
    QMap<ViewTypeEnum, QList<DrawingObjStruct>>::Iterator iter =
        m_mapOfTypeToDrawingObjList.begin();
    for (; iter != m_mapOfTypeToDrawingObjList.end(); iter++) {
        QList<MapLayerSpriteInfoStruct> *layerSpriteInfoListPtr = nullptr;
        ViewTypeEnum viewType = iter.key();
        switch (viewType) {
        case Far:
            layerSpriteInfoListPtr = &mapInfo.LayerInfo.FarLayerSpriteInfoList;
            break;
        case Near:
            layerSpriteInfoListPtr = &mapInfo.LayerInfo.NearLayerSpriteInfoList;
            break;
        case Floor:
            layerSpriteInfoListPtr = &mapInfo.LayerInfo.FloorLayerSpriteInfoList;
            break;
        case Obj:
            layerSpriteInfoListPtr = &mapInfo.LayerInfo.ObjLayerSpriteInfoList;
            break;
        case Effect:
            layerSpriteInfoListPtr = &mapInfo.LayerInfo.EffectLayerSpriteInfoList;
            break;
        case Actor:
            break;
        default:
            break;
        }
        if (layerSpriteInfoListPtr == nullptr) {
            continue;
        }

        layerSpriteInfoListPtr->clear();
        QList<DrawingObjStruct> &drawingObjList = *iter;
        for (const DrawingObjStruct &drawingObj : drawingObjList) {
            MapLayerSpriteInfoStruct layerSpriteInfo = drawingObj.LayerSpriteInfo;
            layerSpriteInfo.Id = drawingObj.Id;
            layerSpriteInfoListPtr->append(layerSpriteInfo);
        }
    }

    // map actor info
    mapInfo.ActorInfoList.clear();
    QList<DrawingObjStruct> &ActorDrawingObjList = m_mapOfTypeToDrawingObjList[Actor];
    for (const DrawingObjStruct &drawingObj : ActorDrawingObjList) {
        mapInfo.ActorInfoList.append(drawingObj.MapActorInfo);
    }

    return mapInfo;
}

