# Flight Protocol Syntax

Flight Protocol, Wire format or RSC payload are different names for a seriliazation method that can be used to transfer different type of data between server and client. These data can be react elements, json objects, javascript primitives, react server function calls or results, ...etc. Flight Protocol format consists of multiple lines separated by new line, each line is called a chunk. Each chunk have the following format

```rsc
<chunk id (hexa-decimal integer)>:<tag at some chunks><json stringified payload>
```

For example the following JSON object

```json
{ "name": "Alice", "age": 20 }
```

is serialized into

```rsc
0:{"name":"Alice","age": 20}
```

## References In Flight Protocol

Flight Protocol can reference chunks in other chunks. The `$` sign is used to reference other chunks, for example the following JSON array

```json
[
  { "name": "Alice", "age": 22 },
  { "name": "Pop", "age": 23 },
  { "name": "Alice", "age": 22 },
  { "name": "John", "age": 25 }
]
```

can be serialized into

```rsc
0:["$1",{"name":"Pop","age":23},"$1","$2"]
1:{"name":"Alice","age":22}
2:{"name":"John","age":25}
```

Order of chunks is not mandatory, the following serialization is valid as well

```rsc
2:{"name":"Alice","age":22}
0:["$2",{"name":"Pop","age":23},"$2","$1"]
1:{"name":"John","age":25}
```

> [!NOTE]
> React usually doesn't do references at JSON objects to share common info at them to DRY it, however, if you did references in serialized data feeded to react deserializer, it will understand it well.

## Javascript Primitives

It serialize different Javascript primitives and objects like strings, numbers, BigInt, Dates, symbols, Maps, Sets, Uint8Array and Float64Array. Primitives that are supported in json such as strings and numbers are serialized in the same way that json use to serialize them. The serialization of the following javascript object shows how all of these primitives are serialized:

```js
{
  null: null,
  undefined: undefined,
  number: 42,
  boolean: true,
  string: 'hello world',
  specialNumbers: {
    inf: Infinity,
    negInf: -Infinity,
    notANumber: NaN,
    negativeZero: -0,
  },
  date: new Date('2025-01-15T10:30:00Z'),
  globalSymbol: Symbol.for('my.test.symbol'),
  map: new Map([['a', 1], ['b', 2]]),
  set: new Set([10, 20, 30, 'hello']),
  Uint8Array: new Uint8Array([72, 101, 108, 108, 111]),
  Float64Array: new Float64Array([3.14, 2.718]),
  dollarString: '$100 dollars',
}
```

is serialized into

```rsc
1:[["a",1],["b",2]]
2:[10,20,30,"hello"]
3:o5,Hello
4:g10,<16 bytes of binary float64 data>
0:{"null":null,"undefined":"$undefined","number":42,"boolean":true,"string":"hello world","specialNumbers":{"inf":"$Infinity","negInf":"$-Infinity","notANumber":"$NaN","negativeZero":"$-0"},"date":"$D2025-01-15T10:30:00.000Z","globalSymbol":"$Smy.test.symbol","map":"$Q1","set":"$W2","Uint8Array":"$3","Float64Array":"$4","dollarString":"$$100 dollars"}
```

As you can notice, types that json can't normally represent are encoded using a `$` prefix followed by a letter that indicate the type. `$undefined` for undefined, `$Infinity` for Infinity, `$-Infinity` for negative infinity, `$NaN` for NaN and `$-0` for negative zero. Dates are encoded as `$D` followed by the ISO string like `$D2025-01-15T10:30:00.000Z`. BigInt is encoded as `$n` followed by the digits like `$n99999999999999999`. Symbols created with `Symbol.for()` are encoded as `$S` followed by the name like `$Smy.test.symbol`.

If the actual string value start with `$`, it get escaped with an extra `$`. So the string `$100 dollars` become `$$100 dollars` at the wire. The client strip the extra `$` when deserializing.

Maps and Sets are outlined to their own chunks. The Map data is serialized as array of key-value pairs like `[["a",1],["b",2]]` and referenced from the parent using `$Q<chunk id>`. Sets are similar but serialized as array of values like `[10,20,30,"hello"]` and referenced with `$W<chunk id>`.

Typed arrays like Uint8Array and Float64Array are also outlined to their own chunks but they use binary row format instead of json. Binary rows have different format:

```
<chunk id>:<tag><length in hex>,<raw binary data>
```

For example `3:o5,Hello` mean chunk id 3, tag `o` (Uint8Array), length 5 bytes in hex, then the raw bytes. The bytes 72, 101, 108, 108, 111 are the ASCII codes for "Hello" thats why it appear readable at the output. Float64Array use tag `g` and the binary data is the raw IEEE 754 representation which is not human readable.

Each typed array type have its own tag: `A` for ArrayBuffer, `O` for Int8Array, `o` for Uint8Array, `U` for Uint8ClampedArray, `S` for Int16Array, `s` for Uint16Array, `L` for Int32Array, `l` for Uint32Array, `G` for Float32Array, `g` for Float64Array, `M` for BigInt64Array, `m` for BigUint64Array and `V` for DataView.

> [!Note]
> Only symbols created with `Symbol.for()` can be serialized. Local symbols created with `Symbol()` will throw an error.

> [!Note]
> Long strings (roughly over 1KB) also switch to binary format using tag `T` instead of being encoded as json string.

## React Elements

React elements are serialized as json arrays at the following format:

```
["$", type, key, props]
```

`"$"` at the first position represent `REACT_ELEMENT_TYPE` (the `$$typeof` of the element). `type` is the element type, it can be a string like `"div"` or a reference to a client component like `"$L1"`. `key` is the react key or `null`. `props` is the props object.

For example the following JSX:

```jsx
<div className="app">
  <h1>Title</h1>
  <p>Body</p>
</div>
```

is serialized into

```rsc
0:["$","div",null,{"className":"app","children":[["$","h1",null,{"children":"Title"}],["$","p",null,{"children":"Body"}]]}]
```

Elements are nested inside each other, the children prop contain the child elements as nested arrays.

## Server Components vs Client Components

Server components (functions without `"use client"`) are executed at the server and their return value is what get serialized. The server component function itself never appear at the output, only what it return.

Client components (marked with `"use client"`) are NOT executed at the server. Instead flight serialize a reference to the client module so the browser can load and execute it. This produce a new type of chunk called Import chunk which have the tag `I`.

For example if you have:

```jsx
// Counter.js
'use client';
export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount((c) => c + 1)}>{count}</button>;
}

// Page.js (server component)
import { Counter } from './Counter';
export function Page() {
  return (
    <div>
      <h1>My Page</h1>
      <Counter />
    </div>
  );
}
```

Serializing `<Page />` produce:

```rsc
1:I{"id":"./src/Counter.js","chunks":["chunk-abc"],"name":"Counter"}
0:["$","div",null,{"children":[["$","h1",null,{"children":"My Page"}],["$","$L1",null,{}]]}]
```

Two chunks are produced. Chunk 1 is an Import chunk (tag `I`) that contain the module metadata: the module id, what webpack chunks to load, and the export name. Chunk 0 is the element tree where the Counter element type is `"$L1"` which is a lazy reference to chunk 1.

The `$L` prefix is important. It tell the client to wrap it in `React.lazy()` so react can show a Suspense fallback while the module is loading. If you pass the client component as a prop value (not as element type) it use `$` instead of `$L`:

```js
// as element type -> "$L1" (lazy)
React.createElement(Counter);
// => ["$","$L1",null,{}]

// as prop value -> "$1" (direct reference)
{
  myComponent: Counter;
}
// => {"myComponent":"$1"}
```

## Promises and Streaming

When a server component is async (for example it await a fetch call), flight handle it with promise references using `$@` prefix. This is what enable streaming at React Server Components.

For example imagine a page with fast and slow parts:

```jsx
async function SlowData() {
  const data = await fetch('/api/slow');
  return <p>{data}</p>;
}

function Page() {
  return (
    <div>
      <h1>Fast Header</h1>
      <Suspense fallback={<p>Loading...</p>}>
        <SlowData />
      </Suspense>
    </div>
  );
}
```

The server start streaming immediately, it don't wait for SlowData to finish:

```rsc
0:["$","div",null,{"children":[["$","h1",null,{"children":"Fast Header"}],["$","$Sreact.suspense",null,{"fallback":["$","p",null,{"children":"Loading..."}],"children":"$L1"}]]}]
```

At this point chunk 1 is not resolved yet. The client render the div and h1 immediately and show the Suspense fallback. When the fetch finish, the server send:

```rsc
1:["$","p",null,{"children":"fetched data here"}]
```

Now chunk 1 is resolved and the `$L1` lazy reference is complete. React replace the fallback with the actual content. This is how streaming work, you don't need the whole tree to be ready before sending the first byte to the client.

For plain promises (not elements), `$@` is used:

```rsc
0:{"fast":"hello","slow":"$@1"}
1:"resolved after 2 seconds"
```

The root object is available immediately with the `fast` property, but `slow` is a promise reference that resolve when chunk 1 arrive.

## Error Chunks

When an error happen during rendering, the server send an error chunk with the `E` tag:

```rsc
0:E{"digest":"NOT_FOUND","message":"page not found"}
```

In development mode the error chunk contain more informations like the error name, stack trace and environment:

```rsc
0:E{"digest":"NOT_FOUND","name":"NotFoundError","message":"page not found","stack":[],"env":"server"}
```

## Hint Chunks

Hint chunks are special because they don't have a chunk id. They are used to tell the client to preload resources like stylesheets or fonts. The format is `:H<code><json data>`.

For example:

```rsc
:HD["https://cdn.example.com/style.css","style"]
```

The `D` after `H` is the hint code that indicate what type of resource to preload. Hints are emitted before any other chunks so the browser can start downloading resources as early as possible.

## Stream and Async Iterable Chunks

Flight Protocol also support serializing ReadableStream and AsyncIterable objects. These use special tags to control the lifecycle: `R` to start a readable stream, `r` to start a readable byte stream, `X` to start an async iterable, `x` to start a byte async iterable and `C` to close/end the stream.

## Chunk Emission Order

The server don't send chunks at random order. It queue them into priority buckets and flush at this order:

1. Hint chunks (`:H...`) so the browser start fetching resources immediately
2. Import chunks (`I` tag) so client javascript can start loading
3. Regular model chunks which is the actual data
4. Error chunks

This is intentional. By the time the client start parsing the model data, the resources and modules referenced at it are already being downloaded.

## Row Format Summary

Text rows are terminated by newline:

```
<hex id>:<tag><json>\n
```

Binary rows are terminated by byte count:

```
<hex id>:<tag><hex length>,<raw bytes>
```

The client parser know which format to use based on the tag character. Binary tags are `T`, `A`, `o`, `O`, `S`, `s`, `L`, `l`, `G`, `g`, `M`, `m`, `V`, `U` and `b`. All other tags and untagged rows are text format terminated by newline.

If the byte after `:` is not a recognized tag letter (like `{` or `"` or a digit), the parser treat it as untagged model row and start reading json from that byte. Thats why `0:{"name":"x"}` work without any tag, because `{` is not a recognized tag character.
