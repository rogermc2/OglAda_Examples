
with Ada.Exceptions; use Ada.Exceptions;
with Ada.Strings.Fixed;

with Maths;

with Audio;
with Batch_Manager;
with Character_Controller;
with Event_Controller;
with Game_Utils;
with Particle_System;
with Properties_Manager.Process;
with Prop_Renderer;
with Prop_Renderer_Support; use Prop_Renderer_Support;
with Sprite_Renderer;
with Tiles_Manager;

package body Properties_Manager is
   use Properties_Manager.Process;

   Properties_Manager_Exception : Exception;

   procedure Rebalance_Props_In (Map_U, Map_V : Integer);
   procedure Set_Property_Defaults (aProperty : in out Property_Data);
   procedure Set_Up_Sprite (New_Prop  : in out Property_Data;
                            aScript   : Prop_Script);

   --  ------------------------------------------------------------------------
   --  Height_level is the property's own height offset from the tile.
   --  Facing is the compass facing 'N' 'S' 'W' or 'E'.
   procedure Create_Prop_From_Script
     (Script_File : String; Map_U, Map_V : Natural; Height_Level : Integer;
      Facing      : Character; Tx, Rx : Integer) is
      use Maths;
      use Singles;
      use Event_Controller;
      use Properties_Script_Package;
      New_Prop      : Property_Data;
      Script_Index  : Positive;
      aScript       : Prop_Script;
      aScript_Type  : Property_Type;
      Respect_Ramps : Boolean;
      Start_Now     : Boolean := True;
      Always_Update : Boolean := False;
      Always_Draw   : Boolean := False;
      Rebalance     : Boolean := False;
      RX_Kind       : RX_Type := Rx_Invalid;
      Rot_Matrix    : Matrix4;
      Ros           : Vector3;
   begin
--        Game_Utils.Game_Log
--          ("--------Properties_Manager.Create_Prop_From_Script--------");
      Set_Property_Defaults (New_Prop);
--        Game_Utils.Game_Log
--          ("Properties_Manager.Create_Prop_From_Script -1- creating property from "
--           & Script_File);
      Script_Index := Get_Index_Of_Prop_Script (Script_File);
      --          Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -2- script index "
      --                               & Integer'Image (Script_Index));
      aScript := Prop_Scripts.Element (Script_Index);
      --          Game_Utils.Game_Log ("Properties_Manager.Create_Prop_From_Script -3- script created ");
      aScript_Type := aScript.Script_Type;
      Respect_Ramps := aScript_Type = Boulder_Prop;
--        Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -4- Mesh_Index"
--                             & Integer'Image (aScript.Mesh_Index));
      if Tiles_Manager.Is_Tile_Valid ((Int (Map_U), Int (Map_V))) then
--           Game_Utils.Game_Log ("Properties Manager creating property from script "
--                                & Script_File);
         New_Prop.Script_Index := Script_Index;
         --   Set_Property_Defaults;   set by record defaults
         New_Prop.Door_Position := Closed_State;
         New_Prop.Trap := Trap_Primed_State;
         for index in 1 .. Mesh_Loader.Max_Bones loop
            New_Prop.Current_Bone_Transforms (index) := Singles.Identity4;
         end loop;
--           Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -5- Current_Bone_Transforms done");

         New_Prop.World_Pos (GL.X) := 2.0 * Single (Map_U);
         New_Prop.World_Pos (GL.Z) := 2.0 * Single (Map_V);
         New_Prop.Is_Visible := aScript.Starts_Visible;
--           Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -5a- New_Prop.Is_Visible set");

         New_Prop.World_Pos (GL.Y) :=
           Tiles_Manager.Get_Tile_Height (New_Prop.World_Pos (GL.X),
                                          New_Prop.World_Pos (GL.Z),
                                          False, Respect_Ramps);
--           Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -5b- initialNew_Prop.World_Pos (GL.Y) set");
         New_Prop.World_Pos (GL.Y) :=
           New_Prop.World_Pos (GL.Y) + Single (2 * Height_Level);
--           Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -5c- New_Prop.World_Pos done");
         --  Allow portcullis and its collision model to start up high
         New_Prop.Elevator := aScript.Initial_Elevator_State;
         if aScript_Type = Elevator_Prop and
           New_Prop.Elevator = At_Top_State then
            New_Prop.World_Pos (GL.Y) :=
              New_Prop.World_Pos (GL.Y) + Single (aScript.Elevator_Top_Height);
            New_Prop.Is_Visible := aScript.Elevator_Visible_At_Top;
         end if;

--           Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -5d- New_Prop.Elevator done");
         New_Prop.Velocity := Vec3_0;
         New_Prop.Anim_Duration := 0.0;
         New_Prop.Anim_Elapsed_Time := 0.0;
         New_Prop.Sprite_Duration := 0.0;
         New_Prop.Delay_Countdown := 0.0;
         New_Prop.Facing := Facing;
         case Facing is
            when 'E' => New_Prop.Heading_Deg := Maths.Degree (270.0);
            when 'S' => New_Prop.Heading_Deg := Maths.Degree (180.0);
            when 'W' => New_Prop.Heading_Deg := Maths.Degree (90.0);
            when others => New_Prop.Heading_Deg := Maths.Degree (0.0);
         end case;
         New_Prop.Map_U := Map_U;
         New_Prop.Map_V := Map_V;
         New_Prop.Tx_Code := Tx;
         New_Prop.Rx_Code := Rx;
         New_Prop.Script_Index := 1;
         New_Prop.Height_Level := Height_Level;
--           Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -6- New_Prop 1 done");

         if aScript.Has_Particles then
            New_Prop.Particle_System_Index :=
              Particle_System.Create_Particle_System
                (To_String (aScript.Particle_Script_File_Name),
                 True, False, False);
            --  rotate offset
            Rot_Matrix := Rotate_Y_Degree
              (Identity4,  New_Prop.Heading_Deg);
            Ros := To_Vector3 (Rot_Matrix * To_Vector4 (aScript.Particles_Offset));
            Particle_System.Set_Particle_System_Position
              (New_Prop.Particle_System_Index, New_Prop.World_Pos + Ros);
         else
            New_Prop.Particle_System_Index := 1;
         end if;

         New_Prop.Was_Triggered := False;
         New_Prop.Is_On_Ground := False;
         New_Prop.No_Save := False;
         New_Prop.Is_Animating := False;
         New_Prop.First_Doom_Tile_Set := False;
         New_Prop.Second_Doom_Tile_Set := False;
         New_Prop.Was_Collected_By_Player := False;

         Process_Script_Type (New_Prop, aScript, RX_Kind, Rebalance);
         if aScript.Uses_Sprite then
            Set_Up_Sprite (New_Prop, aScript);
         end if;
         if aScript.Has_Lamp then
            Batch_Manager.Add_Static_Light
              (Map_U, Map_V, Height_Level, aScript.Lamp_Offset,
               aScript.Lamp_Diffuse, aScript.Lamp_Specular,
               Single (aScript.Lamp_Range));
         end if;
         Properties.Append (New_Prop);

         if New_Prop.Rx_Code > 0 and RX_Kind /= Rx_Invalid then
            Event_Controller.Add_Receiver (New_Prop.Rx_Code, RX_Kind,
                                           Properties.Last_Index);
         end if;
--           Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -11- Update_Props_In_Tiles (Properties.Last_Index: "
--                                & Integer'Image (Properties.Last_Index));
         --  Update_Props_In_Tiles just adds
         Prop_Renderer.Update_Props_In_Tiles_Index
           (Integer (New_Prop.Map_U), Integer (New_Prop.Map_V),
            Int (Properties.Last_Index));
         if Rebalance then
--              Game_Utils.Game_Log ("Properties_Manager Create_Prop_From_Script -12- Rebalance");
            Rebalance_Props_In (Integer (Map_U), Integer (Map_V));
         end if;
      end if;
--        Game_Utils.Game_Log ("--------Leaving Properties_Manager.Create_Prop_From_Script--------");

   exception
      when anError : Constraint_Error =>
         Put ("Properties_Manager.Create_Prop_From_Script constraint error: ");
         Put_Line (Exception_Information (anError));
         raise;
      when anError :  others =>
         Put_Line ("An exception occurred in Properties_Manager.Create_Prop_From_Script.Load_Property_Script.");
         Put_Line (Exception_Information (anError));
         raise;
   end Create_Prop_From_Script;

   -- -------------------------------------------------------------------------

   procedure Delete_Script_Data (Script_Index : Positive) is
   begin
      Prop_Scripts.Delete (Script_Index);
   end Delete_Script_Data;

   --  -------------------------------------------------------------------------

   function Get_Property_Data (Prop_Index : Positive)
                               return Prop_Renderer_Support.Property_Data is
   begin
      --          Put_Line ( "Prop_Renderer.Get_Property_Data, entered with property index: "
      --                      & Positive'Image (Prop_Index));
      if not Properties_Manager.Index_Is_Valid (Prop_Index) then
         raise Properties_Exception with
           "Properties_Manager.Get_Property_Data, invalid property index: " &
           Positive'Image (Prop_Index);
      end if;
      return Properties.Element (Prop_Index);
   end Get_Property_Data;

   --  -------------------------------------------------------------------------

   function Get_Script_Data (Script_Index : Positive)
                             return Prop_Renderer_Support.Prop_Script is
   begin
      return Prop_Scripts.Element (Script_Index);
   end Get_Script_Data;

   --  -------------------------------------------------------------------------

   function Index_Is_Valid (Prop_Index : Positive) return Boolean is
      use Properties_Package;
   begin
      return Prop_Index <= Properties.Last_Index;
   end Index_Is_Valid;

   -- --------------------------------------------------------------------------
   --  read properties from an already open file
   procedure Load_Properties (Prop_File : File_Type) is
      use Ada.Strings;
      aLine          : constant String := Get_Line (Prop_File);
      PosL           : Natural := Fixed.Index (aLine, " ") + 1;
      PosR           : Natural;
      S_Length       : Integer := aLine'Length;
      Property_Count : Integer := 0;
      Script_File    : Unbounded_String;
      U              : Natural := 0;           --  map position
      V              : Natural := 0;
      Height         : Integer := 0;       --  map height level
      Facing         : Character := 'N';   --  compass facing
      --  Map files can have Rx and Tx set to -1
      Rx             : Integer := -1;       --  receive code
      Tx             : Integer := -1;       --  transmit code
   begin

--        Game_Utils.Game_Log ("Properties_Manager.Load_Properties entered");
      if Fixed.Index (aLine, "props ") = 0 then
         raise Properties_Exception with
           "Properties_Manager.Load_Properties, invalid format, ""props"" expected: " &
           aLine (1 .. PosL);
      end if;

      PosR := Fixed.Index (aLine (PosL .. S_Length), " ");

      Property_Count := Integer'Value (aLine (PosL .. PosR));
--        Game_Utils.Game_Log ("Properties_Manager.Load_Properties Property_Count: "
--                             & Integer'Image (Property_Count));
      Prop_Renderer.Set_Portal_Index (0);
      Character_Controller.Set_Gold_Current (0);
      Character_Controller.Set_Gold_Max (0);
      Character_Controller.Set_Total_Treasure_Found (0);

      for p_index in 1 .. Property_Count loop
         declare
            Prop_Line : constant String := Get_Line (Prop_File);
         begin
--              Game_Utils.Game_Log ("Properties_Manager.Load_Properties p_index: "
--                                   & Integer'Image (p_index));
            S_Length := Prop_Line'Length;
            PosL := Fixed.Index (Prop_Line, " ");
            Script_File := To_Unbounded_String (Prop_Line (1 .. PosL - 1));
            PosR := Fixed.Index (Prop_Line (PosL .. S_Length), ",");
            U := Integer'Value (Prop_Line (PosL + 1 .. PosR - 1));
            PosL := Fixed.Index (Prop_Line (PosR .. S_Length), " ");
            V := Integer'Value (Prop_Line (PosR + 1 .. PosL - 1));

            PosR := Fixed.Index (Prop_Line (PosL + 1 .. S_Length), " ");
            Height := Integer'Value (Prop_Line (PosL + 1 .. PosR - 1));
            PosL := Fixed.Index (Prop_Line (PosR + 1 .. S_Length), " ");
            Facing := Prop_Line (PosR + 1);

            PosR := Fixed.Index (Prop_Line (PosL + 1 .. S_Length), " ");
            --  Map files can have Rx and Tx set to -1
            Rx := Integer'Value (Prop_Line (PosL + 1 .. PosR - 1));
            Tx := Integer'Value (Prop_Line (PosR + 1 .. S_Length));
--              Game_Utils.Game_Log ("Properties_Manager.Load_Properties Script_File " &
--                                     To_String (Script_File) & ", U: " &
--                                     Integer'Image (U) & ", V: " &
--                                     Integer'Image (V) & ", Height: " &
--                                     Integer'Image (Height) & ", Facing: " &
--                                     Facing & ", Rx: " &
--                                     Integer'Image (Rx) & ", Tx: " &
--                                     Integer'Image (Tx));
         end; --  declare block
         Create_Prop_From_Script (To_String (Script_File), U, V, Height,
                                  Facing, Tx, Rx);
      end loop;
--        Game_Utils.Game_Log ("Properties_Manager.Load_Properties, Properties loaded");

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Properties_Manager.Load_Properties!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Load_Properties;

   --  ----------------------------------------------------------------------------

   procedure Rebalance_Props_In (Map_U, Map_V : Integer) is
      use Prop_Renderer;
      use Prop_Renderer_Support;
      use Singles;
      Prop_Size     : constant Integer := Props_In_Tiles_Size (Map_U, Map_V);
      Prop_Index    : Integer;
      Prop          : Property_Data;
      Script_Index  : Integer;
      Script        : Prop_Renderer_Support.Prop_Script;
      Script_Kind   : Property_Type;
      Sprite_Pos    : Vector3;
      Rot_Matrix    : Matrix4;
      Origin        : Vector4;
   begin
      if not Tiles_Manager.Is_Tile_Valid ((Int (Map_U), Int (Map_V))) then
         raise Properties_Exception with
           "Properties_Manager.Rebalance_Props_In called with invalid Map_U, Map_V: "
           & Integer'Image (Map_U) & ", " & Integer'Image (Map_V);
      end if;

      For index in 1 .. Prop_Size loop
         Prop_Index := Get_Tile_Property_Index (Map_U, Map_V, index);
         Prop := Get_Property_Data (Prop_Index);
         Script_Index := Prop.Script_Index;
         Script := Get_Script_Data (Script_Index);
         Script_Kind := Script.Script_Type;

         Prop.World_Pos (GL.Y) := Tiles_Manager.Get_Tile_Height
           (Prop.World_Pos (GL.X), Prop.World_Pos (GL.Z), False, False) +
             Single (2 * Prop.Height_Level);
         if Script_Kind = Boulder_Prop then
            Prop.World_Pos (GL.Y) := Prop.World_Pos (GL.Y) + Script.Radius;
            Prop.Is_On_Ground := True;
         end if;
         if Script.Uses_Sprite then
            Sprite_Pos := Prop.World_Pos;
            Sprite_Pos (GL.Y) := Sprite_Pos (GL.Y) +
              Single (Script.Sprite_Y_Offset) + Sprite_Y_Offset;
            Sprite_Renderer.Set_Sprite_Position
              (Prop.Script_Index, Sprite_Pos);
         end if;
         Rot_Matrix := Maths.Rotate_Y_Degree (Identity4, Prop.Heading_Deg);
         Prop.Model_Matrix :=
           Rot_Matrix * Maths.Translation_Matrix ((Prop.World_Pos));
         Origin := To_Vector4 (Script.Origin);
         Prop.Origin_World := To_Vector3 (Prop.Model_Matrix * Origin);
         Replace_Property (index, Prop);
      end loop;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Properties_Manager.Rebalance_Props_In!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Rebalance_Props_In;

   -- --------------------------------------------------------------------------

   procedure Replace_Property (Property_Index : Positive;
                               Property       : Prop_Renderer_Support.Property_Data) is

   begin
      Properties.Replace_Element (Property_Index, Property);
   end Replace_Property;

   -- --------------------------------------------------------------------------

   procedure Set_Property_Defaults (aProperty : in out Property_Data) is
      use Prop_Renderer_Support;
   begin
      aProperty.Door_Position := Closed_State;
      aProperty.Elevator := At_Top_State;
      aProperty.Trap := Trap_Primed_State;
      for index in 1 .. Mesh_Loader.Max_Bones loop
         aProperty.Current_Bone_Transforms (index) := Singles.Identity4;
      end loop;
      aProperty.Quat :=  (0.0, 0.0, 1.0, 0.0);
      aProperty.Facing := 'N';
      aProperty.Script_Index := 1;
      aProperty.Map_U := 0;
      aProperty.Map_V := 0;
      aProperty.Tx_Code := -1;
      aProperty.Rx_Code := -1;
      aProperty.Sprite_Index := 1;
      aProperty.Particle_System_Index := 1;
      aProperty.Boulder_Snd_Idx := 1;
      aProperty.Is_Visible := True;

   end Set_Property_Defaults;

   --  -------------------------------------------------------------------------

   procedure Set_Up_Sprite (New_Prop  : in out Property_Data;
                            aScript   : Prop_Script) is
      use Singles;
      use Sprite_Renderer;
      Diff_Map   : constant GL.Objects.Textures.Texture := aScript.Diffuse_Map_Id;
      Spec_Map   : constant GL.Objects.Textures.Texture := aScript.Specular_Map_Id;
      Rows       : constant Integer := aScript.Sprite_Map_Rows;
      Cols       : constant Integer := aScript.Sprite_Map_Cols;
      Y_Offset   : constant Single := Single (aScript.Sprite_Y_Offset);
      Sprite_Pos : Vector3 := New_Prop.World_Pos;
   begin
      if not Diff_Map.Initialized then
         raise Properties_Manager_Exception with "Properties_Manager.Set_Up_Sprite, " &
           "Diff_Map texture has not been initialized";
      end if;
      if not Spec_Map.Initialized then
         raise Properties_Manager_Exception with "Properties_Manager.Set_Up_Sprite, " &
           "Spec_Map texture has not been initialized";
      end if;

      New_Prop.Script_Index := Add_Sprite (Diff_Map, Spec_Map, Cols, Rows);
      --          Put_Line ("Properties_Manager.Set_Up_Sprite, Spec.Atlas_Diffuse_ID, New_Prop.Script_Index"
      --                    & Integer'Image (New_Prop.Script_Index));
      Set_Sprite_Scale (New_Prop.Sprite_Index, aScript.Scale);
      Sprite_Pos (GL.Y) := Sprite_Pos (GL.Y) + Y_Offset + Sprite_Y_Offset;
      Set_Sprite_Position (New_Prop.Sprite_Index, Sprite_Pos);
      Set_Sprite_Heading (New_Prop.Sprite_Index, New_Prop.Heading_Deg);

   end Set_Up_Sprite;

   -- --------------------------------------------------------------------------

end Properties_Manager;
