
with GL.Types; use GL.Types;

with Menu_Strings;

package Settings is

   type V_GL is (V2_1, V3_2);
   for V_GL use (V2_1 => 0,
                 V3_2 => 1);
   subtype Audio_Volume_Range is Integer range 0 .. 10;
   type Settings_Data is private;

   function Anisotroic_Texturing_Factor return Integer;
   function Audio_Volume return Integer;
   function Auto_Blood_Wipe return Boolean;
   procedure Default_Settings;
   function Far_Clip return GL.Types.Single;
   function Fb_Effects_Enabled return Boolean;
   function Framebuffer_Height return GL.Types.Int;
   function Framebuffer_Width return GL.Types.Int;
   function Full_Screen return Boolean;
   function Graphic_Preset return Menu_Strings.Graphic_Preset_Choice_Type;
   function Hide_GUI return Boolean;
   function Joystick_Disabled return Boolean;
   procedure Load_Settings;
   function Multi_Sample_Anti_Aliasing return Integer;
   function Music_Volume return Audio_Volume_Range;
   function Particle_Mipmaps_Enabled return Boolean;
   function Particles_Enabled return Boolean;
   function Render_OLS return Boolean;
   function Render_Distance return Integer;
   function Save_Settings return Boolean;
   procedure Set_Aniso (Val : Integer);
   procedure Set_Audio_Volume (Volume : Integer);
   procedure Set_Autoblood_Wipe (State : Boolean);
   procedure Set_Disable_Joystick (State : Boolean);
   procedure Set_Far_Clip (Distance : Single);
   procedure Set_FB_Effects_Enabled (State : Boolean);
   procedure Set_Framebuffer_Height (Height : GL.Types.Int);
   procedure Set_Framebuffer_Width (Width : GL.Types.Int);
   procedure Set_Full_Screen (State : Boolean);
   procedure Set_Graphic_Preset (Preset : Menu_Strings.Graphic_Preset_Choice_Type);
   procedure Set_MSAA (Val : Integer);
   procedure Set_Music_Volume (Volume : Integer);
   procedure Set_Render_Distance (Distance : Integer);
   procedure Set_Render_OLS (Set : Boolean);
   procedure Set_Shadows_Enabled (State : Boolean);
   procedure Set_Shadow_Size (Val : Integer);
   procedure Set_Show_FPS (State : Boolean);
   procedure Set_SSAA (Val : Float);
   procedure Set_TexF (Val : Integer);
   procedure Set_V_Sync (State : Boolean);
   procedure Set_Window_Height (Height : Integer);
   procedure Set_Window_Height_To_Save (Height : Integer);
   procedure Set_Window_Width (Width : Integer);
   procedure Set_Window_Width_To_Save (Width : Integer);
   function Shadows_Enabled return Boolean;
   function Show_FPS return Boolean;
   function Shadows_Size return Integer;
   function Super_Sample_Anti_Aliasing return Single;
   function Texture_Filter return Integer;
   function Texture_Filtering return Integer;
   function Tile_Batch_Width return Integer;
   function Video_Record_Mode return Boolean;
   function V_Sync return Boolean;
   function Window_Height_To_Save return Integer;
   function Window_Width_To_Save return Integer;
private

   type Settings_Data is record
      Joy_Axis_Thresh              : Float := 0.5;
      Gfx_Presets                  : Menu_Strings.Graphic_Preset_Choice_Type :=
                                       Menu_Strings.Graphic_Preset_Dire;
--                                         Menu_Strings.Graphic_Preset_Medium;
      GL_Version                   : V_GL := V3_2;
      GL_Version_To_Save           : V_GL := V3_2;
      Allow_Rand_Pitch             : Boolean := False;
      Full_Screen                  : Boolean := False;
      --  lock drawing to monitor's vertical synch i.e. 60Hz
      GL_Window_Width              : Integer := 1024;
      GL_Window_Height             : Integer := 768;
      GL_Window_Width_To_Save      : Integer := 1024;
      GL_Window_Height_To_Save     : Integer := 768;
      GL_Framebuffer_Width         : Int := 512;
      GL_Framebuffer_Height        : Int := 512;
      --  Built-in multi-sample anti-aliasing. Not used much if using FB FX
      Multi_Sample_Anti_Aliasing   : Integer := 4;
      Shadow_Size                  : Integer := 512;
      Super_Sample_Anti_Aliasing   : Float := 2.0;
      --  Texture filtering nearest = 0, bilinear, trilinear
      Texture_Filtering            : Integer := 2;
      Anisotroic_Texturing_Factor  : Integer := 1;  -- 1 to 16
      --  Maximum rendering distance in tiles from player
      Render_Distance              : Integer := 15;  --  orig 15
      Far_Clip                     : Single := 40.0;
      --  Number of tiles*tiles to put in batches
      Tile_Batch_Width             : Integer := 8;
      Texf                         : Integer := 2;
      Audio_Volume                 : Audio_Volume_Range := 5;
      Music_Volume                 : Audio_Volume_Range := 5;
      Render_Dist                  : Integer := 15;
      Disable_Joystick             : Boolean := True;
      Joy_Axis_Threshold           : Float := 0.0;
      Show_Fps                     : Boolean := False;
      Video_Record_Mode            : Boolean := False;
      Render_OLS                   : Boolean := True;
      Shadows_Enabled              : Boolean := True;
      Fb_Effects_Enabled           : Boolean := True;
      Particles_Enabled            : Boolean := True;
      Particle_Mipmaps_Enabled     : Boolean := True;
      Auto_Blood_Wipe              : Boolean := False;
      V_Sync                       : Boolean := True;
      Hide_Gui                     : Boolean := False;
   end record;

end Settings;
