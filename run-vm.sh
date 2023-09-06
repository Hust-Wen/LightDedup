#!/bin/bash

usage() {
    echo ""
    echo "Usage: $0 [ioda|nonioda]"
    echo ""
    exit
}

IODA_IMGDIR="./images"
# IODA_IMGDIR="/home/wenyuhong/vdo/"
IODA_KERNEL="src/iodaLinux/arch/x86/boot/bzImage"
IODA_FEMU="src/iodaFEMU/build-femu/x86_64-softmmu/qemu-system-x86_64"
Share_Dir_Path="./share"

sudo sh -c 'echo 1 > /proc/sys/vm/drop_caches'
echo 2 | sudo tee /sys/kernel/mm/ksm/run >/dev/null 2>&1

echo "===> Booting the IODA Virtual Machine..."
sleep 3

    #-kernel "${IODA_KERNEL}" \
    #-append "root=/dev/sda1 console=ttyS0,115200n8 console=tty0 biosdevname=0 net.ifnames=0 nokaslr log_buf_len=128M loglevel=4" \

MB=1
let GB=1024*${MB}
device_count=4
let array_size_MB=64*${GB}
let device_size_MB_per=${array_size_MB}/${device_count}

device_command=""
for((i=1;i<=${device_count};i++));
do device_command+="-device femu,devsz_mb=${device_size_MB_per},femu_mode=1 "; done

sudo ${IODA_FEMU} \
    -name "iodaVM" \
    -cpu host \
    -smp 24 \
    -m 40G \
    -enable-kvm \
    -boot menu=on \
    -fsdev local,security_model=passthrough,id=fsdev0,path=${Share_Dir_Path} \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare \
    -drive file=${IODA_IMGDIR}/u20s.qcow2,if=virtio,cache=none,aio=native,format=qcow2 \
    ${device_command} \
    -netdev user,id=user0,hostfwd=tcp::10101-:22 \
    -device virtio-net-pci,netdev=user0 \
    -nographic | tee ./ioda-femu.log 2>&1 \

echo "femu finish!"

# cache_size="128MB"  #32MB, 128MB, 512MB
# duplicate_ratio=50   #0, 20, 50, 90
# transaction="4MB"    #0.5MB, 4MB, 64MB
# read_ratio=0            #0, 50, 100
# access_pattern="rand"   #seq, rand, skew

Dedup_engine="LightDedup"  #-Dmdedup -LightDedup -DedupSSD

# if [ $Dedup_engine == "Dmdedup" ]
# then
# GC_threshould=100    #default: 10 for Dmdedup, 10000 for LightDedup 
# elif [ $Dedup_engine == "LightDedup" ]
# then
# GC_threshould=10000    #default: 10 for Dmdedup, 10000 for LightDedup 
# R_MapTable=100       #0, 20, 50, 100, 200
# else
# GC_threshould=10000    #default: 10 for Dmdedup, 10000 for LightDedup 
# R_MapTable=0       #0, 20, 50, 100, 200
# fi

# GC_threshould=5
# R_MapTable=100

# root_name="vdbench"
root_name="Realistic_Workloads"
# dir_name="configurations/${cache_size}cache-${duplicate_ratio}%Dedup-Per${transaction}-r${read_ratio}-${access_pattern}"
# dir_name="R_MapTable/${duplicate_ratio}%Dedup-${R_MapTable}%R_MapTable"
# dir_name="new_R_MapTable/${duplicate_ratio}%Dedup-${R_MapTable}%R_MapTable"
# dir_name="skew_R_MapTable/${duplicate_ratio}%Dedup-${R_MapTable}%R_MapTable"
# dir_name="GC_threshould/${GC_threshould}%GC"
# dir_name="SSDs_of_array"
# Dedup_engine="${device_count}-SSDs-${Dedup_engine}"
# dir_name="temp"
dir_name="Homes"
# dir_name="test/${cache_size}cache-${duplicate_ratio}%Dedup-Per${transaction}-r${read_ratio}-${access_pattern}"

# Dedup_engine="LightDedup50"
# Dedup_engine=""

mkdir -p "./$root_name/$dir_name/$Dedup_engine"
cp ./SSDInfo_*.log "./$root_name/$dir_name/$Dedup_engine/"
# cp ./SSDLatency_*.log ./$root_name/$dir_name/$Dedup_engine/
cp ./ioda-femu.log "./$root_name/$dir_name/$Dedup_engine/"
cp ${Share_Dir_Path}/dedup_info.log "./$root_name/$dir_name/$Dedup_engine/"
cp ${Share_Dir_Path}/result_IOPS.log "./$root_name/$dir_name/$Dedup_engine/"
# cp ${Share_Dir_Path}/running_res.log ./$root_name/$dir_name/$Dedup_engine/
# cp ${Share_Dir_Path}/xremap-run-dedup.sh "./$root_name/$dir_name/$Dedup_engine/"
# cp ${Share_Dir_Path}/my_run.sh ./$root_name/$dir_name/$Dedup_engine/
# cp ${Share_Dir_Path}/latency-*.log ./$root_name/$dir_name/$Dedup_engine/
# cp -r ${Share_Dir_Path}/output "./$root_name/$dir_name/$Dedup_engine/"
# cp -r ${Share_Dir_Path}/output-warm "./$root_name/$dir_name/$Dedup_engine/"
cp ${Share_Dir_Path}/run_replaytrace.sh "./$root_name/$dir_name/$Dedup_engine/"
cp ${Share_Dir_Path}/run_replaytrace.log "./$root_name/$dir_name/$Dedup_engine/"
cp ${Share_Dir_Path}/replay_trace.log "./$root_name/$dir_name/$Dedup_engine/"
# cp -r ${Share_Dir_Path}/output-warm-SSD "./$root_name/$dir_name/$Dedup_engine/"
# cp -r ${Share_Dir_Path}/output-warm-Dedup "./$root_name/$dir_name/$Dedup_engine/"
echo "result files copy finish!"

# rm /home/wenyuhong/git/IODA-SOSP21-AE/SSDInfo_*.log 

# cd /home/wenyuhong/git/IODA-SOSP21-AE/
# mkdir -p ./picture-1/Cache
# cp -r ./$root_name/*-50%Dedup-100%GC-Per4MB-4KBIO/ ./picture-1/Cache/
# mkdir -p ./picture-1/Dup-Ratio
# cp -r ./$root_name/528MBcache-*-100%GC-Per4MB-4KBIO/ ./picture-1/Dup-Ratio/
# mkdir -p ./picture-1/Transaction
# cp -r ./$root_name/528MBcache-50%Dedup-100%GC-*-4KBIO/ ./picture-1/Transaction/
# mkdir -p ./picture-1/IO-Size
# cp -r ./$root_name/528MBcache-50%Dedup-100%GC-Per4MB-*/ ./picture-1/IO-Size/
