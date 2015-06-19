/*
 * Copyright (C) 2014 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 * Jonas G. Drange <jonas.drange@canonical.com>
 *
*/
import QtQuick 2.0

Item {


    /*
        The mapping of code to string is taken from
        http://bazaar.launchpad.net/~vcs-imports/
            network-manager/trunk/view/head:/cli/src/common.c

        NetworkManager documentation: https://developer.gnome.org/
            NetworkManager/0.9/spec.html#type-NM_DEVICE_STATE_REASON
    */
    function reasonToString (reason) {
        switch (reason) {
            case 0:
                return i18n.tr("Unknown error");
            case 1:
                return i18n.tr("No reason given");
            case 2:
                return i18n.tr("Device is now managed");
            case 3:
                return i18n.tr("Device is now unmanaged");
            case 4:
                return i18n.tr("The device could not be readied for configuration");
            case 5:
                return i18n.tr("IP configuration could not be reserved (no available address, timeout, etc.)");
            case 6:
                return i18n.tr("The IP configuration is no longer valid");
            case 7:
                return i18n.tr("Your authentication details were incorrect");
            case 8:
                return i18n.tr("802.1X supplicant disconnected");
            case 9:
                return i18n.tr("802.1X supplicant configuration failed");
            case 10:
                return i18n.tr("802.1X supplicant failed");
            case 11:
                return i18n.tr("802.1X supplicant took too long to authenticate");
            case 15:
                return i18n.tr("DHCP client failed to start");
            case 16:
                return i18n.tr("DHCP client error");
            case 17:
                return i18n.tr("DHCP client failed");
            case 18:
                return i18n.tr("Shared connection service failed to start");
            case 19:
                return i18n.tr("Shared connection service failed");
            case 35:
                return i18n.tr("Necessary firmware for the device may be missing");
            case 36:
                return i18n.tr("The device was removed");
            case 37:
                return i18n.tr("NetworkManager went to sleep");
            case 38:
                return i18n.tr("The device's active connection disappeared");
            case 39:
                return i18n.tr("Device disconnected by user or client");
            case 41:
                return i18n.tr("The device's existing connection was assumed");
            case 42:
                return i18n.tr("The supplicant is now available");
            case 43:
                return i18n.tr("The modem could not be found");
            case 44:
                return i18n.tr("The Bluetooth connection failed or timed out");
            case 50:
                return i18n.tr("A dependency of the connection failed");
            case 52:
                return i18n.tr("ModemManager is unavailable");
            case 53:
                return i18n.tr("The Wi-Fi network could not be found");
            case 54:
                return i18n.tr("A secondary connection of the base connection failed");
            default:
                return i18n.tr("Unknown");
        }
    }
}
