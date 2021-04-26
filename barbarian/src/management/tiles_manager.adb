
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Maths;

with Batch_Manager;
with Game_Utils;
with Settings;
with Sprite_World_Map;
with Texture_Manager;

package body Tiles_Manager is

   type Static_Light_Data is record
      Row      : Positive;
      Column   : Positive;
      Position : GL.Types.Singles.Vector3 := Maths.Vec3_0;
      Diffuse  : GL.Types.Singles.Vector3 := Maths.Vec3_0;
      Specular : GL.Types.Singles.Vector3 := Maths.Vec3_0;
      Distance : GL.Types.Single := 0.0;
   end record;

   package Static_Light_Package is new Ada.Containers.Vectors
     (Positive, Static_Light_Data);
   type Static_Light_List is new Static_Light_Package.Vector with null record;

   Static_Lights          : Static_Light_List;
   Tile_Rows              : Tile_Row_List;

   procedure Add_Static_Light (Row, Col                  : Tiles_RC_Index;
                               Tile_Height_Offset        : Integer;
                               Offset, Diffuse, Specular : Singles.Vector3;
                               Light_Range               : Single);
   function Get_Tile_Level (Index : Tiles_RC_Index) return Integer;
   function Is_Ramp (Index : Tiles_RC_Index) return Boolean;
   function Is_Water (Index : Tiles_RC_Index) return Boolean;
   procedure Parse_Facings_By_Row (File : File_Type);

   --  ------------------------------------------------------------------------

   procedure Add_Dummy_Manifold_Lights is
      use Maths;
   begin
      Add_Static_Light (1, 1, 0, Vec3_0, Vec3_0, Vec3_0, 0.0);
      Add_Static_Light (1, 1, 0, Vec3_0, Vec3_0, Vec3_0, 0.0);

   end Add_Dummy_Manifold_Lights;

   --  ----------------------------------------------------------------------------

   procedure Add_Static_Light (Row, Col                  : Tiles_RC_Index;
                               Tile_Height_Offset        : Integer;
                               Offset, Diffuse, Specular : Singles.Vector3;
                               Light_Range               : Single) is
      use Batch_Manager;
      use Batches_Package;
      Curs          : Batches_Package.Cursor := Batch_List.First;
      aBatch        : Batch_Meta;
      Tile_Index    : constant Tiles_RC_Index := Row * Positive (Max_Map_Cols) + Col;
      X             : constant Single := Single (2 * Col) + Offset (GL.X);
      Y             : constant Single :=
                        Single (2 * Get_Tile_Level (Tile_Index) +
                                  Tile_Height_Offset) + Offset (GL.Y);
      Z             : constant Single := Single (2 * (Row - 1)) + Offset (GL.Z);
      Total_Batches : constant Integer := Batches_Across * Batches_Down;
      --          Sorted        : Boolean := False;
      New_Light     : Static_Light_Data;
   begin
      --        Put_Line ("Tiles_Manager.Add_Static_Light Total_Batches: " &
      --                 Integer'Image (Total_Batches));
      New_Light.Row := Positive (Row);
      New_Light.Column := Positive (Col);
      New_Light.Position := (X, Y, Z);
      New_Light.Diffuse := Diffuse;
      New_Light.Specular := Specular;
      New_Light.Distance := Light_Range;
      Static_Lights.Append (New_Light);

      if Batch_List.Is_Empty then
         raise Tiles_Manager_Exception with
           "Tiles_Manager.Add_Static_Light Batch_List is empty! ";
      end if;

      --        Put_Line ("Tiles_Manager.Add_Static_Light Batch_List size: " &
      --                 Integer'Image (Integer (Batch_List.Length)));
      for index in 0 .. Total_Batches - 1 loop
         --           Put_Line ("Tiles_Manager.Add_Static_Light index: " &
         --                       Integer'Image (index));
         aBatch := Batch_List.Element (index);
         aBatch.Static_Light_Indices.Append (Static_Lights.Last_Index);
         Update_Batch (index, aBatch);
      end loop;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Add_Static_Light!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;

   end Add_Static_Light;

   --  ----------------------------------------------------------------------------

   procedure Add_Tiles_To_Batches is
      use Batch_Manager.Batches_Package;
      Total_Tiles : constant Integer := Max_Map_Rows * Max_Map_Cols;
      Row         : Natural;
      Column      : Natural;
      B_Across    : Natural;
      B_Down      : Natural;
      aBatch      : Batch_Manager.Batch_Meta;
      Batch_Index : Natural;
   begin
      --        Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches Max_Rows, Max_Cols, Batches_Across " &
      --                               Integer'Image (Max_Map_Rows) & ", " &
      --                               Integer'Image (Max_Map_Cols) & ", " &
      --                               Integer'Image (Batches_Across));
      --
      --        Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches Total_Tiles: " &
      --                              Integer'Image (Total_Tiles));

      --  Tile_Batch_Width = 8 is the number of tiles*tiles to put into each batch
      --  a map is a Max_Map_Rows x Max_Map_Cols data frame in a map file
      --  32 x 32 for Introduction.map
      --  Total number of tiles = Max_Map_Rows x Max_Map_Cols
      --  Split Tile indicies into 16 batches of 8 tiles per batch
      for Tile_Index in 0 .. Total_Tiles - 1 loop
         Row := Natural (Tile_Index / Max_Map_Cols);
         --  Row = Tile_Index / 32 truncates towards 0 for integers
         --                        Tile_Index and Max_Map_Cols]
         Column := Natural (Tile_Index) - Row * Natural (Max_Map_Cols);
         --  Column = Tile_Index - 32 * Row;
         --           Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches row, col " &
         --                                 Integer'Image (Row) & ", " & Integer'Image (Column));
         B_Across := Column / Settings.Tile_Batch_Width;
         --  B_Across = Column / 8
         B_Down := Row / Settings.Tile_Batch_Width;
         --   B_Down = Row / 8
         --           Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches B_Down, B_Across " &
         --                                  Integer'Image (B_Down) &  ", " &
         --                                  Integer'Image (B_Across));
         Batch_Index := Row / 8 * Batches_Across + B_Across;
         --  Batch_Index = 32 * B_Down + Column / 8;
         --           Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches Batch_Index, Tile_Index" &
         --                                  Integer'Image (Batch_Index) & ", " &
         --                                  Integer'Image (Tile_Index) );
         --  Add_Tile_Index_To_Batch
         if Batch_Index <= Batch_Manager.Batch_List.Last_Index then
            Batch_Manager.Add_Tile_To_Batch (Batch_Index, Tile_Index);
         else
            aBatch.Tile_Indices.Clear;
            aBatch.Tile_Indices.Append (Tile_Index);
            Batch_Manager.Add_Batch_To_Batch_List (aBatch);
         end if;
      end loop;

      Print_Tile_Indices ("Tiles_Manager.Add_Tiles_To_Batches Batch 1:",
                           Batch_Manager.Batch_List.Element (1).Tile_Indices);
      --        Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches Batch_List, range " &
      --                               Integer'Image (Batch_List.First_Index) & ", " &
      --                               Integer'Image (Batch_List.Last_Index));
      Batch_Manager.Regenerate_Batches;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Add_Tiles_To_Batches!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Add_Tiles_To_Batches;

   --  ----------------------------------------------------------------------------

   function Get_Facing (Index : Tiles_RC_Index) return Character is
      aTile  : constant Tile_Data := Get_Tile (Index);
   begin
      return aTile.Facing;
   end Get_Facing;

   --  ----------------------------------------------------------------------------

   function Get_Facing (Map : Ints.Vector2) return Character is
      use Batch_Manager;
      Tile_Index : Tiles_RC_Index;
      Result     : Character := 'N';
   begin
      if Map (GL.X) > 0 and Map (GL.X) < Int (Max_Map_Rows) and
        Map (GL.Y) > 0 and Map (GL.Y) < Int (Max_Map_Cols) then
         Tile_Index :=  Positive (Map (GL.X)) * Max_Map_Cols + Positive (Map (GL.Y));
         Result := Get_Facing (Tile_Index);
      end if;
      return Result;
   end Get_Facing;

   --  ----------------------------------------------------------------------------

   --     function Get_Tile (Row_Curs  : Tile_Row_Package.Cursor;
   --                        Col_Curs  : Tile_Column_Package.Cursor)
   --                        return Tile_Data is
   --        use Batch_Manager;
   --        use Tile_Row_Package;
   --
   --        Row_Index : constant Tiles_RC_Index := To_Index (Row_Curs);
   --        Col_Index : constant Tiles_RC_Index := To_Index (Col_Curs);
   --        Tile_Row  : constant Tile_Column_List := Tile_Rows (Row_Index);
   --     begin
   --        return  Tile_Row.Element (Col_Index);
   --     end Get_Tile;

   --  ----------------------------------------------------------------------------

   function Get_Tile (Pos : Ints.Vector2) return Tile_Data is
      use Batch_Manager;
      use Tile_Row_Package;
      Row_Vector : constant Tile_Column_List :=
                     Tile_Rows.Element (Natural (Pos (GL.X)));
   begin
      return  Row_Vector.Element (Natural (Pos (GL.Y)));

   exception
      when anError : others =>
         Put ("Tiles_Manager.Get_Tile Vector2 exception: ");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;

   end Get_Tile;

   --  --------------------------------------------------------------------------

   function Get_Tile (Tile_Index : Natural) return Tile_Data is
      use Batch_Manager;
      use Tile_Row_Package;
      Row        : constant Natural := Tile_Index / Positive (Max_Map_Cols);
      Column     : constant Natural := Tile_Index - Row * Positive (Max_Map_Cols);
      Row_Vector : constant Tile_Column_List := Tile_Rows (Row);
   begin
      return  Row_Vector.Element (Column);

   exception
      when anError : others =>
         Put ("Tiles_Manager.Get_Tile Natural exception: ");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;

   end Get_Tile;

   --  --------------------------------------------------------------------------

   --  returns actual height in meters (manifold.h get_tile_level)
   function Get_Tile_Height
     (X, Z : Single; Consider_Water, Respect_Ramps : Boolean) return Single  is
      use Batch_Manager;
      use Tile_Row_Package;
      use Tile_Column_Package;
      Col        : Tiles_RC_Index := Tiles_RC_Index (0.5 * (1.0 + X));
      Row        : Tiles_RC_Index := Tiles_RC_Index (0.5 * (1.0 + Z));
      Row_Curs   : constant Tile_Row_Cursor := Tile_Rows.To_Cursor (Row);
      Tile_Row   : constant Tile_Column_List := Element (Row_Curs);
      Col_Curs   : constant Tile_Column_Cursor := Tile_Row.To_Cursor (Col);
      Tile_Index : Tiles_RC_Index;
      aTile      : Tile_Data;
      --        aTile    : constant Tile_Data := Get_Tile ((Row, Col));
      S          : Single;
      T          : Single;
      Height     : Single := 0.0;
   begin
      --        Game_Utils.Game_Log ("Tiles_Manager.Get_Tile_Height X, Z: " &
      --                              Single'Image (X) & ", " & Single'Image (Z) );
      Col := Tiles_RC_Index (0.5 * (1.0 + X));
      Row := Tiles_RC_Index (0.5 * (1.0 + Z));
      Tile_Index := Row * Positive (Max_Map_Cols) + Col;
      --        Game_Utils.Game_Log ("Tiles_Manager.Get_Tile_Height Row, Col: " &
      --                              Integer'Image (Row) & ", " & Integer'Image (Col));
      --        Game_Utils.Game_Log ("Tiles_Manager.Get_Tile_Height Tile_Index: " &
      --                               Integer'Image (Tile_Index));
      aTile := Get_Tile (Tile_Index);
      if X < -1.0 or Col > Tiles_RC_Index (Max_Map_Cols) or Z < -1.0 or
        Row > Tiles_RC_Index (Max_Map_Rows) then
         Height := Out_Of_Bounds_Height;
         --           Game_Utils.Game_Log ("Tiles_Manager.Get_Tile_Height Out_Of_Bounds_Height" &
         --                                 Single'Image (Height));
      else
         Height := 2.0 * Single (aTile.Height);
         --           Game_Utils.Game_Log ("Tiles_Manager.Get_Tile_Height " &
         --                                 Single'Image (Height));
         if Respect_Ramps and then Is_Ramp (Tile_Index) then
            --  Work out position within ramp. subtract left-most pos from x, etc.
            S := 0.5 * (1.0 + X - Single (2 * Col));
            T := 0.5 * (1.0 + Z - Single (2 * Row));
            --  Work out facing of ramp
            if aTile.Facing = 'N' then
               Height := Height + 2.0 * (1.0 - T);
            elsif aTile.Facing = 'S' then
               Height := Height + 2.0 * T;
            elsif aTile.Facing = 'W' then
               Height := Height + 2.0 * (1.0 - S);
            elsif aTile.Facing = 'E' then
               Height := Height + 2.0 * S;
            end if;
         elsif Consider_Water and then Is_Water (Tile_Index) then
            Height := Height - 0.5;
         end if;
      end if;
      --        Game_Utils.Game_Log ("Tiles_Manager.Get_Tile_Height row, col " &
      --                               Integer'Image (Row) & ", " & Integer'Image (Col));
      return Height;

   exception
      when anError : others =>
         Put ("Tiles_Manager.Get_Tile_Height exception: ");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;

   end Get_Tile_Height;

   --  ----------------------------------------------------------------------------

   function Get_Tile_Level (Index : Tiles_RC_Index) return Integer is
      --        use Batch_Manager;
      --        aTile : constant Tile_Data := Get_Tile (Index);
   begin
      return Get_Tile (Index).Height;
   end Get_Tile_Level;

   --  ----------------------------------------------------------------------------

   function Get_Tile_Type (Index : Tiles_RC_Index) return Character is
      --        use Batch_Manager;
      --        aTile : constant Tile_Data := Get_Tile (Index);
   begin
      return Get_Tile (Index).Tile_Type;
   end Get_Tile_Type;

   --  ----------------------------------------------------------------------------

   function Is_Ramp (Index : Tiles_RC_Index) return Boolean is
      --        use Batch_Manager;
      --        aTile : constant Tile_Data := Get_Tile (Index);
   begin
      return Get_Tile (Index).Tile_Type = '/';
   end Is_Ramp;

   --  ----------------------------------------------------------------------------

   function Get_Tiles_Across return Natural is
   begin
      return Max_Map_Cols;
   end Get_Tiles_Across;

   --  ----------------------------------------------------------------------------

   function Is_Tile_Valid (Map : Ints.Vector2) return Boolean is
      use Batch_Manager;
   begin
      return Map (GL.Y) > 0 and Map (GL.Y) <= Int (Max_Map_Cols) and
        Map (GL.X) > 0 and Map (GL.X) <= Int (Max_Map_Rows);
   end Is_Tile_Valid;

   --  ----------------------------------------------------------------------------

   function Is_Water (Index : Tiles_RC_Index) return Boolean is
      use Batch_Manager;
      aTile : constant Tile_Data := Get_Tile (Index);
   begin
      return Get_Tile (Index).Tile_Type = '~';
   end Is_Water;

   --  ----------------------------------------------------------------------------

   procedure Load_Char_Rows (File  : File_Type; Load_Type : String) is
      use Ada.Strings;
      use Tile_Row_Package;
      Header     : constant String := Get_Line (File);
      Cols       : Integer := 0;
      Rows       : Integer := 0;
      Pos1       : constant Natural := Fixed.Index (Header, " ") + 1;
      Pos2       : Natural;
      Prev_Char  : Character;
      aTile      : Tile_Data;
      Tile_Row   : Tile_Column_List;
   begin
      if Fixed.Index (Header (1 .. Load_Type'Length), Load_Type) = 0 then
         Game_Utils.Game_Log ("Error: Invalid format, " & Load_Type &
                                " expected: " & Header (1 .. Pos1));
         raise Tiles_Manager_Exception with
           "Invalid format, " & Load_Type & " expected: " & Header (1 .. Pos1);
      end if;

      --          Game_Utils.Game_Log ("Manifold.Load_Char_Rows Load_Type: " & Load_Type);
      Pos2 := Fixed.Index (Header (Pos1 + 1 .. Header'Last), "x");
      Cols := Integer'Value (Header (Pos1 .. Pos2 - 1));
      Rows := Integer'Value (Header (Pos2 + 1 .. Header'Last));
      for row in 0 .. Rows - 1 loop
         Tile_Row := Tile_Rows.Element (row);
         declare
            aString  : constant String := Get_Line (File);
            aChar    : Character;
         begin
            if aString'Length < Max_Map_Cols then
               raise Tiles_Manager_Exception with
                 "Tiles_Manager.Load_Char_Rows: " & Load_Type &
                 " line has not enough columns.";
            end if;

            Prev_Char := ASCII.NUL;
            for col in 0 .. Cols - 1 loop
               aTile := Tile_Row.Element (col);
               aChar := aString (Integer (col + 1));
               if Prev_Char = '\' and then
                 (aChar = 'n' or aChar = ASCII.NUL) then
                  Tile_Rows.Delete_Last;
               else
                  aTile.Tile_Type := aChar;
               end if;

               if Has_Element (Tile_Row.To_Cursor (col)) then
                  Tile_Row.Replace_Element (col, aTile);
               else
                  raise Tiles_Manager_Exception with
                    "Load_Char_Rows is missing a tile row";
               end if;
            end loop;

            if Has_Element (Tile_Rows.To_Cursor (row)) then
               Tile_Rows.Replace_Element (row, Tile_Row);
            else
               raise Tiles_Manager_Exception with
                 "Load_Char_Rows is missing a tile row";
            end if;
            Prev_Char := aChar;
         end;  --  declare block
      end loop;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Load_Char_Rows!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Load_Char_Rows;

   --  ----------------------------------------------------------------------------

   procedure Load_Hex_Rows (File : File_Type; Load_Type : String) is
      use Ada.Strings;
      use Tile_Row_Package;
      Header     : constant String := Get_Line (File);
      Code_0     : constant Integer := Character'Pos ('0');
      Code_a     : constant Integer := Character'Pos ('a');
      Num_Cols   : Natural := 0;
      Num_Rows   : Natural := 0;
      Pos1       : constant Natural := Fixed.Index (Header, " ") + 1;
      Pos2       : Natural;
      Prev_Char  : Character;
      aTile      : Tile_Data;
      Tile_Row   : Tile_Column_List;
   begin
      if Fixed.Index (Header (1 .. Load_Type'Length), Load_Type) = 0 then
         Game_Utils.Game_Log ("Error: Load_Hex_Rows, Invalid format, " & Load_Type &
                                " expected: " & Header (1 .. Pos1));
         raise Tiles_Manager_Exception with
           "Load_Hex_Rows, Invalid format, " & Load_Type & " expected: " & Header (1 .. Pos1);
      end if;

      Pos2 := Fixed.Index (Header (Pos1 + 1 .. Header'Last), "x");
      Num_Cols := Integer'Value (Header (Pos1 .. Pos2 - 1));
      Num_Rows := Integer'Value (Header (Pos2 + 1 .. Header'Last));

      for row in 0 .. Num_Rows - 1 loop
         Tile_Row := Tile_Rows.Element (row);  --  List of Tile columns
         declare
            Columns    : constant String := Get_Line (File);
            Hex_Char   : Character;
            Hex_Int    : Hex_Digit;
         begin
            if Columns'Length < Max_Map_Cols then
               raise Tiles_Manager_Exception with
                 " Tiles_Manager.Load_Hex_Rows: " & Load_Type &
                 " line has not enough columns.";
            end if;

            Prev_Char := ASCII.NUL;
            for col in 0 .. Num_Cols - 1 loop
               aTile := Tile_Row.Element (col);
               Hex_Char := Columns (Integer (col + 1));
               if Prev_Char = '\' and then
                 (Hex_Char = 'n' or Hex_Char = ASCII.NUL) then
                  Tile_Rows.Delete_Last;
               else
                  if Hex_Char >= '0' and Hex_Char <= '9' then
                     Hex_Int := Character'Pos (Hex_Char) - Code_0;
                  else
                     Hex_Int := 10 + Character'Pos (Hex_Char) - Code_a;
                  end if;

                  if Load_Type = "textures" then
                     aTile.Texture_Index := Hex_Int;
                  elsif Load_Type = "heights" then
                     aTile.Height := Hex_Int;
                  end if;

                  if Has_Element (Tile_Row.To_Cursor (col)) then
                     Tile_Row.Replace_Element (col, aTile);
                  else
                     raise Tiles_Manager_Exception with
                       "Load_Hex_Rows is missing a tile column";
                  end if;
                  --                          if Load_Type = "textures" then
                  --                              Game_Utils.Game_Log
                  --                                ("Tiles_Manager.Load_Hex_Rows Tile row, col, Texture_Index: " &
                  --                                   Integer'Image (row) & ", " &
                  --                                   Integer'Image (col) & ", " &
                  --                                   Integer'Image (Tile_Row.Element (col).Texture_Index));
                  --                          end if;
               end if;
            end loop;

            if Has_Element (Tile_Rows.To_Cursor (row)) then
               Tile_Rows.Replace_Element (row, Tile_Row);
            else
               raise Tiles_Manager_Exception with
                 "Load_Hex_Rows is missing a tile row";
            end if;
            Prev_Char := Hex_Char;
         end;  --  declare block
      end loop;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Load_Hex_Rows!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Load_Hex_Rows;

   --  ----------------------------------------------------------------------------

   procedure Load_Palette_File_Names
     (File                                 : File_Type;
      Diff_Palette_Name, Spec_Palette_Name : out Unbounded_String) is
      --  Get_Palette_File_Name reads the file name identified by the label ID
      function  Get_Palette_File_Name (ID : String) return Unbounded_String is
         aLine : constant String := Get_Line (File);
         Label : constant String (1 .. 3) := aLine (1 .. 3);
      begin
         if Label /= ID then
            Game_Utils.Game_Log
              ("Tiles_Manager.Get_Palette_File_Name invalid format, expected "
               & "line commencing " & ID & " but obtained " & aLine);
            raise Tiles_Manager_Exception with
              "Tiles_Manager.Get_Palette_File_Name, invalid format, " & ID &
              " expected starting " & aLine;
         end if;
         Game_Utils.Game_Log
           ("Tiles_Manager.Get_Palette_File_Name File_Name: " &
              aLine (4 .. aLine'Last));
         return To_Unbounded_String ("src/" & aLine (4 .. aLine'Last));
      end Get_Palette_File_Name;

   begin
      Diff_Palette_Name := Get_Palette_File_Name ("dm ");
      Spec_Palette_Name := Get_Palette_File_Name ("sm ");

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Load_Palette_File_Names!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Load_Palette_File_Names;

   --  ------------------------------------------------------------------------

   procedure Load_Tile_And_Ramp_Textures
     (File          : File_Type; Tile_Diff_Tex, Tile_Spec_Tex, Ramp_Diff_Tex,
      Ramp_Spec_Tex : in out GL.Objects.Textures.Texture) is
      use Texture_Manager;
      Diff_Palette_Name     : Unbounded_String := To_Unbounded_String ("");
      Spec_Palette_Name     : Unbounded_String := To_Unbounded_String ("");
   begin
      Load_Palette_File_Names (File, Diff_Palette_Name, Spec_Palette_Name);

      Load_Image_To_Texture
        (To_String (Diff_Palette_Name), Tile_Diff_Tex, True, True);
      Load_Image_To_Texture (To_String (Spec_Palette_Name),
                             Tile_Spec_Tex, True, True);
      Load_Image_To_Texture ("src/textures/stepsTileSet1_diff.png",
                             Ramp_Diff_Tex, True, True);
      Load_Image_To_Texture ("src/textures/stepsTileSet1_spec.png",
                             Ramp_Spec_Tex, True, True);
   end Load_Tile_And_Ramp_Textures;

   --  ------------------------------------------------------------------------

   procedure Load_Tiles (File          : File_Type;
                         Tile_Tex, Tile_Spec_Tex, Ramp_Diff_Tex,
                         Ramp_Spec_Tex : in out GL.Objects.Textures.Texture) is
      use Ada.Strings;
      use Batch_Manager;
      use Settings;
      aLine    : constant String := Get_Line (File);
      Pos1     : Natural;
      Pos2     : Natural;
   begin
      Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, loading tiles and generating manifold from FP...");
      Pos1 := Fixed.Index (aLine, " ") + 1;
      if Fixed.Index (aLine, "facings ") = 0 then
         raise Tiles_Manager_Exception with
           "Tiles_Manager.Load_Tiles, invalid format, ""facings"" expected: " & aLine (1 .. Pos1);
      end if;

      Pos2 := Fixed.Index (aLine (Pos1 + 1 .. aLine'Last), "x");

      Max_Map_Cols := Integer'Value (aLine (Pos1 .. Pos2 - 1));
      Max_Map_Rows := Integer'Value (aLine (Pos2 + 1 .. aLine'Last));
      Total_Tiles := Max_Map_Rows * Max_Map_Cols;
      Batches_Across :=
        Integer (Float'Ceiling (Float (Max_Map_Cols) / Float (Tile_Batch_Width)));
      Batches_Down :=
        Integer (Float'Ceiling (Float (Max_Map_Rows) / Float (Tile_Batch_Width)));

      Tile_Rows.Clear;
      --          Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, Batches_Across, Batches_Down"
      --                               & Integer'Image (Batches_Across) & ", " &
      --                                 Integer'Image (Batches_Down));
      --  Parse_Facings_By_Row initializes Tile_Rows
      Parse_Facings_By_Row (File);

      Load_Hex_Rows (File, "textures");  --  textures header and rows
      Load_Char_Rows (File, "types");
      Load_Hex_Rows (File, "heights");

      --          Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, heights loaded.");

      --          Load_Palette_File_Names (File);
      Load_Tile_And_Ramp_Textures (File, Tile_Tex, Tile_Spec_Tex,
                                   Ramp_Diff_Tex, Ramp_Spec_Tex);

      --          Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, Textures loaded.");
      Add_Tiles_To_Batches;
      --          Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, Tiles added To_Batches.");
      Add_Dummy_Manifold_Lights;

      Sprite_World_Map.Init;

      Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, Tiles loaded and Manifold generated.");

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Load_Tiles!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Load_Tiles;

   --  ----------------------------------------------------------------------------

   function Number_Of_Tiles return Integer is
   begin
      return Integer (Tile_Rows.Length);
   end Number_Of_Tiles;

   --  ------------------------------------------------------------------------

   procedure Parse_Facings_By_Row (File : File_Type) is
      use Tile_Row_Package;
      use Tile_Column_Package;
      Prev_Char  : Character;
      aTile      : Tile_Data;
      Tile_Col   : Tile_Column_List;
   begin
      --  Parse_Facings_By_Row initalizes the Tiles list.
      --          Game_Utils.Game_Log ("Tiles_Manager.Parse_Facings_By_Row Max_Map_Rows, Max_Map_Cols "
      --                               & Integer'Image (Max_Map_Rows) & ", " &
      --                                 Integer'Image (Max_Map_Cols));
      for row in 1 .. Max_Map_Rows loop
         declare
            aString     : constant String := Get_Line (File);
            Line_Length : constant Integer := aString'Length;
            Text_Char   : Character;
         begin
            if Line_Length < Integer (Max_Map_Cols) then
               raise Tiles_Manager_Exception with
                 "Tiles_Manager.Parse_Facings_By_Row, facings line has not enough columns";
            end if;

            Prev_Char := ASCII.NUL;
            Tile_Col.Clear;
            for col in 1 .. Max_Map_Cols loop
               Text_Char := aString (Integer (col));
               if Prev_Char = '\' and then
                 (Text_Char = 'n' or Text_Char = ASCII.NUL) then
                  Tile_Rows.Delete_Last;
               else
                  aTile.Facing := Text_Char;
               end if;

               Tile_Col.Append (aTile);
            end loop;
            Prev_Char := Text_Char;
         end;
         Tile_Rows.Append (Tile_Col);
      end loop;
      --          Game_Utils.Game_Log ("Tiles_Manager.Parse_Facings_By_Row done Tile Rows range: "
      --                               & Integer'Image (Integer (Tile_Rows.First_Index)) & ", "
      --                               &  Integer'Image (Integer (Tile_Rows.Last_Index)));

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Parse_Facings_By_Row!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Parse_Facings_By_Row;

   --  ----------------------------------------------------------------------------
   --  Corresponds to while loop inmanifold.cpp print_tile_indices
   procedure Print_Tile_Indices (Name : String; Tiles : Tile_Indices_List) is
      aTile : Tile_Data;
   begin
      for index in Tiles.First_Index .. Tiles.Last_Index loop
         aTile := Get_Tile (index);
         Game_Utils.Game_Log (Name & " Tile " & Integer'Image (index) &
                                "  tile index: " &
                                Integer'Image (Tiles.Element (index)) &
                                " texture index: "
                              & Integer'Image (aTile.Texture_Index));
      end loop;
      Game_Utils.Game_Log ("");
   end Print_Tile_Indices;

   --  ----------------------------------------------------------------------------

end Tiles_Manager;
