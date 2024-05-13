### What is "Windowless Lua"?

  - Windowless Lua does not create a console window.  
    It runs invisible for user.

  - Please note that "windowless" means "doesn't have stdin, stdout and stderr".  
    You will not be able to see error message.  
    `io.read()`, `io.write()` and `print()` in your Lua script will not work.  
    But in some situations invisible Lua is just what you need very much.  
    For example, to avoid a GUI application (especially a game) to lose input focus when some background Lua script is started.

----

# How to build 64-bit windowless Lua 5.4 binaries for Windows


1. **Download the latest Lua sources**

    - Create temporary folder for Lua sources.  
      I assume you would use `C:\Temp\` folder.

    - Visit [Lua FTP webpage](https://www.lua.org/ftp/) and download the latest Lua source archive, currently it is `lua-5.4.6.tar.gz`

    - Use suitable software ([7-Zip](https://www.7-zip.org/a/7z1900-x64.exe), WinRar, WinZip or TotalCommander) to unpack the archive.  
      Please note that with 7-Zip you have to unpack it twice: `lua-5.4.6.tar.gz` -> `lua-5.4.6.tar` -> `lua-5.4.6\`

    - Move unpacked Lua sources to `C:\Temp\lua-5.4.6\`

2. **Modify Lua sources**

    - Open folder `C:\Temp\lua-5.4.6\src\`

    - Find the file `lua.c` (or `luajit.c`), right-click it and select "Edit".  
      Notepad will open.  
      Text might look weird because Notepad does not recognize UNIX-style newline characters.  
      Please ignore this problem.

    - Scroll down to the end of the file and add the following 3 lines after the last line:
    ```c
    #include <windows.h>
    int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd)
    {
      return main(__argc, __argv);
    }
    ```
   
    - Save the file and close Notepad.

3. **Build Lua binaries using MinGW64**

    - Download and install [MSYS2](https://repo.msys2.org/distrib/x86_64/msys2-x86_64-20210419.exe).
      It is recommended to install MSYS2 in the default destination folder `C:\msys64\`,
      but you may choose another path consisting of English letters without spaces.
  
    - After installation is complete, a MSYS2 console window will open.
      Execute the following command in this MSYS2 console window:
      `pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-make`
      When asked `Proceed with installation? [Y/n]`, answer `Y` and press `Enter`.
  
    - Close this MSYS2 console window and open a new one by clicking the `MSYS2 MinGW 64-bit` menu item in Windows Start menu.
      Execute the following commands in the new MSYS2 window:
      ```bash
      cd /c/Temp/lua-5.4.6/
      mingw32-make MYLDFLAGS=-mwindows mingw
      ```
  
    - Close the MSYS2 console window.
  
    - You can uninstall "MSYS2" application now at `Control Panel` -> `Programs and Features`.

4. **Take Lua binaries**

    - Open folder `C:\Temp\lua-5.4.6\src\`
      Sort files by "Date Modified".
  
    - Find `lua.exe` among the most recently modified.
      Rename it to `wlua.exe`
  
    - Take 2 files: `wlua.exe` and `lua54.dll`
      and put them to the folder where Lua binaries should be on your system.
  
    - You can remove Lua sources now.
      Delete folder `C:\Temp\lua-5.4.6\`
