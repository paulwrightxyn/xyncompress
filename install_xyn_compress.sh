#!/bin/env bash

# Handle flags
#if [[ -z "$2" ]]; then
#    echo "Options required. Available options:";
#    echo "  --backups make backups in .opt/backup folder";
#    echo "  --webp make WebP images";
#    echo "  --jpg do not compress jpg files (default is to compress). Compression is lossy and will overwrite original files!";
#    echo "  --png do not compress png files (default is to compress). Compression is lossy and will overwrite original files!";
#    echo "  --force force compression of all files even if they have not been updated."
#    exit 1
#fi


# Define some names:

# compression script
compressscript=xyncompress.sh

# log file name
logfile=imageCompression.log

# function for writing errors
echoerr() { printf "%s\\n" "$*" >&2; }

# get parent directory: the path to the folder in which to run compression 
parent_dir="$(dirname -- "$(readlink -f -- "$PWD")")"

# check if the filesystem is set up like Expression Engine, with images in /uploads/images,
# or like Magento, with images in /media, or like Wordpress, with images in /wp-content/uploads


optionsStr="";
filepath="";
while test $# -gt 0
do
    case "$1" in
        --backups) echo "Backups enabled. ";
          optionsStr="${optionsStr} --backups";
            ;;
        --webp) echo "WebP enabled. ";
          optionsStr="${optionsStr} --webp";
            ;;
        --jpg) echo "JPG enabled";
          optionsStr="${optionsStr} --jpg";
            ;;
        --png) echo "PNG enabled";
          optionsStr="${optionsStr} --png";
            ;;
        --force) echo "Force even if optimized record exists";
          optionsStr="${optionsStr} --force";
            ;;
        --*) echo "bad option $1";
          echo "Available options:";
          echo "  --backups make backups in .opt/backup folder";
          echo "  --webp make WebP images";
          echo "  --jpg compress jpg files. Compression is lossy and will overwrite original files!";
          echo "  --png compress png files. Compression is lossy and will overwrite original files!";
          echo "  --force force compression of all files even if they have not been updated."
          exit 1;
            ;;
        *) filepath="$1";
          echo "Compressing all uncompressed images found in $filepath based on the settings provided.";
            ;;
    esac
    shift
done

if [[ -z "${optionsStr// }" ]]; then
  echo "options required. "
  echo "Available options:";
    echo "  --backups make backups in .opt/backup folder";
    echo "  --webp make WebP images";
    echo "  --jpg compress jpg files. Compression is lossy and will overwrite original files!";
    echo "  --png compress png files. Compression is lossy and will overwrite original files!";
    echo "  --force force compression of all files even if they have not been updated."
    exit 1;
fi

if [[ ! -z "${filepath}" ]]; then
	echo "Installing in directory: $1"
	thedir="${filepath}"
elif [ -d "${parent_dir}/uploads/images/" ]; then
	echo "Expression Engine file system structure detected"
	thedir="${parent_dir}/uploads/images/"
elif [ -d "${parent_dir}/media/" ]; then
	echo "Magento file system structure detected"
	thedir="${parent_dir}/media/"
elif [ -d "${parent_dir}/wp-content/uploads/" ]; then
	echo "Wordpress file system structure detected"
	thedir="${parent_dir}/wp-content/uploads/"
else
	echoerr ""
	echoerr "***  ERROR ***"
	echoerr "CMS file system not detected.  Make sure this script is being run from docs/.xyncompress/, docs.dev/.xyncompress/, or public/.xyncompress/"
	echoerr ""
	exit 1
fi

# write out current crontab - random number used to avoid collisions
tempfile=mycron$RANDOM;
echo "Checking for existing crontab";
crontab -l > ${tempfile};


# make sure our script exists and is executable
if [[ -x "${compressscript}" ]]; then
	echo "${compressscript} already exists and is executable"
else
	echo "${compressscript} does not exist, or is not executable. Making it executable. "
	chmod +x ${compressscript}
fi


# run the script to compress the files
echo "Running script to compress files before adding to crontab.  This may take a while. "
echo "${PWD}/${compressscript} ${thedir} ${optionsStr} | tee -a ${PWD}/${logfile}"
${PWD}/${compressscript}  ${thedir} ${optionsStr} 2>> ${PWD}/${logfile}.err 1>> ${PWD}/${logfile}

# echo new cron into cron file
echo "Adding new cron job for ${compressscript} - run every 2 hours in ${thedir}"
echo "0 */2 * * * ${PWD}/${compressscript} ${thedir} ${optionsStr} 2>> ${PWD}/${logfile}.err 1>> ${PWD}/${logfile} " >> ${tempfile}


# install new cron file
crontab ${tempfile}
echo "crontab now contains: "
crontab -l
rm ${tempfile}
