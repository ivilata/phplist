#!/bin/bash
# script to generate the language gettext template.po from the source code
# $1: current phplist.pot file
# $2: mail where to report the diff between the new and old template
#
# The new template is created on the current dir and named "phplist.pot"

reportto=$2
current=$1
set -e

if [ -z "$current" -o ! -f "$current" ]; then
  echo "Usage: $0 <currentfile>"
  exit 1;
fi

[ "$reportto" ] || reportto=root@localhost

[ -d public_html ] || exit 1; ## needs to run from phplist root

function mail_template_diff() {
	# TODO: Check if there is a way to make this even simpler ?
	now=$(date +%Y%m%d%H%M)

	diff phplist-new.pot $current > diff${now} || true
	fgrep '< msgid' diff${now} | sed s/'< msgid'// > diff2${now}

	if [ -s "diff2${now}" ]; then
		exec > /tmp/message$$
		echo These are this weeks changes in the language template file
		echo They will show up in http://translation.phplist.com as untranslated
		echo Please update your translations, thanks
		echo
		cat diff2${now}

		mail -s "phpList language changes" $reportto < /tmp/message$$
	fi

	rm -f diff${now} diff2${now} /tmp/message$$
}

## from http://www.lxg.de/code/playing-with-xgettext
echo '' > messages.po # xgettext needs that file, and we need it empty

## the structure.php file has texts that cannot be found this way.
php scripts/structuredump.php > public_html/databasestructure.php

find public_html -type f -iname "*.php" | xgettext --omit-header --keyword=__ --keyword=_e --keyword=s --keyword=get -j -f -
msgmerge -qN $current messages.po > phplist-new.pot

mail_template_diff

mv -f phplist-new.pot phplist.pot
rm -f messages.po phplist-new.pot public_html/databasestructure.php

