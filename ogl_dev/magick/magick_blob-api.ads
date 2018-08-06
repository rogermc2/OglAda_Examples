
with System;

with Interfaces.C;

with Blob_Reference;

package Magick_Blob.API is

   -- File_To_Image and Image_To_Blob moved to Magick_Image.API to avoid circularities

   package Class_Blob is

      type Blob is tagged limited record
             Blob_Ref : access Blob_Reference.Class_Blob_Ref.Blob_Ref;
--           Blob_Ref : System.Address;  -- /usr/local/Cellar/imagemagick/7.0.7-31/include/ImageMagick-7/Magick++/Blob.h:75
      end record;
      pragma Import (CPP, Blob);

      function New_Blob return Blob;  -- /usr/local/Cellar/imagemagick/7.0.7-31/include/ImageMagick-7/Magick++/Blob.h:31
      pragma Cpp_Constructor (New_Blob, "_ZN6Magick4BlobC1Ev");

      procedure Delete_Blob (this : access Blob);  -- /usr/local/Cellar/imagemagick/7.0.7-31/include/ImageMagick-7/Magick++/Blob.h:40
      pragma Import (CPP, Delete_Blob, "_ZN6Magick4BlobD1Ev");

      function Data (this : access constant Blob'Class) return System.Address;  -- /usr/local/Cellar/imagemagick/7.0.7-31/include/ImageMagick-7/Magick++/Blob.h:55
      pragma Import (CPP, Data, "_ZNK6Magick4Blob4dataEv");

      function Length (this : access constant Blob'Class) return Interfaces.C.size_t;  -- /usr/local/Cellar/imagemagick/7.0.7-31/include/ImageMagick-7/Magick++/Blob.h:58
      pragma Import (CPP, Length, "_ZNK6Magick4Blob6lengthEv");

   end Class_Blob;

end Magick_Blob.API;
