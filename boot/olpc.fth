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
: ofw-version$ ( -- adr len )
   ofw-model$ drop 6 + 7 -trailing
;
[then]

ofw-model$ drop 3 " CL1" $= 0= if
   ." not an XO-1, turn me off" cr begin halt again
then

\ step 1, ensure firmware is updated
\ Q2E41 and earlier cannot boot Tiny Core Linux for various reasons

[ifndef] do-firmware-update

: do-firmware-update  ( img$ -- )

\ Keep .error from printing an input sream position report
\ which makes a buffer@<address> show up in the error message
  ['] noop to show-error

  visible

   tuck flash-buf  swap move   ( len )

   ['] ?image-valid  catch  ?dup  if    ( )
      visible
      red-letters
      ." Bad firmware image file - "  .error
      ." Continuing with old firmware" cr
      black-letters
      exit
   then

   true to file-loaded?

   d# 12,000 wait-until   \ Wait for EC to notice the battery

   ['] ?enough-power  catch  ?dup  if
      visible
      red-letters
      ." Unsafe to update firmware now - " .error
      ."  Continuing with old firmware" cr
      black-letters
      exit
   then

   " Updating firmware" ?lease-debug-cr

   ec-indexed-io-off?  if
      visible
      ." Restarting to enable SPI FLASH writing."  cr
      d# 3000 ms
      ec-ixio-reboot
      security-failure
   then

   \ Latch alternate? flag for next startup
   alternate?  if  [char] A h# 82 cmos!  then

   reflash      \ Should power-off and reboot
   show-x
   " Reflash returned, unexpectedly" .security-failure
;

[then]

[ifndef] $<
: $<  ( $1 $2 -- $1<$2 )  \ from eapol.fth
   rot drop
   >r true -rot r>
   0  ?do
      over i ca+ c@
      over i ca+ c@
      2dup =  if
	 2drop
      else
	 >  if  rot drop false -rot  then
	 leave
      then
   loop  2drop
;
[then]

: ?ht-reflash  ( -- )
   ofw-version$ " Q2E42" $< if
      ." HaitiOS: reflashing firmware" cr
      " u:\boot\bootfw.zip" (boot-read) img$ do-firmware-update
      \ automatically reboots
   then
;
?ht-reflash

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
