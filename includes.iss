; CygSSH - Inno Setup includes

#define AppGUID "{21A533E3-0284-46B5-A731-FBC66EDFB168}"
#define AppName ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "OpenSSH", "Name", "")
#define AppMajorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "OpenSSH", "Major", "0")
#define AppMinorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "OpenSSH", "Minor", "0")
#define AppFullVersion AppMajorVersion + "." + AppMinorVersion
#define SetupMajorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Setup", "Major", "0")
#define SetupMinorVersion ReadIni(AddBackslash(SourcePath) + "appinfo.ini", "Setup", "Minor", "0")
#define SetupFullVersion SetupMajorVersion + "." + SetupMinorVersion
#define InstallDirName "CygSSH"
#define SetupName "CygSSH-Setup"
#define SetupAuthor "Bill Stewart"
#define SetupCompany SetupAuthor + " (bstewart@iname.com)"
#define SetupVersion AppFullVersion + "." + SetupFullVersion
#define IconFilename "OpenSSH.ico"
#define ServiceName "opensshd"
