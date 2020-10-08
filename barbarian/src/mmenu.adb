
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Glfw.Input.Keys;

with GL.Attributes;
with GL.Objects.Buffers;
with GL.Objects.Textures;
with GL.Objects.Textures.Targets;
with GL.Objects.Vertex_Arrays;
with GL.Toggles;
with GL.Types;
with GL.Types.Colors;

with Glfw;

with Maths;
with Utilities;

with Camera;
with Cursor_Shader_Manager;
with Game_Utils;
with GL_Utils;
with Input_Handler;
with Shader_Attributes;
with Title_Shader_Manager;

package body MMenu is

   Black                 : constant GL.Types.Colors.Color := (0.0, 0.0, 0.0, 1.0);
   Cursor_VAO            : GL.Objects.Vertex_Arrays.Vertex_Array_Object;
   Title_VAO             : GL.Objects.Vertex_Arrays.Vertex_Array_Object;
   Num_Mmenu_Entries     : constant Integer := 7;
   --      Num_Gra_Entries   : constant Integer := 17;
   --      Num_Aud_Entries   : constant Integer := 3;
   --      Num_Inp_Entries   : constant Integer := 4;
   --      Num_Con_Entries   : constant Integer := 2;

   Mmenu_Open             : Boolean := False;
   Mmenu_Was_Closed       : Boolean := False;
   Mmenu_Credits_Open     : Boolean := False;
   Mmenu_End_Story_Open   : Boolean := False;
   Mmenu_Gr_Open          : Boolean := False;
   User_Chose_Custom_Maps : Boolean := False;
   User_Chose_New_Game    : Boolean := False;
   We_Are_In_Custom_Maps  : Boolean := False;
   Title_Author_Text      : Unbounded_String := To_Unbounded_String ("");
   Title_Skull_Texture    : GL.Objects.Textures.Texture;

   Mmenu_Cursor_Curr_Item : Integer := -1;
   Cursor_Current_Item    : Integer := -1;
   Cursor_Point_Count     : GL.Types.Int := 0;
   Title_Point_Count      : GL.Types.Int := 0;
   Title_M                : GL.Types.Singles.Matrix4 := GL.Types.Singles.Identity4;
   Title_V                : GL.Types.Singles.Matrix4 := GL.Types.Singles.Identity4;
   Cursor_M               : GL.Types.Singles.Matrix4 := GL.Types.Singles.Identity4;
   Cursor_V               : GL.Types.Singles.Matrix4 := GL.Types.Singles.Identity4;
   Title_Bounce_Timer     : Float := 5.0;
   Text_Timer             : Float := 0.0;
   Since_Last_Key         : Float := 0.0;

   --  ------------------------------------------------------------------------

   function Are_We_In_Custom_Maps return Boolean is
   begin
      return We_Are_In_Custom_Maps;
   end Are_We_In_Custom_Maps;

   --  ------------------------------------------------------------------------

   function Did_User_Choose_Custom_Maps return Boolean is
   begin
      return User_Chose_Custom_Maps;
   end Did_User_Choose_Custom_Maps;

   --  ------------------------------------------------------------------------

   function Did_User_Choose_New_Game return Boolean is
   begin
      return User_Chose_New_Game;
   end Did_User_Choose_New_Game;

   --  ------------------------------------------------------------------------

   procedure Draw_Menu (Elapsed : Float) is
      use GL.Toggles;
   begin
      if Mmenu_Cursor_Curr_Item < 0 then
         Mmenu_Cursor_Curr_Item := Num_Mmenu_Entries - 1;
      end if;
      if Mmenu_Cursor_Curr_Item >= Num_Mmenu_Entries then
         Mmenu_Cursor_Curr_Item := 0;
      end if;
      Utilities.Clear_Depth;
      if Mmenu_Credits_Open then
         Utilities.Clear_Background_Colour_And_Depth (Black);
         Disable (Depth_Test);
      end if;
      Text_Timer := Text_Timer + Elapsed;
      Enable (Depth_Test);
   end Draw_Menu;

   --  ------------------------------------------------------------------------

   procedure Draw_Title_Only is
      use GL.Types;
      use Singles;
      use Maths;
      S_Matrix     : constant Singles.Matrix4 := Scaling_Matrix (10.0);
      T_Matrix     : constant Singles.Matrix4 :=
                       Translation_Matrix ((0.0, -10.0, -30.0));
      M_Matrix     : constant Singles.Matrix4 := T_Matrix * S_Matrix;
      Title_Matrix : constant Singles.Matrix4 :=
                       Translation_Matrix ((-0.4, -3.0, -1.0));
      Current_Time : constant Single := Single (Glfw.Time);
   begin
      --  Draw cursor skull in background
      Game_Utils.Game_Log ("Mmenu.Draw_Title_Only");
      GL.Objects.Textures.Targets.Texture_2D.Bind (Title_Skull_Texture);
      Cursor_VAO.Initialize_Id;
      Cursor_VAO.Bind;
      Cursor_Shader_Manager.Set_Perspective_Matrix (Camera.Projection_Matrix);
      Cursor_Shader_Manager.Set_View_Matrix (Cursor_V);
      Cursor_Shader_Manager.Set_Model_Matrix (M_Matrix);
      GL_Utils.Draw_Triangles (Cursor_Point_Count);

      --  3D title
      Title_Shader_Manager.Set_View_Matrix (Title_V);
      Title_Shader_Manager.Set_Model_Matrix (Title_Matrix);
      Title_Shader_Manager.Set_Perspective_Matrix (Camera.Projection_Matrix);
      Title_Shader_Manager.Set_Time (Current_Time);
      Title_VAO.Initialize_Id;
      Title_VAO.Bind;
      GL_Utils.Draw_Triangles (Title_Point_Count);

      --  Draw library logos and stuff
      --  Later
   end Draw_Title_Only;

   --  ------------------------------------------------------------------------

   function End_Story_Open return Boolean is
   begin
      return Mmenu_End_Story_Open;
   end End_Story_Open;

   --  ------------------------------------------------------------------------

   procedure Init_MMenu is
      use GL.Objects.Buffers;
      use GL.Types;
      Vertex_Array    : GL.Objects.Vertex_Arrays.Vertex_Array_Object;
      Vertex_Buffer   : Buffer;
      Texture_Buffer  : Buffer;
      Position_Array  : constant Singles.Vector2_Array (1 .. 6) :=
                          ((-1.0, 1.0), (-1.0, -1.0),  (1.0, -1.0),
                           (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0));
      Texture_Array   : constant Singles.Vector2_Array (1 .. 6) :=
                          ((0.0, 1.0), (0.0, 0.0),  (1.0, 0.0),
                           (1.0, 0.0), (1.0, 1.0), (0.0, 1.0));
      Title_Mesh      : Integer := 0;
      Cursor_Mesh     : Integer := 0;
   begin
      Vertex_Array.Initialize_Id;
      Vertex_Array.Bind;
      Vertex_Buffer.Initialize_Id;
      Texture_Buffer.Initialize_Id;

      GL.Attributes.Enable_Vertex_Attrib_Array (Shader_Attributes.Attrib_VP);
      Array_Buffer.Bind (Vertex_Buffer);
      GL.Attributes.Set_Vertex_Attrib_Pointer
        (Shader_Attributes.Attrib_VP, 2, Single_Type, False, 0, 0);

      GL.Attributes.Enable_Vertex_Attrib_Array (Shader_Attributes.Attrib_VT);
      Array_Buffer.Bind (Vertex_Buffer);
      GL.Attributes.Set_Vertex_Attrib_Pointer
        (Shader_Attributes.Attrib_VT, 2, Single_Type, False, 0, 0);

   end Init_MMenu;

   --  ------------------------------------------------------------------------

   function Menu_Open return Boolean is
   begin
      return MMenu_Open;
   end Menu_Open;

   --  ------------------------------------------------------------------------

   function Menu_Was_Closed return Boolean is
   begin
      return Mmenu_Was_Closed;
   end Menu_Was_Closed;

   --  ------------------------------------------------------------------------

   procedure Set_MMenu_Open (State : Boolean) is
   begin
      MMenu_Open := State;
   end Set_MMenu_Open;

   --  ------------------------------------------------------------------------

   procedure Start_Mmenu_Title_Bounce is
   begin
      Title_Bounce_Timer := 0.0;
   end Start_Mmenu_Title_Bounce;

   --  ------------------------------------------------------------------------

   function Update_MMenu (Delta_Time : Float) return Boolean is
      use Glfw.Input.Keys;
      use Input_Handler;
      Num_Video_Modes : constant Integer := 10;
      type Size_Array is array (1 .. Num_Video_Modes) of Integer;
      Widths          : Size_Array := (640, 800, 1024, 1280, 1600,
                                       1920, 1280, 1366, 1600, 1920);
      Heights         : Size_Array := (480, 600, 768, 960, 1200,
                                       1440, 720, 768, 900, 1080);
      Temp            : Unbounded_String := To_Unbounded_String ("");
      Result          : Boolean := False;
   begin
      Since_Last_Key := Since_Last_Key + Delta_Time;
      Mmenu_Was_Closed := False;
      User_Chose_Custom_Maps := False;
      User_Chose_New_Game := False;
      --  Joystick processsing
      Result := Since_Last_Key < 0.15;
      if not Result then
         Result := Mmenu_Gr_Open;
         if Result then
            Result := Was_Key_Pressed (Escape) or
              Was_Open_Menu_Action_Pressed or
              Was_Menu_Back_Action_Pressed;
            if Result then
               Mmenu_Gr_Open := False;
            else
               Result := Was_Key_Pressed (Enter) or
                 Was_Ok_Action_Pressed or
                 Was_Attack_Action_Pressed;
               if Result then
                  case Cursor_Current_Item is
                     when 0 => null;
                     when 1 => null;
                     when 2 => null;
                     when 3 => null;
                     when 4 => null;
                     when 5 => null;
                     when 6 => null;
                     when 7 => null;
                     when 8 => null;
                     when 9 => null;
                     when 10 => null;
                     when 11 => null;
                     when 12 => null;
                     when 13 => null;
                     when 14 => null;
                     when 15 => null;
                     when 16 => null;
                     when others => null;
                  end case;
               else
                  Result := Is_Key_Down (Up);
               end if;
            end if;
         end if;
      end if;

      return Result;
   end Update_MMenu;

   --  ------------------------------------------------------------------------

end MMenu;
