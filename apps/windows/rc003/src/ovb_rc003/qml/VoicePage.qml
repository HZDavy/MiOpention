import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import OvbRc003Settings 1.0

Item {
    id: root
    signal openDeviceRequested()
    signal openButtonsRequested()
    property var tokens
    property var backTabTarget: null
    property var tabTarget: null
    readonly property var firstFocusItem: installVirtualAudioButton
    readonly property var lastFocusItem: testVbCableChannelButton
    property bool voiceHotkeyRecording: false
    property int voiceRecordingSlot: 1
    property string voiceHotkeyCaptureError: ""
    property string pendingVoiceHotkey: ""
    // Status line of the saved-profile list; the C++ actions return {ok,message}.
    property string voiceProfileMessage: ""
    // Name of the profile currently applied, shown by the compact section row.
    readonly property string activeVoiceProfileName: {
        const rows = SettingsController.voiceProfiles
        for (var i = 0; i < rows.length; i++) {
            if (rows[i].applied)
                return String(rows[i].name || "")
        }
        return ""
    }
    // Only the two voice slots exist; each owns one user-recorded shortcut.
    readonly property var voiceSlots: {
        const count = SettingsController.voiceSlotOptions.length
        const slots = []
        for (var i = 0; i < count; i++)
            slots.push(i + 1)
        return slots
    }
    readonly property int settingsStateColumnWidth: 96
    readonly property int settingsActionColumnWidth: tokens.buttonWidth6Chars
    readonly property bool voiceHotkeyBusy: SettingsController.voiceHotkeyBusy
    readonly property bool configurationWriteBusy:
        DiagnosticsController.driverActionRunning
        || DiagnosticsController.vbCableTestRunning
        || SettingsController.bridgeLaunchBusy
        || SettingsController.endpointPreflightBusy
    readonly property bool voiceHotkeyRuntimeBusy:
        String(SettingsController.voiceRuntimeState) === "active"
        || String(SettingsController.voiceRuntimeState) === "mic_confirmed"
        || String(SettingsController.voiceRuntimeState) === "receiving_audio"
        || String(SettingsController.voiceRuntimeState) === "finishing"

    function checkResult(checkId) {
        const rows = DiagnosticsController.checkResults
        for (var i = 0; i < rows.length; i++) {
            if (String(rows[i].checkId) === checkId)
                return rows[i]
        }
        return null
    }

    function checkState(checkId) {
        if (DiagnosticsController.isRefreshing)
            return qsTr("正在检查")
        const row = checkResult(checkId)
        if (!row)
            return qsTr("未检查")
        if (row.status === "pass")
            return qsTr("正常")
        if (row.status === "manual")
            return qsTr("请手动验证")
        if (checkId === "vb_cable_endpoints")
            return String(row.detail || "").indexOf(qsTr("缺少")) >= 0
                ? qsTr("点击“安装音频”") : qsTr("点击“重新检查”")
        if (checkId === "output_endpoint")
            return qsTr("请重新选择端点")
        return qsTr("点击“重新检查”")
    }

    function checkColor(checkId) {
        const state = checkState(checkId)
        if (state === qsTr("正常"))
            return tokens.successColor
        if (state === qsTr("点击“安装音频”")
                || state === qsTr("点击“重新检查”")
                || state === qsTr("请重新选择端点"))
            return tokens.errorColor
        if (state === qsTr("正在检查") || state === qsTr("请手动验证"))
            return tokens.voiceAccent
        return tokens.disabledText
    }

    function checkDetail(checkId, fallback) {
        const row = checkResult(checkId)
        return row && String(row.detail).length > 0
            ? String(row.detail).trim().replace(/[。；;]+$/, "") : fallback
    }

    function startVoiceHotkeyCapture(slot) {
        const sameSlot = voiceHotkeyRecording && voiceRecordingSlot === slot
        if (voiceHotkeyRecording
                && !stopVoiceHotkeyCapture("capture_field_tapped"))
            return
        if (sameSlot)
            return
        voiceHotkeyCaptureError = ""
        pendingVoiceHotkey = ""
        if (!SettingsController.startHotkeyCapture()) {
            voiceHotkeyCaptureError = qsTr("无法开始录入，请结束其它按键操作后重试")
            return
        }
        voiceRecordingSlot = slot
        voiceHotkeyRecording = true
    }

    function stopVoiceHotkeyCapture(reason) {
        pendingVoiceHotkey = ""
        if (!voiceHotkeyRecording)
            return true
        SettingsController.reportHotkeyCaptureUiStop(reason || "unknown")
        if (!SettingsController.stopHotkeyCapture()) {
            voiceHotkeyCaptureError = qsTr("无法停止快捷键录入，请重试")
            return false
        }
        if (!SettingsController.hotkeyCaptureActive)
            voiceHotkeyRecording = false
        return true
    }

    function settleInputUiAfterStop() {
        if (!SettingsController.hotkeyCaptureActive) {
            voiceHotkeyRecording = false
            pendingVoiceHotkey = ""
        }
    }

    // One entry point for every saved-profile action so the status line and the
    // error reporting stay identical across buttons and dialogs.
    function runVoiceProfileAction(operation, identity, text) {
        const result = SettingsController.mappingPresetAction(
            operation, identity || "", text || "")
        voiceProfileMessage = String(result.message || "")
        return result
    }

    function finishCapturedVoiceHotkey(chord) {
        pendingVoiceHotkey = chord
        if (!SettingsController.stopHotkeyCapture()) {
            pendingVoiceHotkey = ""
            voiceHotkeyCaptureError = qsTr("无法停止快捷键录入，请重试")
            return
        }
        if (!SettingsController.hotkeyCaptureActive)
            commitCapturedVoiceHotkey()
    }

    function commitCapturedVoiceHotkey() {
        if (pendingVoiceHotkey.length === 0)
            return
        const chord = pendingVoiceHotkey
        const slot = voiceRecordingSlot
        pendingVoiceHotkey = ""
        voiceHotkeyRecording = false
        SettingsController.setVoiceSlotHotkey(slot, chord)
    }

    function focusRecordingSlot() {
        for (var i = 0; i < voiceSlotRepeater.count; i++) {
            const row = voiceSlotRepeater.itemAt(i)
            if (row)
                row.claimFocus()
        }
    }

    function tapInsideRecordingField(eventPoint) {
        for (var i = 0; i < voiceSlotRepeater.count; i++) {
            const row = voiceSlotRepeater.itemAt(i)
            if (!row)
                continue
            const field = row.recordingField()
            if (!field)
                continue
            const local = field.mapFromItem(voiceScroll.contentItem,
                eventPoint.position.x, eventPoint.position.y)
            if (local.x >= 0 && local.y >= 0
                    && local.x < field.width && local.y < field.height)
                return true
        }
        return false
    }

    onVoiceHotkeyRecordingChanged: {
        if (voiceHotkeyRecording)
            Qt.callLater(root.focusRecordingSlot)
    }
    onVoiceRecordingSlotChanged: {
        if (voiceHotkeyRecording)
            Qt.callLater(root.focusRecordingSlot)
    }

    SettingsDialog {
        id: driverConfirmDialog
        tokens: root.tokens
        preferredWidth: 390
        objectName: "driverConfirmDialog"
        title: qsTr("安装虚拟音频？")
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: DiagnosticsController.launchVbCableSetup()

        contentItem: UiLabel {
            tokens: root.tokens
            kind: bodyKind
            wrapMode: Text.WordWrap
            text: qsTr("将启动 VB-Audio 官方 VB-CABLE 安装程序并请求管理员权限。完成安装后需要重启电脑，再回到这里点击“选推荐端点”。")
        }
    }

    SettingsDialog {
        id: bridgeTestConfirmDialog
        tokens: root.tokens
        preferredWidth: 390
        objectName: "bridgeTestConfirmDialog"
        title: qsTr("临时停止遥控器服务？")
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: DiagnosticsController.testVbCableChannelWithBridgeRestart()

        contentItem: UiLabel {
            tokens: root.tokens
            kind: bodyKind
            wrapMode: Text.WordWrap
            text: qsTr("检查虚拟声卡时会发送一小段测试音，并临时停止遥控器服务，结束后自动恢复。此检查不测试语音识别，平时说话不用先点它。")
        }
    }

    // "保存 / 重命名 / 复制" all collect one name; the automatic mode tag is
    // appended by the store, so the field never asks for it.
    SettingsDialog {
        id: voiceProfileNameDialog
        objectName: "voiceProfileNameDialog"
        tokens: root.tokens
        preferredWidth: 420
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        property string operation: "save"
        property string targetId: ""
        property string suggestedName: ""
        title: operation === "rename"
            ? qsTr("重命名配置")
            : operation === "copy"
                ? qsTr("复制配置") : qsTr("保存为配置")
        onAboutToShow: {
            voiceProfileNameField.text = suggestedName
            Qt.callLater(voiceProfileNameField.forceActiveFocus)
        }
        onAccepted: root.runVoiceProfileAction(
            voiceProfileNameDialog.operation,
            voiceProfileNameDialog.targetId,
            voiceProfileNameField.text)

        contentItem: ColumnLayout {
            spacing: root.tokens.spacingSmall
            UiLabel {
                tokens: root.tokens
                kind: noteKind
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("名字后面会自动加上模式标签：模式1，或模式2 + 麦克风名字。")
            }
            CompactTextField {
                id: voiceProfileNameField
                objectName: "voiceProfileNameField"
                tokens: root.tokens
                Layout.fillWidth: true
                placeholderText: qsTr("配置名称")
                Accessible.name: qsTr("配置名称")
                onAccepted: voiceProfileNameDialog.accept()
            }
        }
    }

    SettingsDialog {
        id: voiceProfileDeleteDialog
        objectName: "voiceProfileDeleteDialog"
        tokens: root.tokens
        preferredWidth: 420
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: qsTr("删除配置？")
        property string pendingProfileId: ""
        property string pendingProfileLabel: ""
        onAccepted: root.runVoiceProfileAction(
            "delete", voiceProfileDeleteDialog.pendingProfileId, "")

        contentItem: UiLabel {
            tokens: root.tokens
            kind: bodyKind
            wrapMode: Text.WordWrap
            text: qsTr("这会删除配置“%1”，删除后无法撤销。当前按键设置和其他配置不受影响。")
                .arg(voiceProfileDeleteDialog.pendingProfileLabel)
        }
    }

    FileDialog {
        id: voiceProfileExportDialog
        objectName: "voiceProfileExportFileDialog"
        title: qsTr("导出配置")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: [qsTr("配置文件 (*.json)")]
        property string pendingProfileId: ""
        onAccepted: root.runVoiceProfileAction(
            "export", voiceProfileExportDialog.pendingProfileId, selectedFile.toString())
    }

    FileDialog {
        id: voiceProfileImportDialog
        objectName: "voiceProfileImportFileDialog"
        title: qsTr("导入配置")
        fileMode: FileDialog.OpenFile
        nameFilters: [qsTr("配置文件 (*.json)")]
        onAccepted: root.runVoiceProfileAction("import", "", selectedFile.toString())
    }

    FileDialog {
        id: voiceProfileExportAllDialog
        objectName: "voiceProfileExportAllFileDialog"
        title: qsTr("导出全部配置")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: [qsTr("配置档案 (*.json)")]
        onAccepted: {
            const result = SettingsController.exportAllMappingPresets(
                selectedFile.toString())
            root.voiceProfileMessage = String(result.message || "")
        }
    }

    // One place to browse, apply and maintain every saved profile. Keeping the
    // cards here (instead of inline on the voice page) gives the row actions
    // enough width and keeps the settings page scannable.
    SettingsDialog {
        id: voiceProfileManagerDialog
        objectName: "voiceProfileManagerDialog"
        tokens: root.tokens
        preferredWidth: 680
        title: qsTr("配置档案")
        titleNote: qsTr("切换配置会同时切换按键映射、语音模式和麦克风")
        closeButtonObjectName: "voiceProfileManagerCloseButton"
        dismissalEnabled: !root.configurationWriteBusy

        contentItem: ColumnLayout {
            spacing: root.tokens.spacingMedium

            ScrollView {
                id: voiceProfileScroll
                objectName: "voiceProfileListScroll"
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(360,
                    Math.max(76, voiceProfileList.implicitHeight))
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    id: voiceProfileList
                    objectName: "voiceProfileList"
                    width: voiceProfileScroll.availableWidth
                    spacing: 0

                    Repeater {
                        objectName: "voiceProfileRepeater"
                        model: SettingsController.voiceProfiles

                        Rectangle {
                            id: profileRow
                            required property var modelData
                            readonly property bool automatic:
                                Boolean(modelData.automatic)
                            readonly property bool applied:
                                Boolean(modelData.applied)
                            readonly property string profileId: String(modelData.id)
                            readonly property string conflictText:
                                String(modelData.voice_conflict_text || "")
                            objectName: "voiceProfileRow_"
                                + (automatic ? "global" : String(index))
                            Layout.fillWidth: true
                            implicitHeight: profileColumn.implicitHeight + 12
                            radius: root.tokens.cornerRadiusControl
                            color: applied ? root.tokens.accentSoft : "transparent"

                            ColumnLayout {
                                id: profileColumn
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.topMargin: 6
                                anchors.bottomMargin: 6
                                spacing: root.tokens.spacingTiny

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: root.tokens.spacingSmall

                                    UiLabel {
                                        id: profileLabel
                                        objectName: "voiceProfileLabel"
                                        tokens: root.tokens
                                        kind: bodyKind
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        text: String(profileRow.modelData.label || "")
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        HoverHandler { id: profileLabelHover }
                                        CompactToolTip {
                                            tokens: root.tokens
                                            active: profileLabelHover.hovered
                                                && profileLabel.truncated
                                            text: String(profileRow.modelData.label || "")
                                        }
                                    }
                                    UiLabel {
                                        tokens: root.tokens
                                        kind: noteKind
                                        visible: profileRow.applied
                                        text: qsTr("当前使用")
                                        color: root.tokens.successColor
                                        font.weight: Font.Medium
                                    }
                                }

                                UiLabel {
                                    objectName: "voiceProfileConflictLabel"
                                    tokens: root.tokens
                                    kind: noteKind
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    visible: profileRow.conflictText.length > 0
                                    text: profileRow.conflictText
                                    color: root.tokens.errorColor
                                    wrapMode: Text.WordWrap
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: root.tokens.spacingSmall

                                    CompactButton {
                                        objectName: "applyVoiceProfileButton"
                                        tokens: root.tokens
                                        compactMinimumWidth: tokens.buttonWidth4Chars
                                        text: qsTr("应用此配置")
                                        enabled: !root.configurationWriteBusy
                                        onClicked: root.runVoiceProfileAction(
                                            "apply", profileRow.profileId, "")
                                    }
                                    CompactButton {
                                        objectName: "updateVoiceProfileButton"
                                        tokens: root.tokens
                                        compactMinimumWidth: tokens.buttonWidth4Chars
                                        visible: !profileRow.automatic
                                        text: qsTr("更新")
                                        enabled: !root.configurationWriteBusy
                                        onClicked: root.runVoiceProfileAction(
                                            "update", profileRow.profileId, "")
                                    }
                                    Item { Layout.fillWidth: true }
                                    CompactButton {
                                        objectName: "renameVoiceProfileButton"
                                        tokens: root.tokens
                                        compactMinimumWidth: tokens.buttonWidth4Chars
                                        visible: !profileRow.automatic
                                        text: qsTr("重命名")
                                        enabled: !root.configurationWriteBusy
                                        onClicked: {
                                            voiceProfileNameDialog.operation = "rename"
                                            voiceProfileNameDialog.targetId =
                                                profileRow.profileId
                                            voiceProfileNameDialog.suggestedName =
                                                String(profileRow.modelData.name || "")
                                            voiceProfileNameDialog.open()
                                        }
                                    }
                                    CompactButton {
                                        objectName: "copyVoiceProfileButton"
                                        tokens: root.tokens
                                        compactMinimumWidth: tokens.buttonWidth4Chars
                                        text: qsTr("复制")
                                        enabled: !root.configurationWriteBusy
                                        onClicked: {
                                            voiceProfileNameDialog.operation = "copy"
                                            voiceProfileNameDialog.targetId =
                                                profileRow.profileId
                                            voiceProfileNameDialog.suggestedName =
                                                profileRow.automatic
                                                    ? qsTr("全局配置副本")
                                                    : String(profileRow.modelData.name || "")
                                                        + qsTr(" 副本")
                                            voiceProfileNameDialog.open()
                                        }
                                    }
                                    CompactButton {
                                        objectName: "exportVoiceProfileButton"
                                        tokens: root.tokens
                                        compactMinimumWidth: tokens.buttonWidth4Chars
                                        text: qsTr("导出")
                                        enabled: !root.configurationWriteBusy
                                        onClicked: {
                                            voiceProfileExportDialog.pendingProfileId =
                                                profileRow.profileId
                                            voiceProfileExportDialog.open()
                                        }
                                    }
                                    CompactButton {
                                        objectName: "deleteVoiceProfileButton"
                                        tokens: root.tokens
                                        compactMinimumWidth: tokens.buttonWidth4Chars
                                        visible: !profileRow.automatic
                                        text: qsTr("删除")
                                        enabled: !root.configurationWriteBusy
                                        onClicked: {
                                            voiceProfileDeleteDialog.pendingProfileId =
                                                profileRow.profileId
                                            voiceProfileDeleteDialog.pendingProfileLabel =
                                                String(profileRow.modelData.label || "")
                                            voiceProfileDeleteDialog.open()
                                        }
                                    }
                                }
                            }

                            SettingsRowDivider {
                                tokens: root.tokens
                            }
                        }
                    }
                }
            }

            UiLabel {
                objectName: "voiceProfileDialogMessage"
                tokens: root.tokens
                kind: noteKind
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.voiceProfileMessage
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.tokens.spacingSmall

                CompactButton {
                    objectName: "saveVoiceProfileButton"
                    tokens: root.tokens
                    compactMinimumWidth: tokens.buttonWidth4Chars
                    text: qsTr("保存当前为配置")
                    enabled: !root.configurationWriteBusy
                    onClicked: {
                        voiceProfileNameDialog.operation = "save"
                        voiceProfileNameDialog.targetId = ""
                        voiceProfileNameDialog.suggestedName = ""
                        voiceProfileNameDialog.open()
                    }
                }
                CompactButton {
                    objectName: "exportAllVoiceProfilesButton"
                    tokens: root.tokens
                    compactMinimumWidth: tokens.buttonWidth4Chars
                    text: qsTr("导出全部")
                    enabled: !root.configurationWriteBusy
                    onClicked: voiceProfileExportAllDialog.open()
                }
                CompactButton {
                    objectName: "importVoiceProfileButton"
                    tokens: root.tokens
                    compactMinimumWidth: tokens.buttonWidth4Chars
                    text: qsTr("导入配置")
                    enabled: !root.configurationWriteBusy
                    onClicked: voiceProfileImportDialog.open()
                }
                Item { Layout.fillWidth: true }
                CompactButton {
                    objectName: "closeVoiceProfileManagerButton"
                    tokens: root.tokens
                    compactMinimumWidth: tokens.buttonWidth4Chars
                    text: qsTr("关闭")
                    onClicked: voiceProfileManagerDialog.reject()
                }
            }
        }
    }

    Connections {
        target: SettingsController
        function onHotkeyCaptured(chord) {
            if (!root.voiceHotkeyRecording)
                return
            root.finishCapturedVoiceHotkey(chord)
        }
        function onHotkeyCaptureError(message) {
            root.pendingVoiceHotkey = ""
            if (!SettingsController.hotkeyCaptureActive)
                root.voiceHotkeyRecording = false
            root.voiceHotkeyCaptureError = message
        }
        function onHotkeyCaptureActiveChanged() {
            if (root.voiceHotkeyRecording
                    && !SettingsController.hotkeyCaptureActive) {
                if (root.pendingVoiceHotkey.length > 0)
                    root.commitCapturedVoiceHotkey()
                else
                    root.voiceHotkeyRecording = false
            }
        }
    }

    onVisibleChanged: {
        if (!visible)
            stopVoiceHotkeyCapture("page_hidden")
    }

    ScrollView {
        id: voiceScroll
        objectName: "voiceScroll"
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: voicePageContent
            objectName: "voicePageContent"
            width: Math.max(0, voiceScroll.availableWidth
                - tokens.pageHorizontalPadding * 2)
            x: tokens.pageHorizontalPadding
            y: tokens.pageVerticalPadding
            spacing: tokens.spacingSmall

            SectionFrame {
                objectName: "audioPrerequisiteSection"
                tokens: root.tokens
                Layout.fillWidth: true
                horizontalPadding: 0
                verticalPadding: 4
                contentSpacing: 0

                SettingsSectionTitle {
                    objectName: "audioPrerequisiteSectionTitle"
                    tokens: root.tokens
                    text: qsTr("音频前置") + " · " + SettingsController.activeRemoteLabel
                }

                InlineSettingsRow {
                    objectName: "virtualAudioRow"
                    tokens: root.tokens
                    stateColumnWidth: root.settingsStateColumnWidth
                    actionColumnWidth: root.settingsActionColumnWidth
                    titleText: qsTr("虚拟音频")
                    descriptionText: DiagnosticsController.driverErrorMessage.length > 0
                        ? DiagnosticsController.driverErrorMessage
                        : DiagnosticsController.driverStatusMessage.length > 0
                            ? DiagnosticsController.driverStatusMessage
                            : DiagnosticsController.driverInfoMessage.length > 0
                                ? DiagnosticsController.driverInfoMessage
                                : root.checkDetail(
                                    "vb_cable_endpoints",
                                    qsTr("检测并选择 CABLE Input")
                                )
                    stateText: DiagnosticsController.driverErrorMessage.length > 0
                        ? qsTr("点击“安装音频”")
                        : DiagnosticsController.driverStatusMessage.length > 0
                            ? qsTr("正常")
                            : DiagnosticsController.driverInfoMessage.length > 0
                                ? (DiagnosticsController.driverInfoMessage.indexOf(
                                    qsTr("正在")) >= 0
                                    ? qsTr("正在处理")
                                    : DiagnosticsController.driverInfoMessage.indexOf(
                                        qsTr("重启电脑")) >= 0
                                        ? qsTr("请重启电脑")
                                        : qsTr("点击“安装音频”"))
                                : root.checkState("vb_cable_endpoints")
                    stateColor: DiagnosticsController.driverErrorMessage.length > 0
                        ? tokens.errorColor
                        : DiagnosticsController.driverStatusMessage.length > 0
                            ? tokens.successColor
                            : DiagnosticsController.driverInfoMessage.length > 0
                                ? tokens.voiceAccent
                                : root.checkColor("vb_cable_endpoints")

                    editorData: [
                        CompactButton {
                            id: installVirtualAudioButton
                            objectName: "installVirtualAudioButton"
                            tokens: root.tokens
                            Layout.fillWidth: true
                            text: qsTr("安装音频")
                            enabled: !root.configurationWriteBusy
                                && !root.voiceHotkeyBusy
                            onClicked: driverConfirmDialog.open()
                            KeyNavigation.backtab: root.backTabTarget
                        }
                    ]
                    CompactButton {
                        objectName: "applyVirtualAudioButton"
                        tokens: root.tokens
                        Layout.fillWidth: true
                        text: qsTr("选推荐端点")
                        highlighted: true
                        visible: SettingsController.recommendedEndpointIndex >= 0
                            && SettingsController.selectedEndpointIndex
                                !== SettingsController.recommendedEndpointIndex
                        enabled: !root.configurationWriteBusy
                            && !root.voiceHotkeyBusy
                        onClicked: SettingsController.selectAndPersistOutputEndpointIndex(
                            SettingsController.recommendedEndpointIndex
                        )
                    }
                }

                InlineSettingsRow {
                    objectName: "outputEndpointRow"
                    tokens: root.tokens
                    stateColumnWidth: root.settingsStateColumnWidth
                    actionColumnWidth: root.settingsActionColumnWidth
                    titleText: qsTr("输出端点")
                    descriptionText: ""
                    stateText: root.checkState("output_endpoint")
                    stateColor: root.checkColor("output_endpoint")

                    editorData: [
                        SelectionComboBox {
                            id: endpointCombo
                            objectName: "endpointCombo"
                            tokens: root.tokens
                            recommendedIndex: SettingsController.recommendedEndpointIndex
                            Layout.fillWidth: true
                            Layout.minimumWidth: 180
                            model: SettingsController.endpointOptions
                            currentIndex: SettingsController.selectedEndpointIndex
                            onActivated: SettingsController.selectAndPersistOutputEndpointIndex(index)
                            enabled: !root.configurationWriteBusy
                                && !root.voiceHotkeyBusy
                            Accessible.name: qsTr("输出端点")
                        }
                    ]
                }

                InlineSettingsRow {
                    objectName: "microphonePrivacyRow"
                    tokens: root.tokens
                    actionColumnWidth: root.settingsActionColumnWidth
                    titleText: qsTr("麦克风权限")
                    descriptionText: qsTr("允许语音程序访问麦克风")
                    showDivider: false

                    CompactButton {
                        objectName: "openMicrophonePrivacyButton"
                        tokens: root.tokens
                        Layout.fillWidth: true
                        text: qsTr("麦克风隐私")
                        onClicked: SettingsController.openMicrophonePrivacySettings()
                    }
                }
            }

            SectionFrame {
                objectName: "voiceKeySection"
                tokens: root.tokens
                Layout.fillWidth: true
                horizontalPadding: 0
                verticalPadding: 4
                contentSpacing: 0

                SettingsSectionTitle {
                    objectName: "voiceKeySectionTitle"
                    tokens: root.tokens
                    text: qsTr("语音键")
                }

                InlineSettingsRow {
                    objectName: "voiceKeyHintRow"
                    tokens: root.tokens
                    titleText: qsTr("触发方式")
                    descriptionText: qsTr("短按一直开麦，再按一次停止；长按持续开麦，松开停止")
                    showDivider: true
                }

                InlineSettingsRow {
                    objectName: "voiceInputSourceRow"
                    tokens: root.tokens
                    editorColumnWidth: 240
                    titleText: qsTr("语音模式")
                    descriptionText: String(SettingsController.voiceInputSource) === "remote"
                        ? qsTr("模式1：遥控器麦克风；按下即触发，长按持续说话")
                        : qsTr("模式2：本机麦克风；按键可自定义，长短按都支持")
                    showDivider: true

                    editorData: [
                        SelectionComboBox {
                            objectName: "voiceInputSourceCombo"
                            tokens: root.tokens
                            Layout.fillWidth: true
                            Layout.minimumWidth: 180
                            model: SettingsController.voiceInputSourceOptions
                            currentIndex: SettingsController.voiceInputSourceIndex
                            onActivated: SettingsController.setVoiceInputSourceIndex(index)
                            enabled: !root.configurationWriteBusy
                                && !root.voiceHotkeyBusy
                            Accessible.name: qsTr("语音模式")
                        }
                    ]
                }

                InlineSettingsRow {
                    objectName: "voiceShortPressDismissRow"
                    tokens: root.tokens
                    actionColumnWidth: root.settingsActionColumnWidth
                    visible: String(SettingsController.voiceInputSource) === "remote"
                    titleText: qsTr("短按补偿")
                    descriptionText: qsTr("短按弹出后立刻再按一次，快速关闭输入框；长按不受影响。部分输入法不需要")
                    showDivider: true

                    CompactSwitch {
                        id: voiceShortPressDismissSwitch
                        objectName: "voiceShortPressDismissSwitch"
                        tokens: root.tokens
                        checked: SettingsController.voiceShortPressDismiss
                        enabled: !root.configurationWriteBusy
                            && !root.voiceHotkeyBusy
                        Accessible.name: qsTr("短按自动双击关闭输入框")
                        onToggled: {
                            if (checked !== SettingsController.voiceShortPressDismiss)
                                SettingsController.setVoiceShortPressDismiss(checked)
                        }
                    }
                }

                InlineSettingsRow {
                    objectName: "localMicrophoneRow"
                    tokens: root.tokens
                    editorColumnWidth: 300
                    visible: String(SettingsController.voiceInputSource) === "local"
                    titleText: qsTr("本机麦克风")
                    descriptionText: SettingsController.localMicrophoneOptions.length > 0
                        ? qsTr("模式2 使用的录音设备")
                        : qsTr("未找到录音设备，插好后点“刷新”")
                    showDivider: true

                    editorData: [
                        SelectionComboBox {
                            objectName: "localMicrophoneCombo"
                            tokens: root.tokens
                            Layout.fillWidth: true
                            Layout.minimumWidth: 180
                            model: SettingsController.localMicrophoneOptions
                            currentIndex: SettingsController.localMicrophoneIndex
                            onActivated: SettingsController.setLocalMicrophoneIndex(index)
                            enabled: !root.configurationWriteBusy
                                && !root.voiceHotkeyBusy
                                && SettingsController.localMicrophoneOptions.length > 0
                            Accessible.name: qsTr("本机麦克风")
                        },
                        CompactButton {
                            objectName: "refreshLocalMicrophoneButton"
                            tokens: root.tokens
                            compactMinimumWidth: tokens.buttonWidth4Chars
                            text: qsTr("刷新")
                            onClicked: SettingsController.refreshLocalMicrophones()
                        }
                    ]
                }

                Repeater {
                    id: voiceSlotRepeater
                    objectName: "voiceSlotHotkeyRepeater"
                    model: root.voiceSlots

                    InlineSettingsRow {
                        id: slotRow
                        required property int modelData
                        readonly property int slot: modelData
                        function recordingField() {
                            return root.voiceHotkeyRecording
                                    && root.voiceRecordingSlot === slot
                                ? slotHotkeyField : null
                        }
                        function claimFocus() {
                            if (root.voiceHotkeyRecording
                                    && root.voiceRecordingSlot === slot)
                                slotHotkeyField.forceActiveFocus()
                        }

                        objectName: "voiceHotkeyRow"
                        tokens: root.tokens
                        stateColumnWidth: root.settingsStateColumnWidth
                        actionColumnWidth: root.settingsActionColumnWidth
                        showDivider: true
                        // Track the QVariantMap property (not the voiceSlotHotkeyText()
                        // method, which QML cannot observe) so the row refreshes whenever
                        // the slot shortcut changes.
                        readonly property string slotHotkey: {
                            var entries = SettingsController.voiceSlotHotkeys
                            var value = entries[slot]
                            return value === undefined ? "" : String(value)
                        }
                        titleText: SettingsController.voiceSlotLabel(slot)
                        descriptionText: !SettingsController.voiceSlotEditable(slot)
                            ? qsTr("模式1 只用语音1（遥控器话筒键）；要把它绑到别的按键请切到模式2")
                            : root.voiceHotkeyCaptureError.length > 0
                                    && root.voiceRecordingSlot === slot
                                ? root.voiceHotkeyCaptureError
                                : qsTr("为该语音键单独录入键盘快捷键")
                        stateText: root.voiceHotkeyRecording
                                && root.voiceRecordingSlot === slot
                            ? SettingsController.hotkeyCaptureReady
                                ? qsTr("录入中") : qsTr("准备中")
                            : root.voiceHotkeyBusy
                                ? qsTr("正在处理")
                                : slotRow.slotHotkey.length === 0
                                    ? qsTr("待录入") : qsTr("已保存")
                        stateColor: root.voiceHotkeyRecording
                                && root.voiceRecordingSlot === slot
                            ? tokens.voiceAccent
                            : slotRow.slotHotkey.length === 0
                                ? tokens.errorColor : tokens.successColor

                        editorData: [
                            Item {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 130
                                implicitHeight: tokens.controlHeight

                                CompactTextField {
                                    id: slotHotkeyField
                                    objectName: "voiceSlotHotkeyField"
                                    anchors.fill: parent
                                    tokens: root.tokens
                                    readOnly: true
                                    background.visible: root.voiceHotkeyRecording
                                        && root.voiceRecordingSlot === slot
                                    activeFocusOnPress: root.voiceHotkeyRecording
                                        && root.voiceRecordingSlot === slot
                                    activeFocusOnTab: root.voiceHotkeyRecording
                                        && root.voiceRecordingSlot === slot
                                    selectByMouse: false
                                    enabled: !root.voiceHotkeyBusy
                                        && !root.configurationWriteBusy
                                    text: root.voiceHotkeyRecording
                                            && root.voiceRecordingSlot === slot
                                        ? SettingsController.hotkeyCaptureReady
                                            ? qsTr("请按快捷键") : qsTr("正在准备…")
                                        : SettingsController.formatHotkeyText(
                                            slotRow.slotHotkey)
                                    color: root.voiceHotkeyRecording
                                            && root.voiceRecordingSlot === slot
                                        ? tokens.accent : tokens.textPrimary
                                    placeholderText: qsTr("尚未录入")
                                    Accessible.name: qsTr("录入语音快捷键")
                                    Keys.onEscapePressed: root.stopVoiceHotkeyCapture(
                                        "escape_pressed")
                                    onActiveFocusChanged: {
                                        if (!activeFocus && root.voiceHotkeyRecording
                                                && root.voiceRecordingSlot === slot)
                                            root.stopVoiceHotkeyCapture("focus_lost")
                                    }
                                }
                            }
                        ]
                        CompactButton {
                            objectName: "recordVoiceHotkeyButton"
                            tokens: root.tokens
                            Layout.fillWidth: true
                            compactMinimumWidth: tokens.buttonWidth4Chars
                            text: root.voiceHotkeyRecording
                                    && root.voiceRecordingSlot === slot
                                ? qsTr("停止") : qsTr("手动录入")
                            enabled: !root.voiceHotkeyBusy
                                && !root.configurationWriteBusy
                                && !root.voiceHotkeyRuntimeBusy
                                && SettingsController.voiceSlotEditable(slot)
                            onClicked: root.startVoiceHotkeyCapture(slot)
                        }
                    }
                }
            }

            // Saved profiles: each one bundles a button layout, the voice mode
            // and (for 模式2) the microphone. The page stays compact - the full
            // list lives in the manager dialog so its many actions never wrap.
            SectionFrame {
                objectName: "voiceProfileSection"
                tokens: root.tokens
                Layout.fillWidth: true
                horizontalPadding: 0
                verticalPadding: 4
                contentSpacing: 0

                SettingsSectionTitle {
                    objectName: "voiceProfileSectionTitle"
                    tokens: root.tokens
                    text: qsTr("配置档案")
                }

                InlineSettingsRow {
                    objectName: "voiceProfileHintRow"
                    tokens: root.tokens
                    stateColumnWidth: 0
                    actionColumnWidth: root.settingsActionColumnWidth
                    titleText: qsTr("已保存配置")
                    descriptionText: root.activeVoiceProfileName.length > 0
                        ? qsTr("当前使用「%1」；可切换按键映射、语音模式与麦克风")
                            .arg(root.activeVoiceProfileName)
                        : qsTr("切换按键映射、语音模式与麦克风")
                    showDivider: false

                    CompactButton {
                        objectName: "manageVoiceProfilesButton"
                        tokens: root.tokens
                        compactMinimumWidth: root.settingsActionColumnWidth
                        text: qsTr("管理配置…")
                        enabled: !root.configurationWriteBusy
                        onClicked: voiceProfileManagerDialog.open()
                    }
                }

                UiLabel {
                    objectName: "voiceProfileMessage"
                    tokens: root.tokens
                    kind: noteKind
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    Layout.bottomMargin: 6
                    visible: text.length > 0 && !voiceProfileManagerDialog.visible
                    text: root.voiceProfileMessage
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                }
            }

            SectionFrame {
                objectName: "voiceTestSection"
                tokens: root.tokens
                Layout.fillWidth: true
                horizontalPadding: 0
                verticalPadding: 4
                contentSpacing: 0

                SettingsSectionTitle {
                    objectName: "voiceTestSectionTitle"
                    tokens: root.tokens
                    text: qsTr("测试验证")
                }

                InlineSettingsRow {
                    objectName: "soundChannelTestRow"
                    tokens: root.tokens
                    stateColumnWidth: root.settingsStateColumnWidth
                    actionColumnWidth: root.settingsActionColumnWidth
                    editorColumnVisible: DiagnosticsController.vbCableBridgeRecoveryNeeded
                    showDivider: false
                    titleText: qsTr("虚拟声卡")
                    descriptionText: DiagnosticsController.vbCableTestMessage.length > 0
                        ? DiagnosticsController.vbCableTestMessage
                        : qsTr("只检查声音通路，不验证识别结果")
                    descriptionObjectName: "soundChannelTestDescription"
                    stateText: DiagnosticsController.vbCableBridgeRecoveryNeeded
                        ? qsTr("点击“启动服务”")
                        : DiagnosticsController.vbCableTestRunning
                        ? qsTr("测试中")
                        : DiagnosticsController.vbCableTestStatus === "pass"
                            ? qsTr("正常")
                            : DiagnosticsController.vbCableTestStatus === "fail"
                                ? qsTr("检查未通过") : qsTr("按需检查")
                    stateColor: DiagnosticsController.vbCableBridgeRecoveryNeeded
                        ? tokens.errorColor
                        : DiagnosticsController.vbCableTestRunning
                        ? tokens.voiceAccent
                        : DiagnosticsController.vbCableTestStatus === "pass"
                            ? tokens.successColor
                            : DiagnosticsController.vbCableTestStatus === "fail"
                                ? tokens.errorColor : tokens.disabledText

                    editorData: [
                        CompactButton {
                            objectName: "recoverBridgeButton"
                            visible: DiagnosticsController.vbCableBridgeRecoveryNeeded
                            tokens: root.tokens
                            compactMinimumWidth: tokens.buttonWidth4Chars
                            text: qsTr("启动服务")
                            highlighted: true
                            enabled: !root.configurationWriteBusy
                                && !root.voiceHotkeyBusy
                            onClicked: SettingsController.startBridge()
                        }
                    ]
                    CompactButton {
                        id: testVbCableChannelButton
                        objectName: "testVbCableChannelButton"
                        tokens: root.tokens
                        Layout.fillWidth: true
                        text: DiagnosticsController.vbCableTestRunning
                            ? qsTr("检查中…") : qsTr("检查虚拟声卡")
                        enabled: !DiagnosticsController.isRefreshing
                            && !root.configurationWriteBusy
                            && !root.voiceHotkeyBusy
                        onClicked: SettingsController.bridgeRunning
                            ? bridgeTestConfirmDialog.open()
                            : DiagnosticsController.testVbCableChannel()
                        KeyNavigation.tab: root.tabTarget
                    }
                }

            }

            UiLabel {
                objectName: "voiceGestureNote"
                tokens: root.tokens
                kind: noteKind
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: qsTr("语音键按下后，遥控器麦克风会按触发方式开启。开启期间请避免同时操作其他按键或鼠标；录入快捷键时请留意与常用操作的冲突。")
            }

            Item { Layout.preferredHeight: tokens.pageVerticalPadding }
        }
    }

    TapHandler {
        parent: voiceScroll.contentItem
        objectName: "voiceHotkeyOutsideTapHandler"
        enabled: root.voiceHotkeyRecording
        acceptedButtons: Qt.AllButtons
        onTapped: function(eventPoint, button) {
            if (!root.tapInsideRecordingField(eventPoint))
                root.stopVoiceHotkeyCapture()
        }
    }
}
