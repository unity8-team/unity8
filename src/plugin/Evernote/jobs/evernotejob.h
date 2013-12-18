#ifndef EVERNOTEJOB_H
#define EVERNOTEJOB_H

#include "notesstore.h"

#include <QThread>

/* How to create a new Job type:
 * - Subclass EvernoteJob
 * - Implement startJob() in which you do the call to evernote.
 *   - No need to catch exceptions, EvernoteJob will deal with those.
 * - Define a jobDone() signal with the result parameters you need.
 *   - Keep the convention of jobDone(EvernoteConnection::ErrorCode errorCode, const QString &message [, ...])
 * - Emit jobDone() in your implementation of emitJobDone().
 *   - NOTE: emitJobDone() might be called with an error even before startJob() is triggered.
 *
 * Jobs can be enqueue()d in NotesStore.
 * They will destroy themselves when finished.
 * The jobqueue will take care about starting them.
 */
class EvernoteJob : public QThread
{
    Q_OBJECT
public:
    explicit EvernoteJob(QObject *parent = 0);
    virtual ~EvernoteJob();

    void run() final;

signals:
    void connectionLost(const QString &errorMessage);

protected:
    virtual void resetConnection() = 0;
    virtual void startJob() = 0;
    virtual void emitJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage) = 0;

    QString token();

private:
    QString m_token;
};

#endif // EVERNOTEJOB_H
