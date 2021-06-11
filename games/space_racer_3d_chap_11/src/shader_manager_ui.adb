
with Ada.Exceptions; use Ada.Exceptions;
with Ada.Text_IO; use Ada.Text_IO;

with GL.Objects.Programs;
with GL.Objects.Shaders;
with GL.Uniforms;

with Program_Loader;

package body Shader_Manager_UI is

   UI_Program          : GL.Objects.Programs.Program;
   Texture_Uniform     : GL.Uniforms.Uniform;
   Model_Uniform       : GL.Uniforms.Uniform;
   View_Uniform        : GL.Uniforms.Uniform;
   Projection_Uniform  : GL.Uniforms.Uniform;

   procedure Init_Shaders is
      use GL.Objects.Shaders;
      use Program_Loader;
   begin
      UI_Program := Program_From
        ((Src ("src/shaders/ui_vertex_shader.glsl", Vertex_Shader),
         Src ("src/shaders/ui_fragment_shader.glsl", Fragment_Shader)));
      GL.Objects.Programs.Use_Program (UI_Program);

      Texture_Uniform :=
        GL.Objects.Programs.Uniform_Location (UI_Program, "texture2d");
      Model_Uniform :=
        GL.Objects.Programs.Uniform_Location (UI_Program, "model_matrix");
      Projection_Uniform :=
        GL.Objects.Programs.Uniform_Location (UI_Program, "projection_matrix");
      View_Uniform :=
        GL.Objects.Programs.Uniform_Location (UI_Program, "view_matrix");

      GL.Uniforms.Set_Single (Model_Uniform, GL.Types.Singles.Identity4);
      GL.Uniforms.Set_Single (Projection_Uniform, GL.Types.Singles.Identity4);
      GL.Uniforms.Set_Single (View_Uniform, GL.Types.Singles.Identity4);

   exception
      when anError : others =>
         Put_Line ("An exception occurred in Shader_Manager.Init_Shaders.");
         Put_Line (Exception_Information (anError));
         raise;
   end Init_Shaders;

   --  ------------------------------------------------------------------------

   procedure Set_Model_Matrix (Model_Matrix : GL.Types.Singles.Matrix4) is
   begin
      GL.Uniforms.Set_Single (Model_Uniform, Model_Matrix);
   end Set_Model_Matrix;

   --   ---------------------------------------------------------------------------------

   procedure Set_Projection_Matrix (Projection_Matrix : GL.Types.Singles.Matrix4) is
   begin
      GL.Uniforms.Set_Single (Projection_Uniform, Projection_Matrix);
   end Set_Projection_Matrix;

   --   ---------------------------------------------------------------------------------

   procedure Set_Texture (Texture  : GL.Types.UInt) is
   begin
      GL.Uniforms.Set_UInt (Texture_Uniform, Texture);
   end Set_Texture;

   --   -----------------------------------------------------------------------

   procedure Set_View_Matrix (View_Matrix : GL.Types.Singles.Matrix4) is
   begin
      GL.Uniforms.Set_Single (View_Uniform, View_Matrix);
   end Set_View_Matrix;

   --   ---------------------------------------------------------------------------------

end Shader_Manager_UI;
