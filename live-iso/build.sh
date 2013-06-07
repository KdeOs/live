#!/bin/bash

if [ ! -e options.conf ] ; then
    echo " "
    echo "the config file options.conf is missing, exiting..."
    echo " "
    exit
fi

if [ ! -e /usr/share/liveiso/functions/colors ] || [ ! -e /usr/share/liveiso/functions/messages ] ; then
    echo " "
    echo "missing live functions file, please run «sudo make install» inside live-iso/"
    echo " "
    exit
fi

source /usr/share/liveiso/functions/colors
.  /usr/share/liveiso/functions/messages
. options.conf

# do UID checking here so someone can at least get usage instructions
if [ "$EUID" != "0" ]; then
    echo "error: This script must be run as root."
    exit 1
fi

banner

if [ -z "${arch}" ] ; then
    arch=$(pacman -Qi bash | grep "Architecture" | cut -d " " -f 5)
    echo " "
    msg  "architecture not supplied, defaulting to host's architecture: ${arch}"
fi


if [ ! -e overlay-pkgs.${arch} ] ; then
    echo " "
    error "the config file overlay-pkgs.${arch} is missing, exiting..."
    echo " "
    exit
fi

set -e -u

pwd=`pwd`
packages=`sed -e 's/\#.*//' -e 's/[ ^I]*$$//' -e '/^$$/ d' packages.${arch}`

export LANG=C
export LC_MESSAGES=C

# Base installation (root-image)
make_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
         echo -e -n "$_r >$_W Base installation (root-image) \n $_n"
         mkliveiso -v -C pacman.conf -a "${arch}" -D "${install_dir}" -p "${packages}" create "${work_dir}"
         pacman -Qr "${work_dir}/root-image" > "${work_dir}/root-image/root-image-pkgs.txt"
         cp ${work_dir}/root-image/etc/locale.gen.bak ${work_dir}/root-image/etc/locale.gen
         : > ${work_dir}/build.${FUNCNAME}
         echo -e "$_g >$_W done $_n"
    fi
}

# Prepare ${install_dir}/boot/
#make_boot() {
#    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
#	echo -e -n "$_r >$_W Prepare ${install_dir}/boot/ \n $_n"
#	mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
#	cp ${work_dir}/root-image/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/${arch}/liveiso
#	cp -Lr boot-files/isolinux ${work_dir}/iso/
#	cp ${work_dir}/root-image/usr/lib/syslinux/isolinux.bin ${work_dir}/iso/isolinux/
#	cp /usr/lib/initcpio/hooks/live* ${work_dir}/root-image/usr/lib/initcpio/hooks
#	mkinitcpio -c ./mkinitcpio.conf -g ${work_dir}/root-image -k $_kernver -g ${work_dir}/iso/${install_dir}/boot/${arch}/liveiso.img
#	rm ${work_dir}/root-image/usr/lib/initcpio/hooks/live*
#	: > ${work_dir}/build.${FUNCNAME}
#	echo -e "$_g >$_W done $_n"
#    fi
#}

make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
	echo -e -n "$_r >$_W Prepare ${install_dir}/boot/ \n $_n"
	mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
        #cp ${work_dir}/root-image/boot/memtest86+/memtest.bin ${work_dir}/iso/${install_dir}/boot/${arch}/memtest
	cp ${work_dir}/root-image/boot/vmlinuz* ${work_dir}/iso/${install_dir}/boot/${arch}/liveiso
	cp -Lr boot-files/isolinux ${work_dir}/iso/
	cp ${work_dir}/root-image/usr/lib/syslinux/isolinux.bin ${work_dir}/iso/isolinux/
        mkdir -p ${work_dir}/boot-image
        if [ "`mount -l | grep ${work_dir}/boot-image`" != "" ]; then
           umount -f ${work_dir}/boot-image/proc ${work_dir}/boot-image/sys ${work_dir}/boot-image/dev ${work_dir}/boot-image
        fi
        mount -t aufs -o br=${work_dir}/boot-image:${work_dir}/root-image=ro none ${work_dir}/boot-image
        mount -t proc none ${work_dir}/boot-image/proc
        mount -t sysfs none ${work_dir}/boot-image/sys
        mount -o bind /dev ${work_dir}/boot-image/dev
        cp /usr/lib/initcpio/hooks/live* ${work_dir}/boot-image/usr/lib/initcpio/hooks
        cp /usr/lib/initcpio/install/live* ${work_dir}/boot-image/usr/lib/initcpio/install
        cp mkinitcpio.conf ${work_dir}/boot-image/etc/mkinitcpio.conf
        _kernver=`cat ${work_dir}/boot-image/lib/modules/*/version`
        chroot ${work_dir}/boot-image /usr/bin/mkinitcpio -k ${_kernver} -c /etc/mkinitcpio.conf -g /boot/liveiso.img
        mv ${work_dir}/boot-image/boot/liveiso.img ${work_dir}/iso/${install_dir}/boot/${arch}/liveiso.img
        umount -f ${work_dir}/boot-image/proc ${work_dir}/boot-image/sys ${work_dir}/boot-image/dev ${work_dir}/boot-image
        rm -R ${work_dir}/boot-image
	: > ${work_dir}/build.${FUNCNAME}
	echo -e "$_g >$_W done $_n"
    fi
}

# Prepare overlay-image
make_overlay() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        echo -e -n "$_r >$_W Prepare overlay-image \n $_n"
        mkdir -p ${work_dir}/overlay/etc/pacman.d
        cp -Lr overlay ${work_dir}/
        wget -O ${work_dir}/overlay/etc/pacman.d/mirrorlist http://github.com/KdeOs/core/raw/master/pacman-mirrorlist/mirrorlist
        sed -i "s/#Server/Server/g" ${work_dir}/overlay/etc/pacman.d/mirrorlist
        sed -i -e "s/@carch@/${arch}/g" ${work_dir}/overlay/etc/pacman.d/mirrorlist
       
        # locales generation
        cp ${work_dir}/overlay/etc/locale.gen ${work_dir}/root-image/etc
        mkdir -p ${work_dir}/overlay/usr/lib/locale/
        if [ -f "${locale_archive}/locale-archive" ] ; then
	    echo -e -n "$_r >$_W You have specified an existing locale-archive data file, skipping locale-gen \n $_n"
	    cp "${locale_archive}/locale-archive" ${work_dir}/root-image/usr/lib/locale/locale-archive
	    chmod 644 ${work_dir}/root-image/usr/lib/locale/locale-archive
	else
	    echo -e -n "$_r >$_W Generating  locales \n $_n"
	    chroot "${work_dir}/root-image" locale-gen
	    cp ${work_dir}/root-image/etc/locale.gen.bak ${work_dir}/root-image/etc/locale.gen
	fi
        mv ${work_dir}/root-image/usr/lib/locale/locale-archive ${work_dir}/overlay/usr/lib/locale/
        
        chmod -R 755 ${work_dir}/overlay/home
        : > ${work_dir}/build.${FUNCNAME}
        echo -e "$_g >$_W done $_n"
    fi
}

# Prepare overlay-pkgs-image
make_overlay_pkgs() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        echo -e -n "$_r >$_W Prepare overlay-pkgs-image \n $_n"
        overlay-pkgs ${arch} ${work_dir}
        : > ${work_dir}/build.${FUNCNAME}
        echo -e "$_g >$_W done $_n"
    fi
}

# Process isomounts
make_isomounts() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        echo -e -n "$_r >$_W Process isomounts \n $_n"
        sed "s|@ARCH@|${arch}|g" isomounts > ${work_dir}/iso/${install_dir}/isomounts
        : > ${work_dir}/build.${FUNCNAME}
        echo -e "$_g >$_W done $_n"
    fi
}

# Build ISO
make_iso() {
        echo -e -n "$_r >$_W Build ISO \n $_n"
        mkliveiso "${verbose}" "${overwrite}" -D "${install_dir}" -L "${iso_label}" -a "${arch}" -c "${compression}" "${high_compression}" iso "${work_dir}" "${name}-${version}-${arch}.iso"
        echo -e "$_g >$_W done $_n"
}

if [[ $verbose == "y" ]]; then
    verbose="-v"
else
    verbose=""
fi

if [[ $overwrite == "y" ]]; then
    overwrite="-f"
else
    overwrite=""
fi

if [[ $high_compression == "y" ]]; then
    high_compression="-x"
else
    high_compression=""
fi

make_root_image
make_boot
make_overlay
make_overlay_pkgs
make_isomounts
make_iso
