package body PIO_Hi is

   procedure Go is
   begin
      RP.Clock.Initialize (Pico.XOSC_Frequency);
      Pico.LED.Configure (RP.GPIO.Output, RP.GPIO.Floating, P.GPIO_Function);

      P.Enable;
      P.Load (Blink_Program, Program_Offset);

      Set_Out_Pins (Config, Pico.LED.Pin, 1);
      Set_Set_Pins (Config, Pico.LED.Pin, 1);
      Set_Wrap (Config,
         Wrap_Target => Program_Offset,
         Wrap        => Program_Offset + Blink_Program'Length);
      Set_Clock_Frequency (Config, 50_000_000);
      Set_Out_Shift (Config,
         Shift_Right    => True,
         Autopull       => True,
         Pull_Threshold => 1);

      P.SM_Initialize (SM,
         Initial_PC => Program_Offset,
         Config     => Config);
      P.Set_Pin_Direction (SM, Pico.LED.Pin, Output);
      P.Set_Enabled (SM, True);

      RP.Device.Timer.Enable;
      loop
         P.Put (SM, 1);
         RP.Device.Timer.Delay_Milliseconds (300);
         P.Put (SM, 0);
         RP.Device.Timer.Delay_Milliseconds (300);
      end loop;
   end Go;

end PIO_Hi;
