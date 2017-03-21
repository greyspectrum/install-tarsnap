#!/usr/bin/env bash

##############################################################################
# install-tarsnap
# -----------------
#
# :author: greyspectrum
# :date: 20 March 2017
# :version: 0.1.0
##############################################################################

# Fetch Tarsnap signing keys
echo -e '\n==Fetching Tarsnap signing keys...'

gpg --recv-keys --keyserver keys.gnupg.net 0xDF27AF8EAB663109

# Verifying Tarsnap signing key fingerprint
echo -e '\n==Verifying Tarsnap signing key fingerprint...'

echo -e 'pub   4096R/AB663109 2017-01-06 [expires: 2018-02-01]\n      Key fingerprint = 16B0 D62B DC0E D244 B77B  DC93 DF27 AF8E AB66 3109\nuid                  Tarsnap source code signing key (Tarsnap Backup Inc.) <cperciva@tarsnap.com>\n' > fingerprint

if gpg --fingerprint 0xDF27AF8EAB663109 | diff -q fingerprint -; then
    echo -e '\n==Verified. The Tarsnap signing key provided by the keyserver, 0xDF27AF8EAB663109, has the expected fingerprint.\nKey Fingerprint = 16B0 D62B DC0E D244 B77B  DC93 DF27 AF8E AB66 3109'
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

# Notify user to register

echo -e '\n==Installation complete.\n\n====> If you do not already have a Tarsnap account, you must create one at https://www.tarsnap.com/register.cgi and deposit funds in your account.\n\n'

echo -e 'Enter the email address you used to register your Tarsnap account, then press [ENTER]: '
read email
echo -e 'Enter a name for this machine, which will be displayed in your Tarsnap account reports so that you know how much data each machine is storing, then press [ENTER]: '
read name

sudo tarsnap-keygen \
	--keyfile /root/tarsnap.key \
	--user $email \
	--machine $name
