module trifle.escaped_string_writer;

import std.range: ElementEncodingType;
import std.traits: Unqual;

void writeQuotedStr(OutRange, SourceRange)(ref OutRange sink, SourceRange src, bool quote = true)
{
	import trifle.parse_utils: empty, front, popFront;

	alias Char = Unqual!(ElementEncodingType!SourceRange);

	if( quote )
		sink.put("\"");
	while( !src.empty )
	{
		Char ch = src.front;
		src.popFront();

		switch( ch )
		{
			case '\"': sink.put("\\\""); break;
			case '\\': sink.put("\\\\"); break;
			case '/': sink.put("\\/"); break;
			case '\a': sink.put("\\a"); break;
			case '\b': sink.put("\\b"); break;
			case '\f': sink.put("\\f"); break;
			case '\n': sink.put("\\n"); break;
			case '\r': sink.put("\\r"); break;
			case '\t': sink.put("\\t"); break;
			case '\v': sink.put("\\v"); break;
			case '\0': sink.put("\\0"); break;
			default: sink.put(ch); break;
		}
	}
	if( quote )
		sink.put("\"");
}

void writeHTMLStr(OutRange, SourceRange)(ref OutRange sink, SourceRange src, bool quote = true)
{
	import trifle.parse_utils: empty, front, popFront;

	alias Char = Unqual!(ElementEncodingType!SourceRange);

	if( quote )
		sink.put("\"");
	while( !src.empty )
	{
		Char ch = src.front;
		src.popFront();

		switch( ch )
		{
			case '&': sink.put("&amp;"); break;
			case '\'': sink.put("&apos;"); break;
			case '"': sink.put("&quot;"); break;
			case '<': sink.put("&lt;"); break;
			case '>': sink.put("&gt;"); break;
			default: sink.put(ch); break;
		}
	}
	if( quote )
		sink.put("\"");
}