
with GL.Types; use GL.Types;
with GL.Objects.Programs;

package Cursor_Shader_Manager is

    procedure Init (Shader_Program : in out GL.Objects.Programs.Program);
    procedure Set_Model_Matrix (Model_Matrix : Singles.Matrix4);
    procedure Set_Perspective_Matrix (Perspective_Matrix : Singles.Matrix4);
    procedure Set_View_Matrix (View_Matrix : Singles.Matrix4);
    procedure Set_Diff_Map (Diff_Map : Int);

end Cursor_Shader_Manager;