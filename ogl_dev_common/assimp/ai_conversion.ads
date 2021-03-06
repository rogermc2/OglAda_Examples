
with Interfaces.C;

with Material;

package AI_Conversion is

   Conversion_Exception : Exception;

   function To_AI_Materials_Map (Num_Materials    : Interfaces.C.unsigned := 0;
                                 C_Material_Array : Material.API_Material_Ptr_Array)
                                 return Material.AI_Material_Map;
end AI_Conversion;
