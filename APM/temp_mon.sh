#!/system/bin/sh

. /sdcard/Scripts/APM/Config/temp_limit.conf

toBinary() # 1:index
{
    byte=0x80
    out=
    while [[ $byte > 0 ]]; do
        [ $((byte & $1)) == $byte ] && out+=1 || out+=0
        byte=$((byte >> 1))
    done
    echo $out
}

writeTo()   # 1:filename 2:data
{
    if [[ -f $1 ]]; then
        chmod 644 $1
        echo "$2" > $1
        chmod 444 $1
    fi
}

getTemp()
{
	temp=$(cat $temperature)
    temp=$(( temp / 1000 ))
}

setProfile() # 1:index
{
    writeTo $GPU $((${gfq[$1]} * 1000000))
    core_conf=$(toBinary "0x${cfg[$1]}")
    i=0
    while [[ $i < 8 ]]; do
        if [[ $i > 0 ]]; then
            writeTo ${CPU[$i]} ${core_conf:$i:1}
        fi
        if [[ $i < 4 ]]; then
            writeTo ${FREQ[$i]} ${lfq[$1]}
        else
            writeTo ${FREQ[$i]} ${bfq[$1]}
        fi
        i=$(( i + 1 ))
    done
}

thresholdCheck()    # 1:start_index
{
    getTemp
    if [[ $1 < ${#thr[@]} && $temp -gt ${thr[$1]} ]]; then
        thresholdCheck $(( $1 + 1 ))
    else
        setProfile $(( $1 - 1 ))
    fi
}

main()
{
    echo "Temp Monitor Started.."
    while :
    do
        thresholdCheck 1
        sleep $delay
    done
}

main
