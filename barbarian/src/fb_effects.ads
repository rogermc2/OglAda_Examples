
package FB_Effects is

   type FB_Effect is (FB_Default, FB_Gold_Flash, FB_Red_Flash, FB_Fadein,
                      FB_Fadeout, FB_Screw, FB_Grey, FB_White_Flash,
                      FB_Green_Flash);

   FB_Effects_Exception : Exception;

   procedure Init (Width, Height : Integer);
   procedure Fade_In;
   procedure Fade_Out;
   procedure Set_Feedback_Effect (Effect : FB_Effect);

end FB_Effects;
