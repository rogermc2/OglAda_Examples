
with Ada.Containers.Vectors;
with Ada.Exceptions;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with GL.Types.Colors;

package body Text_Manager is
    use GL.Types.Colors;

    type Coloured_Text is record
        Text   : Unbounded_String := To_Unbounded_String ("");
        Colour : Color;
    end record;

    package Coloured_Text_Package is new
      Ada.Containers.Vectors (Positive, Coloured_Text);
    type Coloured_Text_List is new Coloured_Text_Package.Vector with null record;

    type Popup_Data is record
        Rx          : Integer;
        RGBA        : GL.Types.Colors.Color;
        Popup_Text  : Unbounded_String := To_Unbounded_String ("");
    end record;

    Preloaded_Comic_Texts : Coloured_Text_List;

    -- -------------------------------------------------------------------------

   procedure Preload_Comic_Texts (Input_File : File_Type) is
        use Ada.Strings;
        use GL.Types;
        aLine       : String := Get_Line (Input_File);
        Last        : Integer := Integer (aLine'Length);
        Pos         : Natural;
        Popup_Count : Integer := 0;
        Popup       : Popup_Data;
        C_Text      : Coloured_Text;
    begin
        Preloaded_Comic_Texts.Clear;
        Pos := Fixed.Index (aLine, " ");
        if aLine (1 .. Pos - 1) /= "popups" then
            raise Text_Manager_Exception with
              "Text_Manager.Preload_Comic_Texts; Invalid Comic_Texts format: "
               & aLine;
        end if;
        Popup_Count := Integer'Value (aLine (Pos + 1 .. Last));
        for index in 1 .. Popup_Count loop
            Popup.Popup_Text := To_Unbounded_String ("");
                -- Process any \n?
                C_Text.Text := Popup.Popup_Text;
                C_Text.Colour := Popup.RGBA;
                Preloaded_Comic_Texts.Append (C_Text);
            --  register rx code
            --  if (!gEventController.addReceiver (rx, RX_STORY,
	    --  g_preloaded_comic_colours.size () - 1))
        end loop;

    exception
        when anError : others =>
            Put_Line
              ("An exception occurred in Text_Manager.Preload_Comic_Texts!");
            Put_Line (Ada.Exceptions.Exception_Information (anError));
    end Preload_Comic_Texts;

    --  ----------------------------------------------------------------------------

end Text_Manager;
