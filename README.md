# <img src="https://user-images.githubusercontent.com/66432268/234748876-331de0ba-519b-4c47-a04a-83b14b1d1720.png" width="48" /> MakeLua
MakeLua is a installer Lua/Nelua/LuaJIT in Windows
 - to update luarocks version use: "sudo luarocks config --scope system lua_version 5.4"
 - to ser var in luarocks use: "luarocks config variables.VAR_NAME VAR_VALUE"

# <img src="https://user-images.githubusercontent.com/66432268/234748876-331de0ba-519b-4c47-a04a-83b14b1d1720.png" width="48" /> Windowless Lua for Windows (wlua)
Read [MAKE_WLUA.md](/MAKE_WLUA.md)

# <img src="https://nelua.io/assets/img/nelua-logo-64px.png" width="48" /> Nelua (In Windows)
[Nelua](https://nelua.io/) is a language type lua

    echo "Installing Nelua"
    git clone https://github.com/edubart/nelua-lang.git 
    cd nelua-lang 
    make
    
    Remove-item -Path .\.git -Force
    rm -r .github
    rm -r docs
    rm -r examples
    rm -r spec
    rm -r src
    rm -r tests
    rm .gitattributes
    rm .gitignore
    rm .luacheckrc
    rm .luacov
    rm CONTRIBUTING.md
    rm Dockerfile
    rm LICENSE
    rm nelua
    rm Makefile
    rm README.md
    echo "Nelua Installed"
    
    
# <img src="https://user-images.githubusercontent.com/66432268/234749103-1b1366c4-6b5a-438a-be0e-3444c661a2b4.png" width="48" /> Lua In linux (Debian)
(dpkg) to get lua and luarocks use:

    echo "Installing Lua"
    wget http://ftp.br.debian.org/debian/pool/main/l/lua5.4/liblua5.4-0_5.4.4-3_amd64.deb
    wget http://ftp.br.debian.org/debian/pool/main/l/lua5.4/liblua5.4-dev_5.4.4-3_amd64.deb
    wget http://ftp.br.debian.org/debian/pool/main/l/lua5.4/lua5.4_5.4.4-3_amd64.deb
    sudo dpkg -i liblua5.4-0_5.4.4-3_amd64.deb
    sudo dpkg -i liblua5.4-dev_5.4.4-3_amd64.deb
    sudo dpkg -i lua5.4_5.4.4-3_amd64.deb
    rm liblua5.4-0_5.4.4-3_amd64.deb
    rm liblua5.4-dev_5.4.4-3_amd64.deb
    rm lua5.4_5.4.4-3_amd64.deb
    echo "Lua Installed"
    
    echo "Installing LuaRocks"
    wget http://ftp.br.debian.org/debian/pool/main/l/luarocks/luarocks_3.8.0+dfsg1-1_all.deb
    sudo dpkg -i luarocks_3.8.0+dfsg1-1_all.deb
    rm luarocks_3.8.0+dfsg1-1_all.deb
    echo "LuaRocks Installed"

(apt) to get lua and luarocks use:
    
    echo "Installing Lua"
    sudo apt install liblua5.4-0
    sudo apt install liblua5.4-0-dbg
    sudo apt install liblua5.4-dev
    sudo apt install lua5.4
    echo "Lua Installed"
    echo "Installing LuaRocks"
    sudo apt install luarocks
    echo "LuaRocks Installed"

(make) to get lua and luarocks use:

    echo "Installing Lua"
    export LUA_VER=5.4
    export LUA_LONG_VER=$LUA_VER.6
    sudo apt install -y liblua$LUA_VER-dev liblua$LUA_VER-0-dbg liblua$LUA_VER-0
    curl -R -O http://www.lua.org/ftp/lua-$LUA_LONG_VER.tar.gz
    tar -zxf lua-$LUA_LONG_VER.tar.gz
    cd lua-$LUA_LONG_VER
    make linux test
    sudo make install
    cd ..
    sudo rm -r lua-$LUA_LONG_VER.tar.gz lua-$LUA_LONG_VER
    echo "Lua Installed"
    
    echo "Installing LuaRocks"
    export LUAROCKS_VER=3.9.2
    wget https://luarocks.org/releases/luarocks-$LUAROCKS_VER.tar.gz
    sudo mkdir -p /root/.luarocks/share/lua/$LUA_VER/luarocks/cmd/external
    mkdir -p /home/gabri/.luarocks
    touch /home/gabri/.luarocks/config-$LUA_VER.lua
    tar zxpf luarocks-$LUAROCKS_VER.tar.gz
    cd luarocks-$LUAROCKS_VER
    ./configure; sudo make bootstrap
    sudo luarocks config --scope system lua_version $LUA_VER
    cd ..
    sudo rm -r luarocks-$LUAROCKS_VER.tar.gz luarocks-$LUAROCKS_VER
    echo "LuaRocks Installed"
