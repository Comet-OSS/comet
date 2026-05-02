--// Imports
local process = require("@lune/process")
local net = require("@lune/net")
local fs = require("@lune/fs")

--// Variables
local packages = process.args[1]
local sources = {
    cascade = {
        ["init.luau"] = "https://github.com/biggaboy212/Cascade/releases/latest/download/dist-typed.luau",
        ["types.luau"] = "https://raw.githubusercontent.com/biggaboy212/Cascade/refs/heads/main/src/types.luau",
    },
}

local DEFAULT_HEADERS = {
    ["User-Agent"] = "CometPipeline/1.0",
    ["Accept"] = "application/octet-stream",
}

local API_HEADERS = {
    ["User-Agent"] = "CometPipeline/1.0",
    ["Accept"] = "application/vnd.github+json",
}

local function request(url, headers)
    return net.request({
        url = url,
        method = "GET",
        headers = headers,
    })
end

local function requestWithCurl(url)
    local tempPath = ".get_packages_download.tmp"
    pcall(fs.removeFile, tempPath)

    local result = process.exec("curl", {
        "-L",
        "-sS",
        "--fail",
        "-H",
        "User-Agent: CometPipeline/1.0",
        "-H",
        "Accept: application/octet-stream",
        "-o",
        tempPath,
        url,
    })
    if not result.ok then
        pcall(fs.removeFile, tempPath)
        return false, nil
    end

    local readOk, body = pcall(fs.readFile, tempPath)
    pcall(fs.removeFile, tempPath)
    if not readOk or type(body) ~= "string" then
        return false, nil
    end

    return true, body
end

local function splitPath(path)
    local parts = {}
    for chunk in string.gmatch(path, "([^/]+)") do
        table.insert(parts, chunk)
    end
    return parts
end

local function parseLatestReleaseDownload(url)
    local parts = splitPath(url)
    if #parts < 7 then
        return nil
    end

    if parts[1] ~= "https:" and parts[1] ~= "http:" then
        return nil
    end

    if parts[2] ~= "github.com" then
        return nil
    end

    if parts[5] ~= "releases" or parts[6] ~= "latest" or parts[7] ~= "download" then
        return nil
    end

    local owner = parts[3]
    local repo = parts[4]
    local assetName = table.concat(parts, "/", 8)

    if assetName == "" then
        return nil
    end

    return owner, repo, assetName
end

local function fetchViaGitHubReleaseApi(url)
    local owner, repo, assetName = parseLatestReleaseDownload(url)
    if not owner then
        return false, nil
    end

    local latestReleaseUrl = `https://api.github.com/repos/{owner}/{repo}/releases/latest`
    local releaseResponse = request(latestReleaseUrl, API_HEADERS)
    if not releaseResponse.ok then
        return false, nil
    end
    local compactBody = string.gsub(releaseResponse.body, "%s+", "")
    local nameToken = `\"name\":\"{assetName}\"`
    local nameStart = string.find(compactBody, nameToken, 1, true)
    if nameStart == nil then
        return false, nil
    end

    local payloadPrefix = string.sub(compactBody, 1, nameStart)
    local assetApiUrl = nil
    for currentUrl in string.gmatch(payloadPrefix, [["url":"(https://api.github.com/repos/[^"]+/releases/assets/%d+)"]]) do
        assetApiUrl = currentUrl
    end

    if type(assetApiUrl) ~= "string" or assetApiUrl == "" then
        return false, nil
    end

    local assetResponse = request(assetApiUrl, DEFAULT_HEADERS)
    if assetResponse.ok then
        return true, assetResponse.body
    end

    return requestWithCurl(assetApiUrl)
end

local function fetchDistribution(url)
    local response = request(url, DEFAULT_HEADERS)
    if response.ok then
        return true, response.body, response
    end

    local owner = parseLatestReleaseDownload(url)
    if owner then
        local curlOk, curlBody = requestWithCurl(url)
        if curlOk and curlBody ~= nil then
            return true, curlBody, response
        end
    end

    local fallbackOk, fallbackBody = fetchViaGitHubReleaseApi(url)
    if fallbackOk and fallbackBody ~= nil then
        return true, fallbackBody, response
    end

    return false, nil, response
end

--// Main
if not packages or packages == "" then
    print("[error] Expected output packages directory argument.")
    process.exit(1)
end

for package, files in sources do
    local packageDir = `{packages}/{package}`
    if not fs.isDir(packageDir) then
        local mkOk, mkErr = pcall(fs.writeDir, packageDir)
        if not mkOk then
            print(`[error] Could not create directory {packageDir}: {mkErr}`)
            process.exit(1)
        end
    end

    for file, distribution in files do
        local path = `{packages}/{package}/{file}`
        local ok, body, response = fetchDistribution(distribution)

        if not ok or body == nil then
            print(`[error] Failed to fetch {distribution}`)
            print(response.ok)
            print(response.statusCode, response.statusMessage)
            print(response.headers)
            process.exit(1)
        end

        local writeOk, writeErr = pcall(fs.writeFile, path, body)
        if not writeOk then
            print(`[error] Failed to write {path}: {writeErr}`)
            process.exit(1)
        end

        print(`[ok] Wrote {path}`)
    end
end