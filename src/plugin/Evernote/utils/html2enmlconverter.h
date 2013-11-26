#ifndef HTML2ENMLCONVERTER_H
#define HTML2ENMLCONVERTER_H

#include <QString>

class Html2EnmlConverter
{
public:
    Html2EnmlConverter();

    static QString html2enml(const QString &html);
};

#endif // HTML2ENMLCONVERTER_H
