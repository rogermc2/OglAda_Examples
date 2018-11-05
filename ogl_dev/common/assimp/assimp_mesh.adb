
with System;

with Interfaces.C.Strings;

with Ada.Text_IO; use Ada.Text_IO;

with Utilities;

with Ogldev_Math;
with Ogldev_Util;

with Assimp_Util;
with Importer;
with Scene;

package body Assimp_Mesh is

   procedure Init_From_Scene (theMesh   : in out Mesh; theScene : Scene.AI_Scene;
                              File_Name : String);
   procedure Init_Materials (theMesh   : in out Mesh; theScene : Scene.AI_Scene;
                             File_Name : String);
   procedure Init_Mesh (theMesh : in out Mesh; Mesh_Index : UInt; anAI_Mesh : AI_Mesh);
   function To_AI_Colours_Map (C_Array      : API_Colour_4D_Ptr_Array;
                               Num_Vertices : Interfaces.C.unsigned) return Colour_Coords_Map;
   function To_AI_Texture_Coords_Map (C_Array      : API_Texture_Coords_3D_Ptr_Array;
                                      Num_Vertices : Interfaces.C.unsigned) return Texture_Coords_Map;
   function To_AI_Vertices_Map (C_Array_Ptr  : Vector_3D_Array_Pointers.Pointer;
                                Num_Vertices : Interfaces.C.unsigned) return Vertices_Map;
   function To_AI_Vertex_Weight_Map (Weights_Ptr : Vertex_Weight_Array_Pointer;
                                     Num_Weights : Interfaces.C.unsigned) return Vertex_Weight_Map;

   ------------------------------------------------------------------------

   function Has_Texture_Coords (aMesh : Mesh; Index : UInt) return Boolean is
   begin
      return Assimp_Texture.Texture_Map_Size (aMesh.Textures) > 0;
   end Has_Texture_Coords;

   ------------------------------------------------------------------------

   procedure Init_From_Scene (theMesh   : in out Mesh; theScene  : Scene.AI_Scene;
                              File_Name : String) is
      use AI_Mesh_Package;
      anAI_Mesh : AI_Mesh;
      Index     : UInt := 0;
   begin
      for iterator  in theScene.Meshes.Iterate loop
         anAI_Mesh := Element (iterator);
         Index := Index + 1;
         Init_Mesh (theMesh, Index, anAI_Mesh);
      end loop;

      Init_Materials (theMesh, theScene, File_Name);
   end Init_From_Scene;

   ------------------------------------------------------------------------

   procedure Init_Materials (theMesh   : in out Mesh; theScene : Scene.AI_Scene;
                             File_Name : String) is
   begin
      null;
   end Init_Materials;

   ------------------------------------------------------------------------

   procedure Init_Mesh (theMesh   : in out Mesh; Mesh_Index : UInt;
                        anAI_Mesh : AI_Mesh) is
      --          Num_Vertices : constant Int := Int (theMesh.Vertices.Length);
      --          Vertices     : Vertex_Array (1 .. Num_Vertices);
      --          Indices      : GL.Types.UInt_Array (1 .. 3 * Num_Vertices);
      --          Position     : GL.Types.Singles.Vector3;
      --          Normal       : GL.Types.Singles.Vector3;
      --          Tex_Coord    : GL.Types.Singles.Vector3;
      --          Face         : Assimp_Mesh.AI_Face;
      --          Index_Index  : Int := 0;
   begin
      null;
      --          for Index in 1 .. Num_Vertices loop
      --              Position := theMesh.Vertices.Element (UInt (Index));
      --              Normal := theMesh.Normals.Element (UInt (Index));
      --              Tex_Coord := theMesh.Texture_Coords (Index);
      --              Vertices (Index) := (Position, (Tex_Coord (GL.X), Tex_Coord (GL.Y)), Normal);
      --          end loop;

      --          for Index in 1 .. theMesh.Faces.Length loop
      --              Face := theMesh.Faces.Element (UInt (Index));
      --              Index_Index := Index_Index + 1;
      --              Indices (Int (Index)) := Face.Indices (1);
      --              Index_Index := Index_Index + 1;
      --              Indices (Int (Index)) := Face.Indices (2);
      --              Index_Index := Index_Index + 1;
      --              Indices (Int (Index)) := Face.Indices (3);
      --          end loop;
      --        Init_Buffers (anEntry, Vertices, Indices);

   exception
      when others =>
         Put_Line ("An exception occurred in Assimp_Mesh.Init_Mesh.");
         raise;
   end Init_Mesh;

   --  ------------------------------------------------------------------------

   procedure Load_Mesh (File_Name : String; theMesh : in out Mesh) is
      theScene : Scene.AI_Scene;
   begin
      theScene := Importer.Read_File (File_Name, UInt (Ogldev_Util.Assimp_Load_Flags));
      Init_From_Scene (theMesh, theScene, File_Name);

   exception
      when others =>
         Put_Line ("An exception occurred in Assimp_Mesh.Load_Mesh.");
         raise;
   end Load_Mesh;

   --  ------------------------------------------------------------------------

   procedure Render_Mesh (theMesh : Mesh) is
   begin
      null;

   exception
      when others =>
         Put_Line ("An exception occurred in Assimp_Mesh.Render_Mesh.");
         raise;
   end Render_Mesh;

   --  ------------------------------------------------------------------------

   function To_AI_Bones_Map (B_Array_Access : access Bones_Array_Pointer;
                             Num_Bones      : Interfaces.C.unsigned) return Bones_Map is

      Bones_Array_Ptr : constant Bones_Array_Pointer := B_Array_Access.all;
      B_Array         : constant API_Bones_Array := Bones_Array_Pointers.Value
        (Bones_Array_Ptr, Interfaces.C.ptrdiff_t (Num_Bones));
      anAPI_Bone      : API_Bone;
      anAI_Bone       : AI_Bone;
      theMap          : Bones_Map;
   begin
      for index in 1 .. Num_Bones loop
         anAPI_Bone := B_Array (index);
         anAI_Bone.Name := Assimp_Util.To_Unbounded_String (anAPI_Bone.Name);
         anAI_Bone.Weights := To_AI_Vertex_Weight_Map (anAPI_Bone.Weights, anAPI_Bone.Num_Weights);
         anAI_Bone.Offset_Matrix := Ogldev_Math.To_GL_Matrix4 (anAPI_Bone.Offset_Matrix);
         theMap.Insert (UInt (index), anAI_Bone);
      end loop;
      return theMap;
   end To_AI_Bones_Map;

   --  ------------------------------------------------------------------------

   function To_AI_Colours_Map (C_Array      : API_Colour_4D_Ptr_Array;
                               Num_Vertices : Interfaces.C.unsigned)
                               return Colour_Coords_Map is
      use Vector_3D_Array_Pointers;
      use Colours_4D_Array_Pointers;
      API_Colours_Ptr   : Colours_4D_Array_Pointer;
      API_Colours_Array : API_Colours_4D_Array (1 .. Num_Vertices);
      API_Colours       : API_Vectors_Matrices.API_Colour_4D;
      Colours           : Singles.Vector4;
      aColours_Map      : Colours_Map;
      TheMap            : Colour_Coords_Map;
   begin
      for index in C_Array'First .. C_Array'Last loop
         if C_Array (index) /= null then
            API_Colours_Ptr := C_Array (index);
            API_Colours_Array :=
              Colours_4D_Array_Pointers.Value
                (API_Colours_Ptr, Interfaces.C.ptrdiff_t (Num_Vertices));
            for T_index in API_Colours_Array'First .. API_Colours_Array'Last loop
               API_Colours := API_Colours_Array (T_index);
               Colours (GL.X) := Single (API_Colours.R);
               Colours (GL.Y) := Single (API_Colours.G);
               Colours (GL.Z) := Single (API_Colours.B);
               Colours (GL.Z) := Single (API_Colours.A);
               aColours_Map.Insert (UInt (T_index), Colours);
            end loop;
            theMap.Insert (UInt (index), aColours_Map);
         end if;
      end loop;
      return TheMap;
   end To_AI_Colours_Map;

   --  ------------------------------------------------------------------------

   function To_AI_Face_Indices_Map (Indices_Ptr : Unsigned_Array_Pointer;
                                    Num_Indices : Interfaces.C.unsigned) return Indices_Map is
      Index_Array  : API_Unsigned_Array (1 .. Num_Indices);
      theMap       : Indices_Map;
   begin
      Index_Array := Unsigned_Array_Pointers.Value
        (Indices_Ptr, Interfaces.C.ptrdiff_t (Num_Indices));

      for index in 1 .. Num_Indices loop
         theMap.Insert (UInt (index), UInt (Index_Array (index)));
      end loop;
      return theMap;
   end To_AI_Face_Indices_Map;

   --  ------------------------------------------------------------------------

   function To_AI_Faces_Map (F_Array_Ptr : Faces_Array_Pointer;
                             Num_Faces   : Interfaces.C.unsigned) return Faces_Map is
      use API_Faces_Array_Pointers;
      Face_Array   : API_Faces_Array (1 .. Num_Faces);
      anAPI_Face   : API_Face;
      anAI_Face    : AI_Face;
      theMap       : Faces_Map;
   begin
      if F_Array_Ptr = null then
         Put_Line ("Assimp_Mesh.To_AI_Faces_Map F_Array_Ptr is null.");
      else
         Face_Array := API_Faces_Array_Pointers.Value
           (F_Array_Ptr, Interfaces.C.ptrdiff_t (Num_Faces));

         for index in 1 .. Num_Faces loop
            anAPI_Face := Face_Array (index);
            anAI_Face.Indices := To_AI_Face_Indices_Map (anAPI_Face.Indices, anAPI_Face.Num_Indices);
            theMap.Insert (UInt (index), anAI_Face);
         end loop;
      end if;
      return theMap;

   exception
      when others =>
         Put_Line ("An exception occurred in Assimp_Mesh.To_AI_Faces_Map.");
         raise;
   end To_AI_Faces_Map;

   --  ------------------------------------------------------------------------

   function To_AI_Mesh (C_Mesh : API_Mesh) return AI_Mesh is
      use Interfaces.C;
      use Vector_3D_Array_Pointers;
      use API_Vectors_Matrices;
      use Unsigned_Array_Pointers;
      theAI_Mesh   : AI_Mesh;
      Num_Vertices : constant unsigned := C_Mesh.Num_Vertices;
      Num_Faces    : constant unsigned :=C_Mesh.Num_Faces;
      Num_Bones    : constant unsigned := C_Mesh.Num_Bones;
   begin
      theAI_Mesh.Name :=  Assimp_Util.To_Unbounded_String (C_Mesh.Name);

      if C_Mesh.Vertices = null then
         raise Strings.Dereference_Error with
           "To_AI_Mesh exception: C_Mesh.Vertices is null.";
      end if;
      theAI_Mesh.Vertices := To_AI_Vertices_Map (C_Mesh.Vertices, C_Mesh.Num_Vertices);

      if C_Mesh.Normals /= null then
         theAI_Mesh.Normals := To_AI_Vertices_Map (C_Mesh.Normals, C_Mesh.Num_Vertices);
      end if;

      if C_Mesh.Tangents /= null then
         theAI_Mesh.Tangents := To_AI_Vertices_Map (C_Mesh.Tangents, C_Mesh.Num_Vertices);
      end if;

      if C_Mesh.Bit_Tangents /= null then
         theAI_Mesh.Bit_Tangents := To_AI_Vertices_Map (C_Mesh.Bit_Tangents, C_Mesh.Num_Vertices);
      end if;

      theAI_Mesh.Colours := To_AI_Colours_Map (C_Mesh.Colours, C_Mesh.Num_Vertices);

      theAI_Mesh.Texture_Coords :=
        To_AI_Texture_Coords_Map (C_Mesh.Texture_Coords, C_Mesh.Num_Vertices);

      theAI_Mesh.Material_Index := UInt (C_Mesh.Material_Index);
      if Num_Faces > 0 then
         theAI_Mesh.Faces := To_AI_Faces_Map (C_Mesh.Faces, C_Mesh.Num_Faces);
      end if;

      if Num_Bones > 0 then
         theAI_Mesh.Bones := To_AI_Bones_Map (C_Mesh.Bones, C_Mesh.Num_Bones);
      end if;
      return theAI_Mesh;

   exception
      when others =>
         Put_Line ("An exception occurred in Assimp_Mesh.To_AI_Mesh.");
         raise;
   end To_AI_Mesh;

   --  ------------------------------------------------------------------------

   function To_AI_Mesh_Map (Num_Meshes   : Interfaces.C.unsigned := 0;
                            C_Mesh_Ptr_Array : Mesh_Ptr_Array_Pointer)
                            return AI_Mesh_Map is
      use Interfaces.C;
      Meshes   : AI_Mesh_Map;
      C_Meshes : API_Mesh_Ptr_Array := Mesh_Array_Pointers.Value
        (C_Mesh_Ptr_Array, ptrdiff_t (Num_Meshes));
      C_Mesh   : API_Mesh;
      aMesh    : AI_Mesh;
   begin
      Put_Line ("Assimp_Mesh.To_AI_Mesh_Map Num_Meshes: " & Interfaces.C.unsigned'image (Num_Meshes));
      Put_Line ("Assimp_Mesh.To_AI_Mesh_Map C_Meshes length: " & Count'image (C_Meshes'Length));
      for index in 1 .. Num_Meshes loop
--           Put_Line ("Assimp_Mesh.To_AI_Mesh_Map, index: " &  unsigned'Image (index));
--           Put_Line ("Assimp_Mesh.To_AI_Mesh_Map, Primitive_Types, Num Vertices, Faces, Bones, Anim_Meshes, Material_Index");
--           Put_Line (unsigned'Image (C_Mesh_Array (index).Primitive_Types) &
--                       unsigned'Image (C_Mesh_Array (index).Num_Vertices) &
--                       unsigned'Image (C_Mesh_Array (index).Num_Faces) &
--                       unsigned'Image (C_Mesh_Array (index).Num_Bones) &
--                       unsigned'Image (C_Mesh_Array (index).Num_Anim_Meshes) &
--                       unsigned'Image (C_Mesh_Array (index).Material_Index));
--           New_Line;
         C_Mesh := C_Meshes (index - 1).all;
         aMesh := To_AI_Mesh (C_Mesh);
         Meshes.Insert (UInt (index), aMesh);
      end loop;
      return Meshes;

   exception
      when others =>
         Put_Line ("An exception occurred in Assimp_Mesh.To_AI_Mesh_Map.");
         raise;

   end To_AI_Mesh_Map;

   --  ------------------------------------------------------------------------

   function To_AI_Texture_Coords_Map (C_Array      : API_Texture_Coords_3D_Ptr_Array;
                                      Num_Vertices : Interfaces.C.unsigned)
                                      return Texture_Coords_Map is
      use Vector_3D_Array_Pointers;
      use Texture_Coords_Array_Pointers;
      API_Coords_Ptr   : Texture_Coords_Array_Pointer;
      API_Coords_Array : API_Texture_Coords_Array (1 .. Num_Vertices);
      API_Coords       : API_Vectors_Matrices.API_Texture_Coords_3D;
      Texture_Coords   : Singles.Vector3;
      Coords_Map       : Vertices_Map;
      theMap           : Texture_Coords_Map;
   begin
      for index in C_Array'First .. C_Array'Last loop
         if C_Array (index) /= null then
            API_Coords_Ptr := C_Array (index);
            API_Coords_Array :=
              Texture_Coords_Array_Pointers.Value
                (API_Coords_Ptr, Interfaces.C.ptrdiff_t (Num_Vertices));
            for T_index in API_Coords_Array'First .. API_Coords_Array'Last loop
               API_Coords := API_Coords_Array (T_index);
               Texture_Coords (GL.X) := Single (API_Coords.U);
               Texture_Coords (GL.Y) := Single (API_Coords.V);
               Texture_Coords (GL.Z) := Single (API_Coords.W);
               Coords_Map.Insert (UInt (T_index), Texture_Coords);
            end loop;
            theMap.Insert (UInt (index), Coords_Map);
         end if;
      end loop;
      return theMap;
   end To_AI_Texture_Coords_Map;

   --  ------------------------------------------------------------------------

   function To_AI_Vertices_Map (C_Array_Ptr  : Vector_3D_Array_Pointers.Pointer;
                                Num_Vertices : Interfaces.C.unsigned) return Vertices_Map is
      V_Array      : API_Vectors_Matrices.API_Vector_3D_Array (1 .. Num_Vertices);
      anAPI_Vector : API_Vector_3D;
      anAI_Vector  : Singles.Vector3;
      theMap       : Vertices_Map;
   begin
      V_Array := API_Vectors_Matrices.Vector_3D_Array_Pointers.Value
        (C_Array_Ptr, Interfaces.C.ptrdiff_t (Num_Vertices));

      for index in 1 .. Num_Vertices loop
         anAPI_Vector := V_Array (index);
         anAI_Vector (GL.X) := Single (anAPI_Vector.X);
         anAI_Vector (GL.Y) := Single (anAPI_Vector.Y);
         anAI_Vector (GL.Z) := Single (anAPI_Vector.Z);
         theMap.Insert (UInt (index), anAI_Vector);
      end loop;
      return theMap;
   end To_AI_Vertices_Map;

   --  ------------------------------------------------------------------------

   function To_AI_Vertex_Weight_Map (Weights_Ptr : Vertex_Weight_Array_Pointer;
                                     Num_Weights : Interfaces.C.unsigned) return Vertex_Weight_Map is
      Weight_Array : API_Vertex_Weight_Array (1 .. Num_Weights);
      anAI_Weight  : AI_Vertex_Weight;
      theMap       : Vertex_Weight_Map;
   begin
      Weight_Array := Vertex_Weight_Array_Pointers.Value
        (Weights_Ptr, Interfaces.C.ptrdiff_t (Num_Weights));

      for index in 1 .. Num_Weights loop
         anAI_Weight.Vertex_ID := UInt (Weight_Array (index).Vertex_ID);
         anAI_Weight.Weight := Single (Weight_Array (index).Weight);
         theMap.Insert (UInt (index), anAI_Weight);
      end loop;
      return theMap;
   end To_AI_Vertex_Weight_Map;

   --  ------------------------------------------------------------------------

end Assimp_Mesh;
