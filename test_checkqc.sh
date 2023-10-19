#!/bin/bash
ls fastq | grep "fq.gz" | sort > allfilesname.txt #list files in fastq dir
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
