
with Ada.Text_IO; use Ada.Text_IO;

with GL;
with GL.Objects.Shaders;
with GL.Uniforms;

with Maths;
with Program_Loader;

package body Lighting_Technique_18 is 

   type Light_Location is record
      Colour            : GL.Uniforms.Uniform;
      Direction         : GL.Uniforms.Uniform;
      Ambient_Intensity : GL.Uniforms.Uniform;
      Diffuse_Intensity : GL.Uniforms.Uniform;
   end record;
     
   WVP_Location                    : GL.Uniforms.Uniform;
   World_Matrix_Location           : GL.Uniforms.Uniform;
   Sampler_Location                : GL.Uniforms.Uniform;
   Eye_World_Pos_Location          : GL.Uniforms.Uniform;
   Directional_Light_Location      : Light_Location;

   function Init (Shader_Program : in out GL.Objects.Programs.Program) return Boolean is
      use GL.Objects.Shaders;
      use Program_Loader;
      OK  : Boolean := False;
   begin
      Shader_Program := Program_From
        ((Src ("src/shaders/diffuse_lighting.vs", Vertex_Shader),
         Src ("src/shaders/diffuse_lighting.fs", Fragment_Shader)));

      OK := GL.Objects.Programs.Link_Status (Shader_Program);
      if not OK then
         Put_Line ("Build_Shader_Program, Shader_Program Link failed");
         Put_Line (GL.Objects.Programs.Info_Log (Shader_Program));
      else
         GL.Objects.Programs.Use_Program (Shader_Program);
         WVP_Location :=
           GL.Objects.Programs.Uniform_Location (Shader_Program, "gWVP");
         Sampler_Location :=
           GL.Objects.Programs.Uniform_Location (Shader_Program, "gSampler");
         World_Matrix_Location :=
           GL.Objects.Programs.Uniform_Location (Shader_Program, "gWorld");
         Eye_World_Pos_Location :=
           GL.Objects.Programs.Uniform_Location (Shader_Program, "gEyeWorldPos");
         Directional_Light_Location.Colour :=
           GL.Objects.Programs.Uniform_Location (Shader_Program, "gDirectionalLight.Color");
         Directional_Light_Location.Ambient_Intensity :=
           GL.Objects.Programs.Uniform_Location (Shader_Program, "gDirectionalLight.AmbientIntensity");
         Directional_Light_Location.Direction :=
           GL.Objects.Programs.Uniform_Location (Shader_Program, "gDirectionalLight.Direction");
         Directional_Light_Location.Diffuse_Intensity  :=
           GL.Objects.Programs.Uniform_Location (Shader_Program, "gDirectionalLight.DiffuseIntensity");
      end if;
      return OK;

   exception
      when  others =>
         Put_Line ("An exception occurred in Main_Loop.Init.");
         raise;
   end Init;

   procedure Set_WVP_Location (WVP : Singles.Matrix4) is
   begin
      GL.Uniforms.Set_Single (WVP_Location, WVP);    
   end Set_WVP_Location;
    
   procedure Set_World_Matrix_Location (World_Inverse: Singles.Matrix4) is
   begin
      GL.Uniforms.Set_Single (World_Matrix_Location, World_Inverse);
   end Set_World_Matrix_Location;

   procedure Set_Texture_Unit (Texture_Unit : Int) is
   begin
      GL.Uniforms.Set_Int (Sampler_Location, Texture_Unit);
   end Set_Texture_Unit;

   procedure Set_Directional_Light_Location (Light : Directional_Light) is
      use GL.Uniforms;
   begin
      Set_Single (Directional_Light_Location.Colour, Light.Colour);
      Set_Single (Directional_Light_Location.Ambient_Intensity,
                  Light.Ambient_Intensity);
      Set_Single (Directional_Light_Location.Direction, 
                  Maths.Normalized (Light.Direction));
      Set_Single (Directional_Light_Location.Diffuse_Intensity, 
                  Light.Diffuse_Intensity);
   end Set_Directional_Light_Location;

   procedure Set_Eye_World_Pos (Eye_World_Pos : Singles.Vector3) is
   begin
      GL.Uniforms.Set_Single (Eye_World_Pos_Location, Eye_World_Pos (GL.X), Eye_World_Pos (GL.Y), Eye_World_Pos (GL.Z));
   end Set_Eye_World_Pos;

   procedure Set_Ambient_Intensity_Location (Intensity : Single) is
   begin
      GL.Uniforms.Set_Single (Directional_Light_Location.Ambient_Intensity, Intensity);
   end Set_Ambient_Intensity_Location;

end Lighting_Technique_18;
