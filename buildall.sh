# build imagebuilder with all packages for a given platform
REMOTE=git://git.openwrt.org/openwrt.git
TARGET=ar71xx
#TARGET=x86
# TARGET=ramips

# in case of oxnas, also use oxnas remote site
# REMOTE=git://gitorious.org/openwrt-oxnas/openwrt-oxnas.git
# TARGET=oxnas

# MAKEOPTS="-j4"

# fail on errors
set +e

git clone $REMOTE openwrt
cd openwrt
rm -rf feeds/routing*
cp feeds.conf.default feeds.conf
echo "src-git luci2 http://git.openwrt.org/project/luci2/ui.git" >> feeds.conf
echo "src-git cjdns git://github.com/lgierth/cjdns-openwrt.git" >> feeds.conf
echo "src-git lff git://git.metameute.de/lff/pkg_fastd" >> feeds.conf
scripts/feeds update -a

# revert to batman-adv 2013.4.0
cd feeds/routing
git remote add github-routing git://github.com/openwrt-routing/packages.git
git fetch github-routing
git checkout -b batman-adv-backport
rm -r batman-adv
git checkout 89c2a8bb562412281d1ff070007be16d5a4d8f55 batman-adv
git commit -a -m "batman-adv: revert to 2013.4.0"
rm -r alfred
git checkout e2cfab7f287673b1d6854c59db6e710668d145f3 alfred
git commit -a -m "alread: revert to 2013.4.0"
cd ../..

# create index and install all packages
scripts/feeds update -i
scripts/feeds install -a

# create default config for given platform
cat >.config <<EOF
CONFIG_MODULES=y
CONFIG_HAVE_DOT_CONFIG=y
CONFIG_TARGET_${TARGET}=y
# CONFIG_TARGET_ROOTFS_EXT4FS is not set
# CONFIG_TARGET_ROOTFS_JFFS2 is not set
CONFIG_TARGET_ROOTFS_SQUASHFS=y
# CONFIG_TARGET_ROOTFS_INCLUDE_UIMAGE is not set
# CONFIG_TARGET_ROOTFS_INCLUDE_ZIMAGE is not set
CONFIG_ALL=y
CONFIG_IB=y
CONFIG_COLLECT_KERNEL_DEBUG=y
CONFIG_BUILD_PATENTED=y
CONFIG_KERNEL_KALLSYMS=y
CONFIG_KERNEL_DEBUG_KERNEL=y
CONFIG_KERNEL_DEBUG_INFO=y
CONFIG_ATH_USER_REGD=y
EOF

make defconfig

# allow stuff to fail from here on
set -e

# make everything
#make $MAKEOPTS IGNORE_ERRORS=m V=99 BUILD_LOG=1
