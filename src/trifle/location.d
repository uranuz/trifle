module trifle.location;

struct LocationConfig
{
	bool withGraphemeIndex = true;
	bool withLineIndex = true;
	bool withColumnIndex = true;
	bool withGraphemeColumnIndex = true;
	bool withSize = true;
}

enum IndentStyle: char {
	none = 0,
	tab = '\t',
	space = ' '
}

struct Location
{
	string fileName;  // Name of source file
	size_t index;     // Start code unit index or grapheme index (if available)
	size_t length;    // Length of source text in code units or in graphemes (if available)
	size_t indentCount;
	IndentStyle indentStyle;
}

struct PlainLocation
{
	string fileName;
	size_t lineIndex;
	size_t columnIndex;
}

struct ExtendedLocation
{
	string fileName; // File name for this source
	size_t index; // Index of UTF code unit that starts element
	size_t length; // Length of element in code units
	size_t graphemeIndex; // Index of grapheme that starts element
	size_t graphemeLength; // Length of element in graphemes
	size_t lineIndex; // Index of line at which element starts
	size_t lineCount; // Number of lines in element (number of CR LF/ CR / LF exactly)
	size_t columnIndex; // Index of code unit in line that starts element
	size_t graphemeColumnIndex; // Index of grapheme in line that starts element
	size_t indentCount; // Line indent count for element
	IndentStyle indentStyle; // Determines if element indented with tabs or spaces
}

struct CustomizedLocation(LocationConfig c)
{
	enum config = c;

	string fileName;

	size_t index;

	static if( config.withSize )
		size_t length;

	static if( config.withGraphemeIndex )
	{
		size_t graphemeIndex;

		static if( config.withSize )
			size_t graphemeLength;
	}

	static if( config.withLineIndex )
	{
		size_t lineIndex;

		static if( config.withSize )
			size_t lineCount;

		static if( config.withColumnIndex )
			size_t columnIndex;

		static if( config.withGraphemeColumnIndex )
			size_t graphemeColumnIndex;
	}

	size_t indentCount;
	IndentStyle indentStyle;

	Location toLocation() const
	{
		Location loc;
		loc.fileName = fileName;
		loc.index = index;
		loc.indentCount = indentCount;
		loc.indentStyle = indentStyle;

		static if( config.withSize )
			loc.length = length;

		return loc;
	}

	PlainLocation toPlainLocation() const
	{
		PlainLocation loc;
		loc.fileName = fileName;

		static if( config.withLineIndex )
			loc.lineIndex = lineIndex;

		static if( config.withLineIndex && config.withGraphemeColumnIndex )
			loc.columnIndex = graphemeColumnIndex;
		else static if( config.withLineIndex && config.withColumnIndex )
			loc.columnIndex = columnIndex;
		else static if( config.withGraphemeIndex )
			loc.columnIndex = graphemeIndex;
		else
			loc.columnIndex = index;

		return loc;
	}

	ExtendedLocation toExtendedLocation() const
	{
		ExtendedLocation loc;

		loc.fileName = fileName;
		loc.index = index;

		static if( config.withSize )
			loc.length = length;

		static if( config.withGraphemeIndex )
		{
			loc.graphemeIndex = graphemeIndex;

			static if( config.withSize )
				loc.graphemeLength = graphemeLength;
		}

		static if( config.withLineIndex )
		{
			loc.lineIndex = lineIndex;

			static if( config.withSize )
				loc.lineCount = lineCount;

			static if( config.withColumnIndex )
				loc.columnIndex = columnIndex;

			static if( config.withGraphemeColumnIndex )
				loc.graphemeColumnIndex = graphemeColumnIndex;
		}

		loc.indentCount = indentCount;
		loc.indentStyle = indentStyle;

		return loc;
	}

}