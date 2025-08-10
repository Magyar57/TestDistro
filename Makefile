# ==== Folders ====
DOWNLOAD_FOLDER=download
BUILD_FOLDER=build
INITRAMFS=$(BUILD_FOLDER)/initramfs

# ==== Files ====
IMAGE=linux/arch/x86/boot/bzImage
# Initramfs
CPIO_ARCHIVE=$(BUILD_FOLDER)/rootfs.cpio.gz
BASH_STATIC=$(INITRAMFS)/bin/bash
BUSYBOX=$(INITRAMFS)/bin/busybox

BASH_STATIC_URL=https://github.com/robxu9/bash-static/releases/download/5.2.015-1.2.3-2/bash-linux-x86_64
BUSYBOX_URL=https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox

.PHONY: all run clean

all: $(CPIO_ARCHIVE)

# Compile

$(BUSYBOX): | $(DOWNLOAD_FOLDER) $(INITRAMFS)
	if [ ! -e $(DOWNLOAD_FOLDER)/busybox ]; then wget -O $(DOWNLOAD_FOLDER)/busybox $(BUSYBOX_URL); fi
	cp $(DOWNLOAD_FOLDER)/busybox $@
	chmod +x $@

$(BASH_STATIC): | $(DOWNLOAD_FOLDER) $(INITRAMFS)
	if [ ! -e $(DOWNLOAD_FOLDER)/bash-static ]; then wget -O $(DOWNLOAD_FOLDER)/bash-static $(BASH_STATIC_URL); fi
	cp $(DOWNLOAD_FOLDER)/bash-static $@
	chmod +x $@

$(IMAGE):
	@echo "Please compile the linux kernel before building this OS"
	@exit 1

$(CPIO_ARCHIVE): $(BASH_STATIC) $(BUSYBOX)
	ln -sf /bin/bash $(INITRAMFS)/init
	cd $(INITRAMFS) && find . | cpio -o --format=newc | gzip >../../$@

# Folders

$(INITRAMFS): | $(BUILD_FOLDER)
	mkdir -p $@ $@/bin

$(BUILD_FOLDER):
	mkdir -p $@

$(DOWNLOAD_FOLDER):
	mkdir -p $@

# Run

run: $(IMAGE) $(CPIO_ARCHIVE)
	qemu-system-x86_64 \
		-kernel $(IMAGE) \
		-initrd $(CPIO_ARCHIVE)

# Clean

clean:
	rm -rf $(BUILD_FOLDER)
