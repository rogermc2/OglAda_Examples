
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use  Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;

with GL.Attributes;
with GL.Blending;
with GL.Buffers;
with GL.Images;
with GL.Low_Level.Enums;
with GL.Objects.Buffers;
with GL.Objects.Programs;
with GL.Objects.Textures;
with GL.Objects.Textures.Targets;
with GL.Objects.Vertex_Arrays;
with GL.Pixels;
with GL.Toggles;

with Utilities;

with Game_Utils;
with GL_Utils;
with Font_Metadata_Manager;
with Shader_Attributes;
with Text_Box_Shader_Manager;
with Text_Shader_Manager;
with Texture_Manager;

package body Text is

   type Particle_Text_Data is record
      Countdown : Float := 0.0;
      Colour    : Singles.Vector4 := (0.0, 0.0, 0.0, 0.0);
      World_Pos : Singles.Vector3 := (0.0, 0.0, 0.0);
      Text_ID   : Integer := 0;
   end record;

   type Renderable_Text is record
      VAO            : GL.Objects.Vertex_Arrays.Vertex_Array_Object;
      Points_VBO     : GL.Objects.Buffers.Buffer;
      Tex_Coords_VBO : GL.Objects.Buffers.Buffer;
      Top_Left_X     : Single := 0.0;
      Top_Left_Y     : Single := 0.0;
      Bottom_Right_X : Single := 0.0;
      Bottom_Right_Y : Single := 0.0;
      Size_Px        : Single := 0.0;
      Red            : Single := 0.0;
      Green          : Single := 0.0;
      Blue           : Single := 0.0;
      A              : Single := 0.0;
      Point_Count    : Int := 0;
      Visible        : Boolean := False;
      Has_Box        : Boolean := False;
      Was_Triggered  : Boolean := False;
      Box_Colour     : Colors.Color := (0.0, 0.0, 0.0, 0.0);
   end record;

   package Renderable_Texts_Package is new Ada.Containers.Vectors
     (Positive, Renderable_Text);
   type Renderable_Text_List is new Renderable_Texts_Package.Vector with null record;

   Max_Particle_Texts : constant Integer := 8;
   Atlas_Cols         : constant Integer := 16;
   Atlas_Rows         : constant Integer := 16;
   Comic_Texts        : array (1 .. 8) of Integer;
   Particle_Texts     : array (1 .. Max_Particle_Texts) of Particle_Text_Data;

   --     Max_Strings          : constant Integer := 256;
   --      MAX_POPUP_TEXTS                 : constant Integer := 128;
   --      MAX_PARTICLE_TEXTS              : constant Integer := 8;
   --      COMIC_TEXT_FULL_COLOUR_TIME     : constant Float := 3.0;
   --      COMIC_TEXT_TIME                 : constant Float :=  6.0;
   --      PARTICLE_TEXT_FULL_COLOUR_TIME  : constant Float := 0.5;
   --      PARTICLE_TEXT_TIME              : constant Float := 0.25;
   --      PARTICLE_TEXT_SPEED             : constant Float := 5.0;

   Font_Shader          : GL.Objects.Programs.Program;
   Font_Texture         : GL.Objects.Textures.Texture;
   Text_Box_Shader      : GL.Objects.Programs.Program;
   Text_Box_VAO         : GL.Objects.Vertex_Arrays.Vertex_Array_Object;
   Text_Box_Points      : constant GL.Types.Singles.Vector2_Array (1 .. 4) :=
                            ((0.0, 0.0),
                             (0.0, -1.0),
                             (1.0,  0.0),
                             (1.0, -1.0));
   Renderable_Texts     : Renderable_Text_List;
   Font_Viewport_Width  : Int := 0;
   Font_Viewport_Height : Int := 0;
   Num_Render_Strings   : Integer := 0;

   Glyphs               : Font_Metadata_Manager.Glyph_Array;

   procedure Load_Font (Atlas_Image, Atlas_Metadata : String);
   procedure Move_Text (Text : in out Renderable_Text; X, Y : Single);
   procedure Text_To_VBO (theText        : String;
                          Glyph_Size_Px  : Single;
                          Points_VBO     : in out GL.Objects.Buffers.Buffer;
                          Tex_Coords_VBO : in out GL.Objects.Buffers.Buffer;
                          Point_Count    : in out Int;
                          Br_X, Br_Y     : in out Single);
   procedure Validate_Text_ID (Text_Index : Positive);

   --  ------------------------------------------------------------------------
   --  Add_Text adds a string of text to render on-screen
   --  returns an integer to identify it with later to change the text
   --  x,y are position of the bottom-left of the first character in clip space
   --  size_is_px is the size of maximum-sized glyph in pixels on screen
   --  r, g, b, a is the colour of the text string
   function Add_Text (theText                          : String;
                      X, Y, Size_In_Pixels, R, G, B, A : Single) return Positive is
      use GL.Objects.Buffers;
      use GL.Types;
      use Shader_Attributes;
      R_Text : Renderable_Text;
      BR_X   : Single := 0.0;
      BR_Y   : Single := 0.0;
   begin
      R_Text.VAO.Initialize_Id;
      R_Text.VAO.Bind;
      R_Text.Visible := True;
      R_Text.Top_Left_X := X;
      R_Text.Top_Left_Y := Y;
      R_Text.Size_Px := Size_In_Pixels;
      R_Text.Red := R;
      R_Text.Green := G;
      R_Text.Blue := B;
      R_Text.A := A;
      R_Text.Points_VBO.Initialize_Id;
      R_Text.Tex_Coords_VBO.Initialize_Id;
      R_Text.Point_Count := 0;

      Text_To_VBO (theText, Size_In_Pixels, R_Text.Points_VBO,
                   R_Text.Tex_Coords_VBO, R_Text.Point_Count, BR_X, BR_Y);

      Array_Buffer.Bind (R_Text.Points_VBO);
      GL.Attributes.Set_Vertex_Attrib_Pointer (Attrib_VP, 2, Single_Type,
                                               False, 0, 0);
      GL.Attributes.Enable_Vertex_Attrib_Array (Attrib_VP);

      Array_Buffer.Bind (R_Text.Tex_Coords_VBO);
      GL.Attributes.Set_Vertex_Attrib_Pointer (Attrib_VT, 2, Single_Type,
                                               False, 0, 0);
      GL.Attributes.Enable_Vertex_Attrib_Array (Attrib_VT);

      Renderable_Texts.Append (R_Text);
      Num_Render_Strings := Integer (Renderable_Texts.Last_Index);
      return Renderable_Texts.Last_Index;

   exception
      when others =>
         Put_Line ("An exception occurred in Text.Add_Text.");
         raise;
         return Renderable_Texts.Last_Index;
   end Add_Text;

   --  ------------------------------------------------------------------------

   procedure Centre_Text (ID : Positive; X, Y : Single) is
      Width   : Single;
      Length  : Single;
      theText : Renderable_Text;
   begin
      if ID <= Renderable_Texts.Last_Index then
         theText := Renderable_Texts.Element (ID);
         Width := theText.Bottom_Right_X;
         Length := X - 0.5 * Width;
         Move_Text (theText, Length, Y);
         Renderable_Texts.Replace_Element (ID, theText);
      else
         raise Text_Exception with "Text.Centre_Text encountered an invalid ID:" &
           Integer'Image (ID);
      end if;
   end Centre_Text;

   --  ------------------------------------------------------------------------

   procedure Change_Text_Colour (ID : Positive; R, G, B, A : Single) is
      use Renderable_Texts_Package;
      Curs     : Cursor := Renderable_Texts.First;
      Valid_ID : Boolean := False;
      theText  : Renderable_Text;
   begin
      while Has_Element (Curs) and not Valid_ID loop
         Valid_ID := To_Index (Curs) = ID;
         if Valid_ID then
            theText := Element (Curs);
            theText.Red := R;
            theText.Green := G;
            theText.Blue := B;
            theText.A := A;
            Renderable_Texts.Replace_Element (ID, theText);
         else
            Next (Curs);
         end if;
      end loop;

      if not Valid_ID then
         raise Text_Exception with "Text.Change_Text_Colour encountered an invalid ID:" &
           Integer'Image (ID);
      end if;

   end Change_Text_Colour;

   --  ------------------------------------------------------------------------

   procedure Create_Font_Shaders is
   begin
      Text_Shader_Manager.Init (Font_Shader);
      Text_Box_Shader_Manager.Init (Text_Box_Shader);
   end Create_Font_Shaders;

   --  ------------------------------------------------------------------------

   function Create_Text_Box (Text                    : String; Font_ID  : Integer;
                             X_Min, Y_Min, Scale     : Single;
                             Text_Colour, Box_Colour : GL.Types.Colors.Color)
                             return Positive is
      use GL.Types.Colors;
      Text_Index : constant Positive :=
                     Add_Text (Text, X_Min, Y_Min, Scale, Text_Colour (R),
                               Text_Colour (G), Text_Colour (B), Text_Colour (A));
      R_Text     : Renderable_Text := Renderable_Texts.Element (Text_Index);
   begin
      R_Text.Box_Colour := Box_Colour;
      R_Text.Has_Box := True;
      Renderable_Texts.Replace_Element (Text_Index, R_Text);
      return Text_Index;

   end Create_Text_Box;

   --  ------------------------------------------------------------------------

   procedure Draw_Text (Text_Index : Positive) is
      use GL.Blending;
      use GL.Objects.Buffers;
      use GL.Objects.Textures;
      use GL.Toggles;
      use Renderable_Texts_Package;
      use Shader_Attributes;
      theText : Renderable_Text;
      SX      : Single;
      SY      : Single;
   begin
      Validate_Text_ID (Text_Index);
      Disable (Depth_Test);
      GL.Blending.Set_Blend_Func (Src_Alpha, One_Minus_Src_Alpha);
      Enable (Blend);

      theText := Renderable_Texts.Element (Text_Index);
      theText.Visible := True;
      if not theText.Points_VBO.Initialized then
         raise Text_Exception with
         "Text.Draw_Text the Points_VBO is invalid.";
      end if;

      if theText.Has_Box then
         SX := Single (theText.Bottom_Right_X + 0.05);
         SY := Single (-theText.Bottom_Right_Y + 0.05);

         Game_Utils.Game_Log ("Text.Draw_Text Text_Box_Shader");
         GL.Objects.Programs.Use_Program (Text_Box_Shader);
         Text_Box_Shader_Manager.Set_Scale ((SX, SY));
         Text_Box_Shader_Manager.Set_Position_ID ((theText.Top_Left_X - 0.025,
                                                  theText.Top_Left_Y + 0.025));
         Text_Box_Shader_Manager.Set_Colour_ID (theText.Box_Colour);

         GL_Utils.Bind_VAO (Text_Box_VAO);
         GL.Objects.Vertex_Arrays.Draw_Arrays (Triangle_Strip_Adjacency, 0, 4);

      end if;

      if not Is_Texture (Font_Texture.Raw_Id) or else
        not Font_Texture.Initialized then
         raise Text_Exception with
           "Text.Draw_Text, invalid font texture";
      end if;

      GL.Objects.Programs.Use_Program (Font_Shader);
      Text_Shader_Manager.Set_Position_ID ((theText.Top_Left_X - 0.95,
                                           theText.Top_Left_Y));
      Text_Shader_Manager.Set_Text_Colour_ID ((theText.Red, theText.Green,
                                               theText.Blue, theText.A));

--        Texture_Manager.Bind_Texture (0, Font_Texture);
      Text_Shader_Manager.Set_Texture_Unit (0);
      Targets.Texture_2D.Bind (Font_Texture);

      GL.Objects.Buffers.Array_Buffer.Bind (theText.Points_VBO);
      GL.Attributes.Set_Vertex_Attrib_Pointer (Attrib_VP, 2, Single_Type,
                                               False, 0, 0);
      GL.Attributes.Enable_Vertex_Attrib_Array (0);

      GL.Objects.Buffers.Array_Buffer.Bind (theText.Tex_Coords_VBO);
      GL.Attributes.Set_Vertex_Attrib_Pointer (Attrib_VT, 2, Single_Type,
                                               False, 0, 0);
      GL.Attributes.Enable_Vertex_Attrib_Array (Attrib_VT);

--        Enable (GL.Toggles.Vertex_Program_Point_Size);
--        GL.Objects.Vertex_Arrays.Draw_Arrays (Points, 0, theText.Point_Count);
      GL.Objects.Vertex_Arrays.Draw_Arrays
        (Triangles, 0, Int (theText.Point_Count));

      Enable (Depth_Test);
      Disable (Blend);

   end Draw_Text;

   --  ----------------------------------------------------------------------------

   procedure Init_Comic_Texts is

      X           : Single_Array (1 .. 8) := (-0.8, -0.6, -0.2, -0.9, -0.8, -0.6, -0.4, -0.7);
      Y           : Single_Array (1 .. 8) := (-0.6, -0.4, 0.4, 0.6, 0.4, 0.6, -0.6, -0.4);
      Scale       : Single := 17.5;
      Text_Colour : Colors.Color := (0.0, 0.0, 0.0, 1.0);
      Box_Colour  : Colors.Color := (0.8, 0.8, 0.8, 1.0);
   begin
      for index in 1 .. 8 loop
         Comic_Texts (index) :=
           Create_Text_Box ("text " & Integer'Image (index), 0, X (Int (index)),
                            Y (Int (index)), Scale, Text_Colour, Box_Colour);
         Set_Text_Visible (Comic_Texts (index), False);
      end loop;
   end Init_Comic_Texts;

   --  ------------------------------------------------------------------------

   procedure Init_Particle_Texts is
   begin
      for index in 1 .. Max_Particle_Texts loop
         Particle_Texts (index).Text_ID :=
           Add_Text ("text", 0.0, 0.0, 20.0, 1.0, 1.0, 1.0, 1.0);
         Set_Text_Visible (Particle_Texts (index).Text_ID, False);
      end loop;
   end Init_Particle_Texts;

   --  ------------------------------------------------------------------------

   procedure Init_Text_Rendering
     (Font_Image_File, Font_Metadata_File : String;
      Viewport_Width, Viewport_Height     : GL.Types.Int) is
      TB_Points_VBO : GL.Objects.Buffers.Buffer;
   begin
      Game_Utils.Game_Log ("Text.Init_Text_Rendering initialising text rendering for "
                           & Font_image_File);
      Font_Viewport_Width := Viewport_Width;
      Font_Viewport_Height := Viewport_Height;
      Create_Font_Shaders;
      Load_Font (Font_Image_File, Font_Metadata_File);
      Text_Box_VAO.Initialize_Id;
      Text_Box_VAO.Bind;

      TB_Points_VBO := GL_Utils.Create_2D_VBO (Text_Box_Points);
      GL.Objects.Buffers.Array_Buffer.Bind (TB_Points_VBO);
      GL.Attributes.Enable_Vertex_Attrib_Array (Shader_Attributes.Attrib_VP);

      GL.Attributes.Set_Vertex_Attrib_Pointer
        (Shader_Attributes.Attrib_VP, 2, GL.Types.Single_Type, False, 0, 0);
      Game_Utils.Game_Log ("Text initialised for " & Font_image_File);

   exception
      when others =>
         Put_Line ("An exception occurred in Text.Init_Text_Rendering.");
         raise;
   end Init_Text_Rendering;

   --  ------------------------------------------------------------------------

   function Is_Text_ID_Valid (ID          : Positive; File_Name : String;
                              Line_Number : Integer) return Boolean is
      Result : constant Boolean := ID <= Num_Render_Strings;
   begin
      if not Result then
         Put_Line ("Text.Is_Text_ID_Valid detected in valid Text ID for " &
                     File_Name & ", line" & Integer'Image (Line_Number));
      end if;
      return Result;
   end Is_Text_ID_Valid;

   --  ------------------------------------------------------------------------

   procedure Load_Font (Atlas_Image, Atlas_Metadata : String) is
      use GL.Images;
      use GL.Pixels;
   begin
      Texture_Manager.Load_Image_To_Texture (Atlas_Image, Font_Texture, False, True);
      Font_Metadata_Manager.Load_Metadata (Atlas_Metadata, Glyphs);
      Game_Utils.Game_Log ("Text.Load_Font Font_Texture " & Atlas_Image & " loaded ");
   end Load_Font;

   --  ------------------------------------------------------------------------

   procedure Move_Text (Text : in out Renderable_Text; X, Y : Single) is
   begin
         Text.Top_Left_X := X;
         Text.Top_Left_Y := Y;
   end Move_Text;

   --  ------------------------------------------------------------------------

   procedure Move_Text (ID : Positive; X, Y : Single) is
      Text : Renderable_Text;
   begin
      if ID <= Renderable_Texts.Last_Index then
         Text := Renderable_Texts.Element (ID);
         Text.Top_Left_X := X;
         Text.Top_Left_Y := Y;
         Renderable_Texts.Replace_Element (ID, Text);
      else
         raise Text_Exception with
           "Text.Move.Text detected invalid Renderable Text ID: " &
           Positive'Image (ID);
      end if;
   end Move_Text;

   --  ------------------------------------------------------------------------

   function Number_Render_Strings return Integer is
   begin
      return Num_Render_Strings;
   end Number_Render_Strings;

   --  ------------------------------------------------------------------------

   procedure Set_Text_Visible (ID : Positive; Visible : Boolean) is
      use Renderable_Texts_Package;
      Curs     : Cursor := Renderable_Texts.First;
      Valid_ID : Boolean := False;
      theText  : Renderable_Text;
   begin
      while Has_Element (Curs) and not Valid_ID loop
         Valid_ID := To_Index (Curs) = ID;
         if Valid_ID then
            theText := Element (Curs);
            theText.Visible := Visible;
            Renderable_Texts.Replace_Element (ID, theText);
         else
            Next (Curs);
         end if;
      end loop;

      if not Valid_ID then
         raise Text_Exception with "Text.Set_Text_Visible encountered an invalid ID:" &
           Integer'Image (ID);
      end if;

   end Set_Text_Visible;

   --  ------------------------------------------------------------------------
   --  Text_To_VBO creates a VBO from a string of text using our font's
   --  glyph sizes to make a set of quads
   procedure Text_To_VBO (theText        : String;
                          Glyph_Size_Px  : Single;
                          Points_VBO     : in out GL.Objects.Buffers.Buffer;
                          Tex_Coords_VBO : in out GL.Objects.Buffers.Buffer;
                          Point_Count    : in out Int;
                          Br_X, Br_Y     : in out GL.Types.Single) is
      use GL.Objects.Buffers;
      use GL.Types;
      Glyph_Size         : constant Single := 2.0 * Single (Glyph_Size_Px);
      Text_Length        : constant Integer := theText'Length;
      Points_Tmp         : Singles.Vector2_Array (1 .. Int (6 * Text_Length));
      Tex_Coords_Tmp     : Singles.Vector2_Array (1 .. Int (6 * Text_Length));
      Atlas_Rows_S       : constant Single := Single (Atlas_Rows);
      Atlas_Cols_S       : constant Single := Single (Atlas_Cols);
      Font_Height        : constant Single := Glyph_Size / Single (Font_Viewport_Height);
      Font_Width         : constant Single := Glyph_Size / Single (Font_Viewport_Width);
      Row_Recip          : constant Single := 1.0 / Atlas_Rows_S;
      Col_Recip          : constant Single := 1.0 / Atlas_Cols_S;
      Line_Offset        : Single := 0.0;
      Current_X          : Single := 0.0;
      Current_Index_6    : Int := -5;
      Ascii_Code         : Integer;
      Atlas_Col          : Integer;
      Atlas_Row          : Integer;
      S                  : Single := 0.0;
      T                  : Single := 0.0;
      X_Pos              : Single := 0.0;
      Y_Pos              : Single := 0.0;
      Skip_Next          : Boolean := False;
   begin
--        Game_Utils.Game_Log ("Text.Text_To_VBO Text_Length, theText: " &
--                              Integer'Image (Text_Length) & ", " & theText);
      Br_X := 0.0;
      Br_Y := 0.0;
      for index in 1 .. Text_Length loop
         if Skip_Next then
            Skip_Next := False;
         else
            if index < Text_Length and then
              theText (index .. index + 1) = "\n" then
               Line_Offset := Line_Offset +  Font_Height;
               Current_X := 0.0;
               Skip_Next := True;
            else
               Current_Index_6 := Current_Index_6 + 6;
               Ascii_Code := Character'Pos (theText (index));
--                 Game_Utils.Game_Log ("Text.Text_To_VBO, Character: " &
--                                        theText (index));
               Atlas_Col := (Ascii_Code - Character'Pos (' ')) mod Atlas_Cols;
               Atlas_Row := (Ascii_Code - Character'Pos (' ')) / Atlas_Cols;
               --  work out texture coordinates in atlas
               S := Single (Atlas_Col) * Col_Recip;
               T := Single (Atlas_Row + 1) * Row_Recip;
               --  Work out position of glyphtriangle_width
               X_Pos := Current_X;
               Y_Pos := -Font_Height *
                 Font_Metadata_Manager.Y_Offset (Glyphs, Ascii_Code) - Line_Offset;
               --  Move next glyph along to the end of this one
               if index < Text_Length then
                  --  Upper-case letters move twice as far
                  Current_X := Current_X +
                    Font_Metadata_Manager.Width (Glyphs, Ascii_Code) * Font_Width;
               end if;
               -- add 6 points and texture coordinates to buffers for each glyph
               Points_Tmp (Current_Index_6) := (X_Pos, Y_Pos);
               Points_Tmp (Current_Index_6 + 1) := (X_Pos, Y_Pos - Font_Height);
               Points_Tmp (Current_Index_6 + 2) :=
                 (X_Pos + Font_Width, Y_Pos - Font_Height);

               Points_Tmp (Current_Index_6 + 3) :=
                 (X_Pos + Font_Width, Y_Pos - Font_Height);
               Points_Tmp (Current_Index_6 + 4) := (X_Pos + Font_Width, Y_Pos);
               Points_Tmp (Current_Index_6 + 5) := (X_Pos, Y_Pos);

               Tex_Coords_Tmp (Current_Index_6) := (S, 1.0 - T + Row_Recip);
               Tex_Coords_Tmp (Current_Index_6 + 1) := (S,  1.0 - T);
               Tex_Coords_Tmp (Current_Index_6 + 2) := (S + Col_Recip, 1.0 - T);
               Tex_Coords_Tmp (Current_Index_6 + 3) := (S + Col_Recip, 1.0 - T);
               Tex_Coords_Tmp (Current_Index_6 + 4) := (S + Col_Recip, 1.0 - T + Row_Recip);
               Tex_Coords_Tmp (Current_Index_6 + 5) := (S, 1.0 - T + Row_Recip);

               --  Update record of bottom-right corner of text area
               if X_Pos + Font_Width > Br_X then
                  Br_X := X_Pos + Font_Width;
               end if;
               if Y_Pos - Font_Height < Br_Y then
                  Br_Y := Y_Pos - Font_Height;
               end if;
            end if;
         end if;
      end loop;

      Array_Buffer.Bind (Points_VBO);
      Utilities.Load_Vertex_Buffer (Array_Buffer, Points_Tmp, Dynamic_Draw);

      Array_Buffer.Bind (Tex_Coords_VBO);
      Utilities.Load_Vertex_Buffer (Array_Buffer, Tex_Coords_Tmp, Dynamic_Draw);
      Point_Count := Current_Index_6 + 5;

   exception
      when others =>
         Put_Line ("An exception occurred in Text.Text_To_VBO.");
         raise;
   end Text_To_VBO;

   --  ------------------------------------------------------------------------

   procedure Update_Text (ID : Positive; aString : String) is
      Item : Renderable_Text;
      use GL.Types;
   begin
      if ID <= Positive (Renderable_Texts.Length) then
         Item := Renderable_Texts.Element (ID);
         Text_To_VBO (aString, Item.Size_Px, Item.Points_VBO, Item.Tex_Coords_VBO,
                      Item.Point_Count, Single (Item.Bottom_Right_X),
                      Single (Item.Bottom_Right_Y));
      else
         raise Text_Exception with "Text.Update_Text encountered an invalid ID:" &
           Integer'Image (ID);
      end if;

   end Update_Text;

   --  ------------------------------------------------------------------------

   procedure Validate_Text_ID (Text_Index : Positive) is
   begin
      if Text_Index > Num_Render_Strings then
         raise Text_Exception with ("Text.Is_Text_Boolean Text_Index " &
                                      Integer'Image (Text_Index) & " is invalid.");
      end if;
   end Validate_Text_ID;

   --  ----------------------------------------------------------------------------

end Text;
