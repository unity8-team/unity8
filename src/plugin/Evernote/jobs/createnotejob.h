#ifndef CREATENOTEJOB_H
#define CREATENOTEJOB_H

#include "notesstorejob.h"

class CreateNoteJob : public NotesStoreJob
{
    Q_OBJECT
public:
    explicit CreateNoteJob(const QString &title, const QString &notebookGuid, const QString &content, QObject *parent = 0);

signals:
    void jobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, evernote::edam::Note note);

protected:
    void startJob();
    void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

private:
    QString m_title;
    QString m_notebookGuid;
    QString m_content;

    evernote::edam::Note m_resultNote;
};

#endif // CREATENOTEJOB_H
