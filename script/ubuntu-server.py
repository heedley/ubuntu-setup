import traceback
import dialog

def main():
    items = [
        ("1", "Ruby", "on"),
        ("2", "Nginx", "on"),
        ("3", "MySQL", "on"),
        ("4", "Memcache", "on"),
        ("5", "Git", "on"),
        ("6", "Subversion", "on"),
        ("7", "Postfix", "on")
    ]
    chosen = Di.checklist(text="Choose the packages you want to be installed:", choices=items)

if __name__ == "__main__":
    Di = dialog.Dialog()
    Di.add_persistent_args(["--backtitle", "Ubuntu Server Setup"])
    
    answer = Di.yesno("This script will configure your Ubuntu box. Make sure this is a fresh Ubuntu install.\n\nDo you want to continue?", width=60)
    
    if answer == Di.DIALOG_OK:
        main()