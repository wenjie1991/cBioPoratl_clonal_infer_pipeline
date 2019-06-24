#!/bin/bash 

mkdir -p test/data
cd test/data
wget -c http://download.cbioportal.org/crc_msk_2017.tar.gz
tar xvf crc_msk_2017.tar.gz

cd ../../

perl6 bin/run_pyclone.pl6 ./test/run_pyclone/ P-0002463-T01-IM3,P-0002463-T02-IM5 ./test/data/crc_msk_2017

