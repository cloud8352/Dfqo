#include "MapSettingsDlg.h"

#include <QDebug>

MapSettingsDlg::MapSettingsDlg(QWidget *parent)
    : QMainWindow(parent)
    // base info
    ,m_widthLineEdit(nullptr)
    ,m_heightLineEdit(nullptr)
    ,m_horizonLineEdit(nullptr)
    ,m_nameLineEdit(nullptr)
    ,m_bgmLineEdit(nullptr)
    ,m_bgsLineEdit(nullptr)
    ,m_themeLineEdit(nullptr)
    ,m_isTownCheckBox(nullptr)
    ,m_nearBgTranslateRateLineEdit(nullptr)

    // scope info
    ,m_xLineEdit(nullptr)
    ,m_yLineEdit(nullptr)
    ,m_wvLineEdit(nullptr)
    ,m_uvLineEdit(nullptr)
    ,m_wLineEdit(nullptr)
    ,m_hvLineEdit(nullptr)
    ,m_hLineEdit(nullptr)
    ,m_dvLineEdit(nullptr)
{
    // pre data init


    // ui init
    setWindowModality(Qt::WindowModality::ApplicationModal);
    setWindowTitle("地图设置");

    QWidget *contentWidget = new QWidget(this);
    setCentralWidget(contentWidget);

    QVBoxLayout *contentLayout = new QVBoxLayout;
    contentWidget->setLayout(contentLayout);

    QGridLayout *mainLayout = new QGridLayout;
    contentLayout->addLayout(mainLayout);

    /// base info
    QLabel *baseInfoTitleLabel = new QLabel(this);
    baseInfoTitleLabel->setText("基础信息");
    mainLayout->addWidget(baseInfoTitleLabel, 0, 0);

    m_widthLineEdit = new QLineEdit(this);
    QHBoxLayout *layout = createKeyValueLayout("width", m_widthLineEdit);
    mainLayout->addLayout(layout, 1, 0);

    m_heightLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("height", m_heightLineEdit);
    mainLayout->addLayout(layout, 1, 1);

    m_horizonLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("horizon", m_horizonLineEdit);
    mainLayout->addLayout(layout, 2, 0);

    m_nameLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("name", m_nameLineEdit);
    mainLayout->addLayout(layout, 2, 1);

    m_bgmLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("bgm", m_bgmLineEdit);
    mainLayout->addLayout(layout, 3, 0);

    m_bgsLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("bgs", m_bgsLineEdit);
    mainLayout->addLayout(layout, 3, 1);

    m_themeLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("theme", m_themeLineEdit);
    mainLayout->addLayout(layout, 4, 0);

    m_isTownCheckBox = new QCheckBox(this);
    layout = createKeyValueLayout("isTown", m_isTownCheckBox);
    mainLayout->addLayout(layout, 4, 1, Qt::AlignLeft);

    m_nearBgTranslateRateLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("NearBgTranslateRate", m_nearBgTranslateRateLineEdit);
    mainLayout->addLayout(layout, 5, 0, Qt::AlignLeft);

    /// scope info
    QLabel *scopeInfoTitleLabel = new QLabel(this);
    scopeInfoTitleLabel->setText("范围信息");
    mainLayout->addWidget(scopeInfoTitleLabel, 6, 0);

    m_xLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("x", m_xLineEdit);
    mainLayout->addLayout(layout, 7, 0);

    m_yLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("y", m_yLineEdit);
    mainLayout->addLayout(layout, 7, 1);

    m_wvLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("wv", m_wvLineEdit);
    mainLayout->addLayout(layout, 8, 0);

    m_uvLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("uv", m_uvLineEdit);
    mainLayout->addLayout(layout, 8, 1);

    m_wLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("w", m_wLineEdit);
    mainLayout->addLayout(layout, 9, 0);

    m_hvLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("hv", m_hvLineEdit);
    mainLayout->addLayout(layout, 9, 1);

    m_hLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("h", m_hLineEdit);
    mainLayout->addLayout(layout, 10, 0);

    m_dvLineEdit = new QLineEdit(this);
    layout = createKeyValueLayout("dv", m_dvLineEdit);
    mainLayout->addLayout(layout, 10, 1);

    //// init connections
    // base info
    connect(m_widthLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onBaseInfoUiDataChanged);
    connect(m_heightLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onBaseInfoUiDataChanged);
    connect(m_horizonLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onBaseInfoUiDataChanged);
    connect(m_nameLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onBaseInfoUiDataChanged);
    connect(m_bgmLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onBaseInfoUiDataChanged);
    connect(m_bgsLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onBaseInfoUiDataChanged);
    connect(m_themeLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onBaseInfoUiDataChanged);
    connect(m_isTownCheckBox, &QCheckBox::stateChanged, this, &MapSettingsDlg::onBaseInfoUiDataChanged);
    connect(m_nearBgTranslateRateLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onBaseInfoUiDataChanged);

    // scope info
    connect(m_xLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onScopeInfoUiDataChanged);
    connect(m_yLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onScopeInfoUiDataChanged);
    connect(m_wvLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onScopeInfoUiDataChanged);
    connect(m_uvLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onScopeInfoUiDataChanged);
    connect(m_wLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onScopeInfoUiDataChanged);
    connect(m_hvLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onScopeInfoUiDataChanged);
    connect(m_hLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onScopeInfoUiDataChanged);
    connect(m_dvLineEdit, &QLineEdit::textEdited, this, &MapSettingsDlg::onScopeInfoUiDataChanged);

    //// post data init
}

MapSettingsDlg::~MapSettingsDlg()
{
}

void MapSettingsDlg::SetMapBaseInfo(const MapBaseInfoStruct &mapBaseInfo)
{

    m_widthLineEdit->setText(QString::number(mapBaseInfo.Width));
    m_heightLineEdit->setText(QString::number(mapBaseInfo.Height));
    m_horizonLineEdit->setText(QString::number(mapBaseInfo.Horizon));
    m_nameLineEdit->setText(QString(mapBaseInfo.Name));
    m_bgmLineEdit->setText(QString(mapBaseInfo.Bgm));
    m_bgsLineEdit->setText(QString(mapBaseInfo.Bgs));
    m_themeLineEdit->setText(QString(mapBaseInfo.Theme));
    m_isTownCheckBox->setChecked(mapBaseInfo.IsTown);
    m_nearBgTranslateRateLineEdit->setText(QString::number(mapBaseInfo.NearBgTranslateRate));
}

void MapSettingsDlg::SetMapScopeInfo(const MapScopeInfoStruct &mapScopeInfo)
{
    m_xLineEdit->setText(QString::number(mapScopeInfo.X));
    m_yLineEdit->setText(QString::number(mapScopeInfo.Y));
    m_wvLineEdit->setText(QString::number(mapScopeInfo.WV));
    m_uvLineEdit->setText(QString::number(mapScopeInfo.UV));
    m_wLineEdit->setText(QString::number(mapScopeInfo.W));
    m_hvLineEdit->setText(QString::number(mapScopeInfo.HV));
    m_hLineEdit->setText(QString::number(mapScopeInfo.H));
    m_dvLineEdit->setText(QString::number(mapScopeInfo.DV));
}

void MapSettingsDlg::onBaseInfoUiDataChanged()
{
    const MapBaseInfoStruct &info = getMapBaseInfoFromUi();
    Q_EMIT MapBaseInfoChanged(info);
}

void MapSettingsDlg::onScopeInfoUiDataChanged()
{
    const MapScopeInfoStruct &info = getMapScopeInfoFromUi();
    Q_EMIT MapScopeInfoChanged(info);
}

QHBoxLayout *MapSettingsDlg::createKeyValueLayout(const QString &keyStr, QWidget *w)
{
    QHBoxLayout *keyValueLayout = new QHBoxLayout;

    QLabel *widthLabel = new QLabel(this);
    widthLabel->setText(keyStr + ": ");
    keyValueLayout->addWidget(widthLabel);

    keyValueLayout->addWidget(w, 0, Qt::AlignLeft);

    return keyValueLayout;
}

MapBaseInfoStruct MapSettingsDlg::getMapBaseInfoFromUi()
{
    MapBaseInfoStruct info;
    info.Width = m_widthLineEdit->text().toInt();
    info.Height = m_heightLineEdit->text().toInt();
    info.Horizon = m_horizonLineEdit->text().toInt();
    info.Name = m_nameLineEdit->text();
    info.Bgm = m_bgmLineEdit->text();
    info.Bgs = m_bgsLineEdit->text();
    info.Theme = m_themeLineEdit->text();
    info.IsTown = m_isTownCheckBox->isChecked();
    info.NearBgTranslateRate = m_nearBgTranslateRateLineEdit->text().toDouble();

    return info;
}

MapScopeInfoStruct MapSettingsDlg::getMapScopeInfoFromUi()
{
    MapScopeInfoStruct info;

    info.X = m_xLineEdit->text().toInt();
    info.Y = m_yLineEdit->text().toInt();
    info.WV = m_wvLineEdit->text().toInt();
    info.UV = m_uvLineEdit->text().toInt();
    info.W = m_wLineEdit->text().toInt();
    info.HV = m_hvLineEdit->text().toInt();
    info.H = m_hLineEdit->text().toInt();
    info.DV = m_dvLineEdit->text().toInt();

    return info;
}

