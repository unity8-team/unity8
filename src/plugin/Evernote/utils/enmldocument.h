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
    QString toHtml(const QString &noteGuid) const;
    QString toRichText(const QString &noteGuid) const;
    QString toPlaintext() const;

    void setRichText(const QString &richText);

    void markTodo(const QString &todoId, bool checked);

private:
    enum Type {
        TypeRichText,
        TypeHtml
    };

    QString convert(const QString &noteGuid, Type type) const;

private:
    QString m_enml;

    static QStringList s_commonTags;
    static QStringList s_argumentBlackListTags;

};

#endif // ENMLDOCUMENT_H
