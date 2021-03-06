
with Interfaces.C;
with Interfaces.C.Strings;

with Ada.Text_IO; use Ada.Text_IO;

package body Assimp_Util is

    procedure Print_AI_Property_Data (Title     : String;
                                      aProperty : Material.AI_Material_Property) is
    begin
        New_Line;
        Put_Line (Title & " Property_Data:");
        Put_Line (" Key: " & Ada.Strings.Unbounded.To_String (aProperty.Key));
        Put_Line (" Semantic, Texture_Index: " &
                    Material.AI_Texture_Type'Image (aProperty.Semantic) &
                    UInt'Image (aProperty.Texture_Index));
        Put_Line (" Data_Type: " &
                    Material.AI_Property_Type_Info'Image (aProperty.Data_Buffer.Data_Type));
        case aProperty.Data_Type is
            when Material.PTI_Float =>
                Put_Line ("Value: " & Single'Image (aProperty.Data_Buffer.Float_Data));
            when Material.PTI_Double =>
                Put_Line ("Value: " & Double'Image (aProperty.Data_Buffer.Double_Data));
            when Material.PTI_String =>
                Put_Line ("Value: " &
                            Ada.Strings.Unbounded.To_String (aProperty.Data_Buffer.String_Data));
            when Material.PTI_Integer =>
                Put_Line ("Value: " & Int'Image (aProperty.Data_Buffer.Integer_Data));
            when Material.PTI_Buffer =>
                Put_Line ("Value: :" & Int'Image (aProperty.Data_Buffer.Buffer_Data));
            when others => null;
        end case;
        New_Line;
    end Print_AI_Property_Data;

    --  -------------------------------------------------------------------------

    procedure Print_API_Property_Data (Title     : String;
                                       aProperty : Material.API_Material_Property) is
        use Interfaces.C;
    begin
        New_Line;
        Put_Line (Title & " Property_Data:");
        Put_Line (" Key length, Key: " & size_t'Image (aProperty.Key.Length) &
                    ", " & To_String (aProperty.Key));
        if aProperty.Key.Length = 0 then
            Put_Line ("Invalid key!");
        else
            Put_Line (" Semantic, Texture_Index: " & unsigned'Image (aProperty.Semantic)
                      & unsigned'Image (aProperty.Texture_Index));
            Put_Line (" Data_Type, Buffer size (bytes): " &
                        Material.AI_Property_Type_Info'Image (aProperty.Data_Type) &
                        unsigned'Image (aProperty.Data_Length));
        end if;
    end Print_API_Property_Data;

    --  -------------------------------------------------------------------------

   procedure Print_API_Sring (Title : String; theAPI_String : Assimp_Types.API_String) is
   begin
      Put_Line (Title & ": " & To_String (theAPI_String));
   end Print_API_Sring;

   --  -------------------------------------------------------------------------

   procedure Print_Unsigned_Array (Name    : String;
                                   anArray : API_Vectors_Matrices.API_Unsigned_Array) is
      use Interfaces.C;
   begin
      Put_Line (Name & ": ");
      for Index in anArray'First .. anArray'Last loop
         Put_Line (unsigned'Image (Index) & ":  " & unsigned'Image (anArray (Index)));
      end loop;
      New_Line;
   end Print_Unsigned_Array;

   --  -------------------------------------------------------------------------

    function To_Assimp_API_String
      (UB_String :  Ada.Strings.Unbounded.Unbounded_String)
      return Assimp_Types.API_String is
        use Interfaces.C;
        theString     : constant String := Ada.Strings.Unbounded.To_String (UB_String);
        Assimp_String : Assimp_Types.API_String;
    begin
        Assimp_String.Length := theString'Length;
        for index in 1 ..  Assimp_String.Length loop
            Assimp_String.Data (index - 1) := To_C (theString (Integer (index)));
        end loop;
        Assimp_String.Data (Assimp_String.Length) := nul;
        return Assimp_String;
    end To_Assimp_API_String;

    --  ------------------------------------------------------------------------

    function To_OGL_Vector2 (C_Vec : API_Vectors_Matrices.API_Vector_2D)
                            return Singles.Vector2 is
        Vec : Singles.Vector2;
    begin
        Vec (GL.X) := Single (C_Vec.X);
        Vec (GL.Y) := Single (C_Vec.Y);
        return Vec;
    end To_OGL_Vector2;

    --  ------------------------------------------------------------------------

    function To_OGL_Vector3 (C_Vec : API_Vectors_Matrices.API_Vector_3D)
                            return Singles.Vector3 is
        Vec : Singles.Vector3;
    begin
        Vec (GL.X) := Single (C_Vec.X);
        Vec (GL.Y) := Single (C_Vec.Y);
        Vec (GL.Z) := Single (C_Vec.Z);
        return Vec;
    end To_OGL_Vector3;

    --  ------------------------------------------------------------------------

    function To_Colour3D (C_Colours : API_Vectors_Matrices.API_Colour_3D)
                         return Singles.Vector3 is
        theColours : Singles.Vector3;
    begin
        theColours :=
          (Single (C_Colours.R), Single (C_Colours.G), Single (C_Colours.B));
        return theColours;
    end To_Colour3D;

    --  ------------------------------------------------------------------------

    function To_Colour4D (C_Colours : API_Vectors_Matrices.API_Colour_4D)
                         return Singles.Vector4 is
        theColours : Singles.Vector4;
    begin
        theColours :=
          (Single (C_Colours.R), Single (C_Colours.G),
           Single (C_Colours.B), Single (C_Colours.A));
        return theColours;
    end To_Colour4D;

    --  ------------------------------------------------------------------------

    function To_Unbounded_String (API_String : Assimp_Types.API_String)
                                 return Ada.Strings.Unbounded.Unbounded_String is
        use Interfaces.C.Strings;
        use Ada.Strings.Unbounded;
        API_String_Ptr : constant chars_ptr := New_Char_Array (API_String.Data);
        UB_String      :  Ada.Strings.Unbounded.Unbounded_String;
    begin
        UB_String :=
          To_Unbounded_String (Value (API_String_Ptr, API_String.Length));
        return UB_String;
    end To_Unbounded_String;

    --  ------------------------------------------------------------------------

    function To_String (API_String : Assimp_Types.API_String) return String is
        use Interfaces.C;
        String_Length : constant Integer := Integer (API_String.Length);
    begin
        if String_Length > 0 then
            declare
                theString : String (1 .. String_Length);
            begin
                for index in 1 .. String_Length loop
                    theString (index) := To_Ada (API_String.Data (size_t (index - 1)));
                end loop;
                return theString;
            end;
        else
            return "Empty String";
        end if;
    end To_String;

    --  ------------------------------------------------------------------------

end Assimp_Util;
