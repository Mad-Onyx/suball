#!/bin/bash

#usage: 
#chmod +x main.sh
#./main.sh <file containing domains> <export path>

if test -z "$1" 
then
    echo "./main.sh <file containing domains> <export path>"
    echo "example: ./main.sh /home/sandy/Desktop/domains.txt /home/sandy/Desktop/indeed "
    exit 1
fi

echo "creating directory....."
mkdir $2 -p
cd $2


echo 'FINDING SUBDOMAINS...'

while read line
do
        for var in $line
        do
                echo 'enumerating:' $var

                subfinder -d $var -nW > out1.txt
                cat out1.txt >> subs1.txt

                assetfinder -subs-only $var > out2.txt
                cat out2.txt >> subs2.txt
                
                python3 /home/sandy/personal_tools/Sublist3r/sublist3r.py -d $var -o out3.txt
                cat out3.txt >> subs3.txt
                
                amass enum -d $var -passive -o out4.txt
                cat out4.txt >> subs4.txt

                rm out1.txt out2.txt out3.txt out4.txt
        done
done < $1

sort -u subs1.txt subs2.txt subs3.txt subs4.txt > all_subs.txt
rm subs1.txt subs2.txt subs3.txt subs4.txt
echo 'saved subdomains to all_subs.txt'

echo 'FINDING LIVE HOSTS...'

cat all_subs.txt | httprobe > live_subs1.txt
cat all_subs.txt | massdns -r /home/sandy/personal_tools/massdns/lists/resolvers.txt -t A -o S -w live_subs2.txt
sed 's/A.*//' live_subs2.txt | sed 's/CN.*//' | sed 's/\..$//' > live_subs3.txt

sort -u live_subs1.txt live_subs3.txt > live_subs.txt
rm live_subs1.txt live_subs2.txt live_subs3.txt
echo "saved live hosts to live_subs.txt"

echo 'CHECKING FOR SUBDOMAIN TAKEOVER...'
subjack -w all_subs.txt -a -t 50 -timeout 30 -ssl -c /home/sandy/go/fingerprints.json -v > potential_takeovers1.txt 
subzy -targets all_subs.txt --hide_fails > potential_takeovers2.txt

sort -u potential_takeovers1.txt potential_takeovers2.txt > potential_takeovers.txt
rm potential_takeovers1.txt potential_takeovers2.txt
echo "saved potential subdomains for takeover to potential_takeovers.txt"
 
echo "SCREENSHOTTING LIVE HOSTS....."
mkdir screenshots
cd screenshots
gowitness file -f ../live_subs.txt

echo 'DONE'

