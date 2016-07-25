disk_file="v_disk"
mnt_pnt="flp-loop"

fat_file_driver="msdos"

btldr_bin="bootloader"
btldr_asm="$btldr_bin.asm"
btldr_list="$btldr_bin.list"

krnl_bin="kernel"
krnl_asm="$krnl_bin.asm"
krnl_list="$krnl_bin.list"	

#unmount flp
echo "Attempting to unmount virtual disk if already mounted ......... "
umount $mnt_pnt

#remove existing flp(virt_img), bootloader(binary) and application(binary) - ready for fresh start
echo "Attempting to remove existing virt disk images, $btldr_bin (binary), $krnl_bin (binary) and their translation listings - Readying for fresh start! ......... "
rm $btldr_bin $krnl_bin $disk_file

#create fresh flp(virt_img) and fresh bootloader(binary)
echo "Attempting to create fresh virtual disk ......... "
mkdosfs -C $disk_file 1440
echo "Attempting to compile $btldr_asm ......... "
nasm -f bin $btldr_asm # -l $btldr_list

#binary write bootloader binary into flp img
echo "Attempting to binary write $btldr_bin (binary) into virtual disk ......... "
dd status=noxfer conv=notrunc if=$btldr_bin of=$disk_file

#create mnt_pnt and mount flp as vfat at mount point
echo "Attempting to umount any virtual disk if already mounted ......... "
mount -o loop -t $fat_file_driver $disk_file $mnt_pnt

#create the file to be copied to v_floppy
echo "Attempting to compile $krnl_asm ......... "
nasm -f bin $krnl_asm -l $krnl_list

#cp the krnl binary into the vfat-flp's root directory
echo "Attempting to copy $krnl_bin into the FAT formated disk, using linux file driver - $fat_file_driver ......... "
cp $krnl_bin $mnt_pnt

#unmount flp before booting from it. If this is not done, before qemu boots from it, every sector, except the bootsector, of flp will appear 
#null (filled with 0) to qemu
echo "Attempting to umount virtual disk for bootup ......... "
umount $mnt_pnt

#remove binaries 
echo "Attempting to remove $btldr_bin and $krnl_bin ......... "
rm $btldr_bin $krnl_bin

echo ""