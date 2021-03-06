module trifle.text_forward_range;

import trifle.parse_utils: isStartCodeUnit, frontUnitLength;

import std.traits: isSomeString, Unqual;

struct TextForwardRange(S)
	if( isSomeString!S )
{
	import std.range: ElementEncodingType;

	alias String = S;
	alias Char = Unqual!(ElementEncodingType!S);

	alias ThisType = TextForwardRange!(S);

	// This range keeps original reference to data internally
	String str;

	// Index of starting position to data this range points to
	size_t index = 0;
	// Index of tail of this range or size_t.max if range ends at end of original data buffer
	size_t endIndex = size_t.max;

	size_t graphemeIndex = 0;

	// Line index related to original data buffer
	size_t lineIndex = 0; 

	size_t columnIndex = 0;

	size_t graphemeColumnIndex = 0;


public:
	@disable this(this);

	this( String source )
	{
		str = source;
	}

	// copy ctor
	this(ref return scope inout(ThisType) rhs) inout
	{
		import std.range: save;

		this.str = rhs.str.save;

		this.index = rhs.index;
		this.endIndex = rhs.endIndex;

		this.graphemeIndex = rhs.graphemeIndex;
		this.lineIndex = rhs.lineIndex;
		this.columnIndex = rhs.columnIndex;
		this.graphemeColumnIndex = rhs.graphemeColumnIndex;
	}

	/// Test if current range is empty or fully consumed
	bool empty() @property inout {
		return index >= this.sliceEndIndex;
	}

	// Ending position of range in original data
	private size_t sliceEndIndex() @property inout
	{
		import std.algorithm: min;

		return min( str.length, endIndex );
	}

	/// Count of remaining symbols in range
	size_t length() @property inout {
		return this.sliceEndIndex - index;
	}

	/// Return current char and push the range forward
	Char popChar()
	{
		Char ch = front();
		popFront();
		return ch;
	}

	/// Push the range forward by one encoding element
	void popFront()
	{
		index++;

		if( index >= this.sliceEndIndex )
			return;

		if( isNewLine )
		{
			lineIndex++;
			columnIndex = 0;
			graphemeColumnIndex = 0;
		}

		columnIndex++;

		import std.traits: Unqual;

		static if( is( Char == char ) || is( Char == wchar ) )
		{
			if( isStartCodeUnit(str[index]) )
			{
				graphemeIndex++;
				graphemeColumnIndex++;
			}
		}
		else static if( is( Char == dchar ) )
		{
			graphemeIndex++;
			graphemeColumnIndex++;
		}
		else
			static assert( false, "Code unit type '" ~ Char.stringof ~ "' is not valid!" );
	}

	/// Push the range forward by N encoding elements
	void popFrontN(size_t N)
	{
		foreach(i; 0..N)
			popFront();
	}

	/// Get current encoding element
	Char front() @property inout {
		return index >= this.sliceEndIndex ? '\0' : str[index];
	}

	/// Tests if current encoding element goes immediatly after new line chars or when it's start of buffer
	@property bool isNewLine() {
		return index == 0 || str[index-1] == '\n' || ( str[index-1] == '\r' && str[index] != '\n' );
	}

	bool match(String input)
	{
		import std.algorithm: equal;

		if( input.length > this.length )
			return false;

		if( !equal( this[0 .. input.length], input ) )
			return false;

		foreach( i; 0..input.length )
			popFront();

		return true;
	}

	auto opSlice() const {
		return this.save;
	}

	alias opDollar = length;

	auto opSlice(size_t start, size_t end) const
	{
		import std.conv: text;
		import std.exception: enforce;

		size_t newEndIndex = this.index + end;

		enforce(
			start <= str.length,
			"Slice start index: " ~ start.text ~ " out of bounds: [0, " ~ str.length.text ~ ")");
		enforce(
			newEndIndex <= str.length,
			"Slice end index: " ~ newEndIndex.text ~ " out of bounds: [0, " ~ str.length.text ~ ")");
		auto thisSlice = this.save;

		thisSlice.popFrontN(start); //Call this in order to get valid lineIndex, graphemeIndex, etc.
		thisSlice.endIndex = newEndIndex; //Calculating end index for slice

		return thisSlice;
	}

	auto save() @property inout {
		return ThisType(this);
	}

	string toString() inout {
		return str[index .. this.sliceEndIndex];
	}
}
