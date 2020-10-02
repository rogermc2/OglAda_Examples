
with Ada.Exceptions;
with Ada.Integer_Text_IO;
with Ada.Float_Text_IO;
with Ada.Strings.Fixed;
with Ada.Text_IO; use Ada.Text_IO;

with Texture_Manager;

with Game_Utils;

package body Specs_Manager is

   --      Max_Anim_Frames   : constant GL.Types.Int := 32;

   Specs                   : Specs_List;
   Use_Character_Mipmaps   : constant Boolean := True;

   procedure Set_Specs_Defaults (aSpec : in out Spec_Data);

   --  ------------------------------------------------------------------------

   procedure Add_Animation_Frame (aLine : String; theSpec : in out Spec_Data) is
      use Ada.Strings;
      Atlas_Index : Integer := 0;
      Anim_Num    : Int := 0;
      Seconds     : Float := 0.0;
      AFC         : Int := 0;
      L_Length    : constant Integer := aLine'Length;
      Pos1        : Integer := Fixed.Index (aLine, ":");
      Pos2        : Integer := Fixed.Index (aLine (Pos1 + 2 .. L_Length), " ");
      anAnim      : Anim_Frame;
      Anim_1D     : Anim_Frame_List;
      Anim_2D     : Anim_Frame_Array;
   begin
      Anim_Num := Int'Value (aLine (Pos1 + 2 .. Pos2 - 1)) + 1;
--        Game_Utils.Game_Log ("Specs_Manager.Add_Animation_Frame, Anim_Num: "
--                            & Int'Image (Anim_Num));
      if Anim_Num >= 0 and Anim_Num < Max_Animations then
         --  Skip "atlas_index:"
         Pos1 := Fixed.Index (aLine (Pos2 .. L_Length), ":");
         Pos2 := Fixed.Index (aLine (Pos1 + 2 .. L_Length), " ");
         Atlas_Index :=  Integer'Value (aLine (Pos1 + 2 .. Pos2 - 1)) + 1;
--           Game_Utils.Game_Log ("Specs_Manager.Add_Animation_Frame, Atlas_Index: "
--                            & Integer'Image (Atlas_Index));
         --  Skip "seconds:"
         Pos1 := Fixed.Index (aLine (Pos2 .. L_Length), ":");
         if Fixed.Index (aLine (Pos1 + 2 .. L_Length), " ") /= 0 then
            Pos2 := Fixed.Index (aLine (Pos1 + 2 .. L_Length), " ");
         else
            Pos2 := L_Length;
         end if;
         Seconds :=  Float'Value (aLine (Pos1 + 1 .. Pos2 - 1));
         AFC := theSpec.Animation_Frame_Count (Anim_Num);
--           Game_Utils.Game_Log ("Specs_Manager.Add_Animation_Frame, AFC: "
--                            & Int'Image (AFC));

         if AFC <= Max_Animations then
            anAnim := (Int (Atlas_Index), Single (Seconds));
            if Int (Anim_1D.Last_Index) < Anim_Num then
               Anim_1D.Append (anAnim);
            else
               Anim_1D.Replace_Element (Positive (Anim_Num), anAnim);
            end if;
            if Int (Anim_2D.Last_Index) < Anim_Num then
               Anim_2D.Append (Anim_1D);
            else
               Anim_2D.Replace_Element (Positive (Anim_Num), Anim_1D);
            end if;
            theSpec.Animations := Anim_2D;
            theSpec.Animation_Frame_Count (Anim_Num) :=
              theSpec.Animation_Frame_Count (Anim_Num) + 1;
         else
            raise Specs_Exception with
              "Specs_Manager.Add_Animation_Frame too many animation frames.";
         end if;
      else
         raise Specs_Exception with
           "Specs_Manager.Add_Animation_Frame invalid animation index: "
           & aLine (Pos1 .. Pos2 - 1);
      end if;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Specs_Manager.Add_Animation_Frame!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
   end Add_Animation_Frame;

   --  -------------------------------------------------------------------------

   procedure Add_Attack_Duration (aLine : String; theSpec : in out Spec_Data) is
      use Ada.Strings;
      Weapon_ID : Weapon_Type := Na_Wt;
      Seconds   : Float := 0.0;
      L_Length    : constant Integer := aLine'Length;
      Pos1        : Integer := Fixed.Index (aLine, ":");
      Pos2        : Integer := Fixed.Index (aLine (Pos1 + 2 .. L_Length), " ");
   begin
      Weapon_ID := Weapon_Type'Enum_Val (Int'Value (aLine (Pos1 + 2 .. Pos2 - 1)));
      if Weapon_ID'Valid then
         Game_Utils.Game_Log ("ERROR: invalid weapon ID in attack event.");
         Weapon_ID := Na_Wt;
      else
         Pos1 := Fixed.Index (aLine (Pos2 + 1 .. L_Length), ":");
         Seconds :=  Float'Value (aLine (Pos1 + 2 .. L_Length));
         theSpec.Weapon_Attack_Time (Weapon_ID) := Seconds;
      end if;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Specs_Manager.Add_Attack_Duration!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
   end Add_Attack_Duration;

   --  -------------------------------------------------------------------------

   procedure Add_Attack_Event (aLine : String; theSpec : in out Spec_Data) is
      use Ada.Strings;
      Weapon_ID   : Weapon_Type := Na_Wt;
      Last        : constant Natural := aLine'Last;
      Pos1        : Integer := Fixed.Index (aLine, ":");
      Pos2        : Integer := Fixed.Index (aLine (Pos1 + 2 .. Last), " ");
      AEC         : Integer;
      anEvent     : Attack_Event;
   begin
      Put_Line ("Specs_Manager.Add_Attack_Event, Weapon_ID int: " &
                  aLine (Pos1 + 2 .. Pos2 - 1));
      Weapon_ID := Weapon_Type'Enum_Val (Integer'Value (aLine (Pos1 + 2 .. Pos2 - 1)));
      Game_Utils.Game_Log ("Specs_Manager.Add_Attack_Event, Weapon_ID: " &
                                   Weapon_Type'Image (Weapon_ID));
      Put_Line ("Specs_Manager.Add_Attack_Event, Weapon_ID: " &
                                   Weapon_Type'Image (Weapon_ID));
      if Weapon_ID'Valid then
         --  "time:"
         Pos1 := Fixed.Index (aLine (Pos2 + 1 .. Last), ":");
         Pos2 := Fixed.Index (aLine (Pos1 + 2 .. Last), " ");
         anEvent.Time_Sec := Single'Value (aLine (Pos1 + 2 .. Pos2 - 1));
         --  "location:"
         Pos1 := Fixed.Index (aLine (Pos2 + 1 .. Last), "(");
         Pos2 := Fixed.Index (aLine (Pos1 + 1 .. Last), ",");
         anEvent.Location (GL.X) := Single'Value (aLine (Pos1 + 1 .. Pos2 - 1));
         Pos1 := Fixed.Index (aLine (Pos2 + 1 .. Last), ",");
         anEvent.Location (GL.Y) := Single'Value (aLine (Pos2 + 1 .. Pos1 - 1));
         Pos2 := Fixed.Index (aLine (Pos1 + 1 .. Last), ")");
         anEvent.Location (GL.Z) := Single'Value (aLine (Pos1 + 1 .. Pos2 - 1));
         --  "radius_m:"
         Pos1 := Fixed.Index (aLine (Pos2 + 1 .. Last), ":");
         Pos2 := Fixed.Index (aLine (Pos1 + 2 .. Last), " ");
         anEvent.Radius := Single'Value (aLine (Pos1 + 2 .. Pos2 - 1));
         --  "min_damage:"
         Pos1 := Fixed.Index (aLine (Pos2 + 1 .. Last), ":");
         Pos2 := Fixed.Index (aLine (Pos1 + 2 .. Last), " ");
         anEvent.Min_Damage := Int'Value (aLine (Pos1 + 1 .. Pos2 - 1));
         --  "max_damage:"
         Pos1 := Fixed.Index (aLine (Pos2 + 1 .. Last), ":");
         Pos2 := Fixed.Index (aLine (Pos1 + 2 .. Last), " ");
         anEvent.Max_Damage := Int'Value (aLine (Pos1 + 1 .. Pos2 - 1));
         --  "throw_back_mps:"
         Pos1 := Fixed.Index (aLine (Pos2 + 1 .. Last), ":");
         anEvent.Throw_Back_MPS := Single'Value (aLine (Pos1 + 1 .. Last));

         AEC := theSpec.Attack_Event_Count (Weapon_ID);
         if AEC < 0 or AEC >= Integer (Max_Attack_Events) then
            raise Specs_Exception with
              "Specs_Manager.Add_Attack_Event, too many attack_event instances.";
         else
            Game_Utils.Game_Log ("Adding attack_event time: " &
                                   Single'Image (anEvent.Time_Sec));
            theSpec.Attack_Events (Weapon_ID).Append (anEvent);
            theSpec.Attack_Event_Count (Weapon_ID) :=
              theSpec.Attack_Event_Count (Weapon_ID) + 1;
         end if;
      else
         raise Specs_Exception with
           "Specs_Manager.Add_Attack_Event invalid weapon index.";
      end if;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Specs_Manager.Add_Attack_Event!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
   end Add_Attack_Event;

   --  -------------------------------------------------------------------------

   procedure Clear_Specs is
   begin
      Specs.Clear;
   end Clear_Specs;

   --  -------------------------------------------------------------------------

   function Get_Script_Index (File_Name : String) return Integer is
      use Specs_Package;
      Curs       : Cursor := Specs.First;
      Data       : Spec_Data;
      Found      : Boolean := False;
      Spec_Index : Integer := 0;
   begin
      while Has_Element (Curs) and not Found loop
         Data := Element (Curs);
         Found := Data.File_Name = File_Name;
         if Found then
            Spec_Index := To_Index (Curs);
         end if;
         Next  (Curs);
      end loop;

      if not Found then
         Game_Utils.Game_Log
           ("Specs_Manager.Get_Script_Index loading specs file: " &
              File_Name);
         Load_Specs_File (File_Name);
      end if;

      return Spec_Index;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Specs_Manager.Get_Script_Index!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         return -1;
   end Get_Script_Index;

   --  -------------------------------------------------------------------------


   procedure Load_Specs_File (File_Name : String) is
      use Ada.Strings;
      Path          : constant String := "src/characters/" & File_Name;
      Input_File    : File_Type;
      --          Attack_Sound  : Integer := 0;
      theSpec       : Spec_Data;
   begin
      Open (Input_File, In_File, Path);
      theSpec.File_Name := To_Unbounded_String (File_Name);
      Set_Specs_Defaults (theSpec);

      while not End_Of_File (Input_File) loop
         declare
            aLine    : constant String := Get_Line (Input_File);
            S_Length : constant Natural := aLine'Length;
            Pos1     : constant Natural := Fixed.Index (aLine, " ");
            Pos_M1   : Natural;
            Pos_P1   : constant Natural := Pos1 + 1;
         begin
            Game_Utils.Game_Log ("Specs_Manager.Load_Specs_File parsing " & aLine);
            if  aLine'Length > 0 then
               Pos_M1 := Pos1 - 1;
            end if;
            if  aLine'Length < 2 or else aLine (1 .. 1) = "#" or else
              aLine (1 .. 1) = "/"  then
               null;
            elsif aLine (1 .. Pos_M1) = "name" then
               theSpec.Name :=
                 To_Unbounded_String (aLine (Pos_P1 .. S_Length));
            elsif aLine (1 .. Pos_M1) = "team_id:" then
               theSpec.Team_ID :=
                 Integer'Value (aLine (Pos_P1 .. S_Length));
            elsif aLine (1 .. Pos_M1) = "sprite_map_diffuse" then
               declare
                  Map_Path : constant String := "src/textures/" & aLine (Pos_P1 .. S_Length);
               begin
               Texture_Manager.Load_Image_To_Texture
                 (Map_Path, theSpec.Atlas_Diffuse_ID, Use_Character_Mipmaps, True);
               end;
            elsif aLine (1 .. Pos_M1) = "sprite_map_specular" then
               declare
                  Map_Path : constant String := "src/textures/" & aLine (Pos_P1 .. S_Length);
               begin
               Texture_Manager.Load_Image_To_Texture
                 (Map_Path, theSpec.Atlas_Diffuse_ID, Use_Character_Mipmaps, True);
               end;
            elsif aLine (1 .. Pos_M1) = "sprite_map_rows" then
               theSpec.Atlas_Rows :=
                 Integer'Value (aLine (Pos_P1 .. S_Length));
            elsif aLine (1 .. Pos_M1) = "sprite_map_cols" then
               theSpec.Atlas_Cols :=
                 Integer'Value (aLine (Pos_P1 .. S_Length));
            elsif aLine (1 .. Pos_M1) = "sprite_map_cols" then
               theSpec.Atlas_Cols :=
                 Integer'Value (aLine (Pos_P1 .. S_Length));
            elsif aLine (1 .. Pos_M1) = "add_anim_frame" then
               Add_Animation_Frame (aLine, theSpec);
            elsif aLine (1 .. Pos_M1) = "attack_duration" then
               Add_Attack_Duration (aLine, theSpec);
            elsif aLine (1 .. Pos_M1) = "attack_event" then
               Add_Attack_Event (aLine, theSpec);

            end if;
         end;  --  declare block
      end loop;

      Close (Input_File);

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Specs_Manager.Load_Specs_File!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
   end Load_Specs_File;

   --  ----------------------------------------------------------------------------

   procedure Set_Specs_Defaults (aSpec : in out Spec_Data) is
   begin
      aSpec.Move_Speed_MPS := 4.0;
      aSpec.Height_Metre := 1.8;
      aSpec.Width_Radius := 0.5;
      aSpec.Initial_Health := 100;
      aSpec.Decapitated_Head_Prop_Script := -1;
      aSpec.Land_Move := True;
      aSpec.Tx_On_Death := -1;
   end Set_Specs_Defaults;

   --  -------------------------------------------------------------------------

end Specs_Manager;
