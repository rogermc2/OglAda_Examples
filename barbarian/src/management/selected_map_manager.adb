
with Ada.Exceptions;
with Ada.Streams.Stream_IO;
with Ada.Text_IO; use Ada.Text_IO;

with Game_Utils;

package body Selected_Map_Manager is

   -- -------------------------------------------------------------------------

   procedure Load_Map (Path             : String; theMap : in out Selected_Map_Data;
                       Has_Hammer_Track : out Boolean) is
      use Ada.Streams;
      Input_File       : File_Type;
      Line_Length      : Integer;
      Num_Story_Lines  : Natural;
   begin
--        Game_Utils.Game_Log ("Selected_Map_Manager.Load_Map loading map " &
--                             Path);
      Open (Input_File, In_File, Path);
      theMap.Map_Title := To_Unbounded_String (Get_Line (Input_File));
      Line_Length := Length (theMap.Map_Title);
      for index in 1 .. Line_Length - 1 loop
         if Slice (theMap.Map_Title, index, index + 1) = "\r" or
           Slice (theMap.Map_Title, index, index + 1) = "\n" then
            Delete  (theMap.Map_Title, index, index + 1);
            Line_Length := Line_Length - 2;
         end if;
      end loop;

      theMap.Par_Time := To_Unbounded_String (Get_Line (Input_File));

      --  Story
      declare
         aString  : constant String := Get_Line (Input_File);
         Num_Part : constant String := aString (13 .. aString'Length);
      begin
         Num_Story_Lines := Integer'Value (Num_Part);
         for line_num in 1 .. Num_Story_Lines loop
            theMap.Map_Intro_Text.Append
              (To_Unbounded_String (Get_Line (Input_File)));
         end loop;
      end;  --  declare block

      theMap.Music_Track := To_Unbounded_String (Get_Line (Input_File));
      theMap.Hammer_Track := To_Unbounded_String (Get_Line (Input_File));
      Has_Hammer_Track := Length (theMap.Hammer_Track) > 3;

      Close (Input_File);

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Selected_Map_Manager.Load_Map!");
         Put_Line (Ada.Exceptions.Exception_Information (anError));
   end Load_Map;

   --  ------------------------------------------------------------------------

   function Map_Locked (aMap : Selected_Map_Data) return Boolean is
   begin
      return aMap.Locked;
   end Map_Locked;

   --  ------------------------------------------------------------------------

   procedure Set_Map_Lock (aMap : in out Selected_Map_Data; Lock : Boolean) is
   begin
      aMap.Locked := Lock;
   end Set_Map_Lock;

   --  ------------------------------------------------------------------------

end Selected_Map_Manager;
