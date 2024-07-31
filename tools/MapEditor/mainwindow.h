#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include "MapWidget.h"

#include <QMainWindow>
#include <QPushButton>
#include <QStandardItemModel>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private:
    QModelIndex m_lastSelectedIndex;
};
#endif // MAINWINDOW_H
