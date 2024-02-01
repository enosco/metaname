#!/bin/bash

#TODO:
    #Handle .zip and other archive files
        #Unzip -> analyze -> rename -> new zip -> cleanup
    #Deal with strange input and output, like unicode characters, blank titles
    #Also handle cases where no metadata is found in the firstplace
    #Deal with excessively long lines
    #implement reverse and test mode
    #make sure renaming follows the path of given directory

# This sets up error checking and basic help
# NOTE: comment out 'pipefail' if you're expecting things to return
#       nonzero, such as grep if something isn't found.
set -o errexit   # stop script when an error occurs
#set -o pipefail  # stop if a pipe fails
set -o nounset   # stop if an unset variable is accessed
#set -o xtrace

rev_mode=0
test_mode=0

#Help Function
Help()
{
	printf "Metanamer takes an album folder/directory as input \n"
	printf "and renames it with the metadata of the songs inside."
	printf "\n\nDefault output format: [ARTIST] - [ALBUM]\n\n"
	

	printf "SYNTAX: metanamer [-h] [DIRECTORY]\n"
	printf "options:\n"
	printf " -h\tPrint help message.\n\n"
	
}

#Loop through options
while getopts ":h:rt" option; do
	case $option in
		h) #Print help message
			Help
			exit;;
		r) #Change output to album - artist
			rev_mode=1
			;;
		t) #Show output without changing names
			echo "====        Operating in test mode        ===="
			echo "====  Directory name will not be changed  ===="
			echo
			
			test_mode=1
			;;
		\?)
			echo "illegal option -- Use -h for help"
			exit;;
	esac
done

shift $((OPTIND-1))

#Check for no input
if [[ $# -eq 0 ]]; then
    echo "Usage: metanamer [OPTIONS] [DIRECTORY] -- Use -h for more details"
    exit 0
fi

#Check for non-directory input
if [[ ! -d $1 ]]; then
    echo "input is not a directory -- Use -h for help"
    exit 1
else 
    targetdir=$1
fi

#Check if dir is empty
if [[ -z "$( ls -A $targetdir )" ]]; then
	echo "directory is empty -- Use -h for help"
	exit 2
fi

#Check for potential invalid input -- no audio files
grep_exit_code=$( ls -A $targetdir | grep -qs '.\(wav\|mp3\|flac\|ogg\|aac\|m4a\)'; echo $?)

if [[ $grep_exit_code == 1 ]]; then
	echo "directory contains no audio files -- Use -h for help"
	exit 3
fi

printf "selected directory: $targetdir\n" 

user_confirm=0

artistname="NULL"
albumname="NULL"

#Loop through audio files in targetdir to find appropriate metadata
for file in "$targetdir"/*; do
    
    filename=$(basename "$file")

	#Check file extension
    if [[ $filename =~ .*\.(wav|mp3|flac|ogg|aac|m4a)$ ]]; then
        printf "found audio file: $filename\n\n"

        artistname=$(exiftool -b -Artist "$targetdir"/"$filename") # | sed 's,\(.*:\) \(.*\),\2,')
        albumname=$(exiftool -b -Album "$targetdir"/"$filename") # | sed 's,\(.*:\) \(.*\),\2,')
       
        read -n 1 -p "found artist and album name -- $albumname by $artistname -- is this correct (y/n)? : " input
        echo
        
        if [[ "$input" == [Yy] ]]; then
            user_confirm=1
            break
        else
            printf "\ntrying other audio files...\n\n"
            continue
        fi
            
        #figure out what to do if garbage response is given
    fi
    
    
    #error checking if no artist or album name is found, or if no audio files were found
        #count to check if exiftool was run at least once?
done

if (( $user_confirm == 1 )); then
    
    if (( $rev_mode == 1 )); then
    	newdir="$albumname - $artistname"
    else 
    	newdir="$artistname - $albumname"
    fi

    mv -nv "$targetdir" "$newdir"
else
	echo "unable to find additional audio files. metadata may be incorrect. exit"  
fi


