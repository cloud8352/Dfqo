#pragma once

#include "Model.h"

#include <QMainWindow>
#include <QPushButton>
#include <QVBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QCheckBox>

class SettingsDlg : public QMainWindow
{
    Q_OBJECT
public:
    SettingsDlg(Model *model, QWidget *parent = nullptr);
    ~SettingsDlg();

    void Reset();

private slots:

Q_SIGNALS:

private:

private:
    Model *m_model;
    QLineEdit *m_gameRootPathLineEdit;
};
