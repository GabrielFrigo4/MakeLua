# makelua use powershell 7 or greater
# makelua use msvc or llvm or gnu
# makelua use make
# makelua use git
# makelua use curl
# makelua use tar
# makelua use 7z

$T = $host.ui.RawUI.ForegroundColor;

function SetColor{
	param(
		[String] $color
	)
	$host.ui.RawUI.ForegroundColor = $color;
}

function ResetColor{
	$host.ui.RawUI.ForegroundColor = $T;
}

function EchoColor{
	param(
		[String] $echo,
		[String] $color
	)
	SetColor $color;
	echo $echo;
	ResetColor;
}

function Newline{
	echo '';
}

function GetLuaVersionWeb{
	$Link = 'https://www.lua.org/ftp/';
	return (Invoke-WebRequest -Uri $Link).links.href[14].Replace('lua-', '').Replace('.tar.gz', '') -as [string];
}

function GetLuaRocksVersionWeb{
	$Link = 'http://luarocks.github.io/luarocks/releases/';
	return (Invoke-WebRequest -Uri $Link).links.href[9].Replace('luarocks-', '').Replace('-windows-64.zip', '') -as [string];
}

# informations
$CURRENT_OS = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption;
$MAKELUA_VERSION = '1.1.1';
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

# create basic dirs
if (-not(Test-Path -Path $LUAROCKS_ROAMING_PATH)) {
	mkdir $LUAROCKS_ROAMING_PATH | Out-Null;
} if (-not(Test-Path -Path $LUAROCKS_LOCAL_PATH)) {
	mkdir $LUAROCKS_LOCAL_PATH | Out-Null;
}

# go to default dir
cd $PROGAM_FILES_PATH;

# makelua noone arg
if($args.Count -eq 0){
	Write-Host 'type: "makelua help" for more information';
	cd $CURRENT_PATH;
	exit;
}

# makelua help
if(($args.Count -ge 1) -and ($Args[0] -eq 'help')){
	$LUA_VERSION = GetLuaVersionWeb;
	$LUAROCKS_VERSION = GetLuaRocksVersionWeb;
	Write-Host "|MAKE_LUA HELP|
	
MakeLua info:
 - os: $CURRENT_OS
 - path: `"$SCRIPT_PATH`"
 - version: $MAKELUA_VERSION

MakeLua uses:
 - powershell 7 or greater
 - msvc or llvm or gnu
 - curl
 - tar
 - 7z

(MakeLua) options: (help / install / uninstall)
 - help: show help information (this)
 - install: install lua and luarocks
 - uninstall: uninstall lua and luarocks

(MakeLua install) options: (lua / nelua / luajit)
 - lua
 - nelua
 - luajit

(MakeLua install lua) options: (link, compiler, optimize, lua_version, luarocks_version)
 - link: dynamic static
 - compiler: msvc llvm gnu
 - optimize: default size speed
 - lua_version:
 - luarocks_version:

to install use `"makelua install lua dynamic msvc default $LUA_VERSION $LUAROCKS_VERSION`"
MakeLua is a installer";
	cd $CURRENT_PATH;
	exit;
}

# get admin mode
$IS_ADMIN = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544");
if(-not $IS_ADMIN)
{
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
	cd $CURRENT_PATH;
	exit;
}

# makelua uninstall
if(($args.Count -eq 1 ) -and ($args[0] -eq 'uninstall')){
	sleep 2;
	if (Test-Path -Path $LUAROCKS_ROAMING_PATH) {
		rm -r $LUAROCKS_ROAMING_PATH -Force;
		EchoColor "remove $LUAROCKS_ROAMING_PATH successfully" 'Green';
	} if (Test-Path -Path $LUAROCKS_LOCAL_PATH) {
		rm -r $LUAROCKS_LOCAL_PATH -Force;
		EchoColor "remove $LUAROCKS_LOCAL_PATH successfully" 'Green';
	} if (Test-Path -Path $LUAROCKS_SYSTEM_PATH) {
		rm -r $LUAROCKS_SYSTEM_PATH -Force;
		EchoColor "remove $LUAROCKS_SYSTEM_PATH successfully" 'Green';
	} if (Test-Path -Path $MAKELUA_PATH) {
		rm -r $MAKELUA_PATH -Force;
		EchoColor "remove $MAKELUA_PATH successfully" 'Green';
	}
	cd $CURRENT_PATH;
	pause;
	exit;
}

$ARG_ERR = $True;

# makelua install lua options: (link, compiler, optimize, lua_version, luarocks_version)
if(($args.Count -ge 2 ) -and ($args[0] -eq 'install') -and ($args[1] -eq 'lua')){
	$LUA_PATH = "$MAKELUA_PATH\lua-lang";
	$ARG_ERR = $False;
	EchoColor "Installing Lua" 'Green';

	#luarocks information dir
	if (-not(Test-Path -Path $LUAROCKS_SYSTEM_PATH)) {
		mkdir $LUAROCKS_SYSTEM_PATH | Out-Null;
	}
	# makelua dir
	if (-not(Test-Path -Path $MAKELUA_PATH)) {
		mkdir $MAKELUA_PATH | Out-Null;
	} if (-not(Test-Path -Path $MAKELUA_PATH)) {
		mkdir $MAKELUA_PATH | Out-Null;
	} 
	
	if (Test-Path -Path $LUA_PATH) {
		rm -r $LUA_PATH;
	}
	mkdir $LUA_PATH;
	
	if (-not($MAKELUA_PATH -eq $SCRIPT_PATH)){
		mv "$SCRIPT_PATH\makelua.ps1" "$MAKELUA_PATH\makelua.ps1"
	}
	
	cd $LUA_PATH;
	EchoColor 'MakeLua Options Using:' 'Green';
	$ERR = $False;
	
	if($Args.Count -ge 3){
		$IS_DYNAMIC_OR_STATIC = $Args[2] -as [string]; #dynamic static || link options	
	} else {
		$IS_DYNAMIC_OR_STATIC='dynamic';
	}
	EchoColor " - link: $IS_DYNAMIC_OR_STATIC" 'Green';
	
	if($Args.Count -ge 4){
		$COMPILER = $Args[3] -as [string]; #msvc llvm gnu || compiler options	
	} else {
		$COMPILER = 'msvc';
	}
	EchoColor " - compiler: $COMPILER" 'Green';
	
	if($Args.Count -ge 5){
		$OPTIMIZE = $Args[4] -as [string]; #default size speed || optimize options	
	} else {
		$OPTIMIZE = 'default';
	}
	EchoColor " - optimize: $OPTIMIZE" 'Green';
	
	if($Args.Count -ge 6){
		$LUA_VERSION = $Args[5] -as [string]; #lua version
	} else {
		$LUA_VERSION = GetLuaVersionWeb;
	}
	EchoColor " - lua_version: $LUA_VERSION" 'Green';
	
	if($Args.Count -ge 7){
		$LUAROCKS_VERSION = $Args[6] -as [string]; #luarocks version
	} else {
		$LUAROCKS_VERSION = GetLuaRocksVersionWeb;
	}
	EchoColor " - luarocks_version: $LUAROCKS_VERSION" 'Green';
		
	Newline;
	if($ERR -eq $True){
		exit;
	}
}

# makelua install nelua
if(($args.Count -eq 2 ) -and ($args[0] -eq 'install') -and ($args[1] -eq 'nelua')){
	$NELUA_PATH = "$MAKELUA_PATH\nelua-lang";
	EchoColor "Installing Nelua" 'Green';
	if (Test-Path -Path $NELUA_PATH) {
		rm -r $NELUA_PATH;
	}
	
	git clone "https://github.com/edubart/nelua-lang.git" "$NELUA_PATH";
	cd $NELUA_PATH;
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
	EchoColor "Nelua Installed" 'Green';
	pause;
	exit;
}

# makelua install luajit
if(($args.Count -eq 2 ) -and ($args[0] -eq 'install') -and ($args[1] -eq 'luajit')){
	$LUAJIT_PATH = "$MAKELUA_PATH\luajit-lang";
	EchoColor "Installing Luajit" 'Green';
	if (Test-Path -Path $LUAJIT_PATH) {
		rm -r $LUAJIT_PATH;
	}
	
	git clone "https://github.com/LuaJIT/LuaJIT.git" "$LUAJIT_PATH";
	cd $LUAJIT_PATH;
	make;
	
	mv $LUAJIT_PATH\src\luajit.exe $LUAJIT_PATH\luajit.exe;
	mv $LUAJIT_PATH\src\lua51.dll $LUAJIT_PATH\lua51.dll;
	Remove-item -Path $LUAJIT_PATH\.git -Force;
	rm -r $LUAJIT_PATH\doc;
	rm -r $LUAJIT_PATH\dynasm;
	rm -r $LUAJIT_PATH\etc;
	rm -r $LUAJIT_PATH\src;
	rm $LUAJIT_PATH\.gitignore;
	rm $LUAJIT_PATH\COPYRIGHT;
	rm $LUAJIT_PATH\Makefile;
	rm $LUAJIT_PATH\README;
	EchoColor "Nelua Installed" 'Green';
	pause;
	exit;
}

# args error
if($ARG_ERR -eq $True) {
	echo 'args count overflow';
	exit;
}

$LUA_VERSION_ARRAY = ($LUA_VERSION).Split('.');
$LUA_VERSION_NAME = ($LUA_VERSION_ARRAY[0] + $LUA_VERSION_ARRAY[1]) -as [string];
$LUAROCKS_CONFIG_FILE = "config-$(($LUA_VERSION_ARRAY[0] + '.' + $LUA_VERSION_ARRAY[1]) -as [string]).lua";
#luarocks information files
if (-not(Test-Path -Path "$LUAROCKS_SYSTEM_PATH\$LUAROCKS_CONFIG_FILE" -PathType Leaf)) {
	new-item "$LUAROCKS_SYSTEM_PATH\$LUAROCKS_CONFIG_FILE" | Out-Null;
} if (-not(Test-Path -Path "$LUAROCKS_ROAMING_PATH\$LUAROCKS_CONFIG_FILE" -PathType Leaf)) {
	new-item "$LUAROCKS_ROAMING_PATH\$LUAROCKS_CONFIG_FILE" | Out-Null;
}
echo "Lua Version: $LUA_VERSION";
echo "LuaRocks Version: $LUAROCKS_VERSION";
echo "Lua Version Name: $LUA_VERSION_NAME";

echo 'start shell script';
echo 'import luarocks';
if (Test-Path -Path luarocks.exe -PathType Leaf) {
	rm luarocks.exe;
} if (Test-Path -Path luarocks-admin.exe -PathType Leaf) {
	rm luarocks-admin.exe;
}
curl -R -O http://luarocks.github.io/luarocks/releases/luarocks-$LUAROCKS_VERSION-windows-64.zip;
7z x luarocks-$LUAROCKS_VERSION-windows-64.zip;
mv luarocks-$LUAROCKS_VERSION-windows-64/luarocks.exe luarocks.exe;
mv luarocks-$LUAROCKS_VERSION-windows-64/luarocks-admin.exe luarocks-admin.exe;
rm -r luarocks-$LUAROCKS_VERSION-windows-64;
rm luarocks-$LUAROCKS_VERSION-windows-64.zip;
echo 'import lua code';
curl -R -O http://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz;
tar zxf lua-$LUA_VERSION.tar.gz;
if (Test-Path -Path ./lua-$LUA_VERSION) {
	cd lua-$LUA_VERSION;
} else {
	echo "dont find lua-$LUA_VERSION folder";
	exit;
}
if (Test-Path -Path ./src) {
	cd src;
} else {
	echo 'dont find src folder';
	cd ..;
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

if ($COMPILER -eq 'msvc'){
	if($OPTIMIZE -eq 'default'){
		$O = 'Ot'
	}
	elseif($OPTIMIZE -eq 'speed'){
		$O = 'O2'
	}
	elseif($OPTIMIZE -eq 'size'){
		$O = 'O1'
	}
	$startEnv = $env:path;
	function Invoke-VsScript {
		param(
			[String] $scriptName
		)
		if(Test-Path 'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build'){
			$env:path = $env:path + ';C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build';
		} elseif(Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build'){
			$env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build';
		} elseif(Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build'){
			$env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build';
		} elseif(Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio\2015\Community\VC\Auxiliary\Build'){
			$env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2015\Community\VC\Auxiliary\Build';
		} else {
			Write-Host "Microsoft Visual Studio path don't find";
			exit;
		}
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
	echo 'using MSVC compiler';
	echo 'start build .c files';
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		cl /MD /$O /c /DLUA_BUILD_AS_DLL *.c | Out-Null;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		cl /MD /$O /c /DLUA_BUILD_AS_LIB *.c | Out-Null;
	}
	ren lua.obj lua.o;
	ren luac.obj luac.o;
	ren wmain.obj wmain.o;
	echo "start build lua$LUA_VERSION_NAME.dll and lua$LUA_VERSION_NAME.lib";
	link /DLL /IMPLIB:lua$LUA_VERSION_NAME.lib /OUT:lua$LUA_VERSION_NAME.dll *.obj | Out-Null;
	echo "start build lua$LUA_VERSION_NAME-static.lib";
	lib /OUT:lua$LUA_VERSION_NAME-static.lib *.obj | Out-Null;
	echo "start build lua$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		link /subsystem:console /OUT:lua$LUA_VERSION_NAME.exe lua.o lua$LUA_VERSION_NAME.lib | Out-Null;	
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		link /subsystem:console /OUT:lua$LUA_VERSION_NAME.exe lua$LUA_VERSION_NAME-static.lib lua.o | Out-Null;	
	}
	echo "start build wlua$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		link /subsystem:windows /defaultlib:shell32.lib /OUT:wlua$LUA_VERSION_NAME.exe lua.o wmain.o lua$LUA_VERSION_NAME.lib | Out-Null;	
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		link /subsystem:windows /defaultlib:shell32.lib /OUT:wlua$LUA_VERSION_NAME.exe lua.o wmain.o lua$LUA_VERSION_NAME-static.lib | Out-Null;
	}
	echo "start build luac$LUA_VERSION_NAME.exe";
	link /subsystem:console /OUT:luac$LUA_VERSION_NAME.exe luac.o lua$LUA_VERSION_NAME-static.lib | Out-Null;
	echo 'finish build';
	RestartEnv;
} elseif ($COMPILER -eq 'llvm'){
	if($OPTIMIZE -eq 'default'){
		$O = 'O3'
	}
	elseif($OPTIMIZE -eq 'speed'){
		$O = 'Ofast'
	}
	elseif($OPTIMIZE -eq 'size'){
		$O = 'Oz'
	}
	echo 'using LLVM compiler';
	echo 'start build .c files';
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		clang -MD -$O -c -DLUA_BUILD_AS_DLL *.c | Out-Null;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		clang -MD -$O -c -DLUA_BUILD_AS_LIB *.c | Out-Null;
	}
	ren lua.o lua.obj;
	ren luac.o luac.obj;
	ren wmain.o wmain.obj;
	echo "start build lua$LUA_VERSION_NAME.dll and lua$LUA_VERSION_NAME.lib";
	clang -$O -DNDEBUG -static *.o -shared -$("Wl,-implib:lua$LUA_VERSION_NAME.lib") -o lua$LUA_VERSION_NAME.dll | Out-Null;
	echo "start build lua$LUA_VERSION_NAME-static.lib";
	llvm-lib /OUT:lua$LUA_VERSION_NAME-static.lib *.o | Out-Null;
	echo "start build lua$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME.lib lua.obj -$('Wl,-subsystem:console') -o lua$LUA_VERSION_NAME.exe | Out-Null;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME-static.lib lua.obj -$('Wl,-subsystem:console') -o lua$LUA_VERSION_NAME.exe | Out-Null;
	}
	echo "start build wlua$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME.lib lua.obj wmain.obj -$('Wl,-subsystem:windows') -$('Wl,-defaultlib:shell32.lib') -o wlua$LUA_VERSION_NAME.exe | Out-Null;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME-static.lib lua.obj wmain.obj -$('Wl,-subsystem:windows') -$('Wl,-defaultlib:shell32.lib') -o wlua$LUA_VERSION_NAME.exe | Out-Null;
	}
	echo "start build luac$LUA_VERSION_NAME.exe";
	clang -$O -DNDEBUG -static lua$LUA_VERSION_NAME-static.lib luac.obj -$('Wl,-subsystem:console') -o luac$LUA_VERSION_NAME.exe | Out-Null;
	echo 'finish build';
} elseif ($COMPILER -eq 'gnu'){
	if($OPTIMIZE -eq 'default'){
		$O = 'O3'
	}
	elseif($OPTIMIZE -eq 'speed'){
		$O = 'Ofast'
	}
	elseif($OPTIMIZE -eq 'size'){
		$O = 'Oz'
	}
	echo 'using GNU compiler';
	echo 'start build .c files';
	gcc -$O -DNDEBUG -c *.c | Out-Null;
	ren lua.o lua.obj;
	ren luac.o luac.obj;
	ren wmain.o wmain.obj;
	echo "start build lua$LUA_VERSION_NAME.dll";
	gcc -$O -DNDEBUG -static-libgcc -static *.o -shared -o lua$LUA_VERSION_NAME.dll;
	echo "start build lua$LUA_VERSION_NAME.lib and liblua$LUA_VERSION_NAME.a";
	ar -rcs lua$LUA_VERSION_NAME.lib lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o lauxlib.o lbaselib.o lcorolib.o ldblib.o liolib.o lmathlib.o loadlib.o loslib.o lstrlib.o ltablib.o lutf8lib.o linit.o;
	cp lua$LUA_VERSION_NAME.lib liblua$LUA_VERSION_NAME.a;
	echo "start build lua$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		gcc -$O -DNDEBUG -static-libgcc -static lua.obj lua$LUA_VERSION_NAME.dll -W -o lua$LUA_VERSION_NAME.exe;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		gcc -$O -DNDEBUG -static-libgcc -static lua.obj -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o lua$LUA_VERSION_NAME.exe;
	}
	echo "start build wlua$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		gcc -mwindows -$O -DNDEBUG -static-libgcc -static lua.obj lua$LUA_VERSION_NAME.dll -W -o wlua$LUA_VERSION_NAME.exe;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		gcc -mwindows -$O -DNDEBUG -static-libgcc -static lua.obj -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o wlua$LUA_VERSION_NAME.exe;
	}
	echo "start build luac$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		gcc -$O -DNDEBUG -static-libgcc -static luac.obj lua$LUA_VERSION_NAME.dll -W -o luac$LUA_VERSION_NAME.exe;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		gcc -$O -DNDEBUG -static-libgcc -static luac.obj -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o luac$LUA_VERSION_NAME.exe;
	}
	echo 'finish build';
} else {
	echo "don't exist this compiler: $COMPILER"
	exit;
}

cd ..;
cd ..;
echo 'start move and delete';
if (Test-Path -Path ./include) {
	rm -r include;
}
mkdir include | Out-Null;
mv lua-$LUA_VERSION\src\lauxlib.h include\lauxlib.h;
mv lua-$LUA_VERSION\src\lua.h include\lua.h;
mv lua-$LUA_VERSION\src\lua.hpp include\lua.hpp;
mv lua-$LUA_VERSION\src\luaconf.h include\luaconf.h;
mv lua-$LUA_VERSION\src\lualib.h include\lualib.h;

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

if (Test-Path -Path lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.dll -PathType Leaf) {
	mv lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.dll lua$LUA_VERSION_NAME.dll;
} if (Test-Path -Path lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.lib -PathType Leaf) {
	mv lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.lib lua$LUA_VERSION_NAME.lib;
} if (Test-Path -Path lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME-static.lib -PathType Leaf) {
	mv lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME-static.lib lua$LUA_VERSION_NAME-static.lib;
} if (Test-Path -Path lua-$LUA_VERSION\src\liblua$LUA_VERSION_NAME.a -PathType Leaf) {
	mv lua-$LUA_VERSION\src\liblua$LUA_VERSION_NAME.a liblua$LUA_VERSION_NAME.a;
} if (Test-Path -Path lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.exe -PathType Leaf) {
	mv lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.exe lua$LUA_VERSION_NAME.exe;
} if (Test-Path -Path lua-$LUA_VERSION\src\luac$LUA_VERSION_NAME.exe -PathType Leaf) {
	mv lua-$LUA_VERSION\src\luac$LUA_VERSION_NAME.exe luac$LUA_VERSION_NAME.exe;
} if (Test-Path -Path lua-$LUA_VERSION\src\wlua$LUA_VERSION_NAME.exe -PathType Leaf) {
	mv lua-$LUA_VERSION\src\wlua$LUA_VERSION_NAME.exe wlua$LUA_VERSION_NAME.exe;
}
rm -r lua-$LUA_VERSION;
rm -r lua-$LUA_VERSION.tar.gz;

echo 'start create linker files';
if (-not(Test-Path -Path lua.bat -PathType Leaf)) {
	new-item lua.bat | Out-Null;
} if (-not(Test-Path -Path luac.bat -PathType Leaf)) {
	new-item luac.bat | Out-Null;
} if (-not(Test-Path -Path wlua.bat -PathType Leaf)) {
	new-item wlua.bat | Out-Null;
} if (-not(Test-Path -Path makelua.bat -PathType Leaf)) {
	new-item makelua.bat | Out-Null;
}
set-content lua.bat "@call `"%~dp0lua$LUA_VERSION_NAME`" %*";
set-content luac.bat "@call `"%~dp0luac$LUA_VERSION_NAME`" %*";
set-content wlua.bat "@call `"%~dp0wlua$LUA_VERSION_NAME`" %*";
set-content makelua.bat "@call pwsh -file `"%~dp0makelua.ps1`" %*";
echo 'finish script';
cd $CURRENT_PATH;
pause;