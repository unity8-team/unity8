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

#include "formattinghelper.h"

#include <QDebug>
#include <QTextBlock>
#include <QTextObject>
#include <QTextCharFormat>
#include <QTextList>

FormattingHelper::FormattingHelper(QObject *parent):
    QObject(parent),
    m_textDoc(0),
    m_formatPosition(-2)
{

}

QQuickTextDocument *FormattingHelper::textDocument() const
{
    return m_textDoc;
}

void FormattingHelper::setTextDocument(QQuickTextDocument *textDocument)
{
    if (m_textDoc) {
        disconnect(m_textDoc->textDocument());
    }

    m_textDoc = textDocument;
    emit textDocumentChanged();

    if (m_textDoc) {
        connect(m_textDoc->textDocument(), &QTextDocument::undoAvailable, this, &FormattingHelper::canUndoChanged);
        connect(m_textDoc->textDocument(), &QTextDocument::redoAvailable, this, &FormattingHelper::canRedoChanged);
        m_textCursor = textDocument->textDocument()->rootFrame()->firstCursorPosition();
        m_selectionCursor = textDocument->textDocument()->rootFrame()->firstCursorPosition();
    } else {
        m_textCursor.setPosition(0);
    }
    emit cursorPositionChanged();
}

QStringList FormattingHelper::allFontFamilies() const
{
    QFontDatabase db;
    return db.families();
}

int FormattingHelper::cursorPosition() const
{
    return m_textCursor.position();
}

void FormattingHelper::setCursorPosition(int position)
{
    if (m_textCursor.position() == m_formatPosition + 1) {
        m_textCursor.movePosition(QTextCursor::PreviousCharacter, QTextCursor::KeepAnchor);
        m_textCursor.setCharFormat(m_nextFormat);
    }
    m_textCursor.setPosition(position);
    m_formatPosition = -2;
    m_nextFormat = m_textCursor.charFormat();

    emit formatChanged();
}

int FormattingHelper::selectionStart() const
{
    return m_selectionCursor.selectionStart();
}

void FormattingHelper::setSelectionStart(int selectionStart)
{
    m_selectionCursor.setPosition(selectionStart, QTextCursor::MoveAnchor);
}

int FormattingHelper::selectionEnd() const
{
    return m_selectionCursor.selectionEnd();
}

void FormattingHelper::setSelectionEnd(int selectionEnd)
{
    m_selectionCursor.setPosition(selectionEnd, QTextCursor::KeepAnchor);
}

QString FormattingHelper::fontFamily() const
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        if (m_formatPosition != -2) {
            return m_nextFormat.font().family();
        }
        return m_textCursor.charFormat().font().family();
    } else {
        return m_selectionCursor.charFormat().font().family();
    }
}

void FormattingHelper::setFontFamily(const QString &fontFamily)
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        m_nextFormat.setFontFamily(fontFamily);
        m_formatPosition = m_textCursor.position();
    } else {
        QTextCharFormat f = m_selectionCursor.charFormat();
        f.setFontFamily(fontFamily);
        m_selectionCursor.setCharFormat(f);
    }
    emit formatChanged();
}

int FormattingHelper::fontSize() const
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        if (m_formatPosition != 2) {
            return m_nextFormat.fontPointSize();
        }
        return m_textCursor.charFormat().fontPointSize();
    } else {
        return m_selectionCursor.charFormat().fontPointSize();
    }
}

void FormattingHelper::setFontSize(qreal fontSize)
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        m_nextFormat.setFontPointSize(fontSize);
        m_formatPosition = m_textCursor.position();
    } else {
        QTextCharFormat f = m_selectionCursor.charFormat();
        f.setFontPointSize(fontSize);
        m_selectionCursor.setCharFormat(f);
    }
    emit formatChanged();
}

bool FormattingHelper::italic() const
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        if (m_formatPosition != -2) {
            return m_nextFormat.fontItalic();
        }
        return m_textCursor.charFormat().fontItalic();
    } else {
        return m_selectionCursor.charFormat().fontItalic();
    }
}

void FormattingHelper::setItalic(bool italic)
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        m_nextFormat.setFontItalic(italic);
        m_formatPosition = m_textCursor.position();
    } else {
        QTextCharFormat f = m_selectionCursor.charFormat();
        f.setFontItalic(italic);
        m_selectionCursor.setCharFormat(f);
    }
    emit formatChanged();
}

bool FormattingHelper::bold() const
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        if (m_formatPosition != -2) {
            return m_nextFormat.fontWeight() >= QFont::Bold;
        }
        return m_textCursor.charFormat().fontWeight() >= QFont::Bold;
    } else {
        return m_selectionCursor.charFormat().fontWeight() >= QFont::Bold;
    }
}

void FormattingHelper::setBold(bool bold)
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        m_nextFormat.setFontWeight(bold ? QFont::Bold : QFont::Normal);
        m_formatPosition = m_textCursor.position();
    } else {
        QTextCharFormat f = m_selectionCursor.charFormat();
        f.setFontWeight(bold ? QFont::Bold : QFont::Normal);
        m_selectionCursor.setCharFormat(f);
    }
    emit formatChanged();
}

bool FormattingHelper::underline() const
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        if (m_formatPosition != -2) {
            return m_nextFormat.fontUnderline();
        }
        return m_textCursor.charFormat().fontUnderline();
    } else {
        return m_selectionCursor.charFormat().fontUnderline();
    }
}

void FormattingHelper::setUnderline(bool underline)
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        m_nextFormat.setFontUnderline(underline);
        m_formatPosition = m_textCursor.position();
        emit formatChanged();
    } else {
        QTextCharFormat f = m_selectionCursor.charFormat();
        f.setFontUnderline(underline);
        m_selectionCursor.setCharFormat(f);
    }
}

bool FormattingHelper::strikeout() const
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        if (m_formatPosition != -2) {
            return m_nextFormat.fontStrikeOut();
        }
        return m_textCursor.charFormat().fontStrikeOut();
    } else {
        return m_selectionCursor.charFormat().fontStrikeOut();
    }
}

void FormattingHelper::setStrikeout(bool strikeout)
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        m_nextFormat.setFontStrikeOut(strikeout);
        m_formatPosition = m_textCursor.position();
    } else {
        QTextCharFormat f = m_selectionCursor.charFormat();
        f.setFontStrikeOut(strikeout);
        m_selectionCursor.setCharFormat(f);
    }
    emit formatChanged();
}

QColor FormattingHelper::color() const
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        if (m_formatPosition != -2) {
            return m_nextFormat.foreground().color();
        }
        return m_textCursor.charFormat().foreground().color();
    } else {
        return m_selectionCursor.charFormat().foreground().color();
    }
}

void FormattingHelper::setColor(const QColor &color)
{
    if (m_selectionCursor.selectedText().isEmpty()) {
        m_nextFormat.setForeground(QBrush(color));
        m_formatPosition = m_textCursor.position();
    } else {
        QTextCharFormat f = m_selectionCursor.charFormat();
        f.setForeground(QBrush(color));
        m_selectionCursor.setCharFormat(f);
    }
    emit formatChanged();
}

bool FormattingHelper::canUndo() const
{
    return m_textDoc != 0 && m_textDoc->textDocument()->isUndoAvailable();
}

bool FormattingHelper::canRedo() const
{
    return m_textDoc != 0 && m_textDoc->textDocument()->isRedoAvailable();
}

Qt::Alignment FormattingHelper::alignment() const
{
    return m_textCursor.blockFormat().alignment();
}

void FormattingHelper::setAlignment(Qt::Alignment alignment)
{
    QTextBlockFormat f = m_textCursor.blockFormat();
    f.setAlignment(alignment);
    m_textCursor.setBlockFormat(f);
    emit formatChanged();
}

void FormattingHelper::addBulletList()
{
    QTextListFormat f;
    f.setStyle(QTextListFormat::ListDisc);
    m_textCursor.insertList(f);
}

void FormattingHelper::addNumberedList()
{
    QTextListFormat f;
    f.setStyle(QTextListFormat::ListDecimal);
    m_textCursor.insertList(f);
}

void FormattingHelper::indentBlock()
{
    QTextBlockFormat f = m_textCursor.blockFormat();
    f.setIndent(f.indent() + 4);
    m_textCursor.setBlockFormat(f);
}

void FormattingHelper::unindentBlock()
{
    QTextBlockFormat f = m_textCursor.blockFormat();
    f.setIndent(f.indent() - 4);
    m_textCursor.setBlockFormat(f);
}

void FormattingHelper::undo()
{
    if (m_textDoc) {
        m_textDoc->textDocument()->undo();
    }
}

void FormattingHelper::redo()
{
    if (m_textDoc) {
        m_textDoc->textDocument()->redo();
    }
}

void FormattingHelper::addHorizontalLine()
{
    m_textCursor.beginEditBlock();
    m_textCursor.insertHtml("____________________");
    m_textDoc->textDocument()->setHtml(m_textDoc->textDocument()->toHtml().replace(QRegExp("____________________"), "<hr/><p></p>"));
    m_textCursor.endEditBlock();
}
