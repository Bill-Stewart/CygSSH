; CygSSH - Inno Setup includes

#define AppGUID "{21A533E3-0284-46B5-A731-FBC66EDFB168}"
#define AppName ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "OpenSSH", "Name", "")
#define AppVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "OpenSSH", "Version", "0.0")
#define AppFullVersion AppVersion + ".0.0"
#define InstallDirName "CygSSH"
#define SetupName "CygSSH-Setup"
#define SetupAuthor ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Setup", "Author", "")
#define SetupEmail ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Setup", "Email", "")
#define SetupCompany SetupAuthor + " (" + SetupEmail + ")"
#define IconFilename "OpenSSH.ico"
#define ServiceName "opensshd"
