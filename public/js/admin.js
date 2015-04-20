function toggle_spoiler(spoiler_id) {
  var element = document.getElementById(spoiler_id);
  
  if (element.style.display == "none") {
    element.style.display = "";
  } else {
    element.style.display = "none";
  }
}