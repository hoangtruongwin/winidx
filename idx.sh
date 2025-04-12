#!/bin/bash

# Cập nhật danh sách gói và cài đặt QEMU-KVM
echo "Đang cập nhật danh sách gói..."
sudo apt update
sudo apt install -y qemu-kvm unzip python3-pip wget

if [ $? -ne 0 ]; then
    echo "Lỗi khi cập nhật và cài đặt các gói cần thiết. Vui lòng kiểm tra lại."
    exit 1
fi

# Đảm bảo thư mục /mnt tồn tại
if [ ! -d /mnt ]; then
    echo "Thư mục /mnt không tồn tại, tạo mới..."
    sudo mkdir /mnt
fi

# Cài đặt gdown để tải từ Google Drive
echo "Cài đặt gdown..."
pip install --break-system-packages gdown

# Tải file từ Google Drive
echo "Đang tải file từ Google Drive..."
gdown --id 12rdnO-JVHPzPDa168ApnIiytYlRtsuK7 -O ./file_downloaded.zip

if [ $? -ne 0 ]; then
    echo "Lỗi khi tải file từ Google Drive."
    exit 1
fi

# Chờ 5s trước khi tiếp tục
echo "Chờ 5s trước khi tiếp tục..."
sleep 5

# Giải nén file zip
echo "Đang giải nén file_downloaded.zip..."
unzip ./file_downloaded.zip -d .

if [ $? -ne 0 ]; then
    echo "Lỗi khi giải nén file zip."
    exit 1
fi

# Resize file a.qcow2 nếu tồn tại
if [ -f ./a.qcow2 ]; then
    echo "Đang mở rộng file a.qcow2 lên 150GB..."
    qemu-img resize ./a.qcow2 150G

    if [ $? -ne 0 ]; then
        echo "Lỗi khi resize file a.qcow2."
        exit 1
    fi
else
    echo "Không tìm thấy file a.qcow2 để resize."
fi

# Khởi chạy máy ảo với KVM
echo "Đang khởi chạy máy ảo..."
echo "Đã khởi động VM thành công, vui lòng tự cài đặt ngrok và mở cổng 5900"

sudo kvm \
-cpu host,+topoext,hv_relaxed,hv_spinlocks=0x1fff,hv-passthrough,+pae,+nx,kvm=on,+svm \
-smp 8 \
-M q35,usb=on \
-device usb-tablet \
-m 24G \
-device virtio-balloon-pci \
-vga virtio \
-net nic,netdev=n0,model=virtio-net-pci \
-netdev user,id=n0,hostfwd=tcp::3389-:3389 \
-boot c \
-device virtio-serial-pci \
-device virtio-rng-pci \
-enable-kvm \
-hda ./a.qcow2 \
-drive if=pflash,format=raw,readonly=off,file=/usr/share/ovmf/OVMF.fd \
-uuid e47ddb84-fb4d-46f9-b531-14bb15156336 \
-vnc :0
