# openwisp-system-management library usage

``
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
``
