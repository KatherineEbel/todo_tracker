$(function() {
  
  $("form.delete").submit(function(event) {
<<<<<<< Updated upstream
    event.preventDefault();
    event.stopPropagation();
    if (confirm("Are you sure you want to delete this item?")) {
      var form = $(this);
      var request =  $.ajax({
        url: form.attr("action"), 
        method: form.attr("method") 
      });
=======
      event.preventDefault();
      event.stopPropagation();
      if (confirm("Are you sure you want to delete this item?")) {
        var form = $(this);
        var request =  $.ajax({
          url: form.attr("action"), 
          method: form.attr("method") 
        });
>>>>>>> Stashed changes
       
      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          form.parent("li").remove();
        } else if (jqXHR.status == 200) {
            document.location = data;
        }
      });

    }
  });
});
