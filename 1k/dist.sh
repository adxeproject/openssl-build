DIST_REVISION=$1
DIST_SUFFIX=$2
DIST_LIBS=$3

DIST_NAME=buildware_dist

if [ "${DIST_REVISION}" != "" ]; then
    DIST_NAME="${DIST_NAME}_${DIST_REVISION}"
fi

if [ "${DIST_SUFFIX}" != "" ]; then
    DIST_NAME="${DIST_NAME}${DIST_SUFFIX}"
fi

DIST_ROOT=`pwd`/${DIST_NAME}
mkdir -p $DIST_ROOT

# compile copy1k for script, non-recursive simple wildchard without error support
mkdir -p build
g++ -std=c++17 1k/copy1k.cpp -o build/copy1k
PATH=`pwd`/build:$PATH

# The dist flags
DISTF_WIN=1
DISTF_LINUX=2
DISTF_ANDROID=4
DISTF_MAC=8
DISTF_IOS=16
DISTF_TVOS=32
DISTF_APPL=$(($DISTF_MAC|$DISTF_IOS|$DISTF_TVOS))
DISTF_NO_INC=1024
DISTF_ANY=$(($DISTF_WIN|$DISTF_LINUX|$DISTF_ANDROID|$DISTF_APPL))

function dist_lib {
    LIB_NAME=$1
    DIST_DIR=$2
    DIST_FLAGS=$3
    CONF_HEADER=$4 # [optional]
    CONF_TEMPLATE=$5 # [optional]
    INC_DIR=$6 # [optional] such as: openssl/

    if [ $(($DIST_FLAGS & $DISTF_NO_INC)) = 0 ]; then
        # mkdir for commen
        mkdir -p ${DIST_DIR}/include

        # mkdir for platform spec config header file
        if [ "$CONF_TEMPLATE" = "config.h.in" ] ; then
            mkdir -p ${DIST_DIR}/include/win32/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/win64/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/linux/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/mac/${INC_DIR}
            # mkdir -p ${DIST_DIR}/include/ios-arm/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/ios-arm64/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/ios-x64/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/tvos-arm64/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/tvos-x64/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/android-arm/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/android-arm64/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/android-x86/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/android-x86_64/${INC_DIR}
        elif [ "$CONF_TEMPLATE" = "config_ab.h.in" ] ; then
            mkdir -p ${DIST_DIR}/include/win32/${INC_DIR}
            mkdir -p ${DIST_DIR}/include/unix/${INC_DIR}
        fi

        # copy common headers
        cp -rf install_osx_x64/${LIB_NAME}/include/${INC_DIR} ${DIST_DIR}/include/${INC_DIR}

        if [ "$CONF_HEADER" != "" ] ; then
            rm -rf ${DIST_DIR}/include/${INC_DIR}${CONF_HEADER}

            CONF_CONTENT=$(cat 1k/$CONF_TEMPLATE)
            STYLED_LIB_NAME=${LIB_NAME//-/_}
            CONF_CONTENT=${CONF_CONTENT//@LIB_NAME@/$STYLED_LIB_NAME}
            CONF_CONTENT=${CONF_CONTENT//@INC_DIR@/$INC_DIR}
            CONF_CONTENT=${CONF_CONTENT//@CONF_HEADER@/$CONF_HEADER}
            echo "$CONF_CONTENT" >> ${DIST_DIR}/include/${INC_DIR}${CONF_HEADER}

            # copy platform spec config header file
            if [ "$CONF_TEMPLATE" = "config.h.in" ] ; then
                cp install_windows_x86/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/win32/${INC_DIR}
                cp install_windows_x64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/win64/${INC_DIR}
                cp install_linux_x64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/linux/${INC_DIR}
                cp install_osx_x64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/mac/${INC_DIR}
                # cp install_ios_arm/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/ios-arm/${INC_DIR}
                cp install_ios_arm64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/ios-arm64/${INC_DIR}
                cp install_ios_x64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/ios-x64/${INC_DIR}
                cp install_tvos_arm64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/tvos-arm64/${INC_DIR}
                cp install_tvos_x64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/tvos-x64/${INC_DIR}
                cp install_android_arm/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/android-arm/${INC_DIR}
                cp install_android_arm64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/android-arm64/${INC_DIR}
                cp install_android_x86/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/android-x86/${INC_DIR}
                cp install_android_x64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/android-x86_64/${INC_DIR}

            elif [ "$CONF_TEMPLATE" = "config_ab.h.in" ] ; then
                cp install_windows_x86/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/win32/${INC_DIR}
                cp install_linux_x64/${LIB_NAME}/include/${INC_DIR}${CONF_HEADER} ${DIST_DIR}/include/unix/${INC_DIR}
            fi
        fi
    fi

    # create prebuilt dirs
    if [ ! $(($DIST_FLAGS & $DISTF_WIN)) = 0 ]; then
        mkdir -p ${DIST_DIR}/prebuilt/windows/x86
        copy1k "install_windows_x86/${LIB_NAME}/lib/*.lib" ${DIST_DIR}/prebuilt/windows/x86/
        copy1k "install_windows_x86/${LIB_NAME}/bin/*.dll" ${DIST_DIR}/prebuilt/windows/x86/

        mkdir -p ${DIST_DIR}/prebuilt/windows/x64
        copy1k "install_windows_x64/${LIB_NAME}/lib/*.lib" ${DIST_DIR}/prebuilt/windows/x64/
        copy1k "install_windows_x64/${LIB_NAME}/bin/*.dll" ${DIST_DIR}/prebuilt/windows/x64/
    fi

    if [ ! $(($DIST_FLAGS & $DISTF_LINUX)) = 0 ]; then
        mkdir -p ${DIST_DIR}/prebuilt/linux/x64
        cp install_linux_x64/${LIB_NAME}/lib/*.a ${DIST_DIR}/prebuilt/linux/x64/
    fi

    if [ ! $(($DIST_FLAGS & $DISTF_ANDROID)) = 0 ]; then
        mkdir -p ${DIST_DIR}/prebuilt/android/armeabi-v7a
        mkdir -p ${DIST_DIR}/prebuilt/android/arm64-v8a
        mkdir -p ${DIST_DIR}/prebuilt/android/x86
        mkdir -p ${DIST_DIR}/prebuilt/android/x86_64
        cp install_android_arm/${LIB_NAME}/lib/*.a ${DIST_DIR}/prebuilt/android/armeabi-v7a/
        cp install_android_arm64/${LIB_NAME}/lib/*.a ${DIST_DIR}/prebuilt/android/arm64-v8a/
        cp install_android_x86/${LIB_NAME}/lib/*.a ${DIST_DIR}/prebuilt/android/x86/
        cp install_android_x64/${LIB_NAME}/lib/*.a ${DIST_DIR}/prebuilt/android/x86_64/
    fi

    if [ ! $(($DIST_FLAGS & $DISTF_MAC)) = 0 ]; then
        mkdir -p ${DIST_DIR}/prebuilt/mac
    fi

    if [ ! $(($DIST_FLAGS & $DISTF_IOS)) = 0 ]; then
        mkdir -p ${DIST_DIR}/prebuilt/ios
    fi

    if [ ! $(($DIST_FLAGS & $DISTF_TVOS)) = 0 ]; then
        mkdir -p ${DIST_DIR}/prebuilt/tvos
    fi
}

# dist libs
if [ "$DIST_LIBS" = "" ] ; then
    DIST_LIBS="zlib,jpeg-turbo,openssl,curl,luajit,angle,glsl-optimizer"
fi

libs_arr=(${DIST_LIBS//,/ })
libs_count=${#libs_arr[@]}
echo "Dist $libs_count libs ..."
for (( i=0; i<${libs_count}; ++i )); do
  source src/${libs_arr[$i]}/dist1.sh ${libs_arr[$i]} $DIST_ROOT
done

# create dist package
DIST_PACKAGE=${DIST_NAME}.zip
zip -q -r ${DIST_PACKAGE} ${DIST_NAME}

# Export DIST_NAME & DIST_PACKAGE for uploading
if [ "$GITHUB_ENV" != "" ] ; then
    echo "DIST_NAME=$DIST_NAME" >> $GITHUB_ENV
    echo "DIST_PACKAGE=${DIST_PACKAGE}" >> $GITHUB_ENV
fi
