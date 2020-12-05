#!/bin/sh
############################################
# Copyright (C) 24/10/2020 - Brice GIBOUDEAU
#
# Libraries to manage system with OpenWisP
############################################
#
. /usr/share/libubox/jshn.sh 
#
SYSTEM_MANAGEMENT_VERSION=2
#
#Functions.
#
#
#
is_opkg_locked()
{
	if [ -f "/var/lock/opkg.lock" ]
	then
		Log_Error "System-Management: opkg is Locked"
		exit 2
	fi
}
#
#
#
is_system_management_records_available()
{
	#After a fresh install system-management-records doesn't exist. Call this function before trying to touch it's content to ensure it's presence.
	uci show system-management-records > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo "config system 'system'" | uci import system-management-records
		uci commit system-management-records	
	fi
}
#
#
#
# $1 = Source file URL (must contain a file $1.sig to check integrity of file)
# $2 = Target file for download
download_and_check_signature()
{
	#Download a file and check it's signature validity.
	local RETURN_CODE=0
	local URL="$1"
	local DST="$2"
	local KEYS_REPO="/etc/opkg/keys"
	
	if [ ! -z $URL ] && [ ! -z $DST ]
	then
		if wget -q $URL -O $DST > /dev/null 2>&1
		then
			if wget $URL.sig  -O $DST.sig > /dev/null 2>&1
			then
				if usign -V -m $DST -s $DST.sig -P $KEYS_REPO > /dev/null 2>&1
				then
					RETURN_CODE=0
					rm $DST.sig
				else
					RETURN_CODE=1
					rm $DST.sig
					rm $DST
				fi
			else
				RETURN_CODE=1
				rm $DST
				rm $DST.sig
			fi
		else
			RETURN_CODE=1
			rm $DST
		fi
	fi

	return $RETURN_CODE
}
#
#
#
# System Log functions.
# Verbosity can be controlled via the JSON Structure below.
#	0: No logging at all.
#	1: Errors only.
#	2: Warnings and Errors.
#	3: Informations (debug messages), Warnings and Errors.
#
#	"system-management": [ 
#	{ 
#		"config_name": "system", 
#		"config_value": "system", 
#		"Logger_verbosity": 3, 
#	} 
#	]  
#
Log_Warn()
{
DEBUG_LEVEL=`uci get system-management.system.Logger_verbosity` > /dev/null 2>&1
case $DEBUG_LEVEL in
	2|3)
		logger -t system-management -p daemon.4 -s $*
		;;
	0|1)
		;;
	*)
		logger -t system-management -p daemon.4 -s $*
		;;
esac
}
#
#
#
Log_Error()
{
DEBUG_LEVEL=`uci get system-management.system.Logger_verbosity` > /dev/null 2>&1
case $DEBUG_LEVEL in
	1|2|3)
		logger -t system-management -p daemon.3 -s $*
		;;
	0)
		;;
	*)
		logger -t system-management -p daemon.3 -s $*
		;;
esac
}
#
#
#
Log_Info()
{
DEBUG_LEVEL=`uci get system-management.system.Logger_verbosity` > /dev/null 2>&1
case $DEBUG_LEVEL in
	3)
		logger -t system-management -p daemon.6 -s $*
		;;
	0|1|2)
		;;
	*)
		;;
esac
}
#
#
#
# Two sources of reboot possible, System-Management variables or presence of the file /tmp/reboot.request
#
# Usage:
# For external reboot source
# 	Just do a 'touch /tmp/reboot.request' in one of your script or task.
#
# OpenWisP reboot source.
#	As it's a list, multiple reboot sources can be possible with an individual order number for each.
#	Order number is just compared and if different reboot will be executed.
#	If you want to launch again an already executed reboot task, just change the reboot order value (can be text or number).
#		Reboot odrer variable name: 	Reboot_Order_[name of the reboot task]
#
# Exemple of JSON structure to call 2 different reboots.
#	"system-management": [ 
#	{ 
#		"config_name": "system", 
#		"config_value": "system", 
#		"Reboot_Tasks": [ 
#			"MyReboot01", 
#			"MyReboot02" 
#		], 
#		"Reboot_Order_MyReboot01": "0001", 
#		"Reboot_Order_MyReboot02": "0001" 
#	} 
#	] 
#
Do_I_Need_To_Reboot()
{
	#Launch a reboot order coming from OpenWisP controller
	is_system_management_records_available
	REBOOT_FLAG=0
	REBOOT_TASKS=`uci get system-management.system.Reboot_Tasks` > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		Log_Info "Empty value: system-management.system.Reboot_Tasks"
	else
		for TASK in $REBOOT_TASKS
		do
			REBOOT_ORDER=`uci get system-management.system.Reboot_Order_$TASK` > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				Log_Error "You want to launch a reboot task: $TASK, without an order number specified"
			else
				EXECUTED_REBOOT_ORDER=`uci get system-management-records.system.Executed_Reboot_Order_$TASK` > /dev/null 2>&1
				if [ "$REBOOT_ORDER" = "$EXECUTED_REBOOT_ORDER" ]
				then
					Log_Info "Reboot Task Already Executed: $TASK"
				else
					Log_Info "Execute Reboot Task: $TASK"
					uci set system-management-records.system.Executed_Reboot_Order_$TASK="$REBOOT_ORDER"
					uci commit system-management-records
					REBOOT_FLAG=1
				fi
			fi
		done
	fi
	#
	#Launch a reboot order coming from an external source (Script)
	if [ -f "/tmp/reboot.request" ]
	then
		Log_Info "System-Management: Externel reboot requested"
		rm /tmp/reboot.request
		REBOOT_FLAG=1
	fi
	#
	#Executing reboot.
	if [ $REBOOT_FLAG -ge 1 ]
	then
		Log_Warn "Rebooting on request in 5 seconds"
		/sbin/reboot -d 5
	fi
}
#
#
#
# Function called to install and check presence of a list of packages
# As it's a list packages can be integrated in various templates.
# Exemple of a Json structure to install two packages.
#	"system-management": [ 
#	{ 
#		"config_name": "system", 
#		"config_value": "system", 
#		"Needed_Packages": [ 
#			"asterisk16", 
#			"msmtp-nossl" 
#		], 
#	} 
#	]
# 
Install_Packages_fct()
{
	NEEDED_PACKAGES=`uci get system-management.system.Needed_Packages` > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		Log_Info "Empty value: system-management.system.Needed_Packages"
	else
		for PACKAGE in $NEEDED_PACKAGES
		do
			is_opkg_locked
			STATUS=`/bin/opkg list-installed $PACKAGE | /usr/bin/wc -l`
			if [ $STATUS -ge 1 ]
			then
				#Packages installed
				Log_Info "$PACKAGE: already installed."
			else
				#Package missing
				Log_Warn "$PACKAGE: missing."
				is_opkg_locked
				STATUS=`/bin/opkg list $PACKAGE | /usr/bin/wc -l`
				if [ $STATUS -ge 1 ]
				then
					#No need to update packages list.
					Log_Info "No need to update packages list"
					is_opkg_locked
					/bin/opkg install $PACKAGE
					if [ $? -ne 0 ]
					then 
						Log_Error "System-management: Requested package present but impossible to install"
					fi
				else
					#Need to upgrade packages list.
					Log_Info "Need to update package list"
					is_opkg_locked
					/bin/opkg update
					is_opkg_locked
					/bin/opkg install $PACKAGE
					if [ $? -ne 0 ]
					then 
						Log_Error "System-management: Requested package not present in package list - Typo ?"
					fi
				fi
			fi
		done
	fi
}
#
#
#
# Function called to remove packages and ensure their absence on the system.
# As it's a list packages can be integrated in various templates.
# Exemple of a Json structure to remove two packages.
#	"system-management": [ 
#	{ 
#		"config_name": "system", 
#		"config_value": "system", 
#		"Extra_Packages": [ 
#			"asterisk16", 
#			"msmtp-nossl" 
#		], 
#	} 
#	]
# 
Remove_Packages_fct()
{
	EXTRA_PACKAGES=`uci get system-management.system.Extra_Packages` > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		Log_Info "Empty value: system-management.system.Extra_Packages"
	else
		for PACKAGE in $EXTRA_PACKAGES
		do
			is_opkg_locked
			STATUS=`/bin/opkg list-installed $PACKAGE | /usr/bin/wc -l`
			if [ $STATUS -ge 1 ]
			then
				#Packages installed
				Log_Warn "$PACKAGE: removing."
				is_opkg_locked
				/bin/opkg remove $PACKAGE
				if [ $? -ne 0 ]
				then 
					Log_Error "System-management: Failed to remove Package"
				fi
			else
				#Package missing
				Log_Info "$PACKAGE: already removed."
			fi
		done
	fi
}
#
#
#
# Function used to run tasks on the system.
# Tasks are ran only once no matter it's exit code.
# As it's a list you can have tasks associated to your various templates.
# Each task need to have a task file to run and an order number.
#	Task file variable name: 	Task_File_[name of the task]
#	Task odrer variable name: 	Task_Order_[name of the task]
# Order number is just compared and if different task request is executed (can be text or number).
# If Order number is '*' the task is executed at each call.
# To run again a task just update order number.
# 
# Below an exemple of the JSON Structure to use it.
#	"system-management": [ 
#	{ 
#		"config_name": "system", 
#		"config_value": "system", 
#		"Execute_Tasks": [ 
#			"MyTask_01", 
#			"MyTask_02" 
#		], 
#		"Task_File_MyTask_01": "/tmp/my_task_01.sh", 
#		"Task_File_MyTask_02": "/tmp/my_task_02.sh", 
#		"Task_Order_MyTask_01": "0001", 
#		"Task_Order_MyTask_02": "0001", 
#	} 
#	]
#
Execute_Tasks_fct()
{
	is_system_management_records_available
	EXECUTE_TASKS=`uci get system-management.system.Execute_Tasks` > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
	        Log_Info "Empty value: system-management.system.Execute_Tasks"
	else
		for TASK in $EXECUTE_TASKS
		do
			TASK_ORDER=`uci get system-management.system.Task_Order_$TASK` > /dev/null 2>&1
			if [ $? -ne 0 ]
			then
				Log_Error "You want to launch a task: $TASK, without an order number specified"
			else
				EXECUTED_TASK_ORDER=`uci get system-management-records.system.Executed_Task_Order_$TASK` > /dev/null 2>&1
				if [ "$TASK_ORDER" = "$EXECUTED_TASK_ORDER" ]
				then
					Log_Info "Task Already Executed: $TASK"
				else
					Log_Info "Execute Task: $TASK"
					TASK_FILE=`uci get system-management.system.Task_File_$TASK` > /dev/null 2>&1
					if [ $? -ne 0 ]
					then
						Log_Error "You want to run task without file specified in Task_File !"
					else
						if [ -f $TASK_FILE ]
						then
							Log_Info "Launching task: $TASK_FILE"
							if [ "$TASK_ORDER" = "*" ]
							then
								uci set system-management-records.system.Executed_Task_Order_$TASK="recurring"
								uci commit system-management-records
							else
								uci set system-management-records.system.Executed_Task_Order_$TASK="$TASK_ORDER"
								uci commit system-management-records
							fi
							/bin/sh $TASK_FILE
							if [ $? -ne 0 ]
							then
								Log_Error "Task $TASK_FILE exited with errors will not run again"
							else
								Log_Info "Task $TASK_FILE run properly and is considered applied by system"
							fi
						else
							Log_Error "You want to launch a script $TASK_FILE not present on the system"
						fi
					fi
			
				fi
			fi
		done
	fi
}
#
#
#
# Function to upgrade the system firmware. Can be called in Tasks to manage firmware upgrade campain with arguments or via a JSON structure in OpenWisP if no arguments are passed to it.
#
#	Arguments to set to used it as function in your scripts
# 	$1: contain the target system board. Obtained with this command: cat /tmp/sysinfo/board_name or ubus call system board | grep board_name
#	$2: contain the new firmware revision. Obtained with the firmware on the repository.
#	$3: contain the URL of the new firmware. Install 'wget' package if your target is https:// and firmware need to be signed to ensure it's integrity.
#	$4: specify 'no-backup' to launch a sysupgrade without local config backup.
#
#	Below an exemple of the JSON Structure to use with OpenWisP pre or post reload. Just call the function without arguments.
#	"system-management": [ 
#	{ 
#		"config_name": "system", 
#		"config_value": "firmware", 
#		"board_name": "tplink,tl-wr902ac-v3", 
#		"revision": "r11208-ce6496d796", 
#		"backup": "no-backup", 
#		"firmware": "http://openwisp.yourserver.org/firmware/openwrt-19.07.4-ramips-mt76x8-tplink_tl-wr902ac-v3-squashfs-sysupgrade.bin" 
#	} 
#	]
#
#
#
Firmware_Upgrade_fct()                                        
{
	local system_board=$1
	local new_firmware_revision=$2
	local system_board_firmware=$3
	local no_backup=$4

	if [ -z $system_board ] && [ -z $new_firmware_revision ] && [ -z $system_board_firmware ]
	then
		Log_Info "Firmware upgrade: UCI mode getting version from system-management.firmware"
		system_board=`uci get system-management.firmware.board_name` > /dev/null 2>&1
		new_firmware_revision=`uci get system-management.firmware.revision` > /dev/null 2>&1
		system_board_firmware=`uci get system-management.firmware.firmware` > /dev/null 2>&1
		no_backup=`uci get system-management.firmware.backup` > /dev/null 2>&1
	fi

	if [ ! -z $system_board ] && [ ! -z $new_firmware_revision ] && [ ! -z $system_board_firmware ]
	then
		json_init
		json_load "`ubus call system board`"
		json_get_var board_name board_name
		json_select release
		json_get_var version version
		json_get_var revision revision
		if [ "$board_name" = "$system_board" ]
		then
			if [ "$version" = "$new_firmware_version" ] && [ "$revision" = "$new_firmware_revision" ]
			then
				Log_Warn "Firmware upgrade: I'm a board $system_board already at $new_firmware_revision"
			else
				if download_and_check_signature $system_board_firmware /tmp/new_firmware.bin
				then
					case $no_backup in
   						no-backup)
							Log_Warn "Firmware upgrade: Flashing board $system_board with firmware $system_board_firmware without config backup"
							sysupgrade -n /tmp/new_firmware.bin
							;;
						*)
							Log_Warn "Firmware upgrade: Flashing board $system_board with firmware $system_board_firmware with config backup"
							sysupgrade /tmp/new_firmware.bin
							;;
					esac
				else
					Log_Error "Firmware upgrade: Failed to download the firmware $system_board_firmware and check it's signature"
				fi
			fi

		else
			Log_Info "Firmware upgrade: I'm not a $system_board"
		fi
	else
		Log_Warn "Firmware upgrade: Calling Test_and_Flash_Me without enough arguments"
	fi
}
#
#
#
# Function to patch the system management package. This function compare the given release in 'system-management.backup.System_Management_Version'
# and if it's above the value of 'SYSTEM_MANAGEMENT_VERSION' in this library it download and restore the backup.
# If you have an HTTPS URL ensure certificates are valid and 'wget' package is installed.
#
# Below an exemple of the JSON Structure to use it.
#	"system-management": [ 
#	{ 
#		"config_name": "system", 
#		"config_value": "backup", 
#		"System_Management_Version": "2", 
#		"System_Management_URL": "http://openwisp2.yourserver.org/backups/system-mgmt.tar.gz"
#	} 
#	]
#
Backup_Upgrade_fct()
{
	local new_system_management_version
	local new_system_management_url
	new_system_management_version=`uci get system-management.backup.System_Management_Version`  > /dev/null 2>&1
	new_system_management_url=`uci get system-management.backup.System_Management_URL`  > /dev/null 2>&1

	if [ ! -z $new_system_management_version ] && [ ! -z $new_system_management_url ]
	then
		if [ "$new_system_management_version" -gt "$SYSTEM_MANAGEMENT_VERSION" ]
		then
			if download_and_check_signature $new_system_management_url /tmp/new-system-management.tar.gz
			then
				Log_Warn "Upgrading System-Management to version $new_system_management_version from URL $new_system_management_url"
				sysupgrade -r /tmp/new-system-management.tar.gz
			else
				Log_Error "Update_System_Management: Failed to download and check signature"
			fi
		else
			Log_Warn "Update_System_Management: Already up to date"
		fi
	else
		Log_Info "Update_System_Management: No new version available"
	fi
}
#
#
#
# END OF LIB File
