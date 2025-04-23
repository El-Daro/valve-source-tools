function Get-IniRegex {
	Param ( )

	return @{
		# Captures an empty line. Ignored
		emptyLine = "^\s*`$";	# A simple regex that matches an empty line

		# Captures a single-line comment
		comment = "(?mnx:				# Multi-line, no implicit captures, exclude whitespaces and allow comments like this one
		^[\t ]*(?<comment>[#;].*))";	# Matches 'empty space', followed by a ';' or '#' symbol and whatever comes after
	
		#region Section pattern
		# Captures a section
		# If no section is captured, the section is assumed to be 'Global'
		section = "(?mnx:							# Multi-line, no implicit captures, exclude whitespaces and allow comments like this one
			^[\t ]*\[								# Find '[' symbol that represents the start of a section
			(?<sectionEmpty>[\t ]*(?=\]))?			# Check whether the section is empty and ends with ']' symbol (uncaptured)
			(?(sectionEmpty)						# If it is, skip this whole section
			|										# Otherwise
				[\t ]*(?<section>					# We search for empty space again, since it was disregarded before (see 'sectionEmpty' construct)
					(?<sectionChar>[^\[\]\t\r\n ])?	# Search for a valid character
					(?(sectionChar)[^\t\r\n]*)		# If there is one, capture the rest. All is saved in 'section' construct
				|)									# Otherwise do nothing and move on
			)\]										# The ']' symbol (end of a section) is not captured
			[\t ]*(?<comment>[;|#].*)?)";			# A standard in-line comment match
		#endregion

		#region Key = no value pattern
		# Captures a key with an empty value
		# The key is stored as $none and is later assigned a default value
		invalidValue =  "(?mnx:		# Multi-line, no implicit captures, exclude whitespaces and allow comments like this one
		^[\t ]*							# Skip empty space (if you remove it, comments and sections can be validated as key-value pair. Only do it if you check for comments/sections first)
		(?<key>							# The key group
			(?<keyChar>[^\[\]\t\r\n=#; ])	# First character has to be something other than empty space, section definition, equals sign or a comment ('=', ';', '#', '[', ']')
			(?(keyChar)[^\t\r\n=#;]*	# If said character was found, capture the rest (whitespaces are allowed, tabs are not)
			|(?!))						# Otherwise stop the matching and go get some rest
		)								# End of the 'key' capture
		[\t ]*=[\t ]*					# Match '=' symbol, surrounded by empty spaces (which is, perhaps, unneeded, since it amounts to a lot of permutations and said whitespaces can easily be trimmed)
		(?<emptyString>''|`"`")?# Match an empty string enclosed in single- or double-quotes, if present
		[\t ]*					# Empty space
		(?<comment>[;|#].*)?$)"; # A comment is optional, but always stored if it's there
		#endregion

		#region Key-Value assessment pattern
		# Captures a seemingly valid key-value pair only to asses
		# whether it starts with one of the quote characters: ' or "
		keyValue = "(?mnx:		# Multi-line, no implicit captures, exclude whitespaces and allow comments like this one
		^[\t ]*							# Skip empty space (if you remove it, comments and sections can be validated as key-value pair. Only do it if you check for comments/sections first)
		(?<key>							# The key group
			(?<keyChar>[^\[\]\t\r\n=#; ])	# First character has to be something other than empty space, section definition, equals sign or a comment ('=', ';', '#', '[', ']')
			(?(keyChar)[^\t\r\n=#;]*	# If said character was found, capture the rest (whitespaces are allowed, tabs are not)
			|(?!))						# Otherwise stop the matching and go get some rest
		)								# End of the 'key' capture
		[\t ]*=[\t ]*					# Match '=' symbol, surrounded by empty spaces (which is, perhaps, unneeded, since it amounts to a lot of permutations and said whitespaces can easily be trimmed)
		(?<value>						# Captures everything after the '=' symbol to process it later
			(?<quoteCharacter>['`"])?.*	# Find a quote char and capture it, if it is present
		)`$)";
		#endregion

		#region Value patterns hashtable
		# Value hashtable
		value = @{
			# This is a string that is definitely NOT enclosed in any quote symbols and that MIGHT contain a comment
			unquoted = "(?mnx:(?<value>[^\t\r\n;#]+)[\t ]*(?<comment>[;|#].*)?)";

			# This is a string that is definitely NOT enclosed in any quote symbols and that does NOT contain a comment
			# Very similar to 'unquoted'. Only used for a faster search
			unquotedNoComments = "(?mnx:(?<value>[^\r\n]+)[\t ]*)";

			# This is a complex string that definitely starts as with a quote symbol, but who knows where it ends
			# Issue: Doesn't capture a comment, if it goes directly after the quote with no spaces.
			# This is a tradeoff, otherwise more values are broken.
			# Example of the issue: Key = "";comment
			quoted = "(?mnx:
			^(?<value>						# A quoted value group
				(?<valueSingleQuote>['])?	# Include starting quote
				(?(valueSingleQuote)		# Does it start with a single quote?
					[^\t\r\n]+				# Assume the control character is single quote and capture one or more characters here
					[']						# We're unsure, whether there are any more quotes, but include the last one, if it's there
				|							# Otherwise it starts with a double-quote
					[`"]					# Include starting quote
					[^\t\r\n]+				# Capture one or more characters here
					[`"]					# And maybe the last one, if it's there
				)
			)
			(?<commentSpace>[\t ]*(?=[;#]))?# See whether we have an empty space, followed (but not captured) by a comment symbol
			(?<comment>
				(?(commentSpace)		# If it's there
					[;#].*				# Capture the comment
				)
			)?)";

			# This is a string that MIGHT represent an in-line comment. Only use it where needed
			commentPattern = "(?mnx:
			[\t ]*				# Possible empty space
			[\t]+				# Followed by at least one TAB character
			[\t ]*				# Followed by possible empty space
			[;#])" 				# And ending with a comment character 
		};
		#endregion
	}
}