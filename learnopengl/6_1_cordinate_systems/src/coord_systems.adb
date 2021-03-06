
with Ada.Exceptions; use Ada.Exceptions;
with Ada.Text_IO; use Ada.Text_IO;

with Glfw;
with Glfw.Windows;

with Initialize;
with Main_Loop;

procedure Coord_Systems is
    Main_Window  : Glfw.Windows.Window;
    Window_Title : constant String := "Learn OpenGL - 6.1 Coordinate Systems";
begin
    Glfw.Init;
    Initialize (Main_Window, Window_Title);
    Main_Loop (Main_Window);
    Glfw.Shutdown;

exception
    when anError : Constraint_Error =>
        Put ("Coord_Systems returned a constraint error: ");
        Put_Line (Exception_Information (anError));

    when anError :  others =>
        Put_Line ("An exception occurred in Coord_Systems.");
        Put_Line (Exception_Information (anError));

end Coord_Systems;
