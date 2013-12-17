#include "enmldocument.h"

#include <QXmlStreamReader>
#include <QXmlStreamWriter>
#include <QStringList>
#include <QUrl>
#include <QUrlQuery>
#include <QStandardPaths>
#include <QDebug>

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
    m_enml(enml)
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
    writer.writeStartDocument();

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
                    isBody = true;
                }
                continue;
            }
            // Write supported start elements to output (including attributes)
            if (s_commonTags.contains(reader.name().toString())) {
                writer.writeStartElement(reader.name().toString());

                writer.writeAttributes(reader.attributes());

                // Fix paragraph alignment (text-align -> align)
                if (reader.name() == "p") {
                    foreach (const QXmlStreamAttribute &attribute, reader.attributes()) {
                        if (attribute.name() == "style" && attribute.value().contains("text-align")) {
                            QString style = attribute.value().toString();
                            QString textAlign = style.split("text-align: ").at(1).split(';').first();
                            writer.writeAttribute("align", textAlign);
                            break;
                        }
                    }
                }
            }

            // Convert images
            // TODO: what to do with music files etc?
            if (reader.name() == "en-media") {
                writer.writeStartElement("img");

                if (type == TypeRichText) {
                    QUrl url("image://resource/" + reader.attributes().value("type").toString());
                    QUrlQuery arguments;
                    arguments.addQueryItem("noteGuid", noteGuid);
                    arguments.addQueryItem("hash", reader.attributes().value("hash").toString());
                    url.setQuery(arguments);
                    writer.writeAttribute("src", url.toString());
                } else if (type  == TypeHtml) {
                    QString hash = reader.attributes().value("hash").toString();
                    QString type = reader.attributes().value("type").toString();
                    QString imagePath = QStandardPaths::standardLocations(QStandardPaths::CacheLocation).first() + "/" + hash + "." + type.split('/').last();
                    writer.writeAttribute("src", imagePath);
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
                    writer.writeAttribute("src", checked ? "image://theme/select" : "image://theme/help");
                } else if (type == TypeHtml){
                    writer.writeStartElement("input");
                    writer.writeAttribute("id", "en-todo" + QString::number(todoIndex++));
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

    writer.writeEndDocument();
    return html;
}

void EnmlDocument::setRichText(const QString &html)
{
    // output
    m_enml.clear();
    QXmlStreamWriter writer(&m_enml);
    writer.writeStartDocument();
    writer.writeDTD("<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">");

    // input
    QXmlStreamReader reader(html);

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
                    writer.writeAttributes(reader.attributes());
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
                } else if (imageUrl.authority() == "theme") {
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
    int todoIndex = tmp.remove("en-todo").toInt();
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

    plaintext.remove('\n');
    return plaintext;
}
