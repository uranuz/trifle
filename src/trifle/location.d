module trifle.location;

struct Location
{
	string fileName; // File name for this source
	size_t index; // Index of UTF code unit that starts element
	size_t lineIndex; // Index of line at which element starts
	size_t columnIndex; // Index of code unit in line that starts element
	size_t graphemeIndex; // Index of grapheme that starts element
	size_t graphemeColumnIndex; // Index of grapheme in line that starts element

	size_t length; // Length of element in code units
	size_t graphemeLength; // Length of element in graphemes

	string toString() inout
	{
		import std.conv: text;

		return this.fileName ~ ":" ~ this.lineIndex.text ~ ":" ~ this.graphemeColumnIndex.text;
	}
}