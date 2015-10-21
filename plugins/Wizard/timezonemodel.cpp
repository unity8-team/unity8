/*
 * Copyright (C) 2015 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QTimeZone>
#include <QDebug>

#include "LocalePlugin.h"
#include "timezonemodel.h"


TimeZoneModel::TimeZoneModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_roleNames = {{IdRole, "id"},
                   {Abbreviation, "abbreviation"},
                   {Country, "country"},
                   {CountryCode, "countryCode"},
                   {City, "city"},
                   {Comment, "comment"},
                   {Time, "time"}};
    init();
}

QString TimeZoneModel::selectedZoneId() const
{
    return m_selectedZoneId;
}

void TimeZoneModel::setSelectedZoneId(const QString &selectedZoneId)
{
    if (m_selectedZoneId == selectedZoneId)
        return;

    m_selectedZoneId = selectedZoneId;
    Q_EMIT selectedZoneIdChanged(selectedZoneId);
}

int TimeZoneModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_zoneIds.count();
}

QVariant TimeZoneModel::data(const QModelIndex &index, int role) const
{
    if (index.isValid()) {
        const QByteArray tzid = m_zoneIds.at(index.row());
        QTimeZone tz(tzid);

        if (!tz.isValid()) {
            qWarning() << Q_FUNC_INFO << "Invalid timezone" << tzid;
            return QVariant();
        }

        switch (role) {
        case IdRole:
            return QString(tz.id()); // to let QML compare it effortlessly with a QString
        case Abbreviation:
            return tz.abbreviation(QDateTime::currentDateTime());
        case Country:
            return LocaleAttached::countryToString(tz.country());
        case CountryCode: {
            return LocaleAttached::qlocToCountryCode(tz.country());
        }
        case City: {
            const QString cityName = QString::fromUtf8(tzid.split('/').last().replace('_', ' ')); // take the last part, replace _ by a space
            return cityName;
        }
        case Comment:
            return tz.comment();
        case Time:
            return QDateTime::currentDateTime().toTimeZone(tz).toString("h:mm");
        default:
            qWarning() << Q_FUNC_INFO << "Unsupported data role" << role;
            break;
        }
    }

    return QVariant();
}

QHash<int, QByteArray> TimeZoneModel::roleNames() const
{
    return m_roleNames;
}

void TimeZoneModel::init()
{
    beginResetModel();
    m_zoneIds = QTimeZone::availableTimeZoneIds();
    endResetModel();
}


TimeZoneFilterModel::TimeZoneFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(false);
    setSortLocaleAware(true);
    setSortRole(TimeZoneModel::City);
    m_stringMatcher.setCaseSensitivity(Qt::CaseInsensitive);
    sort(0);
}

bool TimeZoneFilterModel::filterAcceptsRow(int row, const QModelIndex &parentIndex) const
{
    if (!sourceModel()) {
        return true;
    }

    if (!m_filter.isEmpty()) { // filtering by freeform text input, cf setFilter(QString)
        const QString city = sourceModel()->index(row, 0, parentIndex).data(TimeZoneModel::City).toString();
        //const QString country = sourceModel()->index(row, 0, parentIndex).data(TimeZoneModel::Country).toString();

        if (m_stringMatcher.indexIn(city) == 0 /*|| m_stringMatcher.indexIn(country) == 0*/) { // match at the beginning of the city name
            return true;
        }
    } else if (!m_country.isEmpty()) { // filter by country code
        const QString countryCode = sourceModel()->index(row, 0, parentIndex).data(TimeZoneModel::CountryCode).toString();
        return m_country.compare(countryCode, Qt::CaseInsensitive) == 0;
    }

    return false;
}

QString TimeZoneFilterModel::filter() const
{
    return m_filter;
}

void TimeZoneFilterModel::setFilter(const QString &filter)
{
    m_filter = filter;
    m_stringMatcher.setPattern(m_filter);
    Q_EMIT filterChanged();
    invalidate();
}

QString TimeZoneFilterModel::country() const
{
    return m_country;
}

void TimeZoneFilterModel::setCountry(const QString &country)
{
    if (m_country == country)
        return;

    m_country = country;
    Q_EMIT countryChanged(country);
}