with RP.DMA; use RP.DMA;
with HAL;

package Dac is

   procedure Initialize
      (Ping_Channel, Pong_Channel : DMA_Channel_Id);

end Dac;
