// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function(){
 $("#hover_mu").hover(
   function () {
     $('ul#mu_menu_dash').show();
     },
   function () {
     $('ul#mu_menu_dash').hide();
     }
   );
 });
