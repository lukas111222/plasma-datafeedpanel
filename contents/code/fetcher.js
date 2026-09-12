.pragma library

function extractByPath(obj, path) {
    if (!path || path.trim() === "") {
        return obj;
    }

    var current = obj;
    var segments = path.split(".");

    for (var i = 0; i < segments.length; i++) {
        var key = segments[i].trim();
        if (key === "") {
            continue;
        }
        if (current === null || current === undefined || typeof current !== "object" || !(key in current)) {
            throw new Error("Path segment not found: " + key);
        }
        current = current[key];
    }

    return current;
}

function toDisplayString(value) {
    if (typeof value === "number") {
        if (isFinite(value)) {
            return String(value);
        }
        throw new Error("Value is not finite");
    }

    if (typeof value === "string") {
        var trimmed = value.trim();
        if (trimmed.length === 0) {
            throw new Error("Value is empty");
        }
        return trimmed;
    }

    throw new Error("Value must be a number or text");
}

function normalizePaths(paths) {
    if (!paths || !Array.isArray(paths)) {
        throw new Error("Paths must be an array");
    }

    var normalized = [];
    for (var i = 0; i < paths.length; i++) {
        var path = String(paths[i] || "").trim();
        if (path.length === 0) {
            throw new Error("Path must not be empty");
        }
        normalized.push(path);
    }

    if (normalized.length === 0) {
        throw new Error("At least one path is required");
    }

    return normalized;
}

function mapDisplayValues(payload, paths) {
    var values = [];
    for (var i = 0; i < paths.length; i++) {
        var rawValue = extractByPath(payload, paths[i]);
        values.push(toDisplayString(rawValue));
    }
    return values;
}

function normalizeHeaders(headers) {
    if (headers === null || headers === undefined) {
        return {};
    }

    if (typeof headers !== "object") {
        throw new Error("Headers must be an object");
    }

    var normalized = {};
    for (var name in headers) {
        if (!Object.prototype.hasOwnProperty.call(headers, name)) {
            continue;
        }

        var normalizedName = String(name || "").trim();
        var normalizedValue = String(headers[name] || "").trim();
        if (normalizedName.length === 0 || normalizedValue.length === 0) {
            continue;
        }
        normalized[normalizedName] = normalizedValue;
    }

    return normalized;
}

function fetchValues(url, paths, headers, callback) {
    var normalizedPaths;
    var normalizedHeaders;
    try {
        normalizedPaths = normalizePaths(paths);
        normalizedHeaders = normalizeHeaders(headers);
    } catch (error) {
        callback({ ok: false, error: String(error) });
        return;
    }

    var xhr = new XMLHttpRequest();
    var completed = false;

    function complete(result) {
        if (completed) {
            return;
        }

        completed = true;
        callback(result);
    }

    try {
        xhr.open("GET", url);
        xhr.timeout = 10000;

        for (var headerName in normalizedHeaders) {
            if (Object.prototype.hasOwnProperty.call(normalizedHeaders, headerName)) {
                xhr.setRequestHeader(headerName, normalizedHeaders[headerName]);
            }
        }
    } catch (error) {
        complete({ ok: false, error: String(error) });
        return;
    }

    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
            return;
        }

        if (xhr.status < 200 || xhr.status >= 300) {
            complete({ ok: false, error: "HTTP " + xhr.status });
            return;
        }

        try {
            var payload = JSON.parse(xhr.responseText);
            var displayValues = mapDisplayValues(payload, normalizedPaths);
            complete({ ok: true, values: displayValues });
        } catch (error) {
            complete({ ok: false, error: String(error) });
        }
    };

    xhr.onerror = function() {
        complete({ ok: false, error: "Network error" });
    };

    xhr.ontimeout = function() {
        complete({ ok: false, error: "Timeout" });
    };

    try {
        xhr.send();
    } catch (error) {
        complete({ ok: false, error: String(error) });
        return null;
    }

    return xhr;
}
