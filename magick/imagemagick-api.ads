
with Core_Image;
with Magick_Exception;
with Magick_Type;

package ImageMagick.API is

   function Read_Image (Info : access Core_Image.API_Image_Info;
                        Except : access Magick_Exception.AI_Exception_Info)
                        return Core_Image.API_Image_Ptr;
   pragma Import (C, Read_Image, "ReadImage");

   function Write_Image (Info : access Core_Image.API_Image_Info;
                         theImage : access Core_Image.API_Image;
                         Except : access Magick_Exception.AI_Exception_Info)
                         return Magick_Type.Magick_Boolean_Type;
   pragma Import (C, Write_Image, "WriteImage");

end ImageMagick.API;
