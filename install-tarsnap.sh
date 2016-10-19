#!/usr/bin/env bash

##############################################################################
# install-tarsnap
# -----------------
#
# :author: greyspectrum
# :date: 19 October 2016
# :version: 0.1.0
##############################################################################

# Fetch Tarsnap signing keys
echo -e '\n==Fetching Tarsnap signing keys...'

gpg --recv-keys --keyserver keys.gnupg.net 0xBC5CFA093DA2BCE3

# Verifying Tarsnap signing key fingerprint
echo -e '\n==Verifying Tarsnap signing key fingerprint...'

echo -e 'pub   4096R/3DA2BCE3 2016-02-18 [expires: 2017-02-17]\n      Key fingerprint = ECAE BA77 D19D 1EE0 CAF1  628F BC5C FA09 3DA2 BCE3\nuid                  Tarsnap source code signing key (Colin Percival) <cperciva@tarsnap.com>\n' > fingerprint

if gpg --fingerprint 0xBC5CFA093DA2BCE3 | diff -q fingerprint -; then
    echo -e '\n==Verified. The Tarsnap signing key provided by the keyserver, 0xBC5CFA093DA2BCE3, has the expected fingerprint.\nKey Fingerprint = ECAE BA77 D19D 1EE0 CAF1  628F BC5C FA09 3DA2 BCE3'
else
    echo -e '\n==ERROR: THE KEY PROVIDED BY THE KEYSERVER HAS RETURNED AN UNEXPECTED FINGERPRINT. ABORTING...'
    rm fingerprint
    exit 1
fi

rm fingerprint

# Downloading dependencies
echo -e '\n==Installing dependencies...'

sudo apt-get update
sudo apt-get install gcc libc6-dev make libssl-dev zlib1g-dev e2fslibs-dev

# Download Tarsnap
echo -e '\n==Downloading Tarsnap...'

cd

mkdir .tarsnap

cd .tarsnap

curl -O https://www.tarsnap.com/download/tarsnap-autoconf-1.0.37.tgz

curl -O https://www.tarsnap.com/download/tarsnap-sigs-1.0.37.asc

# Verify Tarsnap
echo -e '\n==Verifying Tarsnap download...'

if gpg --verify tarsnap-sigs-1.0.37.asc; then
    echo -e '\n==Good signature on sha256 sum, verifying checksum...'
else
    echo -e '\n==ERROR: BAD GPG SIGNATURE. ABORTING...'
    cd
    rm -rf .tarsnap
    exit 1
fi

sed '4q;d' tarsnap-sigs-1.0.37.asc | sed 's/^.......................................//' > sha2sum
sed -i '1s/$/  tarsnap-autoconf-1.0.37.tgz/' sha2sum

if sha256sum tarsnap-autoconf-1.0.37.tgz | diff -q sha2sum -; then
    echo -e '\n==Verified. Good sha256 sum.'
else
    echo -e '\n==ERROR: BAD SHA256 SUM. ABORTING...'
    cd
    rm -rf .tarsnap
    exit 1
fi

# Unpack archive
echo -e '\n==Unpacking Tarsnap archive...'

tar -xzf tarsnap-autoconf-1.0.37.tgz

# Compile Tarsnap
echo -e '\n==Compiling Tarsnap...'

cd tarsnap-autoconf-1.0.37
./configure
make all
sudo make install

sudo mv \
    /usr/local/etc/tarsnap.conf.sample \
    /usr/local/etc/tarsnap.conf

cd

# Open Tarsnap registration page
echo -e '\n==Opening Tarsnap registration...'

xdg-open https://www.tarsnap.com/register.cgi

echo -e '\n==Installation complete.'
