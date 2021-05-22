
with Ada.Text_IO; use Ada.Text_IO;

with Fmod_Common;
with Fmod;

package body Audio_Manager is

   Audio    : Fmod.F_System;

   --  -------------------------------------------------------------------------

   procedure Init is
      use Fmod_Common;
      F_Result : Fmod_Result;
   begin
      F_Result := Fmod.System_Create (Audio);
      if F_Result = Fmod_Ok then
         Put_Line ("Audio_Manager.Init audio system created");
      end if;
   end Init;

   --  -------------------------------------------------------------------------

end Audio_Manager;
