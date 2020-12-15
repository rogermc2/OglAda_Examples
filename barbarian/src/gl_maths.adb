
with Ada.Numerics;

with Maths;

package body GL_Maths is

   function Accel_Expand (X : Single; Initial, Final : Vector2) return Single is
      R    : constant Vector2 := Final - Initial;
      X_N  : Single;
      Y    : Single;
   begin
      if Final = Initial then
            raise Maths_Error with
              "Maths.Accel_Expand received equal Final and Initial values.";
      end if;
      X_N := (X - Initial (GL.X)) / R (GL.X);
      Y := 100.0 * (X_N - 1.0) ** 2;
      return R (GL.Y) * Y + Initial (GL.Y);
   end Accel_Expand;

   --  -----------------------------------------------------------

   function Decel_Bounce (X : Single; Initial, Final : Vector2; Num : Integer)
                          return Single is
      use Maths.Single_Math_Functions;
      use Ada.Numerics;
      R    : constant Vector2 := Final - Initial;
      X_N    : Single;
      Y    : Single;
   begin
      if Final = Initial then
            raise Maths_Error with
              "Maths.Decel_Bounce received equal Final and Initial values.";
      end if;

      X_N := (X - Initial (GL.X)) / R (GL.X);
      Y := (1.0 - X_N) * Abs (Sin (X_N * PI * Single (Num)));
      return R (GL.Y) * Y + Initial (GL.Y);
   end Decel_Bounce;

   --  -----------------------------------------------------------

   function Decel_Elastic (X : Single; Initial, Final : Vector2; Num : Integer)
                          return Single is
      use Maths.Single_Math_Functions;
      use Ada.Numerics;
      R    : constant Vector2 := Final - Initial;
      X_N  : Single;
      Y    : Single;
   begin
      if Final = Initial then
            raise Maths_Error with
              "Maths.Decel_Elastic received equal Final and Initial values.";
      end if;

      X_N := (X - Initial (GL.X)) / R (GL.X);
      Y := (1.0 - X_N) * Sin (X_N * PI * Single (Num));
      return R (GL.Y) * Y + Initial (GL.Y);
   end Decel_Elastic;

   --  -----------------------------------------------------------

   function From_Real_Matrix4 (R_Matrix : Single_Matrix)
                               return Singles.Matrix4 is
      GL_Matrix : Singles.Matrix4;
      use GL;
      R_Row : Integer := 0;
      R_Col : Integer := 0;
   begin
      for row in Index_Homogeneous'Range loop
         R_Row := R_Row + 1;
         R_Col := 0;
         for col in Index_Homogeneous'Range loop
            R_Col := R_Col + 1;
            GL_Matrix (row, col) := R_Matrix (R_Row, R_Col);
         end loop;
      end loop;
      return GL_Matrix;
   end From_Real_Matrix4;

   --  -----------------------------------------------------------

   function From_Real_Vector3 (R_Vec : Single_Vector) return Singles.Vector3 is
      use GL;
   begin
      return (R_Vec (1), R_Vec (2), R_Vec (3));
   end From_Real_Vector3;

   --  -----------------------------------------------------------

   function From_Real_Vector4 (R_Vec : Single_Vector)
                               return Singles.Vector4 is
      GL_Vec : Singles.Vector4;
      use GL;
   begin
         GL_Vec (X) := R_Vec (1);
         GL_Vec (Y) := R_Vec (2);
         GL_Vec (Z) := R_Vec (3);
         GL_Vec (W) := R_Vec (4);
      return GL_Vec;
   end From_Real_Vector4;

   --  -------------------------------------------------------------------------

   function Lerp (Vec_A, Vec_B : Singles.Vector3; T : Single)
                  return Singles.Vector3 is
      use Singles;
   begin
      return Vec_A * T + Vec_B * (1.0 - T);
   end Lerp;

   --  -------------------------------------------------------------------------

   function Quat_From_Axis_Degree (Angle : Maths.Degree; X, Y, Z : Single)
                                   return Maths.Single_Quaternion.Quaternion is
   begin
      return Quat_From_Axis_Radian (Maths.To_Radians (Angle), X, Y, Z);
   end Quat_From_Axis_Degree;

   --  -------------------------------------------------------------------------

   function Quat_From_Axis_Radian (Angle : Maths.Radian; X, Y, Z : Single)
                                   return Maths.Single_Quaternion.Quaternion is
      use GL.Types;
      use Maths;
      use Single_Math_Functions;
      Half_Angle : constant Single := Single (Angle / 2.0);
      Quat : Single_Quaternion.Quaternion;
   begin
      Quat.A := Cos (Half_Angle);
      Quat.B := Sin (Half_Angle) * X;
      Quat.C := Sin (Half_Angle) * Y;
      Quat.D := Sin (Half_Angle) * Z;
      return Quat;
   end Quat_From_Axis_Radian;

   --  -----------------------------------------------------------

   function To_Real_Matrix4 (GL_Matrix : Singles.Matrix4) return Single_Matrix is
      R_Matrix : Single_Matrix (1 .. 4, 1 .. 4);
      use GL;
      R_Row : Integer := 0;
      R_Col : Integer := 0;
   begin
      for row in Index_Homogeneous'Range loop
         R_Row := R_Row + 1;
         R_Col := 0;
         for col in Index_Homogeneous'Range loop
            R_Col := R_Col + 1;
            R_Matrix (R_Row, R_Col) := GL_Matrix (row, col);
         end loop;
      end loop;
      return R_Matrix;
   end To_Real_Matrix4;

   --  -----------------------------------------------------------

   function To_Real_Vector3 (GL_Vec : Singles.Vector3) return Single_Vector is
      use GL;
   begin
      return  (GL_Vec (X), GL_Vec (Y), GL_Vec (Z));
   end To_Real_Vector3;

   --  -----------------------------------------------------------

   function To_Real_Vector4 (GL_Vec : Singles.Vector4) return Single_Vector is
      use GL;
   begin
      return (GL_Vec (X), GL_Vec (Y), GL_Vec (Z), GL_Vec (W));
   end To_Real_Vector4;

   --  -----------------------------------------------------------

end GL_Maths;
