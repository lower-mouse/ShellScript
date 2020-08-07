#!/bin/bash

# input dir name
# out file name

g_all_files=""
g_all_need_backup_files=""
g_backup_dir=".backup"
g_extra_suffix="h hh c cpp"

g_script='
function fchange_suffix()
{
	objs=$(find . -name "*")
	
	for file in ${objs}
	do 
		if [ -d $file ]; then
			continue;
		fi
		
		dirpath=$(dirname ${file})
		filename=$(basename ${file})
		presuffix=${filename%.*}
		suffix=${filename##*.}
		
		if [ ${suffix:0:2} = "__" ];then
			new_suffix=${suffix:2}
			echo "mv ${file} ${dirpath}/${presuffix}.${new_suffix}"
			mv ${file} ${dirpath}/${presuffix}.${new_suffix}
		fi
	done	
}

fchange_suffix'

function fgeneration_script_to_backup_dir()
{
	if [ ! -d ${g_backup_dir} ];then
		return ;
	fi

	echo "${g_script}" > ${g_backup_dir}"/m.sh"
}

function fget_dir_all_files()
{
	if [ ! -d $1 ];then
		return 1;
	fi

	for file in `ls $1`
	do
		if [[ ${file} = "." || ${file} = ".." ]]; then
			continue;
		fi
		
		if [ -d $1/${file} ]; then
			#echo "${file} is a direction"
			fget_dir_all_files $1"/"${file}
		else
			g_all_files="${g_all_files} $1/${file}"
		fi
		
	done
	
	return 0;
}

function fextra_suffix()
{
	if [ $# -eq 0 -o "$1" == "" ];then
		echo "fextra_suffix not some thing to do"
		return -1;
	fi
	
	for file in $1
	do 
		filename=$(basename $file)
		exten=${filename##*.}
		if [ ${exten} = "$2" ]; then
			g_all_need_backup_files="${g_all_need_backup_files} ${file}"
		fi
	done
}

function is_extra_suffix()
{
	if [ $# -eq 0 -o "$1" = '' ]; then
		return -1;
	fi

	for suffix in ${g_extra_suffix}
	do
		if [ $1 = ${suffix} ];then
			return 1;
		fi
	done

	return 0;
}

function fcopy_target()
{
	if [ $# -eq 0 -o "$1" = '' ]; then
		return -1;
	fi
	
	for file in $1
	do
		if [ -d ${file} ]; then
			continue;
		fi
		
		tmpfile=${file#*/} #去除目录前缀 比如 ./
		dirpath=$(dirname $tmpfile)			  #提取路径
		filename=$(basename ${tmpfile})		  #提取文件名
		if [ ! -d $g_backup_dir/$dirpath ]; then 
			mkdir -p $g_backup_dir/$dirpath    #创建目录
		fi
		
		file_presuffix=${filename%.*}	#提取文件前缀
		file_suffix=${filename##*.}     #提取文件后缀

		is_extra_suffix ${file_suffix}
		if [ $? -eq 0 ];then
			outfile=${g_backup_dir}/${dirpath}/${filename}
			cp ${file} ${outfile}
		else		
			if [ ${file_presuffix} = ${file_suffix} ];then
				outfile=${g_backup_dir}/${dirpath}/${file_presuffix}
			else
				outfile=${g_backup_dir}/${dirpath}/"${file_presuffix}.__${file_suffix}"
			fi
			
			if [ ${outfile} -ot ${file} ]; then   #备份文件比当前文件要老， 或者备份文件不存在
				cat ${file} > ${outfile}
				echo "cat ${file} > ${outfile}"
			fi
		fi
	done
}

function fdos2unix()
{
	if [ $# -eq 0 -o "$1" = '' ]; then
		return -1;
	fi
	
	for file in $1
	do
		$(dos2unix ${file})
	done
}

function main()
{
	fget_dir_all_files .
	if [ 0 -eq ${#g_all_files} ]; then
		echo "not find any files"
		exit ;
	fi	

		
	fcopy_target "${g_all_files}"
	
	fgeneration_script_to_backup_dir
}

#start
if [ $# -gt 0 ]; then
	echo "xxxxxxxxxxx"
	if [ "$1" = "clean" ]; then
		echo "remove backup direction"
		rm -r ${g_backup_dir}
	fi	
fi
main
