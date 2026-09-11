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
if(a[b]!==t){A.h7(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.m(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.d2(b)
return new t(c,this)}:function(){if(t===null)t=A.d2(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.d2(a).prototype
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
d8(a,b,c,d){return{i:a,p:b,e:c,x:d}},
d4(a){var t,s,r,q,p,o=a[v.dispatchPropertyName]
if(o==null)if($.d6==null){A.fY()
o=a[v.dispatchPropertyName]}if(o!=null){t=o.p
if(!1===t)return o.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return o.i
if(o.e===s)throw A.c(A.dv("Return interceptor for "+A.o(t(a,o))))}r=a.constructor
if(r==null)q=null
else{p=$.cu
if(p==null)p=$.cu=v.getIsolateTag("_$dart_js")
q=r[p]}if(q!=null)return q
q=A.h2(a)
if(q!=null)return q
if(typeof a=="function")return B.J
t=Object.getPrototypeOf(a)
if(t==null)return B.y
if(t===Object.prototype)return B.y
if(typeof r=="function"){p=$.cu
if(p==null)p=$.cu=v.getIsolateTag("_$dart_js")
Object.defineProperty(r,p,{value:B.p,enumerable:false,writable:true,configurable:true})
return B.p}return B.p},
eE(a,b){if(a>4294967295)throw A.c(A.cp(a,0,4294967295,"length",null))
return J.eF(new Array(a),b)},
dk(a,b){return A.m(new Array(a),b.h("i<0>"))},
cf(a,b){if(a<0)throw A.c(A.cP("Length must be a non-negative integer: "+a))
return A.m(new Array(a),b.h("i<0>"))},
eF(a,b){var t=A.m(a,b.h("i<0>"))
t.$flags=1
return t},
ad(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.aB.prototype
return J.bm.prototype}if(typeof a=="string")return J.ak.prototype
if(a==null)return J.aC.prototype
if(typeof a=="boolean")return J.bl.prototype
if(Array.isArray(a))return J.i.prototype
if(typeof a!="object"){if(typeof a=="function")return J.Z.prototype
if(typeof a=="symbol")return J.aG.prototype
if(typeof a=="bigint")return J.aE.prototype
return a}if(a instanceof A.n)return a
return J.d4(a)},
dV(a){if(typeof a=="string")return J.ak.prototype
if(a==null)return a
if(Array.isArray(a))return J.i.prototype
if(typeof a!="object"){if(typeof a=="function")return J.Z.prototype
if(typeof a=="symbol")return J.aG.prototype
if(typeof a=="bigint")return J.aE.prototype
return a}if(a instanceof A.n)return a
return J.d4(a)},
a4(a){if(a==null)return a
if(Array.isArray(a))return J.i.prototype
if(typeof a!="object"){if(typeof a=="function")return J.Z.prototype
if(typeof a=="symbol")return J.aG.prototype
if(typeof a=="bigint")return J.aE.prototype
return a}if(a instanceof A.n)return a
return J.d4(a)},
fT(a){if(a==null)return a
if(!(a instanceof A.n))return J.ao.prototype
return a},
ag(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.ad(a).C(a,b)},
v(a,b){if(typeof b==="number")if(Array.isArray(a)||A.h1(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.a4(a).j(a,b)},
b5(a,b,c){return J.a4(a).q(a,b,c)},
ef(a,b){return J.fT(a).aw(a,b)},
db(a,b){return J.a4(a).O(a,b)},
eg(a,b){return J.a4(a).A(a,b)},
bQ(a,b){return J.a4(a).G(a,b)},
N(a){return J.ad(a).gu(a)},
eh(a){return J.a4(a).gaf(a)},
aw(a){return J.a4(a).gt(a)},
ah(a){return J.dV(a).gl(a)},
ei(a){return J.ad(a).gp(a)},
ej(a,b,c,d){return J.a4(a).aL(a,b,c,d)},
cO(a,b,c){return J.a4(a).ag(a,b,c)},
b6(a){return J.ad(a).i(a)},
bi:function bi(){},
bl:function bl(){},
aC:function aC(){},
aF:function aF(){},
a_:function a_(){},
bA:function bA(){},
ao:function ao(){},
Z:function Z(){},
aE:function aE(){},
aG:function aG(){},
i:function i(a){this.$ti=a},
bk:function bk(){},
cg:function cg(a){this.$ti=a},
a5:function a5(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aD:function aD(){},
aB:function aB(){},
bm:function bm(){},
ak:function ak(){}},A={cR:function cR(){},
eG(a){return new A.aI("Field '"+a+"' has not been initialized.")},
a0(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
cW(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
d7(a){var t,s
for(t=$.J.length,s=0;s<t;++s)if(a===$.J[s])return!0
return!1},
bj(){return new A.aU("No element")},
aI:function aI(a){this.a=a},
cq:function cq(){},
ax:function ax(){},
x:function x(){},
a8:function a8(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
I:function I(a,b,c){this.a=a
this.b=b
this.$ti=c},
aa:function aa(a,b,c){this.a=a
this.b=b
this.$ti=c},
aX:function aX(a,b,c){this.a=a
this.b=b
this.$ti=c},
ce:function ce(a,b,c){this.a=a
this.b=b
this.$ti=c},
az:function az(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
ay:function ay(a){this.$ti=a},
A:function A(){},
e2(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
h1(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.E.b(a)},
o(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.b6(a)
return t},
bB(a){var t,s=$.dq
if(s==null)s=$.dq=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
bC(a){var t,s,r,q
if(a instanceof A.n)return A.D(A.V(a),null)
t=J.ad(a)
if(t===B.H||t===B.K||u.o.b(a)){s=B.r(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.D(A.V(a),null)},
dr(a){var t,s,r
if(a==null||typeof a=="number"||A.d0(a))return J.b6(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.E)return a.i(0)
if(a instanceof A.ac)return a.a9(!0)
t=$.ee()
for(s=0;s<1;++s){r=t[s].aU(a)
if(r!=null)return r}return"Instance of '"+A.bC(a)+"'"},
w(a){var t
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.f.a7(t,10)|55296)>>>0,t&1023|56320)}throw A.c(A.cp(a,0,1114111,null,null))},
d(a,b){if(a==null)J.ah(a)
throw A.c(A.d3(a,b))},
d3(a,b){var t,s="index"
if(!A.bN(b))return new A.X(!0,b,s,null)
t=J.ah(a)
if(b<0||b>=t)return A.di(b,t,a,s)
return new A.aR(null,null,!0,b,s,"Value not in range")},
fK(a){return new A.X(!0,a,null,null)},
c(a){return A.u(a,new Error())},
u(a,b){var t
if(a==null)a=new A.aV()
b.dartException=a
t=A.h8
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
h8(){return J.b6(this.dartException)},
d9(a,b){throw A.u(a,b==null?new Error():b)},
bP(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.d9(A.fi(a,b,c),t)},
fi(a,b,c){var t,s,r,q,p,o,n,m,l
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
return new A.aW("'"+t+"': Cannot "+p+" "+m+l+o)},
bO(a){throw A.c(A.O(a))},
T(a){var t,s,r,q,p,o
a=A.h6(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.m([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.cr(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
cs(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
du(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
cS(a,b){var t=b==null,s=t?null:b.method
return new A.bn(a,s,t?null:b.receiver)},
e3(a){if(a==null)return new A.co(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.af(a,a.dartException)
return A.fJ(a)},
af(a,b){if(u.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
fJ(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.f.a7(s,16)&8191)===10)switch(r){case 438:return A.af(a,A.cS(A.o(t)+" (Error "+r+")",null))
case 445:case 5007:A.o(t)
return A.af(a,new A.aQ())}}if(a instanceof TypeError){q=$.e4()
p=$.e5()
o=$.e6()
n=$.e7()
m=$.ea()
l=$.eb()
k=$.e9()
$.e8()
j=$.ed()
i=$.ec()
h=q.v(t)
if(h!=null)return A.af(a,A.cS(A.M(t),h))
else{h=p.v(t)
if(h!=null){h.method="call"
return A.af(a,A.cS(A.M(t),h))}else if(o.v(t)!=null||n.v(t)!=null||m.v(t)!=null||l.v(t)!=null||k.v(t)!=null||n.v(t)!=null||j.v(t)!=null||i.v(t)!=null){A.M(t)
return A.af(a,new A.aQ())}}return A.af(a,new A.bH(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.aT()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.af(a,new A.X(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.aT()
return a},
dZ(a){if(a==null)return J.N(a)
if(typeof a=="object")return A.bB(a)
return J.N(a)},
fS(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.q(0,a[t],a[s])}return b},
fq(a,b,c,d,e,f){u.Z.a(a)
switch(A.f(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.c(new A.ct("Unsupported number of arguments for wrapped closure"))},
fN(a,b){var t=a.$identity
if(!!t)return t
t=A.fO(a,b)
a.$identity=t
return t},
fO(a,b){var t
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
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.fq)},
ex(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.bE().constructor.prototype):Object.create(new A.ai(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.dg(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.et(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.dg(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
et(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.c("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.er)}throw A.c("Error in functionType of tearoff")},
eu(a,b,c,d){var t=A.df
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
dg(a,b,c,d){if(c)return A.ew(a,b,d)
return A.eu(b.length,d,a,b)},
ev(a,b,c,d){var t=A.df,s=A.es
switch(b?-1:a){case 0:throw A.c(new A.bD("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
ew(a,b,c){var t,s
if($.dd==null)$.dd=A.dc("interceptor")
if($.de==null)$.de=A.dc("receiver")
t=b.length
s=A.ev(t,c,a,b)
return s},
d2(a){return A.ex(a)},
er(a,b){return A.b4(v.typeUniverse,A.V(a.a),b)},
df(a){return a.a},
es(a){return a.b},
dc(a){var t,s,r,q=new A.ai("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.c(A.cP("Field name "+a+" not found."))},
fU(a){return v.getIsolateTag(a)},
h2(a){var t,s,r,q,p,o=A.M($.dW.$1(a)),n=$.cG[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.cK[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.cZ($.dU.$2(a,o))
if(r!=null){n=$.cG[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.cK[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.cM(t)
$.cG[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.cK[o]=t
return t}if(q==="-"){p=A.cM(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.e_(a,t)
if(q==="*")throw A.c(A.dv(o))
if(v.leafTags[o]===true){p=A.cM(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.e_(a,t)},
e_(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.d8(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
cM(a){return J.d8(a,!1,null,!!a.$iG)},
h4(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.cM(t)
else return J.d8(t,c,null,null)},
fY(){if(!0===$.d6)return
$.d6=!0
A.fZ()},
fZ(){var t,s,r,q,p,o,n,m
$.cG=Object.create(null)
$.cK=Object.create(null)
A.fX()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.e0.$1(p)
if(o!=null){n=A.h4(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
fX(){var t,s,r,q,p,o,n=B.A()
n=A.at(B.B,A.at(B.C,A.at(B.t,A.at(B.t,A.at(B.D,A.at(B.E,A.at(B.F(B.r),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.dW=new A.cH(q)
$.dU=new A.cI(p)
$.e0=new A.cJ(o)},
at(a,b){return a(b)||b},
fQ(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
h6(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
aq:function aq(a,b){this.a=a
this.b=b},
bh:function bh(){},
aj:function aj(a,b){this.a=a
this.$ti=b},
aS:function aS(){},
cr:function cr(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
aQ:function aQ(){},
bn:function bn(a,b,c){this.a=a
this.b=b
this.c=c},
bH:function bH(a){this.a=a},
co:function co(a){this.a=a},
E:function E(){},
bb:function bb(){},
bF:function bF(){},
bE:function bE(){},
ai:function ai(a,b){this.a=a
this.b=b},
bD:function bD(a){this.a=a},
S:function S(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
ch:function ch(a){this.a=a},
cl:function cl(a,b){this.a=a
this.b=b
this.c=null},
a7:function a7(a,b){this.a=a
this.$ti=b},
a6:function a6(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
aJ:function aJ(a,b){this.a=a
this.$ti=b},
aK:function aK(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
cH:function cH(a){this.a=a},
cI:function cI(a){this.a=a},
cJ:function cJ(a){this.a=a},
ac:function ac(){},
ap:function ap(){},
dN(a,b,c){if(a>>>0!==a||a>=c)throw A.c(A.d3(b,a))},
al:function al(){},
aN:function aN(){},
br:function br(){},
am:function am(){},
aL:function aL(){},
aM:function aM(){},
bs:function bs(){},
bt:function bt(){},
bu:function bu(){},
bv:function bv(){},
bw:function bw(){},
bx:function bx(){},
by:function by(){},
aO:function aO(){},
bz:function bz(){},
aY:function aY(){},
aZ:function aZ(){},
b_:function b_(){},
b0:function b0(){},
cV(a,b){var t=b.c
return t==null?b.c=A.b2(a,"dh",[b.x]):t},
ds(a){var t=a.w
if(t===6||t===7)return A.ds(a.x)
return t===11||t===12},
eM(a){return a.as},
au(a){return A.cA(v.typeUniverse,a,!1)},
h0(a,b){var t,s,r,q,p
if(a==null)return null
t=b.y
s=a.Q
if(s==null)s=a.Q=new Map()
r=b.as
q=s.get(r)
if(q!=null)return q
p=A.a3(v.typeUniverse,a.x,t,0)
s.set(r,p)
return p},
a3(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.a3(a0,t,a2,a3)
if(s===t)return a1
return A.dE(a0,s,!0)
case 7:t=a1.x
s=A.a3(a0,t,a2,a3)
if(s===t)return a1
return A.dD(a0,s,!0)
case 8:r=a1.y
q=A.as(a0,r,a2,a3)
if(q===r)return a1
return A.b2(a0,a1.x,q)
case 9:p=a1.x
o=A.a3(a0,p,a2,a3)
n=a1.y
m=A.as(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.cX(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.as(a0,k,a2,a3)
if(j===k)return a1
return A.dF(a0,l,j)
case 11:i=a1.x
h=A.a3(a0,i,a2,a3)
g=a1.y
f=A.fG(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.dC(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.as(a0,e,a2,a3)
p=a1.x
o=A.a3(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.cY(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.c(A.b8("Attempted to substitute unexpected RTI kind "+a))}},
as(a,b,c,d){var t,s,r,q,p=b.length,o=A.cB(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.a3(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
fH(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.cB(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.a3(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
fG(a,b,c,d){var t,s=b.a,r=A.as(a,s,c,d),q=b.b,p=A.as(a,q,c,d),o=b.c,n=A.fH(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.bJ()
t.a=r
t.b=p
t.c=n
return t},
m(a,b){a[v.arrayRti]=b
return a},
cF(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.fW(t)
return a.$S()}return null},
h_(a,b){var t
if(A.ds(b))if(a instanceof A.E){t=A.cF(a)
if(t!=null)return t}return A.V(a)},
V(a){if(a instanceof A.n)return A.C(a)
if(Array.isArray(a))return A.B(a)
return A.d_(J.ad(a))},
B(a){var t=a[v.arrayRti],s=u.q
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
C(a){var t=a.$ti
return t!=null?t:A.d_(a)},
d_(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.fp(a,t)},
fp(a,b){var t=a instanceof A.E?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.f9(v.typeUniverse,t.name)
b.$ccache=s
return s},
fW(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.cA(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
fV(a){return A.U(A.C(a))},
d5(a){var t=A.cF(a)
return A.U(t==null?A.V(a):t)},
d1(a){var t
if(a instanceof A.ac)return A.fR(a.$r,a.a4())
t=a instanceof A.E?A.cF(a):null
if(t!=null)return t
if(u.l.b(a))return J.ei(a).a
if(Array.isArray(a))return A.B(a)
return A.V(a)},
U(a){var t=a.r
return t==null?a.r=new A.cz(a):t},
fR(a,b){var t,s,r=b,q=r.length
if(q===0)return u.F
if(0>=q)return A.d(r,0)
t=A.b4(v.typeUniverse,A.d1(r[0]),"@<0>")
for(s=1;s<q;++s){if(!(s<r.length))return A.d(r,s)
t=A.dG(v.typeUniverse,t,A.d1(r[s]))}return A.b4(v.typeUniverse,t,a)},
R(a){return A.U(A.cA(v.typeUniverse,a,!1))},
fo(a){var t=this
t.b=A.fF(t)
return t.b(a)},
fF(a){var t,s,r,q,p
if(a===u.K)return A.fw
if(A.ae(a))return A.fA
t=a.w
if(t===6)return A.fm
if(t===1)return A.dS
if(t===7)return A.fr
s=A.fE(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.ae)){a.f="$i"+r
if(r==="b")return A.fu
if(a===u.m)return A.ft
return A.fz}}else if(t===10){q=A.fQ(a.x,a.y)
p=q==null?A.dS:q
return p==null?A.dM(p):p}return A.fk},
fE(a){if(a.w===8){if(a===u.p)return A.bN
if(a===u.i||a===u.H)return A.fv
if(a===u.N)return A.fy
if(a===u.y)return A.d0}return null},
fn(a){var t=this,s=A.fj
if(A.ae(t))s=A.ff
else if(t===u.K)s=A.dM
else if(A.av(t)){s=A.fl
if(t===u.I)s=A.a2
else if(t===u.v)s=A.cZ
else if(t===u.u)s=A.fb
else if(t===u.x)s=A.dL
else if(t===u.w)s=A.fc
else if(t===u.B)s=A.fe}else if(t===u.p)s=A.f
else if(t===u.N)s=A.M
else if(t===u.y)s=A.cC
else if(t===u.H)s=A.dK
else if(t===u.i)s=A.dJ
else if(t===u.m)s=A.fd
t.a=s
return t.a(a)},
fk(a){var t=this
if(a==null)return A.av(t)
return A.dX(v.typeUniverse,A.h_(a,t),t)},
fm(a){if(a==null)return!0
return this.x.b(a)},
fz(a){var t,s=this
if(a==null)return A.av(s)
t=s.f
if(a instanceof A.n)return!!a[t]
return!!J.ad(a)[t]},
fu(a){var t,s=this
if(a==null)return A.av(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.n)return!!a[t]
return!!J.ad(a)[t]},
ft(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.n)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
dR(a){if(typeof a=="object"){if(a instanceof A.n)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
fj(a){var t=this
if(a==null){if(A.av(t))return a}else if(t.b(a))return a
throw A.u(A.dO(a,t),new Error())},
fl(a){var t=this
if(a==null||t.b(a))return a
throw A.u(A.dO(a,t),new Error())},
dO(a,b){return new A.ar("TypeError: "+A.dw(a,A.D(b,null)))},
fM(a,b,c,d){if(A.dX(v.typeUniverse,a,b))return a
throw A.u(A.f1("The type argument '"+A.D(a,null)+"' is not a subtype of the type variable bound '"+A.D(b,null)+"' of type variable '"+c+"' in '"+d+"'."),new Error())},
dw(a,b){return A.bf(a)+": type '"+A.D(A.d1(a),null)+"' is not a subtype of type '"+b+"'"},
f1(a){return new A.ar("TypeError: "+a)},
L(a,b){return new A.ar("TypeError: "+A.dw(a,b))},
fr(a){var t=this
return t.x.b(a)||A.cV(v.typeUniverse,t).b(a)},
fw(a){return a!=null},
dM(a){if(a!=null)return a
throw A.u(A.L(a,"Object"),new Error())},
fA(a){return!0},
ff(a){return a},
dS(a){return!1},
d0(a){return!0===a||!1===a},
cC(a){if(!0===a)return!0
if(!1===a)return!1
throw A.u(A.L(a,"bool"),new Error())},
fb(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.u(A.L(a,"bool?"),new Error())},
dJ(a){if(typeof a=="number")return a
throw A.u(A.L(a,"double"),new Error())},
fc(a){if(typeof a=="number")return a
if(a==null)return a
throw A.u(A.L(a,"double?"),new Error())},
bN(a){return typeof a=="number"&&Math.floor(a)===a},
f(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.u(A.L(a,"int"),new Error())},
a2(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.u(A.L(a,"int?"),new Error())},
fv(a){return typeof a=="number"},
dK(a){if(typeof a=="number")return a
throw A.u(A.L(a,"num"),new Error())},
dL(a){if(typeof a=="number")return a
if(a==null)return a
throw A.u(A.L(a,"num?"),new Error())},
fy(a){return typeof a=="string"},
M(a){if(typeof a=="string")return a
throw A.u(A.L(a,"String"),new Error())},
cZ(a){if(typeof a=="string")return a
if(a==null)return a
throw A.u(A.L(a,"String?"),new Error())},
fd(a){if(A.dR(a))return a
throw A.u(A.L(a,"JSObject"),new Error())},
fe(a){if(a==null)return a
if(A.dR(a))return a
throw A.u(A.L(a,"JSObject?"),new Error())},
dT(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.D(a[r],b)
return t},
fD(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.dT(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.D(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
dP(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.m([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.a.n(a3,"T"+(s+r))
for(q=u.X,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.d(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.D(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.D(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.D(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.D(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.D(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
D(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.D(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.D(a.x,b)+">"
if(m===8){q=A.fI(a.x)
p=a.y
return p.length>0?q+("<"+A.dT(p,b)+">"):q}if(m===10)return A.fD(a,b)
if(m===11)return A.dP(a,b,null)
if(m===12)return A.dP(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.d(b,o)
return b[o]}return"?"},
fI(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
fa(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
f9(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.cA(a,b,!1)
else if(typeof n=="number"){t=n
s=A.b3(a,5,"#")
r=A.cB(t)
for(q=0;q<t;++q)r[q]=s
p=A.b2(a,b,r)
o[b]=p
return p}else return n},
f8(a,b){return A.dH(a.tR,b)},
f7(a,b){return A.dH(a.eT,b)},
cA(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.dA(A.dy(a,null,b,!1))
s.set(b,t)
return t},
b4(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.dA(A.dy(a,b,c,!0))
r.set(c,s)
return s},
dG(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.cX(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
a1(a,b){b.a=A.fn
b.b=A.fo
return b},
b3(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.Q(null,null)
t.w=b
t.as=c
s=A.a1(a,t)
a.eC.set(c,s)
return s},
dE(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.f5(a,b,s,c)
a.eC.set(s,t)
return t},
f5(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.ae(b))if(!(b===u.P||b===u.T))if(t!==6)s=t===7&&A.av(b.x)
if(s)return b
else if(t===1)return u.P}r=new A.Q(null,null)
r.w=6
r.x=b
r.as=c
return A.a1(a,r)},
dD(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.f3(a,b,s,c)
a.eC.set(s,t)
return t},
f3(a,b,c,d){var t,s
if(d){t=b.w
if(A.ae(b)||b===u.K)return b
else if(t===1)return A.b2(a,"dh",[b])
else if(b===u.P||b===u.T)return u.Q}s=new A.Q(null,null)
s.w=7
s.x=b
s.as=c
return A.a1(a,s)},
f6(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.Q(null,null)
t.w=13
t.x=b
t.as=r
s=A.a1(a,t)
a.eC.set(r,s)
return s},
b1(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
f2(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
b2(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.b1(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.Q(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.a1(a,s)
a.eC.set(q,r)
return r},
cX(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.b1(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.Q(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.a1(a,p)
a.eC.set(r,o)
return o},
dF(a,b,c){var t,s,r="+"+(b+"("+A.b1(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.Q(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.a1(a,t)
a.eC.set(r,s)
return s},
dC(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.b1(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.b1(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.f2(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.Q(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.a1(a,q)
a.eC.set(s,p)
return p},
cY(a,b,c,d){var t,s=b.as+("<"+A.b1(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.f4(a,b,c,s,d)
a.eC.set(s,t)
return t},
f4(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.cB(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.a3(a,b,s,0)
n=A.as(a,c,s,0)
return A.cY(a,o,n,c!==n)}}m=new A.Q(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.a1(a,m)},
dy(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
dA(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.eX(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.dz(a,s,m,l,!1)
else if(r===46)s=A.dz(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.ab(a.u,a.e,l.pop()))
break
case 94:l.push(A.f6(a.u,l.pop()))
break
case 35:l.push(A.b3(a.u,5,"#"))
break
case 64:l.push(A.b3(a.u,2,"@"))
break
case 126:l.push(A.b3(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.eZ(a,l)
break
case 38:A.eY(a,l)
break
case 63:q=a.u
l.push(A.dE(q,A.ab(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.dD(q,A.ab(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.eW(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.dB(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.f0(a.u,a.e,p)
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
return A.ab(a.u,a.e,n)},
eX(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
dz(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.fa(t,p.x)[q]
if(o==null)A.d9('No "'+q+'" in "'+A.eM(p)+'"')
d.push(A.b4(t,p,o))}else d.push(q)
return n},
eZ(a,b){var t,s=a.u,r=A.dx(a,b),q=b.pop()
if(typeof q=="string")b.push(A.b2(s,q,r))
else{t=A.ab(s,a.e,q)
switch(t.w){case 11:b.push(A.cY(s,t,r,a.n))
break
default:b.push(A.cX(s,t,r))
break}}},
eW(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.dx(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.ab(q,a.e,p)
r=new A.bJ()
r.a=t
r.b=o
r.c=n
b.push(A.dC(q,s,r))
return
case-4:b.push(A.dF(q,b.pop(),t))
return
default:throw A.c(A.b8("Unexpected state under `()`: "+A.o(p)))}},
eY(a,b){var t=b.pop()
if(0===t){b.push(A.b3(a.u,1,"0&"))
return}if(1===t){b.push(A.b3(a.u,4,"1&"))
return}throw A.c(A.b8("Unexpected extended operation "+A.o(t)))},
dx(a,b){var t=b.splice(a.p)
A.dB(a.u,a.e,t)
a.p=b.pop()
return t},
ab(a,b,c){if(typeof c=="string")return A.b2(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.f_(a,b,c)}else return c},
dB(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.ab(a,b,c[t])},
f0(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.ab(a,b,c[t])},
f_(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.c(A.b8("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.c(A.b8("Bad index "+c+" for "+b.i(0)))},
dX(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.r(a,b,null,c,null)
s.set(c,t)}return t},
r(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.ae(d))return!0
t=b.w
if(t===4)return!0
if(A.ae(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.r(a,c[b.x],c,d,e))return!0
r=d.w
q=u.P
if(b===q||b===u.T){if(r===7)return A.r(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.r(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.r(a,b.x,c,d,e))return!1
return A.r(a,A.cV(a,b),c,d,e)}if(t===6)return A.r(a,q,c,d,e)&&A.r(a,b.x,c,d,e)
if(r===7){if(A.r(a,b,c,d.x,e))return!0
return A.r(a,b,c,A.cV(a,d),e)}if(r===6)return A.r(a,b,c,q,e)||A.r(a,b,c,d.x,e)
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
if(!A.r(a,k,c,j,e)||!A.r(a,j,e,k,c))return!1}return A.dQ(a,b.x,c,d.x,e)}if(r===11){if(b===u.g)return!0
if(q)return!1
return A.dQ(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.fs(a,b,c,d,e)}if(p&&r===10)return A.fx(a,b,c,d,e)
return!1},
dQ(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.r(a2,a3.x,a4,a5.x,a6))return!1
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
if(!A.r(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.r(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.r(a2,l[i],a6,h,a4))return!1}g=t.c
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
if(!A.r(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
fs(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.b4(a,b,s[p])
return A.dI(a,q,null,c,d.y,e)}return A.dI(a,b.y,null,c,d.y,e)},
dI(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.r(a,b[t],d,e[t],f))return!1
return!0},
fx(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.r(a,s[t],c,r[t],e))return!1
return!0},
av(a){var t=a.w,s=!0
if(!(a===u.P||a===u.T))if(!A.ae(a))if(t!==6)s=t===7&&A.av(a.x)
return s},
ae(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.X},
dH(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
cB(a){return a>0?new Array(a):v.typeUniverse.sEA},
Q:function Q(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
bJ:function bJ(){this.c=this.b=this.a=null},
cz:function cz(a){this.a=a},
bI:function bI(){},
ar:function ar(a){this.a=a},
eH(a,b){return new A.S(a.h("@<0>").B(b).h("S<1,2>"))},
H(a,b,c){return b.h("@<0>").B(c).h("dm<1,2>").a(A.fS(a,new A.S(b.h("@<0>").B(c).h("S<1,2>"))))},
cT(a,b){return new A.S(a.h("@<0>").B(b).h("S<1,2>"))},
cU(a,b,c){var t=A.eH(b,c)
a.D(0,new A.cm(t,b,c))
return t},
dn(a){var t,s
if(A.d7(a))return"{...}"
t=new A.an("")
try{s={}
B.a.n($.J,a)
t.a+="{"
s.a=!0
a.D(0,new A.cn(s,t))
t.a+="}"}finally{if(0>=$.J.length)return A.d($.J,-1)
$.J.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
cm:function cm(a,b,c){this.a=a
this.b=b
this.c=c},
j:function j(){},
F:function F(){},
cn:function cn(a,b){this.a=a
this.b=b},
fC(a,b){var t,s,r,q=null
try{q=JSON.parse(a)}catch(s){t=A.e3(s)
r=String(t)
throw A.c(new A.aA(r))}r=A.cD(q)
return r},
cD(a){var t
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.bL(a,Object.create(null))
for(t=0;t<a.length;++t)a[t]=A.cD(a[t])
return a},
dl(a,b,c){return new A.aH(a,b)},
fh(a){return a.J()},
eU(a,b){return new A.cv(a,[],A.fP())},
eV(a,b,c){var t,s=new A.an(""),r=A.eU(s,b)
r.S(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
bL:function bL(a,b){this.a=a
this.b=b
this.c=null},
bM:function bM(a){this.a=a},
bc:function bc(){},
be:function be(){},
aH:function aH(a,b){this.a=a
this.b=b},
bo:function bo(a,b){this.a=a
this.b=b},
ci:function ci(){},
ck:function ck(a){this.b=a},
cj:function cj(a){this.a=a},
cw:function cw(){},
cx:function cx(a,b){this.a=a
this.b=b},
cv:function cv(a,b,c){this.c=a
this.a=b
this.b=c},
bq(a,b,c,d){var t,s=c?J.dk(a,d):J.eE(a,d)
if(a!==0&&b!=null)for(t=0;t<s.length;++t)s[t]=b
return s},
eI(a,b,c){var t,s,r=A.m([],c.h("i<0>"))
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.bO)(a),++s)B.a.n(r,c.a(a[s]))
r.$flags=1
return r},
bp(a,b){var t,s
if(Array.isArray(a))return A.m(a.slice(0),b.h("i<0>"))
t=A.m([],b.h("i<0>"))
for(s=J.aw(a);s.k();)B.a.n(t,s.gm())
return t},
eJ(a,b,c){var t,s=J.dk(a,c)
for(t=0;t<a;++t)B.a.q(s,t,b.$1(t))
return s},
dt(a,b,c){var t=J.aw(b)
if(!t.k())return a
if(c.length===0){do a+=A.o(t.gm())
while(t.k())}else{a+=A.o(t.gm())
while(t.k())a=a+c+A.o(t.gm())}return a},
bf(a){if(typeof a=="number"||A.d0(a)||a==null)return J.b6(a)
if(typeof a=="string")return JSON.stringify(a)
return A.dr(a)},
b8(a){return new A.b7(a)},
cP(a){return new A.X(!1,null,null,a)},
cp(a,b,c,d,e){return new A.aR(b,c,!0,a,d,"Invalid value")},
eL(a,b,c){if(0>a||a>c)throw A.c(A.cp(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.c(A.cp(b,a,c,"end",null))
return b}return c},
di(a,b,c,d){return new A.bg(b,!0,a,d,"Index out of range")},
eT(a){return new A.aW(a)},
dv(a){return new A.bG(a)},
eN(a){return new A.aU(a)},
O(a){return new A.bd(a)},
eD(a,b,c){var t,s
if(A.d7(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.m([],u.s)
B.a.n($.J,a)
try{A.fB(a,t)}finally{if(0>=$.J.length)return A.d($.J,-1)
$.J.pop()}s=A.dt(b,u.U.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
dj(a,b,c){var t,s
if(A.d7(a))return b+"..."+c
t=new A.an(b)
B.a.n($.J,a)
try{s=t
s.a=A.dt(s.a,a,", ")}finally{if(0>=$.J.length)return A.d($.J,-1)
$.J.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
fB(a,b){var t,s,r,q,p,o,n,m=a.gt(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.k())return
t=A.o(m.gm())
B.a.n(b,t)
l+=t.length+2;++k}if(!m.k()){if(k<=5)return
if(0>=b.length)return A.d(b,-1)
s=b.pop()
if(0>=b.length)return A.d(b,-1)
r=b.pop()}else{q=m.gm();++k
if(!m.k()){if(k<=4){B.a.n(b,A.o(q))
return}s=A.o(q)
if(0>=b.length)return A.d(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gm();++k
for(;m.k();q=p,p=o){o=m.gm();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.d(b,-1)
l-=b.pop().length+2;--k}B.a.n(b,"...")
return}}r=A.o(q)
s=A.o(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.d(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.n(b,n)
B.a.n(b,r)
B.a.n(b,s)},
dp(a,b,c,d){var t
if(B.m===c){t=J.N(a)
b=J.N(b)
return A.cW(A.a0(A.a0($.cN(),t),b))}if(B.m===d){t=J.N(a)
b=J.N(b)
c=J.N(c)
return A.cW(A.a0(A.a0(A.a0($.cN(),t),b),c))}t=J.N(a)
b=J.N(b)
c=J.N(c)
d=J.N(d)
d=A.cW(A.a0(A.a0(A.a0(A.a0($.cN(),t),b),c),d))
return d},
p:function p(){},
b7:function b7(a){this.a=a},
aV:function aV(){},
X:function X(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
aR:function aR(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
bg:function bg(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
aW:function aW(a){this.a=a},
bG:function bG(a){this.a=a},
aU:function aU(a){this.a=a},
bd:function bd(a){this.a=a},
aT:function aT(){},
ct:function ct(a){this.a=a},
aA:function aA(a){this.a=a},
e:function e(){},
a9:function a9(a,b,c){this.a=a
this.b=b
this.$ti=c},
aP:function aP(){},
n:function n(){},
an:function an(a){this.a=a},
dY(a,b,c){A.fM(c,u.H,"T","max")
return Math.max(c.a(a),c.a(b))},
bK:function bK(){},
h3(){var t,s=v.G.globalThis,r=new A.cL()
if(typeof r=="function")A.d9(A.cP("Attempting to rewrap a JS function."))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.fg,r)
t[$.da()]=r
s.blockBattleRules=t},
cL:function cL(){},
fL(a,b){var t=2147483646,s={}
s.a=B.f.E(a+B.f.E(b,t)*104729,t)+1
return A.eJ(3,new A.cE(s),u.k)},
el(a,b,c,d){var t=new A.y(a,c,b)
if(d)t.d=A.em(t.ga5())
return t},
ek(a){var t,s,r,q,p,o,n,m,l
if(!J.ag(a.j(0,"version"),1))throw A.c(B.G)
t=A.M(a.j(0,"roomId"))
s=A.f(a.j(0,"seed"))
r=A.f(a.j(0,"createdAt"))
q=A.m([],u.O)
p=new A.b9(t,s,r,q,A.m([],u.Y))
p.e=A.M(a.j(0,"status"))
p.f=A.f(a.j(0,"revision"))
p.r=A.a2(a.j(0,"startAt"))
p.w=A.a2(a.j(0,"endedAt"))
p.x=A.a2(a.j(0,"winner"))
p.y=A.cZ(a.j(0,"reason"))
for(t=J.aw(u.U.a(a.j(0,"players"))),r=u.f,o=u.N,n=u.z;t.k();){m=A.cU(r.a(t.gm()),o,n)
l=new A.y(A.f(m.j(0,"id")),s,A.M(m.j(0,"name")))
l.e=A.f(m.j(0,"nextSet"))
l.f=A.f(m.j(0,"lives"))
l.r=A.f(m.j(0,"boardOuts"))
l.w=A.f(m.j(0,"thresholds"))
l.x=A.f(m.j(0,"damage"))
l.y=A.f(m.j(0,"lastMove"))
l.z=A.cC(m.j(0,"ready"))
l.Q=A.cC(m.j(0,"connected"))
l.as=A.a2(m.j(0,"disconnectAt"))
m=A.eq(A.cU(r.a(m.j(0,"game")),o,n),l.ga5())
m.toString
l.d=m
B.a.n(q,l)}return p},
cE:function cE(a){this.a=a},
y:function y(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=$
_.e=0
_.f=5
_.y=_.x=_.w=_.r=0
_.Q=_.z=!1
_.as=null},
b9:function b9(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e="waiting"
_.f=0
_.y=_.x=_.w=_.r=null
_.z=e},
bY:function bY(a){this.a=a},
bV:function bV(a){this.a=a},
bR:function bR(){},
bT:function bT(a){this.a=a},
bU:function bU(){},
bS:function bS(a){this.a=a},
bW:function bW(){},
bX:function bX(a){this.a=a},
bZ:function bZ(){},
em(a){var t,s,r=J.cf(8,u.R)
for(t=u.I,s=0;s<8;++s)r[s]=A.bq(8,null,!1,t)
t=A.m([null,null,null],u.b)
t=new A.ba(B.u,a,r,t)
t.a_()
return t},
en(a,b){var t,s,r=J.cf(8,u.R)
for(t=u.I,s=0;s<8;++s)r[s]=A.bq(8,null,!1,t)
t=A.m([null,null,null],u.b)
return new A.ba(B.u,a,r,t)},
cQ(a){var t,s,r,q,p,o,n=u.t,m=A.m([],n)
for(t=0;t<8;++t){if(!(t<a.length))return A.d(a,t)
if(J.bQ(a[t],new A.c_()))m.push(t)}n=A.m([],n)
for(s=u._,r=0;r<8;++r){q=A.m(new Array(8),s)
for(p=a.length,t=0;t<8;++t){if(!(t<p))return A.d(a,t)
o=a[t]
if(!(r<o.length))return A.d(o,r)
q[t]=o[r]}if(B.a.G(q,new A.c0()))n.push(r)}return new A.aq(m,n)},
eo(a){var t,s,r,q,p,o,n=A.cQ(a),m=n.a,l=n.b,k=u.p
k=A.cT(k,k)
for(t=m.length,s=0;s<m.length;m.length===t||(0,A.bO)(m),++s){r=m[s]
for(q=r*8,p=0;p<8;++p){if(!(r<a.length))return A.d(a,r)
o=a[r]
if(!(p<o.length))return A.d(o,p)
o=o[p]
o.toString
k.q(0,q+p,o)}}for(t=l.length,s=0;s<l.length;l.length===t||(0,A.bO)(l),++s){p=l[s]
for(r=0;r<8;++r){if(!(r<a.length))return A.d(a,r)
q=a[r]
if(!(p<q.length))return A.d(q,p)
q=q[p]
q.toString
k.q(0,r*8+p,q)}}for(t=new A.a6(k,k.r,k.e,k.$ti.h("a6<1>"));t.k();){q=t.d
o=B.f.a8(q,8)
if(!(o>=0&&o<a.length))return A.d(a,o)
J.b5(a[o],B.f.E(q,8),null)}return k},
ep(a,b,c,d){var t,s,r,q,p,o=b.a
if(!(o>=0&&o<33))return A.d(B.j,o)
o=B.j[o]
t=o.length
s=b.b
r=0
for(;r<t;++r){q=o[r]
p=c+q[0]
if(!(p>=0&&p<a.length))return A.d(a,p)
J.b5(a[p],d+q[1],s)}},
eq(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h=null,g=null
try{if(!J.ag(a.j(0,"version"),1))return h
l=u.j
k=J.cO(l.a(a.j(0,"grid")),new A.c7(),u.R)
j=A.bp(k,k.$ti.h("x.E"))
t=j
if(J.ah(t)!==8||J.db(t,new A.c8()))return h
l=J.cO(l.a(a.j(0,"tray")),new A.c9(),u.k)
l=A.bp(l,l.$ti.h("x.E"))
s=l
if(J.ah(s)!==3||J.bQ(s,new A.ca()))return h
r=A.f(a.j(0,"score"))
q=A.f(a.j(0,"combo"))
p=A.f(a.j(0,"misses"))
l=r
if(typeof l!=="number")return l.a1()
k=!0
if(!(l<0)){l=q
if(typeof l!=="number")return l.a1()
if(!(l<0)){l=p
if(typeof l!=="number")return l.a1()
if(!(l<0)){l=p
if(typeof l!=="number")return l.aY()
if(!(l>=3))l=J.ag(q,0)&&!J.ag(p,0)
else l=k}else l=k}else l=k}else l=k
if(l)return h
o=null
n=null
m=A.cQ(t)
o=m.a
n=m.b
if(J.ah(o)!==0||J.ah(n)!==0)return h
l=A.en(b,g)
l.sa0(t)
l.saT(s)
l.sak(r)
l.saB(q)
l.saM(p)
l.w=A.cC(a.j(0,"reviveUsed"))
return l}catch(i){return h}},
z:function z(a,b){this.a=a
this.b=b},
cd:function cd(){},
cc:function cc(){},
cb:function cb(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ba:function ba(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.r=_.f=_.e=0
_.w=!1},
c1:function c1(a,b,c){this.a=a
this.b=b
this.c=c},
c2:function c2(a){this.a=a},
c_:function c_(){},
c0:function c0(){},
c4:function c4(){},
c3:function c3(){},
c5:function c5(){},
c7:function c7(){},
c6:function c6(){},
c8:function c8(){},
c9:function c9(){},
ca:function ca(){},
h7(a){throw A.u(new A.aI("Field '"+a+"' has been assigned during initialization."),new Error())},
e1(){throw A.u(A.eG(""),new Error())},
fg(a,b,c){u.Z.a(a)
if(A.f(c)>=1)return a.$1(b)
return a.$0()}},B={}
var w=[A,J,B]
var $={}
A.cR.prototype={}
J.bi.prototype={
C(a,b){return a===b},
gu(a){return A.bB(a)},
i(a){return"Instance of '"+A.bC(a)+"'"},
gp(a){return A.U(A.d_(this))}}
J.bl.prototype={
i(a){return String(a)},
gu(a){return a?519018:218159},
gp(a){return A.U(u.y)},
$ih:1,
$it:1}
J.aC.prototype={
C(a,b){return null==b},
i(a){return"null"},
gu(a){return 0},
$ih:1}
J.aF.prototype={$iq:1}
J.a_.prototype={
gu(a){return 0},
i(a){return String(a)}}
J.bA.prototype={}
J.ao.prototype={}
J.Z.prototype={
i(a){var t=a[$.da()]
if(t==null)return this.am(a)
return"JavaScript function for "+J.b6(t)},
$iY:1}
J.aE.prototype={
gu(a){return 0},
i(a){return String(a)}}
J.aG.prototype={
gu(a){return 0},
i(a){return String(a)}}
J.i.prototype={
n(a,b){A.B(a).c.a(b)
a.$flags&1&&A.bP(a,29)
a.push(b)},
ag(a,b,c){var t=A.B(a)
return new A.I(a,t.B(c).h("1(2)").a(b),t.h("@<1>").B(c).h("I<1,2>"))},
aK(a,b){var t,s=A.bq(a.length,"",!1,u.N)
for(t=0;t<a.length;++t)this.q(s,t,A.o(a[t]))
return s.join(b)},
ab(a,b){var t,s,r
A.B(a).h("t(1)").a(b)
t=a.length
for(s=0;s<t;++s){r=a[s]
if(b.$1(r))return r
if(a.length!==t)throw A.c(A.O(a))}throw A.c(A.bj())},
A(a,b){if(!(b<a.length))return A.d(a,b)
return a[b]},
gR(a){if(a.length>0)return a[0]
throw A.c(A.bj())},
O(a,b){var t,s
A.B(a).h("t(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(b.$1(a[s]))return!0
if(a.length!==t)throw A.c(A.O(a))}return!1},
G(a,b){var t,s
A.B(a).h("t(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(!b.$1(a[s]))return!1
if(a.length!==t)throw A.c(A.O(a))}return!0},
al(a,b){var t,s,r,q,p,o=A.B(a)
o.h("a(1,1)?").a(b)
a.$flags&2&&A.bP(a,"sort")
t=a.length
if(t<2)return
if(t===2){s=a[0]
r=a[1]
o=b.$2(s,r)
if(typeof o!=="number")return o.aZ()
if(o>0){a[0]=r
a[1]=s}return}q=0
if(o.c.b(null))for(p=0;p<a.length;++p)if(a[p]===void 0){a[p]=null;++q}a.sort(A.fN(b,2))
if(q>0)this.ar(a,q)},
ar(a,b){var t,s=a.length
for(;t=s-1,s>0;s=t)if(a[t]===null){a[t]=void 0;--b
if(b===0)break}},
gaf(a){return a.length!==0},
i(a){return A.dj(a,"[","]")},
gt(a){return new J.a5(a,a.length,A.B(a).h("a5<1>"))},
gu(a){return A.bB(a)},
gl(a){return a.length},
q(a,b,c){A.B(a).c.a(c)
a.$flags&2&&A.bP(a)
if(!(b>=0&&b<a.length))throw A.c(A.d3(a,b))
a[b]=c},
$ie:1,
$ib:1}
J.bk.prototype={
aU(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.bC(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.cg.prototype={}
J.a5.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.bO(r)
throw A.c(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0},
$iK:1}
J.aD.prototype={
P(a,b){var t
A.dK(b)
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){t=this.gZ(b)
if(this.gZ(a)===t)return 0
if(this.gZ(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gZ(a){return a===0?1/a<0:a<0},
az(a,b,c){if(B.f.P(b,c)>0)throw A.c(A.fK(b))
if(this.P(a,b)<0)return b
if(this.P(a,c)>0)return c
return a},
i(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gu(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
E(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
return t+b},
a8(a,b){return(a|0)===a?a/b|0:this.av(a,b)},
av(a,b){var t=a/b
if(t>=-2147483648&&t<=2147483647)return t|0
if(t>0){if(t!==1/0)return Math.floor(t)}else if(t>-1/0)return Math.ceil(t)
throw A.c(A.eT("Result of truncating division is "+A.o(t)+": "+A.o(a)+" ~/ "+b))},
a7(a,b){var t
if(a>0)t=this.au(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
au(a,b){return b>31?0:a>>>b},
gp(a){return A.U(u.H)},
$ik:1,
$iW:1}
J.aB.prototype={
gp(a){return A.U(u.p)},
$ih:1,
$ia:1}
J.bm.prototype={
gp(a){return A.U(u.i)},
$ih:1}
J.ak.prototype={
L(a,b,c){return a.substring(b,A.eL(b,c,a.length))},
i(a){return a},
gu(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gp(a){return A.U(u.N)},
gl(a){return a.length},
$ih:1,
$il:1}
A.aI.prototype={
i(a){return"LateInitializationError: "+this.a}}
A.cq.prototype={}
A.ax.prototype={}
A.x.prototype={
gt(a){var t=this
return new A.a8(t,t.gl(t),A.C(t).h("a8<x.E>"))},
gH(a){return this.gl(this)===0},
ah(a,b){var t,s,r,q=this
A.C(q).h("x.E(x.E,x.E)").a(b)
t=q.gl(q)
if(t===0)throw A.c(A.bj())
s=q.A(0,0)
for(r=1;r<t;++r){s=b.$2(s,q.A(0,r))
if(t!==q.gl(q))throw A.c(A.O(q))}return s}}
A.a8.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t,s=this,r=s.a,q=J.dV(r),p=q.gl(r)
if(s.b!==p)throw A.c(A.O(r))
t=s.c
if(t>=p){s.d=null
return!1}s.d=q.A(r,t);++s.c
return!0},
$iK:1}
A.I.prototype={
gl(a){return J.ah(this.a)},
A(a,b){return this.b.$1(J.eg(this.a,b))}}
A.aa.prototype={
gt(a){return new A.aX(J.aw(this.a),this.b,this.$ti.h("aX<1>"))}}
A.aX.prototype={
k(){var t,s
for(t=this.a,s=this.b;t.k();)if(s.$1(t.gm()))return!0
return!1},
gm(){return this.a.gm()},
$iK:1}
A.ce.prototype={
gt(a){return new A.az(J.aw(this.a),this.b,B.z,this.$ti.h("az<1,2>"))}}
A.az.prototype={
gm(){var t=this.d
return t==null?this.$ti.y[1].a(t):t},
k(){var t,s,r=this,q=r.c
if(q==null)return!1
for(t=r.a,s=r.b;!q.k();){r.d=null
if(t.k()){r.c=null
q=J.aw(s.$1(t.gm()))
r.c=q}else return!1}r.d=r.c.gm()
return!0},
$iK:1}
A.ay.prototype={
k(){return!1},
gm(){throw A.c(A.bj())},
$iK:1}
A.A.prototype={}
A.aq.prototype={$r:"+(1,2)",$s:1}
A.bh.prototype={
C(a,b){if(b==null)return!1
return b instanceof A.aj&&this.a.C(0,b.a)&&A.d5(this)===A.d5(b)},
gu(a){return A.dp(this.a,A.d5(this),B.m,B.m)},
i(a){var t=B.a.aK([A.U(this.$ti.c)],", ")
return this.a.i(0)+" with "+("<"+t+">")}}
A.aj.prototype={
$2(a,b){return this.a.$1$2(a,b,this.$ti.y[0])},
$S(){return A.h0(A.cF(this.a),this.$ti)}}
A.aS.prototype={}
A.cr.prototype={
v(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
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
A.aQ.prototype={
i(a){return"Null check operator used on a null value"}}
A.bn.prototype={
i(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.bH.prototype={
i(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.co.prototype={
i(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.E.prototype={
i(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.e2(s==null?"unknown":s)+"'"},
$iY:1,
gaX(){return this},
$C:"$1",
$R:1,
$D:null}
A.bb.prototype={$C:"$2",$R:2}
A.bF.prototype={}
A.bE.prototype={
i(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.e2(t)+"'"}}
A.ai.prototype={
C(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.ai))return!1
return this.$_target===b.$_target&&this.a===b.a},
gu(a){return(A.dZ(this.a)^A.bB(this.$_target))>>>0},
i(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.bC(this.a)+"'")}}
A.bD.prototype={
i(a){return"RuntimeError: "+this.a}}
A.S.prototype={
gl(a){return this.a},
gH(a){return this.a===0},
gI(){return new A.a7(this,A.C(this).h("a7<1>"))},
aw(a,b){A.C(this).h("P<1,2>").a(b).D(0,new A.ch(this))},
j(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.aI(b)},
aI(a){var t,s,r=this.d
if(r==null)return null
t=r[this.ad(a)]
s=this.ae(t,a)
if(s<0)return null
return t[s].b},
q(a,b,c){var t,s,r=this,q=A.C(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.a2(t==null?r.b=r.W():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.a2(s==null?r.c=r.W():s,b,c)}else r.aJ(b,c)},
aJ(a,b){var t,s,r,q,p=this,o=A.C(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.W()
s=p.ad(a)
r=t[s]
if(r==null)t[s]=[p.X(a,b)]
else{q=p.ae(r,a)
if(q>=0)r[q].b=b
else r.push(p.X(a,b))}},
D(a,b){var t,s,r=this
A.C(r).h("~(1,2)").a(b)
t=r.e
s=r.r
while(t!=null){b.$2(t.a,t.b)
if(s!==r.r)throw A.c(A.O(r))
t=t.c}},
a2(a,b,c){var t,s=A.C(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.X(b,c)
else t.b=c},
X(a,b){var t=this,s=A.C(t),r=new A.cl(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else t.f=t.f.c=r;++t.a
t.r=t.r+1&1073741823
return r},
ad(a){return J.N(a)&1073741823},
ae(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.ag(a[s].a,b))return s
return-1},
i(a){return A.dn(this)},
W(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$idm:1}
A.ch.prototype={
$2(a,b){var t=this.a,s=A.C(t)
t.q(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.C(this.a).h("~(1,2)")}}
A.cl.prototype={}
A.a7.prototype={
gl(a){return this.a.a},
gH(a){return this.a.a===0},
gt(a){var t=this.a
return new A.a6(t,t.r,t.e,this.$ti.h("a6<1>"))}}
A.a6.prototype={
gm(){return this.d},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.c(A.O(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.a
s.c=t.c
return!0}},
$iK:1}
A.aJ.prototype={
gl(a){return this.a.a},
gt(a){var t=this.a
return new A.aK(t,t.r,t.e,this.$ti.h("aK<1,2>"))}}
A.aK.prototype={
gm(){var t=this.d
t.toString
return t},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.c(A.O(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=new A.a9(t.a,t.b,s.$ti.h("a9<1,2>"))
s.c=t.c
return!0}},
$iK:1}
A.cH.prototype={
$1(a){return this.a(a)},
$S:3}
A.cI.prototype={
$2(a,b){return this.a(a,b)},
$S:7}
A.cJ.prototype={
$1(a){return this.a(A.M(a))},
$S:8}
A.ac.prototype={
i(a){return this.a9(!1)},
a9(a){var t,s,r,q,p,o=this.ao(),n=this.a4(),m=(a?"Record ":"")+"("
for(t=o.length,s="",r=0;r<t;++r,s=", "){m+=s
q=o[r]
if(typeof q=="string")m=m+q+": "
if(!(r<n.length))return A.d(n,r)
p=n[r]
m=a?m+A.dr(p):m+A.o(p)}m+=")"
return m.charCodeAt(0)==0?m:m},
ao(){var t,s=this.$s
while($.cy.length<=s)B.a.n($.cy,null)
t=$.cy[s]
if(t==null){t=this.an()
B.a.q($.cy,s,t)}return t},
an(){var t,s,r,q=this.$r,p=q.indexOf("("),o=q.substring(1,p),n=q.substring(p),m=n==="()"?0:n.replace(/[^,]/g,"").length+1,l=u.K,k=J.cf(m,l)
for(t=0;t<m;++t)k[t]=t
if(o!==""){s=o.split(",")
t=s.length
for(r=m;t>0;){--r;--t
B.a.q(k,r,s[t])}}k=A.eI(k,!1,l)
k.$flags=3
return k}}
A.ap.prototype={
a4(){return[this.a,this.b]},
C(a,b){if(b==null)return!1
return b instanceof A.ap&&this.$s===b.$s&&J.ag(this.a,b.a)&&J.ag(this.b,b.b)},
gu(a){return A.dp(this.$s,this.a,this.b,B.m)}}
A.al.prototype={
gp(a){return B.am},
$ih:1}
A.aN.prototype={}
A.br.prototype={
gp(a){return B.an},
$ih:1}
A.am.prototype={
gl(a){return a.length},
$iG:1}
A.aL.prototype={
q(a,b,c){A.dJ(c)
a.$flags&2&&A.bP(a)
A.dN(b,a,a.length)
a[b]=c},
$ie:1,
$ib:1}
A.aM.prototype={
q(a,b,c){A.f(c)
a.$flags&2&&A.bP(a)
A.dN(b,a,a.length)
a[b]=c},
$ie:1,
$ib:1}
A.bs.prototype={
gp(a){return B.ao},
$ih:1}
A.bt.prototype={
gp(a){return B.ap},
$ih:1}
A.bu.prototype={
gp(a){return B.aq},
$ih:1}
A.bv.prototype={
gp(a){return B.ar},
$ih:1}
A.bw.prototype={
gp(a){return B.as},
$ih:1}
A.bx.prototype={
gp(a){return B.au},
$ih:1}
A.by.prototype={
gp(a){return B.av},
$ih:1}
A.aO.prototype={
gp(a){return B.aw},
gl(a){return a.length},
$ih:1}
A.bz.prototype={
gp(a){return B.ax},
gl(a){return a.length},
$ih:1}
A.aY.prototype={}
A.aZ.prototype={}
A.b_.prototype={}
A.b0.prototype={}
A.Q.prototype={
h(a){return A.b4(v.typeUniverse,this,a)},
B(a){return A.dG(v.typeUniverse,this,a)}}
A.bJ.prototype={}
A.cz.prototype={
i(a){return A.D(this.a,null)}}
A.bI.prototype={
i(a){return this.a}}
A.ar.prototype={}
A.cm.prototype={
$2(a,b){this.a.q(0,this.b.a(a),this.c.a(b))},
$S:9}
A.j.prototype={
gt(a){return new A.a8(a,a.length,A.V(a).h("a8<j.E>"))},
A(a,b){if(!(b<a.length))return A.d(a,b)
return a[b]},
gaf(a){return a.length!==0},
G(a,b){var t,s,r
A.V(a).h("t(j.E)").a(b)
t=a.length
for(s=t,r=0;r<t;++r){if(!(r<s))return A.d(a,r)
if(!b.$1(a[r]))return!1
s=a.length
if(t!==s)throw A.c(A.O(a))}return!0},
O(a,b){var t,s,r
A.V(a).h("t(j.E)").a(b)
t=a.length
for(s=t,r=0;r<t;++r){if(!(r<s))return A.d(a,r)
if(b.$1(a[r]))return!0
s=a.length
if(t!==s)throw A.c(A.O(a))}return!1},
ag(a,b,c){var t=A.V(a)
return new A.I(a,t.B(c).h("1(j.E)").a(b),t.h("@<j.E>").B(c).h("I<1,2>"))},
i(a){return A.dj(a,"[","]")}}
A.F.prototype={
D(a,b){var t,s,r,q=A.C(this)
q.h("~(F.K,F.V)").a(b)
for(t=this.gI(),t=t.gt(t),q=q.h("F.V");t.k();){s=t.gm()
r=this.j(0,s)
b.$2(s,r==null?q.a(r):r)}},
gl(a){var t=this.gI()
return t.gl(t)},
gH(a){var t=this.gI()
return t.gH(t)},
i(a){return A.dn(this)},
$iP:1}
A.cn.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.o(a)
s.a=(s.a+=t)+": "
t=A.o(b)
s.a+=t},
$S:4}
A.bL.prototype={
j(a,b){var t,s=this.b
if(s==null)return this.c.j(0,b)
else if(typeof b!="string")return null
else{t=s[b]
return typeof t=="undefined"?this.aq(b):t}},
gl(a){return this.b==null?this.c.a:this.M().length},
gH(a){return this.gl(0)===0},
gI(){if(this.b==null){var t=this.c
return new A.a7(t,A.C(t).h("a7<1>"))}return new A.bM(this)},
D(a,b){var t,s,r,q,p=this
u.G.a(b)
if(p.b==null)return p.c.D(0,b)
t=p.M()
for(s=0;s<t.length;++s){r=t[s]
q=p.b[r]
if(typeof q=="undefined"){q=A.cD(p.a[r])
p.b[r]=q}b.$2(r,q)
if(t!==p.c)throw A.c(A.O(p))}},
M(){var t=u.M.a(this.c)
if(t==null)t=this.c=A.m(Object.keys(this.a),u.s)
return t},
aq(a){var t
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
t=A.cD(this.a[a])
return this.b[a]=t}}
A.bM.prototype={
gl(a){return this.a.gl(0)},
A(a,b){var t=this.a
if(t.b==null)t=t.gI().A(0,b)
else{t=t.M()
if(!(b<t.length))return A.d(t,b)
t=t[b]}return t},
gt(a){var t=this.a
if(t.b==null){t=t.gI()
t=t.gt(t)}else{t=t.M()
t=new J.a5(t,t.length,A.B(t).h("a5<1>"))}return t}}
A.bc.prototype={}
A.be.prototype={}
A.aH.prototype={
i(a){var t=A.bf(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.bo.prototype={
i(a){return"Cyclic error in JSON stringify"}}
A.ci.prototype={
aC(a,b){var t=A.fC(a,this.gaD().a)
return t},
aa(a,b){var t=A.eV(a,this.gaF().b,null)
return t},
gaF(){return B.M},
gaD(){return B.L}}
A.ck.prototype={}
A.cj.prototype={}
A.cw.prototype={
aj(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.n.L(a,s,r)
s=r+1
p=A.w(92)
t.a+=p
p=A.w(117)
t.a+=p
p=A.w(100)
t.a+=p
p=q>>>8&15
p=A.w(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.w(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.w(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.n.L(a,s,r)
s=r+1
p=A.w(92)
t.a+=p
switch(q){case 8:p=A.w(98)
t.a+=p
break
case 9:p=A.w(116)
t.a+=p
break
case 10:p=A.w(110)
t.a+=p
break
case 12:p=A.w(102)
t.a+=p
break
case 13:p=A.w(114)
t.a+=p
break
default:p=A.w(117)
t.a+=p
p=A.w(48)
t.a=(t.a+=p)+p
p=q>>>4&15
p=A.w(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.w(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.n.L(a,s,r)
s=r+1
p=A.w(92)
t.a+=p
p=A.w(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.n.L(a,s,n)},
T(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.c(new A.bo(a,null))}B.a.n(t,a)},
S(a){var t,s,r,q,p=this
if(p.ai(a))return
p.T(a)
try{t=p.b.$1(a)
if(!p.ai(t)){r=A.dl(a,null,p.ga6())
throw A.c(r)}r=p.a
if(0>=r.length)return A.d(r,-1)
r.pop()}catch(q){s=A.e3(q)
r=A.dl(a,s,p.ga6())
throw A.c(r)}},
ai(a){var t,s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.c.a+=B.I.i(a)
return!0}else if(a===!0){r.c.a+="true"
return!0}else if(a===!1){r.c.a+="false"
return!0}else if(a==null){r.c.a+="null"
return!0}else if(typeof a=="string"){t=r.c
t.a+='"'
r.aj(a)
t.a+='"'
return!0}else if(u.j.b(a)){r.T(a)
r.aV(a)
t=r.a
if(0>=t.length)return A.d(t,-1)
t.pop()
return!0}else if(a instanceof A.F){r.T(a)
s=r.aW(a)
t=r.a
if(0>=t.length)return A.d(t,-1)
t.pop()
return s}else return!1},
aV(a){var t,s=this.c
s.a+="["
if(J.eh(a)){if(0>=a.length)return A.d(a,0)
this.S(a[0])
for(t=1;t<a.length;++t){s.a+=","
this.S(a[t])}}s.a+="]"},
aW(a){var t,s,r,q,p,o,n=this,m={}
if(a.gH(a)){n.c.a+="{}"
return!0}t=a.gl(a)*2
s=A.bq(t,null,!1,u.X)
r=m.a=0
m.b=!0
a.D(0,new A.cx(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.aj(A.M(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.d(s,o)
n.S(s[o])}q.a+="}"
return!0}}
A.cx.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.a.q(t,s.a++,a)
B.a.q(t,s.a++,b)},
$S:4}
A.cv.prototype={
ga6(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.p.prototype={}
A.b7.prototype={
i(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.bf(t)
return"Assertion failed"}}
A.aV.prototype={}
A.X.prototype={
gV(){return"Invalid argument"+(!this.a?"(s)":"")},
gU(){return""},
i(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.gV()+r+p
if(!t.a)return o
return o+t.gU()+": "+A.bf(t.gY())},
gY(){return this.b}}
A.aR.prototype={
gY(){return A.dL(this.b)},
gV(){return"RangeError"},
gU(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.o(r):""
else if(r==null)t=": Not greater than or equal to "+A.o(s)
else if(r>s)t=": Not in inclusive range "+A.o(s)+".."+A.o(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.o(s)
return t}}
A.bg.prototype={
gY(){return A.f(this.b)},
gV(){return"RangeError"},
gU(){if(A.f(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gl(a){return this.f}}
A.aW.prototype={
i(a){return"Unsupported operation: "+this.a}}
A.bG.prototype={
i(a){return"UnimplementedError: "+this.a}}
A.aU.prototype={
i(a){return"Bad state: "+this.a}}
A.bd.prototype={
i(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bf(t)+"."}}
A.aT.prototype={
i(a){return"Stack Overflow"},
$ip:1}
A.ct.prototype={
i(a){return"Exception: "+this.a}}
A.aA.prototype={
i(a){var t=this.a,s=""!==t?"FormatException: "+t:"FormatException"
return s}}
A.e.prototype={
gl(a){var t,s=this.gt(this)
for(t=0;s.k();)++t
return t},
gR(a){var t=this.gt(this)
if(!t.k())throw A.c(A.bj())
return t.gm()},
A(a,b){var t,s=this.gt(this)
for(t=b;s.k();){if(t===0)return s.gm();--t}throw A.c(A.di(b,b-t,this,"index"))},
i(a){return A.eD(this,"(",")")}}
A.a9.prototype={
i(a){return"MapEntry("+A.o(this.a)+": "+A.o(this.b)+")"}}
A.aP.prototype={
gu(a){return A.n.prototype.gu.call(this,0)},
i(a){return"null"}}
A.n.prototype={$in:1,
C(a,b){return this===b},
gu(a){return A.bB(this)},
i(a){return"Instance of '"+A.bC(this)+"'"},
gp(a){return A.fV(this)},
toString(){return this.i(this)}}
A.an.prototype={
gl(a){return this.a.length},
i(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$ieO:1}
A.bK.prototype={$ieK:1}
A.cL.prototype={
$1(a){var t,s,r,q,p,o,n,m,l,k,j,i,h="state",g="id"
A.M(a)
try{t=u.a.a(B.o.aC(a,null))
s=J.v(t,h)==null?new A.b9(A.M(J.v(t,"roomId")),A.f(J.v(t,"seed")),A.f(J.v(t,"now")),A.m([],u.O),A.m([],u.Y)):A.ek(A.cU(u.f.a(J.v(t,h)),u.N,u.z))
r=A.f(J.v(t,"now"))
q=null
switch(J.v(t,"action")){case"join":J.ej(s,A.f(J.v(t,g)),A.M(J.v(t,"name")),r)
break
case"connect":n=s
m=A.f(J.v(t,g))
l=A.f(r)
n.F(l)
k=n.K(m)
k.Q=!0
k.as=null;++n.f
n.a3(l)
break
case"disconnect":s.aE(A.f(J.v(t,g)),r)
break
case"ready":s.aR(A.f(J.v(t,g)),r)
break
case"advance":s.F(r)
break
case"resign":n=s
m=A.f(J.v(t,g))
l=A.f(r)
n.F(l)
n.K(m)
if(n.e!=="finished")n.N(m,"resigned",l)
break
case"place":q=s.aO(A.f(J.v(t,g)),A.f(J.v(t,"moveId")),A.f(J.v(t,"slot")),A.f(J.v(t,"row")),A.f(J.v(t,"col")),r)
break}p=A.cT(u.N,u.z)
J.b5(p,h,s.J())
J.b5(p,"events",s.z)
o=q
if(o!=null)J.ef(p,o)
j=B.o.aa(p,null)
return j}catch(i){p=u.N
j=B.o.aa(A.H(["error","Ge\xe7ersiz ma\xe7 iste\u011fi."],p,p),null)
return j}},
$S:10}
A.cE.prototype={
$1(a){var t,s=this.a,r=B.f.E(s.a*48271,2147483647)
s.a=r
t=B.f.E(r,33)
return new A.z(t,B.f.E(t,8))},
$S:11}
A.y.prototype={
ap(){return A.fL(this.b,this.e++)},
J(){var t=this,s=t.d
s===$&&A.e1()
return A.H(["id",t.a,"name",t.c,"game",s.J(),"nextSet",t.e,"lives",t.f,"boardOuts",t.r,"thresholds",t.w,"damage",t.x,"lastMove",t.y,"ready",t.z,"connected",t.Q,"disconnectAt",t.as],u.N,u.z)}}
A.b9.prototype={
K(a){return B.a.ab(this.d,new A.bY(a))},
aL(a,b,c,d){var t=this,s=t.d
if(B.a.O(s,new A.bV(b)))return
if(t.e!=="waiting"||s.length>=2)throw A.c(A.eN("Oda dolu veya ma\xe7 ba\u015flam\u0131\u015f."))
B.a.n(s,A.el(b,c,t.b,!0));++t.f},
aE(a,b){var t,s=this
s.F(b)
if(s.e==="finished")return
t=s.K(a)
if(!t.Q)return
t.Q=!1
t.as=b+15e3
if(s.e==="countdown"){s.e="waiting"
s.r=null}++s.f},
aR(a,b){var t,s=this
s.F(b)
if(s.e!=="waiting")return
t=s.K(a)
if(!t.Q)return
t.z=!0;++s.f
s.a3(b)},
a3(a){var t,s=this
if(s.e==="waiting"){t=s.d
t=t.length===2&&B.a.G(t,new A.bR())}else t=!1
if(t){s.e="countdown"
s.r=a+3000;++s.f}},
F(a){var t,s,r,q,p=this
if(p.e==="finished")return
t=p.d
s=A.B(t)
r=s.h("aa<1>")
q=A.bp(new A.aa(t,s.h("t(1)").a(new A.bT(a)),r),r.h("e.E"))
B.a.al(q,new A.bU())
if(q.length!==0){t=B.a.gR(q)
s=B.a.gR(q).as
s.toString
p.N(t.a,"disconnect",s)
return}if(a>=p.c+36e5){p.e="finished"
p.y="expired"
p.w=a;++p.f
return}if(p.e==="countdown"){t=p.r
t.toString
t=a>=t}else t=!1
if(t){p.e="playing";++p.f}},
N(a,b,c){var t,s,r,q=this
if(q.e==="finished")return
q.e="finished"
q.w=c
q.y=b
t=q.d
s=A.B(t)
r=new A.aa(t,s.h("t(1)").a(new A.bS(a)),s.h("aa<1>"))
q.x=!r.gt(0).k()?null:r.gR(0).a
B.a.n(q.z,A.H(["type","GAME_OVER","loser",a,"reason",b],u.N,u.z));++q.f},
aO(a,b,c,d,e,a0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f=this
f.z=A.m([],u.Y)
f.F(a0)
t=f.K(a)
if(b<=t.y&&b>0)return A.H(["duplicate",!0],u.N,u.z)
if(f.e!=="playing")return A.H(["error","Ma\xe7 \u015fu anda oynanabilir de\u011fil."],u.N,u.z)
if(!t.Q||B.a.O(f.d,new A.bW()))return A.H(["error","Ba\u011flant\u0131 bekleniyor."],u.N,u.z)
if(b!==t.y+1)return A.H(["error","Hamle s\u0131ras\u0131 g\xfcncel de\u011fil."],u.N,u.z)
s=t.d
s===$&&A.e1()
r=s.aN(c,d,e)
if(r==null)return A.H(["error","Ge\xe7ersiz yerle\u015ftirme."],u.N,u.z)
t.y=b
q=B.a.ab(f.d,new A.bX(a))
s=B.f.a8(t.d.e,1000)
p=s-t.w
t.w=s
if(p>0){o=B.f.az(p,0,q.f)
t.x+=o
q.f-=o
s=q.a
B.a.n(f.z,A.H(["type","DAMAGE","player",s,"amount",o],u.N,u.z))
if(q.f===0)f.N(s,"score",a0)}if(f.e!=="finished"&&!t.d.gaH()){--t.f;++t.r
B.a.n(f.z,A.H(["type","BOARD_RESET","player",a,"amount",1],u.N,u.z))
if(t.f===0)f.N(a,"board_out",a0)
else{s=t.d
n=J.cf(8,u.R)
for(m=u.I,l=0;l<8;++l)n[l]=A.bq(8,null,!1,m)
s.sa0(n)
s=t.d
s.r=s.f=0
s.a_()}}++f.f
s=r.b
m=r.c
k=r.d
j=u.N
i=A.cT(j,u.p)
for(h=r.a,h=new A.aJ(h,A.C(h).h("aJ<1,2>")).gt(0);h.k();){g=h.d
i.q(0,""+g.a,g.b)}return A.H(["ok",!0,"move",A.H(["player",a,"slot",c,"row",d,"col",e,"lines",s,"points",m,"allClear",k,"clearedCells",i],j,u.K)],j,u.z)},
J(){var t=this,s=t.e,r=t.f,q=t.r,p=t.w,o=t.x,n=t.y,m=t.d,l=A.B(m),k=l.h("I<1,P<l,@>>")
m=A.bp(new A.I(m,l.h("P<l,@>(1)").a(new A.bZ()),k),k.h("x.E"))
return A.H(["version",1,"roomId",t.a,"seed",t.b,"createdAt",t.c,"status",s,"revision",r,"startAt",q,"endedAt",p,"winner",o,"reason",n,"players",m],u.N,u.z)}}
A.bY.prototype={
$1(a){return u.h.a(a).a===this.a},
$S:0}
A.bV.prototype={
$1(a){return u.h.a(a).a===this.a},
$S:0}
A.bR.prototype={
$1(a){u.h.a(a)
return a.z&&a.Q},
$S:0}
A.bT.prototype={
$1(a){var t=u.h.a(a).as
return t!=null&&this.a>=t},
$S:0}
A.bU.prototype={
$2(a,b){var t,s=u.h
s.a(a)
s.a(b)
s=a.as
s.toString
t=b.as
t.toString
return B.f.P(s,t)},
$S:13}
A.bS.prototype={
$1(a){return u.h.a(a).a!==this.a},
$S:0}
A.bW.prototype={
$1(a){return!u.h.a(a).Q},
$S:0}
A.bX.prototype={
$1(a){return u.h.a(a).a!==this.a},
$S:0}
A.bZ.prototype={
$1(a){return u.h.a(a).J()},
$S:14}
A.z.prototype={
gaS(){var t,s=this.a
if(!(s>=0&&s<33))return A.d(B.j,s)
s=B.j[s]
t=A.B(s)
return new A.I(s,t.h("a(1)").a(new A.cd()),t.h("I<1,a>")).ah(0,B.q)+1},
gaA(){var t,s=this.a
if(!(s>=0&&s<33))return A.d(B.j,s)
s=B.j[s]
t=A.B(s)
return new A.I(s,t.h("a(1)").a(new A.cc()),t.h("I<1,a>")).ah(0,B.q)+1}}
A.cd.prototype={
$1(a){u.L.a(a)
if(0>=a.length)return A.d(a,0)
return a[0]},
$S:5}
A.cc.prototype={
$1(a){u.L.a(a)
if(1>=a.length)return A.d(a,1)
return a[1]},
$S:5}
A.cb.prototype={}
A.ba.prototype={
ac(a,b,c,d){var t,s
u.D.a(d)
t=d==null?this.c:d
s=a.a
if(!(s>=0&&s<33))return A.d(B.j,s)
return B.a.G(B.j[s],new A.c1(b,c,t))},
aG(a,b,c){return this.ac(a,b,c,null)},
aQ(a,b){var t,s,r
u.D.a(b)
t=A.m([],u.n)
for(s=0;s<=8-a.gaS();++s)for(r=0;r<=8-a.gaA();++r)if(this.ac(a,s,r,b))t.push(new A.aq(s,r))
return t},
aP(a){return this.aQ(a,null)},
gaH(){return J.db(this.d,new A.c2(this))},
aN(a,b,c){var t,s,r,q,p,o,n,m,l,k=this
if(a<0||a>=k.d.length)return null
t=k.d
if(!(a>=0&&a<t.length))return A.d(t,a)
s=t[a]
if(s==null||!k.aG(s,b,c))return null
A.ep(k.c,s,b,c)
J.b5(k.d,a,null)
r=A.cQ(k.c)
q=r.a.length+r.b.length
p=A.eo(k.c)
t=q>0
if(t){++k.f
k.r=0}else if(k.f>0)if(++k.r>=3)k.r=k.f=0
o=t&&B.a.G(k.c,new A.c4())
t=s.a
if(!(t>=0&&t<33))return A.d(B.j,t)
t=B.j[t]
n=k.f
m=o?300:0
l=t.length+10*q*q*n+m
k.e+=l
if(J.bQ(k.d,new A.c5()))k.a_()
return new A.cb(p,q,l,o)},
a_(){this.d=this.b.$0()
return},
J(){var t,s,r,q,p,o=this,n=o.c,m=A.m([],u.r)
for(t=o.d,s=t.length,r=u.t,q=0;q<t.length;t.length===s||(0,A.bO)(t),++q){p=t[q]
m.push(p==null?null:A.m([p.a,p.b],r))}return A.H(["version",1,"grid",n,"tray",m,"score",o.e,"combo",o.f,"misses",o.r,"reviveUsed",o.w],u.N,u.z)},
sa0(a){this.c=u.A.a(a)},
saT(a){this.d=u.V.a(a)},
sak(a){this.e=A.f(a)},
saB(a){this.f=A.f(a)},
saM(a){this.r=A.f(a)}}
A.c1.prototype={
$1(a){var t,s,r
u.L.a(a)
t=a.length
if(0>=t)return A.d(a,0)
s=this.a+a[0]
if(1>=t)return A.d(a,1)
r=this.b+a[1]
t=!1
if(s>=0)if(s<8)if(r>=0)if(r<8){t=this.c
if(!(s<t.length))return A.d(t,s)
t=t[s]
if(!(r<t.length))return A.d(t,r)
t=t[r]==null}return t},
$S:15}
A.c2.prototype={
$1(a){u.k.a(a)
return a!=null&&this.a.aP(a).length!==0},
$S:1}
A.c_.prototype={
$1(a){return A.a2(a)!=null},
$S:2}
A.c0.prototype={
$1(a){return A.a2(a)!=null},
$S:2}
A.c4.prototype={
$1(a){return J.bQ(u.R.a(a),new A.c3())},
$S:6}
A.c3.prototype={
$1(a){return A.a2(a)==null},
$S:2}
A.c5.prototype={
$1(a){return u.k.a(a)==null},
$S:1}
A.c7.prototype={
$1(a){var t=J.cO(u.j.a(a),new A.c6(),u.I)
t=A.bp(t,t.$ti.h("x.E"))
return t},
$S:16}
A.c6.prototype={
$1(a){var t
if(a!=null)t=!A.bN(a)||a<0||a>=8
else t=!1
if(t)throw A.c(B.v)
return A.a2(a)},
$S:17}
A.c8.prototype={
$1(a){return u.R.a(a).length!==8},
$S:6}
A.c9.prototype={
$1(a){var t,s,r
if(a==null)return null
t=!0
if(u.j.b(a)){s=a.length
if(s===2){if(0>=s)return A.d(a,0)
r=a[0]
if(A.bN(r)){if(1>=s)return A.d(a,1)
t=a[1]
t=!A.bN(t)||r<0||r>=33||t<0||t>=8}}}if(t)throw A.c(B.v)
t=a.length
if(0>=t)return A.d(a,0)
s=A.f(a[0])
if(1>=t)return A.d(a,1)
return new A.z(s,A.f(a[1]))},
$S:18}
A.ca.prototype={
$1(a){return u.k.a(a)==null},
$S:1};(function aliases(){var t=J.a_.prototype
t.am=t.i})();(function installTearOffs(){var t=hunkHelpers._static_1,s=hunkHelpers.installStaticTearOff,r=hunkHelpers._instance_0u
t(A,"fP","fh",3)
s(A,"h5",2,null,["$1$2","$2"],["dY",function(a,b){return A.dY(a,b,u.H)}],19,0)
r(A.y.prototype,"ga5","ap",12)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.n,null)
r(A.n,[A.cR,J.bi,A.aS,J.a5,A.p,A.cq,A.e,A.a8,A.aX,A.az,A.ay,A.A,A.ac,A.E,A.cr,A.co,A.F,A.cl,A.a6,A.aK,A.Q,A.bJ,A.cz,A.j,A.bc,A.be,A.cw,A.aT,A.ct,A.aA,A.a9,A.aP,A.an,A.bK,A.y,A.b9,A.z,A.cb,A.ba])
r(J.bi,[J.bl,J.aC,J.aF,J.aE,J.aG,J.aD,J.ak])
r(J.aF,[J.a_,J.i,A.al,A.aN])
r(J.a_,[J.bA,J.ao,J.Z])
s(J.bk,A.aS)
s(J.cg,J.i)
r(J.aD,[J.aB,J.bm])
r(A.p,[A.aI,A.aV,A.bn,A.bH,A.bD,A.bI,A.aH,A.b7,A.X,A.aW,A.bG,A.aU,A.bd])
r(A.e,[A.ax,A.aa,A.ce])
r(A.ax,[A.x,A.a7,A.aJ])
r(A.x,[A.I,A.bM])
s(A.ap,A.ac)
s(A.aq,A.ap)
r(A.E,[A.bh,A.bb,A.bF,A.cH,A.cJ,A.cL,A.cE,A.bY,A.bV,A.bR,A.bT,A.bS,A.bW,A.bX,A.bZ,A.cd,A.cc,A.c1,A.c2,A.c_,A.c0,A.c4,A.c3,A.c5,A.c7,A.c6,A.c8,A.c9,A.ca])
s(A.aj,A.bh)
s(A.aQ,A.aV)
r(A.bF,[A.bE,A.ai])
r(A.F,[A.S,A.bL])
r(A.bb,[A.ch,A.cI,A.cm,A.cn,A.cx,A.bU])
r(A.aN,[A.br,A.am])
r(A.am,[A.aY,A.b_])
s(A.aZ,A.aY)
s(A.aL,A.aZ)
s(A.b0,A.b_)
s(A.aM,A.b0)
r(A.aL,[A.bs,A.bt])
r(A.aM,[A.bu,A.bv,A.bw,A.bx,A.by,A.aO,A.bz])
s(A.ar,A.bI)
s(A.bo,A.aH)
s(A.ci,A.bc)
r(A.be,[A.ck,A.cj])
s(A.cv,A.cw)
r(A.X,[A.aR,A.bg])
t(A.aY,A.j)
t(A.aZ,A.A)
t(A.b_,A.j)
t(A.b0,A.A)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{a:"int",k:"double",W:"num",l:"String",t:"bool",aP:"Null",b:"List",n:"Object",P:"Map",q:"JSObject"},mangledNames:{},types:["t(y)","t(z?)","t(a?)","@(@)","~(n?,n?)","a(b<a>)","t(b<a?>)","@(@,l)","@(l)","~(@,@)","l(l)","z(a)","b<z?>()","a(y,y)","P<l,@>(y)","t(b<a>)","b<a?>(@)","a?(@)","z?(@)","0^(0^,0^)<W>"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof A.aq&&a.b(c.a)&&b.b(c.b)}}
A.f8(v.typeUniverse,JSON.parse('{"Z":"a_","bA":"a_","ao":"a_","hc":"al","bl":{"t":[],"h":[]},"aC":{"h":[]},"aF":{"q":[]},"a_":{"q":[]},"i":{"b":["1"],"q":[],"e":["1"]},"bk":{"aS":[]},"cg":{"i":["1"],"b":["1"],"q":[],"e":["1"]},"a5":{"K":["1"]},"aD":{"k":[],"W":[]},"aB":{"k":[],"a":[],"W":[],"h":[]},"bm":{"k":[],"W":[],"h":[]},"ak":{"l":[],"h":[]},"aI":{"p":[]},"ax":{"e":["1"]},"x":{"e":["1"]},"a8":{"K":["1"]},"I":{"x":["2"],"e":["2"],"x.E":"2","e.E":"2"},"aa":{"e":["1"],"e.E":"1"},"aX":{"K":["1"]},"ce":{"e":["2"],"e.E":"2"},"az":{"K":["2"]},"ay":{"K":["1"]},"aq":{"ap":[],"ac":[]},"bh":{"E":[],"Y":[]},"aj":{"E":[],"Y":[]},"aQ":{"p":[]},"bn":{"p":[]},"bH":{"p":[]},"E":{"Y":[]},"bb":{"E":[],"Y":[]},"bF":{"E":[],"Y":[]},"bE":{"E":[],"Y":[]},"ai":{"E":[],"Y":[]},"bD":{"p":[]},"S":{"F":["1","2"],"dm":["1","2"],"P":["1","2"],"F.K":"1","F.V":"2"},"a7":{"e":["1"],"e.E":"1"},"a6":{"K":["1"]},"aJ":{"e":["a9<1,2>"],"e.E":"a9<1,2>"},"aK":{"K":["a9<1,2>"]},"ap":{"ac":[]},"al":{"q":[],"h":[]},"aN":{"q":[]},"br":{"q":[],"h":[]},"am":{"G":["1"],"q":[]},"aL":{"j":["k"],"b":["k"],"G":["k"],"q":[],"e":["k"],"A":["k"]},"aM":{"j":["a"],"b":["a"],"G":["a"],"q":[],"e":["a"],"A":["a"]},"bs":{"j":["k"],"b":["k"],"G":["k"],"q":[],"e":["k"],"A":["k"],"h":[],"j.E":"k"},"bt":{"j":["k"],"b":["k"],"G":["k"],"q":[],"e":["k"],"A":["k"],"h":[],"j.E":"k"},"bu":{"j":["a"],"b":["a"],"G":["a"],"q":[],"e":["a"],"A":["a"],"h":[],"j.E":"a"},"bv":{"j":["a"],"b":["a"],"G":["a"],"q":[],"e":["a"],"A":["a"],"h":[],"j.E":"a"},"bw":{"j":["a"],"b":["a"],"G":["a"],"q":[],"e":["a"],"A":["a"],"h":[],"j.E":"a"},"bx":{"j":["a"],"b":["a"],"G":["a"],"q":[],"e":["a"],"A":["a"],"h":[],"j.E":"a"},"by":{"j":["a"],"b":["a"],"G":["a"],"q":[],"e":["a"],"A":["a"],"h":[],"j.E":"a"},"aO":{"j":["a"],"b":["a"],"G":["a"],"q":[],"e":["a"],"A":["a"],"h":[],"j.E":"a"},"bz":{"j":["a"],"b":["a"],"G":["a"],"q":[],"e":["a"],"A":["a"],"h":[],"j.E":"a"},"bI":{"p":[]},"ar":{"p":[]},"F":{"P":["1","2"]},"bL":{"F":["l","@"],"P":["l","@"],"F.K":"l","F.V":"@"},"bM":{"x":["l"],"e":["l"],"x.E":"l","e.E":"l"},"aH":{"p":[]},"bo":{"p":[]},"k":{"W":[]},"a":{"W":[]},"b":{"e":["1"]},"b7":{"p":[]},"aV":{"p":[]},"X":{"p":[]},"aR":{"p":[]},"bg":{"p":[]},"aW":{"p":[]},"bG":{"p":[]},"aU":{"p":[]},"bd":{"p":[]},"aT":{"p":[]},"an":{"eO":[]},"bK":{"eK":[]},"eC":{"b":["a"],"e":["a"]},"eS":{"b":["a"],"e":["a"]},"eR":{"b":["a"],"e":["a"]},"eA":{"b":["a"],"e":["a"]},"eP":{"b":["a"],"e":["a"]},"eB":{"b":["a"],"e":["a"]},"eQ":{"b":["a"],"e":["a"]},"ey":{"b":["k"],"e":["k"]},"ez":{"b":["k"],"e":["k"]}}'))
A.f7(v.typeUniverse,JSON.parse('{"ax":1,"am":1,"bc":2,"be":2}'))
var u=(function rtii(){var t=A.au
return{h:t("y"),C:t("p"),Z:t("Y"),U:t("e<@>"),O:t("i<y>"),S:t("i<b<a>>"),Y:t("i<P<l,@>>"),n:t("i<+(a,a)>"),s:t("i<l>"),q:t("i<@>"),t:t("i<a>"),b:t("i<z?>"),r:t("i<b<a>?>"),_:t("i<a?>"),T:t("aC"),m:t("q"),g:t("Z"),E:t("G<@>"),A:t("b<b<a?>>"),j:t("b<@>"),L:t("b<a>"),V:t("b<z?>"),R:t("b<a?>"),a:t("P<l,@>"),f:t("P<@,@>"),P:t("aP"),K:t("n"),J:t("hd"),F:t("+()"),N:t("l"),l:t("h"),o:t("ao"),y:t("t"),i:t("k"),z:t("@"),p:t("a"),k:t("z?"),Q:t("dh<aP>?"),B:t("q?"),D:t("b<b<a?>>?"),M:t("b<@>?"),X:t("n?"),v:t("l?"),u:t("t?"),w:t("k?"),I:t("a?"),x:t("W?"),H:t("W"),G:t("~(l,@)")}})();(function constants(){var t=hunkHelpers.makeConstList
B.H=J.bi.prototype
B.a=J.i.prototype
B.f=J.aB.prototype
B.I=J.aD.prototype
B.n=J.ak.prototype
B.J=J.Z.prototype
B.K=J.aF.prototype
B.y=J.bA.prototype
B.p=J.ao.prototype
B.q=new A.aj(A.h5(),A.au("aj<a>"))
B.z=new A.ay(A.au("ay<0&>"))
B.r=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.A=function() {
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
B.F=function(getTagFallback) {
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
B.B=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.E=function(hooks) {
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
B.D=function(hooks) {
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
B.C=function(hooks) {
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
B.t=function(hooks) { return hooks; }

B.o=new A.ci()
B.m=new A.cq()
B.u=new A.bK()
B.G=new A.aA("Battle version")
B.v=new A.aA("")
B.L=new A.cj(null)
B.M=new A.ck(null)
B.b=t([0,0],u.t)
B.Y=t([B.b],u.S)
B.c=t([0,1],u.t)
B.X=t([B.b,B.c],u.S)
B.d=t([1,0],u.t)
B.ah=t([B.b,B.d],u.S)
B.h=t([0,2],u.t)
B.a0=t([B.b,B.c,B.h],u.S)
B.i=t([2,0],u.t)
B.S=t([B.b,B.d,B.i],u.S)
B.w=t([0,3],u.t)
B.Q=t([B.b,B.c,B.h,B.w],u.S)
B.x=t([3,0],u.t)
B.a9=t([B.b,B.d,B.i,B.x],u.S)
B.N=t([0,4],u.t)
B.ad=t([B.b,B.c,B.h,B.w,B.N],u.S)
B.R=t([4,0],u.t)
B.Z=t([B.b,B.d,B.i,B.x,B.R],u.S)
B.e=t([1,1],u.t)
B.ai=t([B.b,B.c,B.d,B.e],u.S)
B.k=t([1,2],u.t)
B.l=t([2,1],u.t)
B.P=t([2,2],u.t)
B.a4=t([B.b,B.c,B.h,B.d,B.e,B.k,B.i,B.l,B.P],u.S)
B.a2=t([B.b,B.c,B.d],u.S)
B.a1=t([B.b,B.c,B.e],u.S)
B.U=t([B.b,B.d,B.e],u.S)
B.ak=t([B.c,B.d,B.e],u.S)
B.a6=t([B.b,B.d,B.i,B.l],u.S)
B.O=t([B.b,B.c,B.h,B.d],u.S)
B.ag=t([B.b,B.c,B.e,B.l],u.S)
B.W=t([B.h,B.d,B.e,B.k],u.S)
B.a_=t([B.c,B.e,B.i,B.l],u.S)
B.V=t([B.b,B.d,B.e,B.k],u.S)
B.a5=t([B.b,B.c,B.d,B.i],u.S)
B.ae=t([B.b,B.c,B.h,B.k],u.S)
B.ac=t([B.b,B.c,B.h,B.e],u.S)
B.aj=t([B.c,B.d,B.e,B.k],u.S)
B.ab=t([B.b,B.d,B.e,B.i],u.S)
B.af=t([B.c,B.d,B.e,B.l],u.S)
B.a7=t([B.c,B.h,B.d,B.e],u.S)
B.aa=t([B.b,B.d,B.e,B.l],u.S)
B.al=t([B.b,B.c,B.e,B.k],u.S)
B.a8=t([B.c,B.d,B.e,B.i],u.S)
B.T=t([B.b,B.c,B.h,B.d,B.e,B.k],u.S)
B.a3=t([B.b,B.c,B.d,B.e,B.i,B.l],u.S)
B.j=t([B.Y,B.X,B.ah,B.a0,B.S,B.Q,B.a9,B.ad,B.Z,B.ai,B.a4,B.a2,B.a1,B.U,B.ak,B.a6,B.O,B.ag,B.W,B.a_,B.V,B.a5,B.ae,B.ac,B.aj,B.ab,B.af,B.a7,B.aa,B.al,B.a8,B.T,B.a3],A.au("i<b<b<a>>>"))
B.am=A.R("h9")
B.an=A.R("ha")
B.ao=A.R("ey")
B.ap=A.R("ez")
B.aq=A.R("eA")
B.ar=A.R("eB")
B.as=A.R("eC")
B.at=A.R("n")
B.au=A.R("eP")
B.av=A.R("eQ")
B.aw=A.R("eR")
B.ax=A.R("eS")})();(function staticFields(){$.cu=null
$.J=A.m([],A.au("i<n>"))
$.dq=null
$.de=null
$.dd=null
$.dW=null
$.dU=null
$.e0=null
$.cG=null
$.cK=null
$.d6=null
$.cy=A.m([],A.au("i<b<n>?>"))})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"hb","da",()=>A.fU("_$dart_dartClosure"))
t($,"hp","ee",()=>A.m([new J.bk()],A.au("i<aS>")))
t($,"he","e4",()=>A.T(A.cs({
toString:function(){return"$receiver$"}})))
t($,"hf","e5",()=>A.T(A.cs({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"hg","e6",()=>A.T(A.cs(null)))
t($,"hh","e7",()=>A.T(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"hk","ea",()=>A.T(A.cs(void 0)))
t($,"hl","eb",()=>A.T(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"hj","e9",()=>A.T(A.du(null)))
t($,"hi","e8",()=>A.T(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"hn","ed",()=>A.T(A.du(void 0)))
t($,"hm","ec",()=>A.T(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"ho","cN",()=>A.dZ(B.at))})();(function nativeSupport(){!function(){var t=function(a){var n={}
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
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.al,SharedArrayBuffer:A.al,ArrayBufferView:A.aN,DataView:A.br,Float32Array:A.bs,Float64Array:A.bt,Int16Array:A.bu,Int32Array:A.bv,Int8Array:A.bw,Uint16Array:A.bx,Uint32Array:A.by,Uint8ClampedArray:A.aO,CanvasPixelArray:A.aO,Uint8Array:A.bz})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.am.$nativeSuperclassTag="ArrayBufferView"
A.aY.$nativeSuperclassTag="ArrayBufferView"
A.aZ.$nativeSuperclassTag="ArrayBufferView"
A.aL.$nativeSuperclassTag="ArrayBufferView"
A.b_.$nativeSuperclassTag="ArrayBufferView"
A.b0.$nativeSuperclassTag="ArrayBufferView"
A.aM.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$0=function(){return this()}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$6=function(a,b,c,d,e,f){return this(a,b,c,d,e,f)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$1$1=function(a){return this(a)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.h3
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()