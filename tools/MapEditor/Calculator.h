#pragma once

#include <QtCore>

class Calculator
{
public:
    Calculator();

    static double Calculate(QString expression);
};
