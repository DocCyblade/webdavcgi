#!/bin/bash
#set -e
JS="jquery.js jquery-migrate.js jquery-ui.js jquery.fileupload.js jquery.fancybox.js js.cookie.js multidraggable.js noty.wrapper.js noty.js"

CSS="jquery-ui.css jquery.fancybox.css noty.css"

concat() {
	src=$1
	dst=$2
	test -f "$src" && cat "$src" >> "$dst"
	test -f "$src.gz" && zcat "$src" >> "$dst"
}

test -f contrib.js && rm contrib.js
for js in $JS ; do
	concat $js contrib.js
done
if [ "$1" = "-d" ] ; then
	gzip -c < contrib.js >contrib.min.js.gz
else
	bash minify.sh contrib.js
	rm contrib.js
fi

test -f contrib.css && rm contrib.css
for css in $CSS ; do
	concat $css contrib.css
done
if [ "$1" = "-d" ] ; then
	gzip -c < contrib.css >contrib.min.css.gz
else 
	bash minify.sh contrib.css
	rm contrib.css
fi
