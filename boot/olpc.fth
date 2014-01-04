\ olpc.fth
visible
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
