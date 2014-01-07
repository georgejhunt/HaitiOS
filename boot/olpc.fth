\ filename: olpc.fth
\ HaitiOS boot script -- James Cameron
\ Full source at github.com/georgejhunt/HaitiOS

visible
." -- HaitiOS 0.6.x --" cr

\ step 0, stop if not an XO-1
[ifndef] ofw-model$
: ofw-model$  ( -- adr len )
   " /openprom" find-package drop  ( phandle )
   " model" rot get-package-property  if  ( )
      " ???   ?????  ???"          ( adr len )
   else                            ( adr len )
      decode-string 2nip           ( adr len' )
   then                            ( adr len )
;
[then]

ofw-model$ drop 3 " CL1" $= 0= if
   ." not an XO-1, turn me off" cr begin halt again
then

\ step 2, quietly fix the clock for this boot
: force-2014  ( -- )  \ set the clock to a specific date and time
   d# 0 d# 0 d# 0  d# 1 d# 1 d# 2014       ( s m h d m y )
   " set-time" clock-node @ $call-method   ( )
;
: get-year  ( -- year )  \ get the year only from the clock
   time&date 2nip 2nip nip
;
: ?fix-clock  ( -- )  \ set the clock if the year is obviously wrong
   get-year d# 2014 < if
      force-2014
   then
;
?fix-clock

\ step 3, boot Tiny Core Linux and run xo-custom

\ set kernel command line
" fbcon=font:SUN12x22 superuser quiet showapps multivt waitusb=5 nozswap console=ttyS0,115200 console=tty0 xo-custom" to boot-file

\ choose initramfs
" last:\boot\initrd.x86" to ramdisk

\ choose kernel
" last:\boot\vmlinuz.0" to boot-device

cr
boot
