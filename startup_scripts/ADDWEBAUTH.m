ADDWEBAUTH ; ; 15/11/24
 s keyvalue="FAKE_KEY" ; bring these in from vault?
 s username="user"
 s userpass="password"

 s ^ICONFIG("KEY")=keyvalue
 s Y=$$TORCFOUR^EWEBRC4(userpass,^ICONFIG("KEY"))
 s ^BUSER("USER",username)=Y
 q