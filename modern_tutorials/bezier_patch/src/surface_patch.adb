
with Ada.Text_IO; use Ada.Text_IO;

package body Surface_Patch is
   use GL.Types;

   procedure Print_Patch (Name     : String;
                          thePatch : Patch_Data.Patch_Type);
   function U_Coord (Patch : Patch_Data.Patch_Type;
                     Index : Int; T : Single) return Singles.Vector3;
   function V_Cord (Patch : Patch_Data.Patch_Type;
                    Index : Int; T : Single) return Singles.Vector3;

   --  --------------------------------------------------------------------------------
   --  Blend_Vectors calculates the vector cubic Bezier spline value at the parameter T
   function  Blend_Vectors (CP0, CP1, CP2, CP3 : Singles.Vector3;
                           T : GL.Types.Single) return Singles.Vector3 is
       use GL;
       CP0_Weight : constant Single := (1.0 - T) ** 3;
       CP1_Weight : constant Single := 3.0 * T * (1.0 - T) ** 2;
       CP2_Weight : constant Single := 3.0 * T * T * (1.0 - T);
       CP3_Weight : constant Single := T ** 3;
       Result     : Singles.Vector3;
   begin
      Result (X) :=  CP0_Weight * CP0 (X) + CP1_Weight * CP1 (X) +
        CP2_Weight * CP2 (X) + CP3_Weight * CP3 (X);
      Result (Y) :=  CP0_Weight * CP0 (Y) + CP1_Weight * CP1 (Y) +
        CP2_Weight * CP2 (Y) + CP3_Weight * CP3 (Y);
      Result (Z) :=  CP0_Weight * CP0 (Z) + CP1_Weight * CP1 (Z) +
        CP2_Weight * CP2 (Z) + CP3_Weight * CP3 (Z);
      return Result;
   end Blend_Vectors;

  --  --------------------------------------------------------------------------------
  --  Build_Curve generates the Num_Steps segments of a spline
   procedure Build_Curve (CP0, CP1, CP2, CP3 : Singles.Vector3;
                          Num_Steps          : Int;
                          Curve_Coords       : out Singles.Vector3_Array) is
      Step        : constant Single := 1.0 / Single (Num_Steps);
      Num_Points  : constant Int := Num_Steps + 1;
      T           : Single := Step;
      Coord_Index : Int := 1;
   begin
      Curve_Coords (Coord_Index) := CP0;    --  Start of spline
      while Coord_Index <= Num_Steps loop   --  Build spline
         Coord_Index := Coord_Index + 1;
         Curve_Coords (Coord_Index) := Blend_Vectors (CP0, CP1, CP2, CP3, T);
         T := T + Step;
      end loop;
      Curve_Coords (Num_Points) := CP3;

   exception
      when  others =>
         Put_Line ("An exception occurred in Surface_Patch.Build_Curve.");
         raise;
   end Build_Curve;

   --  --------------------------------------------------------------------------------

   procedure Build_Patch (thePatch : Patch_Data.Patch_Type; Num_Steps : Int;
                          Patch_Array : out Singles.Vector3_Array) is
      CP0, CP1, CP2, CP3 : Singles.Vector3 := (0.0, 0.0, 0.0);
      Step        : constant Single := 1.0 / Single (Num_Steps);
      Num_Points  : constant Int := Num_Steps + 1;
      Index       : Int := 1;
      T           : Single := 0.0;
      Curve       : Singles.Vector3_Array (1 .. Num_Points);
   begin
      for Step_Count in 1 .. Num_Points loop
         --  Splines of constant U
         CP0 := U_Coord (thePatch, 0, T);
         CP1 := U_Coord (thePatch, 1, T);
         CP2 := U_Coord (thePatch, 2, T);
         CP3 := U_Coord (thePatch, 3, T);
         Build_Curve (CP0, CP1, CP2, CP3, Num_Steps, Curve);
         Patch_Array (Index .. Index + Num_Steps) := Curve;
         --  Splines of constant V
         Index := Index + Num_Points;
         CP0 := V_Cord (thePatch, 0, T);
         CP1 := V_Cord (thePatch, 1, T);
         CP2 := V_Cord (thePatch, 2, T);
         CP3 := V_Cord (thePatch, 3, T);
         Build_Curve (CP0, CP1, CP2, CP3, Num_Steps, Curve);
         Patch_Array (Index .. Index + Num_Steps) := Curve;
         Index := Index + Num_Points;
         T := T + Step;
      end loop;

   exception
      when  others =>
         Put_Line ("An exception occurred in Surface_Patch.Build_Patch.");
         raise;
   end Build_Patch;

   --  --------------------------------------------------------------------------------

   procedure Print_Patch (Name     : String;
                          thePatch : Patch_Data.Patch_Type) is
   use GL.Types;
   begin
      Put_Line (Name & ":");
      for Row in thePatch'Range loop
         for Column in thePatch'Range (2) loop
            Put (Int'Image (thePatch (Row, Column)) & "   ");
         end loop;
         New_Line;
      end loop;
      New_Line;
   end Print_Patch;

   --  ------------------------------------------------------------------------

   function U_Coord (Patch : Patch_Data.Patch_Type; Index : Int; T : Single)
                       return Singles.Vector3 is
      use Patch_Data;
   begin
      return Blend_Vectors (Control_Points (Patch (Index, 0)),
                            Control_Points (Patch (Index, 1)),
                            Control_Points (Patch (Index, 2)),
                            Control_Points (Patch (Index, 3)), T);
    end U_Coord;

   --------------------------------------------------------------------------------

   function V_Cord (Patch : Patch_Data.Patch_Type; Index : Int; T : Single)
                    return Singles.Vector3 is
      use Patch_Data;
   begin
      return Blend_Vectors (Control_Points (Patch (0, Index)),
                            Control_Points (Patch (1, Index)),
                            Control_Points (Patch (2, Index)),
                            Control_Points (Patch (3, Index)), T);
    end V_Cord;

   --  --------------------------------------------------------------------------------

end Surface_Patch;
