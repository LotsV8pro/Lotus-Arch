import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    settingsPageIndex: 30
    settingsPageName: Translation.tr("Presets")

    property list<var> onlinePresets: []
    property string onlinePresetsError: ""
    property bool onlinePresetsLoading: false

    // Presets visible once downloaded into the imported folder
    property var pendingOnlinePresets: {
        const downloadedNames = new Set()
        for (let i = 0; i < Presets.onlineFolderModel.count; i++) {
            downloadedNames.add(Presets.onlineFolderModel.get(i, "fileName").replace(".json", ""))
        }
        return page.onlinePresets.filter(p => !downloadedNames.has(p.name))
    }

    function onlinePresetsRepo() {
        return Config.options?.settingsUi?.onlinePresetsRepo ?? "Blapples/wallpapers"
    }

    function refreshOnlinePresets() {
        page.onlinePresetsLoading = true
        page.onlinePresetsError = ""
        onlinePresetsListProc.command = ["curl", "-sSL", "-w", "\nHTTP_STATUS:%{http_code}",
            "-H", "Accept: application/vnd.github+json",
            "-H", "User-Agent: lotus-iNIR-quickshell",
            `https://api.github.com/repos/${page.onlinePresetsRepo()}/git/trees/main?recursive=1`]
        onlinePresetsListProc.running = true
    }

    function rawPresetUrl(path) {
        const repo = page.onlinePresetsRepo()
        return `https://raw.githubusercontent.com/${repo}/main/${path.split("/").map(encodeURIComponent).join("/")}`
    }

    function onlinePresetsDir() {
        return `${Quickshell.env("HOME")}/.cache/quickshell/presets`
    }

    function assetCacheDir(name) {
        return `${page.onlinePresetsDir()}/assets/${name}`
    }

    function shQuote(str) {
        return "'" + String(str).replace(/'/g, "'\"'\"'") + "'"
    }

    function startOnlineAssetsFetch(name, stagingJsonPath, folderAssets, wallpaperFiles) {
        const dir = page.assetCacheDir(name)
        presetAssetsFetchProc.entryName = name
        presetAssetsFetchProc.stagingJsonPath = stagingJsonPath
        presetAssetsFetchProc.assetCacheDirPath = dir

        const wallpaperAssets = wallpaperFiles.map(f => ({ filename: f.split("/").pop(), url: page.rawPresetUrl(f) }))
        const seen = new Set()
        const toDownload = [...wallpaperAssets, ...folderAssets].filter(a => {
            if (seen.has(a.filename)) return false
            seen.add(a.filename)
            return true
        })
        presetAssetsFetchProc.assetFilenames = toDownload.map(a => a.filename)

        let cmd = `mkdir -p ${page.shQuote(dir)}`
        for (const asset of toDownload) {
            cmd += ` && curl -sSL ${page.shQuote(asset.url)} -o ${page.shQuote(dir + "/" + asset.filename)}`
        }
        presetAssetsFetchProc.command = ["bash", "-c", cmd]
        presetAssetsFetchProc.running = true
    }

    function downloadOnlinePreset(entry) {
        page.onlinePresetsError = ""
        const stagingJsonPath = `${page.onlinePresetsDir()}/.${entry.name}.online.json.tmp`
        presetJsonFetchProc.entryName = entry.name
        presetJsonFetchProc.entryAssets = entry.assets
        presetJsonFetchProc.metaUrl = entry.metaUrl
        presetJsonFetchProc.stagingJsonPath = stagingJsonPath
        presetJsonFetchProc.command = ["bash", "-c",
            `mkdir -p ${page.shQuote(page.onlinePresetsDir())} && curl -sSL ${page.shQuote(entry.jsonUrl)} -o ${page.shQuote(stagingJsonPath)}`]
        presetJsonFetchProc.running = true
    }

    Component.onCompleted: {
        if (Presets.folderModel.count === 0) {
            Presets.ensureInitial("2B", "Configuración actual")
        }
        if (Config.options.settingsUi?.onlinePresets ?? false) page.refreshOnlinePresets()
    }

    // ── Processes ─────────────────────────────────────────────────────
    Process {
        id: onlinePresetsListProc
        stdout: StdioCollector { id: onlinePresetsListCollector }
        onExited: (code) => {
            page.onlinePresetsLoading = false
            const raw = onlinePresetsListCollector.text
            const statusMatch = raw.match(/HTTP_STATUS:(\d+)\s*$/)
            const httpStatus = statusMatch ? parseInt(statusMatch[1]) : -1
            const body = statusMatch ? raw.slice(0, statusMatch.index) : raw
            try {
                const data = JSON.parse(body)
                if (!Array.isArray(data.tree)) throw new Error("unexpected response")

                const prefix = "presets/"
                const imageExt = /\.(png|jpe?g|webp)$/i
                const groups = {}

                for (const entry of data.tree) {
                    if (entry.type !== "blob") continue
                    if (!entry.path.startsWith(prefix)) continue
                    const rel = entry.path.slice(prefix.length)
                    const slashIdx = rel.indexOf("/")
                    if (slashIdx === -1) continue
                    const folder = rel.slice(0, slashIdx)
                    const filename = rel.slice(slashIdx + 1)
                    if (filename.includes("/")) continue

                    if (!groups[folder]) groups[folder] = { images: [], assets: [], jsonPath: "", metaPath: "" }
                    if (filename.toLowerCase() === "meta.json") {
                        groups[folder].metaPath = entry.path
                    } else if (/\.json$/i.test(filename)) {
                        groups[folder].jsonPath = entry.path
                    } else {
                        groups[folder].assets.push({ path: entry.path, filename })
                        if (imageExt.test(filename)) {
                            groups[folder].images.push({ path: entry.path, filename })
                        }
                    }
                }

                const presets = []
                for (const folder in groups) {
                    const g = groups[folder]
                    if (!g.jsonPath || g.images.length === 0) continue

                    const exactPreview = /^preview\.png$/i
                    const genericPreview = /^preview?\.png$/i
                    const nonGeneric = g.images.filter(img => !genericPreview.test(img.filename))
                    const mainCandidates = nonGeneric.length > 0 ? nonGeneric : g.images

                    const main = g.images.find(img => exactPreview.test(img.filename))
                        || mainCandidates.find(img => /desktop/i.test(img.filename))
                        || mainCandidates.find(img => !/pfp|avatar|banner/i.test(img.filename))
                        || mainCandidates[0]

                    presets.push({
                        name: folder,
                        title: folder.replace(/[-_]+/g, " ").replace(/\b\w/g, c => c.toUpperCase()),
                        jsonUrl: page.rawPresetUrl(g.jsonPath),
                        metaUrl: g.metaPath ? page.rawPresetUrl(g.metaPath) : "",
                        screenshot: page.rawPresetUrl(main.path),
                        assets: g.assets.map(a => ({ filename: a.filename, url: page.rawPresetUrl(a.path) })),
                    })
                }
                presets.sort((a, b) => a.title.localeCompare(b.title))
                page.onlinePresets = presets
            } catch (e) {
                page.onlinePresets = []
                page.onlinePresetsError = Translation.tr("Failed to load online presets")
            }
        }
    }

    Process {
        id: presetJsonFetchProc
        property string entryName: ""
        property var entryAssets: []
        property string metaUrl: ""
        property string stagingJsonPath: ""
        onExited: (code) => {
            if (code !== 0) {
                page.onlinePresetsError = Translation.tr("Failed to download preset")
                return
            }
            if (presetJsonFetchProc.metaUrl !== "") {
                presetMetaFetchProc.entryName = presetJsonFetchProc.entryName
                presetMetaFetchProc.entryAssets = presetJsonFetchProc.entryAssets
                presetMetaFetchProc.stagingJsonPath = presetJsonFetchProc.stagingJsonPath
                presetMetaFetchProc.command = ["curl", "-sSL", presetJsonFetchProc.metaUrl]
                presetMetaFetchProc.running = true
            } else {
                page.startOnlineAssetsFetch(presetJsonFetchProc.entryName, presetJsonFetchProc.stagingJsonPath, presetJsonFetchProc.entryAssets, [])
            }
        }
    }

    Process {
        id: presetMetaFetchProc
        property string entryName: ""
        property var entryAssets: []
        property string stagingJsonPath: ""
        stdout: StdioCollector { id: presetMetaCollector }
        onExited: (code) => {
            let wallpaperFiles = []
            if (code === 0) {
                try {
                    const meta = JSON.parse(presetMetaCollector.text)
                    if (Array.isArray(meta.wallpapers)) wallpaperFiles = meta.wallpapers
                } catch (e) { /* ignore */ }
            }
            page.startOnlineAssetsFetch(presetMetaFetchProc.entryName, presetMetaFetchProc.stagingJsonPath, presetMetaFetchProc.entryAssets, wallpaperFiles)
        }
    }

    Process {
        id: presetAssetsFetchProc
        property string entryName: ""
        property string stagingJsonPath: ""
        property string assetCacheDirPath: ""
        property var assetFilenames: []
        onExited: (code) => {
            if (code !== 0) {
                page.onlinePresetsError = Translation.tr("Failed to download preset assets")
                return
            }
            const finalJsonPath = `${page.onlinePresetsDir()}/${presetAssetsFetchProc.entryName}.json`
            const jqFilter = '$files as $files | walk(if type == "string" then ((split("/") | last) as $base | if ($files | index($base)) then ($dir + "/" + $base) else . end) else . end) | if has("profile") then .profile.avatarPath = $dir else . end | ._presetMeta.source = "online"'
            const filesJson = JSON.stringify(presetAssetsFetchProc.assetFilenames)
            const cmd = `jq --arg dir ${page.shQuote(presetAssetsFetchProc.assetCacheDirPath)} --argjson files ${page.shQuote(filesJson)} ${page.shQuote(jqFilter)} ${page.shQuote(presetAssetsFetchProc.stagingJsonPath)} > ${page.shQuote(finalJsonPath)} && rm -f ${page.shQuote(presetAssetsFetchProc.stagingJsonPath)}`
            presetRewriteProc.command = ["bash", "-c", cmd]
            presetRewriteProc.running = true
        }
    }

    Process {
        id: presetRewriteProc
        onExited: (code) => {
            if (code === 0) Presets.refreshOnline()
            else page.onlinePresetsError = Translation.tr("Failed to finalize preset")
        }
    }

    // ── File picker for Import ZIP ────────────────────────────────────
    FileDialog {
        id: importZipDialog
        title: Translation.tr("Import Preset ZIP")
        fileMode: FileDialog.OpenFile
        nameFilters: [Translation.tr("Preset archives") + " (*.zip)", Translation.tr("All files") + " (*)"]
        onAccepted: Presets.importZip(FileUtils.trimFileProtocol(String(selectedFile)))
    }

    // ── Layout ────────────────────────────────────────────────────────
    ColumnLayout {
        id: mainLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 20

        SettingsCardSection {
            icon: "bookmark_add"
            title: Translation.tr("Save & Import")

            SettingsGroup {
                // Save as
                MaterialTextField {
                    id: presetNameField
                    Layout.fillWidth: true
                    text: Translation.tr("Save as")
                    placeholderText: Translation.tr("Name, description (optional)")

                    onEditingFinished: {
                        if (presetNameField.text.trim().length > 0) {
                            Presets.save(presetNameField.text)
                            presetNameField.text = ""
                        }
                    }
                }

                // Import ZIP
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    buttonRadius: Appearance.rounding.small
                    colBackground: "transparent"
                    colBackgroundHover: "transparent"
                    colRipple: Appearance.colors.colLayer1Active
                    horizontalPadding: 8
                    downAction: () => importZipDialog.open()
                    contentItem: RowLayout {
                        spacing: 10
                        MaterialSymbol {
                            text: "upload"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Import ZIP")
                            color: Appearance.colors.colOnLayer1
                        }
                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                ConfigSwitch {
                    buttonIcon: "cloud_download"
                    text: Translation.tr("Show online presets")
                    checked: Config.options.settingsUi?.onlinePresets ?? false
                    onCheckedChanged: {
                        Config.setNestedValue("settingsUi.onlinePresets", checked)
                        if (checked) page.refreshOnlinePresets()
                    }
                }
            }
        }

        // ── My presets ────────────────────────────────────────────────
        SettingsCardSection {
            icon: "wallpaper"
            title: Translation.tr("My Presets")

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 40
                visible: Presets.folderModel.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("No presets yet")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            Flow {
                Layout.topMargin: 10
                Layout.fillWidth: true
                width: parent.width
                spacing: 12
                visible: Presets.folderModel.count > 0

                Repeater {
                    model: Presets.folderModel
                    delegate: PresetsCard {
                        id: presetDelegate
                        required property string fileName
                        required property string filePath

                        property string presetName: fileName.replace(".json", "")
                        property string presetWallpaper: ""
                        property string presetDescription: ""

                        FileView {
                            path: presetDelegate.filePath
                            onLoaded: {
                                try {
                                    const data = JSON.parse(text())
                                    const rawWallpaper = data?.background?.wallpaperPath ?? ""
                                    const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWallpaper)
                                    presetDelegate.presetWallpaper = isVideo
                                        ? (data?.background?.thumbnailPath ?? "")
                                        : rawWallpaper
                                    presetDelegate.presetDescription = data?._presetMeta?.description ?? ""
                                } catch (e) {
                                    console.log("Failed to parse preset:", e)
                                }
                            }
                        }

                        imageSource: presetDelegate.presetWallpaper
                        title: presetDelegate.presetName
                        description: presetDelegate.presetDescription !== "" ? presetDelegate.presetDescription : Translation.tr("Saved preset")
                        onApply: () => Presets.apply(presetDelegate.presetName)
                        onRemove: () => Presets.remove(presetDelegate.presetName)
                        onOverwrite: () => Presets.overwrite(presetDelegate.presetName)
                        onExportZip: () => Presets.exportZip(presetDelegate.presetName)
                    }
                }
            }
        }

        // ── Downloaded (online) ───────────────────────────────────────
        SettingsCardSection {
            icon: "cloud_done"
            title: Translation.tr("Downloaded")
            visible: Presets.onlineFolderModel.count > 0

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: 12

                Repeater {
                    model: Presets.onlineFolderModel
                    delegate: PresetsCard {
                        id: onlineDelegate
                        required property string fileName
                        required property string filePath

                        property string presetName: fileName.replace(".json", "")
                        property string presetWallpaper: ""
                        property string presetDescription: ""

                        FileView {
                            path: onlineDelegate.filePath
                            onLoaded: {
                                try {
                                    const data = JSON.parse(text())
                                    const rawWallpaper = data?.background?.wallpaperPath ?? ""
                                    const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWallpaper)
                                    onlineDelegate.presetWallpaper = isVideo
                                        ? (data?.background?.thumbnailPath ?? "")
                                        : rawWallpaper
                                    onlineDelegate.presetDescription = data?._presetMeta?.description ?? ""
                                } catch (e) {
                                    console.log("Failed to parse online preset:", e)
                                }
                            }
                        }

                        imageSource: onlineDelegate.presetWallpaper
                        title: onlineDelegate.presetName
                        description: onlineDelegate.presetDescription !== "" ? onlineDelegate.presetDescription : Translation.tr("Downloaded preset")
                        onApply: () => Presets.applyOnline(onlineDelegate.presetName)
                        onRemove: () => Presets.removeOnline(onlineDelegate.presetName)
                        onOverwrite: () => Presets.overwrite(onlineDelegate.presetName)
                        onExportZip: () => Presets.exportZip(onlineDelegate.presetName)
                    }
                }
            }
        }

        // ── Imported ──────────────────────────────────────────────────
        SettingsCardSection {
            icon: "upload"
            title: Translation.tr("Imported")
            visible: Presets.importedFolderModel.count > 0

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: 12

                Repeater {
                    model: Presets.importedFolderModel
                    delegate: PresetsCard {
                        id: importedDelegate
                        required property string fileName
                        required property string filePath

                        property string presetName: fileName.replace(".json", "")
                        property string presetWallpaper: ""
                        property string presetDescription: ""

                        FileView {
                            path: importedDelegate.filePath
                            onLoaded: {
                                try {
                                    const data = JSON.parse(text())
                                    const rawWallpaper = data?.background?.wallpaperPath ?? ""
                                    const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(rawWallpaper)
                                    importedDelegate.presetWallpaper = isVideo
                                        ? (data?.background?.thumbnailPath ?? "")
                                        : rawWallpaper
                                    importedDelegate.presetDescription = data?._presetMeta?.description ?? ""
                                } catch (e) {
                                    console.log("Failed to parse imported preset:", e)
                                }
                            }
                        }

                        imageSource: importedDelegate.presetWallpaper
                        title: importedDelegate.presetName
                        description: importedDelegate.presetDescription !== "" ? importedDelegate.presetDescription : Translation.tr("Imported preset")
                        onApply: () => Presets.applyImported(importedDelegate.presetName)
                        onRemove: () => Presets.removeImported(importedDelegate.presetName)
                        onOverwrite: () => Presets.overwrite(importedDelegate.presetName)
                        onExportZip: () => Presets.exportZip(importedDelegate.presetName)
                    }
                }
            }
        }

        // ── Browse Online ─────────────────────────────────────────────
        SettingsCardSection {
            icon: "link_2"
            title: Translation.tr("Browse Online")
            visible: Config.options.settingsUi?.onlinePresets ?? false

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                RippleButton {
                    id: refreshOnlineBtn
                    Layout.fillWidth: true
                    Layout.bottomMargin: 6
                    implicitHeight: refreshContentItem.implicitHeight + 8
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    downAction: () => page.refreshOnlinePresets()

                    contentItem: RowLayout {
                        id: refreshContentItem
                        spacing: 10

                        MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.larger
                            text: "cloud_download"
                            color: Appearance.colors.colOnSecondaryContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: page.onlinePresetsRepo()
                            color: Appearance.colors.colOnSecondaryContainer
                        }

                        MaterialSymbol {
                            text: "refresh"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    MaterialSymbol {
                        text: page.onlinePresetsError !== "" ? "error" : "wallpaper"
                        iconSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        text: page.onlinePresetsError !== ""
                            ? page.onlinePresetsError
                            : (page.pendingOnlinePresets.length + " " + Translation.tr("presets available"))
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: 8
                    visible: page.pendingOnlinePresets.length > 0

                    Repeater {
                        model: page.pendingOnlinePresets
                        delegate: Rectangle {
                            id: onlineCard
                            required property var modelData
                            implicitWidth: 293
                            implicitHeight: 186
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer1

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0

                                Rectangle {
                                    id: onlineImageRect
                                    Layout.fillWidth: true
                                    implicitHeight: 130
                                    radius: Appearance.rounding.normal
                                    color: Appearance.colors.colLayer2

                                    Image {
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        source: onlineCard.modelData.screenshot
                                        cache: false
                                        antialiasing: true
                                        sourceSize.width: onlineImageRect.width * 2
                                        sourceSize.height: onlineImageRect.height * 2
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Item {
                                                width: onlineImageRect.width
                                                height: onlineImageRect.height
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: onlineImageRect.radius
                                                }
                                                Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    height: onlineImageRect.radius
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.margins: 10
                                    spacing: 8

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: onlineCard.modelData.title
                                        elide: Text.ElideRight
                                        color: Appearance.colors.colOnLayer1
                                    }

                                    RippleButton {
                                        implicitWidth: 32; implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        colBackground: Appearance.colors.colPrimary
                                        colBackgroundHover: Appearance.colors.colPrimaryHover
                                        colRipple: Appearance.colors.colPrimaryActive
                                        downAction: () => page.downloadOnlinePreset(onlineCard.modelData)

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "download"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.colors.colOnPrimary
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}