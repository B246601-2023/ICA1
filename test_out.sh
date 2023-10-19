#!/bin/bash
rm -f Sample*.list
rm -rf group group_name
mkdir group_name
tail -n +2  Tco2.fqfiles | awk 'BEGIN{FS="\t";}{print$2;}' | uniq > Sample_type.list
tail -n +2  Tco2.fqfiles | awk 'BEGIN{FS="\t";}{print$4;}' | sort | uniq > Sample_time.list
tail -n +2  Tco2.fqfiles | awk 'BEGIN{FS="\t";}{print$5;}' | sort | uniq > Sample_treatment.list
for type in $(cat Sample_type.list)
do
 for times in $(cat Sample_time.list)
 do
  for treatment in $(cat Sample_treatment.list)
  do
   cat Tco2.fqfiles | awk '($1!="SampleName" && $2=="'$type'" && $4=="'$times'" && $5=="'$treatment'")' | cut -f1  > ./group_name/Sample_${type}_${times}_${treatment}.list
  done
 done
done
find ./group_name -empty -delete

#bedtool
rm -rf Sample*
ls group_name > filegroup.txt
while read g
do
 for filename in $(cat ./group_name/${g})
 do
 dname=${g/.list/}
 mkdir -p ./group/${dname}
 bedtools coverage -counts -bed -a TriTrypDB-46_TcongolenseIL3000_2019.bed -b ./bam_sorted/${filename}.bam > ./group/${dname}/${filename}.counts
 awk 'BEGIN{FS="\t";}{print$6;}' ./group/${dname}/${filename}.counts > ./group/${dname}/${filename}.txt
 done
done < filegroup.txt
unset dname

#output plain file
rm -rf outputfiles
rm all.txt
mkdir outputfiles
while read g
do
dname=${g/.list/}
paste TriTrypDB-46_TcongolenseIL3000_2019.bed  ./group/${dname}/*.txt > all.txt
awk 'BEGIN{FS="\t";}{sum=0;for (i=6;i<=NF;i++) sum+=$i;ave=sum/(i-5);print$0"\t"ave;}' all.txt > ./outputfiles/${dname}_ave.output
done < filegroup.txt
unset dname

