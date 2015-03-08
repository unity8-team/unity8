/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "enmldocument.h"
#include "notesstore.h"
#include "note.h"
#include "logging.h"

#include <QXmlStreamReader>
#include <QXmlStreamWriter>
#include <QStringList>
#include <QUrl>
#include <QUrlQuery>
#include <QStandardPaths>

// ENML spec: http://xml.evernote.com/pub/enml2.dtd
// QML supported HTML subset: http://qt-project.org/doc/qt-5.0/qtgui/richtext-html-subset.html

// This is the list of common tags between enml and html. We can just copy those over as they are
QStringList EnmlDocument::s_commonTags = QStringList()
        << "a" << "abbr" << "acronym" << "address" << "area" << "b" << "bdo" << "big"
        << "blockquote" << "br" << "caption" << "center" << "cite" << "code" << "col"
        << "colgroup" << "dd" << "del" << "dfn" << "div" << "dl" << "dt" << "em"
        << "en-crypt" << "en-todo" << "font" << "h1" << "h2" << "h3" << "h4" << "h5"
        << "h6" << "hr" << "i" << "ins" << "kbd" << "li" << "map" << "ol"
        << "p" << "pre" << "q" << "s" << "samp" << "small" << "span" << "strike"
        << "strong" << "sub" << "sup" << "table" << "tbody" << "td" << "tfoot"
        << "th" << "thead" << "tr" << "tt" << "u" << "ul" << "var";

// QML tends to generate more attributes than neccessary and Evernote's web editor gets confused by it.
// Let's blacklist adding attributes to given tags.
QStringList EnmlDocument::s_argumentBlackListTags = QStringList()
        << "ul" << "li" << "ol";

EnmlDocument::EnmlDocument(const QString &enml):
    m_enml(enml),
    m_renderWidth(-1)
{
}

QString EnmlDocument::enml() const
{
    return m_enml;
}

void EnmlDocument::setEnml(const QString &enml)
{
    m_enml = enml;
}

QString EnmlDocument::toHtml(const QString &noteGuid) const
{
    return convert(noteGuid, TypeHtml);
}

QString EnmlDocument::toRichText(const QString &noteGuid) const
{
    return convert(noteGuid, TypeRichText);
}

QString EnmlDocument::convert(const QString &noteGuid, EnmlDocument::Type type) const
{
    // output
    QString html;
    QXmlStreamWriter writer(&html);
    writer.writeDTD("<!DOCTYPE html>");
    writer.writeStartElement("html");
    writer.writeStartElement("head");
    writer.writeStartElement("meta");
    writer.writeAttribute("name", "viewport");
    writer.writeAttribute("content", QString("width=device-width, initial-scale=1.0"));
    writer.writeEndElement();
    writer.writeEndElement();

    // input
    QXmlStreamReader reader(m_enml);

    // state
    bool isBody = false;
    int todoIndex = 0;

    while (!reader.atEnd() && !reader.hasError()) {
        QXmlStreamReader::TokenType token = reader.readNext();
        if(token == QXmlStreamReader::StartDocument) {
            continue;
        }

        // Handle start elements
        if(token == QXmlStreamReader::StartElement) {
            // skip everything if body hasn't started yet
            if (!isBody) {
                if (reader.name() == "en-note") {
                    writer.writeStartElement("body");
                    writer.writeAttributes(reader.attributes());
                    isBody = true;
                }
                continue;
            }
            // Write supported start elements to output (including attributes)
            if (s_commonTags.contains(reader.name().toString())) {
                writer.writeStartElement(reader.name().toString());

                if (reader.name() == "p") {
                    foreach (const QXmlStreamAttribute &attribute, reader.attributes()) {
                        if (attribute.name() == "style") {
                            // Fix paragraph alignment (text-align -> align)
                            if (attribute.value().contains("text-align")) {
                                QString style = attribute.value().toString();
                                QString textAlign = style.split("text-align: ").at(1).split(';').first();
                                writer.writeAttribute("align", textAlign);
                                break;
                            }
                            if (type == TypeRichText) {
                                if (attribute.value().contains("padding-left")) {
                                    QString style = attribute.value().toString();
                                    int padding = style.split("padding-left:").at(1).split("px").first().toInt();
                                    int indent = padding / 30 * 4;
                                    style.replace(QRegExp("padding-left:[ 0-9]*px;"), "-qt-block-indent:" + QString::number(indent) + ";");
                                    writer.writeAttribute("style", style);
                                } else {
                                    writer.writeAttribute(attribute);
                                }
                            } else {
                                writer.writeAttribute(attribute);
                            }
                        } else {
                            writer.writeAttribute(attribute);
                        }
                    }
                } else {
                    writer.writeAttributes(reader.attributes());
                }
            }

            // Convert images
            if (reader.name() == "en-media") {
                QString mediaType = reader.attributes().value("type").toString();
                QString hash = reader.attributes().value("hash").toString();

                writer.writeStartElement("img");
                if (mediaType.startsWith("image")) {

                    if (type == TypeRichText) {
                        writer.writeAttribute("src", composeMediaTypeUrl(mediaType, noteGuid, hash));
                    } else if (type  == TypeHtml) {
                        if (NotesStore::instance()->note(noteGuid)->resource(hash)) {
                            QString fileName = NotesStore::instance()->note(noteGuid)->resource(hash)->fileName();
                            QString imagePath = NotesStore::instance()->storageLocation() + hash + "." + fileName.split('.').last();
                            writer.writeAttribute("src", imagePath);
                        }
                        writer.writeAttribute("id", "en-attachment/" + hash + "/" + mediaType);
                    }

                    // Set the width. We always override what's coming from Evernote and adjust it to our view.
                    // We don't even need to take care about what sizes we write back to Evernote as other
                    // Evernote clients ignore and override/change that too.
                    if (type == TypeRichText) {
                        //get the size of the original image
                        QImage image = QImage::fromData(NotesStore::instance()->note(noteGuid)->resource(hash)->data());
                        int originalWidthInGus = image.width() * gu(1) / 8;
                        int imageWidth = m_renderWidth >= 0 && originalWidthInGus > m_renderWidth ? m_renderWidth : originalWidthInGus;
                        writer.writeAttribute("width", QString::number(imageWidth));
                    } else if (type == TypeHtml) {
                        writer.writeAttribute("style", "max-width: 100%");
                    }
                } else if (mediaType.startsWith("audio")) {
                    if (type == TypeRichText) {
                        writer.writeAttribute("src", composeMediaTypeUrl(mediaType, noteGuid, hash));
                    } else if (type == TypeHtml) {
                        QString imagePath = "file:///usr/share/icons/suru/mimetypes/scalable/audio-x-generic-symbolic.svg";
                        writer.writeAttribute("src", imagePath);
                        writer.writeAttribute("id", "en-attachment/" + hash + "/" + mediaType);
                        if (NotesStore::instance()->note(noteGuid)->resource(hash)) {
                            writer.writeCharacters(NotesStore::instance()->note(noteGuid)->resource(hash)->fileName());
                        }
                    }
                } else if (mediaType == "application/pdf") {
                    if (type == TypeRichText) {
                        writer.writeAttribute("src", composeMediaTypeUrl(mediaType, noteGuid, hash));
                    } else if (type == TypeHtml) {
                        QString imagePath = "file:///usr/share/icons/suru/mimetypes/scalable/application-pdf-symbolic.svg";
                        writer.writeAttribute("src", imagePath);
                        writer.writeAttribute("id", "en-attachment/" + hash + "/" + mediaType);
                        if (NotesStore::instance()->note(noteGuid)->resource(hash)) {
                            writer.writeCharacters(NotesStore::instance()->note(noteGuid)->resource(hash)->fileName());
                        }
                    }
                } else {
                    qCWarning(dcEnml) << "Unknown mediatype" << mediaType;
                    if (type == TypeRichText) {
                        writer.writeAttribute("src", composeMediaTypeUrl(mediaType, noteGuid, hash));
                    } else if (type == TypeHtml) {
                        QString imagePath = "file:///usr/share/icons/suru/mimetypes/scalable/empty-symbolic.svg";
                        writer.writeAttribute("src", imagePath);
                        writer.writeAttribute("id", "en-attachment/" + hash + "/" + mediaType);
                        if (NotesStore::instance()->note(noteGuid)->resource(hash)) {
                            writer.writeCharacters(NotesStore::instance()->note(noteGuid)->resource(hash)->fileName());
                        }
                    }
                }
            }

            // Convert todo checkboxes
            if (reader.name() == "en-todo") {
                bool checked = false;
                foreach(const QXmlStreamAttribute &attr, reader.attributes().toList()) {
                    if (attr.name() == "checked" && attr.value() == "true") {
                        checked = true;
                    }
                }

                if (type == TypeRichText) {
                    writer.writeStartElement("img");
                    writer.writeAttribute("src", checked ? "image://theme/select" : "../images/unchecked.svg");
                    writer.writeAttribute("height", QString::number(gu(2)));
                } else if (type == TypeHtml){
                    writer.writeStartElement("input");
                    writer.writeAttribute("id", "en-todo/" + QString::number(todoIndex++));
                    writer.writeAttribute("type", "checkbox");
                    if (checked) {
                        writer.writeAttribute("checked", "true");
                    }
                }
            }

            // We can't just copy over img tags with s_commonTags, because we generate img tags on our own.
            // Lets copy them manually
            if (reader.name() == "img") {
                writer.writeStartElement("img");
                writer.writeAttributes(reader.attributes());
            }

        }

        // Write *all* normal text inside <body> </body> to output
        if (isBody && token == QXmlStreamReader::Characters) {
            writer.writeCharacters(reader.text().toString());
        }

        // handle end elements
        if (token == QXmlStreamReader::EndElement) {

            // skip everything after body
            if (reader.name() == "en-note") {
                writer.writeEndElement();
                isBody = false;
                break;
            }

            // Write closing tags for supported elements
            if (s_commonTags.contains(reader.name().toString())
                    || reader.name() == "en-media"
                    || reader.name() == "en-todo"
                    || reader.name() == "img") {
                writer.writeEndElement();
            }
        }
    }

    writer.writeEndElement();
    writer.writeEndDocument();
    qCDebug(dcEnml) << QString("Converted to %1:").arg(type == TypeHtml ? "HTML" : "RichText") << html;
    return html;
}

qreal EnmlDocument::gu(qreal px) const
{
    QByteArray ppguString = qgetenv("GRID_UNIT_PX");
    int ppgu = ppguString.toInt();
    if (ppgu == 0) {
        ppgu = 8;
    }
    return px * ppgu;
}

QString EnmlDocument::composeMediaTypeUrl(const QString &mediaType, const QString &noteGuid, const QString &hash) const
{
    QUrl url("image://resource/" + mediaType);
    QUrlQuery arguments;
    arguments.addQueryItem("noteGuid", noteGuid);
    arguments.addQueryItem("hash", hash);
    arguments.addQueryItem("loaded", NotesStore::instance()->note(noteGuid)->resource(hash)->isCached() ? "true" : "false");
    url.setQuery(arguments);
    return url.toString();
}

void EnmlDocument::setRichText(const QString &richText)
{
    // output
    m_enml.clear();

    QXmlStreamWriter writer(&m_enml);
    writer.writeStartDocument();
    writer.writeDTD("<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">");

    if (richText.isEmpty()) {
        writer.writeStartElement("en-note");
        writer.writeEndElement();
    }

    // input
    QXmlStreamReader reader(richText);

    // state
    bool isBody = false;

    while (!reader.atEnd() && !reader.hasError()) {
        QXmlStreamReader::TokenType token = reader.readNext();
        if(token == QXmlStreamReader::StartDocument) {
            continue;
        }

        // Handle start elements
        if(token == QXmlStreamReader::StartElement) {
            // skip everything if body hasn't started yet
            if (!isBody) {
                if (reader.name() == "body") {
                    writer.writeStartElement("en-note");
                    isBody = true;
                }
                continue;
            }

            // Write supported start elements to output (including attributes)
            if (s_commonTags.contains(reader.name().toString())) {
                writer.writeStartElement(reader.name().toString());
                if (!s_argumentBlackListTags.contains(reader.name().toString())) {

                    if (reader.name() == "p") {
                        foreach (const QXmlStreamAttribute &attribute, reader.attributes()) {
                            if (attribute.name() == "style") {
                                if (attribute.value().contains("-qt-block-indent")) {
                                    QString style = attribute.value().toString();
                                    int indent = style.split("-qt-block-indent:").at(1).split(";").first().toInt();
                                    int padding = indent / 4 * 30;
                                    style.replace(QRegExp("-qt-block-indent:[0-9]*;"), "padding-left:" + QString::number(padding) + "px;");
                                    writer.writeAttribute("style", style);
                                } else {
                                    writer.writeAttribute(attribute);
                                }
                            } else {
                                writer.writeAttribute(attribute);
                            }
                        }
                    } else {
                        writer.writeAttributes(reader.attributes());
                    }
                }
            }

            if (reader.name() == "img") {
                QUrl imageUrl = QUrl(reader.attributes().value("src").toString());
                if (imageUrl.authority() == "resource") {
                    QString type = imageUrl.path().remove(QRegExp("^/"));

                    QUrlQuery arguments(imageUrl.query());
                    QString hash = arguments.queryItemValue("hash");

                    writer.writeStartElement("en-media");
                    writer.writeAttribute("hash", hash);
                    writer.writeAttribute("type", type);
                } else if (imageUrl.authority() == "theme" || imageUrl.path() == "../images/unchecked.svg") {
                    writer.writeStartElement("en-todo");
                    writer.writeAttribute("checked", imageUrl.path() == "/select" ? "true" : "false");
                } else {
                    writer.writeStartElement("img");
                    writer.writeAttributes(reader.attributes());
                }
            }
        }


        // Write *all* normal text inside <body> </body> to output
        if (isBody && token == QXmlStreamReader::Characters) {
            writer.writeCharacters(reader.text().toString());
        }

        // handle end elements
        if (token == QXmlStreamReader::EndElement) {

            // skip everything after body
            if (reader.name() == "body") {
                writer.writeEndElement();
                isBody = false;
                break;
            }

            // Write closing tags for supported elements
            if (s_commonTags.contains(reader.name().toString())) {
                writer.writeEndElement();
            }

            if (reader.name() == "img") {
                writer.writeEndElement();
            }
        }
    }

    writer.writeEndDocument();
}

void EnmlDocument::markTodo(const QString &todoId, bool checked)
{
    QXmlStreamReader reader(m_enml);

    QString output;
    QXmlStreamWriter writer(&output);
    writer.writeStartDocument();
    writer.writeDTD("<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">");

    QString tmp = todoId;
    int todoIndex = tmp.toInt();
    int todoCounter = 0;

    while (!reader.atEnd() && !reader.hasError()) {
        QXmlStreamReader::TokenType token = reader.readNext();

        if (token == QXmlStreamReader::StartElement) {
            writer.writeStartElement(reader.name().toString());

            if (reader.name() == "en-todo" && todoCounter++ == todoIndex) {
                if (checked) {
                    writer.writeAttribute("checked", "true");
                }
            } else {
                writer.writeAttributes(reader.attributes());
            }
        }

        if (token == QXmlStreamReader::Characters) {
            writer.writeCharacters(reader.text().toString());
        }
        if (token == QXmlStreamReader::EndElement) {
            writer.writeEndElement();
        }
    }
    m_enml = output;
}

int EnmlDocument::renderWidth() const
{
    return m_renderWidth;
}

void EnmlDocument::setRenderWidth(int renderWidth)
{
    m_renderWidth = renderWidth;
}

void EnmlDocument::attachFile(int position, const QString &hash, const QString &type)
{
    QXmlStreamReader reader(m_enml);

    QString output;
    QXmlStreamWriter writer(&output);
    writer.writeStartDocument();
    writer.writeDTD("<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">");

    int textPos = 0;
    bool inserted = false;

    while (!reader.atEnd() && !reader.hasError()) {
        QXmlStreamReader::TokenType token = reader.readNext();

        if (token == QXmlStreamReader::StartElement) {
            writer.writeStartElement(reader.name().toString());
            writer.writeAttributes(reader.attributes());
        }

        if (token == QXmlStreamReader::Characters) {
            QString textString = reader.text().toString();
            if (textPos <= position && textPos + textString.length() > position) {
                writer.writeCharacters(textString.left(position - textPos));

                writer.writeStartElement("en-media");
                writer.writeAttribute("hash", hash);
                writer.writeAttribute("type", type);
                writer.writeEndElement();
                inserted = true;

                writer.writeCharacters(textString.right(textString.length() - (position - textPos)));
            } else {
                writer.writeCharacters(reader.text().toString());
            }
            textPos += textString.length();
        }
        if (token == QXmlStreamReader::EndElement) {

            // The above logic would fail on an empty note
            if (reader.name() == "en-note" && !inserted) {
                writer.writeStartElement("en-media");
                writer.writeAttribute("hash", hash);
                writer.writeAttribute("type", type);
                writer.writeEndElement();
            }

            writer.writeEndElement();
        }
    }
    m_enml = output;
}

QString EnmlDocument::toPlaintext() const
{
    // output
    QString plaintext;

    // input
    QXmlStreamReader reader(m_enml);

    while (!reader.atEnd() && !reader.hasError()) {
        QXmlStreamReader::TokenType token = reader.readNext();

        // Write all normal text inside <body> </body> to output
        if (token == QXmlStreamReader::Characters) {
            plaintext.append(reader.text().toString());
            plaintext.append(' ');
        }
    }

    plaintext.remove('\n').trimmed();
    return plaintext;
}
