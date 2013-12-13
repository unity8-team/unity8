#ifndef NOTE_H
#define NOTE_H

#include <QObject>
#include <QDateTime>
#include <QStringList>

class Note : public QObject
{
    Q_OBJECT

    // Don't forget to update clone() if you add properties!
    Q_PROPERTY(QString guid READ guid CONSTANT)
    Q_PROPERTY(QString notebookGuid READ notebookGuid WRITE setNotebookGuid NOTIFY notebookGuidChanged)
    Q_PROPERTY(QDateTime created READ created CONSTANT)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(QString content READ content WRITE setContent NOTIFY contentChanged)
    Q_PROPERTY(bool reminder READ reminder WRITE setReminder NOTIFY reminderChanged)
    Q_PROPERTY(QDateTime reminderTime READ reminderTime WRITE setReminderTime NOTIFY reminderTimeChanged)
    Q_PROPERTY(bool reminderDone READ reminderDone WRITE setReminderDone NOTIFY reminderDoneChanged)
    Q_PROPERTY(QDateTime reminderDoneTime READ reminderDoneTime WRITE setReminderDoneTime NOTIFY reminderDoneChanged)
    Q_PROPERTY(bool isSearchResult READ isSearchResult NOTIFY isSearchResultChanged)
    // Don't forget to update clone() if you add properties!

public:
    explicit Note(const QString &guid, const QDateTime &created, QObject *parent = 0);

    QString guid() const;

    QString notebookGuid() const;
    void setNotebookGuid(const QString &notebookGuid);

    QDateTime created() const;

    QString title() const;
    void setTitle(const QString &title);

    QString content() const;
    void setContent(const QString &content);

    // This is the QML representation as we don't want to deal with timestamps there.
    // setting it to false will reset the reminderOrder to 0, setting it to true will
    // create a new timestamp for it.
    bool reminder() const;
    void setReminder(bool reminder);

    qint64 reminderOrder() const;
    void setReminderOrder(qint64 reminderOrder);

    QDateTime reminderTime() const;
    void setReminderTime(const QDateTime &reminderTime);

    // This is the QML representation as we don't want to deal with timestamps there.
    // setting it to false will reset reminderDoneTime to 0, setting it to true will
    // create a new timestamp for it.
    bool reminderDone() const;
    void setReminderDone(bool reminderDone);

    QDateTime reminderDoneTime() const;
    void setReminderDoneTime(const QDateTime &reminderDoneTime);

    bool isSearchResult() const;
    void setIsSearchResult(bool isSearchResult);

    Note* clone();

public slots:
    void save();
    void remove();

signals:
    void titleChanged();
    void notebookGuidChanged();
    void contentChanged();
    void reminderChanged();
    void reminderTimeChanged();
    void reminderDoneChanged();
    void isSearchResultChanged();

private:
    QString m_guid;
    QString m_notebookGuid;
    QDateTime m_created;
    QString m_title;
    QString m_content;
    qint64 m_reminderOrder;
    QDateTime m_reminderTime;
    QDateTime m_reminderDoneTime;
    bool m_isSearchResult;
};

#endif // NOTE_H
