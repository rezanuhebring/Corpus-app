# =================================================================
# Corpus PowerShell Agent v1.0
# Description: Monitors a directory for file changes and uploads them
#              to the Corpus server API.
# =================================================================

# --- SCRIPT CONFIGURATION ---
# Get the directory where this script is located
$ScriptPath = $PSScriptRoot
$ConfigPath = Join-Path $ScriptPath "config.json"

# --- LOAD CONFIGURATION FROM JSON ---
try {
    # Read file with explicit UTF-8 encoding to prevent BOM issues and ensure raw content
    $fileContent = Get-Content -Path $ConfigPath -Encoding UTF8 -Raw
    $config = $fileContent | ConvertFrom-Json
}
catch {
    Write-Error "FATAL: config.json not found or is invalid. Please ensure it exists in the same directory as the script: $ConfigPath. Error details: $($_.Exception.Message)"
    # Pause to allow user to see the error before the window closes if double-clicked
    Start-Sleep -Seconds 10
    exit 1
}

# Validate that the monitor directory exists
if (-not (Test-Path -Path $config.MonitorDirectory -PathType Container)) {
    Write-Error "FATAL: The MonitorDirectory specified in config.json does not exist: $($config.MonitorDirectory)"
    Start-Sleep -Seconds 10
    exit 1
}


# =================================================================
# FUNCTION: Send-FileToCorpus
# This function handles file processing and uploading.
# =================================================================
function Send-FileToCorpus {
    param(
        [string]$FullPath
    )

    $FileName = Split-Path -Path $FullPath -Leaf
    $Extension = [System.IO.Path]::GetExtension($FileName).ToLower()

    # Check if the file extension is in the allowed list
    if ($config.AllowedExtensions -notcontains $Extension) {
        # Write-Verbose "Skipping file with unallowed extension: $FileName"
        return
    }

    Write-Host "$(Get-Date): Detected change for file: $FileName"

    # --- 1. GET METADATA ---
    $fileItem = Get-Item -Path $FullPath
    $relativePath = $fileItem.FullName.Substring($config.MonitorDirectory.Length).TrimStart('\/')
    $clientProjectName = ($relativePath -split '[\\/_]')[0]

    $metadata = @{
        filename_full_path  = $fileItem.FullName
        client_project_name = $clientProjectName
        created_date        = $fileItem.CreationTimeUtc.ToString("o") # ISO 8601 format
        modified_date       = $fileItem.LastWriteTimeUtc.ToString("o")
        source_hostname     = $env:COMPUTERNAME
        creator             = "N/A"
        modifier            = "N/A"
    }

    # --- 2. EXTRACT CONTENT ---
    # This is the most complex part and depends on external tools for non-text files.
    $Content = ""
    switch ($Extension) {
        ".txt" {
            $Content = Get-Content -Path $FullPath -Raw
        }
        ".log" {
            $Content = Get-Content -Path $FullPath -Raw
        }
        ".docx" {
            # REQUIRES MICROSOFT WORD TO BE INSTALLED
            # This code is provided as a functional example if the dependency is met.
            try {
                $word = New-Object -ComObject Word.Application
                $word.Visible = $false
                $document = $word.Documents.Open($FullPath, $false, $true) # Open ReadOnly
                $Content = $document.Content.Text
                $document.Close()
                $word.Quit()
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
            }
            catch {
                Write-Warning "Could not process .docx file: $($_.Exception.Message). Is Microsoft Word installed?"
                $Content = "ERROR: Could not extract content from DOCX file."
            }
        }
        ".pdf" {
            # REQUIRES A 3RD PARTY TOOL (e.g., pdftotext.exe from Xpdf) TO BE IN THE SYSTEM PATH
            # try {
            #     $Content = pdftotext.exe -enc UTF-8 $FullPath -
            # }
            # catch {
            #     Write-Warning "Could not process .pdf file: $($_.Exception.Message). Is a PDF-to-text utility installed and in the PATH?"
            #     $Content = "ERROR: Could not extract content from PDF file."
            # }
            $Content = "PDF content extraction is not configured."
        }
        default {
            $Content = "Content extraction not supported for this file type."
        }
    }

    # --- 3. PREPARE AND SEND THE REQUEST ---
    $jsonPayload = @{
        metadata = $metadata
        content  = $Content
    } | ConvertTo-Json -Depth 5

    $headers = @{
        "X-API-Key" = $config.ApiKey
    }

    $form = @{
        json_payload  = $jsonPayload
        original_file = Get-Item -Path $FullPath
    }

    try {
        Write-Host "Uploading $FileName to Corpus server..."
        Invoke-RestMethod -Uri $config.ApiUrl -Method Post -Headers $headers -Form $form
        Write-Host "Successfully uploaded $FileName." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to upload $FileName. Status: $($_.Exception.Response.StatusCode.value__). Response: $($_.Exception.Response.GetResponseStream() | ForEach-Object { (New-Object System.IO.StreamReader -ArgumentList $_).ReadToEnd() })"
    }
}


# =================================================================
# MAIN SCRIPT BODY: Folder Monitoring
# =================================================================

Write-Host "Starting Corpus PowerShell Agent..." -ForegroundColor Cyan
Write-Host "Monitoring directory: $($config.MonitorDirectory)" -ForegroundColor Cyan
Write-Host "Press CTRL+C to stop the agent." -ForegroundColor Yellow

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $config.MonitorDirectory
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Define the actions for the events
$createdAction = {
    $path = $event.SourceEventArgs.FullPath
    # Add a small delay to ensure the file is fully written before processing
    Start-Sleep -Seconds 2
    Send-FileToCorpus -FullPath $path
}

$changedAction = {
    $path = $event.SourceEventArgs.FullPath
    Start-Sleep -Seconds 2
    Send-FileToCorpus -FullPath $path
}

# Register the event handlers
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $createdAction
Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $changedAction

# Keep the script running to listen for events
try {
    while ($true) {
        Start-Sleep -Seconds 5
    }
}
finally {
    # Clean up event registrations when the script is stopped (e.g., with CTRL+C)
    Get-EventSubscriber | Unregister-Event
    Write-Host "Corpus Agent stopped and event handlers cleaned up."
}