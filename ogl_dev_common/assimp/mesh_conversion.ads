
with Interfaces.C;
with Interfaces.C.Pointers;

with Ada.Strings.Unbounded;
with Ada.Containers.Indefinite_Ordered_Maps;

with GL.Objects.Buffers;
with GL.Types; use GL.Types;

with Assimp_Mesh;
with Assimp_Types;
with API_Vectors_Matrices; use API_Vectors_Matrices;

package Mesh_Conversion is

    AI_Max_Face_Indices   : constant Int := 16#7FFF#;
    AI_Max_Bone_Weights   : constant Int := 16#7FFFFFFF#;
    AI_Max_Vertices       : constant Int := 16#7FFFFFFF#;
    AI_Max_Faces          : constant Int := 16#7FFFFFFF#;
    AI_Max_Texture_Coords : constant Int := 8;
    AI_Max_Colour_Sets    : constant Int := 8;

    type AI_Primitive_Type is
        (AI_Primitive_Type_Point, AI_Primitive_Type_Line, AI_Primitive_Type_Triangle,
        AI_Primitive_Type_Polygon, AI_Primitive_Type_Force32Bit);
   pragma Convention (C, AI_Primitive_Type);

    type AI_Vertex_Weight is record
        Vertex_ID  : UInt;
        Weight     : Single;
    end record;

    type AI_Colour_4D is record
            R, G, B, A : GL.Types.Single;
   end record;

   package Vertex_Weight_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, AI_Vertex_Weight);
   type Vertex_Weight_Map is new Vertex_Weight_Package.Map with
     null Record;

    type API_Vertex_Weight is record
        Vertex_ID  : Interfaces.C.unsigned;
        Weight     : Interfaces.C.C_float;
    end record;
    pragma Convention (C_Pass_By_Copy, API_Vertex_Weight);

   type API_Vertex_Weight_Array is array
     (Interfaces.C.unsigned range <>) of aliased API_Vertex_Weight;
   pragma Convention (C, API_Vertex_Weight_Array);

   package Vertex_Weight_Array_Pointers is new Interfaces.C.Pointers
     (Interfaces.C.unsigned, API_Vertex_Weight, API_Vertex_Weight_Array,
      API_Vertex_Weight'(others => <>));
   subtype Vertex_Weight_Array_Pointer is Vertex_Weight_Array_Pointers.Pointer;

    type API_Bone is record
        Name          : Assimp_Types.API_String;
        Num_Weights   : Interfaces.C.unsigned;
        Weights       : Vertex_Weight_Array_Pointer;
        Offset_Matrix : API_Vectors_Matrices.API_Matrix_4D;
    end record;
   pragma Convention (C_Pass_By_Copy, API_Bone);

   type API_Bones_Array is array
     (Interfaces.C.unsigned range <>) of aliased API_Bone;
   pragma Convention (C, API_Bones_Array);

   package Bones_Array_Pointers is new Interfaces.C.Pointers
     (Interfaces.C.unsigned, API_Bone, API_Bones_Array,
      API_Bone'(others => <>));
   subtype Bones_Array_Pointer is Bones_Array_Pointers.Pointer;

    type AI_Bone is record
        Name          : Ada.Strings.Unbounded.Unbounded_String :=
                         Ada.Strings.Unbounded.To_Unbounded_String ("");
        Weights       : Vertex_Weight_Map;
        Offset_Matrix : GL.Types.Singles.Matrix4;
    end record;

   package Bones_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, AI_Bone);
   type Bones_Map is new  Bones_Package.Map with
     null Record;

   package Indices_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, UInt);
   type Indices_Map is new Indices_Package.Map with
     null Record;

    type AI_Face is record
        Indices : Indices_Map;
    end record;

    type API_Face is record
        Num_Indices : Interfaces.C.unsigned;
        Indices     : Unsigned_Array_Pointer;
    end record;

   type API_Faces_Array is array
     (Interfaces.C.unsigned range <>) of aliased API_Face;
   pragma Convention (C, API_Faces_Array);

   package API_Faces_Array_Pointers is new Interfaces.C.Pointers
     (Interfaces.C.unsigned, API_Face, API_Faces_Array,
      API_Face'(others => <>));
   subtype Faces_Array_Pointer is API_Faces_Array_Pointers.Pointer;

   package Faces_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, AI_Face);
   type Faces_Map is new Faces_Package.Map with null Record;

   use Singles;
   package Vertices_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, Singles.Vector3);
   type Vertices_Map is new  Vertices_Package.Map with null Record;

   package Colours_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, Singles.Vector4);
   type Colours_Map is new  Colours_Package.Map with null Record;

   package Colour_Coords_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, Colours_Map);
   type Colour_Coords_Map is new  Colour_Coords_Package.Map with null Record;

   package Texture_Coords_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, Vertices_Map);
   type Texture_Coords_Map is new  Texture_Coords_Package.Map with null Record;

    type AI_Mesh is record
        Name              : Ada.Strings.Unbounded.Unbounded_String :=
                              Ada.Strings.Unbounded.To_Unbounded_String ("");
        Vertices          : Vertices_Map;
        Normals           : Vertices_Map;
        Tangents          : Vertices_Map;
        Bit_Tangents      : Vertices_Map;
        Colours           : Colour_Coords_Map;
        Texture_Coords    : Texture_Coords_Map;
        Num_UV_Components : UInt_Array (1 .. API_Max_Texture_Coords);
        Faces             : Faces_Map;
        Bones             : Bones_Map;
        Material_Index    : UInt := 0;
    end record;

   package AI_Mesh_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, AI_Mesh);
   subtype  AI_Mesh_Map is AI_Mesh_Package.Map;
    --  C arrays are constrained. To pass C arrays around function calls,
    --  either terminate them with a zero element or with a separate length parameter.

    type API_Mesh is record
        Primitive_Types   : Interfaces.C.unsigned := 0;
        Num_Vertices      : Interfaces.C.unsigned := 0;
        Num_Faces         : Interfaces.C.unsigned := 0;
        Vertices          : Vector_3D_Array_Pointers.Pointer := null;
        Normals           : Vector_3D_Array_Pointers.Pointer := null;
        Tangents          : Vector_3D_Array_Pointers.Pointer := null;
        Bit_Tangents      : Vector_3D_Array_Pointers.Pointer := null;
        Colours           : API_Colour_4D_Ptr_Array;
        Texture_Coords    : API_Texture_Coords_3D_Ptr_Array;
        Num_UV_Components : API_Unsigned_Array (1 .. API_Max_Texture_Coords);
        Faces             : Faces_Array_Pointer := null;
        Num_Bones         : Interfaces.C.unsigned := 0;
        Bones             : access Bones_Array_Pointer := null;
        Material_Index    : Interfaces.C.unsigned := 0;
        Name              : Assimp_Types.API_String;
        Num_Anim_Meshes   : Interfaces.C.unsigned := 0;
        Anim_Meshes       : access Vector_3D_Array_Pointers.Pointer := null;
    end record;
   pragma Convention (C_Pass_By_Copy, API_Mesh);

   type API_Mesh_Ptr is access API_Mesh;
   pragma Convention (C, API_Mesh_Ptr);

   type API_Mesh_Ptr_Array is array
     (Interfaces.C.unsigned range <>) of aliased API_Mesh_Ptr;
   pragma Convention (C, API_Mesh_Ptr_Array);

   package Mesh_Array_Pointers is new Interfaces.C.Pointers
     (Interfaces.C.unsigned, API_Mesh_Ptr, API_Mesh_Ptr_Array, null);
   subtype Mesh_Ptr_Array_Pointer is Mesh_Array_Pointers.Pointer;

   function To_AI_Mesh_Map (Num_Meshes : Interfaces.C.unsigned := 0;
                            C_Mesh_Ptr_Array : Mesh_Ptr_Array_Pointer)
                            return Assimp_Mesh.AI_Mesh_Map;

    private
         for AI_Primitive_Type use
        (AI_Primitive_Type_Point       => 1,
         AI_Primitive_Type_Line        => 2,
         AI_Primitive_Type_Triangle    => 4,
         AI_Primitive_Type_Polygon     => 8,
         AI_Primitive_Type_Force32Bit  => Integer'Last);

    type API_Mesh_Entry is record
        Vertex_Buffer  : GL.Objects.Buffers.Buffer;
        Index_Buffer   : GL.Objects.Buffers.Buffer;
        Num_Indices    : UInt;
        Material_Index : UInt;
    end record;
    pragma Convention (C_Pass_By_Copy, API_Mesh_Entry);

    type API_Entries_Array is array (Interfaces.C.unsigned range <>) of aliased API_Mesh_Entry;
    pragma Convention (C, API_Entries_Array);

   type Entry_Ptr is access API_Entries_Array;

end Mesh_Conversion;
