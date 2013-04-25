all:

install: all
	# install to sbin since script only usable by root
	install -D -m 755 mkliveiso $(DESTDIR)/usr/sbin/mkliveiso
	install -D -m 755 mkliveroot $(DESTDIR)/usr/sbin/mkliveroot
	install -D -m 755 build.sh $(DESTDIR)/usr/sbin/build
	install -D -m 755 overlay-pkgs.sh $(DESTDIR)/usr/bin/overlay-pkgs
	# testiso can be used by anyone
	install -D -m 755 testiso $(DESTDIR)/usr/bin/testiso
	# hooks/install are needed by mkinitcpio
	install -D -m 644 hooks/liveiso $(DESTDIR)/usr/lib/initcpio/hooks/liveiso
	install -D -m 644 install/liveiso $(DESTDIR)/usr/lib/initcpio/install/liveiso
	install -D -m 644 hooks/liveiso_pxe_nbd $(DESTDIR)/usr/lib/initcpio/hooks/liveiso_pxe_nbd
	install -D -m 644 install/liveiso_pxe_nbd $(DESTDIR)/usr/lib/initcpio/install/liveiso_pxe_nbd
	install -D -m 644 hooks/liveiso_loop_mnt $(DESTDIR)/usr/lib/initcpio/hooks/liveiso_loop_mnt
	install -D -m 644 install/liveiso_loop_mnt $(DESTDIR)/usr/lib/initcpio/install/liveiso_loop_mnt
	install -D -m 644 install/liveiso_kms $(DESTDIR)/usr/lib/initcpio/install/liveiso_kms	
	# install helpers
	install -d -m 755 $(DESTDIR)/usr/share/liveiso/
	install -D -m 755 functions/messages $(DESTDIR)/usr/share/liveiso/functions/messages
	install -D -m 755 functions/colors $(DESTDIR)/usr/share/liveiso/functions/colors

uninstall:
	rm -f $(DESTDIR)/usr/sbin/mkliveiso
	rm -f $(DESTDIR)/usr/sbin/mkliveroot
	rm -f $(DESTDIR)/usr/sbin/build
	rm -f $(DESTDIR)/usr/bin/overlay-pkgs
	rm -f $(DESTDIR)/usr/bin/testiso
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/liveiso
	rm -f $(DESTDIR)/usr/lib/initcpio/install/liveiso
	rm -f $(DESTDIR)/usr/lib/initcpio/hooks/liveiso_pxe_nbd
	rm -f $(DESTDIR)/usr/lib/initcpio/install/liveiso_pxe_nbd
	rm -rf $(DESTDIR)/usr/share/liveiso/
