; pcdinst.nsi
;
; Installer for cfBochs.

;--------------------------------

!ifdef HAVE_UPX
!packhdr tmp.dat "upx\upx -9 tmp.dat"
!endif

!ifdef NOCOMPRESS
SetCompress off
!endif

;--------------------------------

Name "cfBochs"
Caption "colorForth in a Bochs"
Icon "${NSISDIR}\Contrib\Graphics\Icons\nsis1-install.ico"
OutFile "cfbochs.exe"

SetDateSave on
SetDatablockOptimize on
CRCCheck on
SilentInstall normal
BGGradient 000000 800000 FFFFFF
InstallColors FF8080 000030
XPStyle on

InstallDir "$PROGRAMFILES\net\sourceforge\colorforth"
InstallDirRegKey HKLM "Software\net\sourceforge\colorforth" ""

CheckBitmap "${NSISDIR}\Contrib\Graphics\Checks\classic-cross.bmp"

LicenseText "GNU Public License"
LicenseData "LICENSE.txt"

;--------------------------------

Page license
Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

!ifndef NOINSTTYPES ; only if not defined
  InstType "Full"
  ;InstType /NOCUSTOM
  ;InstType /COMPONENTSONLYONCUSTOM
!endif

AutoCloseWindow false
ShowInstDetails show

;--------------------------------

Section "" ; empty string makes it hidden, so would starting with -

  ; write registry string
  WriteRegStr HKLM SOFTWARE\net\sourceforge\colorforth "Install_Dir" "$INSTDIR"

  ; write uninstall strings
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\cfBochs" "DisplayName" "cfBochs (remove only)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\cfBochs" "UninstallString" '"$INSTDIR\unwise.exe"'

  SetOutPath $INSTDIR
  CreateDirectory "$INSTDIR"
  WriteUninstaller "unwise.exe"

SectionEnd

Section "Copy Files"

  SectionIn 1

  SetOutPath $INSTDIR
  File /a "bochs.exe"

SectionEnd

Section "Create Shortcuts"
  
  SectionIn 1
  CreateDirectory "$SMPROGRAMS\cfBochs"
  SetOutPath $INSTDIR ; for working directory
  CreateShortCut "$SMPROGRAMS\cfBochs\cfBochs.lnk" "$INSTDIR\bochs.exe" "-q" "" 0
  CreateShortCut "$SMPROGRAMS\cfBochs\Uninstall cfBochs.lnk" "$INSTDIR\unwise.exe" ; use defaults for parameters, icon, etc.
  CreateShortCut "$DESKTOP\cfBochs.lnk" "$INSTDIR\bochs.exe" "" ""

SectionEnd

;--------------------------------

; Uninstaller

UninstallText "This will uninstall cfBochs. Hit next to continue."
UninstallIcon "${NSISDIR}\Contrib\Graphics\Icons\nsis1-uninstall.ico"

Section "Uninstall"

  DeleteRegKey HKLM "SOFTWARE\net\sourceforge\colorforth"
  Delete "$INSTDIR\unwise.exe"
  Delete "$INSTDIR\bochs.exe"
  Delete "$DESKTOP\cfBochs.lnk"
  Delete "$SMPROGRAMS\cfBochs\Uninstall cfBochs.lnk"
  RMDir "$SMPROGRAMS\cfBochs"
  RMDir "$INSTDIR"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\cfBochs"

SectionEnd
