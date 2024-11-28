$target_os = $args[0]
$target_cpu = $args[1]
$install_dir = $args[2]

$CONFIG_ALL_OPTIONS = $build_conf.options
$TARGET_OPTIONS = @()


$env:CFLAGS = $null
$env:LDFLAGS = $null
$env:CC = $null
$env:CXX = $null

if ($target_os.StartsWith('win')) {
    # require preinstalled perl interpreter: https://strawberryperl.com/releases.html
    if ($target_cpu -eq "x86") {
        if (!$is_winrt) {
            $TARGET_OPTIONS += 'VC-WIN32'
        }
        else {
            $TARGET_OPTIONS += 'VC-WIN32-UWP'
        }
    }
    else {
        if (!$is_winrt) {
            $TARGET_OPTIONS += 'VC-WIN64A'
        }
        else {
            if ($target_cpu -eq 'x64') {
                $TARGET_OPTIONS += 'VC-WIN64A-UWP'
            }
            elseif ($target_cpu -eq 'arm64') {
                $TARGET_OPTIONS += 'VC-WIN64-ARM-UWP'
            }
            else {
                Write-Output "Unsupported arch: $target_cpu"
                return 1
            }
        }
    }

    if ($env:NO_DLL -eq 'true') {
        $CONFIG_ALL_OPTIONS += "no-shared"
    }
}
else {
    $ossl_target_cpu = if ($target_cpu -eq 'x64') { 'x86_64' } else { $target_cpu }
    
    # Export OPENSSL_LOCAL_CONFIG_DIR for perl script file 'openssl/Configure' 
    $env:OPENSSL_LOCAL_CONFIG_DIR = Join-Path $_1k_root '1k'

    if ($Global:is_mac) {
        $TARGET_OPTIONS += "darwin64-$ossl_target_cpu-cc"
        if ($Global:target_minsdk) {
            $TARGET_OPTIONS += "-mmacosx-version-min=$Global:target_minsdk"
        }
    }
    elseif ($Global:is_ios -or $Global:is_tvos) {
        $ossl_target_os = "$target_os-"
        $ios_plat_suffix = 'OS'
        if ($Global:is_ios_sim) {
            # asume x64 as simulator
            $ossl_target_os += 'sim-'
            $ios_plat_suffix = 'Simulator'
            if ($target_cpu -eq 'arm64') {
                $TARGET_OPTIONS += 'no-asm'
            }
        }
        $ossl_target_os += "cross-$ossl_target_cpu"
        $TARGET_OPTIONS += $ossl_target_os

        $IOS_PLAT = if ($Global:is_ios) { "iPhone${ios_plat_suffix}" } else { "AppleTV${ios_plat_suffix}" }
        
        $env:CROSS_TOP = "$(xcode-select -print-path)/Platforms/$IOS_PLAT.platform/Developer"
        $env:CROSS_SDK = "$IOS_PLAT.sdk"
    }
    elseif ($Global:is_android) {
        if ($ossl_target_cpu.EndsWith('v7')) { $ossl_target_cpu = $ossl_target_cpu.TrimEnd('v7') }
        $TARGET_OPTIONS += "android-$ossl_target_cpu"
        $TARGET_OPTIONS += "-D__ANDROID_API__=$android_api_level"
        if ( $target_cpu -eq "x86" ) {
            $TARGET_OPTIONS += '-latomic'
        }
    }
    elseif ($Global:is_wasm) {
        $env:CFLAGS = '-pthread -O3'
        $env:LDFLAGS = "-sFILESYSTEM=1 -sINVOKE_RUN=0 -sUSE_ES6_IMPORT_META=0 -pthread"
        $env:CC = 'emcc'
        $env:CXX = 'emcc'
        if ($target_os.EndsWith('wasm64')) {
            $env:CFLAGS = "$env:CFLAGS -sMEMORY64 -Wno-experimental"
            $env:LDFLAGS = "$env:LDFLAGS -sMEMORY64" # may don't require
        }
    }
}

$CONFIG_ALL_OPTIONS += $TARGET_OPTIONS
$CONFIG_ALL_OPTIONS += "--prefix=$install_dir", "--openssldir=$install_dir"
Write-Host ("CONFIG_ALL_OPTIONS=$CONFIG_ALL_OPTIONS, Count={0}" -f $CONFIG_ALL_OPTIONS.Count)

if ($target_os.StartsWith('win')) {
    perl Configure $CONFIG_ALL_OPTIONS
    perl configdata.pm --dump
    nmake install_sw
}
else {
    if ($target_os -ne 'wasm') {
        if (!(Test-Path Makefile -PathType Leaf)) {
            if ( $target_os -eq "linux" ) {
                ./config $CONFIG_ALL_OPTIONS && perl configdata.pm --dump
            }
            else {
                ./Configure $CONFIG_ALL_OPTIONS && perl configdata.pm --dump
            }
        }
        make VERBOSE=1
        make install_sw
    }
    else {
        if (!(Test-Path Makefile -PathType Leaf)) {
            emconfigure ./Configure $CONFIG_ALL_OPTIONS
        }
        perl configdata.pm --dump
        # remove incorrect use of CROSS_COMPILE
        sed -i 's/$(CROSS_COMPILE)//' Makefile
        emmake make VERBOSE=1
        emmake make install_sw
    }
}

