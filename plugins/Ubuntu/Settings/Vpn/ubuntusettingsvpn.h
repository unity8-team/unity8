/*
 * Copyright (C) 2016 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef UBUNTUSETTINGSVPN_H
#define UBUNTUSETTINGSVPN_H

#include <QObject>

class UbuntuSettingsVpn : public QObject
{
    Q_OBJECT


public:
    explicit UbuntuSettingsVpn(QObject* parent = nullptr);

    enum CertificateError
    {
        CERT_VALID,
        CERT_NOT_FOUND,
        CERT_EMPTY,
        CERT_SELFSIGNED,
        CERT_EXPIRED,
        CERT_BLACKLISTED
    };
    Q_ENUMS(CertificateError)

    Q_INVOKABLE CertificateError isCertificateValid(const QString &path);

private:
};

#endif // UBUNTUSETTINGSVPN_H
