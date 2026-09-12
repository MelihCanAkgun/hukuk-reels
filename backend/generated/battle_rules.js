(function dartProgram(){function copyProperties(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
b[r]=a[r]}}function mixinPropertiesHard(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
if(!b.hasOwnProperty(r)){b[r]=a[r]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var t=function(){}
t.prototype={p:{}}
var s=new t()
if(!(Object.getPrototypeOf(s)&&Object.getPrototypeOf(s).p===t.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var r=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(r))return true}}catch(q){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var t=Object.create(b.prototype)
copyProperties(a.prototype,t)
a.prototype=t}}function inheritMany(a,b){for(var t=0;t<b.length;t++){inherit(b[t],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){var s=d()
if(a[b]!==t){A.hY(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.j(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.dQ(b)
return new t(c,this)}:function(){if(t===null)t=A.dQ(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.dQ(a).prototype
return t}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var t=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var s=staticTearOffGetter(t)
a[b]=s}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var t=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var s=instanceTearOffGetter(c,t)
a[b]=s}function setOrUpdateInterceptorsByTag(a){var t=v.interceptorsByTag
if(!t){v.interceptorsByTag=a
return}copyProperties(a,t)}function setOrUpdateLeafTags(a){var t=v.leafTags
if(!t){v.leafTags=a
return}copyProperties(a,t)}function updateTypes(a){var t=v.types
var s=t.length
t.push.apply(t,a)
return s}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var t=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},s=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:t(0,0,null,["$0"],0),_instance_1u:t(0,1,null,["$1"],0),_instance_2u:t(0,2,null,["$2"],0),_instance_0i:t(1,0,null,["$0"],0),_instance_1i:t(1,1,null,["$1"],0),_instance_2i:t(1,2,null,["$2"],0),_static_0:s(0,null,["$0"],0),_static_1:s(1,null,["$1"],0),_static_2:s(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
dV(a,b,c,d){return{i:a,p:b,e:c,x:d}},
dR(a){var t,s,r,q,p,o=a[v.dispatchPropertyName]
if(o==null)if($.dT==null){A.hM()
o=a[v.dispatchPropertyName]}if(o!=null){t=o.p
if(!1===t)return o.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return o.i
if(o.e===s)throw A.d(A.el("Return interceptor for "+A.u(t(a,o))))}r=a.constructor
if(r==null)q=null
else{p=$.cU
if(p==null)p=$.cU=v.getIsolateTag("_$dart_js")
q=r[p]}if(q!=null)return q
q=A.hS(a)
if(q!=null)return q
if(typeof a=="function")return B.K
t=Object.getPrototypeOf(a)
if(t==null)return B.z
if(t===Object.prototype)return B.z
if(typeof r=="function"){p=$.cU
if(p==null)p=$.cU=v.getIsolateTag("_$dart_js")
Object.defineProperty(r,p,{value:B.q,enumerable:false,writable:true,configurable:true})
return B.q}return B.q},
fr(a,b){if(a<0||a>4294967295)throw A.d(A.cP(a,0,4294967295,"length",null))
return J.fs(new Array(a),b)},
ec(a,b){if(a<0)throw A.d(A.c6("Length must be a non-negative integer: "+a))
return A.j(new Array(a),b.h("m<0>"))},
bC(a,b){if(a<0)throw A.d(A.c6("Length must be a non-negative integer: "+a))
return A.j(new Array(a),b.h("m<0>"))},
fs(a,b){var t=A.j(a,b.h("m<0>"))
t.$flags=1
return t},
ar(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.aP.prototype
return J.bE.prototype}if(typeof a=="string")return J.az.prototype
if(a==null)return J.aQ.prototype
if(typeof a=="boolean")return J.bD.prototype
if(Array.isArray(a))return J.m.prototype
if(typeof a!="object"){if(typeof a=="function")return J.ab.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.w)return a
return J.dR(a)},
dr(a){if(typeof a=="string")return J.az.prototype
if(a==null)return a
if(Array.isArray(a))return J.m.prototype
if(typeof a!="object"){if(typeof a=="function")return J.ab.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.w)return a
return J.dR(a)},
a8(a){if(a==null)return a
if(Array.isArray(a))return J.m.prototype
if(typeof a!="object"){if(typeof a=="function")return J.ab.prototype
if(typeof a=="symbol")return J.aU.prototype
if(typeof a=="bigint")return J.aS.prototype
return a}if(a instanceof A.w)return a
return J.dR(a)},
W(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.ar(a).D(a,b)},
B(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.hR(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.dr(a).i(a,b)},
bm(a,b,c){return J.a8(a).l(a,b,c)},
f4(a,b){return J.a8(a).a9(a,b)},
dZ(a,b){return J.a8(a).J(a,b)},
f5(a,b){return J.a8(a).C(a,b)},
bn(a,b){return J.a8(a).H(a,b)},
X(a){return J.ar(a).gu(a)},
f6(a){return J.a8(a).gaC(a)},
ag(a){return J.a8(a).gp(a)},
av(a){return J.dr(a).gn(a)},
f7(a){return J.ar(a).gt(a)},
f8(a,b,c,d){return J.a8(a).bd(a,b,c,d)},
dz(a,b,c){return J.a8(a).S(a,b,c)},
aw(a){return J.ar(a).j(a)},
e_(a,b){return J.a8(a).aH(a,b)},
bA:function bA(){},
bD:function bD(){},
aQ:function aQ(){},
aT:function aT(){},
ac:function ac(){},
bR:function bR(){},
b8:function b8(){},
ab:function ab(){},
aS:function aS(){},
aU:function aU(){},
m:function m(a){this.$ti=a},
bB:function bB(){},
cF:function cF(a){this.$ti=a},
ah:function ah(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aR:function aR(){},
aP:function aP(){},
bE:function bE(){},
az:function az(){}},A={dB:function dB(){},
ft(a){return new A.aW("Field '"+a+"' has not been initialized.")},
ad(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
dI(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
dU(a){var t,s
for(t=$.S.length,s=0;s<t;++s)if(a===$.S[s])return!0
return!1},
dE(a,b,c,d){if(u._.b(a))return new A.aL(a,b,c.h("@<0>").A(d).h("aL<1,2>"))
return new A.an(a,b,c.h("@<0>").A(d).h("an<1,2>"))},
ay(){return new A.b6("No element")},
aW:function aW(a){this.a=a},
cQ:function cQ(){},
h:function h(){},
E:function E(){},
am:function am(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
an:function an(a,b,c){this.a=a
this.b=b
this.$ti=c},
aL:function aL(a,b,c){this.a=a
this.b=b
this.$ti=c},
aY:function aY(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
x:function x(a,b,c){this.a=a
this.b=b
this.$ti=c},
z:function z(a,b,c){this.a=a
this.b=b
this.$ti=c},
ba:function ba(a,b,c){this.a=a
this.b=b
this.$ti=c},
L:function L(a,b,c){this.a=a
this.b=b
this.$ti=c},
aN:function aN(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
aM:function aM(a){this.$ti=a},
ap:function ap(a,b){this.a=a
this.$ti=b},
bb:function bb(a,b){this.a=a
this.$ti=b},
M:function M(){},
eS(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
hR(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.E.b(a)},
u(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.aw(a)
return t},
bS(a){var t,s=$.eg
if(s==null)s=$.eg=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
fx(a,b){var t,s=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(s==null)return null
if(3>=s.length)return A.e(s,3)
t=s[3]
if(t!=null)return parseInt(a,10)
if(s[2]!=null)return parseInt(a,16)
return null},
bT(a){var t,s,r,q
if(a instanceof A.w)return A.N(A.a9(a),null)
t=J.ar(a)
if(t===B.I||t===B.L||u.o.b(a)){s=B.t(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.N(A.a9(a),null)},
eh(a){var t,s,r
if(a==null||typeof a=="number"||A.dO(a))return J.aw(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.K)return a.j(0)
if(a instanceof A.a5)return a.aq(!0)
t=$.f3()
for(s=0;s<1;++s){r=t[s].bm(a)
if(r!=null)return r}return"Instance of '"+A.bT(a)+"'"},
G(a){var t
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.c.ao(t,10)|55296)>>>0,t&1023|56320)}throw A.d(A.cP(a,0,1114111,null,null))},
e(a,b){if(a==null)J.av(a)
throw A.d(A.c5(a,b))},
c5(a,b){var t,s="index"
if(!A.c4(b))return new A.aa(!0,b,s,null)
t=J.av(a)
if(b<0||b>=t)return A.ea(b,t,a,s)
return A.fz(b,s)},
hz(a){return new A.aa(!0,a,null,null)},
d(a){return A.F(a,new Error())},
F(a,b){var t
if(a==null)a=new A.b7()
b.dartException=a
t=A.hZ
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
hZ(){return J.aw(this.dartException)},
dW(a,b){throw A.F(a,b==null?new Error():b)},
au(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.dW(A.h7(a,b,c),t)},
h7(a,b,c){var t,s,r,q,p,o,n,m,l
if(typeof b=="string")t=b
else{s="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
r=s.length
q=b
if(q>r){c=q/r|0
q%=r}t=s[q]}p=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
o=u.j.b(a)?"list":"ByteData"
n=a.$flags|0
m="a "
if((n&4)!==0)l="constant "
else if((n&2)!==0){l="unmodifiable "
m="an "}else l=(n&1)!==0?"fixed-length ":""
return new A.b9("'"+t+"': Cannot "+p+" "+m+l+o)},
a_(a){throw A.d(A.Q(a))},
a4(a){var t,s,r,q,p,o
a=A.hX(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.j([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.cR(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
cS(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
ek(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
dC(a,b){var t=b==null,s=t?null:b.method
return new A.bF(a,s,t?null:b.receiver)},
eT(a){if(a==null)return new A.cO(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.at(a,a.dartException)
return A.hy(a)},
at(a,b){if(u.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
hy(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.c.ao(s,16)&8191)===10)switch(r){case 438:return A.at(a,A.dC(A.u(t)+" (Error "+r+")",null))
case 445:case 5007:A.u(t)
return A.at(a,new A.b3())}}if(a instanceof TypeError){q=$.eU()
p=$.eV()
o=$.eW()
n=$.eX()
m=$.f_()
l=$.f0()
k=$.eZ()
$.eY()
j=$.f2()
i=$.f1()
h=q.B(t)
if(h!=null)return A.at(a,A.dC(A.P(t),h))
else{h=p.B(t)
if(h!=null){h.method="call"
return A.at(a,A.dC(A.P(t),h))}else if(o.B(t)!=null||n.B(t)!=null||m.B(t)!=null||l.B(t)!=null||k.B(t)!=null||n.B(t)!=null||j.B(t)!=null||i.B(t)!=null){A.P(t)
return A.at(a,new A.b3())}}return A.at(a,new A.bY(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.b5()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.at(a,new A.aa(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.b5()
return a},
eP(a){if(a==null)return J.X(a)
if(typeof a=="object")return A.bS(a)
return J.X(a)},
hH(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.l(0,a[t],a[s])}return b},
hf(a,b,c,d,e,f){u.Z.a(a)
switch(A.f(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.d(new A.cT("Unsupported number of arguments for wrapped closure"))},
hB(a,b){var t=a.$identity
if(!!t)return t
t=A.hC(a,b)
a.$identity=t
return t},
hC(a,b){var t
switch(b){case 0:t=a.$0
break
case 1:t=a.$1
break
case 2:t=a.$2
break
case 3:t=a.$3
break
case 4:t=a.$4
break
default:t=null}if(t!=null)return t.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.hf)},
fk(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.bV().constructor.prototype):Object.create(new A.ax(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.e7(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.fg(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.e7(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
fg(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.d("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.fe)}throw A.d("Error in functionType of tearoff")},
fh(a,b,c,d){var t=A.e6
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
e7(a,b,c,d){if(c)return A.fj(a,b,d)
return A.fh(b.length,d,a,b)},
fi(a,b,c,d){var t=A.e6,s=A.ff
switch(b?-1:a){case 0:throw A.d(new A.bU("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
fj(a,b,c){var t,s
if($.e4==null)$.e4=A.e3("interceptor")
if($.e5==null)$.e5=A.e3("receiver")
t=b.length
s=A.fi(t,c,a,b)
return s},
dQ(a){return A.fk(a)},
fe(a,b){return A.bk(v.typeUniverse,A.a9(a.a),b)},
e6(a){return a.a},
ff(a){return a.b},
e3(a){var t,s,r,q=new A.ax("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.d(A.c6("Field name "+a+" not found."))},
hI(a){return v.getIsolateTag(a)},
hS(a){var t,s,r,q,p,o=A.P($.eL.$1(a)),n=$.d8[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.dv[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.dM($.eI.$2(a,o))
if(r!=null){n=$.d8[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.dv[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.dx(t)
$.d8[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.dv[o]=t
return t}if(q==="-"){p=A.dx(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.eQ(a,t)
if(q==="*")throw A.d(A.el(o))
if(v.leafTags[o]===true){p=A.dx(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.eQ(a,t)},
eQ(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.dV(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
dx(a){return J.dV(a,!1,null,!!a.$iR)},
hU(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.dx(t)
else return J.dV(t,c,null,null)},
hM(){if(!0===$.dT)return
$.dT=!0
A.hN()},
hN(){var t,s,r,q,p,o,n,m
$.d8=Object.create(null)
$.dv=Object.create(null)
A.hL()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.eR.$1(p)
if(o!=null){n=A.hU(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
hL(){var t,s,r,q,p,o,n=B.B()
n=A.aI(B.C,A.aI(B.D,A.aI(B.u,A.aI(B.u,A.aI(B.E,A.aI(B.F,A.aI(B.G(B.t),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.eL=new A.ds(q)
$.eI=new A.dt(p)
$.eR=new A.du(o)},
aI(a,b){return a(b)||b},
hE(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
hX(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
aF:function aF(a,b){this.a=a
this.b=b},
bg:function bg(a,b,c){this.a=a
this.b=b
this.c=c},
bz:function bz(){},
ai:function ai(a,b){this.a=a
this.$ti=b},
b4:function b4(){},
cR:function cR(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
b3:function b3(){},
bF:function bF(a,b,c){this.a=a
this.b=b
this.c=c},
bY:function bY(a){this.a=a},
cO:function cO(a){this.a=a},
K:function K(){},
bs:function bs(){},
bt:function bt(){},
bW:function bW(){},
bV:function bV(){},
ax:function ax(a,b){this.a=a
this.b=b},
bU:function bU(a){this.a=a},
a2:function a2(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
cG:function cG(a){this.a=a},
cK:function cK(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
ak:function ak(a,b){this.a=a
this.$ti=b},
aj:function aj(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
a3:function a3(a,b){this.a=a
this.$ti=b},
aX:function aX(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
ds:function ds(a){this.a=a},
dt:function dt(a){this.a=a},
du:function du(a){this.a=a},
a5:function a5(){},
aD:function aD(){},
aE:function aE(){},
a6(a,b,c){if(a>>>0!==a||a>=c)throw A.d(A.c5(b,a))},
aA:function aA(){},
b0:function b0(){},
bI:function bI(){},
aB:function aB(){},
aZ:function aZ(){},
b_:function b_(){},
bJ:function bJ(){},
bK:function bK(){},
bL:function bL(){},
bM:function bM(){},
bN:function bN(){},
bO:function bO(){},
bP:function bP(){},
b1:function b1(){},
bQ:function bQ(){},
bc:function bc(){},
bd:function bd(){},
be:function be(){},
bf:function bf(){},
dH(a,b){var t=b.c
return t==null?b.c=A.bi(a,"e9",[b.x]):t},
ei(a){var t=a.w
if(t===6||t===7)return A.ei(a.x)
return t===11||t===12},
fB(a){return a.as},
bl(a){return A.d_(v.typeUniverse,a,!1)},
hP(a,b){var t,s,r,q,p
if(a==null)return null
t=b.y
s=a.Q
if(s==null)s=a.Q=new Map()
r=b.as
q=s.get(r)
if(q!=null)return q
p=A.af(v.typeUniverse,a.x,t,0)
s.set(r,p)
return p},
af(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.af(a0,t,a2,a3)
if(s===t)return a1
return A.eu(a0,s,!0)
case 7:t=a1.x
s=A.af(a0,t,a2,a3)
if(s===t)return a1
return A.et(a0,s,!0)
case 8:r=a1.y
q=A.aH(a0,r,a2,a3)
if(q===r)return a1
return A.bi(a0,a1.x,q)
case 9:p=a1.x
o=A.af(a0,p,a2,a3)
n=a1.y
m=A.aH(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.dJ(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.aH(a0,k,a2,a3)
if(j===k)return a1
return A.ev(a0,l,j)
case 11:i=a1.x
h=A.af(a0,i,a2,a3)
g=a1.y
f=A.hv(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.es(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.aH(a0,e,a2,a3)
p=a1.x
o=A.af(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.dK(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.d(A.bp("Attempted to substitute unexpected RTI kind "+a))}},
aH(a,b,c,d){var t,s,r,q,p=b.length,o=A.d0(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.af(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
hw(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.d0(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.af(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
hv(a,b,c,d){var t,s=b.a,r=A.aH(a,s,c,d),q=b.b,p=A.aH(a,q,c,d),o=b.c,n=A.hw(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.c_()
t.a=r
t.b=p
t.c=n
return t},
j(a,b){a[v.arrayRti]=b
return a},
d7(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.hK(t)
return a.$S()}return null},
hO(a,b){var t
if(A.ei(b))if(a instanceof A.K){t=A.d7(a)
if(t!=null)return t}return A.a9(a)},
a9(a){if(a instanceof A.w)return A.t(a)
if(Array.isArray(a))return A.q(a)
return A.dN(J.ar(a))},
q(a){var t=a[v.arrayRti],s=u.n
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
t(a){var t=a.$ti
return t!=null?t:A.dN(a)},
dN(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.he(a,t)},
he(a,b){var t=a instanceof A.K?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.fZ(v.typeUniverse,t.name)
b.$ccache=s
return s},
hK(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.d_(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
hJ(a){return A.a7(A.t(a))},
dS(a){var t=A.d7(a)
return A.a7(t==null?A.a9(a):t)},
dP(a){var t
if(a instanceof A.a5)return A.hF(a.$r,a.a4())
t=a instanceof A.K?A.d7(a):null
if(t!=null)return t
if(u.x.b(a))return J.f7(a).a
if(Array.isArray(a))return A.q(a)
return A.a9(a)},
a7(a){var t=a.r
return t==null?a.r=new A.cZ(a):t},
hF(a,b){var t,s,r=b,q=r.length
if(q===0)return u.r
if(0>=q)return A.e(r,0)
t=A.bk(v.typeUniverse,A.dP(r[0]),"@<0>")
for(s=1;s<q;++s){if(!(s<r.length))return A.e(r,s)
t=A.ew(v.typeUniverse,t,A.dP(r[s]))}return A.bk(v.typeUniverse,t,a)},
a0(a){return A.a7(A.d_(v.typeUniverse,a,!1))},
hd(a){var t=this
t.b=A.hu(t)
return t.b(a)},
hu(a){var t,s,r,q,p
if(a===u.K)return A.hl
if(A.as(a))return A.hp
t=a.w
if(t===6)return A.hb
if(t===1)return A.eG
if(t===7)return A.hg
s=A.ht(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.as)){a.f="$i"+r
if(r==="c")return A.hj
if(a===u.m)return A.hi
return A.ho}}else if(t===10){q=A.hE(a.x,a.y)
p=q==null?A.eG:q
return p==null?A.eB(p):p}return A.h9},
ht(a){if(a.w===8){if(a===u.p)return A.c4
if(a===u.i||a===u.H)return A.hk
if(a===u.N)return A.hn
if(a===u.y)return A.dO}return null},
hc(a){var t=this,s=A.h8
if(A.as(t))s=A.h4
else if(t===u.K)s=A.eB
else if(A.aJ(t)){s=A.ha
if(t===u.I)s=A.J
else if(t===u.aD)s=A.dM
else if(t===u.u)s=A.h0
else if(t===u.ae)s=A.eA
else if(t===u.dd)s=A.h1
else if(t===u.M)s=A.h3}else if(t===u.p)s=A.f
else if(t===u.N)s=A.P
else if(t===u.y)s=A.c3
else if(t===u.H)s=A.dL
else if(t===u.i)s=A.ez
else if(t===u.m)s=A.h2
t.a=s
return t.a(a)},
h9(a){var t=this
if(a==null)return A.aJ(t)
return A.eM(v.typeUniverse,A.hO(a,t),t)},
hb(a){if(a==null)return!0
return this.x.b(a)},
ho(a){var t,s=this
if(a==null)return A.aJ(s)
t=s.f
if(a instanceof A.w)return!!a[t]
return!!J.ar(a)[t]},
hj(a){var t,s=this
if(a==null)return A.aJ(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.w)return!!a[t]
return!!J.ar(a)[t]},
hi(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.w)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
eF(a){if(typeof a=="object"){if(a instanceof A.w)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
h8(a){var t=this
if(a==null){if(A.aJ(t))return a}else if(t.b(a))return a
throw A.F(A.eC(a,t),new Error())},
ha(a){var t=this
if(a==null||t.b(a))return a
throw A.F(A.eC(a,t),new Error())},
eC(a,b){return new A.aG("TypeError: "+A.em(a,A.N(b,null)))},
eK(a,b,c,d){if(A.eM(v.typeUniverse,a,b))return a
throw A.F(A.fR("The type argument '"+A.N(a,null)+"' is not a subtype of the type variable bound '"+A.N(b,null)+"' of type variable '"+c+"' in '"+d+"'."),new Error())},
em(a,b){return A.bx(a)+": type '"+A.N(A.dP(a),null)+"' is not a subtype of type '"+b+"'"},
fR(a){return new A.aG("TypeError: "+a)},
V(a,b){return new A.aG("TypeError: "+A.em(a,b))},
hg(a){var t=this
return t.x.b(a)||A.dH(v.typeUniverse,t).b(a)},
hl(a){return a!=null},
eB(a){if(a!=null)return a
throw A.F(A.V(a,"Object"),new Error())},
hp(a){return!0},
h4(a){return a},
eG(a){return!1},
dO(a){return!0===a||!1===a},
c3(a){if(!0===a)return!0
if(!1===a)return!1
throw A.F(A.V(a,"bool"),new Error())},
h0(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.F(A.V(a,"bool?"),new Error())},
ez(a){if(typeof a=="number")return a
throw A.F(A.V(a,"double"),new Error())},
h1(a){if(typeof a=="number")return a
if(a==null)return a
throw A.F(A.V(a,"double?"),new Error())},
c4(a){return typeof a=="number"&&Math.floor(a)===a},
f(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.F(A.V(a,"int"),new Error())},
J(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.F(A.V(a,"int?"),new Error())},
hk(a){return typeof a=="number"},
dL(a){if(typeof a=="number")return a
throw A.F(A.V(a,"num"),new Error())},
eA(a){if(typeof a=="number")return a
if(a==null)return a
throw A.F(A.V(a,"num?"),new Error())},
hn(a){return typeof a=="string"},
P(a){if(typeof a=="string")return a
throw A.F(A.V(a,"String"),new Error())},
dM(a){if(typeof a=="string")return a
if(a==null)return a
throw A.F(A.V(a,"String?"),new Error())},
h2(a){if(A.eF(a))return a
throw A.F(A.V(a,"JSObject"),new Error())},
h3(a){if(a==null)return a
if(A.eF(a))return a
throw A.F(A.V(a,"JSObject?"),new Error())},
eH(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.N(a[r],b)
return t},
hs(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.eH(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.N(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
eD(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.j([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.a.q(a3,"T"+(s+r))
for(q=u.X,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.e(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.N(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.N(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.N(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.N(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.N(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
N(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.N(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.N(a.x,b)+">"
if(m===8){q=A.hx(a.x)
p=a.y
return p.length>0?q+("<"+A.eH(p,b)+">"):q}if(m===10)return A.hs(a,b)
if(m===11)return A.eD(a,b,null)
if(m===12)return A.eD(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.e(b,o)
return b[o]}return"?"},
hx(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
h_(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
fZ(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.d_(a,b,!1)
else if(typeof n=="number"){t=n
s=A.bj(a,5,"#")
r=A.d0(t)
for(q=0;q<t;++q)r[q]=s
p=A.bi(a,b,r)
o[b]=p
return p}else return n},
fY(a,b){return A.ex(a.tR,b)},
fX(a,b){return A.ex(a.eT,b)},
d_(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.eq(A.eo(a,null,b,!1))
s.set(b,t)
return t},
bk(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.eq(A.eo(a,b,c,!0))
r.set(c,s)
return s},
ew(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.dJ(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
ae(a,b){b.a=A.hc
b.b=A.hd
return b},
bj(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.Y(null,null)
t.w=b
t.as=c
s=A.ae(a,t)
a.eC.set(c,s)
return s},
eu(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.fV(a,b,s,c)
a.eC.set(s,t)
return t},
fV(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.as(b))if(!(b===u.P||b===u.T))if(t!==6)s=t===7&&A.aJ(b.x)
if(s)return b
else if(t===1)return u.P}r=new A.Y(null,null)
r.w=6
r.x=b
r.as=c
return A.ae(a,r)},
et(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.fT(a,b,s,c)
a.eC.set(s,t)
return t},
fT(a,b,c,d){var t,s
if(d){t=b.w
if(A.as(b)||b===u.K)return b
else if(t===1)return A.bi(a,"e9",[b])
else if(b===u.P||b===u.T)return u.G}s=new A.Y(null,null)
s.w=7
s.x=b
s.as=c
return A.ae(a,s)},
fW(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.Y(null,null)
t.w=13
t.x=b
t.as=r
s=A.ae(a,t)
a.eC.set(r,s)
return s},
bh(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
fS(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
bi(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.bh(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.Y(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.ae(a,s)
a.eC.set(q,r)
return r},
dJ(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.bh(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.Y(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.ae(a,p)
a.eC.set(r,o)
return o},
ev(a,b,c){var t,s,r="+"+(b+"("+A.bh(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.Y(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.ae(a,t)
a.eC.set(r,s)
return s},
es(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.bh(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.bh(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.fS(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.Y(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.ae(a,q)
a.eC.set(s,p)
return p},
dK(a,b,c,d){var t,s=b.as+("<"+A.bh(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.fU(a,b,c,s,d)
a.eC.set(s,t)
return t},
fU(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.d0(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.af(a,b,s,0)
n=A.aH(a,c,s,0)
return A.dK(a,o,n,c!==n)}}m=new A.Y(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.ae(a,m)},
eo(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
eq(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.fM(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.ep(a,s,m,l,!1)
else if(r===46)s=A.ep(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.aq(a.u,a.e,l.pop()))
break
case 94:l.push(A.fW(a.u,l.pop()))
break
case 35:l.push(A.bj(a.u,5,"#"))
break
case 64:l.push(A.bj(a.u,2,"@"))
break
case 126:l.push(A.bj(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.fO(a,l)
break
case 38:A.fN(a,l)
break
case 63:q=a.u
l.push(A.eu(q,A.aq(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.et(q,A.aq(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.fL(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.er(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.fQ(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-2)
break
case 43:o=m.indexOf("(",s)
l.push(m.substring(s,o))
l.push(-4)
l.push(a.p)
a.p=l.length
s=o+1
break
default:throw"Bad character "+r}}}n=l.pop()
return A.aq(a.u,a.e,n)},
fM(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
ep(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.h_(t,p.x)[q]
if(o==null)A.dW('No "'+q+'" in "'+A.fB(p)+'"')
d.push(A.bk(t,p,o))}else d.push(q)
return n},
fO(a,b){var t,s=a.u,r=A.en(a,b),q=b.pop()
if(typeof q=="string")b.push(A.bi(s,q,r))
else{t=A.aq(s,a.e,q)
switch(t.w){case 11:b.push(A.dK(s,t,r,a.n))
break
default:b.push(A.dJ(s,t,r))
break}}},
fL(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.en(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.aq(q,a.e,p)
r=new A.c_()
r.a=t
r.b=o
r.c=n
b.push(A.es(q,s,r))
return
case-4:b.push(A.ev(q,b.pop(),t))
return
default:throw A.d(A.bp("Unexpected state under `()`: "+A.u(p)))}},
fN(a,b){var t=b.pop()
if(0===t){b.push(A.bj(a.u,1,"0&"))
return}if(1===t){b.push(A.bj(a.u,4,"1&"))
return}throw A.d(A.bp("Unexpected extended operation "+A.u(t)))},
en(a,b){var t=b.splice(a.p)
A.er(a.u,a.e,t)
a.p=b.pop()
return t},
aq(a,b,c){if(typeof c=="string")return A.bi(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.fP(a,b,c)}else return c},
er(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.aq(a,b,c[t])},
fQ(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.aq(a,b,c[t])},
fP(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.d(A.bp("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.d(A.bp("Bad index "+c+" for "+b.j(0)))},
eM(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.C(a,b,null,c,null)
s.set(c,t)}return t},
C(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.as(d))return!0
t=b.w
if(t===4)return!0
if(A.as(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.C(a,c[b.x],c,d,e))return!0
r=d.w
q=u.P
if(b===q||b===u.T){if(r===7)return A.C(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.C(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.C(a,b.x,c,d,e))return!1
return A.C(a,A.dH(a,b),c,d,e)}if(t===6)return A.C(a,q,c,d,e)&&A.C(a,b.x,c,d,e)
if(r===7){if(A.C(a,b,c,d.x,e))return!0
return A.C(a,b,c,A.dH(a,d),e)}if(r===6)return A.C(a,b,c,q,e)||A.C(a,b,c,d.x,e)
if(s)return!1
q=t!==11
if((!q||t===12)&&d===u.Z)return!0
p=t===10
if(p&&d===u.J)return!0
if(r===12){if(b===u.g)return!0
if(t!==12)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.C(a,k,c,j,e)||!A.C(a,j,e,k,c))return!1}return A.eE(a,b.x,c,d.x,e)}if(r===11){if(b===u.g)return!0
if(q)return!1
return A.eE(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.hh(a,b,c,d,e)}if(p&&r===10)return A.hm(a,b,c,d,e)
return!1},
eE(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.C(a2,a3.x,a4,a5.x,a6))return!1
t=a3.y
s=a5.y
r=t.a
q=s.a
p=r.length
o=q.length
if(p>o)return!1
n=o-p
m=t.b
l=s.b
k=m.length
j=l.length
if(p+k<o+j)return!1
for(i=0;i<p;++i){h=r[i]
if(!A.C(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.C(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.C(a2,l[i],a6,h,a4))return!1}g=t.c
f=s.c
e=g.length
d=f.length
for(c=0,b=0;b<d;b+=3){a=f[b]
for(;;){if(c>=e)return!1
a0=g[c]
c+=3
if(a<a0)return!1
a1=g[c-2]
if(a0<a){if(a1)return!1
continue}h=f[b+1]
if(a1&&!h)return!1
h=g[c-1]
if(!A.C(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
hh(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.bk(a,b,s[p])
return A.ey(a,q,null,c,d.y,e)}return A.ey(a,b.y,null,c,d.y,e)},
ey(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.C(a,b[t],d,e[t],f))return!1
return!0},
hm(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.C(a,s[t],c,r[t],e))return!1
return!0},
aJ(a){var t=a.w,s=!0
if(!(a===u.P||a===u.T))if(!A.as(a))if(t!==6)s=t===7&&A.aJ(a.x)
return s},
as(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.X},
ex(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
d0(a){return a>0?new Array(a):v.typeUniverse.sEA},
Y:function Y(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
c_:function c_(){this.c=this.b=this.a=null},
cZ:function cZ(a){this.a=a},
bZ:function bZ(){},
aG:function aG(a){this.a=a},
fu(a,b){return new A.a2(a.h("@<0>").A(b).h("a2<1,2>"))},
O(a,b,c){return b.h("@<0>").A(c).h("ee<1,2>").a(A.hH(a,new A.a2(b.h("@<0>").A(c).h("a2<1,2>"))))},
al(a,b){return new A.a2(a.h("@<0>").A(b).h("a2<1,2>"))},
dD(a,b,c){var t=A.fu(b,c)
a.I(0,new A.cL(t,b,c))
return t},
ef(a){var t,s
if(A.dU(a))return"{...}"
t=new A.ao("")
try{s={}
B.a.q($.S,a)
t.a+="{"
s.a=!0
a.I(0,new A.cN(s,t))
t.a+="}"}finally{if(0>=$.S.length)return A.e($.S,-1)
$.S.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
cL:function cL(a,b,c){this.a=a
this.b=b
this.c=c},
p:function p(){},
r:function r(){},
cM:function cM(a){this.a=a},
cN:function cN(a,b){this.a=a
this.b=b},
hr(a,b){var t,s,r,q=null
try{q=JSON.parse(a)}catch(s){t=A.eT(s)
r=A.e8(String(t))
throw A.d(r)}r=A.d1(q)
return r},
d1(a){var t
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.c1(a,Object.create(null))
for(t=0;t<a.length;++t)a[t]=A.d1(a[t])
return a},
ed(a,b,c){return new A.aV(a,b)},
h6(a){return a.O()},
fJ(a,b){return new A.cV(a,[],A.hD())},
fK(a,b,c){var t,s=new A.ao(""),r=A.fJ(s,b)
r.a0(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
c1:function c1(a,b){this.a=a
this.b=b
this.c=null},
c2:function c2(a){this.a=a},
bu:function bu(){},
bw:function bw(){},
aV:function aV(a,b){this.a=a
this.b=b},
bG:function bG(a,b){this.a=a
this.b=b},
cH:function cH(){},
cJ:function cJ(a){this.b=a},
cI:function cI(a){this.a=a},
cW:function cW(){},
cX:function cX(a,b){this.a=a
this.b=b},
cV:function cV(a,b,c){this.c=a
this.a=b
this.b=c},
hQ(a){var t=A.fx(a,null)
if(t!=null)return t
throw A.d(A.e8(a))},
bH(a,b,c,d){var t,s=c?J.ec(a,d):J.fr(a,d)
if(a!==0&&b!=null)for(t=0;t<s.length;++t)s[t]=b
return s},
fv(a,b,c){var t,s,r=A.j([],c.h("m<0>"))
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.a_)(a),++s)B.a.q(r,c.a(a[s]))
r.$flags=1
return r},
I(a,b){var t,s
if(Array.isArray(a))return A.j(a.slice(0),b.h("m<0>"))
t=A.j([],b.h("m<0>"))
for(s=J.ag(a);s.k();)B.a.q(t,s.gm())
return t},
fw(a,b,c){var t,s=J.ec(a,c)
for(t=0;t<a;++t)B.a.l(s,t,b.$1(t))
return s},
ej(a,b,c){var t=J.ag(b)
if(!t.k())return a
if(c.length===0){do a+=A.u(t.gm())
while(t.k())}else{a+=A.u(t.gm())
while(t.k())a=a+c+A.u(t.gm())}return a},
bx(a){if(typeof a=="number"||A.dO(a)||a==null)return J.aw(a)
if(typeof a=="string")return JSON.stringify(a)
return A.eh(a)},
bp(a){return new A.bo(a)},
c6(a){return new A.aa(!1,null,null,a)},
fy(a){var t=null
return new A.aC(t,t,!1,t,t,a)},
fz(a,b){return new A.aC(null,null,!0,a,b,"Value not in range")},
cP(a,b,c,d,e){return new A.aC(b,c,!0,a,d,"Invalid value")},
fA(a,b,c){if(0>a||a>c)throw A.d(A.cP(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.d(A.cP(b,a,c,"end",null))
return b}return c},
ea(a,b,c,d){return new A.by(b,!0,a,d,"Index out of range")},
fI(a){return new A.b9(a)},
el(a){return new A.bX(a)},
fC(a){return new A.b6(a)},
Q(a){return new A.bv(a)},
e8(a){return new A.aO(a)},
fq(a,b,c){var t,s
if(A.dU(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.j([],u.s)
B.a.q($.S,a)
try{A.hq(a,t)}finally{if(0>=$.S.length)return A.e($.S,-1)
$.S.pop()}s=A.ej(b,u.V.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
eb(a,b,c){var t,s
if(A.dU(a))return b+"..."+c
t=new A.ao(b)
B.a.q($.S,a)
try{s=t
s.a=A.ej(s.a,a,", ")}finally{if(0>=$.S.length)return A.e($.S,-1)
$.S.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
hq(a,b){var t,s,r,q,p,o,n,m=a.gp(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.k())return
t=A.u(m.gm())
B.a.q(b,t)
l+=t.length+2;++k}if(!m.k()){if(k<=5)return
if(0>=b.length)return A.e(b,-1)
s=b.pop()
if(0>=b.length)return A.e(b,-1)
r=b.pop()}else{q=m.gm();++k
if(!m.k()){if(k<=4){B.a.q(b,A.u(q))
return}s=A.u(q)
if(0>=b.length)return A.e(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gm();++k
for(;m.k();q=p,p=o){o=m.gm();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.e(b,-1)
l-=b.pop().length+2;--k}B.a.q(b,"...")
return}}r=A.u(q)
s=A.u(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.e(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.q(b,n)
B.a.q(b,r)
B.a.q(b,s)},
dF(a,b,c,d){var t
if(B.m===c){t=J.X(a)
b=J.X(b)
return A.dI(A.ad(A.ad($.dy(),t),b))}if(B.m===d){t=J.X(a)
b=J.X(b)
c=J.X(c)
return A.dI(A.ad(A.ad(A.ad($.dy(),t),b),c))}t=J.X(a)
b=J.X(b)
c=J.X(c)
d=J.X(d)
d=A.dI(A.ad(A.ad(A.ad(A.ad($.dy(),t),b),c),d))
return d},
v:function v(){},
bo:function bo(a){this.a=a},
b7:function b7(){},
aa:function aa(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
aC:function aC(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
by:function by(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
b9:function b9(a){this.a=a},
bX:function bX(a){this.a=a},
b6:function b6(a){this.a=a},
bv:function bv(a){this.a=a},
b5:function b5(){},
cT:function cT(a){this.a=a},
aO:function aO(a){this.a=a},
b:function b(){},
U:function U(a,b,c){this.a=a
this.b=b
this.$ti=c},
b2:function b2(){},
w:function w(){},
ao:function ao(a){this.a=a},
eO(a,b,c){A.eK(c,u.H,"T","min")
return Math.min(c.a(a),c.a(b))},
eN(a,b,c){A.eK(c,u.H,"T","max")
return Math.max(c.a(a),c.a(b))},
c0:function c0(){},
eJ(a,b){var t=2147483646,s={}
s.a=B.c.v(a+B.c.v(b,t)*104729,t)+1
return A.fw(3,new A.d6(s),u.k)},
hA(a,b){var t,s,r={}
r.a=144
t=a.c
s=A.I(b,u.k)
return new A.d2(r).$2(t,s)},
hG(b2,b3,b4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8=null,a9=2147483646,b0=new A.br(B.c.v(b2+B.c.v(b3,a9)*104729,a9)+1),b1=A.I(b4,u.W)
B.a.ai(b1,new A.di())
t=b1.length===0?0:B.c.aN(B.a.aB(b1,0,new A.dj(),u.p),b1.length)
for(s=A.q(b1),r=s.h("b<a>(1)"),q=s.h("L<1,a>"),p=s.h("a(1)"),o=s.h("x<1,a>"),n=s.h("k(1)"),s=s.h("z<1>"),m=u.A,l=u.I,k=u.B,j=u.k,i=a8,h=-1e4,g=0;g<16;++g){f=b1.length
e=f===0?a8:b1[B.c.v(B.c.V(g,2),f)]
d=A.aK(a8,b0)
d.e=t
if(e!=null){f=A.j([],k)
for(c=e.c,b=c.length,a=0;a<c.length;c.length===b||(0,A.a_)(c),++a){a0=A.I(c[a],l)
f.push(a0)}d.sP(f)}d.N()
f=J.e_(d.d,m)
a1=A.I(f,f.$ti.h("b.E"))
if(a1.length===3){f=A.q(a1)
f=new A.z(a1,f.h("k(1)").a(new A.dk()),f.h("z<1>")).gn(0)>1}else f=!0
if(f)continue
f=A.q(a1)
a2=new A.z(a1,f.h("k(1)").a(new A.dl()),f.h("z<1>")).gn(0)
a3=new A.z(b1,n.a(new A.dm(a1)),s).gn(0)
a4=new A.z(b1,n.a(new A.dn(a1)),s).gn(0)
a5=b1.length===0?3:new A.x(b1,p.a(new A.dp(a1)),o).M(0,B.o)
a6=b1.length===0?3:new A.L(b1,r.a(new A.dq(a1)),q).M(0,B.o)
f=Math.min(a5,2)
c=a2===3?20:0
a7=a3*100+a4*30+f*8+a6*4-c
if(a7>h){f=A.I(a1,j)
h=a7
i=f}if(a4===b1.length&&a5>=2&&a6>=2&&a2<3){b1=A.I(a1,j)
return b1}}if(i!=null)return i
return A.fb(a8,b0).d},
fa(a,b,c,d){return new A.D(a,c,b)},
e0(a,b,c){return new A.bq(a,b,c,A.j([],u.O),A.al(u.p,u.U),A.j([],u.Y))},
f9(a){var t,s,r,q,p,o,n,m,l,k,j="version"
if(!J.W(a.i(0,j),1)&&!J.W(a.i(0,j),2))throw A.d(B.H)
t=A.e0(A.P(a.i(0,"roomId")),A.f(a.i(0,"seed")),A.f(a.i(0,"createdAt")))
t.e=A.f(a.i(0,j))
s=a.i(0,"round")
t.f=A.f(s==null?1:s)
t.w=A.P(a.i(0,"status"))
t.x=A.f(a.i(0,"revision"))
t.y=A.J(a.i(0,"startAt"))
t.z=A.J(a.i(0,"endedAt"))
t.Q=A.J(a.i(0,"winner"))
t.as=A.dM(a.i(0,"reason"))
s=u.a5.a(a.i(0,"sets"))
if(s==null){s=u.z
s=A.al(s,s)}s=s.gaw()
s=s.gp(s)
r=u.V
q=t.r
p=u.b
while(s.k()){o=s.gm()
n=A.hQ(A.P(o.a))
m=A.j([],p)
for(o=J.ag(r.a(o.b));o.k();){l=o.gm()
if(l==null)k=null
else{k=J.dr(l)
k=new A.l(A.f(k.i(l,0)),A.f(k.i(l,1)))}m.push(k)}q.l(0,n,m)}for(s=J.ag(r.a(a.i(0,"players"))),r=t.d,q=u.f,p=u.N,o=u.z,n=t.gan();s.k();){m=A.dD(q.a(s.gm()),p,o)
k=t.b
l=new A.D(A.f(m.i(0,"id")),k,A.P(m.i(0,"name")))
l.f=A.f(m.i(0,"nextSet"))
l.r=A.f(m.i(0,"lives"))
l.w=A.f(m.i(0,"boardOuts"))
l.x=A.f(m.i(0,"thresholds"))
l.y=A.f(m.i(0,"damage"))
l.z=A.f(m.i(0,"lastMove"))
l.Q=A.c3(m.i(0,"ready"))
l.as=A.c3(m.i(0,"connected"))
k=m.i(0,"rematch")
l.at=A.c3(k==null?!1:k)
l.ax=A.J(m.i(0,"disconnectAt"))
m=A.fd(A.dD(q.a(m.i(0,"game")),p,o),l.ga8())
m.toString
l.e=m
l.sah(n)
if(!J.W(a.i(0,"damageStep"),500))l.x=B.c.V(l.e.e,500)
B.a.q(r,l)}return t},
d6:function d6(a){this.a=a},
br:function br(a){this.a=a},
d2:function d2(a){this.a=a},
d3:function d3(){},
d4:function d4(){},
d5:function d5(){},
di:function di(){},
da:function da(){},
db:function db(){},
dc:function dc(){},
dd:function dd(){},
de:function de(){},
df:function df(){},
dg:function dg(){},
dh:function dh(){},
dj:function dj(){},
dk:function dk(){},
dl:function dl(){},
dm:function dm(a){this.a=a},
dn:function dn(a){this.a=a},
dp:function dp(a){this.a=a},
dq:function dq(a){this.a=a},
d9:function d9(a){this.a=a},
D:function D(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.d=c
_.e=$
_.f=0
_.r=5
_.z=_.y=_.x=_.w=0
_.at=_.as=_.Q=!1
_.ax=null},
cl:function cl(a){this.a=a},
bq:function bq(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=2
_.f=1
_.r=e
_.w="waiting"
_.x=0
_.as=_.Q=_.z=_.y=null
_.at=f},
ca:function ca(a,b){this.a=a
this.b=b},
c9:function c9(){},
cc:function cc(){},
cb:function cb(a){this.a=a},
ci:function ci(a){this.a=a},
cf:function cf(a){this.a=a},
c7:function c7(){},
cd:function cd(a){this.a=a},
ce:function ce(){},
c8:function c8(a){this.a=a},
cg:function cg(){},
ch:function ch(a){this.a=a},
cj:function cj(){},
ck:function ck(){},
fb(a,b){var t,s,r,q=J.bC(8,u.R)
for(t=u.I,s=0;s<8;++s)q[s]=A.bH(8,null,!1,t)
t=A.j([null,null,null],u.b)
if(b==null)r=B.v
else r=b
t=new A.y(r,a,q,t)
t.N()
return t},
aK(a,b){var t,s,r,q=J.bC(8,u.R)
for(t=u.I,s=0;s<8;++s)q[s]=A.bH(8,null,!1,t)
t=A.j([null,null,null],u.b)
if(b==null)r=B.v
else r=b
return new A.y(r,a,q,t)},
dA(a){var t,s,r,q,p,o,n=u.t,m=A.j([],n)
for(t=0;t<8;++t){if(!(t<a.length))return A.e(a,t)
if(J.bn(a[t],new A.cm()))m.push(t)}n=A.j([],n)
for(s=u.e,r=0;r<8;++r){q=A.j(new Array(8),s)
for(p=a.length,t=0;t<8;++t){if(!(t<p))return A.e(a,t)
o=a[t]
if(!(r<o.length))return A.e(o,r)
q[t]=o[r]}if(B.a.H(q,new A.cn()))n.push(r)}return new A.aF(m,n)},
e1(a){var t,s,r,q,p,o,n=A.dA(a),m=n.a,l=n.b,k=u.p
k=A.al(k,k)
for(t=m.length,s=0;s<m.length;m.length===t||(0,A.a_)(m),++s){r=m[s]
for(q=r*8,p=0;p<8;++p){if(!(r<a.length))return A.e(a,r)
o=a[r]
if(!(p<o.length))return A.e(o,p)
o=o[p]
o.toString
k.l(0,q+p,o)}}for(t=l.length,s=0;s<l.length;l.length===t||(0,A.a_)(l),++s){p=l[s]
for(r=0;r<8;++r){if(!(r<a.length))return A.e(a,r)
q=a[r]
if(!(p<q.length))return A.e(q,p)
q=q[p]
q.toString
k.l(0,r*8+p,q)}}for(t=new A.aj(k,k.r,k.e,k.$ti.h("aj<1>"));t.k();){q=t.d
o=B.c.V(q,8)
if(!(o>=0&&o<a.length))return A.e(a,o)
J.bm(a[o],B.c.v(q,8),null)}return k},
fc(a){var t,s,r,q,p=A.j([],u.B)
for(t=a.length,s=u.I,r=0;r<a.length;a.length===t||(0,A.a_)(a),++r){q=A.I(a[r],s)
p.push(q)}return p},
e2(a,b,c,d){var t,s,r,q,p,o=b.a
if(!(o>=0&&o<33))return A.e(B.h,o)
o=B.h[o]
t=o.length
s=b.b
r=0
for(;r<t;++r){q=o[r]
p=c+q[0]
if(!(p>=0&&p<a.length))return A.e(a,p)
J.bm(a[p],d+q[1],s)}},
fd(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=null,e=null
try{if(!J.W(a.i(0,"version"),1))return f
k=u.j
j=J.dz(k.a(a.i(0,"grid")),new A.cy(),u.R)
i=A.I(j,j.$ti.h("E.E"))
t=i
if(J.av(t)!==8||J.dZ(t,new A.cz()))return f
k=J.dz(k.a(a.i(0,"tray")),new A.cA(),u.k)
k=A.I(k,k.$ti.h("E.E"))
s=k
if(J.av(s)!==3||J.bn(s,new A.cB()))return f
r=A.f(a.i(0,"score"))
q=A.f(a.i(0,"combo"))
p=A.f(a.i(0,"misses"))
h=A.J(a.i(0,"comboBonus"))
o=h==null?0:h
k=r
if(typeof k!=="number")return k.ag()
j=!0
if(!(k<0)){k=q
if(typeof k!=="number")return k.ag()
if(!(k<0)){k=p
if(typeof k!=="number")return k.ag()
if(!(k<0)){k=p
if(typeof k!=="number")return k.bq()
if(!(k>=3))k=J.W(q,0)&&!J.W(p,0)
else k=j}else k=j}else k=j}else k=j
if(k)return f
n=null
m=null
l=A.dA(t)
n=l.a
m=l.b
if(J.av(n)!==0||J.av(m)!==0)return f
k=A.aK(b,e)
k.sP(t)
k.saf(s)
k.saK(r)
k.sb0(q)
k.sbf(p)
k.sb1(o)
k.x=A.c3(a.i(0,"reviveUsed"))
return k}catch(g){return f}},
l:function l(a,b){this.a=a
this.b=b},
cE:function cE(){},
cD:function cD(){},
cC:function cC(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
y:function y(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.w=_.r=_.f=_.e=0
_.x=!1},
co:function co(a,b,c){this.a=a
this.b=b
this.c=c},
cp:function cp(a){this.a=a},
cm:function cm(){},
cn:function cn(){},
cr:function cr(){},
cq:function cq(){},
cs:function cs(){},
ct:function ct(){},
cu:function cu(){},
cv:function cv(a){this.a=a},
cw:function cw(){},
cy:function cy(){},
cx:function cx(){},
cz:function cz(){},
cA:function cA(){},
cB:function cB(){},
hT(){var t,s=v.G.globalThis,r=new A.dw()
if(typeof r=="function")A.dW(A.c6("Attempting to rewrap a JS function."))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.h5,r)
t[$.dY()]=r
s.blockBattleRules=t},
dw:function dw(){},
hY(a){throw A.F(new A.aW("Field '"+a+"' has been assigned during initialization."),new Error())},
dX(){throw A.F(A.ft(""),new Error())},
h5(a,b,c){u.Z.a(a)
if(A.f(c)>=1)return a.$1(b)
return a.$0()}},B={}
var w=[A,J,B]
var $={}
A.dB.prototype={}
J.bA.prototype={
D(a,b){return a===b},
gu(a){return A.bS(a)},
j(a){return"Instance of '"+A.bT(a)+"'"},
gt(a){return A.a7(A.dN(this))}}
J.bD.prototype={
j(a){return String(a)},
gu(a){return a?519018:218159},
gt(a){return A.a7(u.y)},
$io:1,
$ik:1}
J.aQ.prototype={
D(a,b){return null==b},
j(a){return"null"},
gu(a){return 0},
$io:1}
J.aT.prototype={$iA:1}
J.ac.prototype={
gu(a){return 0},
j(a){return String(a)}}
J.bR.prototype={}
J.b8.prototype={}
J.ab.prototype={
j(a){var t=a[$.dY()]
if(t==null)return this.aM(a)
return"JavaScript function for "+J.aw(t)},
$ia1:1}
J.aS.prototype={
gu(a){return 0},
j(a){return String(a)}}
J.aU.prototype={
gu(a){return 0},
j(a){return String(a)}}
J.m.prototype={
q(a,b){A.q(a).c.a(b)
a.$flags&1&&A.au(a,29)
a.push(b)},
a9(a,b){A.q(a).h("b<1>").a(b)
a.$flags&1&&A.au(a,"addAll",2)
this.aO(a,b)
return},
aO(a,b){var t,s
u.n.a(b)
t=b.length
if(t===0)return
if(a===b)throw A.d(A.Q(a))
for(s=0;s<t;++s)a.push(b[s])},
aa(a){a.$flags&1&&A.au(a,"clear","clear")
a.length=0},
S(a,b,c){var t=A.q(a)
return new A.x(a,t.A(c).h("1(2)").a(b),t.h("@<1>").A(c).h("x<1,2>"))},
bc(a,b){var t,s=A.bH(a.length,"",!1,u.N)
for(t=0;t<a.length;++t)this.l(s,t,A.u(a[t]))
return s.join(b)},
aB(a,b,c,d){var t,s,r
d.a(b)
A.q(a).A(d).h("1(1,2)").a(c)
t=a.length
for(s=b,r=0;r<t;++r){s=c.$2(s,a[r])
if(a.length!==t)throw A.d(A.Q(a))}return s},
az(a,b){var t,s,r
A.q(a).h("k(1)").a(b)
t=a.length
for(s=0;s<t;++s){r=a[s]
if(b.$1(r))return r
if(a.length!==t)throw A.d(A.Q(a))}throw A.d(A.ay())},
C(a,b){if(!(b<a.length))return A.e(a,b)
return a[b]},
gX(a){if(a.length>0)return a[0]
throw A.d(A.ay())},
gbe(a){var t=a.length
if(t>0)return a[t-1]
throw A.d(A.ay())},
J(a,b){var t,s
A.q(a).h("k(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(b.$1(a[s]))return!0
if(a.length!==t)throw A.d(A.Q(a))}return!1},
H(a,b){var t,s
A.q(a).h("k(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(!b.$1(a[s]))return!1
if(a.length!==t)throw A.d(A.Q(a))}return!0},
ai(a,b){var t,s,r,q,p,o=A.q(a)
o.h("a(1,1)?").a(b)
a.$flags&2&&A.au(a,"sort")
t=a.length
if(t<2)return
if(t===2){s=a[0]
r=a[1]
o=b.$2(s,r)
if(typeof o!=="number")return o.br()
if(o>0){a[0]=r
a[1]=s}return}q=0
if(o.c.b(null))for(p=0;p<a.length;++p)if(a[p]===void 0){a[p]=null;++q}a.sort(A.hB(b,2))
if(q>0)this.aT(a,q)},
aT(a,b){var t,s=a.length
for(;t=s-1,s>0;s=t)if(a[t]===null){a[t]=void 0;--b
if(b===0)break}},
aL(a,b){var t,s,r,q
a.$flags&2&&A.au(a,"shuffle")
t=a.length
while(t>1){s=b.ad(t);--t
r=a.length
if(!(t<r))return A.e(a,t)
q=a[t]
if(!(s>=0&&s<r))return A.e(a,s)
a[t]=a[s]
a[s]=q}},
gaC(a){return a.length!==0},
j(a){return A.eb(a,"[","]")},
gp(a){return new J.ah(a,a.length,A.q(a).h("ah<1>"))},
gu(a){return A.bS(a)},
gn(a){return a.length},
i(a,b){if(!(b>=0&&b<a.length))throw A.d(A.c5(a,b))
return a[b]},
l(a,b,c){A.q(a).c.a(c)
a.$flags&2&&A.au(a)
if(!(b>=0&&b<a.length))throw A.d(A.c5(a,b))
a[b]=c},
aH(a,b){return new A.ap(a,b.h("ap<0>"))},
$ih:1,
$ib:1,
$ic:1}
J.bB.prototype={
bm(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.bT(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.cF.prototype={}
J.ah.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.a_(r)
throw A.d(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0},
$iH:1}
J.aR.prototype={
G(a,b){var t
A.dL(b)
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){t=this.gac(b)
if(this.gac(a)===t)return 0
if(this.gac(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gac(a){return a===0?1/a<0:a<0},
aZ(a,b,c){if(B.c.G(b,c)>0)throw A.d(A.hz(b))
if(this.G(a,b)<0)return b
if(this.G(a,c)>0)return c
return a},
j(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gu(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
v(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
if(b<0)return t-b
else return t+b},
aN(a,b){if((a|0)===a)if(b>=1)return a/b|0
return this.ap(a,b)},
V(a,b){return(a|0)===a?a/b|0:this.ap(a,b)},
ap(a,b){var t=a/b
if(t>=-2147483648&&t<=2147483647)return t|0
if(t>0){if(t!==1/0)return Math.floor(t)}else if(t>-1/0)return Math.ceil(t)
throw A.d(A.fI("Result of truncating division is "+A.u(t)+": "+A.u(a)+" ~/ "+b))},
ao(a,b){var t
if(a>0)t=this.aV(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
aV(a,b){return b>31?0:a>>>b},
gt(a){return A.a7(u.H)},
$ii:1,
$iZ:1}
J.aP.prototype={
gt(a){return A.a7(u.p)},
$io:1,
$ia:1}
J.bE.prototype={
gt(a){return A.a7(u.i)},
$io:1}
J.az.prototype={
T(a,b,c){return a.substring(b,A.fA(b,c,a.length))},
G(a,b){var t
A.P(b)
if(a===b)t=0
else t=a<b?-1:1
return t},
j(a){return a},
gu(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gt(a){return A.a7(u.N)},
gn(a){return a.length},
i(a,b){if(b>=a.length)throw A.d(A.c5(a,b))
return a[b]},
$io:1,
$in:1}
A.aW.prototype={
j(a){return"LateInitializationError: "+this.a}}
A.cQ.prototype={}
A.h.prototype={}
A.E.prototype={
gp(a){var t=this
return new A.am(t,t.gn(t),A.t(t).h("am<E.E>"))},
gK(a){return this.gn(this)===0},
S(a,b,c){var t=A.t(this)
return new A.x(this,t.A(c).h("1(E.E)").a(b),t.h("@<E.E>").A(c).h("x<1,2>"))},
M(a,b){var t,s,r,q=this
A.t(q).h("E.E(E.E,E.E)").a(b)
t=q.gn(q)
if(t===0)throw A.d(A.ay())
s=q.C(0,0)
for(r=1;r<t;++r){s=b.$2(s,q.C(0,r))
if(t!==q.gn(q))throw A.d(A.Q(q))}return s}}
A.am.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t,s=this,r=s.a,q=J.dr(r),p=q.gn(r)
if(s.b!==p)throw A.d(A.Q(r))
t=s.c
if(t>=p){s.d=null
return!1}s.d=q.C(r,t);++s.c
return!0},
$iH:1}
A.an.prototype={
gp(a){var t=this.a
return new A.aY(t.gp(t),this.b,A.t(this).h("aY<1,2>"))},
gn(a){var t=this.a
return t.gn(t)}}
A.aL.prototype={$ih:1}
A.aY.prototype={
k(){var t=this,s=t.b
if(s.k()){t.a=t.c.$1(s.gm())
return!0}t.a=null
return!1},
gm(){var t=this.a
return t==null?this.$ti.y[1].a(t):t},
$iH:1}
A.x.prototype={
gn(a){return J.av(this.a)},
C(a,b){return this.b.$1(J.f5(this.a,b))}}
A.z.prototype={
gp(a){return new A.ba(J.ag(this.a),this.b,this.$ti.h("ba<1>"))}}
A.ba.prototype={
k(){var t,s
for(t=this.a,s=this.b;t.k();)if(s.$1(t.gm()))return!0
return!1},
gm(){return this.a.gm()},
$iH:1}
A.L.prototype={
gp(a){return new A.aN(J.ag(this.a),this.b,B.A,this.$ti.h("aN<1,2>"))}}
A.aN.prototype={
gm(){var t=this.d
return t==null?this.$ti.y[1].a(t):t},
k(){var t,s,r=this,q=r.c
if(q==null)return!1
for(t=r.a,s=r.b;!q.k();){r.d=null
if(t.k()){r.c=null
q=J.ag(s.$1(t.gm()))
r.c=q}else return!1}r.d=r.c.gm()
return!0},
$iH:1}
A.aM.prototype={
k(){return!1},
gm(){throw A.d(A.ay())},
$iH:1}
A.ap.prototype={
gp(a){return new A.bb(J.ag(this.a),this.$ti.h("bb<1>"))}}
A.bb.prototype={
k(){var t,s
for(t=this.a,s=this.$ti.c;t.k();)if(s.b(t.gm()))return!0
return!1},
gm(){return this.$ti.c.a(this.a.gm())},
$iH:1}
A.M.prototype={}
A.aF.prototype={$r:"+(1,2)",$s:1}
A.bg.prototype={$r:"+(1,2,3)",$s:2}
A.bz.prototype={
D(a,b){if(b==null)return!1
return b instanceof A.ai&&this.a.D(0,b.a)&&A.dS(this)===A.dS(b)},
gu(a){return A.dF(this.a,A.dS(this),B.m,B.m)},
j(a){var t=B.a.bc([A.a7(this.$ti.c)],", ")
return this.a.j(0)+" with "+("<"+t+">")}}
A.ai.prototype={
$2(a,b){return this.a.$1$2(a,b,this.$ti.y[0])},
$S(){return A.hP(A.d7(this.a),this.$ti)}}
A.b4.prototype={}
A.cR.prototype={
B(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
if(q==null)return null
t=Object.create(null)
s=r.b
if(s!==-1)t.arguments=q[s+1]
s=r.c
if(s!==-1)t.argumentsExpr=q[s+1]
s=r.d
if(s!==-1)t.expr=q[s+1]
s=r.e
if(s!==-1)t.method=q[s+1]
s=r.f
if(s!==-1)t.receiver=q[s+1]
return t}}
A.b3.prototype={
j(a){return"Null check operator used on a null value"}}
A.bF.prototype={
j(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.bY.prototype={
j(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.cO.prototype={
j(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.K.prototype={
j(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.eS(s==null?"unknown":s)+"'"},
$ia1:1,
gbp(){return this},
$C:"$1",
$R:1,
$D:null}
A.bs.prototype={$C:"$0",$R:0}
A.bt.prototype={$C:"$2",$R:2}
A.bW.prototype={}
A.bV.prototype={
j(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.eS(t)+"'"}}
A.ax.prototype={
D(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.ax))return!1
return this.$_target===b.$_target&&this.a===b.a},
gu(a){return(A.eP(this.a)^A.bS(this.$_target))>>>0},
j(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.bT(this.a)+"'")}}
A.bU.prototype={
j(a){return"RuntimeError: "+this.a}}
A.a2.prototype={
gn(a){return this.a},
gK(a){return this.a===0},
gE(){return new A.ak(this,A.t(this).h("ak<1>"))},
gaw(){return new A.a3(this,A.t(this).h("a3<1,2>"))},
W(a){var t,s
if(typeof a=="string"){t=this.b
if(t==null)return!1
return t[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){s=this.c
if(s==null)return!1
return s[a]!=null}else return this.b8(a)},
b8(a){var t=this.d
if(t==null)return!1
return this.Z(t[this.Y(a)],a)>=0},
a9(a,b){A.t(this).h("T<1,2>").a(b).I(0,new A.cG(this))},
i(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.b9(b)},
b9(a){var t,s,r=this.d
if(r==null)return null
t=r[this.Y(a)]
s=this.Z(t,a)
if(s<0)return null
return t[s].b},
l(a,b,c){var t,s,r=this,q=A.t(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.aj(t==null?r.b=r.a6():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.aj(s==null?r.c=r.a6():s,b,c)}else r.bb(b,c)},
bb(a,b){var t,s,r,q,p=this,o=A.t(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.a6()
s=p.Y(a)
r=t[s]
if(r==null)t[s]=[p.a7(a,b)]
else{q=p.Z(r,a)
if(q>=0)r[q].b=b
else r.push(p.a7(a,b))}},
bh(a,b){var t,s,r=this,q=A.t(r)
q.c.a(a)
q.h("2()").a(b)
if(r.W(a)){t=r.i(0,a)
return t==null?q.y[1].a(t):t}s=b.$0()
r.l(0,a,s)
return s},
ae(a,b){var t=this
if(typeof b=="string")return t.am(t.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return t.am(t.c,b)
else return t.ba(b)},
ba(a){var t,s,r,q,p=this,o=p.d
if(o==null)return null
t=p.Y(a)
s=o[t]
r=p.Z(s,a)
if(r<0)return null
q=s.splice(r,1)[0]
p.ar(q)
if(s.length===0)delete o[t]
return q.b},
aa(a){var t=this
if(t.a>0){t.b=t.c=t.d=t.e=t.f=null
t.a=0
t.a5()}},
I(a,b){var t,s,r=this
A.t(r).h("~(1,2)").a(b)
t=r.e
s=r.r
while(t!=null){b.$2(t.a,t.b)
if(s!==r.r)throw A.d(A.Q(r))
t=t.c}},
aj(a,b,c){var t,s=A.t(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.a7(b,c)
else t.b=c},
am(a,b){var t
if(a==null)return null
t=a[b]
if(t==null)return null
this.ar(t)
delete a[b]
return t.b},
a5(){this.r=this.r+1&1073741823},
a7(a,b){var t=this,s=A.t(t),r=new A.cK(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else{s=t.f
s.toString
r.d=s
t.f=s.c=r}++t.a
t.a5()
return r},
ar(a){var t=this,s=a.d,r=a.c
if(s==null)t.e=r
else s.c=r
if(r==null)t.f=s
else r.d=s;--t.a
t.a5()},
Y(a){return J.X(a)&1073741823},
Z(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.W(a[s].a,b))return s
return-1},
j(a){return A.ef(this)},
a6(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$iee:1}
A.cG.prototype={
$2(a,b){var t=this.a,s=A.t(t)
t.l(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.t(this.a).h("~(1,2)")}}
A.cK.prototype={}
A.ak.prototype={
gn(a){return this.a.a},
gK(a){return this.a.a===0},
gp(a){var t=this.a
return new A.aj(t,t.r,t.e,this.$ti.h("aj<1>"))}}
A.aj.prototype={
gm(){return this.d},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.d(A.Q(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.a
s.c=t.c
return!0}},
$iH:1}
A.a3.prototype={
gn(a){return this.a.a},
gp(a){var t=this.a
return new A.aX(t,t.r,t.e,this.$ti.h("aX<1,2>"))}}
A.aX.prototype={
gm(){var t=this.d
t.toString
return t},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.d(A.Q(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=new A.U(t.a,t.b,s.$ti.h("U<1,2>"))
s.c=t.c
return!0}},
$iH:1}
A.ds.prototype={
$1(a){return this.a(a)},
$S:9}
A.dt.prototype={
$2(a,b){return this.a(a,b)},
$S:28}
A.du.prototype={
$1(a){return this.a(A.P(a))},
$S:19}
A.a5.prototype={
j(a){return this.aq(!1)},
aq(a){var t,s,r,q,p,o=this.aQ(),n=this.a4(),m=(a?"Record ":"")+"("
for(t=o.length,s="",r=0;r<t;++r,s=", "){m+=s
q=o[r]
if(typeof q=="string")m=m+q+": "
if(!(r<n.length))return A.e(n,r)
p=n[r]
m=a?m+A.eh(p):m+A.u(p)}m+=")"
return m.charCodeAt(0)==0?m:m},
aQ(){var t,s=this.$s
while($.cY.length<=s)B.a.q($.cY,null)
t=$.cY[s]
if(t==null){t=this.aP()
B.a.l($.cY,s,t)}return t},
aP(){var t,s,r,q=this.$r,p=q.indexOf("("),o=q.substring(1,p),n=q.substring(p),m=n==="()"?0:n.replace(/[^,]/g,"").length+1,l=u.K,k=J.bC(m,l)
for(t=0;t<m;++t)k[t]=t
if(o!==""){s=o.split(",")
t=s.length
for(r=m;t>0;){--r;--t
B.a.l(k,r,s[t])}}k=A.fv(k,!1,l)
k.$flags=3
return k}}
A.aD.prototype={
a4(){return[this.a,this.b]},
D(a,b){if(b==null)return!1
return b instanceof A.aD&&this.$s===b.$s&&J.W(this.a,b.a)&&J.W(this.b,b.b)},
gu(a){return A.dF(this.$s,this.a,this.b,B.m)}}
A.aE.prototype={
a4(){return[this.a,this.b,this.c]},
D(a,b){var t=this
if(b==null)return!1
return b instanceof A.aE&&t.$s===b.$s&&J.W(t.a,b.a)&&J.W(t.b,b.b)&&J.W(t.c,b.c)},
gu(a){var t=this
return A.dF(t.$s,t.a,t.b,t.c)}}
A.aA.prototype={
gt(a){return B.an},
$io:1}
A.b0.prototype={}
A.bI.prototype={
gt(a){return B.ao},
$io:1}
A.aB.prototype={
gn(a){return a.length},
$iR:1}
A.aZ.prototype={
i(a,b){A.a6(b,a,a.length)
return a[b]},
l(a,b,c){A.ez(c)
a.$flags&2&&A.au(a)
A.a6(b,a,a.length)
a[b]=c},
$ih:1,
$ib:1,
$ic:1}
A.b_.prototype={
l(a,b,c){A.f(c)
a.$flags&2&&A.au(a)
A.a6(b,a,a.length)
a[b]=c},
$ih:1,
$ib:1,
$ic:1}
A.bJ.prototype={
gt(a){return B.ap},
$io:1}
A.bK.prototype={
gt(a){return B.aq},
$io:1}
A.bL.prototype={
gt(a){return B.ar},
i(a,b){A.a6(b,a,a.length)
return a[b]},
$io:1}
A.bM.prototype={
gt(a){return B.as},
i(a,b){A.a6(b,a,a.length)
return a[b]},
$io:1}
A.bN.prototype={
gt(a){return B.at},
i(a,b){A.a6(b,a,a.length)
return a[b]},
$io:1}
A.bO.prototype={
gt(a){return B.av},
i(a,b){A.a6(b,a,a.length)
return a[b]},
$io:1}
A.bP.prototype={
gt(a){return B.aw},
i(a,b){A.a6(b,a,a.length)
return a[b]},
$io:1}
A.b1.prototype={
gt(a){return B.ax},
gn(a){return a.length},
i(a,b){A.a6(b,a,a.length)
return a[b]},
$io:1}
A.bQ.prototype={
gt(a){return B.ay},
gn(a){return a.length},
i(a,b){A.a6(b,a,a.length)
return a[b]},
$io:1}
A.bc.prototype={}
A.bd.prototype={}
A.be.prototype={}
A.bf.prototype={}
A.Y.prototype={
h(a){return A.bk(v.typeUniverse,this,a)},
A(a){return A.ew(v.typeUniverse,this,a)}}
A.c_.prototype={}
A.cZ.prototype={
j(a){return A.N(this.a,null)}}
A.bZ.prototype={
j(a){return this.a}}
A.aG.prototype={}
A.cL.prototype={
$2(a,b){this.a.l(0,this.b.a(a),this.c.a(b))},
$S:23}
A.p.prototype={
gp(a){return new A.am(a,a.length,A.a9(a).h("am<p.E>"))},
C(a,b){if(!(b<a.length))return A.e(a,b)
return a[b]},
gaC(a){return a.length!==0},
H(a,b){var t,s,r
A.a9(a).h("k(p.E)").a(b)
t=a.length
for(s=t,r=0;r<t;++r){if(!(r<s))return A.e(a,r)
if(!b.$1(a[r]))return!1
s=a.length
if(t!==s)throw A.d(A.Q(a))}return!0},
J(a,b){var t,s,r
A.a9(a).h("k(p.E)").a(b)
t=a.length
for(s=t,r=0;r<t;++r){if(!(r<s))return A.e(a,r)
if(b.$1(a[r]))return!0
s=a.length
if(t!==s)throw A.d(A.Q(a))}return!1},
aH(a,b){return new A.ap(a,b.h("ap<0>"))},
S(a,b,c){var t=A.a9(a)
return new A.x(a,t.A(c).h("1(p.E)").a(b),t.h("@<p.E>").A(c).h("x<1,2>"))},
j(a){return A.eb(a,"[","]")}}
A.r.prototype={
I(a,b){var t,s,r,q=A.t(this)
q.h("~(r.K,r.V)").a(b)
for(t=this.gE(),t=t.gp(t),q=q.h("r.V");t.k();){s=t.gm()
r=this.i(0,s)
b.$2(s,r==null?q.a(r):r)}},
gaw(){return this.gE().S(0,new A.cM(this),A.t(this).h("U<r.K,r.V>"))},
bk(a,b){var t,s,r,q,p,o=this,n=A.t(o)
n.h("k(r.K,r.V)").a(b)
t=A.j([],n.h("m<r.K>"))
for(s=o.gE(),s=s.gp(s),n=n.h("r.V");s.k();){r=s.gm()
q=o.i(0,r)
if(b.$2(r,q==null?n.a(q):q))B.a.q(t,r)}for(n=t.length,p=0;p<t.length;t.length===n||(0,A.a_)(t),++p)o.ae(0,t[p])},
gn(a){var t=this.gE()
return t.gn(t)},
gK(a){var t=this.gE()
return t.gK(t)},
j(a){return A.ef(this)},
$iT:1}
A.cM.prototype={
$1(a){var t=this.a,s=A.t(t)
s.h("r.K").a(a)
t=t.i(0,a)
if(t==null)t=s.h("r.V").a(t)
return new A.U(a,t,s.h("U<r.K,r.V>"))},
$S(){return A.t(this.a).h("U<r.K,r.V>(r.K)")}}
A.cN.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.u(a)
s.a=(s.a+=t)+": "
t=A.u(b)
s.a+=t},
$S:7}
A.c1.prototype={
i(a,b){var t,s=this.b
if(s==null)return this.c.i(0,b)
else if(typeof b!="string")return null
else{t=s[b]
return typeof t=="undefined"?this.aS(b):t}},
gn(a){return this.b==null?this.c.a:this.R().length},
gK(a){return this.gn(0)===0},
gE(){if(this.b==null){var t=this.c
return new A.ak(t,A.t(t).h("ak<1>"))}return new A.c2(this)},
W(a){if(this.b==null)return this.c.W(a)
if(typeof a!="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
ae(a,b){if(this.b!=null&&!this.W(b))return null
return this.aX().ae(0,b)},
I(a,b){var t,s,r,q,p=this
u.cQ.a(b)
if(p.b==null)return p.c.I(0,b)
t=p.R()
for(s=0;s<t.length;++s){r=t[s]
q=p.b[r]
if(typeof q=="undefined"){q=A.d1(p.a[r])
p.b[r]=q}b.$2(r,q)
if(t!==p.c)throw A.d(A.Q(p))}},
R(){var t=u.aL.a(this.c)
if(t==null)t=this.c=A.j(Object.keys(this.a),u.s)
return t},
aX(){var t,s,r,q,p,o=this
if(o.b==null)return o.c
t=A.al(u.N,u.z)
s=o.R()
for(r=0;q=s.length,r<q;++r){p=s[r]
t.l(0,p,o.i(0,p))}if(q===0)B.a.q(s,"")
else B.a.aa(s)
o.a=o.b=null
return o.c=t},
aS(a){var t
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
t=A.d1(this.a[a])
return this.b[a]=t}}
A.c2.prototype={
gn(a){return this.a.gn(0)},
C(a,b){var t=this.a
if(t.b==null)t=t.gE().C(0,b)
else{t=t.R()
if(!(b<t.length))return A.e(t,b)
t=t[b]}return t},
gp(a){var t=this.a
if(t.b==null){t=t.gE()
t=t.gp(t)}else{t=t.R()
t=new J.ah(t,t.length,A.q(t).h("ah<1>"))}return t}}
A.bu.prototype={}
A.bw.prototype={}
A.aV.prototype={
j(a){var t=A.bx(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.bG.prototype={
j(a){return"Cyclic error in JSON stringify"}}
A.cH.prototype={
b2(a,b){var t=A.hr(a,this.gb3().a)
return t},
av(a,b){var t=A.fK(a,this.gb5().b,null)
return t},
gb5(){return B.N},
gb3(){return B.M}}
A.cJ.prototype={}
A.cI.prototype={}
A.cW.prototype={
aJ(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.n.T(a,s,r)
s=r+1
p=A.G(92)
t.a+=p
p=A.G(117)
t.a+=p
p=A.G(100)
t.a+=p
p=q>>>8&15
p=A.G(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.G(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.G(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.n.T(a,s,r)
s=r+1
p=A.G(92)
t.a+=p
switch(q){case 8:p=A.G(98)
t.a+=p
break
case 9:p=A.G(116)
t.a+=p
break
case 10:p=A.G(110)
t.a+=p
break
case 12:p=A.G(102)
t.a+=p
break
case 13:p=A.G(114)
t.a+=p
break
default:p=A.G(117)
t.a+=p
p=A.G(48)
t.a=(t.a+=p)+p
p=q>>>4&15
p=A.G(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.G(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.n.T(a,s,r)
s=r+1
p=A.G(92)
t.a+=p
p=A.G(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.n.T(a,s,n)},
a1(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.d(new A.bG(a,null))}B.a.q(t,a)},
a0(a){var t,s,r,q,p=this
if(p.aI(a))return
p.a1(a)
try{t=p.b.$1(a)
if(!p.aI(t)){r=A.ed(a,null,p.gal())
throw A.d(r)}r=p.a
if(0>=r.length)return A.e(r,-1)
r.pop()}catch(q){s=A.eT(q)
r=A.ed(a,s,p.gal())
throw A.d(r)}},
aI(a){var t,s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.c.a+=B.J.j(a)
return!0}else if(a===!0){r.c.a+="true"
return!0}else if(a===!1){r.c.a+="false"
return!0}else if(a==null){r.c.a+="null"
return!0}else if(typeof a=="string"){t=r.c
t.a+='"'
r.aJ(a)
t.a+='"'
return!0}else if(u.j.b(a)){r.a1(a)
r.bn(a)
t=r.a
if(0>=t.length)return A.e(t,-1)
t.pop()
return!0}else if(a instanceof A.r){r.a1(a)
s=r.bo(a)
t=r.a
if(0>=t.length)return A.e(t,-1)
t.pop()
return s}else return!1},
bn(a){var t,s=this.c
s.a+="["
if(J.f6(a)){if(0>=a.length)return A.e(a,0)
this.a0(a[0])
for(t=1;t<a.length;++t){s.a+=","
this.a0(a[t])}}s.a+="]"},
bo(a){var t,s,r,q,p,o,n=this,m={}
if(a.gK(a)){n.c.a+="{}"
return!0}t=a.gn(a)*2
s=A.bH(t,null,!1,u.X)
r=m.a=0
m.b=!0
a.I(0,new A.cX(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.aJ(A.P(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.e(s,o)
n.a0(s[o])}q.a+="}"
return!0}}
A.cX.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.a.l(t,s.a++,a)
B.a.l(t,s.a++,b)},
$S:7}
A.cV.prototype={
gal(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.v.prototype={}
A.bo.prototype={
j(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.bx(t)
return"Assertion failed"}}
A.b7.prototype={}
A.aa.prototype={
ga3(){return"Invalid argument"+(!this.a?"(s)":"")},
ga2(){return""},
j(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.ga3()+r+p
if(!t.a)return o
return o+t.ga2()+": "+A.bx(t.gab())},
gab(){return this.b}}
A.aC.prototype={
gab(){return A.eA(this.b)},
ga3(){return"RangeError"},
ga2(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.u(r):""
else if(r==null)t=": Not greater than or equal to "+A.u(s)
else if(r>s)t=": Not in inclusive range "+A.u(s)+".."+A.u(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.u(s)
return t}}
A.by.prototype={
gab(){return A.f(this.b)},
ga3(){return"RangeError"},
ga2(){if(A.f(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gn(a){return this.f}}
A.b9.prototype={
j(a){return"Unsupported operation: "+this.a}}
A.bX.prototype={
j(a){return"UnimplementedError: "+this.a}}
A.b6.prototype={
j(a){return"Bad state: "+this.a}}
A.bv.prototype={
j(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bx(t)+"."}}
A.b5.prototype={
j(a){return"Stack Overflow"},
$iv:1}
A.cT.prototype={
j(a){return"Exception: "+this.a}}
A.aO.prototype={
j(a){var t=this.a,s=""!==t?"FormatException: "+t:"FormatException"
return s}}
A.b.prototype={
S(a,b,c){var t=A.t(this)
return A.dE(this,t.A(c).h("1(b.E)").a(b),t.h("b.E"),c)},
M(a,b){var t,s
A.t(this).h("b.E(b.E,b.E)").a(b)
t=this.gp(this)
if(!t.k())throw A.d(A.ay())
s=t.gm()
while(t.k())s=b.$2(s,t.gm())
return s},
aD(a){var t,s,r,q=this.gp(this)
if(!q.k())return""
t=J.aw(q.gm())
if(!q.k())return t
s=new A.ao(t)
r=t
do{r+=J.aw(q.gm())
s.a=r}while(q.k())
r=s.a
return r.charCodeAt(0)==0?r:r},
gn(a){var t,s=this.gp(this)
for(t=0;s.k();)++t
return t},
gX(a){var t=this.gp(this)
if(!t.k())throw A.d(A.ay())
return t.gm()},
C(a,b){var t,s=this.gp(this)
for(t=b;s.k();){if(t===0)return s.gm();--t}throw A.d(A.ea(b,b-t,this,"index"))},
j(a){return A.fq(this,"(",")")}}
A.U.prototype={
j(a){return"MapEntry("+A.u(this.a)+": "+A.u(this.b)+")"}}
A.b2.prototype={
gu(a){return A.w.prototype.gu.call(this,0)},
j(a){return"null"}}
A.w.prototype={$iw:1,
D(a,b){return this===b},
gu(a){return A.bS(this)},
j(a){return"Instance of '"+A.bT(this)+"'"},
gt(a){return A.hJ(this)},
toString(){return this.j(this)}}
A.ao.prototype={
gn(a){return this.a.length},
j(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$ifD:1}
A.c0.prototype={
ad(a){if(a<=0||a>4294967296)throw A.d(A.fy("max must be in range 0 < max \u2264 2^32, was "+a))
return Math.random()*a>>>0},
aE(){return Math.random()},
$idG:1}
A.d6.prototype={
$1(a){var t,s=this.a,r=B.c.v(s.a*48271,2147483647)
s.a=r
t=B.c.v(r,33)
return new A.l(t,B.c.v(t,8))},
$S:14}
A.br.prototype={
ad(a){var t=B.c.v(this.a*48271,2147483647)
this.a=t
return B.c.v(t,a)},
aE(){var t=B.c.v(this.a*48271,2147483647)
this.a=t
return(t-1)/2147483646},
$idG:1}
A.d2.prototype={
$2(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e
u.F.a(a)
u.U.a(b)
if(J.bn(b,new A.d3()))return!0
t=this.a
if(t.a--<=0)return!1
s=A.aK(new A.d4(),null)
s.sP(a)
s.saf(b)
for(r=u.k,q=u.I,p=u.B,o=0;o<b.length;++o){n=b[o]
if(n==null)continue
for(m=s.a_(n),l=m.length,k=0;k<m.length;m.length===l||(0,A.a_)(m),++k){j=m[k]
if(t.a<=0)return!1
i=A.aK(new A.d5(),null)
h=A.j([],p)
for(g=a.length,f=0;f<a.length;a.length===g||(0,A.a_)(a),++f){e=A.I(a[f],q)
h.push(e)}i.sP(h)
h=A.I(b,r)
i.saf(h)
i.aF(o,j.a,j.b)
if(this.$2(i.c,i.d))return!0}}return!1},
$S:22}
A.d3.prototype={
$1(a){return u.k.a(a)==null},
$S:3}
A.d4.prototype={
$0(){return A.j([null,null,null],u.b)},
$S:4}
A.d5.prototype={
$0(){return A.j([null,null,null],u.b)},
$S:4}
A.di.prototype={
$2(a,b){var t,s,r,q,p,o,n=u.W
n.a(a)
n.a(b)
n=a.c
t=A.q(n)
s=t.h("L<1,a?>")
r=new A.z(new A.L(n,t.h("b<a?>(1)").a(new A.da()),s),s.h("k(b.E)").a(new A.db()),s.h("z<b.E>")).gn(0)
s=b.c
t=A.q(s)
n=t.h("L<1,a?>")
q=new A.z(new A.L(s,t.h("b<a?>(1)").a(new A.dc()),n),n.h("k(b.E)").a(new A.dd()),n.h("z<b.E>")).gn(0)
if(r!==q)return B.c.G(q,r)
n=a.c
t=A.q(n)
s=t.h("L<1,a?>")
p=u.N
s=A.dE(new A.L(n,t.h("b<a?>(1)").a(new A.de()),s),s.h("n(b.E)").a(new A.df()),s.h("b.E"),p).aD(0)
t=b.c
n=A.q(t)
o=n.h("L<1,a?>")
return B.n.G(s,A.dE(new A.L(t,n.h("b<a?>(1)").a(new A.dg()),o),o.h("n(b.E)").a(new A.dh()),o.h("b.E"),p).aD(0))},
$S:15}
A.da.prototype={
$1(a){return u.R.a(a)},
$S:2}
A.db.prototype={
$1(a){return A.J(a)!=null},
$S:1}
A.dc.prototype={
$1(a){return u.R.a(a)},
$S:2}
A.dd.prototype={
$1(a){return A.J(a)!=null},
$S:1}
A.de.prototype={
$1(a){return u.R.a(a)},
$S:2}
A.df.prototype={
$1(a){return A.J(a)==null?"0":"1"},
$S:8}
A.dg.prototype={
$1(a){return u.R.a(a)},
$S:2}
A.dh.prototype={
$1(a){return A.J(a)==null?"0":"1"},
$S:8}
A.dj.prototype={
$2(a,b){return A.f(a)+u.W.a(b).e},
$S:26}
A.dk.prototype={
$1(a){var t=u.A.a(a).a
if(!(t>=0&&t<33))return A.e(B.h,t)
return B.h[t].length===1},
$S:5}
A.dl.prototype={
$1(a){var t=u.A.a(a).a
if(!(t>=0&&t<33))return A.e(B.h,t)
return B.h[t].length>=5},
$S:5}
A.dm.prototype={
$1(a){return B.a.J(this.a,u.W.a(a).gau())},
$S:10}
A.dn.prototype={
$1(a){var t
u.W.a(a)
t=u.A
t=A.I(J.e_(a.d,t),t)
B.a.a9(t,this.a)
return A.hA(a,t)},
$S:10}
A.dp.prototype={
$1(a){var t=this.a,s=A.q(t)
return new A.z(t,s.h("k(1)").a(u.W.a(a).gau()),s.h("z<1>")).gn(0)},
$S:16}
A.dq.prototype={
$1(a){var t=this.a,s=A.q(t)
return new A.x(t,s.h("a(1)").a(new A.d9(u.W.a(a))),s.h("x<1,a>"))},
$S:17}
A.d9.prototype={
$1(a){return Math.min(this.a.a_(u.A.a(a)).length,3)},
$S:18}
A.D.prototype={
aR(){var t=this.c
if(t==null)t=new A.cl(this)
return t.$1(this.f++)},
O(){var t=this,s=t.e
s===$&&A.dX()
return A.O(["id",t.a,"name",t.d,"game",s.O(),"nextSet",t.f,"lives",t.r,"boardOuts",t.w,"thresholds",t.x,"damage",t.y,"lastMove",t.z,"ready",t.Q,"connected",t.as,"rematch",t.at,"disconnectAt",t.ax],u.N,u.z)},
sah(a){this.c=u.b8.a(a)}}
A.cl.prototype={
$1(a){return A.eJ(this.a.b,a)},
$S:11}
A.bq.prototype={
aU(a){var t,s,r,q,p=this
if(p.e===1)return A.eJ(p.b,a)
t=p.r
s=t.bh(a,new A.ca(p,a))
r=p.d
if(r.length===2){q=A.q(r)
t.bk(0,new A.cb(new A.x(r,q.h("a(1)").a(new A.cc()),q.h("x<1,a>")).M(0,B.o)))}t=A.I(s,u.k)
return t},
L(a){return B.a.az(this.d,new A.ci(a))},
bd(a,b,c,d){var t,s=this,r=s.d
if(B.a.J(r,new A.cf(b)))return
if(s.w!=="waiting"||r.length>=2)throw A.d(A.fC("Oda dolu veya ma\xe7 ba\u015flam\u0131\u015f."))
t=A.fa(b,c,s.b,!1)
t.sah(s.gan())
t.e=A.aK(t.ga8(),null)
B.a.q(r,t)
t.e.N();++s.x},
b4(a,b){var t,s,r=this
r.F(b)
t=r.L(a)
t.at=t.as=!1
s=r.w
if(s==="finished"){++r.x
return}if(s==="playing")t.ax=b+15e3
else t.ax=null
if(s==="countdown"){r.w="waiting"
r.y=null}++r.x},
bi(a,b){var t,s=this
s.F(b)
if(s.w!=="waiting")return
t=s.L(a)
if(!t.as)return
t.Q=!0;++s.x
s.ak(b)},
ak(a){var t,s=this
if(s.w==="waiting"){t=s.d
t=t.length===2&&B.a.H(t,new A.c7())}else t=!1
if(t){s.w="countdown"
s.y=a+3000;++s.x}},
F(a){var t,s,r,q=this,p=q.w
if(p==="finished")return
if(p==="playing"){p=q.d
t=A.q(p)
s=t.h("z<1>")
r=A.I(new A.z(p,t.h("k(1)").a(new A.cd(a)),s),s.h("b.E"))
B.a.ai(r,new A.ce())
if(r.length!==0){p=B.a.gX(r)
t=B.a.gX(r).ax
t.toString
q.U(p.a,"disconnect",t)
return}}p=q.w
if(p==="waiting"&&a>=q.c+36e5){q.w="finished"
q.as="expired"
q.z=a;++q.x
return}if(p==="countdown"){p=q.y
p.toString
p=a>=p}else p=!1
if(p){q.w="playing";++q.x}},
U(a,b,c){var t,s,r,q=this
if(q.w==="finished")return
q.w="finished"
q.z=c
q.as=b
t=q.d
s=A.q(t)
r=new A.z(t,s.h("k(1)").a(new A.c8(a)),s.h("z<1>"))
q.Q=!r.gp(0).k()?null:r.gX(0).a
B.a.q(q.at,A.O(["type","GAME_OVER","loser",a,"reason",b],u.N,u.z));++q.x},
bg(a,b,c,d,e,a0,a1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=this
f.at=A.j([],u.Y)
f.F(a0)
t=f.L(a)
if(a1!=null&&a1!==f.f)return A.O(["error","Eski round hamlesi."],u.N,u.z)
if(b<=t.z&&b>0)return A.O(["duplicate",!0],u.N,u.z)
if(f.w!=="playing")return A.O(["error","Ma\xe7 \u015fu anda oynanabilir de\u011fil."],u.N,u.z)
if(!t.as||B.a.J(f.d,new A.cg()))return A.O(["error","Ba\u011flant\u0131 bekleniyor."],u.N,u.z)
if(b!==t.z+1)return A.O(["error","Hamle s\u0131ras\u0131 g\xfcncel de\u011fil."],u.N,u.z)
s=t.e
s===$&&A.dX()
r=s.aF(c,d,e)
if(r==null)return A.O(["error","Ge\xe7ersiz yerle\u015ftirme."],u.N,u.z)
t.z=b
q=B.a.az(f.d,new A.ch(a))
s=B.c.V(t.e.e,500)
p=s-t.x
t.x=s
if(p>0){o=B.c.aZ(p,0,q.r)
t.y+=o
q.r-=o
s=q.a
B.a.q(f.at,A.O(["type","DAMAGE","player",s,"amount",o],u.N,u.z))
if(q.r===0)f.U(s,"score",a0)}if(f.w!=="finished"&&!t.e.gb7()){--t.r;++t.w
B.a.q(f.at,A.O(["type","BOARD_RESET","player",a,"amount",1],u.N,u.z))
if(t.r===0)f.U(a,"board_out",a0)
else{s=t.e
n=J.bC(8,u.R)
for(m=u.I,l=0;l<8;++l)n[l]=A.bH(8,null,!1,m)
s.sP(n)
s=t.e
s.w=s.r=s.f=0
s.N()}}++f.x
s=r.b
m=r.c
k=r.d
j=u.N
i=A.al(j,u.p)
for(h=r.a,h=new A.a3(h,A.t(h).h("a3<1,2>")).gp(0);h.k();){g=h.d
i.l(0,""+g.a,g.b)}return A.O(["ok",!0,"move",A.O(["player",a,"slot",c,"row",d,"col",e,"lines",s,"points",m,"allClear",k,"clearedCells",i],j,u.K)],j,u.z)},
bj(a,b,c){var t,s,r=this
r.F(b)
if(r.w!=="finished")return
t=r.L(a)
if(!t.as)return
t.at=!0;++r.x
s=r.d
if(s.length===2&&B.a.H(s,new A.cj()))r.aW(c,b)},
aW(a,b){var t,s,r,q,p,o=this;++o.f
o.b=a==null?B.c.v(o.b*48271+b,2147483646)+1:a
o.r.aa(0)
o.w="countdown"
o.y=b+3000
o.as=o.Q=o.z=null
o.at=A.j([A.O(["type","REMATCH_STARTED","round",o.f],u.N,u.z)],u.Y)
for(t=o.d,s=t.length,r=0;r<t.length;t.length===s||(0,A.a_)(t),++r){q=t[r]
p=A.aK(q.ga8(),null)
q.e=p
q.f=0
q.r=5
q.z=q.y=q.x=q.w=0
q.Q=!0
q.at=!1
p.N()}++o.x},
O(){var t,s,r,q,p,o,n,m,l,k,j=this,i=u.N,h=A.al(i,u.z)
h.l(0,"version",j.e)
h.l(0,"damageStep",500)
h.l(0,"round",j.f)
if(j.e===2){i=A.al(i,u.d)
for(t=j.r,t=new A.a3(t,A.t(t).h("a3<1,2>")).gp(0),s=u.t,r=u.q;t.k();){q=t.d
p=q.a
o=A.j([],r)
for(n=q.b,m=n.length,l=0;l<n.length;n.length===m||(0,A.a_)(n),++l){k=n[l]
o.push(k==null?null:A.j([k.a,k.b],s))}i.l(0,""+p,o)}h.l(0,"sets",i)}h.l(0,"roomId",j.a)
h.l(0,"seed",j.b)
h.l(0,"createdAt",j.c)
h.l(0,"status",j.w)
h.l(0,"revision",j.x)
h.l(0,"startAt",j.y)
h.l(0,"endedAt",j.z)
h.l(0,"winner",j.Q)
h.l(0,"reason",j.as)
i=j.d
t=A.q(i)
s=t.h("x<1,T<n,@>>")
i=A.I(new A.x(i,t.h("T<n,@>(1)").a(new A.ck()),s),s.h("E.E"))
h.l(0,"players",i)
return h}}
A.ca.prototype={
$0(){var t,s,r=this.a,q=r.b
r=r.d
t=A.q(r)
s=t.h("x<1,y>")
r=A.I(new A.x(r,t.h("y(1)").a(new A.c9()),s),s.h("E.E"))
return A.hG(q,this.b,r)},
$S:4}
A.c9.prototype={
$1(a){var t=u.h.a(a).e
t===$&&A.dX()
return t},
$S:20}
A.cc.prototype={
$1(a){return u.h.a(a).f},
$S:21}
A.cb.prototype={
$2(a,b){A.f(a)
u.U.a(b)
return a<this.a},
$S:34}
A.ci.prototype={
$1(a){return u.h.a(a).a===this.a},
$S:0}
A.cf.prototype={
$1(a){return u.h.a(a).a===this.a},
$S:0}
A.c7.prototype={
$1(a){u.h.a(a)
return a.Q&&a.as},
$S:0}
A.cd.prototype={
$1(a){var t=u.h.a(a).ax
return t!=null&&this.a>=t},
$S:0}
A.ce.prototype={
$2(a,b){var t,s=u.h
s.a(a)
s.a(b)
s=a.ax
s.toString
t=b.ax
t.toString
return B.c.G(s,t)},
$S:24}
A.c8.prototype={
$1(a){return u.h.a(a).a!==this.a},
$S:0}
A.cg.prototype={
$1(a){return!u.h.a(a).as},
$S:0}
A.ch.prototype={
$1(a){return u.h.a(a).a!==this.a},
$S:0}
A.cj.prototype={
$1(a){u.h.a(a)
return a.at&&a.as},
$S:0}
A.ck.prototype={
$1(a){return u.h.a(a).O()},
$S:25}
A.l.prototype={
gbl(){var t,s=this.a
if(!(s>=0&&s<33))return A.e(B.h,s)
s=B.h[s]
t=A.q(s)
return new A.x(s,t.h("a(1)").a(new A.cE()),t.h("x<1,a>")).M(0,B.r)+1},
gb_(){var t,s=this.a
if(!(s>=0&&s<33))return A.e(B.h,s)
s=B.h[s]
t=A.q(s)
return new A.x(s,t.h("a(1)").a(new A.cD()),t.h("x<1,a>")).M(0,B.r)+1}}
A.cE.prototype={
$1(a){u.L.a(a)
if(0>=a.length)return A.e(a,0)
return a[0]},
$S:13}
A.cD.prototype={
$1(a){u.L.a(a)
if(1>=a.length)return A.e(a,1)
return a[1]},
$S:13}
A.cC.prototype={}
A.y.prototype={
aA(a,b,c,d){var t,s
u.D.a(d)
t=d==null?this.c:d
s=a.a
if(!(s>=0&&s<33))return A.e(B.h,s)
return B.a.H(B.h[s],new A.co(b,c,t))},
b6(a,b,c){return this.aA(a,b,c,null)},
aG(a,b){var t,s,r
u.D.a(b)
t=A.j([],u.w)
for(s=0;s<=8-a.gbl();++s)for(r=0;r<=8-a.gb_();++r)if(this.aA(a,s,r,b))t.push(new A.aF(s,r))
return t},
a_(a){return this.aG(a,null)},
aY(a){return this.a_(u.A.a(a)).length!==0},
gb7(){return J.dZ(this.d,new A.cp(this))},
aF(a,b,c){var t,s,r,q,p,o,n,m,l,k=this
if(a<0||a>=k.d.length)return null
t=k.d
if(!(a>=0&&a<t.length))return A.e(t,a)
s=t[a]
if(s==null||!k.b6(s,b,c))return null
A.e2(k.c,s,b,c)
J.bm(k.d,a,null)
r=A.dA(k.c)
q=r.a.length+r.b.length
p=A.e1(k.c)
t=q>0
if(t){o=++k.f
k.r=0
k.w=10*q*q*o}else if(k.f>0)if(++k.r>=3)k.w=k.r=k.f=0
n=t&&B.a.H(k.c,new A.cr())
t=s.a
if(!(t>=0&&t<33))return A.e(B.h,t)
t=B.h[t]
o=k.f
m=n?300:0
l=t.length+10*q*q*o+m
k.e+=l
if(J.bn(k.d,new A.cs()))k.N()
return new A.cC(p,q,l,n)},
N(){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=this,a4=a3.b
if(a4!=null){a3.d=a4.$0()
return}t=A.fc(a3.c)
s=A.j([],u.a)
for(a4=a3.a,r=u.H,q=u.c,p=A.q(t),o=p.h("b<a?>(1)"),p=p.h("L<1,a?>"),n=p.h("k(b.E)"),m=p.h("z<b.E>"),l=0;l<3;++l){k=A.j([],q)
for(j=new A.z(new A.L(t,o.a(new A.ct()),p),n.a(new A.cu()),m).gn(0)/64>0.65,i=0;i<33;++i){h=new A.l(i,B.c.v(i,8))
g=a3.aG(h,t)
if(g.length===0)continue
f=B.h[i].length
e=f===1?0.18:1
if(f>=5)e*=1.3+Math.min(a3.e/5000,0.7)
if(j&&f<=3)e*=1.8
B.a.q(k,new A.bg(h,g,B.a.J(s,new A.cv(i))?e*0.25:e))}if(k.length===0)break
d=a4.aE()*B.a.aB(k,0,new A.cw(),r)
c=B.a.gbe(k)
for(j=k.length,b=0;b<j;++b){a=k[b]
d-=a.c
if(d<=0){c=a
break}}j=c.b
f=a4.ad(j.length)
if(!(f>=0&&f<j.length))return A.e(j,f)
a0=j[f]
f=c.a
B.a.q(s,f)
A.e2(t,f,a0.a,a0.b)
A.e1(t)}B.a.aL(s,a4)
a1=J.bC(3,u.k)
for(a4=s.length,a2=0;a2<3;++a2){if(a2<a4){if(!(a2<a4))return A.e(s,a2)
r=s[a2]}else r=null
a1[a2]=r}a3.d=a1},
O(){var t,s,r,q,p,o=this,n=o.c,m=A.j([],u.q)
for(t=o.d,s=t.length,r=u.t,q=0;q<t.length;t.length===s||(0,A.a_)(t),++q){p=t[q]
m.push(p==null?null:A.j([p.a,p.b],r))}return A.O(["version",1,"grid",n,"tray",m,"score",o.e,"combo",o.f,"misses",o.r,"comboBonus",o.w,"reviveUsed",o.x],u.N,u.z)},
sP(a){this.c=u.F.a(a)},
saf(a){this.d=u.U.a(a)},
saK(a){this.e=A.f(a)},
sb0(a){this.f=A.f(a)},
sbf(a){this.r=A.f(a)},
sb1(a){this.w=A.f(a)}}
A.co.prototype={
$1(a){var t,s,r
u.L.a(a)
t=a.length
if(0>=t)return A.e(a,0)
s=this.a+a[0]
if(1>=t)return A.e(a,1)
r=this.b+a[1]
t=!1
if(s>=0)if(s<8)if(r>=0)if(r<8){t=this.c
if(!(s<t.length))return A.e(t,s)
t=t[s]
if(!(r<t.length))return A.e(t,r)
t=t[r]==null}return t},
$S:27}
A.cp.prototype={
$1(a){u.k.a(a)
return a!=null&&this.a.a_(a).length!==0},
$S:3}
A.cm.prototype={
$1(a){return A.J(a)!=null},
$S:1}
A.cn.prototype={
$1(a){return A.J(a)!=null},
$S:1}
A.cr.prototype={
$1(a){return J.bn(u.R.a(a),new A.cq())},
$S:6}
A.cq.prototype={
$1(a){return A.J(a)==null},
$S:1}
A.cs.prototype={
$1(a){return u.k.a(a)==null},
$S:3}
A.ct.prototype={
$1(a){return u.R.a(a)},
$S:2}
A.cu.prototype={
$1(a){return A.J(a)!=null},
$S:1}
A.cv.prototype={
$1(a){return u.A.a(a).a===this.a},
$S:5}
A.cw.prototype={
$2(a,b){return A.dL(a)+u.Q.a(b).c},
$S:29}
A.cy.prototype={
$1(a){var t=J.dz(u.j.a(a),new A.cx(),u.I)
t=A.I(t,t.$ti.h("E.E"))
return t},
$S:30}
A.cx.prototype={
$1(a){var t
if(a!=null)t=!A.c4(a)||a<0||a>=8
else t=!1
if(t)throw A.d(B.w)
return A.J(a)},
$S:31}
A.cz.prototype={
$1(a){return u.R.a(a).length!==8},
$S:6}
A.cA.prototype={
$1(a){var t,s,r
if(a==null)return null
t=!0
if(u.j.b(a)){s=a.length
if(s===2){if(0>=s)return A.e(a,0)
r=a[0]
if(A.c4(r)){if(1>=s)return A.e(a,1)
t=a[1]
t=!A.c4(t)||r<0||r>=33||t<0||t>=8}}}if(t)throw A.d(B.w)
t=a.length
if(0>=t)return A.e(a,0)
s=A.f(a[0])
if(1>=t)return A.e(a,1)
return new A.l(s,A.f(a[1]))},
$S:32}
A.cB.prototype={
$1(a){return u.k.a(a)==null},
$S:3}
A.dw.prototype={
$1(a){var t,s,r,q,p,o,n,m,l,k,j,i,h="state",g="id"
A.P(a)
try{t=u.l.a(B.p.b2(a,null))
s=J.B(t,h)==null?A.e0(A.P(J.B(t,"roomId")),A.f(J.B(t,"seed")),A.f(J.B(t,"now"))):A.f9(A.dD(u.f.a(J.B(t,h)),u.N,u.z))
r=A.f(J.B(t,"now"))
q=null
switch(J.B(t,"action")){case"join":J.f8(s,A.f(J.B(t,g)),A.P(J.B(t,"name")),r)
break
case"connect":n=s
m=A.f(J.B(t,g))
l=A.f(r)
n.F(l)
k=n.L(m)
k.as=!0
k.ax=null;++n.x
n.ak(l)
break
case"disconnect":s.b4(A.f(J.B(t,g)),r)
break
case"ready":s.bi(A.f(J.B(t,g)),r)
break
case"advance":s.F(r)
break
case"resign":n=s
m=A.f(J.B(t,g))
l=A.f(r)
n.F(l)
n.L(m)
if(n.w!=="finished")n.U(m,"resigned",l)
break
case"rematch":s.bj(A.f(J.B(t,g)),r,A.J(J.B(t,"seed")))
break
case"place":q=s.bg(A.f(J.B(t,g)),A.f(J.B(t,"moveId")),A.f(J.B(t,"slot")),A.f(J.B(t,"row")),A.f(J.B(t,"col")),r,A.J(J.B(t,"round")))
break}p=A.al(u.N,u.z)
J.bm(p,h,s.O())
J.bm(p,"events",s.at)
o=q
if(o!=null)J.f4(p,o)
j=B.p.av(p,null)
return j}catch(i){p=u.N
j=B.p.av(A.O(["error","Ge\xe7ersiz ma\xe7 iste\u011fi."],p,p),null)
return j}},
$S:33};(function aliases(){var t=J.ac.prototype
t.aM=t.j})();(function installTearOffs(){var t=hunkHelpers._static_1,s=hunkHelpers.installStaticTearOff,r=hunkHelpers._instance_0u,q=hunkHelpers._instance_1u
t(A,"hD","h6",9)
s(A,"hW",2,null,["$1$2","$2"],["eO",function(a,b){return A.eO(a,b,u.H)}],12,0)
s(A,"hV",2,null,["$1$2","$2"],["eN",function(a,b){return A.eN(a,b,u.H)}],12,0)
r(A.D.prototype,"ga8","aR",4)
q(A.bq.prototype,"gan","aU",11)
q(A.y.prototype,"gau","aY",5)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.w,null)
r(A.w,[A.dB,J.bA,A.b4,J.ah,A.v,A.cQ,A.b,A.am,A.aY,A.ba,A.aN,A.aM,A.bb,A.M,A.a5,A.K,A.cR,A.cO,A.r,A.cK,A.aj,A.aX,A.Y,A.c_,A.cZ,A.p,A.bu,A.bw,A.cW,A.b5,A.cT,A.aO,A.U,A.b2,A.ao,A.c0,A.br,A.D,A.bq,A.l,A.cC,A.y])
r(J.bA,[J.bD,J.aQ,J.aT,J.aS,J.aU,J.aR,J.az])
r(J.aT,[J.ac,J.m,A.aA,A.b0])
r(J.ac,[J.bR,J.b8,J.ab])
s(J.bB,A.b4)
s(J.cF,J.m)
r(J.aR,[J.aP,J.bE])
r(A.v,[A.aW,A.b7,A.bF,A.bY,A.bU,A.bZ,A.aV,A.bo,A.aa,A.b9,A.bX,A.b6,A.bv])
r(A.b,[A.h,A.an,A.z,A.L,A.ap])
r(A.h,[A.E,A.ak,A.a3])
s(A.aL,A.an)
r(A.E,[A.x,A.c2])
r(A.a5,[A.aD,A.aE])
s(A.aF,A.aD)
s(A.bg,A.aE)
r(A.K,[A.bz,A.bs,A.bt,A.bW,A.ds,A.du,A.cM,A.d6,A.d3,A.da,A.db,A.dc,A.dd,A.de,A.df,A.dg,A.dh,A.dk,A.dl,A.dm,A.dn,A.dp,A.dq,A.d9,A.cl,A.c9,A.cc,A.ci,A.cf,A.c7,A.cd,A.c8,A.cg,A.ch,A.cj,A.ck,A.cE,A.cD,A.co,A.cp,A.cm,A.cn,A.cr,A.cq,A.cs,A.ct,A.cu,A.cv,A.cy,A.cx,A.cz,A.cA,A.cB,A.dw])
s(A.ai,A.bz)
s(A.b3,A.b7)
r(A.bW,[A.bV,A.ax])
r(A.r,[A.a2,A.c1])
r(A.bt,[A.cG,A.dt,A.cL,A.cN,A.cX,A.d2,A.di,A.dj,A.cb,A.ce,A.cw])
r(A.b0,[A.bI,A.aB])
r(A.aB,[A.bc,A.be])
s(A.bd,A.bc)
s(A.aZ,A.bd)
s(A.bf,A.be)
s(A.b_,A.bf)
r(A.aZ,[A.bJ,A.bK])
r(A.b_,[A.bL,A.bM,A.bN,A.bO,A.bP,A.b1,A.bQ])
s(A.aG,A.bZ)
s(A.bG,A.aV)
s(A.cH,A.bu)
r(A.bw,[A.cJ,A.cI])
s(A.cV,A.cW)
r(A.aa,[A.aC,A.by])
r(A.bs,[A.d4,A.d5,A.ca])
t(A.bc,A.p)
t(A.bd,A.M)
t(A.be,A.p)
t(A.bf,A.M)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{a:"int",i:"double",Z:"num",n:"String",k:"bool",b2:"Null",c:"List",w:"Object",T:"Map",A:"JSObject"},mangledNames:{},types:["k(D)","k(a?)","c<a?>(c<a?>)","k(l?)","c<l?>()","k(l)","k(c<a?>)","~(w?,w?)","n(a?)","@(@)","k(y)","c<l?>(a)","0^(0^,0^)<Z>","a(c<a>)","l(a)","a(y,y)","a(y)","b<a>(y)","a(l)","@(n)","y(D)","a(D)","k(c<c<a?>>,c<l?>)","~(@,@)","a(D,D)","T<n,@>(D)","a(a,y)","k(c<a>)","@(@,n)","i(Z,+(l,c<+(a,a)>,i))","c<a?>(@)","a?(@)","l?(@)","n(n)","k(a,c<l?>)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof A.aF&&a.b(c.a)&&b.b(c.b),"3;":(a,b,c)=>d=>d instanceof A.bg&&a.b(d.a)&&b.b(d.b)&&c.b(d.c)}}
A.fY(v.typeUniverse,JSON.parse('{"ab":"ac","bR":"ac","b8":"ac","i2":"aA","bD":{"k":[],"o":[]},"aQ":{"o":[]},"aT":{"A":[]},"ac":{"A":[]},"m":{"c":["1"],"h":["1"],"A":[],"b":["1"]},"bB":{"b4":[]},"cF":{"m":["1"],"c":["1"],"h":["1"],"A":[],"b":["1"]},"ah":{"H":["1"]},"aR":{"i":[],"Z":[]},"aP":{"i":[],"a":[],"Z":[],"o":[]},"bE":{"i":[],"Z":[],"o":[]},"az":{"n":[],"o":[]},"aW":{"v":[]},"h":{"b":["1"]},"E":{"h":["1"],"b":["1"]},"am":{"H":["1"]},"an":{"b":["2"],"b.E":"2"},"aL":{"an":["1","2"],"h":["2"],"b":["2"],"b.E":"2"},"aY":{"H":["2"]},"x":{"E":["2"],"h":["2"],"b":["2"],"E.E":"2","b.E":"2"},"z":{"b":["1"],"b.E":"1"},"ba":{"H":["1"]},"L":{"b":["2"],"b.E":"2"},"aN":{"H":["2"]},"aM":{"H":["1"]},"ap":{"b":["1"],"b.E":"1"},"bb":{"H":["1"]},"aF":{"aD":[],"a5":[]},"bg":{"aE":[],"a5":[]},"bz":{"K":[],"a1":[]},"ai":{"K":[],"a1":[]},"b3":{"v":[]},"bF":{"v":[]},"bY":{"v":[]},"K":{"a1":[]},"bs":{"K":[],"a1":[]},"bt":{"K":[],"a1":[]},"bW":{"K":[],"a1":[]},"bV":{"K":[],"a1":[]},"ax":{"K":[],"a1":[]},"bU":{"v":[]},"a2":{"r":["1","2"],"ee":["1","2"],"T":["1","2"],"r.K":"1","r.V":"2"},"ak":{"h":["1"],"b":["1"],"b.E":"1"},"aj":{"H":["1"]},"a3":{"h":["U<1,2>"],"b":["U<1,2>"],"b.E":"U<1,2>"},"aX":{"H":["U<1,2>"]},"aD":{"a5":[]},"aE":{"a5":[]},"aA":{"A":[],"o":[]},"b0":{"A":[]},"bI":{"A":[],"o":[]},"aB":{"R":["1"],"A":[]},"aZ":{"p":["i"],"c":["i"],"R":["i"],"h":["i"],"A":[],"b":["i"],"M":["i"]},"b_":{"p":["a"],"c":["a"],"R":["a"],"h":["a"],"A":[],"b":["a"],"M":["a"]},"bJ":{"p":["i"],"c":["i"],"R":["i"],"h":["i"],"A":[],"b":["i"],"M":["i"],"o":[],"p.E":"i"},"bK":{"p":["i"],"c":["i"],"R":["i"],"h":["i"],"A":[],"b":["i"],"M":["i"],"o":[],"p.E":"i"},"bL":{"p":["a"],"c":["a"],"R":["a"],"h":["a"],"A":[],"b":["a"],"M":["a"],"o":[],"p.E":"a"},"bM":{"p":["a"],"c":["a"],"R":["a"],"h":["a"],"A":[],"b":["a"],"M":["a"],"o":[],"p.E":"a"},"bN":{"p":["a"],"c":["a"],"R":["a"],"h":["a"],"A":[],"b":["a"],"M":["a"],"o":[],"p.E":"a"},"bO":{"p":["a"],"c":["a"],"R":["a"],"h":["a"],"A":[],"b":["a"],"M":["a"],"o":[],"p.E":"a"},"bP":{"p":["a"],"c":["a"],"R":["a"],"h":["a"],"A":[],"b":["a"],"M":["a"],"o":[],"p.E":"a"},"b1":{"p":["a"],"c":["a"],"R":["a"],"h":["a"],"A":[],"b":["a"],"M":["a"],"o":[],"p.E":"a"},"bQ":{"p":["a"],"c":["a"],"R":["a"],"h":["a"],"A":[],"b":["a"],"M":["a"],"o":[],"p.E":"a"},"bZ":{"v":[]},"aG":{"v":[]},"r":{"T":["1","2"]},"c1":{"r":["n","@"],"T":["n","@"],"r.K":"n","r.V":"@"},"c2":{"E":["n"],"h":["n"],"b":["n"],"E.E":"n","b.E":"n"},"aV":{"v":[]},"bG":{"v":[]},"i":{"Z":[]},"a":{"Z":[]},"c":{"h":["1"],"b":["1"]},"bo":{"v":[]},"b7":{"v":[]},"aa":{"v":[]},"aC":{"v":[]},"by":{"v":[]},"b9":{"v":[]},"bX":{"v":[]},"b6":{"v":[]},"bv":{"v":[]},"b5":{"v":[]},"ao":{"fD":[]},"c0":{"dG":[]},"br":{"dG":[]},"fp":{"c":["a"],"h":["a"],"b":["a"]},"fH":{"c":["a"],"h":["a"],"b":["a"]},"fG":{"c":["a"],"h":["a"],"b":["a"]},"fn":{"c":["a"],"h":["a"],"b":["a"]},"fE":{"c":["a"],"h":["a"],"b":["a"]},"fo":{"c":["a"],"h":["a"],"b":["a"]},"fF":{"c":["a"],"h":["a"],"b":["a"]},"fl":{"c":["i"],"h":["i"],"b":["i"]},"fm":{"c":["i"],"h":["i"],"b":["i"]}}'))
A.fX(v.typeUniverse,JSON.parse('{"h":1,"aB":1,"bu":2,"bw":2}'))
var u=(function rtii(){var t=A.bl
return{h:t("D"),W:t("y"),A:t("l"),_:t("h<@>"),C:t("v"),Z:t("a1"),v:t("ai<a>"),V:t("b<@>"),O:t("m<D>"),a:t("m<l>"),S:t("m<c<a>>"),B:t("m<c<a?>>"),Y:t("m<T<n,@>>"),w:t("m<+(a,a)>"),c:t("m<+(l,c<+(a,a)>,i)>"),s:t("m<n>"),n:t("m<@>"),t:t("m<a>"),b:t("m<l?>"),q:t("m<c<a>?>"),e:t("m<a?>"),T:t("aQ"),m:t("A"),g:t("ab"),E:t("R<@>"),F:t("c<c<a?>>"),j:t("c<@>"),L:t("c<a>"),U:t("c<l?>"),d:t("c<c<a>?>"),R:t("c<a?>"),l:t("T<n,@>"),f:t("T<@,@>"),P:t("b2"),K:t("w"),J:t("i3"),r:t("+()"),Q:t("+(l,c<+(a,a)>,i)"),N:t("n"),x:t("o"),o:t("b8"),y:t("k"),i:t("i"),z:t("@"),p:t("a"),k:t("l?"),G:t("e9<b2>?"),M:t("A?"),D:t("c<c<a?>>?"),aL:t("c<@>?"),b8:t("c<l?>(a)?"),a5:t("T<@,@>?"),X:t("w?"),aD:t("n?"),u:t("k?"),dd:t("i?"),I:t("a?"),ae:t("Z?"),H:t("Z"),cQ:t("~(n,@)")}})();(function constants(){var t=hunkHelpers.makeConstList
B.I=J.bA.prototype
B.a=J.m.prototype
B.c=J.aP.prototype
B.J=J.aR.prototype
B.n=J.az.prototype
B.K=J.ab.prototype
B.L=J.aT.prototype
B.z=J.bR.prototype
B.q=J.b8.prototype
B.r=new A.ai(A.hV(),u.v)
B.o=new A.ai(A.hW(),u.v)
B.A=new A.aM(A.bl("aM<0&>"))
B.t=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.B=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.G=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.C=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.F=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.E=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.D=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.u=function(hooks) { return hooks; }

B.p=new A.cH()
B.m=new A.cQ()
B.v=new A.c0()
B.H=new A.aO("Battle version")
B.w=new A.aO("")
B.M=new A.cI(null)
B.N=new A.cJ(null)
B.b=t([0,0],u.t)
B.Z=t([B.b],u.S)
B.d=t([0,1],u.t)
B.Y=t([B.b,B.d],u.S)
B.e=t([1,0],u.t)
B.ai=t([B.b,B.e],u.S)
B.i=t([0,2],u.t)
B.a1=t([B.b,B.d,B.i],u.S)
B.j=t([2,0],u.t)
B.T=t([B.b,B.e,B.j],u.S)
B.x=t([0,3],u.t)
B.R=t([B.b,B.d,B.i,B.x],u.S)
B.y=t([3,0],u.t)
B.aa=t([B.b,B.e,B.j,B.y],u.S)
B.O=t([0,4],u.t)
B.ae=t([B.b,B.d,B.i,B.x,B.O],u.S)
B.S=t([4,0],u.t)
B.a_=t([B.b,B.e,B.j,B.y,B.S],u.S)
B.f=t([1,1],u.t)
B.aj=t([B.b,B.d,B.e,B.f],u.S)
B.k=t([1,2],u.t)
B.l=t([2,1],u.t)
B.Q=t([2,2],u.t)
B.a5=t([B.b,B.d,B.i,B.e,B.f,B.k,B.j,B.l,B.Q],u.S)
B.a3=t([B.b,B.d,B.e],u.S)
B.a2=t([B.b,B.d,B.f],u.S)
B.V=t([B.b,B.e,B.f],u.S)
B.al=t([B.d,B.e,B.f],u.S)
B.a7=t([B.b,B.e,B.j,B.l],u.S)
B.P=t([B.b,B.d,B.i,B.e],u.S)
B.ah=t([B.b,B.d,B.f,B.l],u.S)
B.X=t([B.i,B.e,B.f,B.k],u.S)
B.a0=t([B.d,B.f,B.j,B.l],u.S)
B.W=t([B.b,B.e,B.f,B.k],u.S)
B.a6=t([B.b,B.d,B.e,B.j],u.S)
B.af=t([B.b,B.d,B.i,B.k],u.S)
B.ad=t([B.b,B.d,B.i,B.f],u.S)
B.ak=t([B.d,B.e,B.f,B.k],u.S)
B.ac=t([B.b,B.e,B.f,B.j],u.S)
B.ag=t([B.d,B.e,B.f,B.l],u.S)
B.a8=t([B.d,B.i,B.e,B.f],u.S)
B.ab=t([B.b,B.e,B.f,B.l],u.S)
B.am=t([B.b,B.d,B.f,B.k],u.S)
B.a9=t([B.d,B.e,B.f,B.j],u.S)
B.U=t([B.b,B.d,B.i,B.e,B.f,B.k],u.S)
B.a4=t([B.b,B.d,B.e,B.f,B.j,B.l],u.S)
B.h=t([B.Z,B.Y,B.ai,B.a1,B.T,B.R,B.aa,B.ae,B.a_,B.aj,B.a5,B.a3,B.a2,B.V,B.al,B.a7,B.P,B.ah,B.X,B.a0,B.W,B.a6,B.af,B.ad,B.ak,B.ac,B.ag,B.a8,B.ab,B.am,B.a9,B.U,B.a4],A.bl("m<c<c<a>>>"))
B.an=A.a0("i_")
B.ao=A.a0("i0")
B.ap=A.a0("fl")
B.aq=A.a0("fm")
B.ar=A.a0("fn")
B.as=A.a0("fo")
B.at=A.a0("fp")
B.au=A.a0("w")
B.av=A.a0("fE")
B.aw=A.a0("fF")
B.ax=A.a0("fG")
B.ay=A.a0("fH")})();(function staticFields(){$.cU=null
$.S=A.j([],A.bl("m<w>"))
$.eg=null
$.e5=null
$.e4=null
$.eL=null
$.eI=null
$.eR=null
$.d8=null
$.dv=null
$.dT=null
$.cY=A.j([],A.bl("m<c<w>?>"))})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"i1","dY",()=>A.hI("_$dart_dartClosure"))
t($,"ig","f3",()=>A.j([new J.bB()],A.bl("m<b4>")))
t($,"i4","eU",()=>A.a4(A.cS({
toString:function(){return"$receiver$"}})))
t($,"i5","eV",()=>A.a4(A.cS({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"i6","eW",()=>A.a4(A.cS(null)))
t($,"i7","eX",()=>A.a4(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"ia","f_",()=>A.a4(A.cS(void 0)))
t($,"ib","f0",()=>A.a4(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"i9","eZ",()=>A.a4(A.ek(null)))
t($,"i8","eY",()=>A.a4(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"id","f2",()=>A.a4(A.ek(void 0)))
t($,"ic","f1",()=>A.a4(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"ie","dy",()=>A.eP(B.au))})();(function nativeSupport(){!function(){var t=function(a){var n={}
n[a]=1
return Object.keys(hunkHelpers.convertToFastObject(n))[0]}
v.getIsolateTag=function(a){return t("___dart_"+a+v.isolateTag)}
var s="___dart_isolate_tags_"
var r=Object[s]||(Object[s]=Object.create(null))
var q="_ZxYxX"
for(var p=0;;p++){var o=t(q+"_"+p+"_")
if(!(o in r)){r[o]=1
v.isolateTag=o
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.aA,SharedArrayBuffer:A.aA,ArrayBufferView:A.b0,DataView:A.bI,Float32Array:A.bJ,Float64Array:A.bK,Int16Array:A.bL,Int32Array:A.bM,Int8Array:A.bN,Uint16Array:A.bO,Uint32Array:A.bP,Uint8ClampedArray:A.b1,CanvasPixelArray:A.b1,Uint8Array:A.bQ})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.aB.$nativeSuperclassTag="ArrayBufferView"
A.bc.$nativeSuperclassTag="ArrayBufferView"
A.bd.$nativeSuperclassTag="ArrayBufferView"
A.aZ.$nativeSuperclassTag="ArrayBufferView"
A.be.$nativeSuperclassTag="ArrayBufferView"
A.bf.$nativeSuperclassTag="ArrayBufferView"
A.b_.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$0=function(){return this()}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$1$0=function(){return this()}
Function.prototype.$1$1=function(a){return this(a)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.hT
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()