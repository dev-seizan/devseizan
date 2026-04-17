#!/bin/bash

# DevSeizan Debian Package Builder
# https://github.com/dev-seizan/devseizan

_PACKAGE=devseizan
_VERSION=1.0.0
_ARCH="all"
PKG_NAME="${_PACKAGE}_${_VERSION}_${_ARCH}.deb"

if [[ ! -e "launch.sh" ]]; then
    echo "launch.sh not found in root directory. Exiting..."
    exit 1
fi

if [[ ${1,,} == "termux" || $(uname -o) == *'Android'* ]]; then
    _depend="ncurses-utils, proot, resolv-conf, "
    _bin_dir="data/data/com.termux/files/"
    _opt_dir="data/data/com.termux/files/usr/"
fi

_depend+="curl, php, unzip"
_bin_dir+="usr/bin"
_opt_dir+="opt/${_PACKAGE}"

# Clean build
rm -rf build_env
mkdir -p build_env/${_bin_dir} build_env/${_opt_dir} build_env/DEBIAN

# Control file
cat > build_env/DEBIAN/control << EOF
Package: ${_PACKAGE}
Version: ${_VERSION}
Architecture: ${_ARCH}
Maintainer: DevSeizan Team
Depends: ${_depend}
Homepage: https://github.com/devseizan/devseizan
Description: Automated phishing tool for educational purposes only.
EOF

# Pre-remove script
cat > build_env/DEBIAN/prerm << EOF
#!/bin/bash
rm -rf ${_opt_dir}
exit 0
EOF

chmod 755 build_env/DEBIAN build_env/DEBIAN/{control,prerm}

# Copy files - MODIFIED: only .sites/ folder, no separate post.php/ip.php
cp -f launch.sh build_env/${_bin_dir}/${_PACKAGE}
chmod 755 build_env/${_bin_dir}/${_PACKAGE}

# Copy everything to opt directory
cp -fr .sites/ devseizan.sh launch.sh Dockerfile docker-launch.sh make-deb.sh build_env/${_opt_dir}

# Build package
dpkg-deb --build build_env "${PKG_NAME}"
rm -rf build_env

echo "Package created: ${PKG_NAME}"