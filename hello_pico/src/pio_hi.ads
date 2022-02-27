with RP.PIO.Encoding; use RP.PIO.Encoding;
with RP.PIO; use RP.PIO;
with RP.Device;
with RP.Clock;
with RP.GPIO;
with Pico;

package PIO_Hi is
   Blink_Program : constant RP.PIO.Program :=
      (1 => Encode (SHIFT_OUT'  (Destination => PINS, Bit_Count => 1, others => <>)));
   Program_Offset : constant PIO_Address := 0;
   SM             : constant PIO_SM := 0;
   Config         : PIO_SM_Config := Default_SM_Config;
   P              : PIO_Device renames RP.Device.PIO_0;

   procedure Go;

end PIO_Hi;
