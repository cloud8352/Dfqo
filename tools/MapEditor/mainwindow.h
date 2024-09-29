#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include "MapWidget.h"
#include "SettingsDlg.h"
#include "SpriteTrim/SpriteTrimDlg.h"

#include <QMainWindow>
#include <QPushButton>
#include <QStandardItemModel>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

public slots:
    void OnModelItemsLoaded();

private:
    void loadTreeItems();

private:
    Model *m_model;
    QModelIndex m_lastSelectedIndex;
    SettingsDlg *m_settingsDlg;
    SpriteTrimDlg *m_spriteTrimDlg;

    QStandardItem *m_spriteTreeItem;
    QStandardItem *m_actorInstanceTreeItem;
};
#endif // MAINWINDOW_H
