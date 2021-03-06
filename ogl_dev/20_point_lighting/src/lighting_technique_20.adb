
with Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;

with GL;
with GL.Objects.Shaders;
with GL.Objects.Shaders.Lists;

with Maths;
with Program_Loader;

package body Lighting_Technique_20 is 
    
   function Light_Program (theTechnique : Technique)
                            return GL.Objects.Programs.Program;
   function Point_Name (Index : GL.Types.Int; Unif : String) return String;
    
   --  -------------------------------------------------------------------------
    
   function Get_Directional_Ambient (Light : Directional_Light) return Single is
   begin
      return Light.Base.Ambient_Intensity;
   end Get_Directional_Ambient;

   --  -------------------------------------------------------------------------
    
   function Get_Directional_Diffuse (Light : Directional_Light) return Single is
   begin
      return Light.Base.Diffuse_Intensity;
   end Get_Directional_Diffuse;

   --  -------------------------------------------------------------------------
    
   function Get_Uniform_Location (theTechnique : Technique; Uniform_Name : String)
                                   return GL.Uniforms.Uniform is
   begin
      return GL.Objects.Programs.Uniform_Location (Light_Program (theTechnique), Uniform_Name);
   end Get_Uniform_Location;

   --  -------------------------------------------------------------------------

   function Init (theTechnique  : out Technique) return Boolean is
      use GL.Objects.Shaders;
      use Program_Loader;
      OK  : Boolean := False;
   begin
      theTechnique.Lighting_Program := Program_From
        ((Src ("src/shaders/lighting_20.vs", Vertex_Shader),
         Src ("src/shaders/lighting_20.fs", Fragment_Shader)));

      OK := GL.Objects.Programs.Link_Status (theTechnique.Lighting_Program);
      if not OK then
         Put_Line ("Build_Shader_Program, theTechnique.Lighting_Program Link failed");
         Put_Line (GL.Objects.Programs.Info_Log (theTechnique.Lighting_Program));
      else
         GL.Objects.Programs.Use_Program (theTechnique.Lighting_Program);
         theTechnique.WVP_Location :=
           GL.Objects.Programs.Uniform_Location (theTechnique.Lighting_Program, "gWVP");
         theTechnique.World_Matrix_Location :=
           GL.Objects.Programs.Uniform_Location (theTechnique.Lighting_Program, "gWorld");
         theTechnique.Sampler_Location :=
           GL.Objects.Programs.Uniform_Location (theTechnique.Lighting_Program, "gSampler");
         theTechnique.Eye_World_Pos_Location :=
           GL.Objects.Programs.Uniform_Location (theTechnique.Lighting_Program, "gEyeWorldPos");
         theTechnique.Direct_Light_Location.Color := GL.Objects.Programs.Uniform_Location
           (theTechnique.Lighting_Program, "gDirectionalLight.Base.Color");
         theTechnique.Direct_Light_Location.Ambient_Intensity := GL.Objects.Programs.Uniform_Location
           (theTechnique.Lighting_Program, "gDirectionalLight.Base.AmbientIntensity");
         theTechnique.Direct_Light_Location.Diffuse_Intensity := GL.Objects.Programs.Uniform_Location
           (theTechnique.Lighting_Program, "gDirectionalLight.Base.DiffuseIntensity");
         theTechnique.Direct_Light_Location.Direction := GL.Objects.Programs.Uniform_Location
           (theTechnique.Lighting_Program, "gDirectionalLight.Direction");

         theTechnique.Mat_Specular_Intensity_Location  :=
           GL.Objects.Programs.Uniform_Location (theTechnique.Lighting_Program, "gMatSpecularIntensity");
         theTechnique.Mat_Specular_Power_Location  :=
           GL.Objects.Programs.Uniform_Location (theTechnique.Lighting_Program, "gSpecularPower");
         theTechnique.Num_Point_Lights_Location  :=
           GL.Objects.Programs.Uniform_Location (theTechnique.Lighting_Program, "gNumPointLights");
            
         for index in GL.Types.Int range
           Point_Lights_Location_Array'First .. Point_Lights_Location_Array'Last loop
            theTechnique.Point_Lights_Locations (GL.Types.Int (index)).Colour :=
              Get_Uniform_Location (theTechnique, Point_Name (index, "Base.Color"));
            theTechnique.Point_Lights_Locations (GL.Types.Int (index)).Ambient_Intensity :=
              Get_Uniform_Location (theTechnique, Point_Name (index, "Base.AmbientIntensity"));
            theTechnique.Point_Lights_Locations (GL.Types.Int (index)).Diffuse_Intensity :=
              Get_Uniform_Location (theTechnique, Point_Name (index, "Base.DiffuseIntensity"));
            theTechnique.Point_Lights_Locations (GL.Types.Int (index)).Position :=
              Get_Uniform_Location (theTechnique, Point_Name (index, "Position"));
            theTechnique.Point_Lights_Locations (GL.Types.Int (index)).Atten.Constant_Atten :=
              Get_Uniform_Location (theTechnique, Point_Name (index, "Atten.Constant"));
            theTechnique.Point_Lights_Locations (GL.Types.Int (index)).Atten.Linear :=
              Get_Uniform_Location (theTechnique, Point_Name (index, "Atten.Linear"));
            theTechnique.Point_Lights_Locations (GL.Types.Int (index)).Atten.Exp :=
              Get_Uniform_Location (theTechnique, Point_Name (index, "Atten.Exp"));
         end loop;

      end if;
      return OK;

   exception
      when  others =>
         Put_Line ("An exception occurred in Main_Loop.Init.");
         raise;
   end Init;
   
   --   -------------------------------------------------------------------------------------------------------

   procedure Init_Directional_Light (Light : out Directional_Light) is
   begin
      Light.Base.Colour := (1.0, 1.0, 1.0);
      Light.Base.Ambient_Intensity := 0.0;
      Light.Base.Diffuse_Intensity := 0.01;
      Light.Direction := (1.0, -1.0, 0.0);
   end Init_Directional_Light;

   --  -------------------------------------------------------------------------
 
   function Light_Program (theTechnique : Technique)
                            return GL.Objects.Programs.Program is
   begin
      return theTechnique.Lighting_Program;
   end Light_Program;

   --  -------------------------------------------------------------------------

   function Point_Name (Index : GL.Types.Int; Unif : String) return String is
      use Ada.Strings.Unbounded;
   begin
      return To_String ("gPointLights[" &
                          Trim (To_Unbounded_String (Int'Image (Index - 1)), Ada.Strings.Left)
                        & "]." & Unif);
   end Point_Name;

   --  -------------------------------------------------------------------------
    
   procedure Set_Ambient_Intensity (theTechnique : Technique; Intensity : Single) is
   begin
      GL.Uniforms.Set_Single (theTechnique.Direct_Light_Location.Ambient_Intensity, Intensity);
   end Set_Ambient_Intensity;
   
   --   -------------------------------------------------------------------------------------------------------

   procedure Set_Directional_Ambient (Light   : in out Directional_Light;
                                      Ambient : Single) is
   begin
      Light.Base.Ambient_Intensity := Ambient;
   end Set_Directional_Ambient;

   --  -------------------------------------------------------------------------
    
   procedure Set_Directional_Diffuse (Light   : in out Directional_Light;
                                      Diffuse : Single) is
   begin
      Light.Base.Diffuse_Intensity := Diffuse;
   end Set_Directional_Diffuse;

   --  -------------------------------------------------------------------------
    
   procedure Set_Directional_Light_Location (theTechnique : Technique; 
                                             Light        : Directional_Light) is
   begin
      GL.Uniforms.Set_Single (theTechnique.Direct_Light_Location.Color,
                              Light.Base.Colour);
      GL.Uniforms.Set_Single (theTechnique.Direct_Light_Location.Ambient_Intensity,
                              Light.Base.Ambient_Intensity);
      GL.Uniforms.Set_Single (theTechnique.Direct_Light_Location.Direction,
                               Maths.Normalized (Light.Direction));
      GL.Uniforms.Set_Single (theTechnique.Direct_Light_Location.Diffuse_Intensity, 
                              Light.Base.Diffuse_Intensity);
   end Set_Directional_Light_Location;
   
   --   -------------------------------------------------------------------------------------------------------

   procedure Set_Eye_World_Pos_Location (theTechnique : Technique; Position : Singles.Vector3) is
   begin
      GL.Uniforms.Set_Single (theTechnique.Eye_World_Pos_Location, Position);
   end Set_Eye_World_Pos_Location;
   
   --   -------------------------------------------------------------------------------------------------------

   procedure Set_Mat_Specular_Intensity (theTechnique : Technique; Intensity : Single) is
   begin
      GL.Uniforms.Set_Single (theTechnique.Mat_Specular_Intensity_Location, Intensity);
   end Set_Mat_Specular_Intensity;

   --   -------------------------------------------------------------------------------------------------------

   procedure Set_Mat_Specular_Power (theTechnique : Technique; Power : Single) is
   begin
      GL.Uniforms.Set_Single (theTechnique.Mat_Specular_Power_Location, Power);
   end Set_Mat_Specular_Power;
    
   --   -------------------------------------------------------------------------------------------------------

   procedure Set_Point_Light (Light            : in out Point_Light; Diffuse : Single; 
                              Colour, Position : Singles.Vector3; Atten : Attenuation) is
   begin
      Light.Base.Colour := Colour;
      Light.Base.Diffuse_Intensity := Diffuse;
      Light.Origin := Position;
      Light.Atten := Atten;
   end Set_Point_Light;

   --  -------------------------------------------------------------------------   
 
   procedure Set_Point_Light_Locations (theTechnique : Technique; Lights : Point_Lights_Array) is
   begin
      GL.Uniforms.Set_Int (theTechnique.Num_Point_Lights_Location, Max_Point_Lights);
      for index in GL.Types.Int range Lights'First .. Lights'Last loop
         GL.Uniforms.Set_Single (theTechnique.Point_Lights_Locations (index).Colour,
                                 Lights (index).Base.Colour);
         GL.Uniforms.Set_Single (theTechnique.Point_Lights_Locations (index).Ambient_Intensity,
                                 Lights (index).Base.Ambient_Intensity);
         GL.Uniforms.Set_Single (theTechnique.Point_Lights_Locations (index).Diffuse_Intensity,
                                 Lights (index).Base.Diffuse_Intensity);
         GL.Uniforms.Set_Single (theTechnique.Point_Lights_Locations (index).Position,
                                 Lights (index).Origin);
         GL.Uniforms.Set_Single (theTechnique.Point_Lights_Locations (index).Atten.Constant_Atten,
                                 Lights (index).Atten.Constant_Atten);
         GL.Uniforms.Set_Single (theTechnique.Point_Lights_Locations (index).Atten.Linear,
                                 Lights (index).Atten.Linear);
         GL.Uniforms.Set_Single (theTechnique.Point_Lights_Locations (index).Atten.Exp,
                                 Lights (index).Atten.Exp);
      end loop;                        
   end Set_Point_Light_Locations;

   --   -------------------------------------------------------------------------------------------------------
    
     
   procedure Set_Texture_Unit (theTechnique : Technique; Texture_Unit : Int) is
   begin
      GL.Uniforms.Set_Int (theTechnique.Sampler_Location, Texture_Unit);
   end Set_Texture_Unit;
   
   --   -------------------------------------------------------------------------------------------------------
  
   procedure Set_World_Matrix_Location (theTechnique  : Technique;
                                        World_Inverse : Singles.Matrix4) is
   begin
      GL.Uniforms.Set_Single (theTechnique.World_Matrix_Location, World_Inverse);
   end Set_World_Matrix_Location;
   
   --   -------------------------------------------------------------------------------------------------------

   procedure Set_WVP_Location (theTechnique : Technique; WVP : Singles.Matrix4) is
   begin
      GL.Uniforms.Set_Single (theTechnique.WVP_Location, WVP);    
   end Set_WVP_Location;
   
   --   -------------------------------------------------------------------------------------------------------

   procedure Use_Program (theTechnique : Technique) is
      use GL.Objects.Shaders.Lists;
   begin
      if GL.Objects.Programs.Link_Status (theTechnique.Lighting_Program) then
         declare
            Shaders_List : constant GL.Objects.Shaders.Lists.List :=
                             GL.Objects.Programs.Attached_Shaders (theTechnique.Lighting_Program);
            Curs         : constant GL.Objects.Shaders.Lists.Cursor := Shaders_List.First;
         begin
            if Curs = GL.Objects.Shaders.Lists.No_Element then
               Put_Line ("Lighting_Technique_20.Use_Program, Shaders list is empty");
            else
               GL.Objects.Programs.Use_Program (theTechnique.Lighting_Program);
            end if;
         end;  -- declare block
      else
         Put_Line ("Lighting_Technique_20.Use_Program, Link check failed");
      end if;

   exception
      when  others =>
         Put_Line ("An exception occurred in Lighting_Technique_20.Use_Program.");
         raise;
   end Use_Program;

   --  -------------------------------------------------------------------------
    
end Lighting_Technique_20;
