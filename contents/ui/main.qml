import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents

import "../code/fetcher.js" as Fetcher

PlasmoidItem {
    id: root

    property string placeholderText: "--"
    property string displayValue: placeholderText
    property string hoverDisplayValue: placeholderText
    property bool isFetching: false
    property int fetchGeneration: 0
    property var activeRequest: null

    readonly property string configuredTitle: {
        var customTitle = String(plasmoid.configuration.customTitle || "").trim();
        if (customTitle.length > 0) {
            return customTitle;
        }

        if (plasmoid.metaData && plasmoid.metaData.name) {
            return String(plasmoid.metaData.name);
        }

        return "Data Feed Panel";
    }

    toolTipMainText: root.configuredTitle
    toolTipSubText: root.hoverDisplayValue

    function parseConfiguredPaths(rawPaths) {
        var text = String(rawPaths || "");
        text = text.replace(/\\n/g, "\n");
        var tokens = text.split(/[\n,;]+/);
        var parsed = [];

        for (var i = 0; i < tokens.length; i++) {
            var value = tokens[i].trim();
            if (value.length > 0) {
                parsed.push(value);
            }
        }

        return parsed;
    }

    function parseSeparator(rawValue, fallbackValue) {
        var value = rawValue !== undefined && rawValue !== null ? String(rawValue) : "";
        if (value.length === 0) {
            value = fallbackValue;
        }

        return value
            .replace(/\\n/g, "\n")
            .replace(/\\t/g, "\t");
    }

    function parseRequestHeaders(rawHeaders) {
        var headers = {};
        var text = String(rawHeaders || "").replace(/\\n/g, "\n");
        var lines = text.split(/\n+/);

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.length === 0) {
                continue;
            }

            var separatorIndex = line.indexOf(":");
            if (separatorIndex <= 0) {
                console.warn("Data Feed Panel ignored invalid header entry:", line);
                continue;
            }

            var name = line.slice(0, separatorIndex).trim();
            var value = line.slice(separatorIndex + 1).trim();
            if (name.length === 0 || value.length === 0) {
                console.warn("Data Feed Panel ignored empty header name/value:", line);
                continue;
            }

            headers[name] = value;
        }

        return headers;
    }

    readonly property string configuredUrl: {
        var url = String(plasmoid.configuration.apiUrl || "").trim();
        return url.length > 0 ? url : "http://localhost:3000";
    }

    readonly property var configuredJsonPaths: {
        var parsed = root.parseConfiguredPaths(plasmoid.configuration.jsonPaths);
        if (parsed.length === 0) {
            parsed.push("value");
        }
        return parsed;
    }

    readonly property var configuredHoverJsonPaths: root.parseConfiguredPaths(plasmoid.configuration.hoverJsonPaths)

    readonly property var configuredRequestHeaders: {
        return root.parseRequestHeaders(plasmoid.configuration.requestHeaders);
    }

    readonly property int configuredValueCount: {
        var count = Number(plasmoid.configuration.valueCount);
        if (!isFinite(count) || count < 1) {
            count = 1;
        }
        return Math.round(count);
    }

    readonly property string configuredSeparator: {
        return root.parseSeparator(plasmoid.configuration.valueSeparator, " | ");
    }

    readonly property string configuredHoverSeparator: {
        return root.parseSeparator(plasmoid.configuration.hoverValueSeparator, "\n");
    }

    readonly property var activeJsonPaths: {
        var selected = [];
        var configured = root.configuredJsonPaths;
        var requestedCount = root.configuredValueCount;

        for (var i = 0; i < requestedCount; i++) {
            if (i < configured.length) {
                selected.push(configured[i]);
                continue;
            }

            if (i === 0) {
                selected.push("value");
            } else {
                selected.push("value" + String(i + 1));
            }
        }

        return selected;
    }

    readonly property int configuredIntervalMs: {
        var seconds = Number(plasmoid.configuration.refreshIntervalSeconds);
        if (!isFinite(seconds) || seconds < 1) {
            seconds = 60;
        }
        return Math.round(seconds * 1000);
    }

    readonly property int configuredDisplayWidth: {
        var width = Number(plasmoid.configuration.displayWidth);
        if (!isFinite(width) || width < 40) {
            width = 140;
        }
        return Math.round(width);
    }

    readonly property int configuredHorizontalAlignment: {
        var alignment = String(plasmoid.configuration.textAlignment || "center").toLowerCase();
        if (alignment === "left") {
            return Text.AlignLeft;
        }
        if (alignment === "right") {
            return Text.AlignRight;
        }
        return Text.AlignHCenter;
    }

    preferredRepresentation: compactRepresentation

    compactRepresentation: Item {
        Layout.minimumWidth: root.configuredDisplayWidth
        Layout.preferredWidth: root.configuredDisplayWidth
        implicitWidth: root.configuredDisplayWidth
        implicitHeight: compactLabel.implicitHeight

        PlasmaComponents.Label {
            id: compactLabel
            anchors.fill: parent
            text: root.displayValue
            horizontalAlignment: root.configuredHorizontalAlignment
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    fullRepresentation: Item {
        PlasmaComponents.Label {
            anchors.centerIn: parent
            text: root.displayValue
        }
    }

    function fetchAndUpdate() {
        if (root.isFetching) {
            return;
        }

        var panelPaths = root.activeJsonPaths;
        var hoverPaths = root.configuredHoverJsonPaths;
        var requestPaths = panelPaths.slice(0);

        for (var i = 0; i < hoverPaths.length; i++) {
            if (requestPaths.indexOf(hoverPaths[i]) === -1) {
                requestPaths.push(hoverPaths[i]);
            }
        }

        root.isFetching = true;
        root.fetchGeneration += 1;
        var requestGeneration = root.fetchGeneration;
        fetchWatchdog.restart();
        root.activeRequest = Fetcher.fetchValues(root.configuredUrl, requestPaths, root.configuredRequestHeaders, function(result) {
            if (requestGeneration !== root.fetchGeneration) {
                return;
            }

            root.isFetching = false;
            root.activeRequest = null;
            fetchWatchdog.stop();
            if (result.ok) {
                var valuesByPath = {};
                for (var i = 0; i < requestPaths.length; i++) {
                    valuesByPath[requestPaths[i]] = result.values[i];
                }

                var panelValues = [];
                for (var panelIndex = 0; panelIndex < panelPaths.length; panelIndex++) {
                    panelValues.push(valuesByPath[panelPaths[panelIndex]]);
                }

                root.displayValue = panelValues.join(root.configuredSeparator);

                if (hoverPaths.length > 0) {
                    var hoverValues = [];
                    for (var hoverIndex = 0; hoverIndex < hoverPaths.length; hoverIndex++) {
                        hoverValues.push(valuesByPath[hoverPaths[hoverIndex]]);
                    }
                    root.hoverDisplayValue = hoverValues.join(root.configuredHoverSeparator);
                } else {
                    root.hoverDisplayValue = root.displayValue;
                }
                return;
            }

            root.displayValue = root.placeholderText;
            root.hoverDisplayValue = root.placeholderText;
            console.warn("Data Feed Panel fetch failed:", result.error);
        });
    }

    function abortActiveRequest() {
        if (root.activeRequest) {
            root.activeRequest.abort();
            root.activeRequest = null;
        }
    }

    function restartFetch() {
        root.fetchGeneration += 1;
        root.abortActiveRequest();
        root.isFetching = false;
        fetchWatchdog.stop();
        root.fetchAndUpdate();
    }

    Timer {
        id: pollTimer
        interval: root.configuredIntervalMs
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.fetchAndUpdate()
    }

    Timer {
        id: fetchWatchdog
        interval: 15000
        repeat: false
        onTriggered: {
            if (!root.isFetching) {
                return;
            }

            root.fetchGeneration += 1;
            root.abortActiveRequest();
            root.isFetching = false;
            console.warn("Data Feed Panel fetch timed out without a response; retrying");
            root.fetchAndUpdate();
        }
    }

    Connections {
        target: plasmoid.configuration

        function onApiUrlChanged() {
            root.restartFetch();
        }

        function onJsonPathsChanged() {
            root.restartFetch();
        }

        function onRequestHeadersChanged() {
            root.restartFetch();
        }

        function onHoverJsonPathsChanged() {
            root.restartFetch();
        }

        function onValueCountChanged() {
            root.restartFetch();
        }

        function onValueSeparatorChanged() {
            root.restartFetch();
        }

        function onHoverValueSeparatorChanged() {
            root.restartFetch();
        }

        function onRefreshIntervalSecondsChanged() {
            pollTimer.restart();
            root.restartFetch();
        }
    }
}
