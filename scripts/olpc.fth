\ OLPC boot script

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
      visible ." warning: my clock was reset to 2014, check clock battery" cr
   then
;
?fix-clock

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

[ifndef] ?ofw-reflash
\ Check for new firmware.
: ?ofw-reflash  ( -- )
   " ${DN}${PN}\bootfw.zip" expand$
   ['] (boot-read) catch  if  2drop exit  then
   img$  firmware-up-to-date?  if  exit  then
   img$ do-firmware-update
;

[then]

: set-path-macros  ( -- )
   button-o game-key?  if  " \boot-alt"  else  " \boot"  then  pn-buf place

   " /chosen" find-package  if                       ( phandle )
      " bootpath" rot  get-package-property  0=  if  ( propval$ )
         get-encoded-string                          ( bootpath$ )
         [char] \ left-parse-string  2nip            ( dn$ )
         dn-buf place                                ( )
      then
   then
;

: olpc-fth-boot-me
   set-path-macros
   ?ofw-reflash
   \ " extra kernel parameters here" to boot-file
   " ${DN}${PN}\vmlinuz"    expand$ to boot-device
   " ${DN}${PN}\initrd.img" expand$ to ramdisk
   boot
;
olpc-fth-boot-me
