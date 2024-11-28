$target_os = $args[0]
$target_cpu = $args[1]
# $install_dir = $args[2]

if ($is_win_family) {
    if ($rebuild) {
        git clean -d -fx
    }
    Push-Location 'src'
    .\msvcbuild.bat
    Pop-Location
}
else {
    # config
    $CONFIG_TARGET = $null
    if ($Global:is_android) {
        $is_32bit_target = $target_cpu -eq 'armv7' -or $target_cpu -eq 'x86'
        if ($is_32bit_target) {
            if ($IsLinux) {
                sudo apt update
                sudo apt install gcc-multilib --fix-missing
            }
        }
        $NDKBIN = $env:ANDROID_NDK_BIN
        $cross_toolchain = @{
            arm64 = 'aarch64-linux-android'; 
            x64   = 'x86_64-linux-android'; 
            armv7 = 'armv7a-linux-androideabi'; 
            x86   = 'i686-linux-android'
        }[$target_cpu]

        $NDKCROSS = "$NDKBIN/$cross_toolchain-"
        $NDKCC = "$NDKBIN/$cross_toolchain$android_api_level-clang" 

        $HOST_CC = @('gcc', 'gcc -m32')[$is_32bit_target]
        # create symlink for cross commands: 'ar' and 'strip' used by luajit makefile
        if ( !(Test-Path "${NDKCROSS}ar" -PathType Leaf)) {
            ln $NDKBIN/llvm-ar ${NDKCROSS}ar
        }
        if ( !(Test-Path "${NDKCROSS}strip" -PathType Leaf) ) {
            ln $NDKBIN/llvm-strip ${NDKCROSS}strip
        }
        $CONFIG_TARGET = @("HOST_CC=$HOST_CC", "CROSS=$NDKCROSS", "STATIC_CC=$NDKCC", "DYNAMIC_CC=$NDKCC -fPIC", "TARGET_LD=$NDKCC", "TARGET_SYS=`"Linux`"")
    }
    elseif ($is_darwin_family) {
        if ($Global:is_mac) {
            $env:MACOSX_DEPLOYMENT_TARGET = $Global:target_minsdk
        } else {
            $env:MACOSX_DEPLOYMENT_TARGET = ''
        }
        # regard ios,tvos x64 as simulator
        $SDK_NAME = $(xcode_get_sdkname $XCODE_VERSION $target_os $Global:is_ios_sim)
        println "SDK_NAME=$SDK_NAME"

        $luajit_target_cpu = $target_cpu
        if ($target_cpu -eq 'x64') { $luajit_target_cpu = 'x86_64' }

        $HOST_CC = "gcc -std=c99"
        $XCFLAGS = "-DLJ_NO_SYSTEM=1"
        $ISDKP = $(xcrun --sdk $SDK_NAME --show-sdk-path)
        $ICC = $(xcrun --sdk $SDK_NAME --find clang)
        $ISDKF = "-arch $luajit_target_cpu -isysroot $ISDKP"
        $TARGET_SYS = if ($Global:is_mac) { 'Darwin' } else { 'iOS' }
        $CONFIG_TARGET = @('DEFAULT_CC=clang', "HOST_CC=$HOST_CC", "CROSS=$(dirname $ICC)/", "TARGET_FLAGS=$ISDKF", "TARGET_SYS=$TARGET_SYS", "XCFLAGS=$XCFLAGS", "LUAJIT_A=libluajit.a")
    }

    # build
    if ($CONFIG_TARGET) {
        if (!$IsWIn) {
            println "CONFIG_TARGET=$CONFIG_TARGET, Count=$($CONFIG_TARGET.Count)"
            make V=1 $CONFIG_TARGET
        }
        else {
            throw "Can't build luajit for $target_os on windows host machine"
        }
    }
    else {
        make V=1
    }
}
