
with Interfaces.C;

with Ada.Numerics.Generic_Real_Arrays;
with Ada.Text_IO; use Ada.Text_IO;

with GL.Attributes;
with GL.Buffers;
with GL.Objects.Buffers;
with GL.Objects.Programs;
with GL.Objects.Shaders;
with GL.Objects.Textures;
with GL.Objects.Textures.Targets;
with GL.Objects.Vertex_Arrays;
with GL.Toggles;
with GL.Types.Colors;
with GL.Uniforms;

with Glfw.Input.Keys;
with Glfw.Input.Mouse;
with Glfw.Windows;
with Glfw.Windows.Context;

with Controls;
with Program_Loader;
with Load_DDS;
with Utilities;
--  with VBO_Indexer;

with Particle_System;

procedure Main_Loop (Main_Window : in out Glfw.Windows.Window) is


   package Real_Array_Functions is new
     Ada.Numerics.Generic_Real_Arrays (GL.Types.Single);

    Dark_Blue              : constant GL.Types.Colors.Color := (0.0, 0.0, 0.4, 0.0);
    White                  : constant GL.Types.Colors.Color := (1.0, 1.0, 1.0, 1.0);

    Vertices_Array_Object  : GL.Objects.Vertex_Arrays.Vertex_Array_Object;
    Element_Buffer         : GL.Objects.Buffers.Buffer;

    Billboard_Buffer       : GL.Objects.Buffers.Buffer;
    Colour_Buffer          : GL.Objects.Buffers.Buffer;
    Positions_Buffer       : GL.Objects.Buffers.Buffer;
    Particle_Texture       : GL.Objects.Textures.Texture;

    Billboard_Program      : GL.Objects.Programs.Program;
    Camera_Right_ID        : GL.Uniforms.Uniform;
    Camera_Up_ID           : GL.Uniforms.Uniform;
    View_Point_ID          : GL.Uniforms.Uniform;
    CameraUp_worldspace    : GL.Uniforms.Uniform;
    Texture_ID             : GL.Uniforms.Uniform;

    Last_Time              : GL.Types.Single := GL.Types.Single (Glfw.Time);
    Number_Of_Frames       : Integer := 0;

    --  ------------------------------------------------------------------------

   function Convert_To_Real (m : GL.Types.Singles.Matrix4)
                             return Real_Array_Functions.Real_Matrix is
     use Real_Array_Functions;
     Result : Real_Matrix (1 .. 4, 1 .. 4);
   begin

      for row in 1 .. 4 loop
         for col in 1 .. 4 loop
            Result (row, col) := m (row, col);
         end loop;
      end loop;
      return Result;
   end Convert_To_Real;

    --  ------------------------------------------------------------------------
    procedure Load_Buffers is
        use GL.Objects.Buffers;
        use GL.Types;
        Vertex_Count       : Int;
        Vertices_Size      : Int;
        Vertex_Data        : constant Singles.Vector3_Array (1 .. 4) :=
                               ((-0.5, -0.5, 0.0),
                                (0.5, -0.5, 0.0),
                                (-0.5, 0.5, 0.0),
                                (0.5, 0.5, 0.0));
        Vertex_Data_Bytes  : constant Int := Vertex_Data'Size / 8;
        Buffer_Size        : constant Long :=
                             4 * Long (Particle_System.Max_Particles * Vertex_Data_Bytes);
    begin
        Billboard_Buffer.Initialize_Id;
        Array_Buffer.Bind (Billboard_Buffer);
        Utilities.Load_Vertex_Buffer (Array_Buffer, Vertex_Data, Static_Draw);

        Positions_Buffer.Initialize_Id;
        Array_Buffer.Bind (Positions_Buffer);
        Allocate (Array_Buffer, Buffer_Size, Static_Draw);

        Colour_Buffer.Initialize_Id;
        Array_Buffer.Bind (Colour_Buffer);
        Allocate (Array_Buffer, Buffer_Size, Static_Draw);

    exception
        when others =>
            Put_Line ("An exception occurred in Load_Buffers.");
            raise;
    end Load_Buffers;

    --  ------------------------------------------------------------------------

    procedure Load_Matrices (Window  : in out Glfw.Windows.Window) is
        use GL.Types;
      use GL.Types.Singles;
      use Real_Array_Functions;
      View_Matrix       : Matrix4;
      View_Matrix_Real  : Real_Matrix (1 .. 4, 1 .. 4);
      View_Matrix_Inv   : Real_Matrix (1 .. 4, 1 .. 4);
        Projection_Matrix : Matrix4;
        VP_Matrix         : Matrix4;
        Camera_Position   : Vector3;
    begin
        Controls.Compute_Matrices_From_Inputs (Window, Projection_Matrix, View_Matrix);
      VP_Matrix :=  Projection_Matrix * View_Matrix;
      View_Matrix_Real := Real_Matrix (View_Matrix);
      View_Matrix_Inv := Real_Matrix (View_Matrix);
      Camera_Position := Real_Array_Functions.Inverse (Real_Matrix (View_Matrix ))(3);

        GL.Uniforms.Set_Single (Model_Matrix_ID, Model_Matrix);
        GL.Uniforms.Set_Single (View_Matrix_ID, View_Matrix);
        GL.Uniforms.Set_Single (MVP_Matrix_ID, MVP_Matrix);
        GL.Uniforms.Set_Single (Light_Position_ID, 4.0, 4.0, 4.0);

    exception
        when others =>
            Put_Line ("An exception occurred in Load_Matrices.");
            raise;
    end Load_Matrices;

   --  ------------------------------------------------------------------------

   procedure Load_Shaders is
      begin
      Particle_Program := Program_Loader.Program_From
          ((Program_Loader.Src ("src/shaders/particle_vertex_shader.glsl",
           Vertex_Shader),
           Program_Loader.Src ("src/shaders/particle_fragment_shader.glsl",
             Fragment_Shader)));

        Camera_Right_ID := GL.Objects.Programs.Uniform_Location
          (Particle_Program, "CameraRight_worldspace");
        Camera_Up_ID := GL.Objects.Programs.Uniform_Location
          (Particle_Program, "CameraUp_worldspace");
        View_Point_ID := GL.Objects.Programs.Uniform_Location
        (Particle_Program, "VP");

        Texture_ID := GL.Objects.Programs.Uniform_Location
        (Particle_Program, "myTextureSampler");

    exception
        when others =>
            Put_Line ("An exception occurred in Load_Shaders.");
            raise;
    end Load_Shaders;

   --  ------------------------------------------------------------------------

    procedure Render (Window : in out Glfw.Windows.Window) is
        use Interfaces.C;
        use GL.Objects.Buffers;
        use GL.Types;
        Current_Time : constant Glfw.Seconds := Glfw.Time;
        Delta_Time   : constant Single := Last_Time - Single (Current_Time);
    begin
        Utilities.Clear_Background_Colour_And_Depth (Dark_Blue);
        if Current_Time - Last_Time >= 1.0 then
            Put_Line (Integer'Image (1000 * Number_Of_Frames) & " ms/frame");
            Number_Of_Frames := 0;
            Last_Time := Last_Time + 1.0;
        end if;

        GL.Objects.Programs.Use_Program (Render_Program);
        Load_Matrices (Window);

        --  First attribute buffer : vertices
        GL.Attributes.Enable_Vertex_Attrib_Array (0);
        GL.Objects.Buffers.Array_Buffer.Bind (Vertex_Buffer);
        GL.Attributes.Set_Vertex_Attrib_Pointer (0, 3, Single_Type, True, 0, 0);
        --  Second attribute buffer : UVs
        GL.Attributes.Enable_Vertex_Attrib_Array (1);
        GL.Objects.Buffers.Array_Buffer.Bind (UVs_Buffer);
        GL.Attributes.Set_Vertex_Attrib_Pointer (1, 2, Single_Type, True, 0, 0);
        --  Third attribute buffer : normals
        GL.Attributes.Enable_Vertex_Attrib_Array (2);
        GL.Objects.Buffers.Array_Buffer.Bind (Normals_Buffer);
        GL.Attributes.Set_Vertex_Attrib_Pointer (2, 3, Single_Type, True, 0, 0);

        --  Index Buffer
        GL.Objects.Buffers.Element_Array_Buffer.Bind (Element_Buffer);

        --  Bind the texture in Texture Unit 0
        GL.Objects.Textures.Set_Active_Unit (0);
        GL.Objects.Textures.Targets.Texture_2D.Bind (UV_Map);
        GL.Uniforms.Set_Int (Texture_ID, 0);

        GL.Objects.Buffers.Draw_Elements (Triangles, Indices_Size, UInt_Type, 0);

        GL.Attributes.Disable_Vertex_Attrib_Array (0);
        GL.Attributes.Disable_Vertex_Attrib_Array (1);
        GL.Attributes.Disable_Vertex_Attrib_Array (2);
    exception
        when others =>
            Put_Line ("An exception occurred in Render.");
            raise;
    end Render;

    --  ------------------------------------------------------------------------

    procedure Setup (Window : in out Glfw.Windows.Window) is
        use GL.Objects.Shaders;
        use GL.Types;
        use Glfw.Input;
        Window_Width    : constant Glfw.Size := 1024;
        Window_Height   : constant Glfw.Size := 768;

    begin
        Window.Set_Input_Toggle (Sticky_Keys, True);
        Window.Set_Cursor_Mode (Mouse.Disabled);

        Window'Access.Set_Size (Window_Width, Window_Height);
        Window'Access.Set_Cursor_Pos (Mouse.Coordinate (0.5 * Single (Window_Width)),
                                      Mouse.Coordinate (0.5 * Single (Window_Height)));
        Utilities.Clear_Background_Colour_And_Depth (Dark_Blue);

        GL.Toggles.Enable (GL.Toggles.Depth_Test);
        GL.Buffers.Set_Depth_Function (GL.Types.Less);

        Vertices_Array_Object.Initialize_Id;
      Vertices_Array_Object.Bind;

      Load_Shaders;

        Load_DDS ("src/textures/particle.DDS", Particle_Texture);

        Load_Buffers;

        Light_Position_ID := GL.Objects.Programs.Uniform_Location
          (Render_Program, "LightPosition_worldspace");
        Last_Time := Glfw.Time;
    exception
        when others =>
            Put_Line ("An exception occurred in Setup.");
            raise;
    end Setup;

    --  ------------------------------------------------------------------------

    use Glfw.Input;
    Running         : Boolean := True;
begin
    Setup (Main_Window);
    while Running loop
        Render (Main_Window, Render_Program, Vertex_Count, UV_Map);
        Glfw.Windows.Context.Swap_Buffers (Main_Window'Access);
        Glfw.Input.Poll_Events;
        Running := Running and then
          not (Main_Window.Key_State (Glfw.Input.Keys.Escape) = Glfw.Input.Pressed);
        Running := Running and then not Main_Window.Should_Close;
    end loop;

exception
    when others =>
        Put_Line ("An exception occurred in Main_Loop.");
        raise;
end Main_Loop;
