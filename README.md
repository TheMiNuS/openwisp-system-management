# OpenWisP System Management Library

This Library enable functions missing in OpenWisP Controller.
* Tasks execution.
* Remote reboot order.
* Packages installation and removal.
* Firmware upgrade.
* System backup update.

To use this library with OpenWisP, include it on your system and call desired fonctions in pre or post reload hooks.
JSON Structures have to be included in your templates or directly in the device configuration using advanced mode button.

-----

## To use Firmware and Backup restore functions generate keys for your system
* usign -G -c "Your KEY Comment Here" -s secure/folder/secret.key -p public/folder/public.key 
* cp public/folder/public.key etc/opkg/keys/\`usign -F -p public/folder/public.key\`
* Include etc/opkg/keys/*key_fingerprint* in your firmware and use keys to sign firmwares and package repository used by Library.

-----

## Library Usage

### Execute Tasks Function.
#### Function Description.
Function used to run tasks on the system. Tasks are ran only once no matter it's exit code. As it's a list you can have tasks associated to your various templates.  
Each task need to have a task file to run and an order number.
* Task file variable name:        Task_File_[name of the task]
* Task odrer variable name:       Task_Order_[name of the task]

Order number is just compared and if different task request is executed (can be text or number).
* If Order number is '*' the task is executed at each call.
* To run again one time a task just update order number.  
#### Function JSON controll structure.
	{
		"system-management": [ 
		{ 
			"config_name": "system", 
			"config_value": "system", 
			"Execute_Tasks": [ 
				"MyTask_01", 
				"MyTask_02" 
			], 
			"Task_File_MyTask_01": "/tmp/my_task_01.sh", 
			"Task_File_MyTask_02": "/tmp/my_task_02.sh", 
			"Task_Order_MyTask_01": "0001", 
			"Task_Order_MyTask_02": "*", 
		} 
		]
	}

---

### Reboot Function.
#### Function Description.
Two sources of reboot possible, System-Management variables or presence of the file /tmp/reboot.request  

__For external reboot source__  
Just do a 'touch /tmp/reboot.request' in one of your script or task.  

__OpenWisP reboot source__  
As it's a list, multiple reboot sources can be possible with an individual order number for each. Order number is just compared and if different reboot will be executed.If you want to launch again an already executed reboot task, just change the reboot order value (can be text or number).  
* Reboot odrer variable name:     Reboot_Order_[name of the reboot task]
#### Function JSON controll structure.
	{
		"system-management": [ 
		{ 
			"config_name": "system", 
			"config_value": "system", 
			"Reboot_Tasks": [ 
			"MyReboot01", 
			"MyReboot02" 
			], 
			"Reboot_Order_MyReboot01": "0001", 
			"Reboot_Order_MyReboot02": "0001" 
		} 
		]
	} 

---

### Install Packages Function.
#### Function's Description.
Function called to install and check presence of a list of packages
As it's a list packages can be integrated in various templates.

#### Function JSON controll structure.
	{
		"system-management": [ 
		{ 
			"config_name": "system", 
			"config_value": "system", 
			"Needed_Packages": [ 
				"asterisk16", 
				"msmtp-nossl" 
			], 
		} 
		]
	}

---

### Remove Package Function.
#### Function Description.
Function called to remove packages and ensure their absence on the system.
As it's a list packages can be integrated in various templates.

#### Function JSON controll structure.
	{
		"system-management": [ 
		{ 
			"config_name": "system", 
			"config_value": "system", 
			"Extra_Packages": [ 
				"asterisk16", 
				"msmtp-nossl" 
			], 
		} 
		]
	}

---

### Firmware Upgrade Function.
#### Function Description.
Function to upgrade the system firmware. Can be called in Tasks to manage firmware upgrade campain with arguments or via a JSON structure in OpenWisP if no arguments are passed to it.  
Arguments to set to used it as function in your scripts
* $1: contain the target system board. Obtained with this command: cat /tmp/sysinfo/board_name or ubus call system board | grep board_name
* $2: contain the new firmware revision. Obtained with the firmware on the repository.
* $3: contain the URL of the new firmware. Install 'wget' package if your target is https:// and firmware need to be signed to ensure it's integrity.
* $4: specify 'no-backup' to launch a sysupgrade without local config backup.

#### Function JSON controll structure.
	{
		"system-management": [ 
		{ 
			"config_name": "system", 
			"config_value": "firmware", 
			"board_name": "tplink,tl-wr902ac-v3", 
			"revision": "r11208-ce6496d796", 
			"backup": "no-backup", 
			"firmware": "http://openwisp.yourserver.org/firmware/openwrt-19.07.4-ramips-mt76x8-tplink_tl-wr902ac-v3-squashfs-sysupgrade.bin" 
		}
	} 

---

### Backup Restore Function.
#### Function Description.
Function to patch the system management package. This function compare the given release in 'system-management.backup.System_Management_Version'
and if it's above the value of 'SYSTEM_MANAGEMENT_VERSION' in this library it download and restore the backup.
If you have an HTTPS URL ensure certificates are valid and 'wget' package is installed.

#### Function JSON controll structure.
	{
		"system-management": [ 
		{ 
			"config_name": "system", 
			"config_value": "backup", 
			"System_Management_Version": "2", 
			"System_Management_URL": "http://openwisp2.yourserver.org/backups/system-mgmt.tar.gz"
		} 
		]
	}

