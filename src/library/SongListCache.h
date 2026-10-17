#pragma once

#include "spotify/SpotifyTypes.h"

#include <QList>
#include <QString>

#include <optional>

namespace swiftify {

/// the songs of a playlist (or the saved songs) as they were last loaded, kept
/// on disk so a list opened after a restart shows at once rather than after
/// the dozens of pages spotify sends it in. what is shown from here is
/// refreshed from spotify underneath, so a stale list only lasts a moment.
/// it is a cache: anything unreadable is treated as missing.
class SongListCache {
public:
    /// keeps its files under `directory`, made when first written to
    explicit SongListCache(QString directory);

    std::optional<QList<Song>> load(const QString &key) const;
    void save(const QString &key, const QList<Song> &songs) const;
    void remove(const QString &key) const;
    /// everything, as when the person signs out
    void clear() const;

private:
    QString pathFor(const QString &key) const;

    QString m_directory;
};

} // namespace swiftify
