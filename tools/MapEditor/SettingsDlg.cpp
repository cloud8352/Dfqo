#include "SettingsDlg.h"

#include <QDebug>

const QString &WindowTitle = "地图设置";

SettingsDlg::SettingsDlg(Model *model, QWidget *parent)
    : QMainWindow(parent)
    , m_model(model)
    , m_gameRootPathLineEdit(nullptr)
{
    // pre data init


    // ui init
    setWindowModality(Qt::WindowModality::ApplicationModal);
    setWindowTitle(WindowTitle);

    setMinimumSize(1000, 640);

    QWidget *contentWidget = new QWidget(this);
    setCentralWidget(contentWidget);

    QVBoxLayout *contentLayout = new QVBoxLayout;
    contentLayout->setAlignment(Qt::AlignTop);
    contentWidget->setLayout(contentLayout);

    QHBoxLayout *gameRootPathLayout = new QHBoxLayout;
    contentLayout->addLayout(gameRootPathLayout);

    QLabel *gameRootPathTitleLabel = new QLabel(this);
    gameRootPathTitleLabel->setText("游戏根目录：");
    gameRootPathLayout->addWidget(gameRootPathTitleLabel, 0, Qt::AlignLeft);

    m_gameRootPathLineEdit = new QLineEdit(this);
    m_gameRootPathLineEdit->setText(m_model->GetGameRootPath());
    gameRootPathLayout->addWidget(m_gameRootPathLineEdit, 1);

    QPushButton *gameRootPathModifyBtn = new QPushButton(this);
    gameRootPathModifyBtn->setText("修改");
    gameRootPathLayout->addWidget(gameRootPathModifyBtn, 0, Qt::AlignLeft);

    // bottom
    contentLayout->addStretch(1);
    QHBoxLayout *bottomLayout = new QHBoxLayout;
    contentLayout->addLayout(bottomLayout);

    bottomLayout->addStretch(4);
    QPushButton *saveBtn = new QPushButton(this);
    saveBtn->setMinimumWidth(100);
    // saveBtn->setSizePolicy(QSizePolicy::Policy::Maximum, QSizePolicy::Policy::Minimum);
    saveBtn->setText("保存");
    bottomLayout->addWidget(saveBtn);

    bottomLayout->addSpacing(30);
    QPushButton *cancelBtn = new QPushButton(this);
    cancelBtn->setMinimumWidth(100);
    // cancelBtn->setSizePolicy(QSizePolicy::Policy::Maximum, QSizePolicy::Policy::Minimum);
    cancelBtn->setText("取消");
    bottomLayout->addWidget(cancelBtn);
    bottomLayout->addStretch(4);

    // init connections
    connect(m_gameRootPathLineEdit, &QLineEdit::textChanged, this, [=](const QString &) {
        setWindowTitle(WindowTitle + "*");
    });

    connect(gameRootPathModifyBtn, &QPushButton::clicked, this, [=](bool) {
        const QString &dirPath = m_gameRootPathLineEdit->text();
        QString dirPathTmp = QFileDialog::getExistingDirectory(nullptr, "设置游戏根目录", dirPath);
        if (dirPathTmp.isEmpty()) {
            return;
        }

        m_gameRootPathLineEdit->setText(dirPathTmp);
    });
    connect(saveBtn, &QPushButton::clicked, this, [=](bool) {
        const QString &dirPath = m_gameRootPathLineEdit->text();
        m_model->SetGameRootPath(dirPath);
        setWindowTitle(WindowTitle);
        setVisible(false);
    });
    connect(cancelBtn, &QPushButton::clicked, this, &SettingsDlg::Reset);

    //// post data init
}

SettingsDlg::~SettingsDlg()
{
}

void SettingsDlg::Reset()
{
    m_gameRootPathLineEdit->setText(m_model->GetGameRootPath());
    setWindowTitle(WindowTitle);
}
