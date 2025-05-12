# zigmatch

I wrote this as a way to learn Zig, this is wayyyyyyyyy slower than any existing Regex engine, and doesn't support any advanced features e.g. capture groups, back referencing, word boundaries, etc...

## TODO
- [ ] Clean-up, this is the first time I've written any serious Zig code, so I'm sure there's plenty of mistakes _(especially that nasty formatter struct)_.
- [ ] Write **comptime** regex parser, that can take a string like "A|B" and transform it to `builder.alt(builder.char('A'), builder.char('B'))` at compile-time. (Not sure if this is possible, comptime still seems a bit like magic to me, so in doing this I should learn a lot)
- [ ] ???
- [ ] Profit
