module trifle.quoted_string_range;

struct QuotedStringRange(SourceRange, dstring Quotes = `"'`, Exc = Exception)
{
	import std.range: ElementEncodingType;
	import std.traits: Unqual;
	import std.exception: enforce;

	import trifle.utf16_escape_range: UEscapeRange;


	alias Char = Unqual!(ElementEncodingType!SourceRange);
	alias enf = enforce!Exc;
	alias UEscRange = UEscapeRange!(SourceRange, Exc);
	alias QuotRange = typeof(this);

private:
	SourceRange _src;
	UEscRange _uRange;
	Char _quot;
	Char _frontChar;

public:
	@disable this(this);

	this(SourceRange src)
	{
		import std.algorithm: canFind;
		import trifle.parse_utils: empty, front, popFront, save;

		_src = src;
		enf(!_src.empty, `Quoted string should not be empty`);
		_quot = _src.front;
		_src.popFront(); // Skip quote
		enf(Quotes.canFind(_quot), `Quoted string should start with a quote`);
		if( !_isEmptyRange ) {
			this.popFront();
		}
	}

	this(ref return scope inout(QuotRange) rhs) inout
	{
		import trifle.parse_utils: save;
		this._src = rhs._src.save;
		this._uRange = rhs._uRange.save;
		this._quot = rhs._quot;
		this._frontChar = rhs._frontChar;
	}

	bool empty() @property {
		return _frontChar == '\0';
	}

	Char front() @property {
		return _frontChar;
	}

	void popFront() {
		_frontChar = _parseFront();
	}

	auto save() @property {
		return typeof(this)(this);
	}

	// De-facto standard property to get underlying range
	SourceRange source() @property {
		return _src;
	}

private:
	bool _isEmptyRange() @property
	{
		import trifle.parse_utils: empty, front;
		return (_src.empty || _src.front == _quot) && _uRange.empty;
	}

	Char _parseFront()
	{
		import trifle.parse_utils: empty, front, popFront;

		if( this._isEmptyRange ) {
			return '\0';
		}

		if( !_uRange.empty )
		{
			// Check if there is something in _uRange left...
			auto ures = _uRange.front;
			_uRange.popFront();
			return ures;
		}

		Char ch = _src.front;
		_src.popFront(); // Skip character
		if( ch != '\\' ) {
			return ch;
		}
		enf(!_src.empty, `Expected escaped sequence`);
		// We have got an escaped character
		ch = _src.front;
		_src.popFront(); // Skip character
		switch( ch )
		{
			case 'u':
			{
				_uRange = UEscRange(_src);
				enf(!_uRange.empty, `UTF16 escaped range must not be empty`);
				auto val = _uRange.front;
				_uRange.popFront();
				return val;
			}
			case 'x': case 'U': {
				enf(false, `Unsupported escape sequence`);
				break;
			}
			// Generate cases for special escape sequences...
			static foreach( Char esc; `bfnrtv0` ) {
				mixin(`case '` ~ esc ~ `': return '\` ~ esc ~ `';`);
			}
			default: break;
		}
		// Regular symbol is being escaped...
		return ch;
	}
}


unittest
{
	import std.algorithm: equal;
	string aaa1 = `"vasya\"petya\\new\tdimension" rest of range...`;
	string aaa2 = "\"vasya\"petya\\new\tdimension\" rest of range...";
	auto rng = QuotedStringRange!string(`"vasya\"petya\\new\tdimension" rest of range...`);
}