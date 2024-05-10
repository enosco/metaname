#!/bin/bash

#TODO:
    #make sure renaming follows the path of given directory
    #Stop from nesting folders if folder already exists
    #Handle case where .zip archive has multiple albums zipped inside
    #Package renaming into a single function
    #Figure out bug in zip mode where it creates an empty folder of the selected album
        #Test on yot club or any agaisnt me album, that seems to provoke it
    #Another error with wecool.zip, something to do with folder with a folder? figure it out
        #Freaks out with certain downloads that have osx metadata folders?
        #mv: cannot move 'wecool.zip' to a subdirectory of itself, '/media/wizard/EVIL JAMS//Jeff Rosenstock - We Cool?.zip'
            #Found error, cannot use '?' in a filename
    #Aphex twin album leads to stop, what happens?
        #Same with me like bees
    #Found issue with hop along album, have to escape the brackets; how do i do that with input?

set -o errexit   # stop script when an error occurs
set -o nounset   # stop if an unset variable is accessed
#set -o xtrace

#Print help message
Help()
{
	#printf '\e[31m%s\e[0m' "RED"
	printf "Metaname takes an album folder/directory as input \n"
	printf "and renames it with the metadata of the songs inside."
	printf "\n\nDefault output format: [ARTIST] - [ALBUM]\n\n"
	

	printf "SYNTAX: metanamer [-h] [DIRECTORY]\n"
	printf "options:\n"
	printf " -h\tPrint help message.\n"
	printf " -z\tRename .zip archives.\n\n"
	
}

Rename()
{
	if [[ $zip_mode == 1 ]]; then

    	new_name="$path/$artist_name - $album_name" #the proper path is already defined in Iterate_Zip
		mv -nv "$targetdir" "$new_name.zip"	

	else
		path=$(realpath "$targetdir"/..)
		newdir="$path/$artist_name - $album_name" 
		mv -nv "$targetdir" "$newdir"
	fi
}

#Loop through audio files in targetdir to find appropriate metadata
Iterate_Dir()
{
	for file in "$targetdir"/*; do
	    
	    filename=$(basename "$file")
	
		#Check file extension
	    if [[ $filename =~ .*\.(wav|mp3|flac|ogg|aac|m4a)$ ]]; then

	        printf '\e[0;34m%s\e[0m' "selected audio file: "
	        printf "$filename\n"
	
	        artist_name=$(exiftool -b -Artist "$targetdir"/"$filename")
	        album_name=$(exiftool -b -Album "$targetdir"/"$filename")

	   	    user_confirm=0

			printf '\e[0;32m%s\e[0m' "found artist and album name"
			read -n 1 -p " -- $album_name by $artist_name -- is this correct (y/n)? : " input
			echo
	        
	        if [[ "$input" == [Yy] ]]; then
	            user_confirm=1
	            break
	        else
	            printf "trying other audio files...\n\n"
	            continue
	        fi
	            
	    fi
	    
	done



	if (( $user_confirm == 1 )); then
		Rename
	else
		printf '\e[31m%s\e[0m' "unable to find additional audio files. exiting..."
		echo  
		exit 1
	fi
}

#Extract individual songs from archive to grab metadata from
#TODO
#Change file list into string or array
#Find if there is a way to read file without extracting
Iterate_Zip2()
{
	path=$(realpath "$targetdir" | sed 's:\(.*/\).*:\1:' )					#Get path of target .zip

	IFS=$'\n' song_list=( $( unzip -Z1 "$targetdir" | grep $audio_formats)) #Place contents of arhcive into array

	for song in "${song_list[@]}"
	do

		unzip -q "$targetdir" "$song" -d "."								#Pull temp song from archive

		printf '\e[0;34m%s\e[0m' "selected audio file: "
		printf "$song\n"

		artist_name=$(exiftool -b -Artist "$song" )							#Attempt to pull metadata from song
		album_name=$(exiftool -b -Album "$song" )

		rm "$song"															#Remove temp song

		user_confirm=0
								
	    printf '\e[0;32m%s\e[0m' "found artist and album name"
	    read -n 1 -p " -- $album_name by $artist_name -- is this correct (y/n)? : " input
	    echo
	    
	    if [[ "$input" == [Yy] ]]; then
	    	user_confirm=1
	        break
	    else
	    	printf "trying other audio files...\n\n"
			continue
	    fi
		
	done


	if (( $user_confirm == 1 )); then
	   	Rename	
	else
		printf '\e[31m%s\e[0m' "unable to find additional audio files. exiting..."
		echo
		exit 1  		
	fi	
}
Iterate_Zip()
{	

	path=$(realpath "$targetdir" | sed 's:\(.*/\).*:\1:' )					#Get path of target .zip
	
	file_list="${path}metaname_temp.txt"									#Create file list of archive's contents in temp dir

	unzip -Z1 "$targetdir" | grep $audio_formats > "$file_list"				#Fill file list			
	
	song_count=$(wc -l < "$file_list")
	
	for	(( i=1 ; i <= $song_count ; i++ ))
	do

		current_song=$( sed -n "${i}p" "$file_list" )						#sed command prints the line at index
		unzip -q "$targetdir" "$current_song" -d "." 						#Grab single song from list
		
		printf '\e[0;34m%s\e[0m' "selected audio file: "
		printf "$current_song\n"

		artist_name=$(exiftool -b -Artist "$current_song" )					#Attempt to pull metadata from song
		album_name=$(exiftool -b -Album "$current_song" )
		
		rm "$current_song"													#Remove song
		
		user_confirm=0
								
	    printf '\e[0;32m%s\e[0m' "found artist and album name"
	    read -n 1 -p " -- $album_name by $artist_name -- is this correct (y/n)? : " input
	    echo
	    
	    if [[ "$input" == [Yy] ]]; then
	    	user_confirm=1
	        break
	    else
	    	printf "trying other audio files...\n\n"
			continue
	    fi

	done

	if (( $user_confirm == 1 )); then
	    #if (( $rev_mode == 1 )); then
	    #	new_name="$path/$album_name - $artist_name"
	    #else 
	    #	new_name="$path/$artist_name - $album_name" #That forward slash creates some formatting weirdness, but it makes the code more readable
	    #fi
	    
        #echo
	   	#mv -nv "$targetdir" "$new_name.zip"
        #echo
	   	Rename
	else
		printf '\e[31m%s\e[0m' "unable to find additional audio files. exiting..."
		echo
		exit 1  		
	fi

	rm "$file_list"

}

#						=== MAIN ===


audio_formats='.\(wav\|mp3\|flac\|ogg\|aac\|m4a\)'
type="directory"
zip_mode=0
rev_mode=0

#Loop through options
while getopts ":hzt" option; do
	case $option in
		h) #Print help message
			Help
			exit 1;;
		z) #Handle .zip archives
			zip_mode=1
			type=".zip archive"
			;;
		\?)
			printf '\e[31m%s\e[0m' "illegal option "
			printf '%s\n' "-- Use -h for help"
			exit 1;;
	esac
done

shift $((OPTIND-1))

echo "selected: $1"
#Check for no input
if [[ $# -eq 0 ]]; then
    echo "Usage: metanamer [OPTIONS] [DIRECTORY] -- Use -h for more details"
    echo
    exit 0
fi

#Check for invalid input | might want to find a way to streamline this check
if [[ ! -d "$1" && $zip_mode == 0 ]] || [[ $zip_mode == 1 && "$1" != *\.zip ]]; then 

  	printf '\e[31m%s\e[0m' "input is not a $type " 
	printf '%s\n' "-- Use -h for help"
    exit 1
else 
    targetdir=$1
fi


#Check for audio files within folder
if [[ $zip_mode == 1 ]]; then
	grep_exit_code=$( unzip -l "$targetdir" | grep -qs $audio_formats; echo $?)
else
	grep_exit_code=$( ls -A "$targetdir" | grep -qs $audio_formats; echo $?)
fi


if [[ $grep_exit_code == 1 ]]; then
	printf '\e[31m%s\e[0m' "$type contains no audio files"
	printf '%s\n' "-- Use -h for help"
	exit 1
fi

#If everything is correct, move onto the renaming

#printf "selected $type: $targetdir\n" 

#user_confirm=0

artist_name="NULL"
album_name="NULL"

if [[ $zip_mode == 1 ]]; then
	Iterate_Zip2
else 
	Iterate_Dir
fi
