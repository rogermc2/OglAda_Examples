
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

   Static_Lights         : Static_Light_List;
   Diff_Palette_Name     : Unbounded_String := To_Unbounded_String ("");
   Spec_Palette_Name     : Unbounded_String := To_Unbounded_String ("");

   Tiles                 : Tile_Row_List;

   procedure Add_Static_Light (Row, Col                  : Tiles_Index;
                               Tile_Height_Offset        : Integer;
                               Offset, Diffuse, Specular : Singles.Vector3;
                               Light_Range               : Single);
   function Get_Tile_Level (Row, Col : Tiles_Index) return Integer;
   function Is_Ramp (Row, Col : Tiles_Index) return Boolean;
   function Is_Water (Row, Col : Tiles_Index) return Boolean;
   procedure Parse_Facings_By_Row (File : File_Type; Max_Rows, Max_Cols : Int);

   --  ------------------------------------------------------------------------

   procedure Add_Dummy_Manifold_Lights is
      use Maths;
   begin
      Add_Static_Light (1, 1, 0, Vec3_0, Vec3_0, Vec3_0, 0.0);
      Add_Static_Light (1, 1, 0, Vec3_0, Vec3_0, Vec3_0, 0.0);
   end Add_Dummy_Manifold_Lights;

   --  ----------------------------------------------------------------------------

   procedure Add_Static_Light (Row, Col                  : Tiles_Index;
                               Tile_Height_Offset        : Integer;
                               Offset, Diffuse, Specular : Singles.Vector3;
                               Light_Range               : Single) is
      use Batch_Manager;
      use Batches_Package;
      Curs          : Batches_Package.Cursor := Batches.First;
      aBatch        : Batch_Meta;
      X             : constant Single := Single (2 * Col) + Offset (GL.X);
      Y             : constant Single := Single (2 * Get_Tile_Level (Col, Row) + Tile_Height_Offset) +
                        Offset (GL.Y);
      Z             : constant Single := Single (2 * (Row - 1)) + Offset (GL.Z);
      Total_Batches : constant Integer := Batches_Across * Batches_Down;
      --          Sorted        : Boolean := False;
      New_Light     : Static_Light_Data;
   begin
      New_Light.Row := Positive (Row);
      New_Light.Column := Positive (Col);
      New_Light.Position := (X, Y, Z);
      New_Light.Diffuse := Diffuse;
      New_Light.Specular := Specular;
      New_Light.Distance := Light_Range;
      Static_Lights.Append (New_Light);

      for index in 1 .. Total_Batches loop
         aBatch := Batches.Element (index);
         aBatch.Static_Light_Indices.Append (Static_Lights.Last_Index);
         Update_Batch (index, aBatch);
      end loop;

   end Add_Static_Light;

   --  ----------------------------------------------------------------------------

   procedure Add_Tile (Batch                : in out Batch_Manager.Batch_Meta;
                       Row_Index, Col_Index : Positive) is
   begin
      --        Game_Utils.Game_Log ("Tiles_Manager.Add_Tile_Index Tile_Index " &
      --                                 Integer'Image (Tile_Index));
      Batch.Tiles.Append ((Int (Row_Index), Int (Col_Index)));
   end Add_Tile;

   --  ----------------------------------------------------------------------------

   procedure Add_Tiles_To_Batches is
      use Batch_Manager;
      use Batches_Package;
      Batch_Across  : Natural;
      Batch_Down    : Natural;
      Batch         : Batch_Manager.Batch_Meta;
      Batch_Index   : Positive;
   begin
      --                Game_Utils.Game_Log ("Manifold.Add_Tiles_To_Batches Max_Rows, Max_Cols " &
      --                                       Int'Image (Max_Rows) & ", " &
      --                                       Int'Image (Max_Cols));

--        Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches Settings.Tile_Batch_Width " &
--                              Integer'Image (Settings.Tile_Batch_Width));

      for Row in 1 .. Integer (Max_Rows) loop
         Batch_Down  := Integer (Row - 1) / Settings.Tile_Batch_Width;
         for Col in 1 .. Integer (Max_Cols) loop
--              Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches row, col " &
--                                   Integer'Image (row) & ", " & Integer'Image (col));
            Batch_Across := Integer (Col - 1) / Settings.Tile_Batch_Width;
            Batch_Index := Batches_Across * Batch_Down + Batch_Across + 1;
            if Has_Element (Batches.To_Cursor (Batch_Index)) then
               Batch := Batches.Element (Batch_Index);
               Add_Tile (Batch, Row, Col);
               Update_Batch (Batch_Index, Batch);
            else
               Add_Tile (Batch, Row, Col);
               Add_Batch (Batch);
            end if;
         end loop;
      end loop;

      for index in Batches.First_Index .. Batches.Last_Index loop
         Game_Utils.Game_Log ("Tiles_Manager.Add_Tiles_To_Batches index " &
                                Integer'Image (index));
         Regenerate_Batch (index);
      end loop;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Add_Tiles_To_Batches!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Add_Tiles_To_Batches;

   --  ----------------------------------------------------------------------------

   function Get_Facing (Pos : Ints.Vector2) return Character is
      aTile  : constant Tile_Data := Get_Tile (Pos);
   begin
      return aTile.Facing;
   end Get_Facing;

   --  ----------------------------------------------------------------------------

   function Get_Tile (Row_Curs  : Tile_Row_Package.Cursor;
                      Col_Curs  : Tile_Column_Package.Cursor)
                       return Tile_Data is
      use Batch_Manager;
      use Tile_Row_Package;

      Row_Index : constant Tiles_Index := To_Index (Row_Curs);
      Col_Index : constant Tiles_Index := To_Index (Col_Curs);
      Row       : constant Tile_Column_List := Tiles (Row_Index);
   begin
      return  Row.Element (Col_Index);
   end Get_Tile;

   --  ----------------------------------------------------------------------------

   function Get_Tile (Pos : Ints.Vector2) return Tile_Data is
      use Batch_Manager;
      use Tile_Row_Package;
      Row_Vector : constant Tile_Column_List := Tiles (Pos (GL.X));
   begin
      return  Row_Vector.Element (Pos (GL.Y));
   end Get_Tile;

   --  ----------------------------------------------------------------------------

   function Get_Tile_Height
     (X, Z : Single; Consider_Water, Respect_Ramps : Boolean) return Single  is
      use Batch_Manager;
      use Tile_Row_Package;
      use Tile_Column_Package;
      Col      : constant Tiles_Index := Tiles_Index (0.5 * (1.0 + X));
      Row      : constant Tiles_Index := Tiles_Index (0.5 * (1.0 + Z));
      Row_Curs : constant Tile_Row_Cursor := Tiles.To_Cursor (Row);
      Tile_Row : constant Tile_Column_List := Element (Row_Curs);
      Col_Curs : constant Tile_Column_Cursor := Tile_Row.To_Cursor (Col);
      aTile    : constant Tile_Data := Get_Tile ((Row, Col));
      S        : Single;
      T        : Single;
      Height   : Single := 0.0;
   begin
      if X < -1.0 or Col > Tiles_Index (Max_Cols) or Z < -1.0 or
        Row > Tiles_Index (Max_Rows) then
         Height := Out_Of_Bounds_Height;
      else
         Height := 2.0 * Single (aTile.Height);
         if Respect_Ramps and then Is_Ramp (Row, Col) then
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
         elsif Consider_Water and then Is_Water (Col, Row) then
            Height := Height - 0.5;
         end if;
      end if;
      --        Game_Utils.Game_Log ("Tiles_Manager.Get_Tile_Height row, col " &
      --                               Int'Image (Row) & ", " & Int'Image (Col));
      return Height;
   end Get_Tile_Height;

   --  ----------------------------------------------------------------------------

   function Get_Tile_Level (Row, Col : Tiles_Index) return Integer is
      use Batch_Manager;
      aTile : constant Tile_Data := Get_Tile ((Row, Col));
   begin
      return aTile.Height;
   end Get_Tile_Level;

   --  ----------------------------------------------------------------------------

   function Is_Ramp (Row, Col : Tiles_Index) return Boolean is
      use Batch_Manager;
      aTile : constant Tile_Data := Get_Tile ((Row, Col));
   begin
      return aTile.Tile_Type = '/';
   end Is_Ramp;

   --  ----------------------------------------------------------------------------

   function Get_Tiles_Across return Int is
   begin
      return Batch_Manager.Max_Cols;
   end Get_Tiles_Across;

   --  ----------------------------------------------------------------------------

   function Is_Tile_Valid (Map : Ints.Vector2) return Boolean is
      use Batch_Manager;
   begin
      return Map (GL.Y) > 0 and Map (GL.Y) <= Max_Cols and
        Map (GL.X) > 0 and Map (GL.X) <= Max_Rows;
   end Is_Tile_Valid;

   --  ----------------------------------------------------------------------------

   function Is_Water (Row, Col : Tiles_Index) return Boolean is
      use Batch_Manager;
      aTile : constant Tile_Data := Get_Tile ((Row, Col));
   begin
      return aTile.Tile_Type = '~';
   end Is_Water;

   --  ----------------------------------------------------------------------------

   procedure Load_Char_Rows (File  : File_Type; Load_Type : String) is
      use Ada.Strings;
      use Tile_Row_Package;
      Header     : constant String := Get_Line (File);
      Cols       : Int := 0;
      Rows       : Int := 0;
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

      Pos2 := Fixed.Index (Header (Pos1 + 1 .. Header'Last), "x");
      Cols := Int'Value (Header (Pos1 .. Pos2 - 1));
      Rows := Int'Value (Header (Pos2 + 1 .. Header'Last));
      for row in 1 .. Rows loop
         Tile_Row := Tiles.Element (row);
         declare
            aString  : constant String := Get_Line (File);
            aChar    : Character;
         begin
            if aString'Length < Batch_Manager.Max_Cols then
               raise Tiles_Manager_Exception with
                 "Tiles_Manager.Load_Char_Rows: " & Load_Type &
                 " line has not enough columns.";
            end if;

            Prev_Char := ASCII.NUL;
            for col in 1 .. Cols loop
               aTile := Tile_Row.Element (col);
               aChar := aString (Integer (col));
               if Prev_Char = '\' and then
                 (aChar = 'n' or aChar = ASCII.NUL) then
                  Tiles.Delete_Last;
               else
                  aTile.Tile_Type := aChar;
               end if;

               if Has_Element (Tile_Row.To_Cursor (col)) then
                  Tile_Row.Replace_Element (col, aTile);
               else
                  Tile_Row.Append (aTile);
               end if;
            end loop;
            if Has_Element (Tiles.To_Cursor (row)) then
               Tiles.Replace_Element (row, Tile_Row);
            else
               Tiles.Append (Tile_Row);
            end if;
            Prev_Char := aChar;
         end;  --  declare block
      end loop;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Manifold.Load_Char_Rows!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Load_Char_Rows;

   --  ----------------------------------------------------------------------------

   procedure Load_Int_Rows (File  : File_Type; Load_Type : String) is
      use Ada.Strings;
      use Tile_Row_Package;
      Header     : constant String := Get_Line (File);
      Code_0     : constant Integer := Character'Pos ('0');
      Code_a     : constant Integer := Character'Pos ('a');
      Cols       : Int := 0;
      Rows       : Int := 0;
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

      Pos2 := Fixed.Index (Header (Pos1 + 1 .. Header'Last), "x");
      Cols := Int'Value (Header (Pos1 .. Pos2 - 1));
      Rows := Int'Value (Header (Pos2 + 1 .. Header'Last));

      for row in Int range 1 .. Rows loop
         Tile_Row := Tiles.Element (row);
         declare
            aString    : constant String := Get_Line (File);
            Tex_Char   : Character;
            Tex_Int    : Integer;
         begin
            if aString'Length < Batch_Manager.Max_Cols then
               raise Tiles_Manager_Exception with
                 " Tiles_Manager.Load_Int_Rows: " & Load_Type &
                 " line has not enough columns.";
            end if;

            Prev_Char := ASCII.NUL;
            for col in 1 .. Cols loop
               aTile := Tile_Row.Element (col);
               Tex_Char := aString (Integer (col));
               if Prev_Char = '\' and then
                 (Tex_Char = 'n' or Tex_Char = ASCII.NUL) then
                  Tiles.Delete_Last;
               else
                  if Tex_Char >= '0' and Tex_Char <= '9' then
                     Tex_Int := Character'Pos (Tex_Char) - Code_0;
                  else
                     Tex_Int := 10 + Character'Pos (Tex_Char) - Code_a;
                  end if;

                  if Load_Type = "textures" then
                     aTile.Texture_Index := Tex_Int;
                  elsif Load_Type = "heights" then
                     aTile.Height := Tex_Int;
                  end if;
                  if Has_Element (Tile_Row.To_Cursor (col)) then
                     Tile_Row.Replace_Element (col, aTile);
                  else
                     Tile_Row.Append (aTile);
                  end if;
               end if;
            end loop;
            if Has_Element (Tiles.To_Cursor (row)) then
               Tiles.Replace_Element (row, Tile_Row);
            else
               Tiles.Append (Tile_Row);
            end if;
            Prev_Char := Tex_Char;
         end;  --  declare block
      end loop;

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Load_Int_Rows!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Load_Int_Rows;

   --  ----------------------------------------------------------------------------

   procedure Load_Palette_File_Names (File : File_Type) is
      --  Get_Palette_File_Name reads the file name identified by the label ID
      function  Get_Palette_File_Name (ID : String) return Unbounded_String is
         aLine : constant String := Get_Line (File);
         Label : constant String (1 .. 3) := aLine (1 .. 3);
      begin
         if Label /= ID then
            Game_Utils.Game_Log
              ("Manifold.Get_Palette_File_Name invalid format, expected "
               & "line commencing " & ID & " but obtained " & aLine);
            raise Tiles_Manager_Exception with
              "Tiles_Manager.Get_Palette_File_Name, invalid format, " & ID &
              " expected starting " & aLine;
         end if;
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

   procedure Load_Textures (Tile_Tex, Tile_Spec_Tex, Ramp_Diff_Tex,
                            Ramp_Spec_Tex : in out GL.Objects.Textures.Texture) is
      use Texture_Manager;
   begin
      Load_Image_To_Texture
        (To_String (Diff_Palette_Name), Tile_Tex, True, True);
      Load_Image_To_Texture (To_String (Spec_Palette_Name),
                             Tile_Spec_Tex, True, True);
      Load_Image_To_Texture ("src/textures/stepsTileSet1_diff.png",
                             Ramp_Diff_Tex, True, True);
      Load_Image_To_Texture ("src/textures/stepsTileSet1_spec.png",
                             Ramp_Spec_Tex, True, True);
   end Load_Textures;

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
      Game_Utils.Game_Log ("Loading tiles and generating manifold from FP...");
      Pos1 := Fixed.Index (aLine, " ") + 1;
      if Fixed.Index (aLine, "facings ") = 0 then
         raise Tiles_Manager_Exception with
           "Invalid format, ""facings"" expected: " & aLine (1 .. Pos1);
      end if;

      Pos2 := Fixed.Index (aLine (Pos1 + 1 .. aLine'Last), "x");

      Max_Cols := Int'Value (aLine (Pos1 .. Pos2 - 1));
      Max_Rows := Int'Value (aLine (Pos2 + 1 .. aLine'Last));
      Batches_Across :=
        Integer (Float'Ceiling (Float (Max_Cols) / Float (Tile_Batch_Width)));
      Batches_Down :=
        Integer (Float'Ceiling (Float (Max_Rows) / Float (Tile_Batch_Width)));

      Parse_Facings_By_Row (File, Max_Rows, Max_Cols);

      Load_Int_Rows (File, "textures");  --  textures header and rows
      Load_Char_Rows (File, "types");
      Load_Int_Rows (File, "heights");

      Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, heights loaded.");

      Load_Palette_File_Names (File);
      Load_Textures (Tile_Tex, Tile_Spec_Tex, Ramp_Diff_Tex, Ramp_Spec_Tex);

      Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, Textures loaded.");
      Add_Tiles_To_Batches;
      Game_Utils.Game_Log ("Tiles_Manager.Load_Tiles, Tiles added To_Batches.");
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
      return Integer (Tiles.Length);
   end Number_Of_Tiles;

   --  ------------------------------------------------------------------------

   procedure Parse_Facings_By_Row (File : File_Type; Max_Rows, Max_Cols : Int) is
      use Tile_Row_Package;
      use Tile_Column_Package;
      Prev_Char  : Character;
      aTile      : Tile_Data;
      Tile_Col   : Tile_Column_List;
   begin
      --  Parse_Facings_By_Row initalizes the Tiles list.
      Game_Utils.Game_Log ("Tiles_Manager.Parse_Facings_By_Row Max_Rows, Max_Cols "
                           & Int'Image (Max_Rows) & ", " & Int'Image (Max_Cols));
      for row in 1 .. Max_Rows loop
         declare
            aString     : constant String := Get_Line (File);
            Line_Length : constant Integer := aString'Length;
            Text_Char   : Character;
         begin
            if Line_Length < Integer (Max_Cols) then
               raise Tiles_Manager_Exception with
                 "Tiles_Manager.Parse_Facings_By_Row, facings line has not enough columns";
            end if;

            Prev_Char := ASCII.NUL;
            Tile_Col.Clear;
            for col in 1 .. Max_Cols loop
               Text_Char := aString (Integer (col));
               if Prev_Char = '\' and then
                 (Text_Char = 'n' or Text_Char = ASCII.NUL) then
                  Tiles.Delete_Last;
               else
                  aTile.Facing := Text_Char;
               end if;

               Tile_Col.Append (aTile);
            end loop;
            Prev_Char := Text_Char;
         end;
         Tiles.Append (Tile_Col);
      end loop;
      Game_Utils.Game_Log ("Tiles_Manager.Parse_Facings_By_Row done");

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Tiles_Manager.Parse_Facings_By_Row!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
         raise;
   end Parse_Facings_By_Row;

   --  ----------------------------------------------------------------------------

   procedure Reset_Vars is
   begin
      Diff_Palette_Name := To_Unbounded_String ("");
      Spec_Palette_Name := To_Unbounded_String ("");
   end Reset_Vars;

   --  ----------------------------------------------------------------------------

end Tiles_Manager;
