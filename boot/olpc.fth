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
[ifndef] ofw-version$
: ofw-version$  ( -- adr len )
   ofw-model$ drop 6 +  7  -trailing
;
[then]

ofw-model$ drop 3 " CL1" $= 0= if
   ." not an XO-1, turn me off" cr begin halt again
then

\ step 1, ensure firmware is updated

ofw-version$ " Q2F19" $= 0= if
   ." HaitiOS: reflashing firmware" cr
   " flash u:\boot\q2f19.rom" eval
   \ automatically reboots
then

\ step 2, make sure user wants to destroy all data

." HaitiOS: press 'y' to erase this laptop and install HaitiOS: " cr
begin  key  [char] y  =  until  .( y) cr

\ step 3, install operating system
" copy-nand u:\21021o0.img" eval
." HaitiOS: installed, customizing ..." cr

\ step 4, boot Tiny Core Linux and run xo-custom

\ set kernel command line
" fbcon=font:SUN12x22 superuser quiet showapps multivt waitusb=5 nozswap console=ttyS0,115200 console=tty0 xo-custom" to boot-file

\ choose initramfs
" last:\boot\initrd.x86" to ramdisk

\ choose kernel
" last:\boot\vmlinuz.0" to boot-device

cr
boot
