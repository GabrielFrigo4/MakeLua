# makelua use powershell
# makelua use msvc or llvm or gnu
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

function GetLuaVersionWeb{
	$Link = 'https://www.lua.org/ftp/';
	return (Invoke-WebRequest -Uri $Link).links.href[14].Replace('lua-', '').Replace('.tar.gz', '') -as [string];
}

function GetLuaRocksVersionWeb{
	$Link = 'http://luarocks.github.io/luarocks/releases/';
	return (Invoke-WebRequest -Uri $Link).links.href[9].Replace('luarocks-', '').Replace('-windows-64.zip', '') -as [string];
}

$CURRENT_OS = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption;
$CURRENT_PATH = pwd;
$SCRIPT_PATH = $PSScriptRoot;
$LUAROCKS_ROAMING_PATH = "$env:USERPROFILE\AppData\Roaming\luarocks";
$LUAROCKS_LOCAL_PATH = "$env:USERPROFILE\AppData\Local\LuaRocks";
$LUAROCKS_SYSTEM_PATH = 'C:\Program Files\luarocks';
$MAKELUA_PATH = 'C:\Program Files\MakeLua';
$MAKELUA_VERSION = '1.0.0';
$LUA_VERSION_WEB = GetLuaVersionWeb;
$LUAROCKS_VERSION_WEB = GetLuaRocksVersionWeb;

cd $SCRIPT_PATH;
# makelua noone arg
if($args.Count -eq 0){
	Write-Host 'type: "makelua help" for more information';
	exit;
}

# makelua help
if(($args.Count -ge 1) -and ($Args[0] -eq 'help')){
	$LUA_VERSION = $LUA_VERSION_WEB;
	$LUAROCKS_VERSION = $LUAROCKS_VERSION_WEB;
	Write-Host "|MAKE_LUA HELP|
	
MakeLua info:
 - os: $CURRENT_OS
 - path: `"$SCRIPT_PATH`"
 - version: $MAKELUA_VERSION

MakeLua uses:
 - powershell
 - msvc or llvm or gnu
 - curl
 - tar
 - 7z

MakeLua options: (help / install)
 - help: show inf
 - install: install lua and luarocks

MakeLua install options: (link, compiler, optimize, lua_version, luarocks_version)
 - link: dynamic static
 - compiler: msvc llvm gnu
 - optimize: default size speed
 - lua_version:
 - luarocks_version:

to install use `"makelua dynamic msvc default $LUA_VERSION $LUAROCKS_VERSION`"
MakeLua is a installer";
	exit;
}

# makelua uninstall
if(($args.Count -eq 1 ) -and ($args[0] -eq 'uninstall')){
	if (Test-Path -Path $LUAROCKS_ROAMING_PATH) {
		rm -r $LUAROCKS_ROAMING_PATH;
		echo "remove $LUAROCKS_ROAMING_PATH successfully"
	} if (Test-Path -Path $LUAROCKS_LOCAL_PATH) {
		rm -r $LUAROCKS_LOCAL_PATH;
		echo "remove $LUAROCKS_LOCAL_PATH successfully"
	} if (Test-Path -Path $LUAROCKS_SYSTEM_PATH) {
		rm -r $LUAROCKS_SYSTEM_PATH;
		echo "remove $LUAROCKS_SYSTEM_PATH successfully"
	} if (Test-Path -Path $MAKELUA_PATH) {
		rm -r $MAKELUA_PATH;
		echo "remove $MAKELUA_PATH successfully"
	}
	exit;
}

# makelua install options: (link, compiler, optimize, lua_version, luarocks_version)
if(($args.Count -ge 1 ) -and ($args[0] -eq 'install')){
	if (-not(Test-Path -Path $MAKELUA_PATH)) {
		mkdir $MAKELUA_PATH;
	}
	if (-not($MAKELUA_PATH -eq $SCRIPT_PATH)){
		mv "$SCRIPT_PATH\makelua.ps1" "$MAKELUA_PATH\makelua.ps1"
	}
	cd $MAKELUA_PATH;
	SetColor "Green";
	echo 'MakeLua Options Using:';
	$ERR = $False;
	if($args.Count -ge 2){
		$IS_DYNAMIC_OR_STATIC = $Args[0] -as [string]; #dynamic static || link options	
	} else {
		$IS_DYNAMIC_OR_STATIC='dynamic';
		echo " - link: $IS_DYNAMIC_OR_STATIC";
	}
	if($args.Count -ge 3){
		$COMPILER = $Args[1] -as [string]; #msvc llvm gnu || compiler options	
	} else {
		$COMPILER = 'msvc';
		echo " - compiler: $COMPILER";
	}
	if($args.Count -ge 4){
		$OPTIMIZE = $Args[2] -as [string]; #default size speed || optimize options	
	} else {
		$OPTIMIZE = 'default';
		echo " - optimize: $OPTIMIZE";
	}
	if($args.Count -ge 5){
		$LUA_VERSION = $Args[3] -as [string]; #lua version
	} else {
		$LUA_VERSION = $LUA_VERSION_WEB;
		echo " - lua_version: $LUA_VERSION";
	} 
	if($args.Count -ge 6){
		$LUAROCKS_VERSION = $Args[4] -as [string]; #luarocks version
	} else {
		$LUAROCKS_VERSION = $LUAROCKS_VERSION_WEB;
		echo " - luarocks_version: $LUAROCKS_VERSION";
	}
	echo '';
	ResetColor;
	if($ERR -eq $True){
		exit;
	}
}

$LUA_VERSION_ARRAY = ($LUA_VERSION).Split('.');
$LUA_VERSION_NAME = ($LUA_VERSION_ARRAY[0] + $LUA_VERSION_ARRAY[1]) -as [string];
$LUAROCKS_CONFIG_FILE = "config-$LUA_VERSION.lua";
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

new-item wmain.c;
set-content wmain.c '#include <windows.h>
#include <stdio.h>
#include <shellapi.h>
#include <stdlib.h>
#include <limits.h>
extern int main (int argc, char **argv);

INT WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    PSTR lpCmdLine, INT nCmdShow)
{
    int argc;
	LPWSTR wCmd = GetCommandLineW();
    LPWSTR* wArgv = CommandLineToArgvW(wCmd, &argc);
	char** argv = malloc(sizeof(char*) * (argc + 1));
	for(int i = 0; i < argc; i++){
		int size = 0;
		while(wArgv[i][size] != 0){
			size++;
		}
		size++;
		argv[i] = malloc(sizeof(char) * size);
		size_t sret;
		wcstombs_s(&sret, argv[i], (size_t)size, wArgv[i], (size_t)size-1);
	}
	argv[argc] = malloc(sizeof(char) * 1);
	argv[argc][0] = 0;
	
	int mret = main(argc, argv);
	for(int i = 0; i <= argc; i++){
		free(argv[i]);
	}
	free(argv);
	LocalFree(wArgv);	
	
    return mret;
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
	llvm-ar -rcs lua$LUA_VERSION_NAME-static.lib *.o | Out-Null;
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
mkdir include;
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
	new-item lua.bat;
} if (-not(Test-Path -Path luac.bat -PathType Leaf)) {
	new-item luac.bat;
} if (-not(Test-Path -Path wlua.bat -PathType Leaf)) {
	new-item wlua.bat;
}
if (-not(Test-Path -Path makelua.bat -PathType Leaf)) {
	new-item makelua.bat;
}
set-content lua.bat "@call `"%~dp0\lua$LUA_VERSION_NAME`" %*";
set-content luac.bat "@call `"%~dp0\luac$LUA_VERSION_NAME`" %*";
set-content wlua.bat "@call `"%~dp0\wlua$LUA_VERSION_NAME`" %*";
set-content makelua.bat "@call pwsh -file `"%~dp0\\makelua.ps1`" %*";
echo 'finish script';
cd $CURRENT_PATH
pause;