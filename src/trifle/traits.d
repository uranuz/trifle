module trifle.traits;

import std.traits: isDynamicArray, isAssociativeArray;

///Returns true if T is nullable type
enum bool isNullableType(T) = __traits( compiles, { bool aaa = T.init is null; } );

enum bool isSafelyNullable(T) = isNullableType!T && (isDynamicArray!T || isAssociativeArray!T);

enum bool isUnsafelyNullable(T) = isNullableType!T && !isDynamicArray!T && !isAssociativeArray!T;

///Шаблон, возвращает true, если T является Nullable или NullableRef
template isStdNullable(T)
{
	import std.traits: isInstanceOf, Unqual;
	import std.typecons: Nullable, NullableRef;
	enum bool isStdNullable = isInstanceOf!(Nullable, Unqual!T) || isInstanceOf!(NullableRef, Unqual!T);
}

///Шаблон возвращает базовый тип для Nullable или NullableRef
template getStdNullableType(T)
{
	import std.typecons: Nullable, NullableRef;
	import std.traits: fullyQualifiedName;
	static if( is( T == NullableRef!(TL2), TL2... ) )
		alias getStdNullableType = TL2[0] ;
	else static if( is( T == Nullable!(TL2), TL2... ) )
		alias getStdNullableType = TL2[0];
	else
		static assert(false, `Type ` ~ fullyQualifiedName!(T) ~ ` can't be used as Nullable type!!!` );
}

unittest
{
	import std.typecons: Nullable, NullableRef;
	static assert( !isStdNullable!int );
	static assert( !isStdNullable!(int*) );
	static assert( !isStdNullable!(int[4]) );

	static assert( isStdNullable!(Nullable!int) );
	static assert( isStdNullable!(NullableRef!int) );

	static assert( is( getStdNullableType!(Nullable!int) == int ) );
	static assert( is( getStdNullableType!(NullableRef!int) == int ) );
}

unittest
{
	interface Vasya {}

	class Petya {}

	struct Vova {}
	
	alias void function(int) FuncType;
	alias bool delegate(string, int) DelType;

	//Check that these types are nullable
	static assert( isNullableType!Vasya );
	static assert( isNullableType!Petya );
	static assert( isNullableType!(string) );
	static assert( isNullableType!(int*) );
	static assert( isNullableType!(string[string]) );
	static assert( isNullableType!(FuncType) );
	static assert( isNullableType!(DelType) );
	static assert( isNullableType!(dchar[7]*) );

	//Check that these types are not nullable
	static assert( !isNullableType!Vova );
	static assert( !isNullableType!(double) );
	static assert( !isNullableType!(int[8]) );
	static assert( !isNullableType!(double) );
}

unittest
{
	// Types for tests
	interface Vasya {}
	class Petya {}
	struct Vova {}
	alias void function(int) FuncType;
	alias bool delegate(string, int) DelType;


	// Tests for isSafelyNullable
	// These types are not nullable at all
	static assert( !isSafelyNullable!Vova );
	static assert( !isSafelyNullable!(int) );
	static assert( !isSafelyNullable!(int[8]) );
	static assert( !isSafelyNullable!(double) );

	// These types are nullable, but null value IS safe to access
	static assert( isSafelyNullable!(string) );
	static assert( isSafelyNullable!(int[]) );
	static assert( isSafelyNullable!(string[string]) );

	// These types are nullable, but null value IS NOT safe to access
	static assert( !isSafelyNullable!Vasya );
	static assert( !isSafelyNullable!Petya );
	static assert( !isSafelyNullable!(int*) );
	static assert( !isSafelyNullable!(FuncType) );
	static assert( !isSafelyNullable!(DelType) );
	static assert( !isSafelyNullable!(dchar[7]*) );


	// Tests for isUnsafelyNullable
	// These types are not nullable at all
	static assert( !isUnsafelyNullable!Vova );
	static assert( !isUnsafelyNullable!(int) );
	static assert( !isUnsafelyNullable!(int[8]) );
	static assert( !isUnsafelyNullable!(double) );

	// These types are nullable, but null value IS safe to access
	static assert( !isUnsafelyNullable!(string) );
	static assert( !isUnsafelyNullable!(int[]) );
	static assert( !isUnsafelyNullable!(string[string]) );
	
	// These types are nullable, but null value IS NOT safe to access
	static assert( isUnsafelyNullable!Vasya );
	static assert( isUnsafelyNullable!Petya );
	static assert( isUnsafelyNullable!(int*) );
	static assert( isUnsafelyNullable!(FuncType) );
	static assert( isUnsafelyNullable!(DelType) );
	static assert( isUnsafelyNullable!(dchar[7]*) );
}