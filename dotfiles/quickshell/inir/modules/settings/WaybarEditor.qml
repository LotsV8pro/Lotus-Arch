import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

ContentPage {
    id: root
    settingsPageIndex: 29
    settingsPageName: Translation.tr("Waybar Editor")

    readonly property string waybarConfigDir: `${Directories.homePath}/.config/waybar`
    readonly property string stateFilePath: `${Directories.homePath}/.local/state/haku_theme/waybar_current_mode`
    readonly property string activeConfigPath: root.waybarConfigDir + "/config"

    property string currentProfile: ""
    property var profileList: []
    property var configData: ({})
    property bool dirty: false

    readonly property var _positionOptions: ["top", "bottom", "left", "right"]
    readonly property var _layerOptions: ["top", "bottom", "overlay"]
    readonly property var _knownModules: [
        "clock", "battery", "cpu", "memory", "temperature",
        "tray", "pulseaudio", "pulseaudio/slider", "network", "bluetooth",
        "cava", "mpris", "backlight", "backlight/slider",
        "power-profiles-daemon",
        "custom/logo", "custom/notification", "custom/agenda",
        "custom/monitor", "custom/settings", "custom/recorder",
        "group/hworkspaces", "group/monitor", "group/settings"
    ]

    property var barStyle: ({})
    property var paletteColors: ({})

    onConfigDataChanged: root.rebuildModuleList()

    Component.onCompleted: {
        loadCurrentProfile()
        loadProfileList()
        loadBarStyle()
        root.loadPaletteColors()
    }

    // ─── Module list helpers ─────────────────────────────────────────
    readonly property var _zones: ["modules-left", "modules-center", "modules-right"]
    readonly property var _zoneLabels: [
        Translation.tr("Left"), Translation.tr("Center"), Translation.tr("Right")
    ]
    property var moduleList: []

    function cssId(name) {
        if (name.indexOf("group/") === 0)
            return name.slice("group/".length)
        return name.split("/").join("-")
    }

    function rebuildModuleList() {
        const out = []
        for (const z of root._zones)
            for (const m of (root.configData[z] ?? []))
                out.push({ name: m, zone: z })
        root.moduleList = out
    }

    function zoneIndexOf(zone) {
        return root._zones.indexOf(zone)
    }

    function addModule(name, zone) {
        name = (name ?? "").trim()
        if (name.length === 0)
            return
        const arr = (root.configData[zone] ?? []).slice()
        if (arr.includes(name))
            return
        arr.push(name)
        root.setConfigKey(zone, arr)
    }

    function removeModule(name, zone) {
        const arr = (root.configData[zone] ?? []).slice()
        const idx = arr.indexOf(name)
        if (idx !== -1)
            arr.splice(idx, 1)
        root.setConfigKey(zone, arr)
    }

    function moveModule(name, zone, dir) {
        const arr = (root.configData[zone] ?? []).slice()
        const idx = arr.indexOf(name)
        const dst = idx + dir
        if (idx === -1 || dst < 0 || dst >= arr.length)
            return
        const tmp = arr[idx]; arr[idx] = arr[dst]; arr[dst] = tmp
        root.setConfigKey(zone, arr)
    }

    function setModuleZone(name, fromZone, toZone) {
        if (fromZone === toZone)
            return
        const from = (root.configData[fromZone] ?? []).slice()
        const to = (root.configData[toZone] ?? []).slice()
        const idx = from.indexOf(name)
        if (idx !== -1)
            from.splice(idx, 1)
        if (!to.includes(name))
            to.push(name)
        root.setConfigKey(fromZone, from)
        root.setConfigKey(toZone, to)
    }

    function setModuleStyle(name, key, value) {
        const st = JSON.parse(JSON.stringify(root.barStyle))
        st[key] = value
        root.barStyle = st
        root.dirty = true
    }

    function currentModuleStyle(name, key) {
        return root.barStyle?.[key] ?? "auto"
    }

    function formatModuleStyles() {
        const bg = root.barStyle?.background ?? "auto"
        const fg = root.barStyle?.color ?? "auto"
        if (bg === "auto" && fg === "auto")
            return "[]"
        const out = []
        const seen = {}
        for (const z of root._zones) {
            for (const n of (root.configData[z] ?? [])) {
                if (seen[n]) continue
                seen[n] = true
                out.push({
                    id: root.cssId(n),
                    background: bg,
                    color: fg
                })
            }
        }
        return JSON.stringify(out)
    }

    // ─── Config file I/O ──────────────────────────────────────────────
    FileView {
        id: configFileView
        path: root.activeConfigPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                const text = configFileView.text()
                root.configData = text ? JSON.parse(text) : {}
                root.dirty = false
            } catch(e) {
                console.log("[WaybarEditor] Config parse error:", e)
                root.configData = {}
            }
        }
    }

    FileView {
        id: styleFileView
        path: `${root.waybarConfigDir}/style.css`
        watchChanges: true
        printErrors: false
        onLoaded: root.loadBarStyle()
    }

    FileView {
        id: paletteFileView
        path: `${Directories.homePath}/.local/state/haku_theme/colors.css`
        watchChanges: true
        printErrors: false
        onLoaded: root.loadPaletteColors()
    }

    function loadBarStyle() {
        const text = styleFileView.text()
        const M0 = "/* ====== INIR WAYBAR MODULE STYLES START ====== */"
        const M1 = "/* ====== INIR WAYBAR MODULE STYLES END ====== */"
        const a = text.indexOf(M0)
        const b = text.indexOf(M1)
        const style = { background: "auto", color: "auto" }
        if (a !== -1 && b > a) {
            const block = text.slice(a + M0.length, b)
            const re = /#([\w-]+)\s*\{([^}]*)\}/g
            const m = re.exec(block)
            if (m) {
                const decl = m[2]
                const bg = /background-color:\s*([^;\n]+)/.exec(decl)
                const fg = /color:\s*([^;\n]+)/.exec(decl)
                if (bg) style.background = bg[1].trim()
                if (fg) style.color = fg[1].trim()
            }
        }
        root.barStyle = style
    }

    function loadPaletteColors() {
        const text = paletteFileView.text()
        const map = {}
        const re = /@define-color\s+([\w-]+)\s+(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{8})\s*;/g
        let m
        while ((m = re.exec(text)) !== null)
            map[m[1]] = m[2]
        root.paletteColors = map
    }

    readonly property var _bgOptions: [
        { value: "auto", label: Translation.tr("Automatic"), css: "" },
        { value: "@accent_color", label: Translation.tr("Accent"), css: "@accent_color" },
        { value: "@surface", label: Translation.tr("Surface"), css: "@surface" },
        { value: "@surface_high", label: Translation.tr("Surface high"), css: "@surface_high" },
        { value: "@surface_container", label: Translation.tr("Surface container"), css: "@surface_container" },
        { value: "@background", label: Translation.tr("Background"), css: "@background" },
        { value: "transparent", label: Translation.tr("Transparent"), css: "" }
    ]

    readonly property var _fgOptions: [
        { value: "auto", label: Translation.tr("Automatic"), css: "" },
        { value: "@on_accent", label: Translation.tr("On Accent"), css: "@on_accent" },
        { value: "@on_surface", label: Translation.tr("On Surface"), css: "@on_surface" },
        { value: "@on_background", label: Translation.tr("On Background"), css: "@on_background" }
    ]

    function paletteHex(cssName) {
        if (!cssName)
            return "transparent"
        if (root.paletteColors[cssName])
            return root.paletteColors[cssName]
        const fb = {
            "@accent_color": Appearance.colors.colPrimary,
            "@on_accent": Appearance.colors.colOnPrimary,
            "@accent_container": Appearance.m3colors.m3primaryContainer,
            "@on_accent_container": Appearance.m3colors.m3onPrimaryContainer,
            "@background": Appearance.colors.colLayer0Base,
            "@on_background": Appearance.m3colors.m3onBackground,
            "@surface": Appearance.m3colors.m3surface,
            "@surface_container": Appearance.m3colors.m3surfaceContainer,
            "@surface_high": Appearance.m3colors.m3surfaceContainerHigh,
            "@on_surface": Appearance.m3colors.m3onSurface,
            "@on_surface_variant": Appearance.m3colors.m3onSurfaceVariant,
            "@outline": Appearance.m3colors.m3outline,
            "@error": Appearance.m3colors.m3error
        }
        return fb[cssName] ?? "transparent"
    }

    function setConfigKey(key, value) {
        const d = JSON.parse(JSON.stringify(root.configData))
        d[key] = value
        root.configData = d
        root.dirty = true
    }

    function setNestedKey(obj, value) {
        const d = JSON.parse(JSON.stringify(root.configData))
        let keys = obj.split(".")
        let cur = d
        for (let i = 0; i < keys.length - 1; i++) {
            if (cur[keys[i]] === undefined || cur[keys[i]] === null || typeof cur[keys[i]] !== "object")
                cur[keys[i]] = {}
            cur = cur[keys[i]]
        }
        cur[keys[keys.length - 1]] = value
        root.configData = d
        root.dirty = true
    }

    function saveConfig() {
        const py = "import json,os,sys,re\n"
            + "cp=os.path.realpath(sys.argv[1])\n"
            + "d=json.loads(sys.argv[2])\n"
            + "os.makedirs(os.path.dirname(cp),exist_ok=True)\n"
            + "t=cp+'.tmp'\n"
            + "open(t,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\\n')\n"
            + "os.replace(t,cp)\n"
            + "sp=os.path.realpath(sys.argv[3])\n"
            + "hs=os.path.dirname(sp)\n"
            + "os.makedirs(hs,exist_ok=True)\n"
            + "rules=json.loads(sys.argv[4])\n"
            + "lines=[]\n"
            + "for r in rules:\n"
            + "    decl=[]\n"
            + "    if r.get('background','auto')!='auto': decl.append('    background-color: %s;'%r['background'])\n"
            + "    if r.get('color','auto')!='auto': decl.append('    color: %s;'%r['color'])\n"
            + "    if decl: lines.append('#%s {\\n%s\\n}'%(r['id'],'\\n'.join(decl)))\n"
            + "M0='/* ====== INIR WAYBAR MODULE STYLES START ====== */'\n"
            + "M1='/* ====== INIR WAYBAR MODULE STYLES END ====== */'\n"
            + "block=M0+'\\n'+'\\n'.join(lines)+'\\n'+M1+('\\n' if lines else '')\n"
            + "if os.path.exists(sp):\n"
            + "    data=open(sp,encoding='utf-8').read()\n"
            + "else:\n"
            + "    data=''\n"
            + "a=data.find(M0); b=data.find(M1)\n"
            + "if a>=0 and b>=0:\n"
            + "    data=data[:a]+block+data[b+len(M1):]\n"
            + "else:\n"
            + "    data=data.rstrip()+'\\n\\n'+block+'\\n' if data.strip() else block+'\\n'\n"
            + "open(sp,'w',encoding='utf-8').write(data)"
        configWriteProcess.command = [
            "/usr/bin/python3", "-c", py,
            root.activeConfigPath, JSON.stringify(root.configData),
            `${root.waybarConfigDir}/style.css`,
            root.formatModuleStyles()
        ]
        configWriteProcess.running = true
    }

    function loadCurrentProfile() {
        readStateProcess.running = true
    }

    function loadProfileList() {
        listProfilesProcess.running = true
    }

    function applyProfile(profileName) {
        applyProfileProcess.command = [
            "/usr/bin/bash", "-c",
            `ln -sf "${root.waybarConfigDir}/${profileName}/config" "${root.waybarConfigDir}/config" && ` +
            `ln -sf "${root.waybarConfigDir}/${profileName}/style.css" "${root.waybarConfigDir}/style.css" && ` +
            `mkdir -p "$(dirname "${root.stateFilePath}")" && ` +
            `printf '%s' '${profileName}' > "${root.stateFilePath}" && ` +
            `pkill -x waybar; sleep 0.2; setsid waybar >/dev/null 2>&1 < /dev/null &`
        ]
        applyProfileProcess.running = true
        _applyTarget = profileName
    }

    function reloadWaybar() {
        reloadWaybarProcess.running = true
    }

    function savePresetTo(presetName) {
        _saveTarget = presetName
        savePresetProcess.command = [
            "/usr/bin/python3", "-c",
            "import json,os,sys,shutil; p=sys.argv[1]; d=json.loads(sys.argv[2]);"
            + " os.makedirs(os.path.dirname(p),exist_ok=True);"
            + " css=os.path.join(os.path.dirname(p),'style.css');"
            + " if not os.path.exists(css) and len(sys.argv)>=4: shutil.copy(sys.argv[3],css);"
            + " t=p+'.tmp'; open(t,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\\n');"
            + " os.replace(t,p)",
            `${root.waybarConfigDir}/${presetName}/config`,
            JSON.stringify(root.configData),
            `${root.waybarConfigDir}/${root.currentProfile.length > 0 ? root.currentProfile : "coredge"}/style.css`
        ]
        savePresetProcess.running = true
    }

    function saveCurrentAsNewPreset() {
        const name = (root.newPresetName ?? "").trim()
        if (name.length === 0)
            return
        root.savePresetTo(name)
    }

    function deletePreset(presetName) {
        _deleteTarget = presetName
        deletePresetProcess.command = ["/usr/bin/rm", "-rf", `${root.waybarConfigDir}/${presetName}`]
        deletePresetProcess.running = true
    }

    property string _saveTarget: ""
    property string _deleteTarget: ""
    property string newPresetName: ""

    property string _applyTarget: ""
    property string _applyStatus: ""

    // ─── Current Status ──────────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "bar_chart"
        title: Translation.tr("Current Status")

        SettingsGroup {
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                MaterialSymbol {
                    text: "smart_display"
                    iconSize: 32
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: root.currentProfile.length > 0 ? root.currentProfile : Translation.tr("Loading...")
                        font.pixelSize: Appearance.font.pixelSize.title
                        color: Appearance.colors.colOnLayer1
                    }

                    StyledText {
                        text: Translation.tr("Active Waybar profile")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8
                visible: root.currentProfile.length > 0

                MaterialSymbol {
                    text: "link"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    text: "config \u2192 %1/%2/config".arg(root.waybarConfigDir).arg(root.currentProfile)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.monospace
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.currentProfile.length > 0

                MaterialSymbol {
                    text: "link"
                    iconSize: 14
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    text: "style.css \u2192 %1/%2/style.css".arg(root.waybarConfigDir).arg(root.currentProfile)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.monospace
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
        }
    }

    // ─── Visual Config Editor ─────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "edit"
        title: Translation.tr("Visual Config Editor")

        SettingsGroup {
            visible: Object.keys(root.configData).length > 0

            // Save / Discard bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: "info"
                    iconSize: 16
                    color: root.dirty ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.dirty
                        ? Translation.tr("Unsaved changes")
                        : Translation.tr("Editing active profile config")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: root.dirty ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }

                RippleButtonWithIcon {
                    visible: root.dirty
                    materialIcon: "undo"
                    mainText: Translation.tr("Revert")
                    onClicked: configFileView.reload()
                }

                RippleButtonWithIcon {
                    visible: root.dirty
                    materialIcon: "save"
                    mainText: Translation.tr("Save & Reload")
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    onClicked: {
                        root.saveConfig()
                    }
                }
            }

            // ── Position ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.leftMargin: 8
                Layout.rightMargin: 8

                MaterialSymbol { text: "swap_vert"; iconSize: 18; color: Appearance.colors.colSubtext }

                StyledText {
                    Layout.preferredWidth: 100
                    text: Translation.tr("Position")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }

                Flow { Layout.fillWidth: true; spacing: 4
                    Repeater {
                        model: root._positionOptions
                        delegate: RippleButton {
                        implicitWidth: Math.max(48, (modelData.charAt(0).toUpperCase() + modelData.slice(1)).length * 8 + 20)
                        implicitHeight: 28
                        textHorizontalAlignment: Text.AlignHCenter
                        buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        toggled: (root.configData["position"] ?? "top") === modelData
                        onClicked: root.setConfigKey("position", modelData)
                    }
                    }
                }
            }

            // ── Layer ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.leftMargin: 8
                Layout.rightMargin: 8

                MaterialSymbol { text: "layers"; iconSize: 18; color: Appearance.colors.colSubtext }

                StyledText {
                    Layout.preferredWidth: 100
                    text: Translation.tr("Layer")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }

                Flow { Layout.fillWidth: true; spacing: 4
                    Repeater {
                        model: root._layerOptions
                        delegate: RippleButton {
                            implicitWidth: Math.max(48, (modelData.charAt(0).toUpperCase() + modelData.slice(1)).length * 8 + 20)
                            implicitHeight: 28
                            textHorizontalAlignment: Text.AlignHCenter
                            buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            toggled: (root.configData["layer"] ?? "top") === modelData
                            onClicked: root.setConfigKey("layer", modelData)
                        }
                    }
                }
            }

            // ── Spacing ──
            ConfigSpinBox {
                icon: "space_bar"
                text: Translation.tr("Spacing")
                from: 0; to: 50; stepSize: 1
                value: root.configData["spacing"] ?? 2
                onValueChanged: root.setConfigKey("spacing", value)
            }

            // ── Margins ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.leftMargin: 8
                Layout.rightMargin: 8

                MaterialSymbol { text: "select_all"; iconSize: 18; color: Appearance.colors.colSubtext }

                StyledText {
                    text: Translation.tr("Margins")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }

                Repeater {
                    model: ["margin-top", "margin-right", "margin-bottom", "margin-left"]
                    delegate: ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: Translation.tr(modelData.replace("margin-", ""))
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                        StyledSpinBox {
                            from: 0; to: 100; stepSize: 1
                            value: root.configData[modelData] ?? 0
                            onValueChanged: root.setConfigKey(modelData, value)
                        }
                    }
                }
            }

            // ── Tooltip ──
            ConfigSwitch {
                buttonIcon: "info"
                text: Translation.tr("Enable tooltip")
                checked: root.configData["tooltip"] ?? true
                onCheckedChanged: root.setConfigKey("tooltip", checked)
            }

            // ── Reload on style change ──
            ConfigSwitch {
                buttonIcon: "autorenew"
                text: Translation.tr("Reload on style change")
                checked: root.configData["reload_style_on_change"] ?? true
                onCheckedChanged: root.setConfigKey("reload_style_on_change", checked)
            }

            SettingsDivider {}

            // ── Clock ──
            ColumnLayout {
                visible: root.configData["clock"] !== undefined
                spacing: 8

                StyledText {
                    text: Translation.tr("Clock")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    StyledText {
                        text: Translation.tr("Format")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }

                    MaterialTextField {
                        Layout.fillWidth: true
                        placeholderText: " {:%H:%M} "
                        text: (root.configData["clock"] ?? {})["format"] ?? ""
                        onEditingFinished: {
                            const clock = JSON.parse(JSON.stringify(root.configData["clock"] ?? {}))
                            clock["format"] = text
                            root.setConfigKey("clock", clock)
                        }
                    }
                }

                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true

                    StyledText {
                        text: Translation.tr("Format (alt)")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }

                    MaterialTextField {
                        Layout.fillWidth: true
                        placeholderText: " {:%A, %d %B %Y} "
                        text: (root.configData["clock"] ?? {})["format-alt"] ?? ""
                        onEditingFinished: {
                            const clock = JSON.parse(JSON.stringify(root.configData["clock"] ?? {}))
                            clock["format-alt"] = text
                            root.setConfigKey("clock", clock)
                        }
                    }
                }
            }

            SettingsDivider {}

            // ── Tray ──
            ConfigSpinBox {
                visible: root.configData["tray"] !== undefined
                icon: "notifications"
                text: Translation.tr("Tray icon size")
                from: 8; to: 64; stepSize: 2
                value: (root.configData["tray"] ?? {})["icon-size"] ?? 18
                onValueChanged: {
                    const tray = JSON.parse(JSON.stringify(root.configData["tray"] ?? {}))
                    tray["icon-size"] = value
                    root.setConfigKey("tray", tray)
                }
            }

            SettingsDivider {}

            // ── Modules ──
            ColumnLayout {
                spacing: 8

                StyledText {
                    text: Translation.tr("Modules")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                // ── Add module ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledComboBox {
                        id: addModuleCombo
                        Layout.fillWidth: true
                        property string lastChosen: ""
                        model: {
                            const inUse = []
                            for (const z of root._zones)
                                Array.prototype.push.apply(inUse, root.configData[z] ?? [])
                            return root._knownModules.filter(m => !inUse.includes(m))
                        }
                        onActivated: {
                            const name = currentText
                            if (!name) return
                            root.addModule(name, root._zones[addZoneCombo.currentIndex])
                            lastChosen = name
                            currentIndex = -1
                        }
                    }

                    StyledComboBox {
                        id: addZoneCombo
                        Layout.preferredWidth: 110
                        model: root._zoneLabels
                        currentIndex: 0
                    }

                    RippleButtonWithIcon {
                        materialIcon: "add"
                        mainText: Translation.tr("Add")
                        onClicked: {
                            if (addModuleCombo.lastChosen.length > 0) {
                                root.addModule(addModuleCombo.lastChosen, root._zones[addZoneCombo.currentIndex])
                                addModuleCombo.lastChosen = ""
                            }
                        }
                    }
                }

                // Custom module name
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialTextField {
                        id: customModuleField
                        Layout.fillWidth: true
                        placeholderText: "custom/script"
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    RippleButtonWithIcon {
                        materialIcon: "add_circle"
                        mainText: Translation.tr("Add custom")
                        onClicked: {
                            const name = customModuleField.text.trim()
                            if (!name)
                                return
                            root.addModule(name, root._zones[addZoneCombo.currentIndex])
                            customModuleField.text = ""
                        }
                    }
                }

                // ── Module list (all zones, ordered) ──
                Repeater {
                    model: root.moduleList

                    delegate: Rectangle {
                        id: modRow
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Appearance.rounding.small
                        color: modRowMA.containsMouse ? Appearance.colors.colLayer1Hover
                            : Appearance.colors.colLayer1
                        border.width: 1
                        border.color: Appearance.colors.colLayer0Border
                        Behavior on color {
                            ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 6

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.family: Appearance.font.family.monospace
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideMiddle
                            }

                            StyledComboBox {
                                Layout.preferredWidth: 90
                                model: root._zoneLabels
                                currentIndex: root.zoneIndexOf(modelData.zone)
                                onActivated: (idx) => root.setModuleZone(modelData.name, modelData.zone, root._zones[idx])
                            }

                            Repeater {
                                model: [ { icon: "arrow_upward", dir: -1 }, { icon: "arrow_downward", dir: 1 } ]
                                delegate: MaterialSymbol {
                                    iconSize: 16
                                    text: modelData.icon
                                    color: Appearance.colors.colSubtext
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.moveModule(modelData.name, modelData.zone, modelData.dir)
                                    }
                                }
                            }

                            MaterialSymbol {
                                text: "close"
                                iconSize: 16
                                color: Appearance.colors.colSubtext
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removeModule(modelData.name, modelData.zone)
                                }
                            }
                        }

                        MouseArea {
                            id: modRowMA
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                        }
                    }
                }
            }

            StyledText {
                visible: Object.keys(root.configData).length === 0
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("No config loaded")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                font.italic: true
            }
        }
    }

    // ─── Color Palette ────────────────────────────────────────────
    SettingsCardSection {
        visible: Object.keys(root.configData).length > 0
        expanded: true
        icon: "format_color_fill"
        title: Translation.tr("Color Palette")

        SettingsGroup {
            visible: root.moduleList.length > 0

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Colors apply to the whole bar. New modules inherit the same look automatically.")
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                opacity: 0.8
            }

            StyledText {
                text: Translation.tr("Background")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }

            Flow {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root._bgOptions

                    Rectangle {
                        required property var modelData
                        required property int index
                        property bool _active: root.currentModuleStyle("", "background") === modelData.value

                        width: (parent.width - 4 * 6) / 7
                        implicitHeight: 36
                        radius: Appearance.rounding.small
                        color: _bgMA.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                        border.width: _active ? 1.5 : 0
                        border.color: Appearance.colors.colPrimary
                        Behavior on color { enabled: Appearance.animationsEnabled; ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 4
                            spacing: 4

                            // Overlapping circles like ThemePresetCard
                            Row {
                                spacing: -4

                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: root.paletteHex(modelData.css) || Appearance.colors.colLayer1
                                    border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25)
                                    z: 3
                                }
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: modelData.value === "transparent" ? Appearance.colors.colLayer0
                                        : Appearance.m3colors.m3primary
                                    border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25)
                                    z: 2
                                }
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: Appearance.m3colors.m3surface
                                    border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25)
                                    z: 1
                                }
                            }

                            StyledText {
                                text: modelData.label
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: _active ? Font.DemiBold : Font.Normal
                                color: _active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            MaterialSymbol {
                                visible: _active
                                text: "check"
                                iconSize: 14
                                color: Appearance.colors.colPrimary
                            }
                        }

                        MouseArea {
                            id: _bgMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setModuleStyle("", "background", modelData.value)
                        }
                    }
                }
            }

            StyledText {
                text: Translation.tr("Foreground")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }

            Flow {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root._fgOptions

                    Rectangle {
                        required property var modelData
                        required property int index
                        property bool _active: root.currentModuleStyle("", "color") === modelData.value

                        width: (parent.width - 4 * 3) / 4
                        implicitHeight: 36
                        radius: Appearance.rounding.small
                        color: _fgMA.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
                        border.width: _active ? 1.5 : 0
                        border.color: Appearance.colors.colPrimary
                        Behavior on color { enabled: Appearance.animationsEnabled; ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 4
                            spacing: 4

                            Row {
                                spacing: -4

                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: root.paletteHex(modelData.css) || Appearance.colors.colLayer1
                                    border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25)
                                    z: 3
                                }
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: modelData.value === "auto" ? Appearance.colors.colOnPrimary : Appearance.m3colors.m3onSurface
                                    border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25)
                                    z: 2
                                }
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: Appearance.m3colors.m3surface
                                    border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.25)
                                    z: 1
                                }
                            }

                            StyledText {
                                text: modelData.label
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: _active ? Font.DemiBold : Font.Normal
                                color: _active ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            MaterialSymbol {
                                visible: _active
                                text: "check"
                                iconSize: 14
                                color: Appearance.colors.colPrimary
                            }
                        }

                        MouseArea {
                            id: _fgMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setModuleStyle("", "color", modelData.value)
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Module styles are written as CSS rules in the active preset's style.css using the palette. 'Automatic' inherits the preset look.")
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                opacity: 0.7
                Layout.topMargin: 6
            }
        }
    }

    // ─── Available Profiles ───────────────────────────────────────────
    SettingsCardSection {
        expanded: true
        icon: "palette"
        title: Translation.tr("Available Presets")

        SettingsGroup {
            // Save current config as a new preset
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialTextField {
                    id: newPresetNameField
                    Layout.fillWidth: true
                    text: root.newPresetName
                    placeholderText: Translation.tr("New preset name")
                    font.pixelSize: Appearance.font.pixelSize.small
                    onTextChanged: root.newPresetName = newPresetNameField.text
                    onEditingFinished: root.saveCurrentAsNewPreset()
                }

                RippleButtonWithIcon {
                    materialIcon: "save"
                    mainText: Translation.tr("Save current preset")
                    onClicked: root.saveCurrentAsNewPreset()
                }
            }

            Repeater {
                model: root.profileList

                delegate: Item {
                    id: profileItem
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: profileRow.implicitHeight + 12

                    readonly property bool isActive: profileItem.modelData === root.currentProfile
                    readonly property bool isApplying: profileItem.modelData === root._applyTarget && root._applyStatus === "applying"

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.small
                        color: profileMA.containsMouse ? Appearance.colors.colLayer1Hover
                            : profileItem.isActive ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.90)
                            : "transparent"
                        border.width: profileItem.isActive ? 1 : 0
                        border.color: Appearance.colors.colPrimary
                        Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }

                        RowLayout {
                            id: profileRow
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 12
                                Layout.preferredHeight: 12
                                radius: 6
                                color: profileItem.isActive ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: profileItem.modelData
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: profileItem.isActive ? Font.Medium : Font.Normal
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                visible: profileItem.isActive
                                text: Translation.tr("Active")
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.weight: Font.Medium
                                color: Appearance.colors.colPrimary
                            }

                            RippleButtonWithIcon {
                                visible: !profileItem.isActive && !root._applyStatus
                                materialIcon: "check"
                                mainText: Translation.tr("Apply")
                                onClicked: root.applyProfile(profileItem.modelData)
                            }

                            RippleButtonWithIcon {
                                visible: !root._applyStatus
                                materialIcon: "save"
                                mainText: Translation.tr("Save")
                                onClicked: root.savePresetTo(profileItem.modelData)
                            }

                            RippleButtonWithIcon {
                                visible: !profileItem.isActive && !root._applyStatus
                                materialIcon: "delete"
                                mainText: Translation.tr("Delete")
                                onClicked: root.deletePreset(profileItem.modelData)
                            }

                            MaterialSymbol {
                                visible: profileItem.isApplying
                                text: "progress_activity"
                                iconSize: 18
                                color: Appearance.colors.colPrimary

                                RotationAnimation on rotation {
                                    running: profileItem.isApplying
                                    from: 0; to: 360
                                    duration: 800
                                    loops: Animation.Infinite
                                }
                            }
                        }

                        MouseArea {
                            id: profileMA
                            anchors.fill: parent
                            z: -1
                            hoverEnabled: true
                        }
                    }
                }
            }

            StyledText {
                visible: root.profileList.length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                text: Translation.tr("No profiles found in ~/.config/waybar/")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                font.italic: true
            }
        }
    }

    // ─── Actions ─────────────────────────────────────────────────────
    SettingsCardSection {
        expanded: false
        icon: "build"
        title: Translation.tr("Actions")

        SettingsGroup {
            Flow {
                Layout.fillWidth: true
                spacing: 5

                RippleButtonWithIcon {
                    materialIcon: "refresh"
                    mainText: Translation.tr("Reload Waybar")
                    onClicked: root.reloadWaybar()
                }

                RippleButtonWithIcon {
                    materialIcon: "folder_open"
                    mainText: Translation.tr("Open config folder")
                    onClicked: ShellExec.execDetachedArgs(["xdg-open", root.waybarConfigDir], Translation.tr("Open config folder"))
                }

                RippleButtonWithIcon {
                    visible: root.currentProfile.length > 0
                    materialIcon: "description"
                    mainText: Translation.tr("Open active config")
                    onClicked: ShellExec.execDetachedArgs(["xdg-open", `${root.waybarConfigDir}/config`], Translation.tr("Open active config"))
                }
            }
        }
    }

    // ─── Installed Profiles Info ──────────────────────────────────────
    SettingsCardSection {
        expanded: false
        icon: "info"
        title: Translation.tr("Installed Profiles")

        SettingsGroup {
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.profileList

                    delegate: RowLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        spacing: 8

                        MaterialSymbol {
                            text: "folder"
                            iconSize: 14
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.family: Appearance.font.family.monospace
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: Translation.tr("Each profile contains a config.json and style.css. Symlinks in ~/.config/waybar/ point to the active profile.")
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    opacity: 0.7
                }
            }
        }
    }

    // ─── Processes ────────────────────────────────────────────────────
    Process {
        id: readStateProcess
        command: ["/usr/bin/cat", root.stateFilePath]
        stdout: SplitParser {
            onRead: data => {
                const profile = data.trim()
                if (profile.length > 0)
                    root.currentProfile = profile
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0)
                root.currentProfile = ""
        }
    }

    Process {
        id: listProfilesProcess
        command: ["/usr/bin/bash", "-c", `for d in "${root.waybarConfigDir}"/*/; do [ -f "$d/config" ] && [ -f "$d/style.css" ] && basename "$d"; done | sort`]
        stdout: SplitParser {
            onRead: data => {
                const name = data.trim()
                if (name.length > 0)
                    root.profileList = root.profileList.concat([name])
            }
        }
        onStarted: root.profileList = []
    }

    Process {
        id: applyProfileProcess
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.currentProfile = root._applyTarget
                root._applyTarget = ""
                root._applyStatus = ""
                configFileView.reload()
                styleFileView.reload()
                root.reloadWaybar()
            } else {
                root._applyStatus = "error"
                root._applyTarget = ""
                applyErrorTimer.restart()
            }
        }
    }

    Timer {
        id: applyErrorTimer
        interval: 3000
        onTriggered: root._applyStatus = ""
    }

    Process {
        id: reloadWaybarProcess
        command: ["/usr/bin/bash", "-c", "pkill -x waybar; sleep 0.2; setsid waybar >/dev/null 2>&1 < /dev/null &"]
    }

    Process {
        id: configWriteProcess
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.dirty = false
                configFileView.reload()
                root.reloadWaybar()
            }
        }
    }

    Process {
        id: savePresetProcess
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.newPresetName = ""
                root.loadProfileList()
            }
            root._saveTarget = ""
        }
    }

    Process {
        id: deletePresetProcess
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.loadProfileList()
            }
            root._deleteTarget = ""
        }
    }
}
