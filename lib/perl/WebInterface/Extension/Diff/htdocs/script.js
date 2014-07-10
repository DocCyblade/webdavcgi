$(document).ready(function() {
	function blockPage() {
		return $("<div></div>").prependTo("body").addClass("overlay");
	}
	$("body").on("fileActionEvent", function(event,data) {
		if (data.obj.hasClass("disabled")) return;
		if (!data.obj.hasClass("diff")) return;
		var block = blockPage();
		$.post(window.location.pathname, {action:'diff', files: data.selected}, function(response) {
				block.remove();
				if (response.error) {
					noty({text: response.error, type: 'error', layout: 'topCenter', timeout: 30000 });
				} else {
					var dialog = $(response.content);
					
					dialog.dialog({modal: true, width: "auto", height: "auto", maxHeight: 800, maxWidth: 1024});
				}
			
		});

	});
});