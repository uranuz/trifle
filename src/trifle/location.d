module trifle.location;

struct Location
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

	string toString()
	{
		import std.conv: text;

		return fileName ~ `:` ~ lineIndex.text ~ `:` ~ graphemeColumnIndex.text;
	}
}