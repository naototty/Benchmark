#!/bin/bash

echo "
###############################################################################
#                                                                             #
#             Installation(s) complete.  Benchmarks starting...               #
#                                                                             #
#  Running Benchmark as a background task. This can take several hours.       #
#  ServerBear will email you when it's done.                                  #
#  You can log out/Ctrl-C any time while this is happening                    #
#  (it's running through nohup).                                              #
#                                                                             #
###############################################################################
"
>sb-output.log

echo "Checking server stats..."
echo "Distro:
`cat /etc/issue 2>&1`
CPU Info:
`cat /proc/cpuinfo 2>&1`
Disk space: 
`df --total 2>&1`
Free: 
`free 2>&1`" >> sb-output.log

echo "Running dd I/O benchmark..."

echo "dd 1Mx1k fdatasync: `dd if=/dev/zero of=/data/sb-io-test bs=1M count=1k conv=fdatasync 2>&1`" >> sb-output.log
echo "dd 64kx16k fdatasync: `dd if=/dev/zero of=/data/sb-io-test bs=64k count=16k conv=fdatasync 2>&1`" >> sb-output.log
echo "dd 1Mx1k dsync: `dd if=/dev/zero of=/data/sb-io-test bs=1M count=1k oflag=dsync 2>&1`" >> sb-output.log
echo "dd 64kx16k dsync: `dd if=/dev/zero of=/data/sb-io-test bs=64k count=16k oflag=dsync 2>&1`" >> sb-output.log

rm -f /data/sb-io-test

echo "Running IOPing I/O benchmark..."
cd ioping-0.6
make >> ../sb-output.log 2>&1

if [ "a/data"=="a" ]; then
  echo "IOPing I/O: `./ioping -c 10 . 2>&1 `
  IOPing seek rate: `./ioping -RD . 2>&1 `
  IOPing sequential: `./ioping -RL . 2>&1`
  IOPing cached: `./ioping -RC . 2>&1`" >> ../sb-output.log
else
  echo "IOPing I/O: `./ioping -c 10 /data/ 2>&1 `
  IOPing seek rate: `./ioping -RD /data/ 2>&1 `
  IOPing sequential: `./ioping -RL /data/ 2>&1`
  IOPing cached: `./ioping -RC /data/ 2>&1`" >> ../sb-output.log
fi
cd ..

echo "Running FIO benchmark..."
cd fio-2.0.9
make >> ../sb-output.log 2>&1

echo "FIO random reads:
`./fio reads.ini 2>&1`
Done" >> ../sb-output.log

echo "FIO random writes:
`./fio writes.ini 2>&1`
Done" >> ../sb-output.log

rm /data/sb-io-test 2>/dev/null
cd ..

function download_benchmark() {
  echo "Benchmarking download from $1 ($2)"
  DOWNLOAD_SPEED=`wget -O /dev/null $2 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}'`
  echo "Got $DOWNLOAD_SPEED"
  echo "Download $1: $DOWNLOAD_SPEED" >> sb-output.log 2>&1
}

echo "Running bandwidth benchmark..."

download_benchmark 'Cachefly' 'http://cachefly.cachefly.net/100mb.test'
download_benchmark 'Linode, Atlanta, GA, USA' 'http://speedtest.atlanta.linode.com/100MB-atlanta.bin'
download_benchmark 'Linode, Dallas, TX, USA' 'http://speedtest.dallas.linode.com/100MB-dallas.bin'
download_benchmark 'Linode, Tokyo, JP' 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin'
download_benchmark 'Linode, London, UK' 'http://speedtest.london.linode.com/100MB-london.bin'
download_benchmark 'OVH, Paris, France' 'http://proof.ovh.net/files/100Mio.dat'
download_benchmark 'SmartDC, Rotterdam, Netherlands' 'http://mirror.i3d.net/100mb.bin'
download_benchmark 'Hetzner, Nuernberg, Germany' 'http://hetzner.de/100MB.iso'
download_benchmark 'iiNet, Perth, WA, Australia' 'http://ftp.iinet.net.au/test100MB.dat'
download_benchmark 'Leaseweb, Haarlem, NL' 'http://mirror.nl.leaseweb.net/speedtest/100mb.bin'
download_benchmark 'Leaseweb, Manassas, VA, USA' 'http://mirror.us.leaseweb.net/speedtest/100mb.bin'
download_benchmark 'Softlayer, Singapore' 'http://speedtest.sng01.softlayer.com/downloads/test100.zip'
download_benchmark 'Softlayer, Seattle, WA, USA' 'http://speedtest.sea01.softlayer.com/downloads/test100.zip'
download_benchmark 'Softlayer, San Jose, CA, USA' 'http://speedtest.sjc01.softlayer.com/downloads/test100.zip'
download_benchmark 'Softlayer, Washington, DC, USA' 'http://speedtest.wdc01.softlayer.com/downloads/test100.zip'

echo "Running traceroute..."
echo "Traceroute (cachefly.cachefly.net): `traceroute cachefly.cachefly.net 2>&1`" >> sb-output.log

echo "Running ping benchmark..."
echo "Pings (cachefly.cachefly.net): `ping -c 10 cachefly.cachefly.net 2>&1`" >> sb-output.log

echo "Running UnixBench benchmark..."
cd UnixBench-5.1.3
./Run -c 1 -c 16 >> ../sb-output.log 2>&1
cd ..

TM_STR=$(date "+%Y-%m%d")

## RESPONSE=`curl -s -F "upload[upload_type]=unix-bench-output" -F "upload[data]=<sb-output.log" -F "upload[key]=cloud.gmo.jp|naoto.gohko@gmail.com|GMO-AppsCloud-v2-FIO-baremetal|[$16500000/mth]" -F "private=" http://promozor.com/uploads.text`
## 
## echo "Uploading results..."
## echo "Response: $RESPONSE"
echo "Completed! Your benchmark has been queued & will be delivered in a jiffy."
kill -15 `ps -p $$ -o ppid=` &> /dev/null
## rm -rf ../sb-bench
mv -vf ../sb-bench ../sb-bench-${TM_STR}
rm -rf ~/.sb-pid

exit 0
