#include "notebook.h"

Notebook::Notebook(QString guid, QObject *parent) :
    QObject(parent),
    m_guid(guid)
{
}

QString Notebook::guid() const
{
    return m_guid;
}

QString Notebook::name() const
{
    return m_name;
}

void Notebook::setName(const QString &name)
{
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}
