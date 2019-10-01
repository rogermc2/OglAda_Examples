

with Ada.Numerics.Float_Random;
with Ada.Text_IO; use Ada.Text_IO;

with GL.Objects.Textures.Targets;
with GL.Pixels;

package body Random_Texture is

   procedure Init_Random_Texture (aTexture : in out GL.Objects.Textures.Texture;
                                  Size : GL.Types.UInt) is
      use Ada.Numerics.Float_Random;
      use GL.Objects.Textures.Targets;
      use GL.Types;
      Gen           : Generator;
      Random_Data   : Singles.Vector3_Array (1 .. Int (Size));
   begin
      for index in Random_Data'Range loop
         Random_Data (index) := (Single (Random (Gen)), Single (Random (Gen)),
                                 Single (Random (Gen)));
      end loop;

      aTexture.Initialize_Id;
      Texture_1D.Bind (aTexture);
      Texture_1D.Load_From_Data
        (Level           => 0,
         Internal_Format => GL.Pixels.RGB,
         Width           => GL.Types.Int (Size),
         Source_Format   => GL.Pixels.RGB,
         Source_Type     => GL.Pixels.Float,
         Source          => GL.Objects.Textures.Image_Source (Random_Data'Address));

      Texture_1D.Set_Minifying_Filter (GL.Objects.Textures.Linear);
      Texture_1D.Set_Magnifying_Filter (GL.Objects.Textures.Linear);
      Texture_2D.Set_X_Wrapping (GL.Objects.Textures.Repeat); --  Wrap_S

   exception
      when  others =>
         Put_Line ("An exception occurred in Random_Texture.Init_Random_Texture.");
         raise;
   end Init_Random_Texture;

   --  ------------------------------------------------------------------------

   procedure  Bind (aTexture : in out GL.Objects.Textures.Texture;
                    Texture_Unit : GL.Objects.Textures.Texture_Unit) is
   use GL.Objects.Textures;
   begin
      Set_Active_Unit (Texture_Unit);
      Targets.Texture_1D.Bind (aTexture);
   end Bind;

   --  ------------------------------------------------------------------------

end Random_Texture;
