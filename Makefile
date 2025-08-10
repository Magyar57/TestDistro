# ==== Folders ====
TOOLCHAIN_DIR=toolchain
BUILD_DIR=build
INITRAMFS_DIR=$(BUILD_DIR)/initramfs
ISO_DIR=$(BUILD_DIR)/iso

# ==== Files ====
IMAGE=linux/arch/x86/boot/bzImage
# Initramfs
INITRAMFS_ARCHIVE=$(BUILD_DIR)/initramfs.cpio.gz
BASH_STATIC=$(INITRAMFS_DIR)/bin/bash
BUSYBOX=$(INITRAMFS_DIR)/bin/busybox
# ISO image (with Limine bootloader)
ISO_IMAGE=$(BUILD_DIR)/TestDistro.iso
LIMINE_CONF=limine.conf
# Toolchain
BASH_STATIC_URL=https://github.com/robxu9/bash-static/releases/download/5.2.015-1.2.3-2/bash-linux-x86_64
BUSYBOX_URL=https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
LIMINE_URL=https://github.com/limine-bootloader/limine.git
LIMINE_BRANCH=v9.x-binary
LIMINE_PATH=$(TOOLCHAIN_DIR)/limine
LIMINE_EXEC=$(TOOLCHAIN_DIR)/bin/limine

.PHONY: all run clean

all: $(ISO_IMAGE)

# Kernel

$(IMAGE):
	@echo "Please manually compile the linux kernel before building this OS"
	@exit 1

# Initramfs

$(BUSYBOX): | $(TOOLCHAIN_DIR) $(BUILD_DIR)
	if [ ! -e $(TOOLCHAIN_DIR)/busybox ]; then wget -O $(TOOLCHAIN_DIR)/busybox $(BUSYBOX_URL); fi
	cp $(TOOLCHAIN_DIR)/busybox $@
	chmod +x $@

$(BASH_STATIC): | $(TOOLCHAIN_DIR) $(BUILD_DIR)
	if [ ! -e $(TOOLCHAIN_DIR)/bash-static ]; then wget -O $(TOOLCHAIN_DIR)/bash-static $(BASH_STATIC_URL); fi
	cp $(TOOLCHAIN_DIR)/bash-static $@
	chmod +x $@

$(INITRAMFS_ARCHIVE): $(BASH_STATIC) $(BUSYBOX)
	ln -sf /bin/bash $(INITRAMFS_DIR)/init
	cd $(INITRAMFS_DIR) && find . | cpio -o --format=newc | gzip >../../$@

# Bootloader

$(LIMINE_EXEC): | $(TOOLCHAIN_DIR)
	if [ ! -d "$(TOOLCHAIN_DIR)/limine" ]; then git clone $(LIMINE_URL) $(TOOLCHAIN_DIR)/limine --branch=$(LIMINE_BRANCH) --depth=1; fi
	$(MAKE) -C $(TOOLCHAIN_DIR)/limine install PREFIX=$(shell realpath $(TOOLCHAIN_DIR))

# Bootable ISO

$(ISO_IMAGE): $(IMAGE) $(INITRAMFS_ARCHIVE) $(LIMINE_CONF) | $(LIMINE_EXEC)
	cp $(IMAGE) $(ISO_DIR)/boot/vmlinuz
	cp $(INITRAMFS_ARCHIVE) $(ISO_DIR)/boot/
	cp $(TOOLCHAIN_DIR)/limine/limine-bios.sys $(TOOLCHAIN_DIR)/limine/limine-bios-cd.bin $(TOOLCHAIN_DIR)/limine/limine-uefi-cd.bin $(ISO_DIR)
	cp $(LIMINE_CONF) $(ISO_DIR)/boot
	xorriso -as mkisofs -R -r -J -b limine-bios-cd.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
        -apm-block-size 2048 --efi-boot limine-uefi-cd.bin \
        -efi-boot-part --efi-boot-image --protective-msdos-label \
        $(ISO_DIR) -o $@
	$(LIMINE_EXEC) bios-install $@

# Folders

$(BUILD_DIR):
	mkdir -p $@ $(INITRAMFS_DIR) $(INITRAMFS_DIR)/bin $(ISO_DIR) $(ISO_DIR)/boot

$(TOOLCHAIN_DIR):
	mkdir -p $@ $@/bin

# Run

run: $(IMAGE) $(INITRAMFS_ARCHIVE)
	qemu-system-x86_64 \
		-kernel $(IMAGE) \
		-initrd $(INITRAMFS_ARCHIVE)

# Clean

clean:
	rm -rf $(BUILD_DIR)

clean-toolchain:
	rm -rf $(TOOLCHAIN_DIR)
