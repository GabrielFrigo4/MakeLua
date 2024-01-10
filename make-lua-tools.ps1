################################################################
#	VARIABLES
################################################################

# admin
$IS_ADMIN = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544");

# versions
$MAKELUA_VERSION = '1.3.0';
$CURRENT_OS_VERSION = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption;

# basic paths
$CURRENT_PATH = pwd;
$SCRIPT_PATH = $PSScriptRoot;
$PROGAM_FILES_PATH = 'C:\Program Files';

# luarocks paths
$LUAROCKS_ROAMING_PATH = "$env:USERPROFILE\AppData\Roaming\luarocks";
$LUAROCKS_LOCAL_PATH = "$env:USERPROFILE\AppData\Local\LuaRocks";
$LUAROCKS_SYSTEM_PATH = 'C:\Program Files\luarocks';

# makelua paths
$MAKELUA_PATH = 'C:\Program Files\MakeLua';
$LUA_PATH = "$MAKELUA_PATH\lua-lang";
$NELUA_PATH = "$MAKELUA_PATH\nelua-lang";
$LUAJIT_PATH = "$MAKELUA_PATH\luajit-lang";
	
# colors
$DefaultColors = @{
	"ForegroundColor"=$host.ui.RawUI.ForegroundColor;
	"BackgroundColor"=$host.ui.RawUI.BackgroundColor;
};

# lua data
$LUA_DATA = @{
	"IS_DYNAMIC_OR_STATIC"=$null;
	"COMPILER"=$null;
	"OPTIMIZE"=$null;
	"LUA_VERSION"=$null;
	"LUAROCKS_VERSION"=$null;
};

# batch file data
$BATCH_FILE_DATA = "@call pwsh -file `"%~dp0make-lua-tools.ps1`" makelua %*";

# powershell file data
$POWERSHELL_FILE_DATA = "Invoke-Expression `"& ```"C:\Program Files\MakeLua\make-lua-tools.ps1```" makelua `$args`"";

################################################################
#	FUNCTIONS
################################################################

function GetLuaVersionWeb {
	$Link = 'https://www.lua.org/ftp/';
	return (Invoke-WebRequest -Uri $Link).links.href[14].Replace('lua-', '').Replace('.tar.gz', '') -as [string];
}

function GetLuaRocksVersionWeb {
	$Link = 'http://luarocks.github.io/luarocks/releases/';
	return (Invoke-WebRequest -Uri $Link).links.href[9].Replace('luarocks-', '').Replace('-windows-64.zip', '') -as [string];
}

function SetForegroundColor {
	param(
		[String] $foregroundColor
	);
	$host.ui.RawUI.ForegroundColor = $foregroundColor;
}

function SetBackgroundColor {
	param(
		[String] $backgroundColor
	);
	$host.ui.RawUI.BackgroundColor = $backgroundColor;
}

function SetColors {
	param(
		[String] $foregroundColor,
		[String] $backgroundColor
	);
	SetForegroundColor $foregroundColor;
	SetBackgroundColor $backgroundColor;
}

function ResetForegroundColor {
	SetForegroundColor $DefaultColors.ForegroundColor;
}

function ResetBackgroundColor {
	SetBackgroundColor $DefaultColors.BackgroundColor;
}

function ResetColors {
	ResetForegroundColor;
	ResetBackgroundColor;
}

function WriteHost-Newline {
	Write-Host;
}

function WriteHost-ForegroundColor {
	param(
		[String] $text,
		[String] $backgroundColor
	);
	SetBackgroundColor $backgroundColor;
	Write-Host $text;
	ResetBackgroundColor;
}

function WriteHost-ForegroundColor {
	param(
		[String] $text,
		[String] $foregroundColor
	);
	SetForegroundColor $foregroundColor;
	Write-Host $text;
	ResetForegroundColor;
}

function WriteHost-Colors {
	param(
		[String] $text,
		[String] $foregroundColor,
		[String] $backgroundColor
	);
	SetColors $foregroundColor $backgroundColor;
	Write-Host $text;
	ResetColors;
}

function WriteHost-Colored {
    [CmdletBinding(ConfirmImpact='None', SupportsShouldProcess=$false, SupportsTransactions=$false)]
    param(
        [parameter(Position=0, ValueFromPipeline=$true)]
        [string[]] $Text,
        [switch] $NoNewline,
        [ConsoleColor] $BackgroundColor =  $host.UI.RawUI.BackgroundColor,
        [ConsoleColor] $ForegroundColor = $host.UI.RawUI.ForegroundColor
    );

    begin {
        if ($Text -ne $null) {
            $Text = "$Text";
        }
    };

    process {
        if ($Text) {
            $curFgColor = $ForegroundColor;
            $curBgColor = $BackgroundColor;

            $tokens = $Text.split("#");
      
            $prevWasColorSpec = $false;
            foreach($token in $tokens) {

                if (-not $prevWasColorSpec -and $token -match '^([a-z]+)(:([a-z]+))?$') {
                    try {
                        $curFgColor = [ConsoleColor]  $matches[1];
                        $prevWasColorSpec = $true;
                    } catch {}
                    if ($matches[3]) {
                        try {
                            $curBgColor = [ConsoleColor]  $matches[3];
                            $prevWasColorSpec = $true;
                        } catch {}
                    }
                    if ($prevWasColorSpec) {
                        continue;              
                    }
                }

                $prevWasColorSpec = $false;

                if ($token) {
                    $argsHash = @{};
                    if ([int] $curFgColor -ne -1) { $argsHash += @{ 'ForegroundColor' = $curFgColor; } }
                    if ([int] $curBgColor -ne -1) { $argsHash += @{ 'BackgroundColor' = $curBgColor; } }
                    Write-Host -NoNewline @argsHash $token;
                }

                $curFgColor = $ForegroundColor;
                $curBgColor = $BackgroundColor;
            }
        }
        if (-not $NoNewLine) { WriteHost-Newline; }
    };
}

function CreateBasicDirs {
	if (-not(Test-Path -Path $LUAROCKS_ROAMING_PATH)) {
		mkdir $LUAROCKS_ROAMING_PATH | Out-Null;
	} if (-not(Test-Path -Path $LUAROCKS_LOCAL_PATH)) {
		mkdir $LUAROCKS_LOCAL_PATH | Out-Null;
	}
}

function CreateMakeLuaLinker {
	if (-not(Test-Path -Path "$MAKELUA_PATH\makelua.bat" -PathType Leaf)) {
		Write-Host 'start create "makelua.bat" linker file';
		new-item "$MAKELUA_PATH\makelua.bat" | Out-Null;
		set-content "$MAKELUA_PATH\makelua.bat" $BATCH_FILE_DATA;
	}
	if (-not(Test-Path -Path "$MAKELUA_PATH\mklua.bat" -PathType Leaf)) {
		Write-Host 'start create "mklua.bat" linker file';
		new-item "$MAKELUA_PATH\mklua.bat" | Out-Null;
		set-content "$MAKELUA_PATH\mklua.bat" $BATCH_FILE_DATA;
	}
	if (-not(Test-Path -Path "$MAKELUA_PATH\mkl.bat" -PathType Leaf)) {
		Write-Host 'start create "mkl.bat" linker file';
		new-item "$MAKELUA_PATH\mkl.bat" | Out-Null;
		set-content "$MAKELUA_PATH\mkl.bat" $BATCH_FILE_DATA;
	}
	if (-not(Test-Path -Path "$MAKELUA_PATH\makelua.ps1" -PathType Leaf)) {
		Write-Host 'start create "makelua.ps1" linker file';
		new-item "$MAKELUA_PATH\makelua.ps1" | Out-Null;
		set-content "$MAKELUA_PATH\makelua.ps1" $POWERSHELL_FILE_DATA;
	}
	if (-not(Test-Path -Path "$MAKELUA_PATH\mklua.ps1" -PathType Leaf)) {
		Write-Host 'start create "mklua.ps1" linker file';
		new-item "$MAKELUA_PATH\mklua.ps1" | Out-Null;
		set-content "$MAKELUA_PATH\mklua.ps1" $POWERSHELL_FILE_DATA;
	}
	if (-not(Test-Path -Path "$MAKELUA_PATH\mkl.ps1" -PathType Leaf)) {
		Write-Host 'start create "mkl.ps1" linker file';
		new-item "$MAKELUA_PATH\mkl.ps1" | Out-Null;
		set-content "$MAKELUA_PATH\mkl.ps1" $POWERSHELL_FILE_DATA;
	}
}

function GotoDefaultDir {
	Set-Location $PROGAM_FILES_PATH;
}

function GetAdminMode {
    param(
        [parameter(Position=0, Mandatory=$true)]
        [string[]] $Args
    );
	
	$params = @{
		FilePath = 'pwsh';
		Verb = 'RunAs';
		ArgumentList = @(
			"-ExecutionPolicy ByPass";
			"-File `"$PSCommandPath`"";
			$Args;
		);
	};
	
	Start-Process @params;
	Set-Location $CURRENT_PATH;
	exit;
}

function MakeLua-DefaultMessage {
	WriteHost-Colored 'type: #green#"makelua help"# for more information';
	Set-Location $CURRENT_PATH;
	exit;
}

function MakeLua-Help {
	$LUA_DATA.LUA_VERSION = GetLuaVersionWeb;
	$LUA_DATA.LUAROCKS_VERSION = GetLuaRocksVersionWeb;
	WriteHost-Colored "#green#|MAKE_LUA HELP|#
	
#green#MakeLua info:#
 - Operating System: #green#$CURRENT_OS_VERSION#
 - Path: #green#`"$SCRIPT_PATH`"#
 - Version: #green#$MAKELUA_VERSION#

#green#MakeLua uses:#
 - powershell 7.X
 - msvc or llvm or gnu
 - make
 - git
 - curl
 - tar
 - 7z

#green#(MakeLua) options: (help / setup / remove / install / uninstall)#
 - help: show help information (this)
 - setup: setup makelua
 - remove: remove makelua
 - install: install lua (and luarocks) / nelua / luajit
 - uninstall: uninstall lua (and luarocks) / nelua / luajit

#green#(MakeLua install) options: (lua / nelua / luajit)#
 - lua
 - nelua
 - luajit

#green#(MakeLua uninstall) options: (lua / nelua / luajit)#
 - lua
 - nelua
 - luajit

#green#(MakeLua install lua) options: (link, compiler, optimize, lua_version, luarocks_version)#
 - link: dynamic static
 - compiler: msvc llvm gnu
 - optimize: default size speed
 - lua_version: number.number.number
 - luarocks_version: number.number.number

to install use #green#`"makelua install lua dynamic msvc default $($LUA_DATA.LUA_VERSION) $($LUA_DATA.LUAROCKS_VERSION)`"#
MakeLua is a Lua Installer";
	Set-Location $CURRENT_PATH;
	exit;
}

function MakeLua-Setup {
	WriteHost-ForegroundColor "Setup MakeLua" 'Green';
	if (-not(Test-Path -Path $MAKELUA_PATH)) {
		mkdir $MAKELUA_PATH | Out-Null;
	}
	if (-not($MAKELUA_PATH -eq $SCRIPT_PATH)) {
		mv "$SCRIPT_PATH\make-lua-tools.ps1" "$MAKELUA_PATH\make-lua-tools.ps1"
	}
	CreateMakeLuaLinker;
	
	return $False;
}

function MakeLua-Remove {
	WriteHost-ForegroundColor "Remove MakeLua" 'Green';
	sleep 2;
	if (Test-Path -Path $LUAROCKS_ROAMING_PATH) {
		rm -r $LUAROCKS_ROAMING_PATH -Force;
		WriteHost-ForegroundColor "remove $LUAROCKS_ROAMING_PATH successfully" 'Green';
	} if (Test-Path -Path $LUAROCKS_LOCAL_PATH) {
		rm -r $LUAROCKS_LOCAL_PATH -Force;
		WriteHost-ForegroundColor "remove $LUAROCKS_LOCAL_PATH successfully" 'Green';
	} if (Test-Path -Path $LUAROCKS_SYSTEM_PATH) {
		rm -r $LUAROCKS_SYSTEM_PATH -Force;
		WriteHost-ForegroundColor "remove $LUAROCKS_SYSTEM_PATH successfully" 'Green';
	} if (Test-Path -Path $MAKELUA_PATH) {
		rm -r $MAKELUA_PATH -Force;
		WriteHost-ForegroundColor "remove $MAKELUA_PATH successfully" 'Green';
	}
	Set-Location $CURRENT_PATH;
	
	return $False;
}

function MakeLua-Install-Lua {
	WriteHost-ForegroundColor "Installing Lua" 'Green';

	#luarocks information dir
	if (-not(Test-Path -Path $LUAROCKS_SYSTEM_PATH)) {
		mkdir $LUAROCKS_SYSTEM_PATH | Out-Null;
	}
	
	MakeLua-Uninstall-Lua;
	mkdir $LUA_PATH;

	Set-Location $LUA_PATH;
	WriteHost-ForegroundColor 'MakeLua Options Using:' 'Green';
	$ERR = $False;
	
	if ($Args.Count -ge 3) {
		$LUA_DATA.IS_DYNAMIC_OR_STATIC = $Args[2] -as [string]; #dynamic static || link options	
	} else {
		$LUA_DATA.IS_DYNAMIC_OR_STATIC='dynamic';
	}
	WriteHost-ForegroundColor " - link: $($LUA_DATA.IS_DYNAMIC_OR_STATIC)" 'Green';
	
	if ($Args.Count -ge 4) {
		$LUA_DATA.COMPILER = $Args[3] -as [string]; #msvc llvm gnu || compiler options	
	} else {
		$LUA_DATA.COMPILER = 'msvc';
	}
	WriteHost-ForegroundColor " - compiler: $($LUA_DATA.COMPILER)" 'Green';
	
	if ($Args.Count -ge 5) {
		$LUA_DATA.OPTIMIZE = $Args[4] -as [string]; #default size speed || optimize options	
	} else {
		$LUA_DATA.OPTIMIZE = 'default';
	}
	WriteHost-ForegroundColor " - optimize: $($LUA_DATA.OPTIMIZE)" 'Green';
	
	if ($Args.Count -ge 6) {
		$LUA_DATA.LUA_VERSION = $Args[5] -as [string]; #lua version
	} else {
		$LUA_DATA.LUA_VERSION = GetLuaVersionWeb;
	}
	WriteHost-ForegroundColor " - lua_version: $($LUA_DATA.LUA_VERSION)" 'Green';
	
	if ($Args.Count -ge 7) {
		$LUA_DATA.LUAROCKS_VERSION = $Args[6] -as [string]; #luarocks version
	} else {
		$LUA_DATA.LUAROCKS_VERSION = GetLuaRocksVersionWeb;
	}
	WriteHost-ForegroundColor " - luarocks_version: $($LUA_DATA.LUAROCKS_VERSION)" 'Green';

	WriteHost-Newline;
	if ($ERR -eq $True) {
		exit;
	}
	
	return $False;
}

function MakeLua-Install-Nelua {
	WriteHost-ForegroundColor "Installing Nelua" 'Green';

	MakeLua-Uninstall-Nelua;
	
	git clone "https://github.com/edubart/nelua-lang.git" "$NELUA_PATH";
	Set-Location $NELUA_PATH;
	make;
	
	Remove-item -Path $NELUA_PATH\.git -Force;
	rm -r $NELUA_PATH\.github;
	rm -r $NELUA_PATH\docs;
	rm -r $NELUA_PATH\examples;
	rm -r $NELUA_PATH\spec;
	rm -r $NELUA_PATH\src;
	rm -r $NELUA_PATH\tests;
	rm $NELUA_PATH\.gitattributes;
	rm $NELUA_PATH\.gitignore;
	rm $NELUA_PATH\.luacheckrc;
	rm $NELUA_PATH\.luacov;
	rm $NELUA_PATH\CONTRIBUTING.md;
	rm $NELUA_PATH\Dockerfile;
	rm $NELUA_PATH\LICENSE;
	rm $NELUA_PATH\nelua;
	rm $NELUA_PATH\Makefile;
	rm $NELUA_PATH\README.md;
	WriteHost-ForegroundColor "Nelua Installed" 'Green';	
	
	return $False;
}

function MakeLua-Install-LuaJIT {
	WriteHost-ForegroundColor "Installing LuaJIT" 'Green';
	
	MakeLua-Uninstall-LuaJIT;
	
	git clone "https://github.com/LuaJIT/LuaJIT.git" "$LUAJIT_PATH";
	mkdir $LUAJIT_PATH\lua | Out-Null;
	mkdir $LUAJIT_PATH\include | Out-Null;
	Set-Location $LUAJIT_PATH;
	make;
	
	mv $LUAJIT_PATH\src\luajit.exe $LUAJIT_PATH\luajit.exe;
	mv $LUAJIT_PATH\src\lua51.dll $LUAJIT_PATH\lua51.dll;
	mv $LUAJIT_PATH\src\jit $LUAJIT_PATH\lua\jit;
	mv $LUAJIT_PATH\src\lauxlib.h $LUAJIT_PATH\include\lauxlib.h;
	mv $LUAJIT_PATH\src\lua.h $LUAJIT_PATH\include\lua.h;
	mv $LUAJIT_PATH\src\lua.hpp $LUAJIT_PATH\include\lua.hpp;
	mv $LUAJIT_PATH\src\luaconf.h $LUAJIT_PATH\include\luaconf.h;
	mv $LUAJIT_PATH\src\lualib.h $LUAJIT_PATH\include\lualib.h;
	Remove-item -Path $LUAJIT_PATH\.git -Force;
	rm -r $LUAJIT_PATH\doc;
	rm -r $LUAJIT_PATH\dynasm;
	rm -r $LUAJIT_PATH\etc;
	rm -r $LUAJIT_PATH\src;
	rm $LUAJIT_PATH\.gitignore;
	rm $LUAJIT_PATH\COPYRIGHT;
	rm $LUAJIT_PATH\Makefile;
	rm $LUAJIT_PATH\README;
	WriteHost-ForegroundColor "LuaJIT Installed" 'Green';
	
	return $False;
}

function MakeLua-Uninstall-Lua {
	WriteHost-ForegroundColor "Uninstalling Lua" 'Green';
	if (Test-Path -Path $LUA_PATH) {
		rm -r $LUA_PATH;
	}
	WriteHost-ForegroundColor "Lua Uninstalled" 'Green';

	return $False;
}

function MakeLua-Uninstall-Nelua {
	WriteHost-ForegroundColor "Uninstalling Nelua" 'Green';
	if (Test-Path -Path $NELUA_PATH) {
		rm -r $NELUA_PATH;
	}
	WriteHost-ForegroundColor "Nelua Uninstalled" 'Green';

	return $False;
}

function MakeLua-Uninstall-LuaJIT {
	WriteHost-ForegroundColor "Uninstalling LuaJIT" 'Green';
	if (Test-Path -Path $LUAJIT_PATH) {
		rm -r $LUAJIT_PATH;
	}
	WriteHost-ForegroundColor "LuaJIT Uninstalled" 'Green';

	return $False;
}

function Argument-Error {
	WriteHost-Colored '#red#Non-Existent# Options';
	pause;
	exit;
}

################################################################
#	BEHAVIORS
################################################################

CreateBasicDirs;
GotoDefaultDir;

if ($args.Count -eq 0) {
	MakeLua-DefaultMessage;
}

if ($args.Count -eq 1) {
	MakeLua-DefaultMessage;
}

if (($args.Count -ge 2) -and ($Args[0] -eq 'makelua') -and ($Args[1] -eq 'help')) {
	MakeLua-Help;
}

if (-not $IS_ADMIN) {
	GetAdminMode $Args;
}

$ARG_ERR = $True;

if (($args.Count -eq 2 ) -and ($Args[0] -eq 'makelua') -and ($args[1] -eq 'setup')) {
	$ARG_ERR = MakeLua-Setup;
	exit;
}

if (($args.Count -eq 2 ) -and ($Args[0] -eq 'makelua') -and ($args[1] -eq 'remove')) {
	$ARG_ERR = MakeLua-Remove;
	pause;
	exit;
}

if (($args.Count -ge 3 ) -and ($Args[0] -eq 'makelua') -and ($args[1] -eq 'install') -and ($args[2] -eq 'lua')) {
	$ARG_ERR = MakeLua-Install-Lua;
}

if (($args.Count -eq 3 ) -and ($Args[0] -eq 'makelua') -and ($args[1] -eq 'install') -and ($args[2] -eq 'nelua')) {
	$ARG_ERR = MakeLua-Install-Nelua;
	pause;
	exit;
}

if (($args.Count -eq 3 ) -and ($Args[0] -eq 'makelua') -and ($args[1] -eq 'install') -and ($args[2] -eq 'luajit')) {
	$ARG_ERR = MakeLua-Install-LuaJIT;
	pause;
	exit;
}

if (($args.Count -ge 3 ) -and ($Args[0] -eq 'makelua') -and ($args[1] -eq 'uninstall') -and ($arg[2] -eq 'lua')) {
	$ARG_ERR = MakeLua-Uninstall-Lua;
	pause;
	exit;
}

if (($args.Count -eq 3 ) -and ($Args[0] -eq 'makelua') -and ($args[1] -eq 'uninstall') -and ($args[2] -eq 'nelua')) {
	$ARG_ERR = MakeLua-Uninstall-Nelua;
	pause;
	exit;
}

if (($args.Count -eq 3 ) -and ($Args[0] -eq 'makelua') -and ($args[1] -eq 'uninstall') -and ($args[2] -eq 'luajit')) {
	$ARG_ERR = MakeLua-Uninstall-LuaJIT;
	pause;
	exit;
}

if ($ARG_ERR -eq $True) {
	Argument-Error;
}

################################
# makelua install lua
################################
$LUA_VERSION_ARRAY = ($LUA_DATA.LUA_VERSION).Split('.');
$LUA_VERSION_NAME = ($LUA_VERSION_ARRAY[0] + $LUA_VERSION_ARRAY[1]) -as [string];
$LUAROCKS_CONFIG_FILE = "config-$(($LUA_VERSION_ARRAY[0] + '.' + $LUA_VERSION_ARRAY[1]) -as [string]).lua";

################################
# luarocks information files
################################
if (-not(Test-Path -Path "$LUAROCKS_SYSTEM_PATH\$LUAROCKS_CONFIG_FILE" -PathType Leaf)) {
	new-item "$LUAROCKS_SYSTEM_PATH\$LUAROCKS_CONFIG_FILE" | Out-Null;
} if (-not(Test-Path -Path "$LUAROCKS_ROAMING_PATH\$LUAROCKS_CONFIG_FILE" -PathType Leaf)) {
	new-item "$LUAROCKS_ROAMING_PATH\$LUAROCKS_CONFIG_FILE" | Out-Null;
}
Write-Host "Lua Version: $($LUA_DATA.LUA_VERSION)";
Write-Host "LuaRocks Version: $($LUA_DATA.LUAROCKS_VERSION)";
Write-Host "Lua Version Name: $LUA_VERSION_NAME";

Write-Host 'start shell script';
Write-Host 'import luarocks';
if (Test-Path -Path luarocks.exe -PathType Leaf) {
	rm luarocks.exe;
} if (Test-Path -Path luarocks-admin.exe -PathType Leaf) {
	rm luarocks-admin.exe;
}
curl -R -O http://luarocks.github.io/luarocks/releases/luarocks-$($LUA_DATA.LUAROCKS_VERSION)-windows-64.zip;
7z x luarocks-$($LUA_DATA.LUAROCKS_VERSION)-windows-64.zip;
mv luarocks-$($LUA_DATA.LUAROCKS_VERSION)-windows-64/luarocks.exe luarocks.exe;
mv luarocks-$($LUA_DATA.LUAROCKS_VERSION)-windows-64/luarocks-admin.exe luarocks-admin.exe;
rm -r luarocks-$($LUA_DATA.LUAROCKS_VERSION)-windows-64;
rm luarocks-$($LUA_DATA.LUAROCKS_VERSION)-windows-64.zip;

Write-Host 'import lua code';
curl -L -R -O http://www.lua.org/ftp/lua-$($LUA_DATA.LUA_VERSION).tar.gz;
tar zxf lua-$($LUA_DATA.LUA_VERSION).tar.gz;
if (Test-Path -Path ./lua-$($LUA_DATA.LUA_VERSION)) {
	Set-Location lua-$($LUA_DATA.LUA_VERSION);
} else {
	Write-Host "dont find lua-$($LUA_DATA.LUA_VERSION) folder";
	exit;
}
if (Test-Path -Path ./src) {
	Set-Location src;
} else {
	Write-Host 'dont find src folder';
	Set-Location ..;
	exit;
}

new-item wmain.c | Out-Null;
set-content wmain.c '#include <windows.h>
#include <stdlib.h>
extern int main (int argc, char **argv);
extern int __argc;
extern char ** __argv;

INT WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR pCmdLine, int nCmdShow)
{
    return main(__argc, __argv);
}';

if ($LUA_DATA.COMPILER -eq 'msvc') {
	if ($LUA_DATA.OPTIMIZE -eq 'default') {
		$O = 'Ot'
	}
	elseif ($LUA_DATA.OPTIMIZE -eq 'speed') {
		$O = 'O2'
	}
	elseif ($LUA_DATA.OPTIMIZE -eq 'size') {
		$O = 'O1'
	}
	$startEnv = $env:path;
	function Invoke-VsScript {
		param(
			[String] $scriptName
		)

		if(Test-Path 'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build') {
			$env:path = $env:path + ';C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build';
		} elseif(Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build') {
			$env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build';
		} elseif(Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build') {
			$env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build';
		} elseif(Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2015\Community\VC\Auxiliary\Build') {
			$env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2015\Community\VC\Auxiliary\Build';
		} else {
			Write-Host "Microsoft Visual Studio path don't find";
			exit;
		}

		$env:VSCMD_SKIP_SENDTELEMETRY = 1
		$cmdLine = "$scriptName $args & set";
		& $env:SystemRoot\system32\cmd.exe /c $cmdLine |
		Select-String '^([^=]*)=(.*)$' | ForEach-Object {
			$varName = $_.Matches[0].Groups[1].Value;
			$varValue = $_.Matches[0].Groups[2].Value;
			Set-Item Env:$varName $varValue;
		}
	}
	
	function RestartEnv {
		$env:path = $startEnv
	}
	
	Invoke-VsScript vcvars64.bat;
	Write-Host 'using MSVC compiler';
	Write-Host 'start build .c files';
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		cl /MD /$O /c /DLUA_BUILD_AS_DLL *.c | Out-Null;
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		cl /MD /$O /c /DLUA_BUILD_AS_LIB *.c | Out-Null;
	}
	ren lua.obj lua.o;
	ren luac.obj luac.o;
	ren wmain.obj wmain.o;
	Write-Host "start build lua$LUA_VERSION_NAME.dll and lua$LUA_VERSION_NAME.lib";
	link /DLL /IMPLIB:lua$LUA_VERSION_NAME.lib /OUT:lua$LUA_VERSION_NAME.dll *.obj | Out-Null;
	Write-Host "start build lua$LUA_VERSION_NAME-static.lib";
	lib /OUT:lua$LUA_VERSION_NAME-static.lib *.obj | Out-Null;
	Write-Host "start build lua$LUA_VERSION_NAME.exe";
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		link /subsystem:console /OUT:lua$LUA_VERSION_NAME.exe lua.o lua$LUA_VERSION_NAME.lib | Out-Null;	
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		link /subsystem:console /OUT:lua$LUA_VERSION_NAME.exe lua$LUA_VERSION_NAME-static.lib lua.o | Out-Null;	
	}
	Write-Host "start build wlua$LUA_VERSION_NAME.exe";
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		link /subsystem:windows /defaultlib:shell32.lib /OUT:wlua$LUA_VERSION_NAME.exe lua.o wmain.o lua$LUA_VERSION_NAME.lib | Out-Null;	
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		link /subsystem:windows /defaultlib:shell32.lib /OUT:wlua$LUA_VERSION_NAME.exe lua.o wmain.o lua$LUA_VERSION_NAME-static.lib | Out-Null;
	}
	Write-Host "start build luac$LUA_VERSION_NAME.exe";
	link /subsystem:console /OUT:luac$LUA_VERSION_NAME.exe luac.o lua$LUA_VERSION_NAME-static.lib | Out-Null;
	Write-Host 'finish build';
	RestartEnv;
} elseif ($LUA_DATA.COMPILER -eq 'llvm') {
	if ($LUA_DATA.OPTIMIZE -eq 'default') {
		$O = 'O3'
	}
	elseif ($LUA_DATA.OPTIMIZE -eq 'speed') {
		$O = 'Ofast'
	}
	elseif ($LUA_DATA.OPTIMIZE -eq 'size') {
		$O = 'Oz'
	}
	Write-Host 'using LLVM compiler';
	Write-Host 'start build .c files';
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		clang -MD -$O -c -DLUA_BUILD_AS_DLL *.c | Out-Null;
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		clang -MD -$O -c -DLUA_BUILD_AS_LIB *.c | Out-Null;
	}
	ren lua.o lua.obj;
	ren luac.o luac.obj;
	ren wmain.o wmain.obj;
	Write-Host "start build lua$LUA_VERSION_NAME.dll and lua$LUA_VERSION_NAME.lib";
	clang -$O -DNDEBUG -static *.o -shared -$("Wl,-implib:lua$LUA_VERSION_NAME.lib") -o lua$LUA_VERSION_NAME.dll | Out-Null;
	Write-Host "start build lua$LUA_VERSION_NAME-static.lib";
	llvm-lib /OUT:lua$LUA_VERSION_NAME-static.lib *.o | Out-Null;
	Write-Host "start build lua$LUA_VERSION_NAME.exe";
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME.lib lua.obj -$('Wl,-subsystem:console') -o lua$LUA_VERSION_NAME.exe | Out-Null;
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME-static.lib lua.obj -$('Wl,-subsystem:console') -o lua$LUA_VERSION_NAME.exe | Out-Null;
	}
	Write-Host "start build wlua$LUA_VERSION_NAME.exe";
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME.lib lua.obj wmain.obj -$('Wl,-subsystem:windows') -$('Wl,-defaultlib:shell32.lib') -o wlua$LUA_VERSION_NAME.exe | Out-Null;
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME-static.lib lua.obj wmain.obj -$('Wl,-subsystem:windows') -$('Wl,-defaultlib:shell32.lib') -o wlua$LUA_VERSION_NAME.exe | Out-Null;
	}
	Write-Host "start build luac$LUA_VERSION_NAME.exe";
	clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME-static.lib luac.obj -$('Wl,-subsystem:console') -o luac$LUA_VERSION_NAME.exe | Out-Null;
	Write-Host 'finish build';
} elseif ($LUA_DATA.COMPILER -eq 'gnu') {
	if ($LUA_DATA.OPTIMIZE -eq 'default') {
		$O = 'O3'
	}
	elseif ($LUA_DATA.OPTIMIZE -eq 'speed') {
		$O = 'Ofast'
	}
	elseif ($LUA_DATA.OPTIMIZE -eq 'size') {
		$O = 'Oz'
	}
	Write-Host 'using GNU compiler';
	Write-Host 'start build .c files';
	gcc -$O -DNDEBUG -c *.c | Out-Null;
	ren lua.o lua.obj;
	ren luac.o luac.obj;
	ren wmain.o wmain.obj;
	Write-Host "start build lua$LUA_VERSION_NAME.dll";
	gcc -$O -DNDEBUG -static-libgcc -static *.o -shared -o lua$LUA_VERSION_NAME.dll;
	Write-Host "start build lua$LUA_VERSION_NAME.lib and liblua$LUA_VERSION_NAME.a";
	ar -rcs lua$LUA_VERSION_NAME.lib lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o lauxlib.o lbaselib.o lcorolib.o ldblib.o liolib.o lmathlib.o loadlib.o loslib.o lstrlib.o ltablib.o lutf8lib.o linit.o;
	cp lua$LUA_VERSION_NAME.lib liblua$LUA_VERSION_NAME.a;
	Write-Host "start build lua$LUA_VERSION_NAME.exe";
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		gcc -$O -DNDEBUG -static-libgcc -static lua.obj lua$LUA_VERSION_NAME.dll -W -o lua$LUA_VERSION_NAME.exe;
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		gcc -$O -DNDEBUG -static-libgcc -static lua.obj -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o lua$LUA_VERSION_NAME.exe;
	}
	Write-Host "start build wlua$LUA_VERSION_NAME.exe";
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		gcc -mwindows -$O -DNDEBUG -static-libgcc -static lua.obj lua$LUA_VERSION_NAME.dll -W -o wlua$LUA_VERSION_NAME.exe;
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		gcc -mwindows -$O -DNDEBUG -static-libgcc -static lua.obj -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o wlua$LUA_VERSION_NAME.exe;
	}
	Write-Host "start build luac$LUA_VERSION_NAME.exe";
	if ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'dynamic') {
		gcc -$O -DNDEBUG -static-libgcc -static luac.obj lua$LUA_VERSION_NAME.dll -W -o luac$LUA_VERSION_NAME.exe;
	}
	elseif ($LUA_DATA.IS_DYNAMIC_OR_STATIC -eq 'static') {
		gcc -$O -DNDEBUG -static-libgcc -static luac.obj -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o luac$LUA_VERSION_NAME.exe;
	}
	Write-Host 'finish build';
} else {
	Write-Host "don't exist this compiler: $($LUA_DATA.COMPILER)"
	exit;
}

Set-Location ..;
Set-Location ..;
Write-Host 'start move and delete';
if (Test-Path -Path ./include) {
	rm -r include;
}
mkdir include | Out-Null;
mv lua-$($LUA_DATA.LUA_VERSION)\src\lauxlib.h include\lauxlib.h;
mv lua-$($LUA_DATA.LUA_VERSION)\src\lua.h include\lua.h;
mv lua-$($LUA_DATA.LUA_VERSION)\src\lua.hpp include\lua.hpp;
mv lua-$($LUA_DATA.LUA_VERSION)\src\luaconf.h include\luaconf.h;
mv lua-$($LUA_DATA.LUA_VERSION)\src\lualib.h include\lualib.h;

if (Test-Path -Path lua$LUA_VERSION_NAME.dll -PathType Leaf) {
	rm lua$LUA_VERSION_NAME.dll;
} if (Test-Path -Path lua$LUA_VERSION_NAME.lib -PathType Leaf) {
	rm lua$LUA_VERSION_NAME.lib;
} if (Test-Path -Path lua$LUA_VERSION_NAME-static.lib -PathType Leaf) {
	rm lua$LUA_VERSION_NAME-static.lib;
} if (Test-Path -Path liblua$LUA_VERSION_NAME.a -PathType Leaf) {
	rm liblua$LUA_VERSION_NAME.a;
} if (Test-Path -Path lua$LUA_VERSION_NAME.exe -PathType Leaf) {
	rm lua$LUA_VERSION_NAME.exe;
} if (Test-Path -Path luac$LUA_VERSION_NAME.exe -PathType Leaf) {
	rm luac$LUA_VERSION_NAME.exe;
} if (Test-Path -Path wlua$LUA_VERSION_NAME.exe -PathType Leaf) {
	rm wlua$LUA_VERSION_NAME.exe;
}

if (Test-Path -Path lua-$($LUA_DATA.LUA_VERSION)\src\lua$LUA_VERSION_NAME.dll -PathType Leaf) {
	mv lua-$($LUA_DATA.LUA_VERSION)\src\lua$LUA_VERSION_NAME.dll lua$LUA_VERSION_NAME.dll;
} if (Test-Path -Path lua-$($LUA_DATA.LUA_VERSION)\src\lua$LUA_VERSION_NAME.lib -PathType Leaf) {
	mv lua-$($LUA_DATA.LUA_VERSION)\src\lua$LUA_VERSION_NAME.lib lua$LUA_VERSION_NAME.lib;
} if (Test-Path -Path lua-$($LUA_DATA.LUA_VERSION)\src\lua$LUA_VERSION_NAME-static.lib -PathType Leaf) {
	mv lua-$($LUA_DATA.LUA_VERSION)\src\lua$LUA_VERSION_NAME-static.lib lua$LUA_VERSION_NAME-static.lib;
} if (Test-Path -Path lua-$($LUA_DATA.LUA_VERSION)\src\liblua$LUA_VERSION_NAME.a -PathType Leaf) {
	mv lua-$($LUA_DATA.LUA_VERSION)\src\liblua$LUA_VERSION_NAME.a liblua$LUA_VERSION_NAME.a;
} if (Test-Path -Path lua-$($LUA_DATA.LUA_VERSION)\src\lua$LUA_VERSION_NAME.exe -PathType Leaf) {
	mv lua-$($LUA_DATA.LUA_VERSION)\src\lua$LUA_VERSION_NAME.exe lua$LUA_VERSION_NAME.exe;
} if (Test-Path -Path lua-$($LUA_DATA.LUA_VERSION)\src\luac$LUA_VERSION_NAME.exe -PathType Leaf) {
	mv lua-$($LUA_DATA.LUA_VERSION)\src\luac$LUA_VERSION_NAME.exe luac$LUA_VERSION_NAME.exe;
} if (Test-Path -Path lua-$($LUA_DATA.LUA_VERSION)\src\wlua$LUA_VERSION_NAME.exe -PathType Leaf) {
	mv lua-$($LUA_DATA.LUA_VERSION)\src\wlua$LUA_VERSION_NAME.exe wlua$LUA_VERSION_NAME.exe;
}
rm -r lua-$($LUA_DATA.LUA_VERSION);
rm -r lua-$($LUA_DATA.LUA_VERSION).tar.gz;

Write-Host 'start create linker files';
if (-not(Test-Path -Path lua.bat -PathType Leaf)) {
	new-item lua.bat | Out-Null;
} if (-not(Test-Path -Path luac.bat -PathType Leaf)) {
	new-item luac.bat | Out-Null;
} if (-not(Test-Path -Path wlua.bat -PathType Leaf)) {
	new-item wlua.bat | Out-Null;
}
set-content lua.bat "@call `"%~dp0lua$LUA_VERSION_NAME`" %*";
set-content luac.bat "@call `"%~dp0luac$LUA_VERSION_NAME`" %*";
set-content wlua.bat "@call `"%~dp0wlua$LUA_VERSION_NAME`" %*";

Write-Host 'start create init lua files';
if (-not(Test-Path -Path ./init)) {
	mkdir init;
}
if (-not(Test-Path -Path init/rocks.lua -PathType Leaf)) {
	new-item init/rocks.lua | Out-Null;
}
set-content init/rocks.lua 'local app_data = os.getenv ("APPDATA")
local lua_version = _VERSION:sub(5,7)
local luarocks_path = ";" .. app_data .. "\\luarocks\\share\\lua\\" .. lua_version .. "\\?.lua"
local luarocks_cpath = ";" .. app_data .. "\\luarocks\\lib\\lua\\" .. lua_version .. "\\?.dll"

package.path = package.path .. luarocks_path
package.cpath = package.cpath .. luarocks_cpath';

Write-Host 'finish script';
Set-Location $CURRENT_PATH;
pause;