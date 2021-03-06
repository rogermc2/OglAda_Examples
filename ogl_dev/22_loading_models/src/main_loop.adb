
with Ada.Text_IO; use Ada.Text_IO;

with GL.Buffers;
with GL.Objects;
with GL.Objects.Programs;
with GL.Objects.Vertex_Arrays;
with GL.Toggles;
with GL.Types.Colors;
with GL.Window;

with Glfw;
with Glfw.Input;
with Glfw.Input.Keys;
with Glfw.Windows.Context;

with Maths;
with Utilities;

with Ogldev_Basic_Lighting;
with Ogldev_Camera;
with Ogldev_Lights_Common;
with Ogldev_Math;
with Ogldev_Pipeline;

with Meshes_22;

procedure Main_Loop (Main_Window :  in out Glfw.Windows.Window) is
    use GL.Types;

    Background             : constant GL.Types.Colors.Color := (0.7, 0.7, 0.7, 0.0);

    VAO                    : GL.Objects.Vertex_Arrays.Vertex_Array_Object;
    Game_Camera            : Ogldev_Camera.Camera;
    Light_Technique        : Ogldev_Basic_Lighting.Basic_Lighting_Technique;
    Direct_Light           : Ogldev_Lights_Common.Directional_Light;
    Perspective_Proj_Info  : Ogldev_Math.Perspective_Projection_Info;
    Scale                  : Single := 0.0;

    --  ------------------------------------------------------------------------

    procedure Init (Window  : in out Glfw.Windows.Window;
                    theMesh : out Meshes_22.Mesh_22; Result : out Boolean) is

        Window_Width        : Glfw.Size;
        Window_Height       : Glfw.Size;
        Camera_Position     : constant Singles.Vector3 := (2.0, 2.0, 10.0); --  Normalized by Camera.Init
        Target_Position     : constant Singles.Vector3 := (0.0, 0.0, -1.0);  --  Normalized by Camera.Init
        Up                  : constant Singles.Vector3 := (0.0, 1.0, 0.0);
    begin
        VAO.Initialize_Id;
        VAO.Bind;
        Result := Ogldev_Basic_Lighting.Init (Light_Technique);
        if Result then
            Ogldev_Lights_Common.Init_Directional_Light
              (Direct_Light, 1.0, 0.01, Ogldev_Lights_Common.Colour_White, (1.0, -1.0, 0.0));
            Window.Get_Framebuffer_Size (Window_Width, Window_Height);

            Ogldev_Math.Set_Perspective_FOV (Perspective_Proj_Info, 60.0);
            Ogldev_Math.Set_Perspective_Height (Perspective_Proj_Info, GL.Types.UInt (Window_Height));
            Ogldev_Math.Set_Perspective_Width (Perspective_Proj_Info, GL.Types.UInt (Window_Width));
            Ogldev_Math.Set_Perspective_Near (Perspective_Proj_Info, 1.0);
            Ogldev_Math.Set_Perspective_Far (Perspective_Proj_Info, 50.0);

            Ogldev_Camera.Init_Camera (Game_Camera, Window,
                                       Camera_Position, Target_Position, Up);
            Ogldev_Camera.Set_Step_Size (2.0);
            Utilities.Clear_Background_Colour_And_Depth (Background);

            GL.Toggles.Enable (GL.Toggles.Depth_Test);
            GL.Buffers.Set_Depth_Function (GL.Types.LEqual);
            GL.Objects.Programs.Use_Program (Ogldev_Basic_Lighting.Lighting_Program (Light_Technique));
            Ogldev_Basic_Lighting.Set_Color_Texture_Unit_Location (Light_Technique, 0);

            Meshes_22.Load_Mesh
              (theMesh, "/Ada_Source/OglAda_Examples/ogl_dev/content/phoenix_ugv.md2");
        else
            Put_Line ("Main_Loop.Init, Ogldev_Basic_Lighting.Init failed.");
        end if;

    exception
        when others =>
            Put_Line ("An exception occurred in Main_Loop.Init.");
            raise;
    end Init;

    --  ------------------------------------------------------------------------

    procedure Render_Scene (Window  : in out Glfw.Windows.Window;
                            theMesh : Meshes_22.Mesh_22) is
        use GL.Types.Singles;
        use Maths.Single_Math_Functions;
        use Ogldev_Basic_Lighting;
        use Ogldev_Camera;
        use Ogldev_Lights_Common;
        Window_Width         : Glfw.Size;
        Window_Height        : Glfw.Size;
        Field_Depth          : constant Single := 10.0;
        Point_Lights         : Point_Light_Array (1 .. 2);
        Spot_Lights          : Spot_Light_Array (1 .. 1);
        Pipe                 : Ogldev_Pipeline.Pipeline;
    begin
        Scale := Scale + 0.02;
        Utilities.Clear_Background_Colour_And_Depth (Background);
        Update_Camera (Game_Camera, Window);

        Window.Get_Framebuffer_Size (Window_Width, Window_Height);
        GL.Window.Set_Viewport (0, 0, GL.Types.Int (Window_Width),
                                GL.Types.Int (Window_Height));
        GL.Objects.Programs.Use_Program (Ogldev_Basic_Lighting.Lighting_Program (Light_Technique));

        Set_Diffuse_Intensity (Point_Lights (1), 0.25);
        Set_Point_Light (Light     => Point_Lights (1),
                         Pos       => (3.0, 1.0, Field_Depth * (Cos (Scale) + 1.0) / 2.0),
                         theColour => (1.0, 0.5, 0.0));
        Set_Linear_Attenuation (Point_Lights (1), 0.1);

        Set_Diffuse_Intensity (Point_Lights (2), 0.25);
        Set_Point_Light (Point_Lights (2), (7.0, 1.0,
                         Field_Depth * (Sin (Scale) + 1.0) / 2.0),
                         (0.0, 0.5, 1.0));
        Set_Linear_Attenuation (Point_Lights (2), 0.1);

        Set_Point_Lights_Location (Light_Technique, Point_Lights);

        Set_Diffuse_Intensity (Spot_Lights (1), 0.9);
        Set_Spot_Light (Spot_Lights (1), Get_Position (Game_Camera), (0.0, 1.0, 1.0));
        Set_Spot_Light (Spot_Lights (1), (0.0, 0.0, 0.0), (0.0, 1.0, 1.0));
        Set_Direction (Spot_Lights (1), Get_Target (Game_Camera));
        Set_Direction (Spot_Lights (1),  (0.0, 0.0, -1.0));
        Set_Linear_Attenuation (Spot_Lights (1), 0.1);
        Set_Cut_Off (Spot_Lights (1), 10.0);

        Ogldev_Pipeline.Set_Scale (Pipe, 0.04);
        Ogldev_Pipeline.Set_Rotation (Pipe, 0.0, 30.0 * Scale, 0.0);
        Ogldev_Pipeline.Set_World_Position (Pipe, 0.0, 0.0, -6.0);
        Ogldev_Pipeline.Set_Camera (Pipe, Game_Camera);
        Ogldev_Pipeline.Set_Perspective_Projection (Pipe, Perspective_Proj_Info);
        Ogldev_Pipeline.Init_Transforms  (Pipe);

        Set_World_Matrix_Location (Light_Technique, Ogldev_Pipeline.Get_World_Transform (Pipe));
        Set_Eye_World_Pos_Location (Light_Technique, Get_Position (Game_Camera));
        Set_WVP_Location (Light_Technique, Ogldev_Pipeline.Get_WVP_Transform (Pipe));
        Set_Directional_Light_Location (Light_Technique, Direct_Light);
        Set_Specular_Intensity_Location (Light_Technique, 0.0);
        Set_Specular_Power_Location (Light_Technique, 0);

        Meshes_22.Render_Mesh (theMesh);

    exception
        when  others =>
            Put_Line ("An exception occurred in Main_Loop.Render_Scene.");
            raise;
    end Render_Scene;

    --  ------------------------------------------------------------------------

    use Glfw.Input;
    theMesh : Meshes_22.Mesh_22;
    Running : Boolean;
begin
    Init (Main_Window, theMesh, Running);
    while Running loop
        Render_Scene (Main_Window, theMesh);
        Glfw.Windows.Context.Swap_Buffers (Main_Window'Access);
        Glfw.Input.Poll_Events;
        Running := Running and not
          (Main_Window.Key_State (Glfw.Input.Keys.Escape) = Glfw.Input.Pressed);
        Running := Running and not Main_Window.Should_Close;
    end loop;

exception
    when others =>
        Put_Line ("An exception occurred in Main_Loop.");
        raise;
end Main_Loop;
