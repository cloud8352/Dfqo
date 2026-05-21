#pragma once

#include "../Model.h"

#include <QMainWindow>
#include <QPushButton>
#include <QVBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QTextEdit>

class MapActorsMirroringDlg : public QMainWindow
{
    Q_OBJECT
public:
    MapActorsMirroringDlg(Model *model, QWidget *parent = nullptr);
    ~MapActorsMirroringDlg();

private slots:

Q_SIGNALS:
private:
    QString getCfgFilePathByFileDlg();

private:
    Model *m_model;
};
