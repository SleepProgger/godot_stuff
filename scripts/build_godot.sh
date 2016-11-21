#!/bin/bash

#
# TODO:
#	- --help
#	- backup old files (template +  bin ?)
#	- colors
#	- all export templates
#		- Check for android tools and exit if not available.
#		- android arches (x86, armv6 ?)
#	- use arguments for more stuff
#	- check errors
#	- add --help
#

#
# Pathes
#
BUILD_PATH=~/.bin/GodotEngine/
EMSDK_PATH="$BUILD_PATH/emscripten"
TMP_PATH="/tmp/godot_build"
ANDROID_SDK_PATH="/home/nope/Android/Sdk/"
ANDROID_NDK_PATH="/home/nope/Android/Sdk/ndk-bundle"
# Path to move the executables to after testing them.
# This way if something broke we still have the last good executables.
EXPORT_PATH="$BUILD_PATH/current_build"


#
# Export template stuff
#
UPDATE_EMSDK=0
# Move new templates to ~/.godot/templates ?
MOVE_TEMPLATES=0
BUILD_EXPORTER_JS=0
BUILD_EXPORTER_JS_DEBUG=0
BUILD_EXPORTER_X11_64=1
BUILD_EXPORTER_X11_64_DEBUG=1
# Not supported atm.
BUILD_EXPORTER_X11_32=0
# Not supported atm.
BUILD_EXPORTER_X11_32_DEBUG=0
BUILD_EXPORTER_ANDROID=0
BUILD_EXPORTER_ANDROID_DEBUG=0
# TODO: other platforms

JS_SCONS_ARGS="vorbis=no opus=no theora=no speex=no webp=no openssl=no freetype=no webm=no musepack=no disable_3d=yes disable_advanced_gui=yes module_enet_enabled=no"
# TODO: other platforms



#
# Stuff
#
# BUILD_MODE: Can be:
#	- git  		Download new $GIT_BRANCH and rebuild
#	- build		Only (re)build (Usefull for modules and core changes)
#	- templates	Only (re)build export templates ( if set to 1 on the top of this file )
#	- run		Run editor from bin folder
#	- export	Move executables to EXPORT_PATH. Also move export templates to ~/.godot/templates
BUILD_MODE="git"
GIT_BRANCH="master"
CORES=4
ARCH=`uname -m` # TODO: do we need this ?

#
# Logging stuff
#
USE_LOG_FILE=1
LOG_FILE=/tmp/godot_build.log
LVL_INFO=0
LVL_WARN=1
LVL_ERROR=2
LOG_LEVEL=$LVL_ERROR
info() {
	if [[ $LOG_LEVEL -lt $LVL_WARN ]]; then
		echo $*
	fi
}
warn() {
	if [[ $LOG_LEVEL -lt $LVL_ERROR ]]; then
		echo $*
	fi
}
error() {
	echo $*
}


build_template_js() {
	cd "$BUILD_PATH"
	if [[ $BUILD_EXPORTER_JS == 1 ]] || [[ $BUILD_EXPORTER_JS_DEBUG == 1 ]]; then
		if [[ ! -d $EMSDK_PATH ]]; then
			if [[ $UPDATE_EMSDK != 1 ]]; then			
				error "EMSDK path is invalid. Can't build javascript export template."
				error "Set UPDATE_EMSDK to 1 to automatically download it."
				exit 2
			fi
			info "Downloading EMSDK"
			mkdir -p "$EMSDK_PATH"
			cd "$EMSDK_PATH"
			wget https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz
			info "Unpacking EMSDK"
			tar -xzf emsdk-portable.tar.gz
		fi
		# Find correct subfolder. A bit dirty but okish
		emsdk_path=$(find "$EMSDK_PATH" -name emsdk_env.sh)
		if [[ $emsdk_path == "" ]]; then
			error "Invalid EMSDK_PATH. Can't build javascript export template."
			exit 2
		fi
		emsdk_path=$(dirname $emsdk_path)
		if [[ $UPDATE_EMSDK == 1 ]]; then
			info "Update emscripten"
			cd "$emsdk_path"
			./emsdk update
			./emsdk install latest
			./emsdk activate latest
		fi
		info "Source emsdk_env"
		source "$emsdk_path/emsdk_env.sh"
		export EMSCRIPTEN_ROOT="$EMSCRIPTEN"
		cd ${BUILD_PATH}/build-git
		if [[ $BUILD_EXPORTER_JS == 1 ]]; then
			info "Building JavaScript export template"
			scons -j $CORES p=javascript tools=no target=release $JS_SCONS_ARGS
			rm -r "$TMP_PATH" 2>/dev/null; mkdir "$TMP_PATH"
			cp bin/godot.javascript.opt.js "$TMP_PATH/godot.js"
			cp bin/godot.javascript.opt.html.mem "$TMP_PATH/godot.mem"
			cp tools/dist/html_fs/godot.html "$TMP_PATH/godot.html"
			cp tools/dist/html_fs/godotfs.js "$TMP_PATH/godotfs.js"
			zip -j javascript_release.zip $TMP_PATH/*
			mv javascript_release.zip templates/
		fi
		if [[ $BUILD_EXPORTER_JS_DEBUG == 1 ]]; then
			info "Building JavaScript debug export template"
			scons -j $CORES p=javascript tools=no target=release_debug $JS_SCONS_ARGS
			rm -r "$TMP_PATH" 2>/dev/null; mkdir "$TMP_PATH"
			cp bin/godot.javascript.opt.debug.js "$TMP_PATH/godot.js"
			cp bin/godot.javascript.opt.debug.html.mem "$TMP_PATH/godot.mem"
			cp tools/dist/html_fs/godot.html "$TMP_PATH/godot.html"
			cp tools/dist/html_fs/godotfs.js "$TMP_PATH/godotfs.js"
			zip -j javascript_debug.zip $TMP_PATH/*
			mv javascript_debug.zip templates/
		fi
	fi
}


build_templates() {
	cd "$BUILD_PATH/build-git"
	mkdir templates 2>/dev/null
	build_template_js
	cd "$BUILD_PATH/build-git"
	if [[ $BUILD_EXPORTER_X11_64 == 1 ]]; then
		info "Building linux export templates x64."
		scons -j $CORES p=x11 target=release tools=no bits=64
		cp bin/godot.x11.opt.64 templates/linux_x11_64_release
	fi
	if [[ $BUILD_EXPORTER_X11_64_DEBUG == 1 ]]; then
		info "Building linux export templates x64 debug mode."
		scons -j $CORES p=x11 target=release_debug tools=no bits=64
		cp bin/godot.x11.opt.debug.64 templates/linux_x11_64_debug
	fi
	if [[ $BUILD_EXPORTER_ANDROID == 1 ]]; then
		cd "$BUILD_PATH/build-git"
		export ANDROID_HOME="$ANDROID_SDK_PATH"
		export ANDROID_NDK_ROOT="$ANDROID_NDK_PATH"
		info "Building android export templates."
		scons -j $CORES platform=android target=release
		cd platform/android/java
		./gradlew build
		cd "$BUILD_PATH/build-git/"
		cp bin/android_release.apk templates/
	fi
	if [[ $BUILD_EXPORTER_ANDROID == 1 ]]; then
		cd "$BUILD_PATH/build-git"
		export ANDROID_HOME="$ANDROID_SDK_PATH"
		export ANDROID_NDK_ROOT="$ANDROID_NDK_PATH"
		info "Building android export templates debug."
		scons -j $CORES platform=android target=release_debug
		cd platform/android/java
		./gradlew build
		cd "$BUILD_PATH/build-git/"
		cp bin/android_debug.apk templates/
	fi

	# TODO: 32 bit
	# TODO: move to ~/.godot/templates if flag is set. Also handle backup
}


build() {
	cd "$BUILD_PATH"
	cd build-git
	info "Build editor"
	# Does this need the arch ?
	scons -j $CORES platform=x11 tools=yes
	build_templates
}


git_build() {
	cd "$BUILD_PATH"
	if [[ ! -d build-git ]]; then
		# TODO: use new url (is redirect but still..)
		git clone https://github.com/okamstudio/godot.git build-git
		cd build-git
	else
		cd build-git
		git pull	
	fi
	git checkout "$GIT_BRANCH"
	build
	# TODO: move editor executable somewhere else and backup old ?
}


# Parse arguments
# TODO: add more arguments to set all the flags
while [[ $# > 0 ]]; do
	key=$1
	case $key in
		-v|--verbose)
			let LOG_LEVEL=$LOG_LEVEL-1
			shift
		;;
		-l|--log)
			USE_LOG_FILE=1
			shift
		;;
		*)
			break
		;;
	esac
done

if [[ $USE_LOG_FILE == 1 ]]; then
	# We want log and output to stdout
	exec > >(tee -i $LOG_FILE)
	exec 2>&1
fi

if [[ $# > 0 ]]; then
	BUILD_MODE=$1
fi
mkdir -p $BUILD_PATH 2>/dev/null
case $BUILD_MODE in
	g*) # git
		git_build
	;;
	b*) # build
		build
	;;
	t*) # templates
		build_templates
	;;
	r*) # run
		# TODO: TODO: use new build templates ?
		$BUILD_PATH/build-git/bin/godot.x11.tools.* -e # yeah too lazy to check for arch
	;;
	e*) # export
		# TODO: backup old templates
		cp "${BUILD_PATH}/build-git/templates/"* ~/.godot/templates/
		# TODO: should we clear the EXPORT_PATH dir ?
		mkdir -p $EXPORT_PATH 2>/dev/null
		cp "$BUILD_PATH/build-git/bin/"* "$EXPORT_PATH/"
	;;
	*)
		error "Invalid build mode supplied"
		exit 1
	;;
esac
