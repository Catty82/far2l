#!/bin/bash
# This script used by Viewer to produce F5-toggled 'Processed view' content.
# It gets input file as 1st argument, tries to analyze what is it and should
# write any filetype-specific information into output file, given in 2nd argument.
# Input: $1
# Output: $2

FILE="$(file "$1")"

# Optional per-user script
if [ -x ~/.config/far2l/view.sh ]; then
. ~/.config/far2l/view.sh
fi

echo "$FILE" > "$2"
echo >> "$2"

if [[ "$FILE" == *" archive data, "* ]] \
		|| [[ "$FILE" == *" compressed data"* ]] \
		|| [[ "$FILE" == *": Debian "*" package"* ]] \
		|| [[ "$FILE" == *": RPM"* ]]; then
	if command -v exiftool >/dev/null 2>&1; then
		exiftool "$1" | head -n 40 | head -c 1024 >>"$2" 2>&1
		echo "" >>"$2" 2>&1
	else
		echo "Install <exiftool> to see information" >>"$2" 2>&1
	fi
	echo "------------" >>"$2" 2>&1
	echo "Processing file as archive with 7z contents listing" >>"$2" 2>&1
	echo "----bof----" >>"$2" 2>&1
	if command -v 7z >/dev/null 2>&1; then
		7z l "$1" >>"$2" 2>&1
	else
		echo "Install <p7zip-full> to see information" >>"$2" 2>&1
	fi
	if [[ "$FILE" == *" compressed data"* ]]; then
		echo "------------" >>"$2" 2>&1
		echo "Processing file as archive with tar contents listing" >>"$2" 2>&1
		TAROPTS=""
		if [[ "$FILE" == *": gzip compressed data"* ]]; then
			TAROPTS=-z
		fi
		if [[ "$FILE" == *": bzip2 compressed data"* ]]; then
			TAROPTS=-j
		fi
		if [[ "$FILE" == *": XZ compressed data"* ]]; then
			TAROPTS=-J
		fi
		if [[ "$FILE" == *": lzma compressed data"* ]]; then
			TAROPTS=--lzma
		fi
		if [[ "$FILE" == *": lzop compressed data"* ]]; then
			TAROPTS=--lzop
		fi
		if [[ "$FILE" == *": zstd compressed data"* ]]; then
			TAROPTS=--zstd
		fi
		if [[ "$(tar --help | grep -e '--full-time' | wc -l)" == "1" ]]; then
			TAROPTS=$TAROPTS" --full-time"
		fi
		echo "TAROPTS=[ "$TAROPTS" ]" >>"$2" 2>&1
		echo "------------" >>"$2" 2>&1		
		ELEMENTCOUNT=$( tar -tv $TAROPTS -f "$1" 2>/dev/null | wc -l )
		echo "tar archive elements count = "$ELEMENTCOUNT >>"$2" 2>&1
		if [[ $ELEMENTCOUNT -gt 0 ]]; then
			echo "------------" >>"$2" 2>&1
			tar -tv $TAROPTS -f "$1" >>"$2" 2>&1
			echo "------------" >>"$2" 2>&1
			tar -tv $TAROPTS -f "$1" | \
				tee >/dev/null \
				>( CTOTAL=$( wc -l ) ; ( echo $CTOTAL' total' ; echo "----done----" ; ) >>"$2" 2>&1 ) \
				>( CFOLDERS=$( grep -e '^d' | wc -l ) ; ( echo $CFOLDERS' folders' ) >>"$2" 2>&1 ) \
				>( CFILES=$( grep -v -e '^d' | wc -l ) ; ( echo $CFILES' files' ) >>"$2" 2>&1 )
		fi
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *ELF*executable* ]] || [[ "$FILE" == *ELF*object* ]]; then
	if command -v exiftool >/dev/null 2>&1; then
		exiftool "$1" | head -n 40 | head -c 1024 >>"$2" 2>&1
		echo "" >>"$2" 2>&1
	else
		echo "Install <exiftool> to see information" >>"$2" 2>&1
	fi
	echo "------------" >>"$2" 2>&1
	if command -v readelf >/dev/null 2>&1; then
		readelf -n --version-info --dyn-syms "$1" >>"$2" 2>&1
	else
		echo "Install <readelf> utility to see more information" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *" image data, "* ]] \
	|| [[ "$FILE" == *"JPEG image"* ]]; then
	# ??? workaround for bash to get values of variables
	bash -c "echo ${FOO}" >/dev/null 2>&1
	TCOLUMNS=$( bash -c "echo ${COLUMNS}" )
	TLINES=$( bash -c "echo ${LINES}" )
	TCOLUMNS=$(( ${TCOLUMNS:-80} - 0 ))
	TLINES=$(( ${TLINES:-25} - 2 ))
	VCHAFA="no"
	if command -v chafa >/dev/null 2>&1; then
		VCHAFA="yes"
		# chafa -c 16 --color-space=din99d --dither=ordered -w 9 --symbols all --fill all !.! && read -n1 -r -p "$1" >>"$2" 2>&1
		chafa -c none --symbols -all+stipple+braille+ascii+space+extra --size ${TCOLUMNS}x${TLINES} "$1" >>"$2" 2>&1
		echo "Image is viewed by chafa in "${TCOLUMNS}"x"${TLINES}" symbols sized area" >>"$2" 2>&1
		chafa -c 16 --color-space=din99d -w 9 --symbols all --fill all "$1" && read -n1 -r -p "" >>"$2" 2>&1
		clear
	else
		echo "Install <chafa> to see picture" >>"$2" 2>&1
	fi
	VJP2A="no"
	if [[ "$FILE" == *"JPEG image"* ]] \
		&& [[ "$VCHAFA" == "no" ]]; then
		if command -v jp2a >/dev/null 2>&1; then
			VJP2A="yes"
			# jp2a --colors "$1" >>"$2" 2>&1
			# jp2a --size=${TCOLUMNS}x${TLINES} "$1" >>"$2" 2>&1
			# jp2a --height=${TLINES} "$1" >>"$2" 2>&1
			TCOLUMNS=$(( ${TCOLUMNS:-80} - 1 ))
			jp2a --width=${TCOLUMNS} "$1" >>"$2" 2>&1
			echo "Image is viewed by jp2a in "${TCOLUMNS}"x"${TLINES}" symbols sized area" >>"$2" 2>&1
			jp2a --colors --term-fit "$1" && read -n1 -r -p "" >>"$2" 2>&1
			clear
		else
			echo "Install <jp2a> to see colored picture" >>"$2" 2>&1
		fi
	fi
	VASCIIART="no"
	if [[ "$VCHAFA" == "no" ]] \
		&& [[ "$VJP2A" == "no" ]]; then
		if command -v asciiart >/dev/null 2>&1; then
			VASCIIART="yes"
			# asciiart -c "$1" >>"$2" 2>&1
			asciiart "$1" >>"$2" 2>&1
			echo "Image is viewed by asciiart in "${TCOLUMNS}"x"${TLINES}" symbols sized area" >>"$2" 2>&1
			asciiart --color "$1" && read -n1 -r -p "" >>"$2" 2>&1
			clear
		else
			echo "Install <asciiart> to see picture" >>"$2" 2>&1
		fi
	fi
	echo "------------" >>"$2" 2>&1
	if command -v exiftool >/dev/null 2>&1; then
		exiftool "$1" | head -n 40 | head -c 1024 >>"$2" 2>&1
		echo "" >>"$2" 2>&1
	else
		echo "Install <exiftool> to see information" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": Audio file"* ]]; then
	if command -v exiftool >/dev/null 2>&1; then
		exiftool "$1" >>"$2" 2>&1
	else
		echo "Install <exiftool> to see information" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": RIFF"*" data"* ]]; then
	if command -v exiftool >/dev/null 2>&1; then
		exiftool "$1" >>"$2" 2>&1
	else
		echo "Install <exiftool> to see information" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": BitTorrent file"* ]]; then
	if command -v exiftool >/dev/null 2>&1; then
		exiftool "$1" >>"$2" 2>&1
	else
		echo "Install <exiftool> to see information" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": HTML document"* ]]; then
	if command -v exiftool >/dev/null 2>&1; then
		exiftool "$1" | head -n 40 | head -c 1024 >>"$2" 2>&1
		echo "" >>"$2" 2>&1
	else
		echo "Install <exiftool> to see information" >>"$2" 2>&1
	fi
	echo "------------" >>"$2" 2>&1
	echo "Processing file as html with pandoc ( formatted as markdown )" >>"$2" 2>&1
	echo "----bof----" >>"$2" 2>&1
	if command -v pandoc >/dev/null 2>&1; then
		pandoc -f html -t markdown "$1" >>"$2" 2>&1
	else
		echo "Install <pandoc> to see document" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": OpenDocument Text"* ]]; then
	if command -v pandoc >/dev/null 2>&1; then
		pandoc -f odt -t markdown "$1" >>"$2" 2>&1
	else
		echo "Install <pandoc> to see document" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": EPUB document"* ]]; then
	if command -v pandoc >/dev/null 2>&1; then
		pandoc -f epub -t markdown "$1" >>"$2" 2>&1
	else
		echo "Install <pandoc> to see document" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

# if [[ "$FILE" == *" FictionBook2 ebook"* ]]; then
if [[ "$FILE" == *": XML 1.0 document, UTF-8 Unicode text, with very long lines"* ]]; then
	if command -v pandoc >/dev/null 2>&1; then
		pandoc -f fb2 -t markdown "$1" >>"$2" 2>&1
	else
		echo "Install <pandoc> to see document" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": Microsoft Word 2007+"* ]]; then
	if command -v pandoc >/dev/null 2>&1; then
		pandoc "$1" >>"$2" 2>&1
	else
		echo "Install <pandoc> to see document" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": Composite Document File"*"Microsoft Office Word"* ]]; then
	if command -v catdoc >/dev/null 2>&1; then
		catdoc "$1" >>"$2" 2>&1
	else
		echo "Install <catdoc> to see document" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": Composite Document File"*"Microsoft PowerPoint"* ]]; then
	if command -v catppt >/dev/null 2>&1; then
		catppt "$1" >>"$2" 2>&1
	else
		echo "Install <catppt> to see document" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": PDF document"* ]]; then
	if command -v pdftotext >/dev/null 2>&1; then
		pdftotext -enc UTF-8 "$1" "$2" 2>>"$2"
	else
		echo "Install <pdftotext> to see document" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": unified diff output"* ]]; then
	if command -v colordiff >/dev/null 2>&1; then
		cat "$1" | colordiff --color=yes >>"$2" 2>&1
	else
		echo "Install <colordiff> to see colored diff" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": "*" source, "*" text"* ]]; then
	if command -v ctags >/dev/null 2>&1; then
		ctags --totals -x -u "$1" >>"$2" 2>&1
	else
		echo "Install <ctags> to see source overview" >>"$2" 2>&1
	fi
	echo "----eof----" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": ASCII text, with very long lines"* ]] \
		|| [[ "$FILE" == *": UTF-8 Unicode text, with very long lines"* ]]; then
	head -c 256 "$1" >>"$2" 2>&1
	echo "" >>"$2" 2>&1
	echo ............  >>"$2" 2>&1
	tail -c 256 "$1" >>"$2" 2>&1
	echo "" >>"$2" 2>&1
	exit 0
fi

if [[ "$FILE" == *": ASCII text"* ]] \
		|| [[ "$FILE" == *": UTF-8 Unicode"* ]]; then
	head "$1" >>"$2" 2>&1
	echo ............  >>"$2" 2>&1
	tail "$1" >>"$2" 2>&1
	exit 0
fi

echo "Hint: use <F5> to switch back to raw file viewer" >>"$2" 2>&1
#exit 1
