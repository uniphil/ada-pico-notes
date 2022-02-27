with RP.Device;
with RP.PIO.Encoding;
with Pico;

package body Dac is
   DMA_Buffer_Size : constant Natural := 4096;
   type DMA_Buffer is array (Integer range 1 .. DMA_Buffer_Size) of HAL.UInt16;
   Transfer_Count  : constant HAL.UInt32 := HAL.UInt32 (DMA_Buffer_Size / 2);  -- DMA tranfers two values at a time (32 bits)

   Ping_Channel_Id, Pong_Channel_Id : RP.DMA.DMA_Channel_Id;
   Ping_Buffer,     Pong_Buffer     : DMA_Buffer;
   for Ping_Buffer'Alignment use DMA_Buffer_Size;
   for Pong_Buffer'Alignment use DMA_Buffer_Size;

   Pio_Dev  : RP.PIO.PIO_Device := RP.Device.PIO_0;  -- fixme: would prefer not to hardcode, but then get unconstrained subtype error.
   Pio_SM_x : RP.PIO.PIO_SM;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Ping_Channel, Pong_Channel : RP.DMA.DMA_Channel_Id;
                         Pio_Device                 : RP.PIO.PIO_Device;
                         Pio_SM                     : RP.PIO.PIO_SM)
   is

      -- pio program
      use RP.PIO.Encoding;
      R2R_Program        : constant RP.PIO.Program :=
         (1 => Encode (SHIFT_OUT' (Destination => PINS, Bit_Count => 1, others => <>)));
      R2R_Program_Offset : constant RP.PIO.PIO_Address := 0;
      R2R_Config         : RP.PIO.PIO_SM_Config := RP.PIO.Default_SM_Config;

      procedure Setup_DMA (A, B   : RP.DMA.DMA_Channel_Id;
                           A_Buff : DMA_Buffer) is
      begin
         RP.DMA.Configure
            (Channel => A,
             Config => 
               (Data_Size       => RP.DMA.Transfer_32,
                Increment_Read  => True,
                Increment_Write => False,
                Ring_Wrap       => RP.DMA.Wrap_Read,
                Trigger         => Pio_Device.DMA_TX_Trigger (Pio_SM),
                Chain_To        => B,
                others          => <>));
         RP.DMA.Start  -- configure addresses, we don't actually want to start yet
            (Channel => A,
             From    => A_Buff'Address,
             To      => Pio_Device.TX_FIFO_Address (Pio_SM),
             Count   => Transfer_Count);
         RP.DMA.Disable(Pong_Channel);  -- since we unintentionally started it
      end Setup_DMA;
   begin
      Ping_Channel_Id := Ping_Channel;
      Pong_Channel_Id := Pong_Channel;
      Pio_Dev         := Pio_Device;
      Pio_SM_x        := Pio_SM;

      Pio_Dev.Enable;
      Pio_Dev.Load (R2R_Program, R2R_Program_Offset);
      RP.PIO.Set_Out_Pins (R2R_Config, Pico.LED.Pin, 1);
      RP.PIO.Set_Wrap (R2R_Config,
            Wrap_Target => R2R_Program_Offset,
            Wrap        => R2R_Program_Offset + R2R_Program'Length);

      RP.PIO.Set_Clock_Frequency (R2R_Config, 100_000);

      Pio_Dev.SM_Initialize (Pio_SM_x,
         Initial_PC => R2R_Program_Offset,
         Config     => R2R_Config);
      Pio_Dev.Set_Pin_Direction (Pio_SM_x, Pico.LED.Pin, RP.PIO.Output);
      Pio_Dev.Set_Enabled (Pio_SM_x, True);

      for Sample of Ping_Buffer loop Sample := 0; end loop;
      for Sample of Pong_Buffer loop Sample := 0; end loop;
      RP.DMA.Enable;
      Setup_DMA(Ping_Channel, Pong_Channel, Ping_Buffer);
      Setup_DMA(Pong_Channel, Ping_Channel, Pong_Buffer);
   end Initialize;

   ----------------
   -- Start --
   ----------------

   procedure Start is
   begin
      RP.DMA.Start  -- alskdjflasdkjfk
         (Channel => Ping_Channel_Id,
          From    => Ping_Buffer'Address,
          To      => Pio_Dev.TX_FIFO_Address (Pio_SM_x),
          Count   => Transfer_Count);
   end Start;

end Dac;
