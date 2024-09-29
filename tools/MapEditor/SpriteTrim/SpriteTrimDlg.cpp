#include "SpriteTrimDlg.h"

#include <QDebug>

SpriteTrimDlg::SpriteTrimDlg(Model *model, QWidget *parent)
    : QMainWindow(parent)
    , m_model(model)
{
    // pre data init

    // ui init
    setWindowModality(Qt::WindowModality::ApplicationModal);
    setWindowTitle("素材修剪工具");

    resize(1000, 600);

    QWidget *contentWidget = new QWidget(this);
    setCentralWidget(contentWidget);

    QHBoxLayout *mainLayout = new QHBoxLayout;
    contentWidget->setLayout(mainLayout);

    QVBoxLayout *leftLayout = new QVBoxLayout;
    mainLayout->addLayout(leftLayout);

    QHBoxLayout *leftHeaderLayout = new QHBoxLayout;
    leftLayout->addLayout(leftHeaderLayout);

    QLabel *leftHeaderTitleLabel = new QLabel(this);
    leftHeaderTitleLabel->setText("图片文件列表：");
    leftHeaderLayout->addWidget(leftHeaderTitleLabel, 1);

    QPushButton *addBtn = new QPushButton(this);
    addBtn->setText("添加");
    leftHeaderLayout->addWidget(addBtn);

    QListView *listView = new QListView(this);
    leftLayout->addWidget(listView);

    QStandardItemModel *imgFileListViewModel = new QStandardItemModel(this);
    listView->setModel(imgFileListViewModel);

    QHBoxLayout *leftHeaderLayout2 = new QHBoxLayout;
    leftLayout->addLayout(leftHeaderLayout2);

    QLabel *leftHeaderTitleLabel2 = new QLabel(this);
    leftHeaderTitleLabel2->setText("偏移文件列表：");
    leftHeaderLayout2->addWidget(leftHeaderTitleLabel2, 1);

    QPushButton *addBtn2 = new QPushButton(this);
    addBtn2->setText("添加");
    leftHeaderLayout2->addWidget(addBtn2);

    QListView *listView2 = new QListView(this);
    leftLayout->addWidget(listView2);

    QStandardItemModel *offsetFileListViewModel = new QStandardItemModel(this);
    listView2->setModel(offsetFileListViewModel);

    // right layout
    QVBoxLayout *rightLayout = new QVBoxLayout;
    mainLayout->addLayout(rightLayout);

    rightLayout->addSpacing(80);
    QGridLayout *propertySetLayout = new QGridLayout;
    rightLayout->addLayout(propertySetLayout);

    QLabel *trimWidthLabel = new QLabel(this);
    trimWidthLabel->setText("剪切宽度");
    propertySetLayout->addWidget(trimWidthLabel, 0, 0);

    QLineEdit *trimWidthEdit = new QLineEdit(this);
    trimWidthEdit->setText("0");
    propertySetLayout->addWidget(trimWidthEdit, 0, 1);

    QLabel *trimHeightLabel = new QLabel(this);
    trimHeightLabel->setText("剪切高度");
    propertySetLayout->addWidget(trimHeightLabel, 1, 0);

    QLineEdit *trimHeightEdit = new QLineEdit(this);
    trimHeightEdit->setText("0");
    propertySetLayout->addWidget(trimHeightEdit, 1, 1);

    // trim btn
    rightLayout->addStretch(1);
    QPushButton *trimBtn = new QPushButton(this);
    trimBtn->setText("剪切");
    trimBtn->setMinimumWidth(80);
    trimBtn->setSizePolicy(QSizePolicy::Policy::Fixed, QSizePolicy::Policy::Fixed);
    rightLayout->addWidget(trimBtn, 0, Qt::AlignCenter);

    // connect
    connect(addBtn, &QPushButton::clicked, this, [=] {
        const QStringList &filePathList = getFilePathListByFileDlg();
        loadToListViewModel(imgFileListViewModel, filePathList);
    });
    connect(addBtn2, &QPushButton::clicked, this, [=] {
        const QStringList &filePathList = getFilePathListByFileDlg();
        loadToListViewModel(offsetFileListViewModel, filePathList);
    });

    connect(trimBtn, &QPushButton::clicked, this, [=] {
        const QString &desktopPath = QStandardPaths::writableLocation(QStandardPaths::StandardLocation::DesktopLocation);
        int trimWidth = trimWidthEdit->text().toInt();
        int trimHeight = trimHeightEdit->text().toInt();
        for (int i = 0; i < imgFileListViewModel->rowCount(); i++) {
            QStandardItem *item = imgFileListViewModel->item(i, 0);
            QImage img(item->text());
            QRect rect(trimWidth, trimHeight, img.width() - trimWidth, img.height() - trimHeight);
            img = img.copy(rect);

            QFileInfo info(item->text());
            QString outputFilePath = QString("%1/SpritTrimOutput/Img/%2").arg(desktopPath).arg(info.fileName());

            info.setFile(outputFilePath);
            if (!info.dir().exists()) {
                info.dir().mkpath(info.dir().absolutePath());
            }
            img.save(outputFilePath);
        }
        for (int i = 0; i < offsetFileListViewModel->rowCount(); i++) {
            QStandardItem *item = offsetFileListViewModel->item(i, 0);

            QFile file(item->text());
            if (!file.open(QIODevice::OpenModeFlag::ReadOnly)) {
                qWarning() << Q_FUNC_INFO << file.fileName() << "open failed!";
                continue;
            }
            const QString &contentStr = file.readAll();
            file.close();

            QJsonObject jsonObj = Lua::LuaStrToJsonObj(contentStr);
            int ox = jsonObj.value("ox").toInt() - trimWidth;
            int oy = jsonObj.value("oy").toInt() - trimHeight;

            jsonObj.insert("ox", ox);
            jsonObj.insert("oy", oy);

            // save
            QFileInfo info(item->text());
            QString outputFilePath = QString("%1/SpritTrimOutput/Offset/%2").arg(desktopPath).arg(info.fileName());

            info.setFile(outputFilePath);
            if (!info.dir().exists()) {
                info.dir().mkpath(info.dir().absolutePath());
            }
            file.setFileName(outputFilePath);
            if (!file.open(QIODevice::OpenModeFlag::WriteOnly)) {
                qWarning() << Q_FUNC_INFO << file.fileName() << "open failed!";
                continue;
            }

            QString contentStrNeedWrite = Lua::JsonObjToLuaStr(jsonObj);
            file.write(contentStrNeedWrite.toUtf8());
            file.close();
        }

        QMessageBox::information(this, "成功", "修剪成功");
    });

    //// post data init
}

SpriteTrimDlg::~SpriteTrimDlg()
{
}

QStringList SpriteTrimDlg::getFilePathListByFileDlg()
{
    return QFileDialog::getOpenFileNames(this, "添加文件", m_model->GetGameRootPath());
}

void SpriteTrimDlg::loadToListViewModel(QStandardItemModel *itemModel, const QStringList &filePathList)
{
    for (const QString &filePath : filePathList) {
        QFileInfo info(filePath);
        if (info.isDir()) {
            continue;
        }
        QStandardItem *item = new QStandardItem(filePath);
        itemModel->appendRow(item);
    }
}

