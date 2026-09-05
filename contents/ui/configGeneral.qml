import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.Page {
    id: root
    title: i18n("General")

    function alignmentIndexForValue(value) {
        var normalized = String(value || "center").toLowerCase();
        if (normalized === "left") {
            return 0;
        }
        if (normalized === "right") {
            return 2;
        }
        return 1;
    }

    property alias cfg_customTitle: customTitleField.text
    property string cfg_customTitleDefault
    property alias cfg_apiUrl: apiUrlField.text
    property string cfg_apiUrlDefault
    property alias cfg_requestHeaders: requestHeadersField.text
    property string cfg_requestHeadersDefault
    property alias cfg_jsonPaths: jsonPathsField.text
    property string cfg_jsonPathsDefault
    property alias cfg_hoverJsonPaths: hoverJsonPathsField.text
    property string cfg_hoverJsonPathsDefault
    property alias cfg_valueCount: valueCountField.value
    property int cfg_valueCountDefault
    property alias cfg_valueSeparator: separatorField.text
    property string cfg_valueSeparatorDefault
    property alias cfg_hoverValueSeparator: hoverSeparatorField.text
    property string cfg_hoverValueSeparatorDefault
    property alias cfg_refreshIntervalSeconds: intervalField.value
    property int cfg_refreshIntervalSecondsDefault
    property alias cfg_displayWidth: displayWidthField.value
    property int cfg_displayWidthDefault
    property string cfg_textAlignment: "center"
    property string cfg_textAlignmentDefault
    property bool cfg_expanding
    property alias cfg_length: displayWidthField.value

    onCfg_textAlignmentChanged: {
        var targetIndex = alignmentIndexForValue(cfg_textAlignment);
        if (alignmentField.currentIndex !== targetIndex) {
            alignmentField.currentIndex = targetIndex;
        }
    }

    QQC2.ScrollView {
        id: settingsScrollView
        anchors.fill: parent
        clip: true

        Kirigami.FormLayout {
            width: settingsScrollView.availableWidth

            QQC2.TextField {
                id: customTitleField
                Kirigami.FormData.label: i18n("Title:")
                placeholderText: i18n("Data Feed Panel")
            }

            QQC2.TextField {
                id: apiUrlField
                Kirigami.FormData.label: i18n("API URL:")
                placeholderText: "http://localhost:3000"
            }

            QQC2.TextArea {
                id: requestHeadersField
                Kirigami.FormData.label: i18n("HTTP headers (one per line):")
                placeholderText: "Authorization: Bearer <token>"
                wrapMode: TextEdit.NoWrap
                implicitHeight: Kirigami.Units.gridUnit * 4
            }

            QQC2.TextArea {
                id: jsonPathsField
                Kirigami.FormData.label: i18n("JSON paths (line/comma separated):")
                placeholderText: "value\nvalue2"
                wrapMode: TextEdit.NoWrap
                implicitHeight: Kirigami.Units.gridUnit * 5
            }

            QQC2.TextArea {
                id: hoverJsonPathsField
                Kirigami.FormData.label: i18n("Hover JSON paths (line/comma separated):")
                placeholderText: "value3\nvalue4"
                wrapMode: TextEdit.NoWrap
                implicitHeight: Kirigami.Units.gridUnit * 5
            }

            QQC2.SpinBox {
                id: valueCountField
                Kirigami.FormData.label: i18n("Number of values:")
                from: 1
                to: 20
                editable: true
            }

            QQC2.TextField {
                id: separatorField
                Kirigami.FormData.label: i18n("Separator:")
                placeholderText: " | "
            }

            QQC2.TextField {
                id: hoverSeparatorField
                Kirigami.FormData.label: i18n("Hover separator:")
                placeholderText: "\\n"
            }

            QQC2.SpinBox {
                id: intervalField
                Kirigami.FormData.label: i18n("Refresh interval (s):")
                from: 1
                to: 86400
                editable: true
            }

            QQC2.SpinBox {
                id: displayWidthField
                Kirigami.FormData.label: i18n("Display width (px):")
                from: 40
                to: 2000
                editable: true
            }

            QQC2.ComboBox {
                id: alignmentField
                Kirigami.FormData.label: i18n("Text alignment:")
                model: [
                    {
                        text: i18n("Left"),
                        value: "left"
                    },
                    {
                        text: i18n("Center"),
                        value: "center"
                    },
                    {
                        text: i18n("Right"),
                        value: "right"
                    }
                ]
                textRole: "text"

                Component.onCompleted: {
                    currentIndex = root.alignmentIndexForValue(root.cfg_textAlignment);
                }

                onCurrentIndexChanged: {
                    if (currentIndex < 0) {
                        return;
                    }

                    var selected = model[currentIndex].value;
                    if (root.cfg_textAlignment !== selected) {
                        root.cfg_textAlignment = selected;
                    }
                }
            }
        }
    }
}
