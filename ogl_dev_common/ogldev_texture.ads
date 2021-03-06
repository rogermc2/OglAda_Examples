
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Strings.Unbounded;

with Core_Image;

with GL.Types; use GL.Types;
with GL.Low_Level.Enums;
with GL.Objects.Textures;

with Magick_Blob;

Package Ogldev_Texture is

   type Ogl_Texture is record
      File_Name      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String ("");
      Texture_Target : GL.Low_Level.Enums.Texture_Kind;
      Texture_Object : GL.Objects.Textures.Texture;
      --  DON't Change Image or Blob_Data
      Image          : Core_Image.Image;
      Blob_Data      : Magick_Blob.Blob_Data;  --  Blob_Package.List
   end record;

   package Mesh_Texture_Package is new
     Ada.Containers.Indefinite_Ordered_Maps (UInt, Ogl_Texture);
   subtype Mesh_Texture_Map is Mesh_Texture_Package.Map;

   Texture_Exception : Exception;

   procedure Bind (theTexture : Ogl_Texture;
                   theTexture_Unit : GL.Objects.Textures.Texture_Unit);
   function Init_Texture (theTexture : in out Ogl_Texture;
                          Target_Type : GL.Low_Level.Enums.Texture_Kind;
                          Texture_File  :  String) return Boolean;
   procedure Load (theTexture : in out Ogl_Texture; Data_Type : String := "RGBA");
   function Texture_Map_Size (theMap : Ogldev_Texture.Mesh_Texture_Map)
                              return GL.Types.UInt;

end Ogldev_Texture;
