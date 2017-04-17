#!/bin/bash

if [ $(cat /sys/module/nf_conntrack/parameters/hashsize) -lt 2500000 ]; then
        echo 2500000 > /sys/module/nf_conntrack/parameters/hashsize
fi

if [ $(sysctl -n net.netfilter.nf_conntrack_tcp_loose) -eq 1 ]; then
        sysctl -w net/netfilter/nf_conntrack_tcp_loose=0
fi

ncpus=`grep -ciw ^processor /proc/cpuinfo`
test "$ncpus" -gt 1 || exit 1

n=0
for irq in `cat /proc/interrupts | grep eth | awk '{print $1}' | sed s/\://g`
do
    f="/proc/irq/$irq/smp_affinity"
    test -r "$f" || continue
    cpu=$[$ncpus - ($n % $ncpus) - 1]
    if [ $cpu -ge 0 ]
            then
                mask=`printf %x $[2 ** $cpu]`
                echo "Assign SMP affinity: eth$n, irq $irq, cpu $cpu, mask 0x$mask"
                echo "$mask" > "$f"
                let n+=1
    fi
done
