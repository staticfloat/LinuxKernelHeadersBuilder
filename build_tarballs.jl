using BinaryBuilder

name = "LinuxKernelHeaders"
version = v"4.12"

# sources to build, such as glibc, linux kernel headers, our patches, etc....
sources = [
	"https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.12.tar.xz" =>
	"a45c3becd4d08ce411c14628a949d08e2433d8cdeca92036c7013980e93858ab",
]

# Bash recipe for building across all platforms
script = raw"""
## Function to take in a target such as `aarch64-linux-gnu`` and spit out a
## linux kernel arch like "arm64".
target_to_linux_arch()
{
    case "$1" in
        arm*)
            echo "arm"
            ;;
        aarch64*)
            echo "arm64"
            ;;
        powerpc*)
            echo "powerpc"
            ;;
        i686*)
            echo "x86"
            ;;
        x86*)
            echo "x86"
            ;;
    esac
}

## sysroot is where most of this stuff gets plopped
sysroot=${prefix}/${target}/sys-root

# First, install kernel headers
cd $WORKSPACE/srcdir/linux-*/

# The kernel make system can't deail
KERNEL_FLAGS="ARCH=\\\"$(target_to_linux_arch ${target})\\\" CROSS_COMPILE=\\\"/opt/${target}/bin/${target}-\\\" HOSTCC=\\\"${HOSTCC}\\\""
echo $KERNEL_FLAGS

eval make ${KERNEL_FLAGS} mrproper V=1
eval make ${KERNEL_FLAGS} headers_check V=1
eval make ${KERNEL_FLAGS} INSTALL_HDR_PATH=${sysroot}/usr V=1 headers_install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p)]

# The products that we will ensure are always built
products(prefix) = [
    FileProduct(prefix, "\${target}/sys-root/usr/include/linux/types.h", :types_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
