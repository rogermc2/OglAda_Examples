
with Ada.Exceptions;
with Ada.Text_IO; use Ada.Text_IO;

with Glfw;
with Glfw.Input.Keys;
with Glfw.Windows.Context;

with GL.Types.Colors;

with Maths;
with Utilities;

with Audio;
with Batch_Manager;
with Blood_Splats;
with Character_Controller;
with Character_Map;
with Event_Controller;
with FB_Effects;
with Game_Utils;
with GL_Utils;
with GUI;
with GUI_Level_Chooser;
with Input_Callback;
with Input_Handler;
with Manifold;
with Main_Menu;
with Particle_System;
with Prop_Renderer;
with Settings;
with Shader_Manager;
with Shadows;
with Sprite_Renderer;
with Sprite_World_Map;
with Text;
with Transparency;

package body Main_Loop.Game_Support is

   Yellow                       : constant GL.Types.Colors.Color :=
                                    (0.6, 0.6, 0.0, 0.5);
   Shadow_Caster_Max_Tiles_Away : constant Positive := 10;
   FPS_Counter                  : Integer := 0;

   --      procedure Cycle_Rendering_Mode;  --  Debug
   procedure Update_FPS_Box;

   --  -------------------------------------------------------------------------

   function Cheat_Check_1 return Boolean is
      use Glfw.Input.Keys;
      Cheating : Boolean := False;
   begin
      if Input_Callback.Is_Key_Down (M) and
        Input_Callback.Is_Key_Down (L) and
        Input_Callback.Is_Key_Down (I) then
         Cheating := True;

      elsif Input_Callback.Is_Key_Down (A) and
        Input_Callback.Is_Key_Down (N) and
        Input_Callback.Is_Key_Down (T) then
         Cheating := True;
      elsif Input_Callback.Is_Key_Down (R) and
        Input_Callback.Is_Key_Down (O) and
        Input_Callback.Is_Key_Down (M) then
         Cheating := True;
      elsif Input_Callback.Is_Key_Down (D) and
        Input_Callback.Is_Key_Down (A) and
        Input_Callback.Is_Key_Down (V) then
         Cheating := True;
      end if;
      return Cheating;
   end Cheat_Check_1;

   --  -------------------------------------------------------------------------

   procedure Check_Keys (Window          : in out Input_Callback.Barbarian_Window;
                         Save_Screenshot : in out Boolean) is
      use Glfw.Input.Keys;
   begin
      Save_Screenshot := Input_Callback.Was_Key_Pressed (Window, F11);
      if Input_Callback.Was_Key_Pressed (Window, F1) then
         Prop_Renderer.Splash_Particles_At
           (Character_Controller.Get_Character_Position (1));
      end if;
   end Check_Keys;

   --  -------------------------------------------------------------------------

   --  Debug
   --      procedure Cycle_Rendering_Mode is
   --      begin
   --          null;
   --      end Cycle_Rendering_Mode;

   --  -------------------------------------------------------------------------

   function Check_Victory_Defeat return Boolean is
   begin
      return True;
   end Check_Victory_Defeat;

   --  -------------------------------------------------------------------------

   procedure Player_1_View (Window          : in out Input_Callback.Barbarian_Window;
                            Fallback_Shader : GL.Objects.Programs.Program;
                            Tile_Diff_Tex, Tile_Spec_Tex, Ramp_Diff_Tex,
                            Ramp_Spec_Tex   : GL.Objects.Textures.Texture;
                            Delta_Time      : Float; Dump_Video : Boolean;
                            Save_Screenshot : Boolean) is
      use GL.Types;
      use Glfw.Input.Keys;
      use Shadows;
      Camera_Position : constant Singles.Vector3 := Camera.World_Position;
      --  the 1.0 is to offset by half a tile
      Centre_X        : constant Integer := Integer ((1.0 + Camera_Position (GL.X)) / 2.0);
      Centre_Z        : constant Integer := Integer ((1.0 + Camera_Position (GL.Z)) / 2.0);
      UV              : constant Ints.Vector2 :=
                          (Int (Abs (Centre_X)), Int (Abs (Centre_Z)));
   begin
      if Settings.Shadows_Enabled and Camera.Is_Dirty then
--           Game_Utils.Game_Log ("Settings.Shadows_Enabled and Camera.Is_Dirty...");
         for index in Shadow_Direction'Range loop
            Bind_Shadow_FB (index);
--              Game_Utils.Game_Log ("Draw_manifold_around_depth_only...");
            Manifold.Draw_Manifold_Around_Depth_Only;
            Prop_Renderer.Render_Props_Around_Depth_Only
              (Natural (UV (GL.X)), Natural (UV (GL.Y)), Shadow_Caster_Max_Tiles_Away);
         end loop;
      end if;   --  end of shadow mapping pass

--        Game_Utils.Game_Log ("Main_Loop.Game_Support.Player_1_View, Bind_main_scene_fb...");
      FB_Effects.Bind_Main_Scene_FB;
      Utilities.Clear_Colour_Buffer_And_Depth;
      Transparency.Reset_Transparency_List (Camera_Position);
      Manifold.Draw_Manifold_Around (Camera_Position,
                                     Single (Settings.Render_Distance),
                                     Tile_Diff_Tex, Tile_Spec_Tex,
                                     Ramp_Diff_Tex, Ramp_Spec_Tex);
      Blood_Splats.Render_Splats;
      GL_Utils.Set_Resized_View (False);
      Prop_Renderer.Render_Props_Around_Split
          (Fallback_Shader, Centre_X, Centre_Z, Settings.Render_Distance);
      GL.Objects.Programs.Use_Program (Fallback_Shader);
      Sprite_World_Map.Cache_Sprites_Around
        (Natural (UV (GL.X)), Natural (UV (GL.Y)), Settings.Render_Distance);
      Transparency.Draw_Transparency_List;
      Particle_System.Render_Particle_Systems (Single (Delta_Time));
      GL_Utils.Set_Resized_View (False);
      --  if Draw_Debug_Quads then
      --    Draw_Shadow_Debug;
      --  end if;
      FB_Effects.Draw_FB_Effects (Single (Delta_Time));
      -- Debug:
      --        if Settings.Show_FPS then
      --           Update_FPS_Box;
      --        end if;
      if Main_Menu.Menu_Open then
         Game_Utils.Game_Log ("Main_Loop.Game_Supprt.Player_1_View, Menu_Open");
         Main_Menu.Draw_Menu (Delta_Time);
      elsif not Settings.Hide_GUI then
         null;
         GUI.Render_GUIs;
      end if;

      GUI.Draw_Controller_Button_Overlays (Delta_Time);
      -- Debug:
      --        if Settings.Show_FPS then
      --           Text.Draw_Text (FPS_Text);
      --        end if;
      Glfw.Input.Poll_Events;
      --        Poll_Joystick;
      --  ANTON moved this BEFORE swap buffers to avoid weird draw
      --  artifacts in output images
      if Settings.Video_Record_Mode and Dump_Video then
         null;
      end if;
      if Save_Screenshot then
         null;
         --           Screenshot;
      end if;

      Glfw.Windows.Context.Swap_Buffers (Window'Access);
      Camera.Set_Is_Dirty (False);
      if not Main_Menu.Menu_Open and then
        (Input_Callback.Was_Key_Pressed (Window, Escape) or
             Input_Handler.Was_Action_Pressed
           (Window, Input_Handler.Menu_Open_Action)) then
         Main_Menu.Set_Menu_Open (True);
         FB_Effects.Set_Feedback_Effect (FB_Effects.FB_Grey_Effect);
      end if;

   exception
      when anError : others =>
         Put_Line ("Main_Loop.Game_Support.Player_1_View exception");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Player_1_View;

   --  -------------------------------------------------------------------------

   procedure Unload_Level is
      use GUI_Level_Chooser;
   begin
      Set_Cheated_On_Map (False);
      Set_Boulder_Crushes (0);
      Set_Hammer_Kills (0);
      Set_Fall_Kills (0);
      Camera.Set_Camera_Position ((2.0, 10.0, 2.0));
      FB_Effects.Set_Feedback_Effect (FB_Effects.FB_Default_Effect);
      Event_Controller.Reset;
      Text.Unload_Comic_Texts;
      Sprite_World_Map.Free_Sprite_World_Map;
      Sprite_Renderer.Clear_Sprites;
      Manifold.Clear_Manifold_Lights;
      Particle_System.Stop_Particle_Systems;
      GUI.Reset_GUIs;
      Prop_Renderer.Reset_Properties;
      Character_Map.Free_Character_Map;
      Blood_Splats.Clear_Splats;
      Batch_Manager.Free_Manifold_Meta_Data;
      Manifold.Reset_Manifold_Vars;
      Audio.Stop_All_Sounds;
      Camera.Set_Screen_Shake_Countdown (0.0);
   end  Unload_Level;

   --  -------------------------------------------------------------------------

   procedure Update_FPS_Box is
      FPS : Float := 0.0;
   begin
      FPS_Counter := FPS_Counter + 1;
      if FPS_Counter >= 30 then
         FPS_Counter := 0;
      end if;
   end  Update_FPS_Box;

   --  -------------------------------------------------------------------------

   procedure Update_Timers (Last_Time, Delta_Time, Avg_Frame_Time_Accum_Ms,
                            Curr_Frame_Time_Accum_Ms            : in out Float;
                            Avg_Frames_Count, Curr_Frames_Count : in out Integer) is
      Current_Time     : constant Float := Float (Glfw.Time);
      Delta_Time_Ms    : Float := 0.0;
   begin
      Delta_Time := Current_Time - Last_Time;
      Delta_Time_Ms := 1000.0 * Delta_Time;
      Last_Time := Current_Time;

      Avg_Frame_Time_Accum_Ms := Avg_Frame_Time_Accum_Ms + Delta_Time_Ms;
      Curr_Frame_Time_Accum_Ms := Curr_Frame_Time_Accum_Ms + Delta_Time_Ms;
      Avg_Frames_Count := Avg_Frames_Count + 1;
      Curr_Frames_Count := Curr_Frames_Count + 1;
      if Avg_Frames_Count > 999 then
         Avg_Frames_Count := 0;
         Avg_Frame_Time_Accum_Ms := 0.0;
      end if;
      if Curr_Frames_Count > 99 then
         Curr_Frames_Count := 0;
         Curr_Frame_Time_Accum_Ms := 0.0;
      end if;

   end Update_Timers;

end Main_Loop.Game_Support;
