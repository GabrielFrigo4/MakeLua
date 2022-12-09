# MakeLua
MakeLua is a installer lua in windows
 - to update luarocks version use: "sudo luarocks config --scope system lua_version 5.4"
 - to ser var in luarocks use: "luarocks config variables.VAR_NAME VAR_VALUE"

In linux to get all lua pkgs use this commands:

    echo "Installing Lua"
    wget http://ftp.br.debian.org/debian/pool/main/l/lua5.4/liblua5.4-0_5.4.4-3_amd64.deb
    wget http://ftp.br.debian.org/debian/pool/main/l/lua5.4/liblua5.4-dev_5.4.4-3_amd64.deb
    wget http://ftp.br.debian.org/debian/pool/main/l/lua5.4/lua5.4_5.4.4-3_amd64.deb
    wget http://ftp.br.debian.org/debian/pool/main/l/luarocks/luarocks_3.8.0+dfsg1-1_all.deb
    sudo dpkg -i liblua5.4-0_5.4.4-3_amd64.deb
    sudo dpkg -i liblua5.4-dev_5.4.4-3_amd64.deb
    sudo dpkg -i lua5.4_5.4.4-3_amd64.deb
    sudo dpkg -i luarocks_3.8.0+dfsg1-1_all.deb
    echo "Lua Installed"
