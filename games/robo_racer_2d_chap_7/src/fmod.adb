
with Interfaces.C;

--  with System.Address_Image;

with Ada.Text_IO; use Ada.Text_IO;

with Fmod.API;

package body Fmod is

    Audio_Handle : Fmod_Common.Fmod_System_Handle := null;
    pragma Convention (C, Audio_Handle);

    --     procedure Print_Channel_Handle (Msg : String; n : Fmod_Common.Fmod_Channel_Handle);
    --     procedure Print_Handle (Msg : String; n : Fmod_Common.Fmod_System_Handle);
    --     procedure Print_Sound_Handle (Msg : String; n : Fmod_Common.Fmod_Sound_Handle);

    --  -------------------------------------------------------------------------

    function Close_System return Fmod_Result is
    begin
        return Fmod.API.System_Close (Audio_Handle);
    end Close_System;

    --  -------------------------------------------------------------------------

    procedure Create_Sound (name_or_data : String; mode : Fmod_Mode;
                            exinfo       : Fmod_Create_Sound_Exinfo_Ptr;
                            sound        : out Fmod_Sound_Handle) is
        Result : constant Fmod_Result := Fmod.API.Create_Sound
          (Audio_Handle.all, Interfaces.C.To_C (name_or_data), mode,
           exinfo, sound);
    begin
        if Result /= Fmod_Ok then
            raise Fmod_Exception with
              "Fmod.Create_Sound could not create " & name_or_data &
              " due to error " & Fmod_Result'Image (Result);
        end if;
    end Create_Sound;

    --  -------------------------------------------------------------------------

    function Create_System return Fmod_Result is
        Result : constant Fmod_Result := Fmod.API.System_Create (Audio_Handle);
    begin
        return Result;
    end Create_System;

    --  -------------------------------------------------------------------------

    function Create_And_Initialize_System
      (maxchannels     : Int; flags : Fmod_Init_Flags;
       extradriverdata : System.Address) return Fmod_Result is
        Result : Fmod_Result := Fmod.API.System_Create (Audio_Handle);
    begin
        if Result = Fmod_Ok then
            Result := Init_System (maxchannels, flags, extradriverdata);
            if Result /= Fmod_Ok then
                raise Fmod_Exception with
                  "Fmod.Init_System audio system initialization failed"
                  & " with failure code " & Fmod_Result'Image (Result);
            end if;
        else
            raise Fmod_Exception with
              "Fmod.Init_System audio system creation failed"
              & " with failure code " & Fmod_Result'Image (Result);
        end if;
        return Result;
    end Create_And_Initialize_System;

    --  -------------------------------------------------------------------------
    --  Get_Open_State parameters
    --  openstate: address of a variable that receives the open state of a sound.
    --  Optional. Specify 0 or NULL to ignore.
    --  percentbuffered: address of a variable that receives the percentage of the
    --  file buffer filled progress of a stream.
    --  Optional. Specify 0 or NULL to ignore.
    --  starving: address of a variable that receives the starving state of a sound.
    --  If a stream has decoded more than the stream file buffer has ready for it,
    --  it will return TRUE.
    --  Optional. Specify 0 or NULL to ignore.
    --  diskbusy: address of a variable that receives the disk busy state of a sound.
    --  That is, whether or not the disk is currently being accessed for the sound.
    --  Get_Open_State determines if a sound has finished loading / opening or not.
    --  While it is loading (not ready), sound functions are not accessible for
    --  that sound.
    function Get_Open_State (sound              : Fmod_Sound_Handle;
                             openstate          : out Fmod_Open_State;
                             percentbuffered    : out UInt;
                             starving, diskbusy : out Boolean)
                             return Fmod_Result is
        use Interfaces.C;
        State         : aliased Fmod_Open_State;
        Openstate_Ptr : constant access Fmod_Open_State := State'Access;
        PB            : aliased unsigned;
        PB_Ptr        : constant access unsigned := PB'Access;
        Starve        : aliased Fmod_Bool;
        Starving_Ptr  : constant access Fmod_Bool := Starve'Access;
        Disk_Busy     : aliased Fmod_Bool;
        Disk_Busy_Ptr : constant access Fmod_Bool := Disk_Busy'Access;
        Result        : constant Fmod_Result
          := Fmod.API.Get_Open_State (sound, Openstate_Ptr, PB_Ptr,
                                      Starving_Ptr, Disk_Busy_Ptr);
    begin
        if sound /= null then
            if Result = Fmod_Ok then
                openstate := State;
                percentbuffered := UInt (PB);
                starving := Starve /= 0;
                diskbusy := Disk_Busy /= 0;
            else
                Put_Line ("Fmod.Get_Open_State failed with " &
                            Fmod_Result'Image (Result));
            end if;
        else
            Put_Line ("Fmod.Get_Open_State called with null Sound_Ptr.");
        end if;

        return Result;
    end Get_Open_State;

    --  ------------------------------------------------------------------------

    function Init_System (maxchannels     : Int; flags : Fmod_Init_Flags;
                          extradriverdata : System.Address) return Fmod_Result is
    begin
        return Fmod.API.System_Init
          (Audio_Handle.all, Interfaces.C.int (maxchannels), flags,
           extradriverdata);
    end Init_System;

    --  -------------------------------------------------------------------------

    procedure Pause_Channel (Channel : Fmod_Channel_Handle; Pause : Boolean) is
        F_Pause  : Fmod_Bool := 0;
        Result   : Fmod_Result;
    begin
        if Pause then
            F_Pause := 1;
        end if;
        Result := Fmod.API.Set_Paused (Channel, F_Pause);
        if Result /= Fmod_Ok then
            raise Fmod_Exception with
              "Fmod.Pause_Channel failed with failure code " &
              Fmod_Result'Image (Result);
        end if;
    end Pause_Channel;

    --  -------------------------------------------------------------------------

    procedure Play_Sound (sound        : Fmod_Sound_Handle;
                          channelgroup : Fmod_Channelgroup_Ptr;
                          paused       : Boolean;
                          channel : out Fmod_Channel_Handle) is
        Pause  : Fmod_Bool := 0;
        Result : Fmod_Result;
    begin
        if paused then
            Pause := 1;
        end if;
        Result := Fmod.API.Play_Sound (Audio_Handle, sound,
                                       channelgroup, Pause, channel);
        if Result /= Fmod_Ok then
            Fmod.Print_Open_State ("Fmod.Play_Sound play sound Open_State",
                                   sound);
            raise Fmod_Exception with
              "Fmod.Play_Sound failed with failure code " &
              Fmod_Result'Image (Result);
        end if;
    end Play_Sound;

    --  -------------------------------------------------------------------------

    --     procedure Print_Channel_Handle (Msg : String; n : Fmod_Common.Fmod_Channel_Handle) is
    --     begin
    --
    --        if n /= null then
    --           Put_Line (Msg & " Channel handle at address " & System.Address_Image (n.all'address));
    --           --        Put_Line (Msg & " Channel pointer at address " & System.Address_Image (n_ptr.all'address));
    --        else
    --           Put_Line (Msg & " channel handle is null");
    --        end if;
    --           New_Line;
    --        end Print_Channel_Handle;

    --  -------------------------------------------------------------------------

    --        procedure Print_Handle (Msg : String; n : Fmod_Common.Fmod_System_Handle) is
    --           n_ptr : constant Fmod_Common.Fmod_System_Ptr := n.all;
    --        begin
    --           Put_Line (Msg & " System handle at address " & System.Address_Image (n.all'address));
    --           Put_Line (Msg & " System pointer at address " & System.Address_Image (n_ptr.all'address));
    --           New_Line;
    --        end Print_Handle;

    --  -------------------------------------------------------------------------

    procedure Print_Open_State (Message : String;
                                Sound   : Fmod_Common.Fmod_Sound_Handle) is
        Open_State       : Fmod_Open_State := Fmod_Openstate_Null;
        Percent_Buffered : UInt;
        Starving         : Boolean;
        Disk_Busy        : Boolean;
        Result           : constant Fmod_Result :=
                             Get_Open_State (Sound, Open_State, Percent_Buffered,
                                             Starving, Disk_Busy);
    begin
        New_Line;
        Put_Line (Message & " Open State Status:");
        if Result = Fmod_Ok then
            Put_Line ("   Open State: " & Fmod_Open_State'Image (Open_State));
            if Open_State /= Fmod_Openstate_Null then
                Put_Line ("   Percent Buffered: " & UInt'Image (Percent_Buffered));
                Put_Line ("   Starving: " & Boolean'Image (Starving));
                Put_Line ("   Disk Busy: " & Boolean'Image (Disk_Busy));
            end if;
        else
            Put_Line ("Fmod Result: " & Fmod_Result'Image (Result));
        end if;
        New_Line;
    end Print_Open_State;

    --  -------------------------------------------------------------------------

    --        procedure Print_Sound_Handle (Msg : String; n : Fmod_Common.Fmod_Sound_Handle) is
    --           n_ptr : constant Fmod_Common.Fmod_Sound_Ptr := n.all;
    --        begin
    --           Put_Line (Msg & " Sound handle at address " & System.Address_Image (n.all'address));
    --           Put_Line (Msg & " Sound pointer at address " & System.Address_Image (n_ptr.all'address));
    --           New_Line;
    --        end Print_Sound_Handle;

    --  -------------------------------------------------------------------------

    procedure Release_Channel_Group (Group : Fmod_Channelgroup_Handle) is
        Result  : constant Fmod_Result :=
                    Fmod.API.Release_Channel_Group (Group);
    begin
        if Result /= Fmod_Ok then
            Put_Line ("Fmod.Release_Channel_Group failed with failure code " &
                        Fmod_Result'Image (Result));
        end if;
    end Release_Channel_Group;

    --  -------------------------------------------------------------------------

    procedure Release_Sound (Sound : Fmod_Sound_Handle) is
        Result  : constant Fmod_Result := Fmod.API.Release_Sound (Sound);
    begin
        if Result /= Fmod_Ok then
            Put_Line ("Fmod.Release_Sound failed with failure code " &
                        Fmod_Result'Image (Result));
        end if;
    end Release_Sound;

    --  -------------------------------------------------------------------------

    procedure Release_System is
        Result  : constant Fmod_Result := Fmod.API.Release_System (Audio_Handle);
    begin
        if Result /= Fmod_Ok then
            Put_Line ("Fmod.Release_System failed with failure code " &
                        Fmod_Result'Image (Result));
        end if;
    end Release_System;

    --  -------------------------------------------------------------------------

    end Fmod;
