; Inno Setup Script for Fully Automated Corpus Agent Installer (v1.2)

[Setup]
AppId={{C6C2B4E8-4A73-4D9D-B1A1-25595E7C20B3}
AppName=Corpus Agent
AppVersion=1.2
AppPublisher=Your Company Name
DefaultDirName={autopf}\Corpus Agent
DisableProgramGroupPage=yes
OutputBaseFilename=CorpusAgent-Automated-Setup-v1.2
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "source\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Corpus Agent\Uninstall Corpus Agent"; Filename: "{uninstallexe}"

[Run]
; Updated to pass the selected schedule to the PowerShell script.
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\install-task.ps1"" -InstallPath ""{app}"" -ScheduleType ""{code:GetScheduleType}"""; Flags: runhidden waituntilterminated

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\uninstall-task.ps1"""; Flags: runhidden waituntilterminated

; =================================================================
; The [Code] section updated with new UI elements
; =================================================================
[Code]
var
  ConfigPage: TInputQueryWizardPage;
  SchedulePage: TInputOptionWizardPage; // New page for the schedule selection
  ApiUrl: string;
  ApiKey: string;
  MonitorDir: string;
  ScheduleType: string;

procedure InitializeWizard;
begin
  // --- Page 1: Configuration ---
  ConfigPage := CreateInputQueryPage(wpWelcome,
    'Corpus Agent Configuration', 'Please provide the connection details',
    'Enter the information needed to connect to the Corpus server.');

  ConfigPage.Add('Server URL or IP Address:', False);
  ConfigPage.Add('Agent API Key:', False);
  ConfigPage.Add('Folder to Monitor:', False);

  ConfigPage.Values[0] := 'http://corpus-server.local';
  ConfigPage.Values[1] := 'DEV_API_KEY_12345';
  ConfigPage.Values[2] := 'C:\Users\Public\Documents';

  // --- Page 2: Schedule Selection ---
  SchedulePage := CreateInputOptionPage(ConfigPage.ID,
    'Agent Run Schedule', 'How often should the agent run?',
    'Choose how frequently the agent should check for new documents. "At Startup" is recommended for most users.',
    True, False);

  SchedulePage.Add('Run when the computer starts up (Recommended)');
  SchedulePage.Add('Run once every day (at 3 AM)');
  SchedulePage.Add('Run once every hour');
  
  // Set the default selection
  SchedulePage.SelectedValueIndex := 0; 
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  // When leaving the config page, validate the inputs
  if CurPageID = ConfigPage.ID then
  begin
    ApiUrl := ConfigPage.Values[0] + '/api/v1/documents/ingest'; // Append the endpoint
    ApiKey := ConfigPage.Values[1];
    MonitorDir := ConfigPage.Values[2];
    if (ConfigPage.Values[0] = '') or (ApiKey = '') or (MonitorDir = '') then
    begin
      MsgBox('All configuration fields are required. Please fill them in.', mbError, MB_OK);
      Result := False;
    end;
  end;
  
  // When leaving the schedule page, store the choice
  if CurPageID = SchedulePage.ID then
  begin
    if SchedulePage.SelectedValueIndex = 0 then
      ScheduleType := 'Startup'
    else if SchedulePage.SelectedValueIndex = 1 then
      ScheduleType := 'Daily'
    else if SchedulePage.SelectedValueIndex = 2 then
      ScheduleType := 'Hourly';
  end;
end;

// This function is called by the [Run] section to get the chosen schedule type
function GetScheduleType(Param: string): string;
begin
  Result := ScheduleType;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigContent: TArrayOfString;
  ConfigPath: string;
begin
  if CurStep = ssPostInstall then
  begin
    ConfigPath := ExpandConstant('{app}\config.ini');
    SetArrayLength(ConfigContent, 5);
    ConfigContent[0] := '[Corpus]';
    ConfigContent[1] := 'api_url = ' + ApiUrl;
    ConfigContent[2] := 'api_key = ' + ApiKey;
    ConfigContent[3] := 'monitor_directory = ' + MonitorDir;
    ConfigContent[4] := 'allowed_extensions = .docx,.pdf,.xlsx,.txt,.eml,.wpd';
    SaveStringsToFile(ConfigPath, ConfigContent, False);
  end;
end;