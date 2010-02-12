$insts = {}
def inst(opcode, sym, *operands)
	$insts[opcode] = [sym, operands]
end

inst 0x02, :nop
inst 0x03, :throw
inst 0x04, :getsuper, :multiname
inst 0x05, :setsuper, :multiname
inst 0x06, :dxns, :string
inst 0x07, :dxnslate
inst 0x08, :kill, :uint30
inst 0x09, :label

inst 0x0C, :ifnlt, :int24
inst 0x0D, :ifnle, :int24
inst 0x0E, :ifngt, :int24
inst 0x0F, :ifnge, :int24

inst 0x10, :jump, :int24
inst 0x11, :iftrue, :int24
inst 0x12, :iffalse, :int24
inst 0x13, :ifeq, :int24
inst 0x14, :ifne, :int24
inst 0x15, :iflt, :int24
inst 0x16, :ifle, :int24
inst 0x17, :ifgt, :int24
inst 0x18, :ifge, :int24
inst 0x19, :ifstricteq, :int24
inst 0x1A, :ifstrictne, :int24
inst 0x1B, :lookupswitch, :int24, :jumptable
inst 0x1C, :pushwith
inst 0x1D, :popscope
inst 0x1E, :nextname
inst 0x1F, :hasnext

inst 0x20, :pushnull
inst 0x21, :pushundefined
inst 0x23, :nextvalue
inst 0x24, :pushbyte, :uint8
inst 0x25, :pushshort, :uint30
inst 0x26, :pushtrue
inst 0x27, :pushfalse
inst 0x28, :pushnan
inst 0x29, :pop
inst 0x2A, :dup
inst 0x2B, :swap
inst 0x2C, :pushstring, :string
inst 0x2D, :pushint, :uint30
inst 0x2E, :pushuint, :uint30
inst 0x2F, :pushdouble, :uint30

inst 0x30, :pushscope
inst 0x31, :pushnamespace, :uint30
inst 0x32, :hasnext2, :uint30, :uint30

inst 0x40, :newfunction, :uint30
inst 0x41, :call, :uint30
inst 0x42, :construct, :uint30
inst 0x43, :callmethod, :uint30, :uint30
inst 0x44, :callstatic, :uint30, :uint30
inst 0x45, :callsuper, :multiname, :uint30
inst 0x46, :callproperty, :multiname, :uint30
inst 0x47, :returnvoid
inst 0x48, :returnvalue
inst 0x49, :constructsuper, :uint30
inst 0x4A, :constructprop, :multiname, :uint30
inst 0x4C, :callproplex, :multiname, :uint30
inst 0x4E, :callsupervoid, :multiname, :uint30
inst 0x4F, :callpropvoid, :multiname, :uint30

inst 0x55, :newobject, :uint30
inst 0x56, :newarray, :uint30
inst 0x57, :newactivation
inst 0x58, :newclass, :uint30
inst 0x59, :getdescendants, :multiname
inst 0x5A, :newcatch, :uint30
inst 0x5D, :findpropstrict, :multiname
inst 0x5E, :findproperty, :multiname

inst 0x60, :getlex, :multiname
inst 0x61, :setproperty, :uint30
inst 0x62, :getlocal, :uint30
inst 0x63, :setlocal, :uint30
inst 0x64, :getglobalscope
inst 0x65, :getscopeobject, :uint8
inst 0x66, :getproperty, :multiname
inst 0x68, :initproperty, :multiname
inst 0x6A, :deleteproperty, :multiname
inst 0x6C, :getslot, :uint30
inst 0x6D, :setslot, :uint30
inst 0x6E, :getglobalslot, :uint30
inst 0x6F, :setglobalslot, :uint30

inst 0x70, :convert_s
inst 0x71, :esc_xelem
inst 0x72, :esc_xattr
inst 0x73, :convert_i
inst 0x74, :convert_u
inst 0x75, :convert_d
inst 0x76, :convert_b
inst 0x77, :convert_o
inst 0x78, :checkfilter

inst 0x80, :coerce, :multiname
inst 0x82, :coerce_a
inst 0x85, :coerce_s
inst 0x86, :astype, :multiname
inst 0x87, :astypelate

inst 0x90, :negate
inst 0x91, :increment
inst 0x92, :inclocal, :uint30
inst 0x93, :decrement
inst 0x94, :declocal, :uint30
inst 0x95, :typeof
inst 0x96, :not
inst 0x97, :bitnot

inst 0xA0, :add
inst 0xA1, :subtract
inst 0xA2, :multiply
inst 0xA3, :divide
inst 0xA4, :modulo
inst 0xA5, :lshift
inst 0xA6, :rshift
inst 0xA7, :urshift
inst 0xA8, :bitand
inst 0xA9, :bitor
inst 0xAA, :bitxor
inst 0xAB, :equals
inst 0xAC, :strictequals
inst 0xAD, :lessthan
inst 0xAE, :lessequals
inst 0xAF, :greaterthan
inst 0xB0, :greaterequals

inst 0xB1, :instanceof
inst 0xB2, :istype, :multiname
inst 0xB3, :istypelate
inst 0xB4, :in

inst 0xC0, :increment_i
inst 0xC1, :decrement_i
inst 0xC2, :inclocal_i, :uint30
inst 0xC3, :declocal_i, :uint30
inst 0xC4, :negate_i
inst 0xC5, :add_i
inst 0xC6, :subtract_i
inst 0xC7, :multiply_i

inst 0xD0, :getlocal_0
inst 0xD1, :getlocal_1
inst 0xD2, :getlocal_2
inst 0xD3, :getlocal_3
inst 0xD4, :setlocal_0
inst 0xD5, :setlocal_1
inst 0xD6, :setlocal_2
inst 0xD7, :setlocal_3

inst 0xEF, :debug, :uint8, :string, :uint8, :uint30
inst 0xF0, :debugline, :uint30
inst 0xF1, :debugfile, :string
