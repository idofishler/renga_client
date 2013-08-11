#! /bin/tcsh -x

set DEBUG = 1

if ($DEBUG) then
	set msg = "debug is ON"
	echo $msg
	repeat $%msg echo -n =
	echo
endif

# usage
if ($# < 1) then
	echo Usage: $0:t file_path
	exit 1
endif

set file_path = "$1"

# folder handling
if (-d $file_path) then
	set file_name = "$file_path"
	if ($DEBUG) then
		echo "$file_name is a directory"
	endif
	set folder_path = "$file_path"
	set folder = 1
else
	set file_name = "$file_path:t"
	if ($DEBUG) then
		echo "$file_name is a file"
	endif
	set folder_path = "$file_path:h"
	set folder = 0
endif

set ext = "$file_path:e"
set name = "$file_path:t:r"

if ($DEBUG) then
	echo file_path: $file_path
	echo file_name: $name
	echo file_ext: $ext
	echo folder_path: $folder_path
endif

cd $folder_path

# check if a git repo exists
git status
if ($status) then
	if ($DEBUG) then
		echo "No git repo here!"
	endif
	exit 1
endif

# if this file is being not monitored
set files = `git ls-files "$file_path" --error-unmatch`
if ($status) then
	if ($DEBUG) then
		echo "This file(s) is(are) not being monitored!"
	endif
	exit 2
endif

# prepare a dir to put all milestones
set mls_dir = "$file_path"_milestones
mkdir "$mls_dir"

# copy current file or folder to milestones folder
if ($folder) then
	cp -a "$file_path" "${mls_dir}/${name}_current"
else
	cp -a "$file_path" "${mls_dir}" # for later use (icon issue)
	cp -a "$file_path" "${mls_dir}/${name}_current.${ext}"
endif


# save file's uncommitted changes
git stash

# find revision for this file where the file has been touched
set revs = ( `git log --reverse --format=oneline $file_path | cut -d" " -f1` )
set i = 1;
foreach r ($revs)
	# get this file revision
	git checkout $r "$file_path"
	
	# copy revision to the milestones folder
	if ($folder) then
		set new_file_name = "${mls_dir}/${name}_${i}"
	else
		set new_file_name = "${mls_dir}/${name}_${i}.${ext}"
	endif
	cp -a "$file_path" $new_file_name

	@ i++
end

# clean up...
## get orignal file to the last revision
git checkout HEAD "$file_path"
## and also uncommitted changes if there are any
git stash pop
## fix the icon (for files only)
if (! $folder) then
	mv "${mls_dir}/${file_name}" "./${file_name}"
endif

exit 0