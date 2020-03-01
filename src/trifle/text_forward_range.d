module trifle.text_forward_range;

import trifle.location: LocationConfig, IndentStyle;
import trifle.parse_utils: isStartCodeUnit, frontUnitLength;

import std.traits: isSomeString, Unqual;

struct TextForwardRange(S, LocationConfig c = LocationConfig.init)
	if( isSomeString!S )
{
	import std.range: ElementEncodingType;

	alias String = S;
	alias Char = Unqual!(ElementEncodingType!S);
	enum LocationConfig config = c;

	alias ThisType = TextForwardRange!(S, c);

	// This range keeps original reference to data internally
	String str;

	// Index of starting position to data this range points to
	size_t index = 0;
	// Index of tail of this range or size_t.max if range ends at end of original data buffer
	size_t endIndex = size_t.max;

	static if( config.withGraphemeIndex )
		size_t graphemeIndex = 0;

	static if( config.withLineIndex )
	{
		size_t lineIndex = 0; // Line index related to original data buffer

		static if( config.withColumnIndex )
			size_t columnIndex = 0;

		static if( config.withGraphemeColumnIndex )
			size_t graphemeColumnIndex = 0;
	}

	// If it set to true means that indents on current line have passed
	private bool isIndenting = true;
	IndentStyle indentStyle; // Tabs or spaces indent style for current line
	size_t indentCount; // Indentation count in number of tabs or spaces


public:
	@disable this(this);

	this( String source )
	{
		str = source;

		analyzeIndents();
	}

	// copy ctor
	this(ref return scope inout(ThisType) rhs) inout
	{
		import std.range: save;

		this.str = rhs.str.save;

		this.index = rhs.index;
		this.endIndex = rhs.endIndex;
		this.isIndenting = rhs.isIndenting;
		this.indentCount = rhs.indentCount;
		this.indentStyle = rhs.indentStyle;

		static if( config.withGraphemeIndex )
			this.graphemeIndex = rhs.graphemeIndex;

		static if( config.withLineIndex )
		{
			this.lineIndex = rhs.lineIndex;

			static if( config.withColumnIndex )
				this.columnIndex = rhs.columnIndex;

			static if( config.withGraphemeColumnIndex )
				this.graphemeColumnIndex = rhs.graphemeColumnIndex;
		}
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

	// Tests if current item is line indentation symbol
	private void analyzeIndents()
	{
		if( index >= this.sliceEndIndex )
			return;

		if( isNewLine )
		{
			indentCount = 0;
			isIndenting = true;
		}

		if( isIndenting )
		{
			if( indentCount == 0 )
			{
				if( str[index] == '\t' )
				{
					indentStyle = IndentStyle.tab;
					++indentCount;
				}
				else if( str[index] == ' ' )
				{
					indentStyle = IndentStyle.space;
					++indentCount;
				}
				else
					isIndenting = false;
			}
			else
			{
				if( str[index] == indentStyle )
					++indentCount;
				else
					isIndenting = false;
			}
		}
	}

	/// Push the range forward by one encoding element
	void popFront()
	{
		index++;

		if( index >= this.sliceEndIndex )
			return;

		analyzeIndents();

		static if( config.withLineIndex )
		{
			if( isNewLine )
			{
				lineIndex++;

				static if( config.withColumnIndex )
					columnIndex = 0;

				static if( config.withGraphemeColumnIndex )
					graphemeColumnIndex = 0;
			}

			static if( config.withColumnIndex )
				columnIndex++;
		}

		import std.traits: Unqual;

		static if( is( Char == char ) || is( Char == wchar ) )
		{
			if( isStartCodeUnit(str[index]) )
			{
				static if( config.withGraphemeIndex )
					graphemeIndex++;

				static if( config.withGraphemeColumnIndex )
					graphemeColumnIndex++;
			}
		}
		else static if( is( Char == dchar ) )
		{
			static if( config.withGraphemeIndex )
				graphemeIndex++;

			static if( config.withGraphemeColumnIndex )
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

	/// Tests if range front currently points to indentation symbol
	@property bool isIndentation() {
		return isIndenting && ( str[index] == '\t' || str[index] == ' ' );
	}

	/// Get current's line indent info without pushing this range forward
	void getLineIndent( ref size_t count, ref IndentStyle style )
	{
		bool isInd = this.isIndentation;

		if( !isInd )
		{
			count = indentCount;
			style = indentStyle;
			return;
		}

		auto tmp = this.save;
		isInd = tmp.isIndentation;

		while( isInd && !tmp.empty )
		{
			tmp.popFront();
			isInd = tmp.isIndentation;
		}

		count = tmp.indentCount;
		style = tmp.indentStyle;

		return;
	}

	/// Parses current's line indent with pushing the range forward
	void parseLineIndent( ref size_t count, ref IndentStyle style )
	{
		while( isIndentation && !this.empty )
			this.popFront();

		count = indentCount;
		style = indentStyle;
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

	bool matchWord(String input)
	{
		import std.uni: isAlpha;
		import std.algorithm: equal;

		import trifle.parse_utils: decodeFront;

		size_t inpIndex = 0;

		auto thisSlice = this.save; //Creating temporary slice of this range

		if( input.length > thisSlice.length || input.length == 0 || thisSlice.empty )
			return false;

		Char thisChar = thisSlice.front;
		dchar thisDChar;
		ubyte codeUnitLen;

		//Match if we have input starting with
		if( !isStartCodeUnit(input[0]) || !isStartCodeUnit(thisChar) )
			return false;

		while( !thisSlice.empty )
		{
			thisDChar = thisSlice.decodeFront();

			codeUnitLen = frontUnitLength(thisSlice);

			if( isAlpha(thisDChar) )
			{
				if( inpIndex + codeUnitLen > input.length )
					return false;

				if( !equal( thisSlice[0 .. codeUnitLen], input[inpIndex .. inpIndex + codeUnitLen] ) )
					return false;
			}
			else
				break;

			inpIndex += codeUnitLen;
			thisSlice.popFrontN(codeUnitLen);
		}

		if( thisSlice.empty || ( !isAlpha(thisDChar) && ( inpIndex + codeUnitLen > input.length ) ) )
		{
			this = thisSlice.save;
			return true;
		}
		else
			return false;
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

template GetSourceRangeConfig(R)
{
	static if( is( typeof(R.config) == LocationConfig ) )
	{
		enum GetSourceRangeConfig = R.config;
	}
	else
	{
		enum GetSourceRangeConfig = ( () {
			LocationConfig c;

			return c;
		} )();
	}
}