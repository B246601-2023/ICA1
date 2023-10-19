#!/bin/bash
rm -rf fastqc_report sam bam bam_sorted
rm -f allfilesname.txt bowtie*
mkdir fastqc_report sam bam bam_sorted 
echo "Getting data ... ..."
cp -r /localdisk/data/BPSM/ICA1/fastq .
cp /localdisk/data/BPSM/ICA1/Tcongo_genome/TriTrypDB-46_TcongolenseIL3000_2019_Genome.fasta.gz .
cp /localdisk/data/BPSM/ICA1/TriTrypDB-46_TcongolenseIL3000_2019.bed .
mv ./fastq/Tco2.fqfiles . #for convenience
if [ -e "./fastq" ] && [ -e "TriTrypDB-46_TcongolenseIL3000_2019_Genome.fasta.gz" ] && [ -e TriTrypDB-46_TcongolenseIL3000_2019.bed ] && [ -e "Tco2.fqfiles" ]
then
continue
else
echo "Lack neccessary files."
exit 1
fi
ls fastq | grep "fq.gz" | sort > allfilesname.txt #list files in fastq dir 
fastqc -o fastqc_report ./fastq/*.fq.gz
echo "Quality check complete."
while read name
do 
   name=${name/.fq.gz/_fastqc}
   unzip -o ./fastqc_report/${name}.zip -d ./fastqc_report
   E=$(grep -i "fail" ./fastqc_report/${name}/summary.txt | wc -l)
   if [[ ${E} == 0 ]]
   then
   continue
   else
   echo ${name} >> ./fastqc_report/fails.txt
   grep -i "fail" ./fastqc_report/${name}/summary.txt >> ./fastqc_report/fails.txt
   echo "${E} errors are found in ${name} by fastqc. Open the html in 'fastqc_report' for details. See all fails in fails.txt"
   fi
done < allfilesname.txt
bowtie2-build TriTrypDB-46_TcongolenseIL3000_2019_Genome.fasta.gz bowtie
unset name

n=$(wc -l < allfilesname.txt)
if ((${n}%2==0))
then
 while read line1
 do
  read line2
  filename=${line1/_1.fq.gz/}
  filename=${filename/-/}
  bowtie2 -x bowtie -1 ./fastq/${line1} -2 ./fastq/${line2} -S ./sam/${filename}.sam
  samtools view -S -b ./sam/${filename}.sam > ./bam/${filename}.bam
  samtools sort ./bam/${filename}.bam -o ./bam_sorted/${filename}.bam
  samtools index ./bam_sorted/${filename}.bam
 done < allfilesname.txt
else
echo "error"
fi
unset n
unset filename

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
echo "Overlap counts reading complete. Original results are saved in 'group'."
unset dname

#output plain file
rm -rf outputfiles
rm -f all.txt
mkdir outputfiles
while read g
do
dname=${g/.list/}
paste TriTrypDB-46_TcongolenseIL3000_2019.bed  ./group/${dname}/*.txt > all.txt
awk 'BEGIN{FS="\t";}{sum=0;for (i=6;i<=NF;i++) sum+=$i;ave=sum/(i-5);print$0"\t"ave;}' all.txt > ./outputfiles/${dname}_ave.output
rm -f ./group/${dname}/*.txt
done < filegroup.txt
ehco "The output files of average of expression levels for each gene are saved in 'outputfiles'."
rm -f all.txt
unset dname

#foldchange
rm -rf comparison
mkdir comparison
echo "Now calculating fold change between groups. The groups to be processed can be edit in 'group_foldchange.txt'."
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
echo "The results are saved in 'comparison'."
echo "Missions complete."
