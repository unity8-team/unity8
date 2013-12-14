#ifndef ENMLDOCUMENT_H
#define ENMLDOCUMENT_H

#include <QString>

class EnmlDocument
{
public:
    EnmlDocument(const QString &enml = QString());

    QString enml() const;
    void setEnml(const QString &enml);

    // noteGuid is required to convert en-media tags to urls for image provider
    QString html(const QString &noteGuid) const;
    void setHtml(const QString &html);

    QString plaintext() const;

private:
    QString m_enml;

    static QStringList s_commonTags;
    static QStringList s_argumentBlackListTags;

};

#endif // ENMLDOCUMENT_H
