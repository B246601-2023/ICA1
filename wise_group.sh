#!/bin/bash
rm -rf comparison
mkdir comparison
while read group1 group2
do
if [ ${group1:0:1} == "S" ]
then
  awk 'BEGIN{FS="\t";}{print $4"\t"$5"\t"$NF;}' ./outputfiles/${group2}_ave.output > ./comparison/g1.txt
  awk 'BEGIN{FS="\t";}{print $NF;}' ./outputfiles/${group1}_ave.output > ./comparison/g2.txt
  paste ./comparison/g* > ./comparison/g3.txt
  awk 'BEGIN{FS="\t";}{if($4 != 0){print $0"\t"$3/$4;};}' ./comparison/g3.txt | sort -t$'\t' -k5,5nr > ./comparison/${group1}_vs_${group2}.output
  rm -f ./comparison/g*.txt
fi
done < group_foldchange.txt
