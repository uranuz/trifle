module trifle.parse_utils;

enum dchar replacementChar = 0xFFFD;

bool isStartCodeUnit(char ch) {
	return (ch & 0b1100_0000) != 0b1000_0000;
}

bool isStartCodeUnit(wchar ch) {
	return ch < 0xDC00 || ch > 0xDFFF;
}

bool isStartCodeUnit(dchar ch) {
	return true;
}

public import std.range: empty, save;
import std.traits: isSomeString, Unqual;
import std.range: isInputRange, isForwardRange, ElementEncodingType;

@property ref inout(T) front(T)(return scope inout(T)[] a) @safe pure nothrow @nogc
	if( isSomeString!(T[]) )
{
	assert(a.length, "Attempting to fetch the front of an empty array of " ~ T.stringof);
	return a[0];
}

void popFront(T)(scope ref inout(T)[] a) @safe pure nothrow @nogc
	if( isSomeString!(T[]) )
{
	assert(a.length, "Attempting to popFront() past the end of an array of " ~ T.stringof);
	a = a[1 .. $];
}

ubyte frontUnitLength(SourceRange)(ref const(SourceRange) input)
	if( isInputRange!SourceRange )
{
	alias Char = Unqual!(ElementEncodingType!SourceRange);

	if( input.empty )
		return 0;

	Char ch = input.front;

	//For UTF-8 and UTF-16 code points encoded with variable number of code units
	static if( is( Char == char ) )
	{
		if( (ch & 0b1000_0000) == 0 )
			return 1;
		else if( (ch & 0b1110_0000) == 0b1100_0000  )
			return 2;
		else if( (ch & 0b1111_0000) == 0b1110_0000 )
			return 3;
		else if( (ch & 0b1111_1000) == 0b1111_0000 )
			return 4;
		else
			//If SourceRange is in the middle of code point then just return 0
			//instead of throwing error
			return 0;

	}
	else static if( is( Char == wchar ) )
	{
		if( ch < 0xD800 || ch > 0xDFFF )
			return 1;
		else
			return 2;
	}
	else static if( is( Char == dchar ) )
	{
		return 1; //For UTF-32 each code points encoded with 1 code unit
	}
	else
		static assert( false, "Unsupported character type!" );
}

dchar decodeFront(SourceRange)(ref const(SourceRange) input)
	if( isForwardRange!SourceRange )
{
	import std.exception: enforce;

	alias enf = enforce;

	alias Char = Unqual!(ElementEncodingType!SourceRange);

	static if( is( Char == char ) )
	{
		static immutable(char)[4] firstByteMasks = [
			0b0111_1111,
			0b0001_1111,
			0b0000_1111,
			0b0000_0111
		];
		auto textRange = input.save;
		enf(!textRange.empty, `UTF-8 byte sequence is empty`);

		ubyte seqLen = frontUnitLength(input);
		enf(seqLen != 0 && seqLen < 4, `Unexpected UTF-8 byte sequence length`);

		dchar result = textRange.front & firstByteMasks[seqLen-1];
		textRange.popFront();

		if( seqLen == 1 )
			return result;

		foreach( i; 0..seqLen-1 )
		{
			enf(!textRange.empty, `Expected UTF-8 continuation bytes, but sequence is empty`);
			// All continuation bytes must satisfy mask 10xxxxxx
			enf((textRange.front & 0b1100_0000) == 0b1000_0000, `Incorrect UTF-8 continuation byte`);

			result <<= 6;
			result |= (textRange.front & 0b0011_1111);
			textRange.popFront();
		}

		return result;
	}
	else static if( is( Char == wchar ) )
	{
		auto textRange = input.save;
		enf(!textRange.empty, `UTF-16 byte sequence is empty`);

		Char ch1 = textRange.front;
		textRange.popFront();
		// Values outside of `private` range are taken as is
		if( ch1 < 0xD800 || ch1 > 0xDFFF )
			return ch1;

		enf(ch1 <= 0xDBFF, `Value of first surrogate must between 0xD800 and 0xDBFF (first 10 bits)`);
		enf(!textRange.empty, `Second value of surrogate pair is required`);

		Char ch2 = textRange.front;
		textRange.popFront();
		enf(0xDC00 <= ch2 && ch2 <= 0xDFFF, `Value of second surrogate must between 0xDC00 and 0xDFFF (second 10 bits)`);

		return ((ch1 & 1023) << 10) + (ch2 & 1023) + 0x10000;
	}
	else static if( is( Char == dchar ) )
	{
		return input.front;
	}
	else
		static assert( false, "Unsupported character type!!!");
}