targetfile="iperf-auto.csv"
echo "delay1,delay2,total_delay,threads,reverse,MB_sec" > $targetfile

for t in "0" "25" "50"; do
  fulldelay=$(($t * 2))
  grep '00-' $t-$t-1200-1.txt | grep -v -e omitted -e sender -e receiver | awk '{print $7}' | sed -e "s/^/$t,$t,$fulldelay,1,0,/" >> $targetfile
  grep '00-' $t-$t-1200-1-reverse.txt | grep -v -e omitted -e sender -e receiver | awk '{print $7}' | sed -e "s/^/$t,$t,$fulldelay,1,1,/" >> $targetfile
  for i in 2 3 4 5; do
    grep SUM $t-$t-1200-$i.txt | grep -v -e omitted -e sender -e receiver | awk '{print $6}' | sed -e "s/^/$t,$t,$fulldelay,$i,0,/" >> $targetfile
    grep SUM $t-$t-1200-$i-reverse.txt | grep -v -e omitted -e sender -e receiver | awk '{print $6}' | sed -e "s/^/$t,$t,$fulldelay,$i,1,/" >> $targetfile
  done
done
