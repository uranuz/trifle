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
	Char _frontChar = '\0';
	bool _finished = false;

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
		
		_checkEndQuote();
		if( !_finished ) {
			this.popFront(); // Parse the first character
		}
	}

	/// Copy constructor
	this(ref return scope inout(QuotRange) rhs) inout
	{
		import trifle.parse_utils: save;
		this._src = rhs._src.save;
		this._uRange = rhs._uRange.save;
		this._quot = rhs._quot;
		this._frontChar = rhs._frontChar;
		this._finished = rhs._finished;
	}

	/// Range empty primitive
	bool empty() @property {
		return _frontChar == '\0' && _finished;
	}

	/// Range front primitive
	Char front() @property {
		return _frontChar;
	}

	/// Range popFront primitive
	void popFront() {
		_frontChar = _parseFront();
	}

	/// Range save primitive
	auto save() @property {
		return typeof(this)(this);
	}

	// Returns underlying range at it's current state
	SourceRange source() @property {
		return _src;
	}

private:
	Char _parseFront()
	{
		import trifle.parse_utils: empty, front, popFront;

		if( !_uRange.empty )
		{
			// Check if there is something in _uRange left...
			auto ures = _uRange.front;
			_uRange.popFront();
			return ures;
		}

		if( _finished )
		{
			enf(_frontChar != '\0', `Attempt to push forward an empty range`);
			return '\0';
		}

		enf(!_src.empty, `Unexpected end of quoted string`);
		Char ch = _src.front;
		_src.popFront(); // Skip character

		ch = (ch == '\\'? _parseEscaped(): ch);

		_checkEndQuote();
		return ch;
	}

	void _checkEndQuote()
	{
		enf(!_src.empty, `Unexpected finish of quoted string`);
		// We shall test if the next char is quout and consume it
		if( _src.front == _quot )
		{
			_src.popFront(); // Drop quot
			_finished = true; // Set state that we have done with this escaped string
		}
	}

	Char _parseEscaped()
	{
		enf(!_src.empty, `Expected escaped sequence, but got end of input`);
		// We have got an escaped character
		Char ch = _src.front;
		_src.popFront(); // Skip this character
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
