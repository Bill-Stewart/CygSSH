; CygSSH - Inno Setup includes

#define AppGUID "{21A533E3-0284-46B5-A731-FBC66EDFB168}"
#define AppName ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "OpenSSH", "Name", "")
#define AppMajorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "OpenSSH", "Major", "0")
#define AppMinorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "OpenSSH", "Minor", "0")
#define SetupMajorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Setup", "Major", "0")
#define SetupMinorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Setup", "Minor", "0")
#define AppFullVersion AppMajorVersion + "." + AppMinorVersion + "." + SetupMajorVersion + "." + SetupMinorVersion
#define InstallDirName "CygSSH"
#define SetupName "CygSSH-Setup"
#define SetupAuthor ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Setup", "Author", "")
#define SetupEmail ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Setup", "Email", "")
#define SetupCompany SetupAuthor + " (" + SetupEmail + ")"
#define SetupVersion AppFullVersion
#define IconFilename "OpenSSH.ico"
#define ServiceName "opensshd"
