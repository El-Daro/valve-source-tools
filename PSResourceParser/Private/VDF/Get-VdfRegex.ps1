function Get-VdfRegex {
	Param ()

	return @{
		# Captures an empty line. Ignored
		emptyLine = "^\s*`$";			# A simple regex that matches an empty line

		# Captures a single-line comment	| Might really be unneeded
		comment = "(?mnx:				# Multi-line, no implicit captures, exclude whitespaces and allow comments like this one
		^[\t ]*(?<comment>\\\\.*))";	# Matches 'empty space', followed by a '\\' comment symbols and whatever comes after

		# This regex captures a key enclosed in double quotes and maybe a value
		# If a value is not captured, the next line expected to be an opening curly bracket: '{'
		# Otherwise the structure is broken and we call it off
		# Note: Simplified 'value' capture group. Now it captures any character instead of [^"] (double-quote should be escaped) 
		keyValue = "(?mnx:
		^[\s]*					# Skip empty space
		[`"]					# Verify the quote character
		(?<key>[^\t\r\n\\`" ]+)	# 'Key' is anything enclosed in double quotes. Whitespaces are not allowed. '\' is a comment character
		[`"][\s]*				# Match closing quote char, empty spaces
		(?<valueQuoted>[`"]		# This is a group that might or might not occur in the file
			(?<value>.*)		# Values can actually occupy a few lines, so everything is allowed, ~~as long as it is not a quote char~~
		[`"])?					# A value is optional. If it is not present, the next line is expected to be just a curly bracket: '{'
		[\s]*`$					# The empty space in the end might really be unnecessary to match
		)";

		# An open bracket
		bracketOpen = "[{]";

		# A close bracket
		bracketClose = "[}]"
	}
}