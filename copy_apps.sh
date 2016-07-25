mount -o loop -t msdos v_disk flp-loop

cd app_sources

mkdir apps

cp -t apps *.asm

cd apps

for i in *.asm
do
	nasm -f bin $i
done

rm *.asm

cd ../..

mkdir folder

cd folder

mkdir empty prgms

cd ..

cp -t folder/prgms app_sources/apps/*

cp -R folder flp-loop/

rm -R app_sources/apps

rm -R folder

umount flp-loop
