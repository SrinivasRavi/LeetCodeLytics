# LeetAnalytics Privacy Policy

**Last updated:** March 23, 2026

## Overview

LeetAnalytics is an iOS app that displays your LeetCode coding statistics. This policy explains what data the app accesses and how it is handled.

## Data Collection

LeetAnalytics does **not** collect, store, or transmit any personal data to third-party servers. All data stays on your device.

### Data accessed from LeetCode

The app fetches the following data from LeetCode's public GraphQL API using the username you provide:

- Profile information (username, avatar URL, ranking)
- Problem-solving statistics (easy/medium/hard counts, acceptance rate)
- Submission history (recent 20 submissions — title, language, status, timestamp)
- Submission calendar (daily solve counts for heatmap display)
- Skill/tag statistics (problems solved per topic)
- Language statistics (problems solved per programming language)
- Badges earned

This data is fetched directly from `leetcode.com` and cached locally on your device using UserDefaults. It is never sent to any other server.

### Session credentials (optional)

If you choose to sign in with your LeetCode session cookies (LEETCODE_SESSION and csrftoken), these credentials are stored securely in your device's Keychain. They are used solely to fetch your Daily Coding Challenge streak from LeetCode's authenticated API. Credentials are never transmitted anywhere other than `leetcode.com`.

### On-device storage

- **UserDefaults**: Cached API responses, app preferences, username, and widget data
- **Keychain**: Session credentials (if provided)
- **App Group container**: Widget data shared between the main app and widget extension

No data is stored in iCloud, on remote servers, or shared with any third party.

## Third-Party Services

LeetAnalytics communicates only with:

- `leetcode.com` — to fetch your coding statistics
- `assets.leetcode.com` — to load profile avatars and badge images

No analytics, crash reporting, advertising, or tracking SDKs are included in the app.

## Data Retention

All data is stored locally on your device. Uninstalling the app removes all stored data, including cached responses and Keychain entries.

## Children's Privacy

LeetAnalytics does not knowingly collect data from children under 13. The app displays publicly available LeetCode statistics and does not require account creation.

## Changes to This Policy

Updates to this policy will be reflected in the app's repository and the "Last updated" date above.

## Contact

For questions about this privacy policy, please open an issue at the project's GitHub repository.
