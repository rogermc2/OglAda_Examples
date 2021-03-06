
with Ada.Directories;
with Ada.Text_IO; use Ada.Text_IO;

with Assimp.API;

package body Importer is

   -------------------------------------------------------------------------

   --  Read a file  into a scene with the Assimp aiImportFile function
   function Import_File (File_Name : String; Flags : GL.Types.UInt)
                         return Scene.AI_Scene is
      use Scene;
      C_Scene  : API_Scene;
      theScene : AI_Scene;
   begin
      if Ada.Directories.Exists (File_Name) then
         Put_Line ("Importer.Import_File, File_Name: " & File_Name);
         C_Scene := Assimp.API.Import_File
           (Interfaces.C.To_C (File_Name), unsigned (Flags)).all;
         To_AI_Scene (C_Scene, theScene);
      else
         raise Import_Exception with "Importer.Import_File can't find " & File_Name;
      end if;
      return theScene;

   exception
      when  others =>
         Put_Line ("An exception occurred in Importer.Import_File.");
         raise;
   end Import_File;

   ------------------------------------------------------------------------

   function Read_File (File_Name : String; Flags : GL.Types.UInt)
                       return Scene.AI_Scene is
      use Scene;
      C_Scene   : API_Scene;
      theScene  : AI_Scene;
      C_Name    : constant Interfaces.C.char_array := Interfaces.C.To_C (File_Name);
   begin
      if Ada.Directories.Exists (File_Name) then
         Put_Line ("Importer.Read_File, C_Name: " & Interfaces.C.To_Ada (C_Name));
         C_Scene := Assimp.API.Read_File (C_Name, unsigned (Flags)).all;
         To_AI_Scene (C_Scene, theScene);
      else
         raise Import_Exception with "Importer.Read_File can't find " & File_Name;
      end if;

      return theScene;

   exception
      when  others =>
         Put_Line ("An exception occurred in Importer.Read_File.");
         raise;
   end Read_File;

   ------------------------------------------------------------------------

end Importer;
