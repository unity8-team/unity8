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
#include "ubuntusettingsvpn.h"

#include <QDateTime>
#include <QDebug>
#include <QSslCertificate>


UbuntuSettingsVpn::UbuntuSettingsVpn(QObject* parent)
    : QObject(parent)
{
}

UbuntuSettingsVpn::CertificateError UbuntuSettingsVpn::isCertificateValid(const QString &path)
{
    QList<QSslCertificate> certs = QSslCertificate::fromPath(path);

    if (certs.size() == 0 || certs.size() > 1) {
        qWarning() << "None or multiple certificates found at" << path;
        return UbuntuSettingsVpn::CertificateError::CERT_NOT_FOUND;
    }

    QSslCertificate cert = certs.at(0);

    if (cert.isBlacklisted()) {
        return UbuntuSettingsVpn::CertificateError::CERT_BLACKLISTED;
    } else if (cert.isSelfSigned()) {
        return UbuntuSettingsVpn::CertificateError::CERT_SELFSIGNED;
    } else if (cert.expiryDate() < QDateTime::currentDateTime()) {
        return UbuntuSettingsVpn::CertificateError::CERT_EXPIRED;
    } else if (cert.isNull()) {
        return UbuntuSettingsVpn::CertificateError::CERT_EMPTY;
    }

    return UbuntuSettingsVpn::CertificateError::CERT_VALID;
}
