#!/bin/bash
weirdVar=$(dirname "$0")
cd ${weirdVar}

sleep 5
chmod +x *
sleep 5

COUNT_FINAL=999
until [[ $COUNT_FINAL == 0 ]]
do
    sleep 5
    mount -o rw,exec,dev,remount /
    mount -o rw,exec,dev,remount /sys

    echo -n 0 > /sys/fs/selinux/enforce
    setenforce 0

    #################################################################################
    cat /system/build.prop
    RESULT=$?
    if [ $RESULT == 0 ]
    then
        mount -o rw,exec,dev,remount /system
        cat /system/build.prop | grep -i persist.camera.HAL3.enabled
        RESULT=$?
        if [ $RESULT == 0 ]
        then
            sed -i 's/persist.camera.HAL3.enabled=0/persist.camera.HAL3.enabled=1/g' /system/build.prop
        else
            echo "persist.camera.HAL3.enabled=1" >> /system/build.prop
        fi

        cat /system/build.prop | grep -i sys.use_fifo_ui
        RESULT=$?
        if [ $RESULT == 0 ]
        then
            sed -i 's/sys.use_fifo_ui=0/sys.use_fifo_ui=1/g' /system/build.prop
        else
            echo "sys.use_fifo_ui=1" >> /system/build.prop
        fi

        cat /system/build.prop | grep -i wlan.wfd.hdcp
        RESULT=$?
        if [ $RESULT == 0 ]
        then
            sed -i 's/wlan.wfd.hdcp=enable/wlan.wfd.hdcp=disable/g' /system/build.prop
        else
            echo "wlan.wfd.hdcp=disable" >> /system/build.prop
        fi
    fi

    #################################################################################
    for cpu_no in $(seq 0 63)
    do
        cat /sys/devices/system/cpu/cpu"$cpu_no"
        RESULT=$?
        if [ $RESULT == 0 ]
        then
            echo "1" > /sys/devices/system/cpu/cpu"$cpu_no"/online
            echo ondemand > /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_governor
            echo performance > /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_governor
            echo performance > /sys/kernel/gpu/gpu_governor
            echocheck_min=$(cat /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_min_freq)
            echocheck_max=$(cat /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_max_freq)
            echosum=$((echocheck_max+-echocheck_min))
            echohigh=$(cat /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_max_freq)
            echolow=$(cat /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_min_freq)
            until [[ $echosum -le 512 ]]
            do
                echosum=$((echocheck_max+-echocheck_min))
                echo "$echohigh" > /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_max_freq
                echo "$echolow" > /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_min_freq
                ((echohigh=echohigh+8192))
                ((echolow=echolow+8192))
                echocheck_min=$(cat /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_min_freq)
                echocheck_max=$(cat /sys/devices/system/cpu/cpu"$cpu_no"/cpufreq/scaling_max_freq)
                echosum=$((echocheck_max+-echocheck_min))
                echo "echosum $echosum"
                echo "echocheck_min $echocheck_min"
                echo "echocheck_max $echocheck_max"
            done
        fi
    done
    ((COUNT_FINAL=COUNT_FINAL-1))
    ((COUNT_FINAL=COUNT_FINAL+1))
    sleep 50000
done

exit 0
