\ filename: olpc.fth
\ HaitiOS boot script -- James Cameron
\ Full source at github.com/georgejhunt/HaitiOS

visible
.( -- Starting HaitiOS customization --    ) cr

\ step 0, stop if not an XO-1

ofw-model$ drop 3 " CL1" $= 0= if
   ." not an XO-1, turn me off" cr begin halt again
then

\ step 1, ensure firmware is updated

ofw-version$ " Q2F19" $= 0= if
   " flash u:\boot\q2f19.rom" eval
   \ automatically reboots
then

\ step 2, ensure operating system is updated
\ currently opting to have this be 4 button initiated
\" copy-nand u:\21021o0.img" eval

\ step 3, set the clock if it year < 2014
:force-2014  ( -- )  \ set the clock to a specific date and time
   d# 19 d# 54 d# 04  d# 3 d# 01 d# 2014   ( s m h d m y )
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
\?fix-clock

\ step 4, boot Tiny Core Linux and run xo-custom

.( -- Tiny Core Linux boot script for Open Firmware    ) cr
.(    by quozl@laptop.org, 2013-07-30               -- ) cr cr

\ translate a bundle suffix string to an architecture tag string
: b>a  ( bundle$ -- architecture$ )
   drop c@ case
      [char] 0  of  " x86" exit  endof
      [char] 1  of  " x86" exit  endof
      [char] 2  of  " arm" exit  endof
      [char] 4  of  " arm" exit  endof
   endcase
;

\ translate a bundle suffix string to an serial terminal tag string
: b>s  ( bundle$ -- serialterm$ )
   drop c@ case
      [char] 0  of  " ttyS0" exit  endof
      [char] 1  of  " ttyS0" exit  endof
      [char] 2  of  " ttyS2" exit  endof
      [char] 4  of  " ttyS2" exit  endof
   endcase
;

[ifndef] bundle-suffix$
: bundle-suffix$
   " model" " /" find-package drop get-package-property 2drop c@
   case
      [char] C  of  " 0" exit  endof
      [char] D  of  " 1" exit  endof
      " 2" exit
   endcase
;
[then]

\ set macros
bundle-suffix$     " MACHINE"      $set-macro
bundle-suffix$ b>a " ARCHITECTURE" $set-macro
bundle-suffix$ b>s " SERIALTERM"   $set-macro

\ set kernel command line
" fbcon=font:SUN12x22 superuser quiet showapps multivt waitusb=5 nozswap console=${SERIALTERM},115200 console=tty0 xo-custom"                           expand$ to boot-file

\ choose initramfs
" last:\boot\initrd.${ARCHITECTURE}"   expand$ to ramdisk

\ choose kernel
" last:\boot\vmlinuz.${MACHINE}"       expand$ to boot-device

cr
boot
