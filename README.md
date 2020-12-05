# OpenWisP System Management Library

---

## First to use the Firmware and Backup restore functions generate keys
* usign -G -c "Your KEY Comment Here" -s secure/folder/secret.key -p public/folder/public.key 
* cp public/folder/public.key etc/opkg/keys/\`usign -F -p public/folder/public.key\`
* Include etc/opkg/keys/\`usign -F -p public/folder/public.key\` in your firmware and use keys to sign firmwares and files transfered with this Library.

---

## Library Usage

### Execute Tasks Function.

#### Function's Description.
Function used to run tasks on the system.
Tasks are ran only once no matter it's exit code.
As it's a list you can have tasks associated to your various templates.
Each task need to have a task file to run and an order number.
     Task file variable name:        Task_File_[name of the task]
     Task odrer variable name:       Task_Order_[name of the task]
Order number is just compared and if different task request is executed (can be text or number).

If Order number is '*' the task is executed at each call.
To run again one time a task just update order number.

#### Function's JSON controll structure.
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

### Reboot Function.

### Install Packages Function.

### Remove Package Function.

### Firmware Upgrade Function.

### Backup Restore Function.



`
{
    "system-management": [
        {
            "config_name": "system",
            "config_value": "system",
            "Extra_Packages": [
                "extra_package_01",
                "extra_package_02"
            ],
            "Needed_Packages": [
                "asterisk16",
                "msmtp-nossl"
            ],
            "Execute_Tasks": [
                "My_Task_01",
                "My_Task_02"
            ],
            "Task_File_My_Task_01": "/tmp/my_task_01.sh",
            "Task_File_My_Task_02": "/tmp/my_task_02.sh",
            "Task_Order_My_Task_01": "0002",
            "Task_Order_My_Task_02": "0002",
            "Reboot_Tasks": [
                "My_Reboot_01",
                "My_Reboot_02"
            ],
            "Reboot_Order_My_Reboot_01": "0001",
            "Reboot_Order_My_Reboot_02": "0001"
        }
    ]
}
`
