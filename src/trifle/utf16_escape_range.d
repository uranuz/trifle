module trifle.utf16_escape_range;

static struct UEscapeRange(SourceRange, Exc = Exception)
{
	import std.range: ElementEncodingType;
	import std.traits: Unqual;
	
	import std.exception: enforce;

	alias enf = enforce!Exc;
	alias Char = Unqual!(ElementEncodingType!SourceRange);
	alias UEscRange = typeof(this);

private:
	static if( is( Char == char ) ) {
		enum _sizeMax = 4;
	} else static if( is( Char == wchar ) ) {
		enum _sizeMax = 2;
	} else static if( is( Char == dchar ) ) {
		enum _sizeMax = 1;
	} else
		static assert(false, `Unexpected kind of code unit`);
	
	char[_sizeMax] _units;
	ubyte _size = 0;

public:
	this(ref SourceRange rng)
	{
		import trifle.parse_utils: empty, front;
		enf(
			!rng.empty,
			`Expected non empty unicode escaped sequence`);
		enf(
			_isUnicodeEscapedSeq(rng.front),
			`Invalid unicode escaped sequence`);
		_parseSeq(rng);
	}

	this(ref return scope inout(UEscRange) rhs) inout
	{
		this._units[] = rhs._units[];
		this._size = rhs._size;
	}

	Char front() @property {
		return _units[_units.length - _size];
	}

	void popFront()
	{
		enf(_size > 0 && _size <= _sizeMax, `Unicode escaped range is empty`);
		--_size;
	}

	bool empty() @property {
		return _size == 0;
	}

	UEscapeRange save() @property inout {
		return UEscapeRange(this);
	}

private:
	static bool _isUnicodeEscapedSeq(Char ch)
	{
		import std.ascii: isHexDigit;
		return ch == '\\' || ch == 'u' || isHexDigit(ch);
	}

	void _parseSeq(ref SourceRange rng)
	{
		import trifle.parse_utils: empty, front, popFront;
		import std.uni: isSurrogateHi, isSurrogateLo;

		wchar wc = _parseWChar(rng);

		// Non-BMP characters are escaped as a pair of
		// UTF-16 surrogate characters (see RFC 4627).
		if (isSurrogateHi(wc))
		{
			wchar[2] pair;

			pair[0] = wc;
			enf(!rng.empty, `Expected non empty range`);
			enf(rng.front == '\\', `Expected escaped low surrogate after escaped high surrogate`);
			rng.popFront(); // Skip \

			enf(!rng.empty, `Expected non empty range`);
			enf(rng.front == 'u', `Expected escaped low surrogate after escaped high surrogate`);
			rng.popFront(); // Skip u
			pair[1] = _parseWChar(rng);

			static if( is( Char == wchar ) )
			{
				_size = 2;
				_units[] = pair[];
			}
			else
			{
				import trifle.parse_utils: decodeFront;
				wchar[] pairSlice = pair[];
				dchar val = decodeFront(pairSlice);

				static if( is( Char == char ) )
				{
					import std.utf: encode;

					_size = cast(ubyte) encode(_units, val);
				}
				else // dchar
				{
					_size = 1;
					_units[0] = val;
				}
			}
		}
		else
		{
			enf(!isSurrogateLo(wc), `Unexpected low surrogate`);
			static if( is( Char == char ) )
			{
				import std.utf: encode;

				_size = cast(ubyte) encode(_units, wc);
			}
			else // wchar, dchar
			{
				_size = 1;
				_units[0] = wc;
			}
		}
	}

	static wchar _parseWChar(ref SourceRange rng)
	{
		import trifle.parse_utils: empty, front, popFront;
		import std.ascii: isDigit, isHexDigit, toUpper;

		wchar val = 0;
		foreach_reverse( i; 0 .. 4 )
		{
			enf(!rng.empty, `Expected hex character`);
			auto hex = toUpper(rng.front);
			rng.popFront();
			enf(isHexDigit(hex), `Expecting hex character`);
			val += (isDigit(hex)? hex - '0': hex - ('A' - 10)) << (4 * i);
		}
		return val;
	}
}
