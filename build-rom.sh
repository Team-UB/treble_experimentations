#!/bin/bash

rom_fp="$(date +%y%m%d)"
originFolder="$(dirname "$0")"
mkdir -p release/$rom_fp/
set -e

if [ "$#" -le 1 ];then
	echo "Usage: $0 <android-9.0> <carbon|lineage|rr|tub> '# of jobs'"
	exit 0
fi
localManifestBranch=$1
rom=$2

if [ "$release" == true ];then
    [ -z "$version" ] && exit 1
    [ ! -f "$originFolder/release/config.ini" ] && exit 1
fi

if [ -z "$USER" ];then
	export USER="$(id -un)"
fi
export LC_ALL=C

if [[ -n "$3" ]];then
	jobs=$3
else
    if [[ $(uname -s) = "Darwin" ]];then
        jobs=$(sysctl -n hw.ncpu)
    elif [[ $(uname -s) = "Linux" ]];then
        jobs=$(nproc)
    fi
fi

#We don't want to replace from AOSP since we'll be applying patches by hand
rm -f .repo/local_manifests/replace.xml
if [ "$rom" == "carbon" ];then
	repo init -u https://github.com/CarbonROM/android -b cr-6.1
elif [ "$rom" == "lineage" ];then
	repo init -u https://github.com/LineageOS/android.git -b lineage-16.0
elif [ "$rom" == "rr" ];then
	repo init -u https://github.com/ResurrectionRemix/platform_manifest.git -b oreo
elif [ "$rom" == "tub" ];then
	repo init -u https://github.com/Team-UB/android.git -b TUB-Pie --depth=1
fi

if [ -d .repo/local_manifests ] ;then
	( cd .repo/local_manifests; git fetch; git checkout origin/TUB-Pie)
else
	git clone https://github.com/team-ub/treble_manifest .repo/local_manifests -b TUB-Pie
fi

if [ -z "$local_patches" ];then
    if [ -d patches ];then
        ( cd patches; git fetch; git reset --hard; git checkout origin/$localManifestBranch)
    else
        git clone https://github.com/Team-UB/treble_patches patches -b TUB-Pie
    fi
else
    rm -Rf patches
    mkdir patches
    unzip  "$local_patches" -d patches
fi

#We don't want to replace from AOSP since we'll be applying patches by hand
rm -f .repo/local_manifests/replace.xml

repo sync -c -j52 --force-sync
rm -f device/*/sepolicy/common/private/genfs_contexts
(cd device/phh/treble; bash generate.sh $rom)

sed -i -e 's/BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3000000000/BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3000000000/g' device/phh/treble/phhgsi_arm64_a/BoardConfig.mk

if [ -f vendor/rr/prebuilt/common/Android.mk ];then
    sed -i \
        -e 's/LOCAL_MODULE := Wallpapers/LOCAL_MODULE := WallpapersRR/g' \
        vendor/rr/prebuilt/common/Android.mk
fi

bash "$(dirname "$0")/apply-patches.sh" patches

. build/envsetup.sh

buildVariant() {
	lunch $1
	make WITHOUT_CHECK_API=true BUILD_NUMBER=$rom_fp installclean
	make WITHOUT_CHECK_API=true BUILD_NUMBER=$rom_fp -j$jobs systemimage
	make WITHOUT_CHECK_API=true BUILD_NUMBER=$rom_fp vndk-test-sepolicy
	#xz -c $OUT/system.img > release/$rom_fp/system-${2}.img.xz
}

repo manifest -r > release/$rom_fp/manifest.xml
buildVariant treble_arm64_agN-userdebug arm64-aonly-gapps

if [ "$release" == true ];then
    (
        rm -Rf venv
        pip install virtualenv
        export PATH=$PATH:~/.local/bin/
        virtualenv -p /usr/bin/python3 venv
        source venv/bin/activate
        pip install -r $originFolder/release/requirements.txt

        python $originFolder/release/push.py "${rom^}" "$version" release/$rom_fp/
        rm -Rf venv
    )
fi
