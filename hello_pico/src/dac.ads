with RP.DMA;
with RP.PIO;
-- with RP2040_SVD;
with HAL;

package Dac is

   procedure Initialize
      (Ping_Channel, Pong_Channel : RP.DMA.DMA_Channel_Id;
       Pio_Device                 : RP.PIO.PIO_Device;
       Pio_SM                     : RP.PIO.PIO_SM);

   procedure Start;

end Dac;
