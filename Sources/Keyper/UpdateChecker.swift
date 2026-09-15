import Foundation
import AppKit

/// Model representing a GitHub Release
struct GitHubRelease: Codable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlUrl: String
    let publishedAt: String?
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

/// Model representing a release asset (e.g. .dmg or .pkg)
struct GitHubAsset: Codable {
    let name: String
    let size: Int
    let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case name
        case size
        case browserDownloadUrl = "browser_download_url"
    }
}

/// Handles checking for updates from GitHub Releases and triggering downloads
class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    /// Current application version
    let currentVersion: String = "1.0.0"

    /// GitHub repo coordinate
    private let repo = "OrangeSAM/Keyper"

    @Published var isChecking: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var latestRelease: GitHubRelease?
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var lastCheckedDate: Date?

    private init() {}

    /// Check for updates from GitHub Releases API
    /// - Parameter manual: If true, will set a status message when already up to date
    func checkForUpdates(manual: Bool = false) {
        guard !isChecking else { return }

        DispatchQueue.main.async {
            self.isChecking = true
            self.errorMessage = nil
            self.statusMessage = nil
        }

        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else {
            DispatchQueue.main.async {
                self.isChecking = false
                self.errorMessage = "无效的更新检查地址"
            }
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Keyper-App/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isChecking = false
                self.lastCheckedDate = Date()

                if let error = error {
                    self.errorMessage = "检查更新失败: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "无效的网络响应"
                    return
                }

                if httpResponse.statusCode == 404 {
                    // No release found yet
                    if manual {
                        self.statusMessage = "当前已是最新版本 (v\(self.currentVersion))"
                    }
                    return
                }

                guard httpResponse.statusCode == 200, let data = data else {
                    self.errorMessage = "服务器返回错误 (状态码 \(httpResponse.statusCode))"
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let release = try decoder.decode(GitHubRelease.self, from: data)
                    let remoteVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))

                    if self.isVersion(remoteVersion, higherThan: self.currentVersion) {
                        self.latestRelease = release
                        self.updateAvailable = true
                        self.statusMessage = "发现新版本 v\(remoteVersion)"
                    } else {
                        self.updateAvailable = false
                        if manual {
                            self.statusMessage = "当前已是最新版本 (v\(self.currentVersion))"
                        }
                    }
                } catch {
                    self.errorMessage = "解析版本信息失败: \(error.localizedDescription)"
                }
            }
        }

        task.resume()
    }

    /// Compare two semantic version strings (e.g., "1.0.1" vs "1.0.0")
    func isVersion(_ v1: String, higherThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }

        let count = max(parts1.count, parts2.count)
        for i in 0..<count {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }

    /// Get preferred download asset (.dmg preferred, then .pkg, or fallback to htmlUrl)
    func preferredDownloadURL() -> URL? {
        guard let release = latestRelease else { return nil }

        // Find .dmg asset
        if let dmg = release.assets.first(where: { $0.name.hasSuffix(".dmg") }),
           let url = URL(string: dmg.browserDownloadUrl) {
            return url
        }

        // Find .pkg asset
        if let pkg = release.assets.first(where: { $0.name.hasSuffix(".pkg") }),
           let url = URL(string: pkg.browserDownloadUrl) {
            return url
        }

        // Fallback to release page
        return URL(string: release.htmlUrl)
    }

    /// Open browser to download latest release
    func openDownload() {
        if let url = preferredDownloadURL() {
            NSWorkspace.shared.open(url)
        } else if let release = latestRelease, let url = URL(string: release.htmlUrl) {
            NSWorkspace.shared.open(url)
        }
    }
}
