#include "mainwindow.h"
#include "Model.h"

#include <QMenuBar>
#include <QVBoxLayout>
#include <QToolBar>
#include <QLabel>
#include <QTreeView>
#include <QDebug>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    // pre data init
    Model *model = new Model();
    model->LoadItems();
    model->LoadMapBySimplePath("TestMap");

    // ui init
    QMenuBar *menuBar = this->menuBar();

    QMenu *fileMenu = new QMenu(this);
    fileMenu->setTitle("文件");
    QAction *newMapAction = new QAction("创建新地图");
    fileMenu->addAction(newMapAction);
    QAction *openFileAction = new QAction("打开");
    fileMenu->addAction(openFileAction);
    QAction *saveFileAction = new QAction("保存");
    fileMenu->addAction(saveFileAction);
    QAction *saveAsAction = new QAction("另存为");
    fileMenu->addAction(saveAsAction);
    menuBar->addMenu(fileMenu);

    menuBar->addAction("地图设置");
    menuBar->addAction("软件设置");

    QVBoxLayout *mainLayout = new QVBoxLayout;
    mainLayout->setContentsMargins(0, 0, 0, 0);

    QWidget *mainWidget = new QWidget(this);
    mainWidget->setLayout(mainLayout);

    setCentralWidget(mainWidget);

    QHBoxLayout *contentLayout = new QHBoxLayout;
    contentLayout->setContentsMargins(0, 0, 0, 0);
    contentLayout->setSpacing(0);
    mainLayout->addLayout(contentLayout);

    // left content
    contentLayout->addSpacing(3);
    QVBoxLayout *leftContentLayout = new QVBoxLayout;
    leftContentLayout->setContentsMargins(0, 0, 0, 0);
    contentLayout->addLayout(leftContentLayout);

    leftContentLayout->addSpacing(5);
    QLabel *leftContentTitleLabel = new QLabel(this);
    leftContentTitleLabel->setText("项目");
    leftContentLayout->addWidget(leftContentTitleLabel, 0, Qt::AlignLeft | Qt::AlignTop);

    leftContentLayout->addSpacing(5);
    QTreeView *itemTreeView = new QTreeView(this);
    itemTreeView->setHeaderHidden(true);
    itemTreeView->setIconSize(QSize(30, 30));
    itemTreeView->setWordWrap(true);
    itemTreeView->setEditTriggers(QTreeView::EditTrigger::NoEditTriggers);
//    itemTreeView->setStyleSheet("background-color:yellow");
    leftContentLayout->addWidget(itemTreeView, 0, Qt::AlignLeft);

    QStandardItemModel *itemTreeViewModel = new QStandardItemModel(this);
    itemTreeView->setModel(itemTreeViewModel);

    // right content
    contentLayout->addSpacing(3);
    QVBoxLayout *rightContentLayout = new QVBoxLayout;
    rightContentLayout->setContentsMargins(0, 0, 0, 0);
    contentLayout->addLayout(rightContentLayout, 1);

    // map title layout
    rightContentLayout->addSpacing(5);
    QHBoxLayout *mapTitleLayout = new QHBoxLayout;
    mapTitleLayout->setContentsMargins(0, 0, 0, 0);
    rightContentLayout->addLayout(mapTitleLayout);

    QLabel *rightContentTitleLabel = new QLabel(this);
//    rightContentTitleLabel->setStyleSheet("background-color:red");
    rightContentTitleLabel->setText("地图");
    mapTitleLayout->addWidget(rightContentTitleLabel, 0, Qt::AlignLeft | Qt::AlignVCenter);

    // view type
    mapTitleLayout->addSpacing(10);
    QPushButton *viewTypeBtn = new QPushButton(this);
    viewTypeBtn->setText("视图");
    QMenu *viewTypeBtnMenu = new QMenu(this);
    QAction *farViewAction = new QAction("远景", this);
    farViewAction->setCheckable(true);
    farViewAction->setChecked(true);
    viewTypeBtnMenu->addAction(farViewAction);
    QAction *nearViewAction = new QAction("近景", this);
    nearViewAction->setCheckable(true);
    nearViewAction->setChecked(true);
    viewTypeBtnMenu->addAction(nearViewAction);
    QAction *floorViewAction = new QAction("地面", this);
    floorViewAction->setCheckable(true);
    floorViewAction->setChecked(true);
    viewTypeBtnMenu->addAction(floorViewAction);
    QAction *objViewAction = new QAction("物体", this);
    objViewAction->setCheckable(true);
    objViewAction->setChecked(true);
    viewTypeBtnMenu->addAction(objViewAction);
    QAction *effectViewAction = new QAction("效果", this);
    effectViewAction->setCheckable(true);
    effectViewAction->setChecked(true);
    viewTypeBtnMenu->addAction(effectViewAction);
    QAction *actorViewAction = new QAction("人物", this);
    actorViewAction->setCheckable(true);
    actorViewAction->setChecked(true);
    viewTypeBtnMenu->addAction(actorViewAction);
    viewTypeBtn->setMenu(viewTypeBtnMenu);
    mapTitleLayout->addWidget(viewTypeBtn, 0, Qt::AlignLeft);

    // place as label
    mapTitleLayout->addSpacing(10);
    QLabel *placeAsLabel = new QLabel(this);
    placeAsLabel->setText("放置为：");
    mapTitleLayout->addWidget(placeAsLabel, 0, Qt::AlignLeft);

    QPushButton *placeAsBtn = new QPushButton(this);
    QMenu *placeAsBtnMenu = new QMenu(this);
    QAction *farViewItemAction = new QAction("远景项", this);
    farViewItemAction->setCheckable(true);
    placeAsBtnMenu->addAction(farViewItemAction);
    QAction *nearViewItemAction = new QAction("近景项", this);
    nearViewItemAction->setCheckable(true);
    placeAsBtnMenu->addAction(nearViewItemAction);
    QAction *floorViewItemAction = new QAction("地面项", this);
    floorViewItemAction->setCheckable(true);
    placeAsBtnMenu->addAction(floorViewItemAction);
    QAction *objViewItemAction = new QAction("物体项", this);
    objViewItemAction->setCheckable(true);
    placeAsBtnMenu->addAction(objViewItemAction);
    QAction *effectViewItemAction = new QAction("效果项", this);
    effectViewItemAction->setCheckable(true);
    placeAsBtnMenu->addAction(effectViewItemAction);
    QAction *actorViewItemAction = new QAction("人物项", this);
    actorViewItemAction->setCheckable(true);
    placeAsBtnMenu->addAction(actorViewItemAction);
    placeAsBtn->setMenu(placeAsBtnMenu);
    mapTitleLayout->addWidget(placeAsBtn, 0, Qt::AlignLeft);

    mapTitleLayout->addStretch(1);

    rightContentLayout->addSpacing(5);
    MapWidget *mapWidget = new MapWidget(this, model);
    // mapWidget->setStyleSheet("background-color:blue");
    rightContentLayout->addWidget(mapWidget, 1);

    //
    QHBoxLayout *dockLayout = new QHBoxLayout;
    mainLayout->addLayout(dockLayout);

    dockLayout->addSpacing(5);
    QLabel *posLabel = new QLabel(this);
    posLabel->setText("坐标：(0, 0)");
    dockLayout->addWidget(posLabel, 0, Qt::AlignLeft);

    mainLayout->addSpacing(5);

    // init connections
    connect(fileMenu, &QMenu::triggered, this, [=](QAction *action) {
        if (action == openFileAction) {
            model->OpenMap();
        }
        if (action == saveFileAction) {
            model->SaveMap();
        }
        if (action == saveAsAction) {
            model->SaveMapAs();
        }
    });


    connect(mapWidget, &MapWidget::SendMousePosInMap, this, [=](int x, int y) {
        posLabel->setText(QString("坐标：(%1, %2)").arg(x).arg(y));
    });

    connect(viewTypeBtnMenu, &QMenu::triggered, this, [=](QAction *action) {
        QList<ViewType> viewTypeList;
        if (farViewAction->isChecked()) {
            viewTypeList.append(Far);
        }
        if (nearViewAction->isChecked()) {
            viewTypeList.append(Near);
        }
        if (floorViewAction->isChecked()) {
            viewTypeList.append(Floor);
        }
        if (objViewAction->isChecked()) {
            viewTypeList.append(Obj);
        }
        if (effectViewAction->isChecked()) {
            viewTypeList.append(Effect);
        }
        if (actorViewAction->isChecked()) {
            viewTypeList.append(Actor);
        }

        mapWidget->SetViewTypeList(viewTypeList);
    });

    connect(placeAsBtnMenu, &QMenu::triggered, this, [=](QAction *action){
        farViewItemAction->setChecked(false);
        nearViewItemAction->setChecked(false);
        floorViewItemAction->setChecked(false);
        objViewItemAction->setChecked(false);
        effectViewItemAction->setChecked(false);
        actorViewItemAction->setChecked(false);

        action->setChecked(true);
        placeAsBtn->setText(action->text());

        ViewType placingViewType = Floor;
        if (action == farViewItemAction) {
            placingViewType = Far;
        } else if  (action == nearViewItemAction) {
            placingViewType = Near;
        } else if  (action == floorViewItemAction) {
            placingViewType = Floor;
        } else if  (action == objViewItemAction) {
            placingViewType = Obj;
        } else if  (action == effectViewItemAction) {
            placingViewType = Effect;
        } else if  (action == actorViewItemAction) {
            placingViewType = Actor;
        }

        mapWidget->SetPlacingViewType(placingViewType);
    });

    // itemTreeView->customContextMenuRequested()
    connect(itemTreeView, &QTreeView::clicked, this, [=](QModelIndex index) {
        if (m_lastSelectedIndex == index) {
            itemTreeView->setCurrentIndex(QModelIndex());

            mapWidget->SetPlacingDrawingSpriteVisible(false);
            m_lastSelectedIndex = QModelIndex();
            return;
        }
        const QString &tag = itemTreeViewModel->itemFromIndex(index)->text();
        const QMap<QString, SpriteInfoStruct> &mapOfTagToSpriteInfo = model->GetMapOfTagToSpriteInfo();
        const SpriteInfoStruct &spriteInfo = mapOfTagToSpriteInfo.value(tag);

        mapWidget->SetPlacingDrawingSpriteVisible(true);
        mapWidget->SetPlacingSpriteInfo(spriteInfo);

        m_lastSelectedIndex = index;
    });



    //// post data init
    // select placing view type
    Q_EMIT placeAsBtnMenu->triggered(floorViewItemAction);

    // load to tree view
    const QMap<QString, SpriteInfoStruct> &mapOfTagToSpriteInfo = model->GetMapOfTagToSpriteInfo();
    QMap<QString, SpriteInfoStruct>::const_iterator cIt = mapOfTagToSpriteInfo.constBegin();
    for (; cIt != mapOfTagToSpriteInfo.constEnd(); cIt++) {
        QStandardItem *item = new QStandardItem(cIt.key());
        item->setCheckable(false);
        // item->setData("")
        item->setSizeHint(QSize(30, 50));
        item->setIcon(QIcon(cIt.value().ImgPath));
        itemTreeViewModel->appendRow(item);
    }
}

MainWindow::~MainWindow()
{
}

