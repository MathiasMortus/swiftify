pragma ComponentBehavior: Bound
import QtQuick
import Swiftify

// Now Playing (NowPlayingPanel): the song's cover large at the top of the side
// sheet, as the spotify client has it, the title, artists and album under it,
// and the lyrics below those. soft blurred shapes in the cover's colours drift
// behind it all and swell with the bass. the cover opens the immersive player;
// the names go to their pages.
Item {
    id: root

    property MaterialScheme scheme: Appearance.colors
    /// under the immersive player: nothing moves, nothing scrolls
    property bool suspended: false
    signal immersiveRequested()

    clip: true

    readonly property bool flows: visible && !suspended && !Appearance.reduceMotion && !Appearance.performanceMode

    function shade(index: int): color {
        const palette = PlayerStyle.palette
        return palette.length > 0 ? palette[index % palette.length] : root.scheme.primary
    }

    // ticks at 30 hz while music plays, and holds where it stood on pause
    BackdropClock {
        id: clock
        running: root.flows
        playing: Player.playing
        reactivity: Settings.backdropReactivity
    }

    // the drifting shapes: sdf blurs, no layer, each on a slow loop of its own
    Item {
        id: blobs
        anchors.fill: parent
        visible: Player.hasSong
        opacity: 0.7

        Repeater {
            model: [
                { "size": 0.95, "cx": 0.30, "cy": 0.18, "ax": 0.22, "ay": 0.10, "fx": 0.11, "fy": 0.17, "phase": 0.0 },
                { "size": 0.80, "cx": 0.72, "cy": 0.40, "ax": 0.18, "ay": 0.16, "fx": 0.13, "fy": 0.09, "phase": 2.1 },
                { "size": 0.85, "cx": 0.35, "cy": 0.68, "ax": 0.20, "ay": 0.12, "fx": 0.07, "fy": 0.12, "phase": 4.2 },
                { "size": 0.70, "cx": 0.65, "cy": 0.88, "ax": 0.16, "ay": 0.08, "fx": 0.15, "fy": 0.10, "phase": 1.3 }
            ]

            delegate: SoftShadow {
                id: blob
                required property var modelData
                required property int index

                readonly property real t: clock.time
                // the bass swells them a touch, the lower two most
                readonly property real swell: 1 + 0.18 * (index < 2 ? clock.energy.y : clock.energy.x)
                readonly property real side: blobs.width * modelData.size * swell

                width: side
                height: side
                radius: side / 2
                blur: blobs.width * 0.22
                color: root.shade(index)
                x: blobs.width * (modelData.cx + modelData.ax * Math.sin(t * modelData.fx * 2 * Math.PI / 4 + modelData.phase)) - side / 2
                y: blobs.height * (modelData.cy + modelData.ay * Math.cos(t * modelData.fy * 2 * Math.PI / 4 + modelData.phase)) - side / 2

                Behavior on color {
                    ColorAnimation { duration: Appearance.duration(900); easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // the shapes sit under a veil of the sheet's own colour, so the text over
    // them keeps its contrast
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Appearance.colors.layer1, 0.35)
    }

    StyledText {
        id: header
        x: 18
        y: 16
        text: "Now Playing"
        font.pixelSize: Appearance.fontSize.normal
        font.weight: Font.DemiBold
        color: root.scheme.onSurfaceVariant
    }

    Column {
        id: info
        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        // the cover gives way to the lyrics in a short window
        width: Math.max(120, Math.min(root.width - 32, root.height * 0.38))
        spacing: 4
        visible: Player.hasSong

        Item {
            id: cover
            width: parent.width
            height: width

            SoftShadow {
                anchors.fill: parent
                radius: Appearance.sizes.artworkRadius
                blur: 16
                offset: Qt.vector2d(0, 6)
                color: Qt.rgba(0, 0, 0, 0.3)
            }

            ArtworkImage {
                anchors.fill: parent
                source: Player.currentSong.artworkUrl
                crossfade: true
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.sizes.artworkRadius
                color: Qt.rgba(0, 0, 0, coverHover.hovered ? 0.25 : 0)

                Behavior on color {
                    ColorAnimation { duration: Appearance.duration(160) }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "open_in_full"
                    iconSize: 28
                    weight: 600
                    color: "white"
                    opacity: coverHover.hovered ? 1 : 0
                }
            }

            HoverHandler {
                id: coverHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: root.immersiveRequested()
            }
        }

        Item { width: 1; height: 8 }

        TitleText {
            width: parent.width
            text: Player.currentSong.name
            elide: Text.ElideRight
            color: root.scheme.onSurface
            font.underline: titleHover.hovered && !Player.currentSong.isLocalFile

            HoverHandler {
                id: titleHover
                cursorShape: Player.currentSong.isLocalFile ? Qt.ArrowCursor : Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: if (!Player.currentSong.isLocalFile) Library.goToAlbum(Player.currentSong)
            }
        }

        StyledText {
            width: parent.width
            text: Player.currentSong.artists
            elide: Text.ElideRight
            font.pixelSize: Appearance.fontSize.small
            color: root.scheme.onSurfaceVariant
            font.underline: artistHover.hovered && !Player.currentSong.isLocalFile

            HoverHandler {
                id: artistHover
                cursorShape: Player.currentSong.isLocalFile ? Qt.ArrowCursor : Qt.PointingHandCursor
            }
            TapHandler {
                onTapped: if (!Player.currentSong.isLocalFile) Library.goToArtist(Player.currentSong)
            }
        }

        StyledText {
            width: parent.width
            visible: text.length > 0
            topPadding: 2
            text: Player.currentSong.albumName
            elide: Text.ElideRight
            font.pixelSize: Appearance.fontSize.smaller
            color: Qt.alpha(root.scheme.onSurfaceVariant, 0.75)
        }
    }

    // the lyrics fill what is left under the song
    LyricsPanel {
        id: lyrics
        anchors.top: info.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: Player.hasSong
        suspended: root.suspended || !root.visible
        scheme: root.scheme
    }

    EmptyState {
        anchors.centerIn: parent
        width: parent.width - 32
        Reveal.shown: !Player.hasSong
        symbol: "album"
        title: "Nothing Playing"
        description: "Play a song and its cover shows here."
    }
}
