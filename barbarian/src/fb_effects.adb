
with Ada.Text_IO; use Ada.Text_IO;

with GL.Attributes;
with GL.Buffers;
with GL.Objects.Buffers;
with GL.Objects.Framebuffers;
with GL.Objects.Programs;
with GL.Objects.Renderbuffers;
with GL.Objects.Textures;
with GL.Objects.Textures.Targets;
with GL.Objects.Vertex_Arrays;
with GL.Pixels;
with GL.Types.Colors;
with GL.Window;

with Utilities;

with Game_Utils;
with GL_Utils;
with Settings;
with Shader_Attributes;
with FB_Default_Shader_Manager;
with FB_Gold_Shader_Manager;
with FB_Red_Shader_Manager;
with FB_Fadein_Shader_Manager;
with FB_Fadeout_Shader_Manager;
with FB_Screw_Shader_Manager;
with FB_Grey_Shader_Manager;
with FB_White_Shader_Manager;
with FB_Green_Shader_Manager;

package body FB_Effects is
   use GL.Types;

   Grey                    : constant Colors.Color := (0.6, 0.6, 0.6, 1.0);
   Num_Shader_Effects      : constant Integer := 9;
   FB_Effect_Elapsed       : Single := 0.0;
   Ww_Fb_Current_Effect    : FB_Effect := FB_Default_Effect;
   Ww_Fb_Effect_Elapsed    : Float := 0.0;
   FB_Screw_Factor         : Single := 0.0;
   Curr_Ssaa               : Single := 1.0;

   FB_VAO               : GL.Objects.Vertex_Arrays.Vertex_Array_Object;
   FB_Texture           : GL.Objects.Textures.Texture;
   --  g_fb:
   Special_FB           : GL.Objects.Framebuffers.Framebuffer;
   WW_FB                : GL.Objects.Framebuffers.Framebuffer;
   WW_FB_Texture        : GL.Objects.Textures.Texture;
   FB_Current_Effect    : FB_Effect := FB_Default_Effect;
   FB_Shader_Programs   : array (FB_Effect'Range) of
     GL.Objects.Programs.Program;

   FB_Durations         : constant array (FB_Effect'Range) of Single :=
                            (0.0,    --  default
                             0.25,   --  gold (was 1.0 / 2.0 * 0.5 -- wth?)
                             0.17,   --  red (was 1.0 / 3.0 * 0.5 -- ?)
                             2.0,    --  fadein
                             2.0,    --  fadeout
                             5.0,    --  screw
                             10.0,   --  greyscale
                             1.0,    --  white flash
                             0.25);  --  green

   FB_Expires           : constant array (FB_Effect'Range) of Boolean :=
                            (False, --  Default
                             True,  --  Gold
                             True,  --  Red
                             True,  --  Fade In
                             True,  --  Fade Out
                             False, --  Screw
                             False, --  Grey
                             True,  --  White
                             True); --  Green

   --  -------------------------------------------------------------------------

   procedure Bind_Main_Scene_FB is
      use GL.Types;
      use GL.Objects.Framebuffers;
   begin
      if Settings.Fb_Effects_Enabled then
         Read_And_Draw_Target.Bind  (Special_FB);
         GL.Window.Set_Viewport
           (0, 0, Int (Single (Settings.Framebuffer_Width) * Curr_Ssaa),
            Int (Single (Settings.Framebuffer_Height) * Curr_Ssaa));
      else
         Read_And_Draw_Target.Bind (Default_Framebuffer);
         GL.Window.Set_Viewport
           (0, 0, Int (Single (Settings.Framebuffer_Width)),
            Int (Single (Settings.Framebuffer_Height)));
      end if;
   end Bind_Main_Scene_FB;

   --  -------------------------------------------------------------------------

   function Current_SSAA return GL.Types.Single is
   begin
      return Curr_Ssaa;
   end Current_SSAA;

   --  -------------------------------------------------------------------------

   procedure Draw_FB_Effects (Delta_Time : GL.Types.Single) is
      use GL.Objects.Framebuffers;
      use GL.Objects.Textures.Targets;
      Wibbly_Pass : Boolean := False;
   begin
      if Settings.Fb_Effects_Enabled then
         FB_Effect_Elapsed := FB_Effect_Elapsed + Delta_Time;
         Ww_Fb_Effect_Elapsed := Ww_Fb_Effect_Elapsed + Float (Delta_Time);
         Wibbly_Pass := Ww_Fb_Current_Effect /= FB_Default_Effect;
         if Wibbly_Pass then
           Read_And_Draw_Target.Bind (WW_FB);
         else
           Read_And_Draw_Target.Bind (Default_Framebuffer);
         end if;

         GL.Window.Set_Viewport (0, 0, Settings.Framebuffer_Width,
                                 Settings.Framebuffer_Height);
         Utilities.Clear_Background_Colour_And_Depth (Grey);
         GL.Objects.Textures.Set_Active_Unit (0);
         Texture_2D.Bind (FB_Texture);
      end if;

      GL.Objects.Programs.Use_Program (FB_Shader_Programs (FB_Current_Effect));
      if FB_Expires (FB_Current_Effect) and
        FB_Effect_Elapsed > FB_Durations (FB_Current_Effect) then
         FB_Current_Effect := FB_Default_Effect;
      end if;

      case FB_Current_Effect is
         when FB_Gold_Flash_Effect =>
            FB_Gold_Shader_Manager.Set_Time (FB_Effect_Elapsed);
         when FB_Red_Flash_Effect =>
            FB_Red_Shader_Manager.Set_Time (FB_Effect_Elapsed);
         when FB_Fadein_Effect =>
            FB_Fadein_Shader_Manager.Set_Time (FB_Effect_Elapsed);
         when FB_Fadeout_Effect =>
            FB_Fadeout_Shader_Manager.Set_Time (FB_Effect_Elapsed);
         when FB_White_Flash_Effect =>
            FB_White_Shader_Manager.Set_Time (FB_Effect_Elapsed);
         when FB_Green_Flash_Effect =>
            FB_Green_Shader_Manager.Set_Time (FB_Effect_Elapsed);
         when others => null;
      end case;
      Put_Line ("FB_Effects.Draw_FB_Effects 2a");

      GL_Utils.Bind_VAO (FB_VAO);
      Put_Line ("FB_Effects.Draw_FB_Effects Draw_Arrays 1");
      GL.Objects.Vertex_Arrays.Draw_Arrays (Triangles, 0, 6);

      Put_Line ("FB_Effects.Draw_FB_Effects 3");
      GL.Objects.Textures.Set_Active_Unit (0);
      if Wibbly_Pass then
         Read_And_Draw_Target.Bind (Default_Framebuffer);
         Utilities.Clear_Colour_Buffer_And_Depth;
         Texture_2D.Bind (WW_FB_Texture);

      Put_Line ("FB_Effects.Draw_FB_Effects 4");
         GL.Objects.Programs.Use_Program (FB_Shader_Programs (FB_Current_Effect));
         if FB_Expires (FB_Current_Effect) and
           FB_Effect_Elapsed > FB_Durations (FB_Current_Effect) then
            FB_Current_Effect := FB_Default_Effect;
         end if;
         if Ww_Fb_Current_Effect = FB_Screw_Effect then
            FB_Screw_Shader_Manager.Set_Time (FB_Effect_Elapsed);
            FB_Screw_Shader_Manager.Set_Force (FB_Screw_Factor);
            GL.Objects.Vertex_Arrays.Draw_Arrays (Triangles, 0, 6);

            if FB_Screw_Factor < 0.1 then
               FB_Current_Effect := FB_Default_Effect;
            end if;
         end if;
      end if;

   end Draw_FB_Effects;

   --  -------------------------------------------------------------------------

   procedure Init (Width, Height : Integer) is
      use GL.Attributes;
      use GL.Buffers;
      use GL.Objects.Framebuffers;
      use GL.Objects.Renderbuffers;
      use GL.Objects.Textures.Targets;
      use Shader_Attributes;
      Points       : constant Singles.Vector2_Array (1 .. 6) :=
                       ((-1.0, -1.0),
                        ( 1.0,  1.0),
                        (-1.0,  1.0),
                        (-1.0, -1.0),
                        ( 1.0, -1.0),
                        ( 1.0,  1.0));

      Draw_Buffers : Explicit_Color_Buffer_List (1 .. 1);
      VBO          : GL.Objects.Buffers.Buffer;
      FB_Width     : constant Int := Int (Curr_Ssaa * Single (Width));
      FB_Height    : constant Int := Int (Curr_Ssaa * Single (Height));
      RB           : Renderbuffer;
   begin
      Game_Utils.Game_Log ("---INIT FRAMEBUFFER---");
      Draw_Buffers (1) := Color_Attachment0;
      Curr_Ssaa := Settings.Super_Sample_Anti_Aliasing;

      Special_FB.Initialize_Id;
      Read_And_Draw_Target.Bind (Special_FB);

      RB.Initialize_Id;
      Active_Renderbuffer.Bind (RB);
      Active_Renderbuffer.Allocate (GL.Pixels.Depth_Component,
                                    FB_Width, FB_Height);
      Read_And_Draw_Target.Attach_Renderbuffer (Depth_Attachment, RB);

      FB_Texture.Initialize_Id;
      GL.Objects.Textures.Set_Active_Unit (0);
      Texture_2D.Bind (FB_Texture);
      if Curr_Ssaa > 1.0 then
         Texture_2D.Set_Magnifying_Filter (GL.Objects.Textures.Linear);
      else
         Texture_2D.Set_Magnifying_Filter (GL.Objects.Textures.Nearest);
      end if;
      Texture_2D.Set_Minifying_Filter (GL.Objects.Textures.Nearest);
      Texture_2D.Set_X_Wrapping (GL.Objects.Textures.Clamp_To_Edge); --  Wrap_S
      Texture_2D.Set_Y_Wrapping (GL.Objects.Textures.Clamp_To_Edge); --  Wrap_T
      Texture_2D.Load_Empty_Texture (0, GL.Pixels.SRGB_Alpha,
                                     FB_Width, FB_Height);
      Set_Active_Buffers (Draw_Buffers);
      if not GL_Utils.Verify_Bound_Framebuffer then
         raise FB_Effects_Exception with "FB_Effects.Init Incomplete frambuffer";
      end if;

      FB_VAO.Initialize_Id;
      VBO := GL_Utils.Create_2D_VBO (Points);
      GL_Utils.Bind_VAO (FB_VAO);
      Enable_Vertex_Attrib_Array (Attrib_VP);
      Set_Vertex_Attrib_Pointer (Attrib_VP, 2, Single_Type, False, 0, 0);

      FB_Default_Shader_Manager.Init (FB_Shader_Programs (FB_Default_Effect));
      FB_Gold_Shader_Manager.Init (FB_Shader_Programs (FB_Gold_Flash_Effect));
      FB_Red_Shader_Manager.Init (FB_Shader_Programs (FB_Red_Flash_Effect));
      FB_Fadein_Shader_Manager.Init (FB_Shader_Programs (FB_Fadein_Effect));

      FB_Fadeout_Shader_Manager.Init (FB_Shader_Programs (FB_Fadeout_Effect));
      FB_Screw_Shader_Manager.Init (FB_Shader_Programs (FB_Screw_Effect));
      FB_Grey_Shader_Manager.Init (FB_Shader_Programs (FB_Grey_Effect));
      FB_White_Shader_Manager.Init (FB_Shader_Programs (FB_White_Flash_Effect));
      FB_Green_Shader_Manager.Init (FB_Shader_Programs (FB_Green_Flash_Effect));

      Game_Utils.Game_Log ("---FRAMEBUFFER INITIALIZED---");

   exception
      when others =>
         Put_Line ("An exception occurred in FB_Effects.Init.");
         raise;
   end Init;

   --  -------------------------------------------------------------------------

   procedure Fade_In is
   begin
      FB_Current_Effect := FB_Fadein_Effect;
      FB_Effect_Elapsed := 0.0;
   end Fade_In;

   --  -------------------------------------------------------------------------

   procedure Fade_Out is
   begin
      if FB_Current_Effect /= FB_Fadeout_Effect then
         FB_Current_Effect := FB_Fadeout_Effect;
         FB_Effect_Elapsed := 0.0;
      end if;
   end Fade_Out;

   --  -------------------------------------------------------------------------

   procedure FB_Gold_Flash is
   begin
      FB_Current_Effect := FB_Gold_Flash_Effect;
      FB_Effect_Elapsed := 0.0;
   end FB_Gold_Flash;

   --  -------------------------------------------------------------------------

   procedure FB_Green_Flash is
   begin
      FB_Current_Effect := FB_Green_Flash_Effect;
      FB_Effect_Elapsed := 0.0;
   end FB_Green_Flash;

   --  -------------------------------------------------------------------------

   procedure FB_White_Flash is
   begin
      FB_Current_Effect := FB_White_Flash_Effect;
      FB_Effect_Elapsed := 0.0;
   end FB_White_Flash;

   --  -------------------------------------------------------------------------

   procedure Set_Feedback_Effect (Effect : FB_Effect) is
   begin
      FB_Current_Effect := Effect;
      FB_Effect_Elapsed := 0.0;
   end Set_Feedback_Effect;

   --  -------------------------------------------------------------------------

   procedure Set_Feedback_Screw (Factor : Float) is
   begin
      Ww_Fb_Current_Effect := FB_Screw_Effect;
      FB_Screw_Factor := Single (Factor);
   end Set_Feedback_Screw;

   --  -------------------------------------------------------------------------

   procedure Set_WW_FB_Effect (Effect : FB_Effect) is
   begin
      WW_FB_Current_Effect := Effect;
      WW_FB_Effect_Elapsed := 0.0;
   end Set_WW_FB_Effect;

   --  ------------------------------------------------------------------------

end FB_Effects;
