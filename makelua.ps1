# makelua use powershell
# makelua use msvc or llvm or gnu
# makelua use curl
# makelua use tar
# makelua use 7z

# makelua noone arg
if($args.Count -eq 0){
	Write-Host 'type: "makelua.ps1 help" for more information'
	exit;
}

# makelua help
if(($args.Count -ge 1) -and ($Args[0] -eq 'help')){
	Write-Host '|MAKE_LUA HELP|

MakeLua uses:
 - powershell
 - msvc or llvm or gnu
 - curl
 - tar
 - 7z

MakeLua options: (link, compiler, otimization, lua_version, luarocks_version)
 - link:
 - compiler:
 - otimization:
 - lua_version:
 - luarocks_version:

to install use "makelua.ps1 dynamic msvc fast 5.4.4 3.9.1"
MakeLua is a installer'
	exit;
}

# makelua options: (link, compiler, otimization, lua_version, luarocks_version)
if($args.Count -ge 1){
	$IS_DYNAMIC_OR_STATIC = $Args[0] -as [string]; #msvc llvm gnu || compiler options	
} else {
	$IS_DYNAMIC_OR_STATIC='dynamic'; # dynamic static || link options
}
if($args.Count -ge 2){
	$COMPILER = $Args[1] -as [string]; #msvc llvm gnu || compiler options	
} else {
	$COMPILER = 'msvc';
}
if($args.Count -ge 3){
	$OTIMIZATION = $Args[2] -as [string]; #default size speed || otimization options	
} else {
	$OTIMIZATION = 'default';
}
if($args.Count -ge 4){
	$LUA_VERSION = $Args[3] -as [string]; #lua version
} else {
	$Link = 'https://www.lua.org/ftp/';
	$LUA_VERSION = (Invoke-WebRequest -Uri $Link).links.href[14].Replace('lua-', '').Replace('.tar.gz', '') -as [string];
} 
if($args.Count -ge 5){
	$LUAROCKS_VERSION = $Args[4] -as [string]; #luarocks version
} else {
	$Link = 'http://luarocks.github.io/luarocks/releases/';
	$LUAROCKS_VERSION = (Invoke-WebRequest -Uri $Link).links.href[9].Replace('luarocks-', '').Replace('-windows-64.zip', '') -as [string];
}
$LUA_VERSION_ARRAY = ($LUA_VERSION).Split('.');
$LUA_VERSION_NAME = ($LUA_VERSION_ARRAY[0] + $LUA_VERSION_ARRAY[1]) -as [string];
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
	$startEnv = $env:path;
	function Invoke-VsScript {
	  param(
		[String] $scriptName
	  )
	  $env:path = $env:path + ';C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build';
	  $env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build';
	  $env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build';
	  $env:path = $env:path + ';C:\Program Files (x86)\Microsoft Visual Studio\2015\Community\VC\Auxiliary\Build';
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
	echo "start build lua$LUA_VERSION_NAME.dll";
	cl /O2 lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c /link /dll /out:lua$LUA_VERSION_NAME.dll | Out-Null;
	echo "start build lua$LUA_VERSION_NAME.lib and liblua$LUA_VERSION_NAME.a";
	cl /O2 /c lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c | Out-Null;
	lib /O2 /out:lua$LUA_VERSION_NAME.lib lapi.obj lcode.obj lctype.obj ldebug.obj ldo.obj ldump.obj lfunc.obj lgc.obj llex.obj lmem.obj lobject.obj lopcodes.obj lparser.obj lstate.obj lstring.obj ltable.obj ltm.obj lundump.obj lvm.obj lzio.obj lauxlib.obj lbaselib.obj lcorolib.obj ldblib.obj liolib.obj lmathlib.obj loadlib.obj loslib.obj lstrlib.obj ltablib.obj lutf8lib.obj linit.obj | Out-Null;
	cp lua$LUA_VERSION_NAME.lib liblua$LUA_VERSION_NAME.a;
	echo "start build lua$LUA_VERSION_NAME.exe";
	cl /O2 lua$LUA_VERSION_NAME.lib lua.c /link /subsystem:console /defaultlib:shell32.lib /defaultlib:user32.lib /defaultlib:kernel32.lib /out:lua$LUA_VERSION_NAME.exe | Out-Null;
	echo "start build lua$LUA_VERSION_NAME.exe";
	cl /O2 lua$LUA_VERSION_NAME.lib lua.c wmain.c /link /subsystem:windows /defaultlib:shell32.lib /defaultlib:user32.lib /defaultlib:kernel32.lib /out:wlua$LUA_VERSION_NAME.exe | Out-Null;
	echo "start build luac$LUA_VERSION_NAME.exe";
	cl /O2 lua$LUA_VERSION_NAME.lib luac.c /link /subsystem:console /defaultlib:shell32.lib /defaultlib:user32.lib /defaultlib:kernel32.lib  /out:luac$LUA_VERSION_NAME.exe | Out-Null;
	echo 'finish build';
	RestartEnv;
} elseif ($COMPILER -eq 'llvm'){
	echo 'using LLVM compiler';
	echo "start build lua$LUA_VERSION_NAME.dll";
	clang -O3 -DNDEBUG -static lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c -shared -o lua$LUA_VERSION_NAME.dll;
	echo "start build lua$LUA_VERSION_NAME.lib and liblua$LUA_VERSION_NAME.a";
	clang -O3 -DNDEBUG -c lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c;
	llvm-ar -rcs lua$LUA_VERSION_NAME.lib lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o lauxlib.o lbaselib.o lcorolib.o ldblib.o liolib.o lmathlib.o loadlib.o loslib.o lstrlib.o ltablib.o lutf8lib.o linit.o;
	cp lua$LUA_VERSION_NAME.lib liblua$LUA_VERSION_NAME.a;
	echo "start build lua$LUA_VERSION_NAME.exe";
	clang -O3 -DNDEBUG -static lua$LUA_VERSION_NAME.lib lua.c -$('Wl,-subsystem:console') -$('Wl,-defaultlib:shell32.lib') -$('Wl,-defaultlib:user32.lib') -$('Wl,-defaultlib:kernel32.lib') -o lua$LUA_VERSION_NAME.exe;
	echo "start build wlua$LUA_VERSION_NAME.exe";
	clang -O3 -DNDEBUG -static lua$LUA_VERSION_NAME.lib lua.c wmain.c -$('Wl,-subsystem:windows') -$('Wl,-defaultlib:shell32.lib') -$('Wl,-defaultlib:user32.lib') -$('Wl,-defaultlib:kernel32.lib') -o wlua$LUA_VERSION_NAME.exe;
	echo "start build luac$LUA_VERSION_NAME.exe";
	clang -O3 -DNDEBUG -static lua$LUA_VERSION_NAME.lib luac.c -$('Wl,-subsystem:console') -$('Wl,-defaultlib:shell32.lib') -$('Wl,-defaultlib:user32.lib') -$('Wl,-defaultlib:kernel32.lib') -o luac$LUA_VERSION_NAME.exe;
	echo 'finish build';
} elseif ($COMPILER -eq 'gnu'){
	echo 'using GNU compiler';
	echo "start build lua$LUA_VERSION_NAME.dll";
	gcc -O3 -DNDEBUG -static-libgcc -static lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c -shared -o lua$LUA_VERSION_NAME.dll;
	echo "start build lua$LUA_VERSION_NAME.lib and liblua$LUA_VERSION_NAME.a";
	gcc -O3 -DNDEBUG -c lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c lmathlib.c loadlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c;
	ar -rcs lua$LUA_VERSION_NAME.lib lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o ltm.o lundump.o lvm.o lzio.o lauxlib.o lbaselib.o lcorolib.o ldblib.o liolib.o lmathlib.o loadlib.o loslib.o lstrlib.o ltablib.o lutf8lib.o linit.o;
	cp lua$LUA_VERSION_NAME.lib liblua$LUA_VERSION_NAME.a;
	echo "start build lua$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		gcc -O3 -DNDEBUG -static-libgcc -static lua.c lua$LUA_VERSION_NAME.dll -W -o lua$LUA_VERSION_NAME.exe;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		gcc -O3 -DNDEBUG -static-libgcc -static lua.c -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o lua$LUA_VERSION_NAME.exe;
	}
	echo "start build wlua$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		gcc -mwindows -O3 -DNDEBUG -static-libgcc -static lua.c lua$LUA_VERSION_NAME.dll -W -o wlua$LUA_VERSION_NAME.exe;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		gcc -mwindows -O3 -DNDEBUG -static-libgcc -static lua.c -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o wlua$LUA_VERSION_NAME.exe;
	}
	echo "start build luac$LUA_VERSION_NAME.exe";
	if($IS_DYNAMIC_OR_STATIC -eq 'dynamic'){
		gcc -O3 -DNDEBUG -static-libgcc -static luac.c lua$LUA_VERSION_NAME.dll -W -o luac$LUA_VERSION_NAME.exe;
	}
	elseif($IS_DYNAMIC_OR_STATIC -eq 'static'){
		gcc -O3 -DNDEBUG -static-libgcc -static luac.c -L. -Bstatic -$('llua' + $LUA_VERSION_NAME) -W -o luac$LUA_VERSION_NAME.exe;
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
} if (Test-Path -Path liblua$LUA_VERSION_NAME.a -PathType Leaf) {
	rm liblua$LUA_VERSION_NAME.a;
} if (Test-Path -Path lua$LUA_VERSION_NAME.exe -PathType Leaf) {
	rm lua$LUA_VERSION_NAME.exe;
} if (Test-Path -Path luac$LUA_VERSION_NAME.exe -PathType Leaf) {
	rm luac$LUA_VERSION_NAME.exe;
} if (Test-Path -Path wlua$LUA_VERSION_NAME.exe -PathType Leaf) {
	rm wlua$LUA_VERSION_NAME.exe;
}
mv lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.dll lua$LUA_VERSION_NAME.dll;
mv lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.lib lua$LUA_VERSION_NAME.lib;
mv lua-$LUA_VERSION\src\liblua$LUA_VERSION_NAME.a liblua$LUA_VERSION_NAME.a;
mv lua-$LUA_VERSION\src\lua$LUA_VERSION_NAME.exe lua$LUA_VERSION_NAME.exe;
mv lua-$LUA_VERSION\src\luac$LUA_VERSION_NAME.exe luac$LUA_VERSION_NAME.exe;
mv lua-$LUA_VERSION\src\wlua$LUA_VERSION_NAME.exe wlua$LUA_VERSION_NAME.exe;
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
set-content lua.bat "@call lua$LUA_VERSION_NAME %*";
set-content luac.bat "@call luac$LUA_VERSION_NAME %*";
set-content wlua.bat "@call wlua$LUA_VERSION_NAME %*";
echo 'finish script';
pause;