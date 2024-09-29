#pragma once

#include "../Model.h"

#include <QMainWindow>
#include <QPushButton>
#include <QVBoxLayout>
#include <QListView>
#include <QStandardItemModel>
#include <QStandardItem>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>

class SpriteTrimDlg : public QMainWindow
{
    Q_OBJECT
public:
    SpriteTrimDlg(Model *model, QWidget *parent = nullptr);
    ~SpriteTrimDlg();

private slots:

Q_SIGNALS:
private:
    QStringList getFilePathListByFileDlg();
    void loadToListViewModel(QStandardItemModel *itemModel, const QStringList &filePathList);

private:
    Model *m_model;
};
