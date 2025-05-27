# 🩸 spillblood.sh - BloodHound & Neo4j Launcher for Active Directory Analysis

`spillblood.sh` is a Bash script that automates the launch of **Neo4j** and **BloodHound**, two powerful tools for analyzing Active Directory environments. It performs logging, verifies service availability, and ensures a smooth startup experience for red teamers and security auditors.

---

## 🚀 Features

- ✅ Automatically launches Neo4j in background mode
- ✅ Starts the BloodHound GUI interface
- ✅ Verifies service readiness (Neo4j HTTP port)
- ✅ Logs everything to a dedicated log and report file
- ✅ Gracefully shuts down Neo4j on exit
- 🛡️ Requires **root privileges**

---

## 📦 Requirements

Make sure the following tools are installed:

- [Neo4j](https://neo4j.com/download/)
- [BloodHound](https://github.com/BloodHoundAD/BloodHound)
- Bash 5.x+
- GUI environment (BloodHound launches a desktop app)

Install on Debian/Ubuntu:

```bash
sudo apt update
sudo apt install neo4j bloodhound curl netcat
