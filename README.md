# MakeLua
makelua is a script (for windows) that allows you to install any version of the lua (>= 5.2) + luarocks (>= 3.3.0) running only 1 command in the terminal using MSVC, LLVM or GNU compiler. 

 - command: makelua.ps1 [compiler(optional)] [lua version(optional)] [luarocks version(optional)]
 - example1: makelua.ps1 gnu 5.4.4 3.9.1
 - example2: makelua.ps1 llvm 5.4.4 3.9.1
 - example3: makelua.ps1 msvc 5.4.4 3.9.1
 - example3: makelua.ps1 --> will use MSVC with the latest lua and luarocks
