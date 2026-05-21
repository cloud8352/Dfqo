#include "MapActorsMirroringDlg.h"

#include <QDebug>

MapActorsMirroringDlg::MapActorsMirroringDlg(Model *model, QWidget *parent)
    : QMainWindow(parent)
    , m_model(model)
{
    // pre data init

    // ui init
    setWindowModality(Qt::WindowModality::ApplicationModal);
    setWindowTitle("地图角色实例镜像工具");

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
    leftHeaderTitleLabel->setText("原地图角色实例数据：");
    leftHeaderLayout->addWidget(leftHeaderTitleLabel, 1);

    QPushButton *openBtn = new QPushButton(this);
    openBtn->setText("打开");
    leftHeaderLayout->addWidget(openBtn);

    QTextEdit *oriActorsEdit = new QTextEdit(this);
    leftLayout->addWidget(oriActorsEdit);

    QHBoxLayout *leftHeaderLayout2 = new QHBoxLayout;
    leftLayout->addLayout(leftHeaderLayout2);

    QLabel *leftHeaderTitleLabel2 = new QLabel(this);
    leftHeaderTitleLabel2->setText("镜像后地图角色实例数据：");
    leftHeaderLayout2->addWidget(leftHeaderTitleLabel2, 1);

    QTextEdit *mirroredActorsEdit = new QTextEdit(this);
    leftLayout->addWidget(mirroredActorsEdit);

    // right layout
    QVBoxLayout *rightLayout = new QVBoxLayout;
    mainLayout->addLayout(rightLayout);

    rightLayout->addSpacing(80);
    QGridLayout *propertySetLayout = new QGridLayout;
    rightLayout->addLayout(propertySetLayout);

    QLabel *mirroringBasedXposLabel = new QLabel(this);
    mirroringBasedXposLabel->setText("镜像中心X坐标");
    propertySetLayout->addWidget(mirroringBasedXposLabel, 0, 0);

    QLineEdit *mirroringBasedXposEdit = new QLineEdit(this);
    mirroringBasedXposEdit->setText("0");
    propertySetLayout->addWidget(mirroringBasedXposEdit, 0, 1);

    QLabel *mirroringBasedYposLabel = new QLabel(this);
    mirroringBasedYposLabel->setText("镜像中心Y坐标");
    propertySetLayout->addWidget(mirroringBasedYposLabel, 1, 0);

    QLineEdit *mirroringBasedYposEdit = new QLineEdit(this);
    mirroringBasedYposEdit->setText("0");
    propertySetLayout->addWidget(mirroringBasedYposEdit, 1, 1);

    // mirror btn
    rightLayout->addStretch(1);
    QPushButton *mirrorByXBtn = new QPushButton(this);
    mirrorByXBtn->setText("水平镜像");
    mirrorByXBtn->setMinimumWidth(80);
    mirrorByXBtn->setSizePolicy(QSizePolicy::Policy::Fixed, QSizePolicy::Policy::Fixed);
    rightLayout->addWidget(mirrorByXBtn, 0, Qt::AlignCenter);

    QPushButton *mirrorByYBtn = new QPushButton(this);
    mirrorByYBtn->setText("垂直镜像");
    mirrorByYBtn->setMinimumWidth(80);
    mirrorByYBtn->setSizePolicy(QSizePolicy::Policy::Fixed, QSizePolicy::Policy::Fixed);
    rightLayout->addWidget(mirrorByYBtn, 0, Qt::AlignCenter);

    // connect
    connect(openBtn, &QPushButton::clicked, this, [=] {
        const QString &luaCfgPath = getCfgFilePathByFileDlg();
        QFile file(luaCfgPath);
        if (!file.open(QIODevice::OpenModeFlag::ReadOnly)) {
            qWarning() << Q_FUNC_INFO << file.fileName() << "open failed!";
        }
        const QString &contentStr = file.readAll();
        file.close();

        oriActorsEdit->setPlainText(contentStr);
    });

    connect(mirrorByXBtn, &QPushButton::clicked, this, [=] {
        int mirroringBasedXpos = mirroringBasedXposEdit->text().toInt();
        const QString &contentStr = oriActorsEdit->toPlainText();
        QJsonArray oriJsonArray = Lua::LuaStrToJsonArray(contentStr);
        QJsonArray mirroredJsonArray;
        for (const QJsonValue &jsonValue : oriJsonArray) {
            QJsonObject jsonObj = jsonValue.toObject();

            int x = jsonObj.value("x").toInt();
            x = mirroringBasedXpos * 2 - x;
            jsonObj.insert("x", x);
            mirroredJsonArray.append(jsonObj);
        }

        const QString &mirroredStr = Lua::JsonArrayToLuaStr(mirroredJsonArray);
        mirroredActorsEdit->setPlainText(mirroredStr);

        QMessageBox::information(this, "成功", "水平镜像成功");
    });

    connect(mirrorByYBtn, &QPushButton::clicked, this, [=] {
        int mirroringBasedYpos = mirroringBasedYposEdit->text().toInt();
        const QString &contentStr = oriActorsEdit->toPlainText();
        QJsonArray oriJsonArray = Lua::LuaStrToJsonArray(contentStr);
        QJsonArray mirroredJsonArray;
        for (const QJsonValue &jsonValue : oriJsonArray) {
            QJsonObject jsonObj = jsonValue.toObject();

            int y = jsonObj.value("y").toInt();
            y = mirroringBasedYpos * 2 - y;
            jsonObj.insert("y", y);
            mirroredJsonArray.append(jsonObj);
        }

        const QString &mirroredStr = Lua::JsonArrayToLuaStr(mirroredJsonArray);
        mirroredActorsEdit->setPlainText(mirroredStr);

        QMessageBox::information(this, "成功", "垂直镜像成功");
    });

    //// post data init
}

MapActorsMirroringDlg::~MapActorsMirroringDlg()
{
}

QString MapActorsMirroringDlg::getCfgFilePathByFileDlg()
{
    return QFileDialog::getOpenFileName(this, "打开文件", m_model->GetGameRootPath());
}
