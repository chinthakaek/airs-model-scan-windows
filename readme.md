# Model Security Scanner (Windows/PowerShell)

This repository contains PowerShell automation for scanning AI models using the Palo Alto Networks Model Security CLI. It handles authentication, virtual environment management, and execution of scans against both Hugging Face URLs and local directories.

## Prerequisites

* Windows 10/11
* PowerShell 5.1 or Core 7+
* Python 3.12 installed and added to PATH 

URL to install Git 
https://git-scm.com/install/windows

URL to download Python
https://www.python.org/downloads/windows/

Verify by using > python --version
example output - Python 3.12.10

## Setup

1.  **Clone the repository:**
    ```powershell
    git clone https://github.com/chinthakaek/airs-model-scan-windows
    cd airs-model-scan-windows
    ```

2.  **Configure Credentials:**
    * Copy `.env.example` to a new file named `.env`.
    * Open `.env` and fill in your Client ID, Secret, TSG ID, and Security Group UUIDs.

3.  **Initialize Environment:**
    Run the setup script. This creates the Python virtual environment (`.venv`), authenticates with the private repository, and installs the required tools.
    ```powershell
    .\Set-Environment.ps1
    ```

## Usage

### Scanning a Hugging Face Model
To scan a public model hosted on Hugging Face:

```powershell
.\Scan-Model.ps1 -Type hf -Target "[https://huggingface.co/microsoft/DialoGPT-medium](https://huggingface.co/microsoft/DialoGPT-medium)"