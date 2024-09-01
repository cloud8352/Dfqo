#pragma once

#include "Model.h"

#include <QMainWindow>
#include <QPushButton>
#include <QVBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QCheckBox>

class MapSettingsDlg : public QMainWindow
{
    Q_OBJECT
public:
    MapSettingsDlg(QWidget *parent = nullptr);
    ~MapSettingsDlg();

    void SetMapBaseInfo(const MapBaseInfoStruct &mapBaseInfo);
    void SetMapScopeInfo(const MapScopeInfoStruct &mapScopeInfo);

private slots:
    void onBaseInfoUiDataChanged();
    void onScopeInfoUiDataChanged();

Q_SIGNALS:
    void MapBaseInfoChanged(const MapBaseInfoStruct &mapBaseInfo);
    void MapScopeInfoChanged(const MapScopeInfoStruct &mapScopeInfo);

private:
    QHBoxLayout *createKeyValueLayout(const QString &keyStr, QWidget *w);
    MapBaseInfoStruct getMapBaseInfoFromUi();
    MapScopeInfoStruct getMapScopeInfoFromUi();

private:
    // base info
    QLineEdit *m_widthLineEdit;
    QLineEdit *m_heightLineEdit;
    QLineEdit *m_horizonLineEdit;
    QLineEdit *m_nameLineEdit;
    QLineEdit *m_bgmLineEdit;
    QLineEdit *m_bgsLineEdit;
    QLineEdit *m_themeLineEdit;
    QCheckBox *m_isTownCheckBox;
    QLineEdit *m_nearBgTranslateRateLineEdit;

    // scope info
    QLineEdit *m_xLineEdit;
    QLineEdit *m_yLineEdit;
    QLineEdit *m_wvLineEdit;
    QLineEdit *m_uvLineEdit;
    QLineEdit *m_wLineEdit;
    QLineEdit *m_hvLineEdit;
    QLineEdit *m_hLineEdit;
    QLineEdit *m_dvLineEdit;
};
