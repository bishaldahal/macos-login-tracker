# macOS Login Tracker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://www.apple.com/macos/)

## 🕒 Does your office have HRMS but doesn't share your time logs with you?

**Here's the solution - for YOU, not for the office!**

Track your own work hours on your office Mac. Many companies have HRMS systems but don't provide employees access to their detailed time logs. This tool helps office workers generate their own accurate work hour reports by analyzing login/logout patterns from your company Mac's system logs.

Perfect for keeping personal records, validating timesheet entries, or simply understanding your daily work patterns on office systems.

## Features

- **Smart Time Calculation** - Total time from first login to last logout (not sum of sessions)
- **Edge Case Handling** - Handles crashes, ongoing sessions, and missing logout times
- **CSV Export** - Clean reports for spreadsheet applications
- **Flexible Configuration** - Custom date ranges, work hours, and output files

## Installation

**One-line install (recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/bishaldahal/macos-login-tracker/main/install.sh | bash
```

**Manual install:**
```bash
curl -O https://raw.githubusercontent.com/bishaldahal/macos-login-tracker/main/install.sh
chmod +x install.sh
./install.sh
```

## Usage

After installation, use the `login-tracker` command:

```bash
login-tracker                         # Last 30 days (default)
login-tracker -d 7                    # Last 7 days
login-tracker -d 14 -o report.csv     # Last 14 days, custom output
login-tracker -w 8:17 -d 7            # Custom work hours (8 AM - 5 PM)
login-tracker --help                  # Show all options
```

## Sample Output

```csv
Date,First Login,Last Logout,Intermediate Sessions,Total Working Hours
2025-08-26,09:12,ongoing,09:12-ongoing; 17:48-ongoing,09:10
2025-08-25,09:26,18:30,09:26-10:01; 10:02-crashed; 18:10-18:30,09:04
2025-08-22,09:31,18:28,09:31-12:18; 12:19-16:41; 17:34-18:28,08:57
```

## How It Works

The tracker calculates **total time at work** (first login to last logout) rather than just active computer time. This provides a realistic view of your work hours, including breaks and system downtime.

## Requirements

- macOS 10.14 or later
- Standard Unix tools (pre-installed on macOS)

## License

MIT License - see [LICENSE](LICENSE) for details.

---

⭐ **Star this repo if it helps you track your work hours!**