#include "Calculator.h"

Calculator::Calculator() {}

/*获取操作符优先级*/
int priority(QString data)
{
    int priority;
    if(data == "(")
        priority = 1;
    else if(data == "+" || data == "-")
        priority = 2;
    else if(data == "*" || data == "/")
        priority = 3;
    else if (data == ")")
        priority = 4;
    else
        priority = -1;
    return priority;
}

/*将表达式的数据，操作符分割，依次存入mask_buffer数组中*/
int maskData(QString expression, QString *mask_buffer)
{
    int i,k = 0, cnt = 0;
    QString::iterator p = expression.begin();
    int length = expression.length();
    for(i = 0 ; i < length; i += cnt, k++)
    {
        cnt = 0;
        if(*p >= '0' && *p <= '9')
        {
            QString temp = *p;
            p ++;
            cnt ++;
            while((*p >= '0' && *p <= '9') || *p == '.')
            {
                temp += *p;
                p++;
                cnt ++;
            }
            mask_buffer[k] = temp;
        }else{
            QString temp = *p;
            p++;
            cnt ++;
            mask_buffer[k] = temp;
        }
    }
    return k;
}

/*将获取到的分割好的表达式数组，转化为逆波兰表达式，存入数组repolish中*/
int repolish(QString *mask_buffer, QString *repolishArray, int length)
{
    QStack<QString> st2;
    int i = 0;
    for(int j = 0; j < length; j++)
    {
        if(mask_buffer[j] != "(" && mask_buffer[j] != ")" && mask_buffer[j] != "+" && mask_buffer[j] != "-" && mask_buffer[j] != "*" && mask_buffer[j] != "/" )
            repolishArray[i++] = mask_buffer[j];
        else if(mask_buffer[j] == "("){
            st2.push(mask_buffer[j]);
        }
        else if(mask_buffer[j] == ")"){
            while(st2.top() != "(")
            {
                repolishArray[i++] = st2.top();
                st2.pop();
            }
            if(st2.top() == "(")
                st2.pop();
        }
        else if(st2.empty() || priority(mask_buffer[j]) > priority(st2.top()))
            st2.push(mask_buffer[j]);
        else{
            while(priority(mask_buffer[j]) <= priority(st2.top()))
            {
                repolishArray[i++] = st2.top();
                st2.pop();
                if(st2.empty())
                    break;
            }
            st2.push(mask_buffer[j]);
        }
    }
    while(!st2.empty())
    {
        repolishArray[i++] = st2.top();
        st2.pop();
    }
    return i;
}

/*计算逆波兰表达式值并显示*/
double repolishCalculat(QString *repolishArray, int length)
{
    QStack <double> st;
    for(int m = 0; m < length; m++)
    {
        if(repolishArray[m] != "+" && repolishArray[m] != "-" && repolishArray[m] != "*" && repolishArray[m] != "/" )
        {
            st.push(repolishArray[m].toDouble());
        }
        else
        {
            if(repolishArray[m] == "+")
            {
                double a = st.top();
                st.pop();
                double b = st.top();
                st.pop();
                st.push(b + a);
            }
            else if(repolishArray[m] == "-")
            {
                double a = st.top();
                st.pop();
                double b = st.top();
                st.pop();
                st.push(b - a);
            }
            else if(repolishArray[m] == "*")
            {
                double a = st.top();
                st.pop();
                double b = st.top();
                st.pop();
                st.push(b * a);
            }
            else if(repolishArray[m] == "/")
            {
                double a = st.top();
                st.pop();
                double b = st.top();
                st.pop();
                if(a != 0)
                    st.push(b/a);
                else
                {
                    return -1;
                }
            }
        }
    }
    QString res = QString::number(st.top(), 'g', 10);
    return st.top();
}

/*表达式计算整合*/
double Calculator::Calculate(QString expression)
{
    if (!expression.isEmpty() && !expression.front().isDigit()) {
        expression.insert(0, "0");
    }

    QString mask_buffer[100] = {"0"}, repolishArray[100]={"0"};
    int length = maskData(expression, mask_buffer);
    length = repolish(mask_buffer, repolishArray, length);
    double result = repolishCalculat(repolishArray, length);
    return result;
}
