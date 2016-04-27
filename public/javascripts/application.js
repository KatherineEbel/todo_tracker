$(document).ready(function() {
  $("form.delete").submit(function(event) {
      event.preventDefault();
      event.stopPropagation();
      if (confirm("Are you sure you want to delete this item?")) {
        this.submit();
      }
  });
});
