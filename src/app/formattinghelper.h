/*
 * Copyright: 2014 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
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

#ifndef FORMATTINGHELPER_H
#define FORMATTINGHELPER_H

#include <QObject>
#include <QQuickTextDocument>
#include <QTextCursor>

class FormattingHelper: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList allFontFamilies READ allFontFamilies CONSTANT)

    Q_PROPERTY(QQuickTextDocument* textDocument READ textDocument WRITE setTextDocument NOTIFY textDocumentChanged)

    Q_PROPERTY(int cursorPosition READ cursorPosition WRITE setCursorPosition NOTIFY cursorPositionChanged)

    Q_PROPERTY(QString fontFamily READ fontFamily WRITE setFontFamily NOTIFY formatChanged)
    Q_PROPERTY(qreal fontSize READ fontSize WRITE setFontSize NOTIFY formatChanged)
    Q_PROPERTY(bool italic READ italic WRITE setItalic NOTIFY formatChanged)
    Q_PROPERTY(bool bold READ bold WRITE setBold NOTIFY formatChanged)
    Q_PROPERTY(bool underline READ underline WRITE setUnderline NOTIFY formatChanged)
    Q_PROPERTY(bool strikeout READ strikeout WRITE setStrikeout NOTIFY formatChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY formatChanged)
    Q_PROPERTY(Qt::Alignment alignment READ alignment WRITE setAlignment NOTIFY formatChanged)

    Q_PROPERTY(bool canUndo READ canUndo NOTIFY canUndoChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY canRedoChanged)


public:
    FormattingHelper(QObject *parent = 0);

    QStringList allFontFamilies() const;

    QQuickTextDocument* textDocument() const;
    void setTextDocument(QQuickTextDocument* textDocument);

    int cursorPosition() const;
    void setCursorPosition(int position);

    QString fontFamily() const;
    void setFontFamily(const QString &fontFamily);

    int fontSize() const;
    void setFontSize(qreal fontSize);

    bool italic() const;
    void setItalic(bool italic);

    bool bold() const;
    void setBold(bool bold);

    bool underline() const;
    void setUnderline(bool underline);

    bool strikeout() const;
    void setStrikeout(bool strikeout);

    QColor color() const;
    void setColor(const QColor &color);

    bool canUndo() const;
    bool canRedo() const;

    Qt::Alignment alignment() const;
    void setAlignment(Qt::Alignment alignment);

public slots:
    void addHorizontalLine();
    void addBulletList();
    void addNumberedList();
    void indentBlock();
    void unindentBlock();

    void undo();
    void redo();

signals:
    void textDocumentChanged();
    void cursorPositionChanged();
    void formatChanged();

    void canUndoChanged(bool canUndo);
    void canRedoChanged(bool canRedo);

private:
    QQuickTextDocument *m_textDoc;
    QTextCursor m_textCursor;

    QTextCharFormat m_nextFormat;
    int m_formatPosition;
};

#endif
