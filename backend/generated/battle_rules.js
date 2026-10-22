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
if(a[b]!==t){A.j6(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.e(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.eH(b)
return new t(c,this)}:function(){if(t===null)t=A.eH(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.eH(a).prototype
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
eM(a,b,c,d){return{i:a,p:b,e:c,x:d}},
eI(a){var t,s,r,q,p,o=a[v.dispatchPropertyName]
if(o==null)if($.eK==null){A.iW()
o=a[v.dispatchPropertyName]}if(o!=null){t=o.p
if(!1===t)return o.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return o.i
if(o.e===s)throw A.d(A.fc("Return interceptor for "+A.z(t(a,o))))}r=a.constructor
if(r==null)q=null
else{p=$.dA
if(p==null)p=$.dA=v.getIsolateTag("_$dart_js")
q=r[p]}if(q!=null)return q
q=A.j1(a)
if(q!=null)return q
if(typeof a=="function")return B.P
t=Object.getPrototypeOf(a)
if(t==null)return B.B
if(t===Object.prototype)return B.B
if(typeof r=="function"){p=$.dA
if(p==null)p=$.dA=v.getIsolateTag("_$dart_js")
Object.defineProperty(r,p,{value:B.t,enumerable:false,writable:true,configurable:true})
return B.t}return B.t},
hu(a,b){if(a<0||a>4294967295)throw A.d(A.aE(a,0,4294967295,"length",null))
return J.hv(new Array(a),b)},
f1(a,b){if(a<0)throw A.d(A.cx("Length must be a non-negative integer: "+a))
return A.e(new Array(a),b.h("p<0>"))},
aS(a,b){if(a<0)throw A.d(A.cx("Length must be a non-negative integer: "+a))
return A.e(new Array(a),b.h("p<0>"))},
hv(a,b){var t=A.e(a,b.h("p<0>"))
t.$flags=1
return t},
hw(a,b){var t=u.w
return J.h3(t.a(a),t.a(b))},
aL(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.be.prototype
return J.c2.prototype}if(typeof a=="string")return J.aA.prototype
if(a==null)return J.bf.prototype
if(typeof a=="boolean")return J.c1.prototype
if(Array.isArray(a))return J.p.prototype
if(typeof a!="object"){if(typeof a=="function")return J.aq.prototype
if(typeof a=="symbol")return J.bi.prototype
if(typeof a=="bigint")return J.bg.prototype
return a}if(a instanceof A.y)return a
return J.eI(a)},
a8(a){if(typeof a=="string")return J.aA.prototype
if(a==null)return a
if(Array.isArray(a))return J.p.prototype
if(typeof a!="object"){if(typeof a=="function")return J.aq.prototype
if(typeof a=="symbol")return J.bi.prototype
if(typeof a=="bigint")return J.bg.prototype
return a}if(a instanceof A.y)return a
return J.eI(a)},
a4(a){if(a==null)return a
if(Array.isArray(a))return J.p.prototype
if(typeof a!="object"){if(typeof a=="function")return J.aq.prototype
if(typeof a=="symbol")return J.bi.prototype
if(typeof a=="bigint")return J.bg.prototype
return a}if(a instanceof A.y)return a
return J.eI(a)},
iR(a){if(typeof a=="number")return J.aT.prototype
if(typeof a=="string")return J.aA.prototype
if(a==null)return a
if(!(a instanceof A.y))return J.aY.prototype
return a},
E(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.aL(a).O(a,b)},
l(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.j0(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.a8(a).i(a,b)},
aO(a,b,c){return J.a4(a).l(a,b,c)},
h1(a,b){return J.a4(a).p(a,b)},
h2(a,b){return J.a4(a).Y(a,b)},
eQ(a,b){return J.a4(a).G(a,b)},
eR(a,b){return J.a4(a).a7(a,b)},
h3(a,b){return J.iR(a).H(a,b)},
ek(a,b){return J.a4(a).C(a,b)},
cw(a,b){return J.a4(a).E(a,b)},
X(a){return J.aL(a).gB(a)},
h4(a){return J.a8(a).gu(a)},
h5(a){return J.a4(a).gN(a)},
M(a){return J.a4(a).gq(a)},
Y(a){return J.a8(a).gj(a)},
h6(a){return J.aL(a).gA(a)},
h7(a,b,c,d){return J.a4(a).bQ(a,b,c,d)},
el(a,b,c){return J.a4(a).a_(a,b,c)},
ao(a){return J.aL(a).n(a)},
eS(a,b){return J.a4(a).aH(a,b)},
c_:function c_(){},
c1:function c1(){},
bf:function bf(){},
bh:function bh(){},
ar:function ar(){},
cf:function cf(){},
aY:function aY(){},
aq:function aq(){},
bg:function bg(){},
bi:function bi(){},
p:function p(a){this.$ti=a},
c0:function c0(){},
dk:function dk(a){this.$ti=a},
ay:function ay(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
aT:function aT(){},
be:function be(){},
c2:function c2(){},
aA:function aA(){}},A={eq:function eq(){},
hh(a,b,c){if(u._.b(a))return new A.bA(a,b.h("@<0>").v(c).h("bA<1,2>"))
return new A.az(a,b.h("@<0>").v(c).h("az<1,2>"))},
hx(a){return new A.bk("Field '"+a+"' has not been initialized.")},
at(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
ez(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
eL(a){var t,s
for(t=$.a0.length,s=0;s<t;++s)if(a===$.a0[s])return!0
return!1},
eu(a,b,c,d){if(u._.b(a))return new A.ba(a,b,c.h("@<0>").v(d).h("ba<1,2>"))
return new A.a6(a,b,c.h("@<0>").v(d).h("a6<1,2>"))},
aR(){return new A.aF("No element")},
hs(){return new A.aF("Too many elements")},
au:function au(){},
b6:function b6(a,b){this.a=a
this.$ti=b},
az:function az(a,b){this.a=a
this.$ti=b},
bA:function bA(a,b){this.a=a
this.$ti=b},
bz:function bz(){},
ac:function ac(a,b){this.a=a
this.$ti=b},
bk:function bk(a){this.a=a},
dw:function dw(){},
k:function k(){},
C:function C(){},
bv:function bv(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
aD:function aD(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
a6:function a6(a,b,c){this.a=a
this.b=b
this.$ti=c},
ba:function ba(a,b,c){this.a=a
this.b=b
this.$ti=c},
bm:function bm(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
H:function H(a,b,c){this.a=a
this.b=b
this.$ti=c},
t:function t(a,b,c){this.a=a
this.b=b
this.$ti=c},
aj:function aj(a,b,c){this.a=a
this.b=b
this.$ti=c},
Q:function Q(a,b,c){this.a=a
this.b=b
this.$ti=c},
bc:function bc(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
bb:function bb(a){this.$ti=a},
ak:function ak(a,b){this.a=a
this.$ti=b},
by:function by(a,b){this.a=a
this.$ti=b},
R:function R(){},
bM:function bM(){},
fQ(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
j0(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.da.b(a)},
z(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.ao(a)
return t},
cg(a){var t,s=$.f7
if(s==null)s=$.f7=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
hB(a,b){var t,s=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(s==null)return null
if(3>=s.length)return A.f(s,3)
t=s[3]
if(t!=null)return parseInt(a,10)
if(s[2]!=null)return parseInt(a,16)
return null},
ch(a){var t,s,r,q
if(a instanceof A.y)return A.V(A.a9(a),null)
t=J.aL(a)
if(t===B.O||t===B.Q||u.cr.b(a)){s=B.v(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.V(A.a9(a),null)},
f8(a){var t,s,r
if(a==null||typeof a=="number"||A.eF(a))return J.ao(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.O)return a.n(0)
if(a instanceof A.al)return a.aZ(!0)
t=$.h0()
for(s=0;s<1;++s){r=t[s].c6(a)
if(r!=null)return r}return"Instance of '"+A.ch(a)+"'"},
N(a){var t
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.b.aW(t,10)|55296)>>>0,t&1023|56320)}throw A.d(A.aE(a,0,1114111,null,null))},
f(a,b){if(a==null)J.Y(a)
throw A.d(A.cv(a,b))},
cv(a,b){var t,s="index"
if(!A.cu(b))return new A.ap(!0,b,s,null)
t=J.Y(a)
if(b<0||b>=t)return A.dj(b,t,a,s)
return A.hD(b,s)},
iH(a){return new A.ap(!0,a,null,null)},
d(a){return A.L(a,new Error())},
L(a,b){var t
if(a==null)a=new A.bw()
b.dartException=a
t=A.j7
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
j7(){return J.ao(this.dartException)},
eN(a,b){throw A.L(a,b==null?new Error():b)},
a5(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.eN(A.ia(a,b,c),t)},
ia(a,b,c){var t,s,r,q,p,o,n,m,l
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
return new A.bx("'"+t+"': Cannot "+p+" "+m+l+o)},
D(a){throw A.d(A.P(a))},
ai(a){var t,s,r,q,p,o
a=A.j4(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.e([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.dx(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
dy(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
fb(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
er(a,b){var t=b==null,s=t?null:b.method
return new A.c3(a,s,t?null:b.receiver)},
eO(a){if(a==null)return new A.du(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.aN(a,a.dartException)
return A.iG(a)},
aN(a,b){if(u.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
iG(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.b.aW(s,16)&8191)===10)switch(r){case 438:return A.aN(a,A.er(A.z(t)+" (Error "+r+")",null))
case 445:case 5007:A.z(t)
return A.aN(a,new A.bs())}}if(a instanceof TypeError){q=$.fR()
p=$.fS()
o=$.fT()
n=$.fU()
m=$.fX()
l=$.fY()
k=$.fW()
$.fV()
j=$.h_()
i=$.fZ()
h=q.L(t)
if(h!=null)return A.aN(a,A.er(A.I(t),h))
else{h=p.L(t)
if(h!=null){h.method="call"
return A.aN(a,A.er(A.I(t),h))}else if(o.L(t)!=null||n.L(t)!=null||m.L(t)!=null||l.L(t)!=null||k.L(t)!=null||n.L(t)!=null||j.L(t)!=null||i.L(t)!=null){A.I(t)
return A.aN(a,new A.bs())}}return A.aN(a,new A.cm(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.bu()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.aN(a,new A.ap(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.bu()
return a},
fN(a){if(a==null)return J.X(a)
if(typeof a=="object")return A.cg(a)
return J.X(a)},
iP(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.l(0,a[t],a[s])}return b},
iQ(a,b){var t,s=a.length
for(t=0;t<s;++t)b.p(0,a[t])
return b},
ik(a,b,c,d,e,f){u.Z.a(a)
switch(A.h(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.d(new A.dz("Unsupported number of arguments for wrapped closure"))},
iI(a,b){var t=a.$identity
if(!!t)return t
t=A.iJ(a,b)
a.$identity=t
return t},
iJ(a,b){var t
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
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.ik)},
hm(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.cj().constructor.prototype):Object.create(new A.aP(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.eY(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.hi(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.eY(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
hi(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.d("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.hf)}throw A.d("Error in functionType of tearoff")},
hj(a,b,c,d){var t=A.eX
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
eY(a,b,c,d){if(c)return A.hl(a,b,d)
return A.hj(b.length,d,a,b)},
hk(a,b,c,d){var t=A.eX,s=A.hg
switch(b?-1:a){case 0:throw A.d(new A.ci("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
hl(a,b,c){var t,s
if($.eV==null)$.eV=A.eU("interceptor")
if($.eW==null)$.eW=A.eU("receiver")
t=b.length
s=A.hk(t,c,a,b)
return s},
eH(a){return A.hm(a)},
hf(a,b){return A.bL(v.typeUniverse,A.a9(a.a),b)},
eX(a){return a.a},
hg(a){return a.b},
eU(a){var t,s,r,q=new A.aP("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.d(A.cx("Field name "+a+" not found."))},
iS(a){return v.getIsolateTag(a)},
j1(a){var t,s,r,q,p,o=A.I($.fH.$1(a)),n=$.dV[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.eb[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.ct($.fD.$2(a,o))
if(r!=null){n=$.dV[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.eb[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.ed(t)
$.dV[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.eb[o]=t
return t}if(q==="-"){p=A.ed(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.fO(a,t)
if(q==="*")throw A.d(A.fc(o))
if(v.leafTags[o]===true){p=A.ed(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.fO(a,t)},
fO(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.eM(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
ed(a){return J.eM(a,!1,null,!!a.$ia_)},
j3(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.ed(t)
else return J.eM(t,c,null,null)},
iW(){if(!0===$.eK)return
$.eK=!0
A.iX()},
iX(){var t,s,r,q,p,o,n,m
$.dV=Object.create(null)
$.eb=Object.create(null)
A.iV()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.fP.$1(p)
if(o!=null){n=A.j3(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
iV(){var t,s,r,q,p,o,n=B.H()
n=A.b3(B.I,A.b3(B.J,A.b3(B.w,A.b3(B.w,A.b3(B.K,A.b3(B.L,A.b3(B.M(B.v),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.fH=new A.e8(q)
$.fD=new A.e9(p)
$.fP=new A.ea(o)},
b3(a,b){return a(b)||b},
iL(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
j4(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
a1:function a1(a,b){this.a=a
this.b=b},
av:function av(a,b,c){this.a=a
this.b=b
this.c=c},
b7:function b7(){},
b9:function b9(a,b,c){this.a=a
this.b=b
this.$ti=c},
bB:function bB(a,b){this.a=a
this.$ti=b},
aG:function aG(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
b8:function b8(){},
aQ:function aQ(a,b,c){this.a=a
this.b=b
this.$ti=c},
bZ:function bZ(){},
ab:function ab(a,b){this.a=a
this.$ti=b},
bt:function bt(){},
dx:function dx(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
bs:function bs(){},
c3:function c3(a,b,c){this.a=a
this.b=b
this.c=c},
cm:function cm(a){this.a=a},
du:function du(a){this.a=a},
O:function O(){},
bS:function bS(){},
bT:function bT(){},
ck:function ck(){},
cj:function cj(){},
aP:function aP(a,b){this.a=a
this.b=b},
ci:function ci(a){this.a=a},
af:function af(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
dl:function dl(a){this.a=a},
dq:function dq(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
aC:function aC(a,b){this.a=a
this.$ti=b},
aB:function aB(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
ag:function ag(a,b){this.a=a
this.$ti=b},
bl:function bl(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
e8:function e8(a){this.a=a},
e9:function e9(a){this.a=a},
ea:function ea(a){this.a=a},
al:function al(){},
aZ:function aZ(){},
b_:function b_(){},
fw(a){return a},
am(a,b,c){if(a>>>0!==a||a>=c)throw A.d(A.cv(b,a))},
aU:function aU(){},
bp:function bp(){},
c6:function c6(){},
aV:function aV(){},
bn:function bn(){},
bo:function bo(){},
c7:function c7(){},
c8:function c8(){},
c9:function c9(){},
ca:function ca(){},
cb:function cb(){},
cc:function cc(){},
cd:function cd(){},
bq:function bq(){},
ce:function ce(){},
bC:function bC(){},
bD:function bD(){},
bE:function bE(){},
bF:function bF(){},
ex(a,b){var t=b.c
return t==null?b.c=A.bJ(a,"f_",[b.x]):t},
f9(a){var t=a.w
if(t===6||t===7)return A.f9(a.x)
return t===11||t===12},
hF(a){return a.as},
b4(a){return A.dJ(v.typeUniverse,a,!1)},
iZ(a,b){var t,s,r,q,p
if(a==null)return null
t=b.y
s=a.Q
if(s==null)s=a.Q=new Map()
r=b.as
q=s.get(r)
if(q!=null)return q
p=A.ax(v.typeUniverse,a.x,t,0)
s.set(r,p)
return p},
ax(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.ax(a0,t,a2,a3)
if(s===t)return a1
return A.fn(a0,s,!0)
case 7:t=a1.x
s=A.ax(a0,t,a2,a3)
if(s===t)return a1
return A.fm(a0,s,!0)
case 8:r=a1.y
q=A.b2(a0,r,a2,a3)
if(q===r)return a1
return A.bJ(a0,a1.x,q)
case 9:p=a1.x
o=A.ax(a0,p,a2,a3)
n=a1.y
m=A.b2(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.eC(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.b2(a0,k,a2,a3)
if(j===k)return a1
return A.fo(a0,l,j)
case 11:i=a1.x
h=A.ax(a0,i,a2,a3)
g=a1.y
f=A.iD(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.fl(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.b2(a0,e,a2,a3)
p=a1.x
o=A.ax(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.eD(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.d(A.bP("Attempted to substitute unexpected RTI kind "+a))}},
b2(a,b,c,d){var t,s,r,q,p=b.length,o=A.dK(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.ax(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
iE(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.dK(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.ax(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
iD(a,b,c,d){var t,s=b.a,r=A.b2(a,s,c,d),q=b.b,p=A.b2(a,q,c,d),o=b.c,n=A.iE(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.co()
t.a=r
t.b=p
t.c=n
return t},
e(a,b){a[v.arrayRti]=b
return a},
dU(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.iU(t)
return a.$S()}return null},
iY(a,b){var t
if(A.f9(b))if(a instanceof A.O){t=A.dU(a)
if(t!=null)return t}return A.a9(a)},
a9(a){if(a instanceof A.y)return A.r(a)
if(Array.isArray(a))return A.w(a)
return A.eE(J.aL(a))},
w(a){var t=a[v.arrayRti],s=u.o
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
r(a){var t=a.$ti
return t!=null?t:A.eE(a)},
eE(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.ii(a,t)},
ii(a,b){var t=a instanceof A.O?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.i1(v.typeUniverse,t.name)
b.$ccache=s
return s},
iU(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.dJ(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
iT(a){return A.an(A.r(a))},
eJ(a){var t=A.dU(a)
return A.an(t==null?A.a9(a):t)},
eG(a){var t
if(a instanceof A.al)return A.iN(a.$r,a.al())
t=a instanceof A.O?A.dU(a):null
if(t!=null)return t
if(u.bW.b(a))return J.h6(a).a
if(Array.isArray(a))return A.w(a)
return A.a9(a)},
an(a){var t=a.r
return t==null?a.r=new A.dI(a):t},
iN(a,b){var t,s,r=b,q=r.length
if(q===0)return u.F
if(0>=q)return A.f(r,0)
t=A.bL(v.typeUniverse,A.eG(r[0]),"@<0>")
for(s=1;s<q;++s){if(!(s<r.length))return A.f(r,s)
t=A.fp(v.typeUniverse,t,A.eG(r[s]))}return A.bL(v.typeUniverse,t,a)},
aa(a){return A.an(A.dJ(v.typeUniverse,a,!1))},
ih(a){var t=this
t.b=A.iC(t)
return t.b(a)},
iC(a){var t,s,r,q,p
if(a===u.K)return A.ir
if(A.aM(a))return A.iv
t=a.w
if(t===6)return A.ie
if(t===1)return A.fB
if(t===7)return A.il
s=A.iB(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.aM)){a.f="$i"+r
if(r==="c")return A.ip
if(a===u.m)return A.io
return A.iu}}else if(t===10){q=A.iL(a.x,a.y)
p=q==null?A.fB:q
return p==null?A.fv(p):p}return A.ic},
iB(a){if(a.w===8){if(a===u.p)return A.cu
if(a===u.V||a===u.H)return A.iq
if(a===u.N)return A.it
if(a===u.y)return A.eF}return null},
ig(a){var t=this,s=A.ib
if(A.aM(t))s=A.i6
else if(t===u.K)s=A.fv
else if(A.b5(t)){s=A.id
if(t===u.I)s=A.u
else if(t===u.aD)s=A.ct
else if(t===u.cG)s=A.fs
else if(t===u.ae)s=A.fu
else if(t===u.dd)s=A.i3
else if(t===u.aQ)s=A.i5}else if(t===u.p)s=A.h
else if(t===u.N)s=A.I
else if(t===u.y)s=A.aK
else if(t===u.H)s=A.dL
else if(t===u.V)s=A.ft
else if(t===u.m)s=A.i4
t.a=s
return t.a(a)},
ic(a){var t=this
if(a==null)return A.b5(t)
return A.fI(v.typeUniverse,A.iY(a,t),t)},
ie(a){if(a==null)return!0
return this.x.b(a)},
iu(a){var t,s=this
if(a==null)return A.b5(s)
t=s.f
if(a instanceof A.y)return!!a[t]
return!!J.aL(a)[t]},
ip(a){var t,s=this
if(a==null)return A.b5(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.y)return!!a[t]
return!!J.aL(a)[t]},
io(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.y)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
fA(a){if(typeof a=="object"){if(a instanceof A.y)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
ib(a){var t=this
if(a==null){if(A.b5(t))return a}else if(t.b(a))return a
throw A.L(A.fx(a,t),new Error())},
id(a){var t=this
if(a==null||t.b(a))return a
throw A.L(A.fx(a,t),new Error())},
fx(a,b){return new A.b1("TypeError: "+A.fe(a,A.V(b,null)))},
fG(a,b,c,d){if(A.fI(v.typeUniverse,a,b))return a
throw A.L(A.hU("The type argument '"+A.V(a,null)+"' is not a subtype of the type variable bound '"+A.V(b,null)+"' of type variable '"+c+"' in '"+d+"'."),new Error())},
fe(a,b){return A.bX(a)+": type '"+A.V(A.eG(a),null)+"' is not a subtype of type '"+b+"'"},
hU(a){return new A.b1("TypeError: "+a)},
a3(a,b){return new A.b1("TypeError: "+A.fe(a,b))},
il(a){var t=this
return t.x.b(a)||A.ex(v.typeUniverse,t).b(a)},
ir(a){return a!=null},
fv(a){if(a!=null)return a
throw A.L(A.a3(a,"Object"),new Error())},
iv(a){return!0},
i6(a){return a},
fB(a){return!1},
eF(a){return!0===a||!1===a},
aK(a){if(!0===a)return!0
if(!1===a)return!1
throw A.L(A.a3(a,"bool"),new Error())},
fs(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.L(A.a3(a,"bool?"),new Error())},
ft(a){if(typeof a=="number")return a
throw A.L(A.a3(a,"double"),new Error())},
i3(a){if(typeof a=="number")return a
if(a==null)return a
throw A.L(A.a3(a,"double?"),new Error())},
cu(a){return typeof a=="number"&&Math.floor(a)===a},
h(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.L(A.a3(a,"int"),new Error())},
u(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.L(A.a3(a,"int?"),new Error())},
iq(a){return typeof a=="number"},
dL(a){if(typeof a=="number")return a
throw A.L(A.a3(a,"num"),new Error())},
fu(a){if(typeof a=="number")return a
if(a==null)return a
throw A.L(A.a3(a,"num?"),new Error())},
it(a){return typeof a=="string"},
I(a){if(typeof a=="string")return a
throw A.L(A.a3(a,"String"),new Error())},
ct(a){if(typeof a=="string")return a
if(a==null)return a
throw A.L(A.a3(a,"String?"),new Error())},
i4(a){if(A.fA(a))return a
throw A.L(A.a3(a,"JSObject"),new Error())},
i5(a){if(a==null)return a
if(A.fA(a))return a
throw A.L(A.a3(a,"JSObject?"),new Error())},
fC(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.V(a[r],b)
return t},
iy(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.fC(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.V(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
fy(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.e([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.a.p(a3,"T"+(s+r))
for(q=u.O,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.f(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.V(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.V(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.V(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.V(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.V(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
V(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.V(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.V(a.x,b)+">"
if(m===8){q=A.iF(a.x)
p=a.y
return p.length>0?q+("<"+A.fC(p,b)+">"):q}if(m===10)return A.iy(a,b)
if(m===11)return A.fy(a,b,null)
if(m===12)return A.fy(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.f(b,o)
return b[o]}return"?"},
iF(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
i2(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
i1(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.dJ(a,b,!1)
else if(typeof n=="number"){t=n
s=A.bK(a,5,"#")
r=A.dK(t)
for(q=0;q<t;++q)r[q]=s
p=A.bJ(a,b,r)
o[b]=p
return p}else return n},
i0(a,b){return A.fq(a.tR,b)},
i_(a,b){return A.fq(a.eT,b)},
dJ(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.fi(A.fg(a,null,b,!1))
s.set(b,t)
return t},
bL(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.fi(A.fg(a,b,c,!0))
r.set(c,s)
return s},
fp(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.eC(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
aw(a,b){b.a=A.ig
b.b=A.ih
return b},
bK(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.a7(null,null)
t.w=b
t.as=c
s=A.aw(a,t)
a.eC.set(c,s)
return s},
fn(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.hY(a,b,s,c)
a.eC.set(s,t)
return t},
hY(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.aM(b))if(!(b===u.P||b===u.T))if(t!==6)s=t===7&&A.b5(b.x)
if(s)return b
else if(t===1)return u.P}r=new A.a7(null,null)
r.w=6
r.x=b
r.as=c
return A.aw(a,r)},
fm(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.hW(a,b,s,c)
a.eC.set(s,t)
return t},
hW(a,b,c,d){var t,s
if(d){t=b.w
if(A.aM(b)||b===u.K)return b
else if(t===1)return A.bJ(a,"f_",[b])
else if(b===u.P||b===u.T)return u.bc}s=new A.a7(null,null)
s.w=7
s.x=b
s.as=c
return A.aw(a,s)},
hZ(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.a7(null,null)
t.w=13
t.x=b
t.as=r
s=A.aw(a,t)
a.eC.set(r,s)
return s},
bI(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
hV(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
bJ(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.bI(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.a7(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.aw(a,s)
a.eC.set(q,r)
return r},
eC(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.bI(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.a7(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.aw(a,p)
a.eC.set(r,o)
return o},
fo(a,b,c){var t,s,r="+"+(b+"("+A.bI(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.a7(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.aw(a,t)
a.eC.set(r,s)
return s},
fl(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.bI(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.bI(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.hV(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.a7(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.aw(a,q)
a.eC.set(s,p)
return p},
eD(a,b,c,d){var t,s=b.as+("<"+A.bI(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.hX(a,b,c,s,d)
a.eC.set(s,t)
return t},
hX(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.dK(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.ax(a,b,s,0)
n=A.b2(a,c,s,0)
return A.eD(a,o,n,c!==n)}}m=new A.a7(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.aw(a,m)},
fg(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
fi(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.hO(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.fh(a,s,m,l,!1)
else if(r===46)s=A.fh(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.aJ(a.u,a.e,l.pop()))
break
case 94:l.push(A.hZ(a.u,l.pop()))
break
case 35:l.push(A.bK(a.u,5,"#"))
break
case 64:l.push(A.bK(a.u,2,"@"))
break
case 126:l.push(A.bK(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.hQ(a,l)
break
case 38:A.hP(a,l)
break
case 63:q=a.u
l.push(A.fn(q,A.aJ(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.fm(q,A.aJ(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.hN(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.fj(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.hS(a.u,a.e,p)
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
return A.aJ(a.u,a.e,n)},
hO(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
fh(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.i2(t,p.x)[q]
if(o==null)A.eN('No "'+q+'" in "'+A.hF(p)+'"')
d.push(A.bL(t,p,o))}else d.push(q)
return n},
hQ(a,b){var t,s=a.u,r=A.ff(a,b),q=b.pop()
if(typeof q=="string")b.push(A.bJ(s,q,r))
else{t=A.aJ(s,a.e,q)
switch(t.w){case 11:b.push(A.eD(s,t,r,a.n))
break
default:b.push(A.eC(s,t,r))
break}}},
hN(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.ff(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.aJ(q,a.e,p)
r=new A.co()
r.a=t
r.b=o
r.c=n
b.push(A.fl(q,s,r))
return
case-4:b.push(A.fo(q,b.pop(),t))
return
default:throw A.d(A.bP("Unexpected state under `()`: "+A.z(p)))}},
hP(a,b){var t=b.pop()
if(0===t){b.push(A.bK(a.u,1,"0&"))
return}if(1===t){b.push(A.bK(a.u,4,"1&"))
return}throw A.d(A.bP("Unexpected extended operation "+A.z(t)))},
ff(a,b){var t=b.splice(a.p)
A.fj(a.u,a.e,t)
a.p=b.pop()
return t},
aJ(a,b,c){if(typeof c=="string")return A.bJ(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.hR(a,b,c)}else return c},
fj(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.aJ(a,b,c[t])},
hS(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.aJ(a,b,c[t])},
hR(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.d(A.bP("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.d(A.bP("Bad index "+c+" for "+b.n(0)))},
fI(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.J(a,b,null,c,null)
s.set(c,t)}return t},
J(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.aM(d))return!0
t=b.w
if(t===4)return!0
if(A.aM(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.J(a,c[b.x],c,d,e))return!0
r=d.w
q=u.P
if(b===q||b===u.T){if(r===7)return A.J(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.J(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.J(a,b.x,c,d,e))return!1
return A.J(a,A.ex(a,b),c,d,e)}if(t===6)return A.J(a,q,c,d,e)&&A.J(a,b.x,c,d,e)
if(r===7){if(A.J(a,b,c,d.x,e))return!0
return A.J(a,b,c,A.ex(a,d),e)}if(r===6)return A.J(a,b,c,q,e)||A.J(a,b,c,d.x,e)
if(s)return!1
q=t!==11
if((!q||t===12)&&d===u.Z)return!0
p=t===10
if(p&&d===u.cY)return!0
if(r===12){if(b===u.e)return!0
if(t!==12)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.J(a,k,c,j,e)||!A.J(a,j,e,k,c))return!1}return A.fz(a,b.x,c,d.x,e)}if(r===11){if(b===u.e)return!0
if(q)return!1
return A.fz(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.im(a,b,c,d,e)}if(p&&r===10)return A.is(a,b,c,d,e)
return!1},
fz(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.J(a2,a3.x,a4,a5.x,a6))return!1
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
if(!A.J(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.J(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.J(a2,l[i],a6,h,a4))return!1}g=t.c
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
if(!A.J(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
im(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.bL(a,b,s[p])
return A.fr(a,q,null,c,d.y,e)}return A.fr(a,b.y,null,c,d.y,e)},
fr(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.J(a,b[t],d,e[t],f))return!1
return!0},
is(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.J(a,s[t],c,r[t],e))return!1
return!0},
b5(a){var t=a.w,s=!0
if(!(a===u.P||a===u.T))if(!A.aM(a))if(t!==6)s=t===7&&A.b5(a.x)
return s},
aM(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.O},
fq(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
dK(a){return a>0?new Array(a):v.typeUniverse.sEA},
a7:function a7(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
co:function co(){this.c=this.b=this.a=null},
dI:function dI(a){this.a=a},
cn:function cn(){},
b1:function b1(a){this.a=a},
fk(a,b,c){return 0},
bH:function bH(a,b){var _=this
_.a=a
_.e=_.d=_.c=_.b=null
_.$ti=b},
b0:function b0(a,b){this.a=a
this.$ti=b},
hy(a,b){return new A.af(a.h("@<0>").v(b).h("af<1,2>"))},
m(a,b,c){return b.h("@<0>").v(c).h("f3<1,2>").a(A.iP(a,new A.af(b.h("@<0>").v(c).h("af<1,2>"))))},
ah(a,b){return new A.af(a.h("@<0>").v(b).h("af<1,2>"))},
f5(a){return new A.aH(a.h("aH<0>"))},
hz(a,b){return b.h("f4<0>").a(A.iQ(a,new A.aH(b.h("aH<0>"))))},
eB(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
hM(a,b,c){var t=new A.aI(a,b,c.h("aI<0>"))
t.c=a.e
return t},
f0(a,b){var t=J.M(a.a)
if(new A.aj(t,a.b,a.$ti.h("aj<1>")).k())return t.gm()
return null},
es(a,b,c){var t=A.hy(b,c)
a.P(0,new A.dr(t,b,c))
return t},
et(a){var t,s
if(A.eL(a))return"{...}"
t=new A.aX("")
try{s={}
B.a.p($.a0,a)
t.a+="{"
s.a=!0
a.P(0,new A.dt(s,t))
t.a+="}"}finally{if(0>=$.a0.length)return A.f($.a0,-1)
$.a0.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
aH:function aH(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
cs:function cs(a){this.a=a
this.b=null},
aI:function aI(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
dr:function dr(a,b,c){this.a=a
this.b=b
this.c=c},
q:function q(){},
x:function x(){},
ds:function ds(a){this.a=a},
dt:function dt(a,b){this.a=a
this.b=b},
as:function as(){},
bG:function bG(){},
ix(a,b){var t,s,r,q=null
try{q=JSON.parse(a)}catch(s){t=A.eO(s)
r=A.eZ(String(t))
throw A.d(r)}r=A.dQ(q)
return r},
dQ(a){var t
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.cq(a,Object.create(null))
for(t=0;t<a.length;++t)a[t]=A.dQ(a[t])
return a},
f2(a,b,c){return new A.bj(a,b)},
i9(a){return a.W()},
hK(a,b){return new A.dB(a,[],A.iK())},
hL(a,b,c){var t,s=new A.aX(""),r=A.hK(s,b)
r.ad(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
cq:function cq(a,b){this.a=a
this.b=b
this.c=null},
cr:function cr(a){this.a=a},
bU:function bU(){},
bW:function bW(){},
bj:function bj(a,b){this.a=a
this.b=b},
c4:function c4(a,b){this.a=a
this.b=b},
dm:function dm(){},
dp:function dp(a){this.b=a},
dn:function dn(a){this.a=a},
dC:function dC(){},
dD:function dD(a,b){this.a=a
this.b=b},
dB:function dB(a,b,c){this.c=a
this.a=b
this.b=c},
j_(a){var t=A.hB(a,null)
if(t!=null)return t
throw A.d(A.eZ(a))},
c5(a,b,c,d){var t,s=c?J.f1(a,d):J.hu(a,d)
if(a!==0&&b!=null)for(t=0;t<s.length;++t)s[t]=b
return s},
hA(a,b,c){var t,s,r=A.e([],c.h("p<0>"))
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.D)(a),++s)B.a.p(r,c.a(a[s]))
r.$flags=1
return r},
S(a,b){var t,s
if(Array.isArray(a))return A.e(a.slice(0),b.h("p<0>"))
t=A.e([],b.h("p<0>"))
for(s=J.M(a);s.k();)B.a.p(t,s.gm())
return t},
f6(a,b,c){var t,s=J.f1(a,c)
for(t=0;t<a;++t)B.a.l(s,t,b.$1(t))
return s},
fa(a,b,c){var t=J.M(b)
if(!t.k())return a
if(c.length===0){do a+=A.z(t.gm())
while(t.k())}else{a+=A.z(t.gm())
while(t.k())a=a+c+A.z(t.gm())}return a},
bX(a){if(typeof a=="number"||A.eF(a)||a==null)return J.ao(a)
if(typeof a=="string")return JSON.stringify(a)
return A.f8(a)},
bP(a){return new A.bO(a)},
cx(a){return new A.ap(!1,null,null,a)},
hC(a){var t=null
return new A.aW(t,t,!1,t,t,a)},
hD(a,b){return new A.aW(null,null,!0,a,b,"Value not in range")},
aE(a,b,c,d,e){return new A.aW(b,c,!0,a,d,"Invalid value")},
hE(a,b,c){if(0>a||a>c)throw A.d(A.aE(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.d(A.aE(b,a,c,"end",null))
return b}return c},
dv(a,b){if(a<0)throw A.d(A.aE(a,0,null,b,null))
return a},
dj(a,b,c,d){return new A.bY(b,!0,a,d,"Index out of range")},
fd(a){return new A.bx(a)},
fc(a){return new A.cl(a)},
ey(a){return new A.aF(a)},
P(a){return new A.bV(a)},
eZ(a){return new A.bd(a)},
ht(a,b,c){var t,s
if(A.eL(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.e([],u.s)
B.a.p($.a0,a)
try{A.iw(a,t)}finally{if(0>=$.a0.length)return A.f($.a0,-1)
$.a0.pop()}s=A.fa(b,u.c.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
ep(a,b,c){var t,s
if(A.eL(a))return b+"..."+c
t=new A.aX(b)
B.a.p($.a0,a)
try{s=t
s.a=A.fa(s.a,a,", ")}finally{if(0>=$.a0.length)return A.f($.a0,-1)
$.a0.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
iw(a,b){var t,s,r,q,p,o,n,m=a.gq(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.k())return
t=A.z(m.gm())
B.a.p(b,t)
l+=t.length+2;++k}if(!m.k()){if(k<=5)return
if(0>=b.length)return A.f(b,-1)
s=b.pop()
if(0>=b.length)return A.f(b,-1)
r=b.pop()}else{q=m.gm();++k
if(!m.k()){if(k<=4){B.a.p(b,A.z(q))
return}s=A.z(q)
if(0>=b.length)return A.f(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gm();++k
for(;m.k();q=p,p=o){o=m.gm();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.f(b,-1)
l-=b.pop().length+2;--k}B.a.p(b,"...")
return}}r=A.z(q)
s=A.z(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.f(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.p(b,n)
B.a.p(b,r)
B.a.p(b,s)},
ev(a,b,c,d){var t
if(B.m===c){t=J.X(a)
b=J.X(b)
return A.ez(A.at(A.at($.ei(),t),b))}if(B.m===d){t=J.X(a)
b=J.X(b)
c=J.X(c)
return A.ez(A.at(A.at(A.at($.ei(),t),b),c))}t=J.X(a)
b=J.X(b)
c=J.X(c)
d=J.X(d)
d=A.ez(A.at(A.at(A.at(A.at($.ei(),t),b),c),d))
return d},
A:function A(){},
bO:function bO(a){this.a=a},
bw:function bw(){},
ap:function ap(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
aW:function aW(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
bY:function bY(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
bx:function bx(a){this.a=a},
cl:function cl(a){this.a=a},
aF:function aF(a){this.a=a},
bV:function bV(a){this.a=a},
bu:function bu(){},
dz:function dz(a){this.a=a},
bd:function bd(a){this.a=a},
b:function b(){},
U:function U(a,b,c){this.a=a
this.b=b
this.$ti=c},
br:function br(){},
y:function y(){},
aX:function aX(a){this.a=a},
fM(a,b,c){A.fG(c,u.H,"T","min")
return Math.min(c.a(a),c.a(b))},
fL(a,b,c){A.fG(c,u.H,"T","max")
return Math.max(c.a(a),c.a(b))},
cp:function cp(){},
fE(a,b){var t=2147483646,s={}
s.a=B.b.t(a+B.b.t(b,t)*104729,t)+1
return A.f6(3,new A.dT(s),u.k)},
em(a,b){var t=2147483646
return new A.bR(B.b.t(a+B.b.t(b,t)*104729,t)+1)},
iO(a2,a3,a4,a5){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=A.em(a2,a3),a1=A.S(a4,u.W)
B.a.T(a1,new A.e4())
t=u.J
s=A.e([],t)
for(r=a1.length,q=u.A,p=0;p<a1.length;a1.length===r||(0,A.D)(a1),++p){o=a1[p]
s.push(A.iA(A.hT(o.c),J.eS(o.e,q)))}a1=!1
if(a5)if(s.length!==0){a1=B.a.gb0(s)
a1=a1.gav()>=0.5&&a1.b5()<$.bN().length/3}n=a1?A.iz(s,a0):null
a1=n==null
r=!a1
if(r)for(m=s.length,p=0;p<s.length;s.length===m||(0,A.D)(s),++p){l=s[p]
l.aG(n,l.Z(n).a)}m=u.a
k=A.e([],m)
for(j=u.ba,i=u.cC,h=u.B,g=u.Q,f=-1/0,e=0;e<6;++e){d=A.e([],t)
for(c=s.length,p=0;p<s.length;s.length===c||(0,A.D)(s),++p){b=new Uint8Array(A.fw(s[p].a))
d.push(new A.a2(b,B.q.b8(Math.sqrt(b.length))))}c=A.e([],m)
if(r)c.push(new A.n(n,B.b.t(n,8)))
B.a.Y(c,A.i7(d,a0,a1?3:2))
if(c.length<3||new A.t(c,h.a(new A.e5()),g).gj(0)>1)continue
a=d.length===0?0:new A.H(d,j.a(new A.e6()),i).V(0,B.E)
if(a>f){f=a
k=c}}if(k.length===0){a1=J.eS(A.ha(null,a0).e,q)
k=A.S(a1,a1.$ti.h("b.E"))}B.a.aK(k,a0)
return new A.a1(k,r&&B.a.G(k,new A.e7(n)))},
iz(a,b){var t,s,r,q,p,o,n,m,l=null,k=B.b.t(b.a*48271,2147483647)
b.a=k
if((k-1)/2147483646>=0.5)return l
for(k=A.w(a),t=k.c,k=k.h("bv<1>"),s=l,r=0,q=0;q<39;++q){p=B.a.gb0(a).Z(q)
if(p==null||p.b===0)continue
o=new A.bv(a,1,l,k)
o.bh(a,1,l,t)
if(o.G(0,new A.dR(q)))continue
o=p.b
n=$.ej().D(0,q)?0:50
m=o*100+n+B.d[q].length
if(m>r){r=m
s=q}}return s},
i7(b1,b2,b3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0=A.e([],u.a)
for(t=u.H,s=u.t,r=u.B,q=u.Q,p=u.r,o=A.w(b1),n=o.h("j(1)"),o=o.h("H<1,j>"),m=0;m<b3;++m){l=b1.length===0?0:new A.H(b1,n.a(new A.dM()),o).V(0,B.F)
k=A.e([],p)
for(j=$.bN(),i=j.length,h=l>0.45,g=l<0.35,f=1+(l-0.45)*4,e=l>0.4,d=0;d<j.length;j.length===i||(0,A.D)(j),++d){c=j[d]
b=A.e([],s)
for(a=b1.length,a0=0,a1=81,a2=0;a2<b1.length;b1.length===a||(0,A.D)(b1),++a2){a3=b1[a2].Z(c)
if(a3==null)break
B.a.p(b,a3.a)
a0+=a3.b
a1=Math.min(a1,a3.c)}if(b.length!==b1.length)continue
if(!(c<39))return A.f(B.d,c)
a4=B.d[c].length
a=a4>=5
if(a&&new A.t(b0,r.a(new A.dN()),q).gj(0)===2)continue
a5=a4===1?0.18:1
if(a)a5*=g?1.3:0.6
if(h&&a4<=3)a5*=f
if(a0>0)a5*=1+a0*(e?1.2:0.4)
if(B.a.G(b0,new A.dO(c)))a5*=0.25
B.a.p(k,new A.av(c,b,a5*(a1/(a1+6))))}if(k.length===0)break
j=B.b.t(b2.a*48271,2147483647)
b2.a=j
a6=(j-1)/2147483646*B.a.aw(k,0,new A.dP(),t)
a7=B.a.gb4(k)
for(j=k.length,d=0;d<j;++d){a8=k[d]
a6-=a8.c
if(a6<=0){a7=a8
break}}j=a7.a
B.a.p(b0,new A.n(j,B.b.t(j,8)))
for(i=a7.b,h=J.a8(i),a9=0;a9<b1.length;++a9)b1[a9].aG(j,h.i(i,a9))}return b0},
iA(a,b){var t,s,r,q,p=A.S(b,u.A)
B.a.T(p,new A.dS())
for(t=p.length,s=0;s<p.length;p.length===t||(0,A.D)(p),++s){r=p[s].a
q=a.Z(r)
if(q!=null)a.aG(r,q.a)}return a},
hT(a){var t,s,r,q=A.e([],u.t)
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.D)(a),++s)for(r=J.M(a[s]);r.k();)q.push(r.gm()==null?0:1)
q=new Uint8Array(A.fw(q))
return new A.a2(q,B.q.b8(Math.sqrt(q.length)))},
h9(a,b,c,d){var t=u.s,s=A.e([],t)
t=A.e([],t)
return new A.F(a,c,b,s,t)},
iM(a,b){var t=A.f0(b.bf(0,b.$ti.h("i(C.E)").a(new A.dW(a))),u.p)
if(a==null||t==null)return A.e([],u.t)
return B.a.be(A.e([a,t,t,a],u.t),0,4)},
eT(a,b,c){return new A.bQ(a,b,c,A.e([],u.x),A.e([],u.t),A.ah(u.p,u.U),A.e([],u.X))},
h8(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g="version",f="joker"
if(!J.E(a.i(0,g),1)&&!J.E(a.i(0,g),2))throw A.d(B.N)
t=A.eT(A.I(a.i(0,"roomId")),A.h(a.i(0,"seed")),A.h(a.i(0,"createdAt")))
t.r=A.h(a.i(0,g))
t.e=A.I(B.r.I(a.i(0,"mode"))?a.i(0,"mode"):"duel")
s=A.e([],u.t)
r=u.g
q=r.a(a.i(0,"invited"))
q=J.M(q==null?[]:q)
while(q.k())s.push(A.h(q.gm()))
t.sb2(s)
s=a.i(0,"round")
t.w=A.h(s==null?1:s)
t.y=J.E(a.i(0,"jokers"),!0)
t.z=A.u(a.i(0,"draftEnd"))
t.Q=A.u(a.i(0,"picker"))
s=A.u(a.i(0,"lastRescue"))
t.as=s==null?-100:s
t.at=A.I(a.i(0,"status"))
t.ax=A.h(a.i(0,"revision"))
t.ay=A.u(a.i(0,"startAt"))
t.ch=A.u(a.i(0,"endedAt"))
t.CW=A.u(a.i(0,"winner"))
t.cx=A.ct(a.i(0,"reason"))
s=u.a5.a(a.i(0,"sets"))
if(s==null){s=u.z
s=A.ah(s,s)}s=s.ga8()
s=s.gq(s)
q=u.c
p=t.x
o=u.b
while(s.k()){n=s.gm()
m=A.j_(A.I(n.a))
l=A.e([],o)
for(n=J.M(q.a(n.b));n.k();){k=n.gm()
if(k==null)j=null
else{j=J.a8(k)
j=new A.n(A.h(j.i(k,0)),A.h(j.i(k,1)))}l.push(j)}p.l(0,m,l)}for(s=J.M(q.a(a.i(0,"players"))),q=t.d,p=u.f,o=u.N,n=u.z,m=t.gaV(),l=u.s;s.k();){j=A.es(p.a(s.gm()),o,n)
i=t.b
k=new A.F(A.h(j.i(0,"id")),i,A.I(j.i(0,"name")),A.e([],l),A.e([],l))
k.f=A.h(j.i(0,"nextSet"))
k.r=A.h(j.i(0,"lives"))
k.w=A.h(j.i(0,"boardOuts"))
k.x=A.h(j.i(0,"thresholds"))
k.y=A.h(j.i(0,"damage"))
k.z=A.h(j.i(0,"lastMove"))
k.Q=A.aK(j.i(0,"ready"))
k.as=A.aK(j.i(0,"connected"))
i=j.i(0,"rematch")
k.at=A.aK(i==null?!1:i)
k.ax=A.u(j.i(0,"disconnectAt"))
k.ay=J.E(j.i(0,"out"),!0)
k.ch=A.u(j.i(0,"place"))
i=A.e([],l)
h=r.a(j.i(0,"jokers"))
h=h==null?null:J.eR(h,o)
if(h!=null)B.a.Y(i,h)
if(typeof j.i(0,f)=="string")i.push(A.I(j.i(0,f)))
k.saD(i)
i=A.e([],l)
h=r.a(j.i(0,"usedJokers"))
h=h==null?null:J.eR(h,o)
if(h!=null)B.a.Y(i,h)
if(J.E(j.i(0,"jokerUsed"),!0)&&typeof j.i(0,f)=="string")i.push(A.I(j.i(0,f)))
k.sb9(i)
k.cy=A.u(j.i(0,"frozenUntil"))
k.db=A.u(j.i(0,"stuckAt"))
k.dx=A.u(j.i(0,"stuckLeft"))
k.dy=A.u(j.i(0,"aimUntil"))
k.fr=A.u(j.i(0,"expandUntil"))
k.fx=A.ct(j.i(0,"expandCorner"))
k.fy=A.u(j.i(0,"reflectUntil"))
k.go=J.E(j.i(0,"reflected"),!0)
k.id=A.u(j.i(0,"saltUntil"))
j=A.hd(A.es(p.a(j.i(0,"game")),o,n),k.gap())
j.toString
k.e=j
k.saJ(m)
if(!J.E(a.i(0,"damageStep"),500))k.x=B.b.aq(k.e.f,500)
B.a.p(q,k)}return t},
dT:function dT(a){this.a=a},
bR:function bR(a){this.a=a},
e4:function e4(){},
dX:function dX(){},
dY:function dY(){},
dZ:function dZ(){},
e_:function e_(){},
e0:function e0(){},
e1:function e1(){},
e2:function e2(){},
e3:function e3(){},
e5:function e5(){},
e6:function e6(){},
e7:function e7(a){this.a=a},
dR:function dR(a){this.a=a},
dM:function dM(){},
dN:function dN(){},
dO:function dO(a){this.a=a},
dP:function dP(){},
dS:function dS(){},
a2:function a2(a,b){this.a=a
this.b=b},
dF:function dF(){},
dG:function dG(){},
dH:function dH(){},
F:function F(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=null
_.d=c
_.e=$
_.f=0
_.r=5
_.z=_.y=_.x=_.w=0
_.at=_.as=_.Q=!1
_.ax=null
_.ay=!1
_.ch=null
_.CW=d
_.cx=e
_.fy=_.fx=_.fr=_.dy=_.dx=_.db=_.cy=null
_.go=!1
_.id=null},
cW:function cW(a){this.a=a},
dW:function dW(a){this.a=a},
bQ:function bQ(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e="duel"
_.f=e
_.r=2
_.w=1
_.x=f
_.y=!1
_.Q=_.z=null
_.as=-100
_.at="waiting"
_.ax=0
_.cx=_.CW=_.ch=_.ay=null
_.cy=g},
cJ:function cJ(){},
cB:function cB(a,b){this.a=a
this.b=b},
cA:function cA(){},
cD:function cD(){},
cC:function cC(a){this.a=a},
cP:function cP(a){this.a=a},
cK:function cK(a){this.a=a},
cy:function cy(){},
cE:function cE(){},
cz:function cz(a){this.a=a},
cS:function cS(){},
cT:function cT(){},
cU:function cU(){},
cV:function cV(a){this.a=a},
cF:function cF(a){this.a=a},
cG:function cG(){},
cH:function cH(a){this.a=a},
cI:function cI(){},
cL:function cL(){},
cM:function cM(a){this.a=a},
cN:function cN(){},
cO:function cO(){},
cQ:function cQ(){},
cR:function cR(){},
j5(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=a.length
for(t=u.bx,s=u.p,r=null,q=0,p=0;p<39;++p){o=B.d[p]
for(n=o.length,m=0;m<b;++m)for(l=0;l<b;++l){if(!B.a.E(o,new A.ee(m,l,b,a)))continue
k=A.f5(s)
for(j=0;j<n;++j){i=o[j]
k.p(0,(m+i[0])*b+l+i[1])}h=new A.eh(a,k,b)
for(g=0,f=0;f<b;++f){e=A.e(new Array(b),t)
for(d=0;d<b;++d)e[d]=h.$2(f,d)
if(B.a.E(e,new A.ef()))++g
e=A.e(new Array(b),t)
for(d=0;d<b;++d)e[d]=h.$2(d,f)
if(B.a.E(e,new A.eg()))++g}if(g===0)continue
k=$.ej().D(0,p)?0:50
c=g*100+k+n
if(c>q){r=new A.av(p,m,l)
q=c}}}return r},
hc(a){A.u(a)
return a!=null&&a!==8},
ha(a,b){var t,s,r,q=J.aS(8,u.R)
for(t=u.I,s=0;s<8;++s)q[s]=A.c5(8,null,!1,t)
t=A.e([null,null,null],u.b)
if(b==null)r=B.x
else r=b
t=new A.Z(r,a,q,t)
t.a0()
return t},
cX(a,b){var t,s,r=J.aS(8,u.R)
for(t=u.I,s=0;s<8;++s)r[s]=A.c5(8,null,!1,t)
t=A.e([null,null,null],u.b)
return new A.Z(B.x,a,r,t)},
en(a){var t,s,r,q,p,o=u.t,n=A.e([],o)
for(t=0;t<a.length;++t)if(J.cw(a[t],A.fF()))n.push(t)
o=A.e([],o)
for(s=u.d,r=0;q=a.length,r<q;++r){p=A.e(new Array(q),s)
for(t=0;t<q;++t){if(!(t<a.length))return A.f(a,t)
p[t]=J.l(a[t],r)}if(B.a.E(p,A.fF()))o.push(r)}return new A.a1(n,o)},
cY(a){var t,s,r,q,p,o,n=A.en(a),m=n.a,l=n.b,k=a.length,j=u.p
j=A.ah(j,j)
for(t=m.length,s=0;s<m.length;m.length===t||(0,A.D)(m),++s){r=m[s]
for(q=r*k,p=0;p<k;++p){if(!(r<a.length))return A.f(a,r)
o=J.l(a[r],p)
o.toString
j.l(0,q+p,o)}}for(t=l.length,s=0;s<l.length;l.length===t||(0,A.D)(l),++s){p=l[s]
for(r=0;r<k;++r){if(!(r<a.length))return A.f(a,r)
q=J.l(a[r],p)
q.toString
j.l(0,r*k+p,q)}}for(t=new A.aB(j,j.r,j.e,j.$ti.h("aB<1>"));t.k();){q=t.d
o=B.b.aM(q,k)
if(!(o>=0&&o<a.length))return A.f(a,o)
J.aO(a[o],B.b.t(q,k),null)}return j},
hb(a){var t,s,r,q,p=A.e([],u.E)
for(t=a.length,s=u.I,r=0;r<a.length;a.length===t||(0,A.D)(a),++r){q=A.S(a[r],s)
p.push(q)}return p},
eo(a,b,c,d){var t,s,r,q,p,o=b.a
if(!(o>=0&&o<39))return A.f(B.d,o)
o=B.d[o]
t=o.length
s=b.b
r=0
for(;r<t;++r){q=o[r]
p=c+q[0]
if(!(p>=0&&p<a.length))return A.f(a,p)
J.aO(a[p],d+q[1],s)}},
he(a){var t,s=a.length,r=A.w(a),q=r.h("Q<1,a?>")
if(new A.t(new A.Q(a,r.h("b<a?>(1)").a(new A.dd()),q),q.h("i(b.E)").a(new A.de()),q.h("t<b.E>")).gj(0)/(s*s)<0.5)return!1
t=A.cX(null,null)
t.sae(a)
r=$.bN()
q=A.w(r)
return new A.t(r,q.h("i(1)").a(new A.df(t)),q.h("t<1>")).gj(0)<r.length/3},
hd(b0,b1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=null,a5="placementsMade",a6="linesCleared",a7="bestCombo",a8="allClears",a9=null
try{if(!J.E(b0.i(0,"version"),1))return a4
f=u.j
e=J.el(f.a(b0.i(0,"grid")),new A.d9(),u.R)
d=A.S(e,e.$ti.h("C.E"))
t=d
if(J.Y(t)!==8&&J.Y(t)!==9||J.eQ(t,new A.da(t)))return a4
f=J.el(f.a(b0.i(0,"tray")),new A.db(),u.k)
f=A.S(f,f.$ti.h("C.E"))
s=f
if(J.Y(s)!==3||J.cw(s,new A.dc()))return a4
r=A.h(b0.i(0,"score"))
q=A.h(b0.i(0,"combo"))
p=A.h(b0.i(0,"misses"))
c=A.u(b0.i(0,"comboBonus"))
o=c==null?0:c
b=A.u(b0.i(0,a5))
n=b==null?0:b
a=A.u(b0.i(0,a6))
m=a==null?0:a
a0=A.u(b0.i(0,a7))
l=a0==null?q:a0
a1=A.u(b0.i(0,a8))
k=a1==null?0:a1
a2=A.fs(b0.i(0,"runSummaryAvailable"))
if(a2==null)a2=b0.I(a5)&&b0.I(a6)&&b0.I(a7)&&b0.I(a8)
j=a2
f=r
if(typeof f!=="number")return f.R()
e=!0
if(!(f<0)){f=q
if(typeof f!=="number")return f.R()
if(!(f<0)){f=p
if(typeof f!=="number")return f.R()
if(!(f<0)){f=p
if(typeof f!=="number")return f.aI()
if(!(f>=3))if(!(J.E(q,0)&&!J.E(p,0))){f=n
if(typeof f!=="number")return f.R()
if(!(f<0)){f=m
if(typeof f!=="number")return f.R()
if(!(f<0)){f=k
if(typeof f!=="number")return f.R()
f=f<0}else f=e}else f=e}else f=e
else f=e}else f=e}else f=e}else f=e
if(f)return a4
i=null
h=null
g=A.en(t)
i=g.a
h=g.b
if(J.Y(i)!==0||J.Y(h)!==0)return a4
f=A.cX(b1,a9)
f.sae(t)
f.sc5(s)
f.sbc(r)
f.sbD(q)
f.sbS(p)
f.sbE(o)
f.ax=A.aK(b0.i(0,"reviveUsed"))
e=A.u(b0.i(0,"sinceRescue"))
f.d=e==null?6:e
f.sbX(n)
f.sbR(m)
f.sbA(l)
f.sbz(k)
f.sc4(j)
return f}catch(a3){return a4}},
ee:function ee(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
eh:function eh(a,b,c){this.a=a
this.b=b
this.c=c},
ef:function ef(){},
eg:function eg(){},
n:function n(a,b){this.a=a
this.b=b},
di:function di(){},
dh:function dh(){},
dg:function dg(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
Z:function Z(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=6
_.e=d
_.as=_.Q=_.z=_.y=_.x=_.w=_.r=_.f=0
_.at=!0
_.ax=!1},
d_:function d_(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
d0:function d0(a){this.a=a},
cZ:function cZ(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
d2:function d2(){},
d1:function d1(){},
d3:function d3(){},
d4:function d4(){},
d5:function d5(){},
d6:function d6(a){this.a=a},
d7:function d7(){},
dd:function dd(){},
de:function de(){},
df:function df(a){this.a=a},
d9:function d9(){},
d8:function d8(){},
da:function da(a){this.a=a},
db:function db(){},
dc:function dc(){},
j2(){var t,s=v.G.globalThis,r=new A.ec()
if(typeof r=="function")A.eN(A.cx("Attempting to rewrap a JS function."))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.i8,r)
t[$.eP()]=r
s.blockBattleRules=t},
ec:function ec(){},
j6(a){throw A.L(new A.bk("Field '"+a+"' has been assigned during initialization."),new Error())},
W(){throw A.L(A.hx(""),new Error())},
i8(a,b,c){u.Z.a(a)
if(A.h(c)>=1)return a.$1(b)
return a.$0()}},B={}
var w=[A,J,B]
var $={}
A.eq.prototype={}
J.c_.prototype={
O(a,b){return a===b},
gB(a){return A.cg(a)},
n(a){return"Instance of '"+A.ch(a)+"'"},
gA(a){return A.an(A.eE(this))}}
J.c1.prototype={
n(a){return String(a)},
gB(a){return a?519018:218159},
gA(a){return A.an(u.y)},
$iv:1,
$ii:1}
J.bf.prototype={
O(a,b){return null==b},
n(a){return"null"},
gB(a){return 0},
$iv:1}
J.bh.prototype={$iG:1}
J.ar.prototype={
gB(a){return 0},
n(a){return String(a)}}
J.cf.prototype={}
J.aY.prototype={}
J.aq.prototype={
n(a){var t=a[$.eP()]
if(t==null)return this.bg(a)
return"JavaScript function for "+J.ao(t)},
$iae:1}
J.bg.prototype={
gB(a){return 0},
n(a){return String(a)}}
J.bi.prototype={
gB(a){return 0},
n(a){return String(a)}}
J.p.prototype={
a7(a,b){return new A.ac(a,A.w(a).h("@<1>").v(b).h("ac<1,2>"))},
p(a,b){A.w(a).c.a(b)
a.$flags&1&&A.a5(a,29)
a.push(b)},
a1(a,b){var t
a.$flags&1&&A.a5(a,"remove",1)
for(t=0;t<a.length;++t)if(J.E(a[t],b)){a.splice(t,1)
return!0}return!1},
Y(a,b){var t
A.w(a).h("b<1>").a(b)
a.$flags&1&&A.a5(a,"addAll",2)
if(Array.isArray(b)){this.bj(a,b)
return}for(t=J.M(b);t.k();)a.push(t.gm())},
bj(a,b){var t,s
u.o.a(b)
t=b.length
if(t===0)return
if(a===b)throw A.d(A.P(a))
for(s=0;s<t;++s)a.push(b[s])},
ar(a){a.$flags&1&&A.a5(a,"clear","clear")
a.length=0},
a_(a,b,c){var t=A.w(a)
return new A.H(a,t.v(c).h("1(2)").a(b),t.h("@<1>").v(c).h("H<1,2>"))},
aC(a,b){var t,s=A.c5(a.length,"",!1,u.N)
for(t=0;t<a.length;++t)this.l(s,t,A.z(a[t]))
return s.join(b)},
aw(a,b,c,d){var t,s,r
d.a(b)
A.w(a).v(d).h("1(1,2)").a(c)
t=a.length
for(s=b,r=0;r<t;++r){s=c.$2(s,a[r])
if(a.length!==t)throw A.d(A.P(a))}return s},
bL(a,b){var t,s,r
A.w(a).h("i(1)").a(b)
t=a.length
for(s=0;s<t;++s){r=a[s]
if(b.$1(r))return r
if(a.length!==t)throw A.d(A.P(a))}throw A.d(A.aR())},
C(a,b){if(!(b>=0&&b<a.length))return A.f(a,b)
return a[b]},
be(a,b,c){var t=a.length
if(b>t)throw A.d(A.aE(b,0,t,"start",null))
if(c<b||c>t)throw A.d(A.aE(c,b,t,"end",null))
if(b===c)return A.e([],A.w(a))
return A.e(a.slice(b,c),A.w(a))},
gb0(a){if(a.length>0)return a[0]
throw A.d(A.aR())},
gb4(a){var t=a.length
if(t>0)return a[t-1]
throw A.d(A.aR())},
gaL(a){var t=a.length
if(t===1){if(0>=t)return A.f(a,0)
return a[0]}if(t===0)throw A.d(A.aR())
throw A.d(A.hs())},
G(a,b){var t,s
A.w(a).h("i(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(b.$1(a[s]))return!0
if(a.length!==t)throw A.d(A.P(a))}return!1},
E(a,b){var t,s
A.w(a).h("i(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(!b.$1(a[s]))return!1
if(a.length!==t)throw A.d(A.P(a))}return!0},
T(a,b){var t,s,r,q,p,o=A.w(a)
o.h("a(1,1)?").a(b)
a.$flags&2&&A.a5(a,"sort")
t=a.length
if(t<2)return
if(b==null)b=J.ij()
if(t===2){s=a[0]
r=a[1]
o=b.$2(s,r)
if(typeof o!=="number")return o.cc()
if(o>0){a[0]=r
a[1]=s}return}q=0
if(o.c.b(null))for(p=0;p<a.length;++p)if(a[p]===void 0){a[p]=null;++q}a.sort(A.iI(b,2))
if(q>0)this.br(a,q)},
br(a,b){var t,s=a.length
for(;t=s-1,s>0;s=t)if(a[t]===null){a[t]=void 0;--b
if(b===0)break}},
aK(a,b){var t,s,r,q
a.$flags&2&&A.a5(a,"shuffle")
t=a.length
while(t>1){s=b.aF(t);--t
r=a.length
if(!(t<r))return A.f(a,t)
q=a[t]
if(!(s>=0&&s<r))return A.f(a,s)
a[t]=a[s]
a[s]=q}},
D(a,b){var t
for(t=0;t<a.length;++t)if(J.E(a[t],b))return!0
return!1},
gu(a){return a.length===0},
gN(a){return a.length!==0},
n(a){return A.ep(a,"[","]")},
gq(a){return new J.ay(a,a.length,A.w(a).h("ay<1>"))},
gB(a){return A.cg(a)},
gj(a){return a.length},
i(a,b){if(!(b>=0&&b<a.length))throw A.d(A.cv(a,b))
return a[b]},
l(a,b,c){A.w(a).c.a(c)
a.$flags&2&&A.a5(a)
if(!(b>=0&&b<a.length))throw A.d(A.cv(a,b))
a[b]=c},
aH(a,b){return new A.ak(a,b.h("ak<0>"))},
$ik:1,
$ib:1,
$ic:1}
J.c0.prototype={
c6(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.ch(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.dk.prototype={}
J.ay.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.D(r)
throw A.d(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0},
$iB:1}
J.aT.prototype={
H(a,b){var t
A.dL(b)
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){t=this.gaB(b)
if(this.gaB(a)===t)return 0
if(this.gaB(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gaB(a){return a===0?1/a<0:a<0},
b8(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw A.d(A.fd(""+a+".round()"))},
bB(a,b,c){if(B.b.H(b,c)>0)throw A.d(A.iH(b))
if(this.H(a,b)<0)return b
if(this.H(a,c)>0)return c
return a},
n(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gB(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
t(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
if(b<0)return t-b
else return t+b},
aM(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.aY(a,b)},
aq(a,b){return(a|0)===a?a/b|0:this.aY(a,b)},
aY(a,b){var t=a/b
if(t>=-2147483648&&t<=2147483647)return t|0
if(t>0){if(t!==1/0)return Math.floor(t)}else if(t>-1/0)return Math.ceil(t)
throw A.d(A.fd("Result of truncating division is "+A.z(t)+": "+A.z(a)+" ~/ "+b))},
aW(a,b){var t
if(a>0)t=this.bu(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
bu(a,b){return b>31?0:a>>>b},
gA(a){return A.an(u.H)},
$iad:1,
$ij:1,
$iK:1}
J.be.prototype={
gA(a){return A.an(u.p)},
$iv:1,
$ia:1}
J.c2.prototype={
gA(a){return A.an(u.V)},
$iv:1}
J.aA.prototype={
a3(a,b,c){return a.substring(b,A.hE(b,c,a.length))},
H(a,b){var t
A.I(b)
if(a===b)t=0
else t=a<b?-1:1
return t},
n(a){return a},
gB(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gA(a){return A.an(u.N)},
gj(a){return a.length},
i(a,b){if(b>=a.length)throw A.d(A.cv(a,b))
return a[b]},
$iv:1,
$iad:1,
$io:1}
A.au.prototype={
gq(a){return new A.b6(J.M(this.gS()),A.r(this).h("b6<1,2>"))},
gj(a){return J.Y(this.gS())},
gu(a){return J.h4(this.gS())},
gN(a){return J.h5(this.gS())},
C(a,b){return A.r(this).y[1].a(J.ek(this.gS(),b))},
n(a){return J.ao(this.gS())}}
A.b6.prototype={
k(){return this.a.k()},
gm(){return this.$ti.y[1].a(this.a.gm())},
$iB:1}
A.az.prototype={
gS(){return this.a}}
A.bA.prototype={$ik:1}
A.bz.prototype={
i(a,b){return this.$ti.y[1].a(J.l(this.a,b))},
l(a,b,c){var t=this.$ti
J.aO(this.a,b,t.c.a(t.y[1].a(c)))},
$ik:1,
$ic:1}
A.ac.prototype={
a7(a,b){return new A.ac(this.a,this.$ti.h("@<1>").v(b).h("ac<1,2>"))},
gS(){return this.a}}
A.bk.prototype={
n(a){return"LateInitializationError: "+this.a}}
A.dw.prototype={}
A.k.prototype={}
A.C.prototype={
gq(a){var t=this
return new A.aD(t,t.gj(t),A.r(t).h("aD<C.E>"))},
gu(a){return this.gj(this)===0},
G(a,b){var t,s,r=this
A.r(r).h("i(C.E)").a(b)
t=r.gj(r)
for(s=0;s<t;++s){if(b.$1(r.C(0,s)))return!0
if(t!==r.gj(r))throw A.d(A.P(r))}return!1},
a_(a,b,c){var t=A.r(this)
return new A.H(this,t.v(c).h("1(C.E)").a(b),t.h("@<C.E>").v(c).h("H<1,2>"))},
V(a,b){var t,s,r,q=this
A.r(q).h("C.E(C.E,C.E)").a(b)
t=q.gj(q)
if(t===0)throw A.d(A.aR())
s=q.C(0,0)
for(r=1;r<t;++r){s=b.$2(s,q.C(0,r))
if(t!==q.gj(q))throw A.d(A.P(q))}return s}}
A.bv.prototype={
bh(a,b,c,d){var t,s=this.b
A.dv(s,"start")
t=this.c
if(t!=null){A.dv(t,"end")
if(s>t)throw A.d(A.aE(s,0,t,"start",null))}},
gbm(){var t=J.Y(this.a),s=this.c
if(s==null||s>t)return t
return s},
gbv(){var t=J.Y(this.a),s=this.b
if(s>t)return t
return s},
gj(a){var t,s=J.Y(this.a),r=this.b
if(r>=s)return 0
t=this.c
if(t==null||t>=s)return s-r
return t-r},
C(a,b){var t=this,s=t.gbv()+b
if(b<0||s>=t.gbm())throw A.d(A.dj(b,t.gj(0),t,"index"))
return J.ek(t.a,s)}}
A.aD.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t,s=this,r=s.a,q=J.a8(r),p=q.gj(r)
if(s.b!==p)throw A.d(A.P(r))
t=s.c
if(t>=p){s.d=null
return!1}s.d=q.C(r,t);++s.c
return!0},
$iB:1}
A.a6.prototype={
gq(a){var t=this.a
return new A.bm(t.gq(t),this.b,A.r(this).h("bm<1,2>"))},
gj(a){var t=this.a
return t.gj(t)},
gu(a){var t=this.a
return t.gu(t)},
C(a,b){var t=this.a
return this.b.$1(t.C(t,b))}}
A.ba.prototype={$ik:1}
A.bm.prototype={
k(){var t=this,s=t.b
if(s.k()){t.a=t.c.$1(s.gm())
return!0}t.a=null
return!1},
gm(){var t=this.a
return t==null?this.$ti.y[1].a(t):t},
$iB:1}
A.H.prototype={
gj(a){return J.Y(this.a)},
C(a,b){return this.b.$1(J.ek(this.a,b))}}
A.t.prototype={
gq(a){return new A.aj(J.M(this.a),this.b,this.$ti.h("aj<1>"))}}
A.aj.prototype={
k(){var t,s
for(t=this.a,s=this.b;t.k();)if(s.$1(t.gm()))return!0
return!1},
gm(){return this.a.gm()},
$iB:1}
A.Q.prototype={
gq(a){return new A.bc(J.M(this.a),this.b,B.G,this.$ti.h("bc<1,2>"))}}
A.bc.prototype={
gm(){var t=this.d
return t==null?this.$ti.y[1].a(t):t},
k(){var t,s,r=this,q=r.c
if(q==null)return!1
for(t=r.a,s=r.b;!q.k();){r.d=null
if(t.k()){r.c=null
q=J.M(s.$1(t.gm()))
r.c=q}else return!1}r.d=r.c.gm()
return!0},
$iB:1}
A.bb.prototype={
k(){return!1},
gm(){throw A.d(A.aR())},
$iB:1}
A.ak.prototype={
gq(a){return new A.by(J.M(this.a),this.$ti.h("by<1>"))}}
A.by.prototype={
k(){var t,s
for(t=this.a,s=this.$ti.c;t.k();)if(s.b(t.gm()))return!0
return!1},
gm(){return this.$ti.c.a(this.a.gm())},
$iB:1}
A.R.prototype={}
A.bM.prototype={}
A.a1.prototype={$r:"+(1,2)",$s:1}
A.av.prototype={$r:"+(1,2,3)",$s:2}
A.b7.prototype={
gu(a){return this.gj(this)===0},
n(a){return A.et(this)},
ga8(){return new A.b0(this.bJ(),A.r(this).h("b0<U<1,2>>"))},
bJ(){var t=this
return function(){var s=0,r=1,q=[],p,o,n,m,l
return function $async$ga8(a,b,c){if(b===1){q.push(c)
s=r}for(;;)switch(s){case 0:p=t.gK(),p=p.gq(p),o=A.r(t),n=o.y[1],o=o.h("U<1,2>")
case 2:if(!p.k()){s=3
break}m=p.gm()
l=t.i(0,m)
s=4
return a.b=new A.U(m,l==null?n.a(l):l,o),1
case 4:s=2
break
case 3:return 0
case 1:return a.c=q.at(-1),3}}}},
$iT:1}
A.b9.prototype={
gj(a){return this.b.length},
gaS(){var t=this.$keys
if(t==null){t=Object.keys(this.a)
this.$keys=t}return t},
I(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
i(a,b){if(!this.I(b))return null
return this.b[this.a[b]]},
P(a,b){var t,s,r,q
this.$ti.h("~(1,2)").a(b)
t=this.gaS()
s=this.b
for(r=t.length,q=0;q<r;++q)b.$2(t[q],s[q])},
gK(){return new A.bB(this.gaS(),this.$ti.h("bB<1>"))}}
A.bB.prototype={
gj(a){return this.a.length},
gu(a){return 0===this.a.length},
gN(a){return 0!==this.a.length},
gq(a){var t=this.a
return new A.aG(t,t.length,this.$ti.h("aG<1>"))}}
A.aG.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t=this,s=t.c
if(s>=t.b){t.d=null
return!1}t.d=t.a[s]
t.c=s+1
return!0},
$iB:1}
A.b8.prototype={}
A.aQ.prototype={
gj(a){return this.b},
gu(a){return this.b===0},
gN(a){return this.b!==0},
gq(a){var t,s=this,r=s.$keys
if(r==null){r=Object.keys(s.a)
s.$keys=r}t=r
return new A.aG(t,t.length,s.$ti.h("aG<1>"))},
D(a,b){if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)}}
A.bZ.prototype={
O(a,b){if(b==null)return!1
return b instanceof A.ab&&this.a.O(0,b.a)&&A.eJ(this)===A.eJ(b)},
gB(a){return A.ev(this.a,A.eJ(this),B.m,B.m)},
n(a){var t=B.a.aC([A.an(this.$ti.c)],", ")
return this.a.n(0)+" with "+("<"+t+">")}}
A.ab.prototype={
$2(a,b){return this.a.$1$2(a,b,this.$ti.y[0])},
$S(){return A.iZ(A.dU(this.a),this.$ti)}}
A.bt.prototype={}
A.dx.prototype={
L(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
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
A.bs.prototype={
n(a){return"Null check operator used on a null value"}}
A.c3.prototype={
n(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.cm.prototype={
n(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.du.prototype={
n(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.O.prototype={
n(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.fQ(s==null?"unknown":s)+"'"},
$iae:1,
gcb(){return this},
$C:"$1",
$R:1,
$D:null}
A.bS.prototype={$C:"$0",$R:0}
A.bT.prototype={$C:"$2",$R:2}
A.ck.prototype={}
A.cj.prototype={
n(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.fQ(t)+"'"}}
A.aP.prototype={
O(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.aP))return!1
return this.$_target===b.$_target&&this.a===b.a},
gB(a){return(A.fN(this.a)^A.cg(this.$_target))>>>0},
n(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.ch(this.a)+"'")}}
A.ci.prototype={
n(a){return"RuntimeError: "+this.a}}
A.af.prototype={
gj(a){return this.a},
gu(a){return this.a===0},
gK(){return new A.aC(this,A.r(this).h("aC<1>"))},
ga8(){return new A.ag(this,A.r(this).h("ag<1,2>"))},
I(a){var t,s
if(typeof a=="string"){t=this.b
if(t==null)return!1
return t[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){s=this.c
if(s==null)return!1
return s[a]!=null}else return this.bM(a)},
bM(a){var t=this.d
if(t==null)return!1
return this.ac(t[this.ab(a)],a)>=0},
Y(a,b){A.r(this).h("T<1,2>").a(b).P(0,new A.dl(this))},
i(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.bN(b)},
bN(a){var t,s,r=this.d
if(r==null)return null
t=r[this.ab(a)]
s=this.ac(t,a)
if(s<0)return null
return t[s].b},
l(a,b,c){var t,s,r=this,q=A.r(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.aN(t==null?r.b=r.an():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.aN(s==null?r.c=r.an():s,b,c)}else r.bP(b,c)},
bP(a,b){var t,s,r,q,p=this,o=A.r(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.an()
s=p.ab(a)
r=t[s]
if(r==null)t[s]=[p.ao(a,b)]
else{q=p.ac(r,a)
if(q>=0)r[q].b=b
else r.push(p.ao(a,b))}},
bY(a,b){var t,s,r=this,q=A.r(r)
q.c.a(a)
q.h("2()").a(b)
if(r.I(a)){t=r.i(0,a)
return t==null?q.y[1].a(t):t}s=b.$0()
r.l(0,a,s)
return s},
a1(a,b){var t=this
if(typeof b=="string")return t.aU(t.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return t.aU(t.c,b)
else return t.bO(b)},
bO(a){var t,s,r,q,p=this,o=p.d
if(o==null)return null
t=p.ab(a)
s=o[t]
r=p.ac(s,a)
if(r<0)return null
q=s.splice(r,1)[0]
p.b_(q)
if(s.length===0)delete o[t]
return q.b},
ar(a){var t=this
if(t.a>0){t.b=t.c=t.d=t.e=t.f=null
t.a=0
t.am()}},
P(a,b){var t,s,r=this
A.r(r).h("~(1,2)").a(b)
t=r.e
s=r.r
while(t!=null){b.$2(t.a,t.b)
if(s!==r.r)throw A.d(A.P(r))
t=t.c}},
aN(a,b,c){var t,s=A.r(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.ao(b,c)
else t.b=c},
aU(a,b){var t
if(a==null)return null
t=a[b]
if(t==null)return null
this.b_(t)
delete a[b]
return t.b},
am(){this.r=this.r+1&1073741823},
ao(a,b){var t=this,s=A.r(t),r=new A.dq(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else{s=t.f
s.toString
r.d=s
t.f=s.c=r}++t.a
t.am()
return r},
b_(a){var t=this,s=a.d,r=a.c
if(s==null)t.e=r
else s.c=r
if(r==null)t.f=s
else r.d=s;--t.a
t.am()},
ab(a){return J.X(a)&1073741823},
ac(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.E(a[s].a,b))return s
return-1},
n(a){return A.et(this)},
an(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$if3:1}
A.dl.prototype={
$2(a,b){var t=this.a,s=A.r(t)
t.l(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.r(this.a).h("~(1,2)")}}
A.dq.prototype={}
A.aC.prototype={
gj(a){return this.a.a},
gu(a){return this.a.a===0},
gq(a){var t=this.a
return new A.aB(t,t.r,t.e,this.$ti.h("aB<1>"))}}
A.aB.prototype={
gm(){return this.d},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.d(A.P(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.a
s.c=t.c
return!0}},
$iB:1}
A.ag.prototype={
gj(a){return this.a.a},
gu(a){return this.a.a===0},
gq(a){var t=this.a
return new A.bl(t,t.r,t.e,this.$ti.h("bl<1,2>"))}}
A.bl.prototype={
gm(){var t=this.d
t.toString
return t},
k(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.d(A.P(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=new A.U(t.a,t.b,s.$ti.h("U<1,2>"))
s.c=t.c
return!0}},
$iB:1}
A.e8.prototype={
$1(a){return this.a(a)},
$S:12}
A.e9.prototype={
$2(a,b){return this.a(a,b)},
$S:20}
A.ea.prototype={
$1(a){return this.a(A.I(a))},
$S:27}
A.al.prototype={
n(a){return this.aZ(!1)},
aZ(a){var t,s,r,q,p,o=this.bo(),n=this.al(),m=(a?"Record ":"")+"("
for(t=o.length,s="",r=0;r<t;++r,s=", "){m+=s
q=o[r]
if(typeof q=="string")m=m+q+": "
if(!(r<n.length))return A.f(n,r)
p=n[r]
m=a?m+A.f8(p):m+A.z(p)}m+=")"
return m.charCodeAt(0)==0?m:m},
bo(){var t,s=this.$s
while($.dE.length<=s)B.a.p($.dE,null)
t=$.dE[s]
if(t==null){t=this.bk()
B.a.l($.dE,s,t)}return t},
bk(){var t,s,r,q=this.$r,p=q.indexOf("("),o=q.substring(1,p),n=q.substring(p),m=n==="()"?0:n.replace(/[^,]/g,"").length+1,l=u.K,k=J.aS(m,l)
for(t=0;t<m;++t)k[t]=t
if(o!==""){s=o.split(",")
t=s.length
for(r=m;t>0;){--r;--t
B.a.l(k,r,s[t])}}k=A.hA(k,!1,l)
k.$flags=3
return k}}
A.aZ.prototype={
al(){return[this.a,this.b]},
O(a,b){if(b==null)return!1
return b instanceof A.aZ&&this.$s===b.$s&&J.E(this.a,b.a)&&J.E(this.b,b.b)},
gB(a){return A.ev(this.$s,this.a,this.b,B.m)}}
A.b_.prototype={
al(){return[this.a,this.b,this.c]},
O(a,b){var t=this
if(b==null)return!1
return b instanceof A.b_&&t.$s===b.$s&&J.E(t.a,b.a)&&J.E(t.b,b.b)&&J.E(t.c,b.c)},
gB(a){var t=this
return A.ev(t.$s,t.a,t.b,t.c)}}
A.aU.prototype={
gA(a){return B.aH},
$iv:1}
A.bp.prototype={}
A.c6.prototype={
gA(a){return B.aI},
$iv:1}
A.aV.prototype={
gj(a){return a.length},
$ia_:1}
A.bn.prototype={
i(a,b){A.am(b,a,a.length)
return a[b]},
l(a,b,c){A.ft(c)
a.$flags&2&&A.a5(a)
A.am(b,a,a.length)
a[b]=c},
$ik:1,
$ib:1,
$ic:1}
A.bo.prototype={
l(a,b,c){A.h(c)
a.$flags&2&&A.a5(a)
A.am(b,a,a.length)
a[b]=c},
$ik:1,
$ib:1,
$ic:1}
A.c7.prototype={
gA(a){return B.aJ},
$iv:1}
A.c8.prototype={
gA(a){return B.aK},
$iv:1}
A.c9.prototype={
gA(a){return B.aL},
i(a,b){A.am(b,a,a.length)
return a[b]},
$iv:1}
A.ca.prototype={
gA(a){return B.aM},
i(a,b){A.am(b,a,a.length)
return a[b]},
$iv:1}
A.cb.prototype={
gA(a){return B.aN},
i(a,b){A.am(b,a,a.length)
return a[b]},
$iv:1}
A.cc.prototype={
gA(a){return B.aP},
i(a,b){A.am(b,a,a.length)
return a[b]},
$iv:1}
A.cd.prototype={
gA(a){return B.aQ},
i(a,b){A.am(b,a,a.length)
return a[b]},
$iv:1}
A.bq.prototype={
gA(a){return B.aR},
gj(a){return a.length},
i(a,b){A.am(b,a,a.length)
return a[b]},
$iv:1}
A.ce.prototype={
gA(a){return B.aS},
gj(a){return a.length},
i(a,b){A.am(b,a,a.length)
return a[b]},
$iv:1,
$ieA:1}
A.bC.prototype={}
A.bD.prototype={}
A.bE.prototype={}
A.bF.prototype={}
A.a7.prototype={
h(a){return A.bL(v.typeUniverse,this,a)},
v(a){return A.fp(v.typeUniverse,this,a)}}
A.co.prototype={}
A.dI.prototype={
n(a){return A.V(this.a,null)}}
A.cn.prototype={
n(a){return this.a}}
A.b1.prototype={}
A.bH.prototype={
gm(){var t=this.b
return t==null?this.$ti.c.a(t):t},
bs(a,b){var t,s,r
a=A.h(a)
b=b
t=this.a
for(;;)try{s=t(this,a,b)
return s}catch(r){b=r
a=1}},
k(){var t,s,r,q,p=this,o=null,n=0
for(;;){t=p.d
if(t!=null)try{if(t.k()){p.b=t.gm()
return!0}else p.d=null}catch(s){o=s
n=1
p.d=null}r=p.bs(n,o)
if(1===r)return!0
if(0===r){p.b=null
q=p.e
if(q==null||q.length===0){p.a=A.fk
return!1}if(0>=q.length)return A.f(q,-1)
p.a=q.pop()
n=0
o=null
continue}if(2===r){n=0
o=null
continue}if(3===r){o=p.c
p.c=null
q=p.e
if(q==null||q.length===0){p.b=null
p.a=A.fk
throw o
return!1}if(0>=q.length)return A.f(q,-1)
p.a=q.pop()
n=1
continue}throw A.d(A.ey("sync*"))}return!1},
cd(a){var t,s,r=this
if(a instanceof A.b0){t=a.a()
s=r.e
if(s==null)s=r.e=[]
B.a.p(s,r.a)
r.a=t
return 2}else{r.d=J.M(a)
return 2}},
$iB:1}
A.b0.prototype={
gq(a){return new A.bH(this.a(),this.$ti.h("bH<1>"))}}
A.aH.prototype={
gq(a){var t=this,s=new A.aI(t,t.r,t.$ti.h("aI<1>"))
s.c=t.e
return s},
gj(a){return this.a},
gu(a){return this.a===0},
gN(a){return this.a!==0},
D(a,b){var t,s
if(typeof b=="string"&&b!=="__proto__"){t=this.b
if(t==null)return!1
return u.M.a(t[b])!=null}else if(typeof b=="number"&&(b&1073741823)===b){s=this.c
if(s==null)return!1
return u.M.a(s[b])!=null}else return this.bl(b)},
bl(a){var t=this.d
if(t==null)return!1
return this.aQ(t[J.X(a)&1073741823],a)>=0},
p(a,b){var t,s,r=this
r.$ti.c.a(b)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
return r.aO(t==null?r.b=A.eB():t,b)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
return r.aO(s==null?r.c=A.eB():s,b)}else return r.bi(b)},
bi(a){var t,s,r,q=this
q.$ti.c.a(a)
t=q.d
if(t==null)t=q.d=A.eB()
s=J.X(a)&1073741823
r=t[s]
if(r==null)t[s]=[q.ai(a)]
else{if(q.aQ(r,a)>=0)return!1
r.push(q.ai(a))}return!0},
aO(a,b){this.$ti.c.a(b)
if(u.M.a(a[b])!=null)return!1
a[b]=this.ai(b)
return!0},
ai(a){var t=this,s=new A.cs(t.$ti.c.a(a))
if(t.e==null)t.e=t.f=s
else t.f=t.f.b=s;++t.a
t.r=t.r+1&1073741823
return s},
aQ(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.E(a[s].a,b))return s
return-1},
$if4:1}
A.cs.prototype={}
A.aI.prototype={
gm(){var t=this.d
return t==null?this.$ti.c.a(t):t},
k(){var t=this,s=t.c,r=t.a
if(t.b!==r.r)throw A.d(A.P(r))
else if(s==null){t.d=null
return!1}else{t.d=t.$ti.h("1?").a(s.a)
t.c=s.b
return!0}},
$iB:1}
A.dr.prototype={
$2(a,b){this.a.l(0,this.b.a(a),this.c.a(b))},
$S:28}
A.q.prototype={
gq(a){return new A.aD(a,this.gj(a),A.a9(a).h("aD<q.E>"))},
C(a,b){return this.i(a,b)},
gu(a){return this.gj(a)===0},
gN(a){return!this.gu(a)},
E(a,b){var t,s
A.a9(a).h("i(q.E)").a(b)
t=this.gj(a)
for(s=0;s<t;++s){if(!b.$1(this.i(a,s)))return!1
if(t!==this.gj(a))throw A.d(A.P(a))}return!0},
G(a,b){var t,s
A.a9(a).h("i(q.E)").a(b)
t=this.gj(a)
for(s=0;s<t;++s){if(b.$1(this.i(a,s)))return!0
if(t!==this.gj(a))throw A.d(A.P(a))}return!1},
aH(a,b){return new A.ak(a,b.h("ak<0>"))},
a_(a,b,c){var t=A.a9(a)
return new A.H(a,t.v(c).h("1(q.E)").a(b),t.h("@<q.E>").v(c).h("H<1,2>"))},
a7(a,b){return new A.ac(a,A.a9(a).h("@<q.E>").v(b).h("ac<1,2>"))},
n(a){return A.ep(a,"[","]")}}
A.x.prototype={
P(a,b){var t,s,r,q=A.r(this)
q.h("~(x.K,x.V)").a(b)
for(t=this.gK(),t=t.gq(t),q=q.h("x.V");t.k();){s=t.gm()
r=this.i(0,s)
b.$2(s,r==null?q.a(r):r)}},
ga8(){return this.gK().a_(0,new A.ds(this),A.r(this).h("U<x.K,x.V>"))},
c1(a,b){var t,s,r,q,p,o=this,n=A.r(o)
n.h("i(x.K,x.V)").a(b)
t=A.e([],n.h("p<x.K>"))
for(s=o.gK(),s=s.gq(s),n=n.h("x.V");s.k();){r=s.gm()
q=o.i(0,r)
if(b.$2(r,q==null?n.a(q):q))B.a.p(t,r)}for(n=t.length,p=0;p<t.length;t.length===n||(0,A.D)(t),++p)o.a1(0,t[p])},
gj(a){var t=this.gK()
return t.gj(t)},
gu(a){var t=this.gK()
return t.gu(t)},
n(a){return A.et(this)},
$iT:1}
A.ds.prototype={
$1(a){var t=this.a,s=A.r(t)
s.h("x.K").a(a)
t=t.i(0,a)
if(t==null)t=s.h("x.V").a(t)
return new A.U(a,t,s.h("U<x.K,x.V>"))},
$S(){return A.r(this.a).h("U<x.K,x.V>(x.K)")}}
A.dt.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.z(a)
s.a=(s.a+=t)+": "
t=A.z(b)
s.a+=t},
$S:8}
A.as.prototype={
gu(a){return this.gj(this)===0},
gN(a){return this.gj(this)!==0},
n(a){return A.ep(this,"{","}")},
C(a,b){var t,s
A.dv(b,"index")
t=this.gq(this)
for(s=b;t.k();){if(s===0)return t.gm();--s}throw A.d(A.dj(b,b-s,this,"index"))},
$ik:1,
$ib:1}
A.bG.prototype={}
A.cq.prototype={
i(a,b){var t,s=this.b
if(s==null)return this.c.i(0,b)
else if(typeof b!="string")return null
else{t=s[b]
return typeof t=="undefined"?this.bq(b):t}},
gj(a){return this.b==null?this.c.a:this.X().length},
gu(a){return this.gj(0)===0},
gK(){if(this.b==null){var t=this.c
return new A.aC(t,A.r(t).h("aC<1>"))}return new A.cr(this)},
I(a){if(this.b==null)return this.c.I(a)
if(typeof a!="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
a1(a,b){if(this.b!=null&&!this.I(b))return null
return this.bx().a1(0,b)},
P(a,b){var t,s,r,q,p=this
u.cQ.a(b)
if(p.b==null)return p.c.P(0,b)
t=p.X()
for(s=0;s<t.length;++s){r=t[s]
q=p.b[r]
if(typeof q=="undefined"){q=A.dQ(p.a[r])
p.b[r]=q}b.$2(r,q)
if(t!==p.c)throw A.d(A.P(p))}},
X(){var t=u.g.a(this.c)
if(t==null)t=this.c=A.e(Object.keys(this.a),u.s)
return t},
bx(){var t,s,r,q,p,o=this
if(o.b==null)return o.c
t=A.ah(u.N,u.z)
s=o.X()
for(r=0;q=s.length,r<q;++r){p=s[r]
t.l(0,p,o.i(0,p))}if(q===0)B.a.p(s,"")
else B.a.ar(s)
o.a=o.b=null
return o.c=t},
bq(a){var t
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
t=A.dQ(this.a[a])
return this.b[a]=t}}
A.cr.prototype={
gj(a){return this.a.gj(0)},
C(a,b){var t=this.a
if(t.b==null)t=t.gK().C(0,b)
else{t=t.X()
if(!(b>=0&&b<t.length))return A.f(t,b)
t=t[b]}return t},
gq(a){var t=this.a
if(t.b==null){t=t.gK()
t=t.gq(t)}else{t=t.X()
t=new J.ay(t,t.length,A.w(t).h("ay<1>"))}return t}}
A.bU.prototype={}
A.bW.prototype={}
A.bj.prototype={
n(a){var t=A.bX(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.c4.prototype={
n(a){return"Cyclic error in JSON stringify"}}
A.dm.prototype={
bF(a,b){var t=A.ix(a,this.gbG().a)
return t},
au(a,b){var t=A.hL(a,this.gbI().b,null)
return t},
gbI(){return B.S},
gbG(){return B.R}}
A.dp.prototype={}
A.dn.prototype={}
A.dC.prototype={
bb(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.n.a3(a,s,r)
s=r+1
p=A.N(92)
t.a+=p
p=A.N(117)
t.a+=p
p=A.N(100)
t.a+=p
p=q>>>8&15
p=A.N(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.N(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.N(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.n.a3(a,s,r)
s=r+1
p=A.N(92)
t.a+=p
switch(q){case 8:p=A.N(98)
t.a+=p
break
case 9:p=A.N(116)
t.a+=p
break
case 10:p=A.N(110)
t.a+=p
break
case 12:p=A.N(102)
t.a+=p
break
case 13:p=A.N(114)
t.a+=p
break
default:p=A.N(117)
t.a+=p
p=A.N(48)
t.a=(t.a+=p)+p
p=q>>>4&15
p=A.N(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.N(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.n.a3(a,s,r)
s=r+1
p=A.N(92)
t.a+=p
p=A.N(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.n.a3(a,s,n)},
ag(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.d(new A.c4(a,null))}B.a.p(t,a)},
ad(a){var t,s,r,q,p=this
if(p.ba(a))return
p.ag(a)
try{t=p.b.$1(a)
if(!p.ba(t)){r=A.f2(a,null,p.gaT())
throw A.d(r)}r=p.a
if(0>=r.length)return A.f(r,-1)
r.pop()}catch(q){s=A.eO(q)
r=A.f2(a,s,p.gaT())
throw A.d(r)}},
ba(a){var t,s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.c.a+=B.q.n(a)
return!0}else if(a===!0){r.c.a+="true"
return!0}else if(a===!1){r.c.a+="false"
return!0}else if(a==null){r.c.a+="null"
return!0}else if(typeof a=="string"){t=r.c
t.a+='"'
r.bb(a)
t.a+='"'
return!0}else if(u.j.b(a)){r.ag(a)
r.c9(a)
t=r.a
if(0>=t.length)return A.f(t,-1)
t.pop()
return!0}else if(u.f.b(a)){r.ag(a)
s=r.ca(a)
t=r.a
if(0>=t.length)return A.f(t,-1)
t.pop()
return s}else return!1},
c9(a){var t,s,r=this.c
r.a+="["
t=J.a4(a)
if(t.gN(a)){this.ad(t.i(a,0))
for(s=1;s<t.gj(a);++s){r.a+=","
this.ad(t.i(a,s))}}r.a+="]"},
ca(a){var t,s,r,q,p,o,n=this,m={}
if(a.gu(a)){n.c.a+="{}"
return!0}t=a.gj(a)*2
s=A.c5(t,null,!1,u.O)
r=m.a=0
m.b=!0
a.P(0,new A.dD(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.bb(A.I(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.f(s,o)
n.ad(s[o])}q.a+="}"
return!0}}
A.dD.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.a.l(t,s.a++,a)
B.a.l(t,s.a++,b)},
$S:8}
A.dB.prototype={
gaT(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.A.prototype={}
A.bO.prototype={
n(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.bX(t)
return"Assertion failed"}}
A.bw.prototype={}
A.ap.prototype={
gak(){return"Invalid argument"+(!this.a?"(s)":"")},
gaj(){return""},
n(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.gak()+r+p
if(!t.a)return o
return o+t.gaj()+": "+A.bX(t.gaA())},
gaA(){return this.b}}
A.aW.prototype={
gaA(){return A.fu(this.b)},
gak(){return"RangeError"},
gaj(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.z(r):""
else if(r==null)t=": Not greater than or equal to "+A.z(s)
else if(r>s)t=": Not in inclusive range "+A.z(s)+".."+A.z(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.z(s)
return t}}
A.bY.prototype={
gaA(){return A.h(this.b)},
gak(){return"RangeError"},
gaj(){if(A.h(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gj(a){return this.f}}
A.bx.prototype={
n(a){return"Unsupported operation: "+this.a}}
A.cl.prototype={
n(a){return"UnimplementedError: "+this.a}}
A.aF.prototype={
n(a){return"Bad state: "+this.a}}
A.bV.prototype={
n(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bX(t)+"."}}
A.bu.prototype={
n(a){return"Stack Overflow"},
$iA:1}
A.dz.prototype={
n(a){return"Exception: "+this.a}}
A.bd.prototype={
n(a){var t=this.a,s=""!==t?"FormatException: "+t:"FormatException"
return s}}
A.b.prototype={
a7(a,b){return A.hh(this,A.r(this).h("b.E"),b)},
a_(a,b,c){var t=A.r(this)
return A.eu(this,t.v(c).h("1(b.E)").a(b),t.h("b.E"),c)},
c8(a,b){var t=A.r(this)
return new A.t(this,t.h("i(b.E)").a(b),t.h("t<b.E>"))},
aH(a,b){return new A.ak(this,b.h("ak<0>"))},
V(a,b){var t,s
A.r(this).h("b.E(b.E,b.E)").a(b)
t=this.gq(this)
if(!t.k())throw A.d(A.aR())
s=t.gm()
while(t.k())s=b.$2(s,t.gm())
return s},
E(a,b){var t
A.r(this).h("i(b.E)").a(b)
for(t=this.gq(this);t.k();)if(!b.$1(t.gm()))return!1
return!0},
aC(a,b){var t,s,r=this.gq(this)
if(!r.k())return""
t=J.ao(r.gm())
if(!r.k())return t
if(b.length===0){s=t
do s+=J.ao(r.gm())
while(r.k())}else{s=t
do s=s+b+J.ao(r.gm())
while(r.k())}return s.charCodeAt(0)==0?s:s},
b3(a){return this.aC(0,"")},
G(a,b){var t
A.r(this).h("i(b.E)").a(b)
for(t=this.gq(this);t.k();)if(b.$1(t.gm()))return!0
return!1},
gj(a){var t,s=this.gq(this)
for(t=0;s.k();)++t
return t},
gu(a){return!this.gq(this).k()},
gN(a){return!this.gu(this)},
C(a,b){var t,s
A.dv(b,"index")
t=this.gq(this)
for(s=b;t.k();){if(s===0)return t.gm();--s}throw A.d(A.dj(b,b-s,this,"index"))},
n(a){return A.ht(this,"(",")")}}
A.U.prototype={
n(a){return"MapEntry("+A.z(this.a)+": "+A.z(this.b)+")"}}
A.br.prototype={
gB(a){return A.y.prototype.gB.call(this,0)},
n(a){return"null"}}
A.y.prototype={$iy:1,
O(a,b){return this===b},
gB(a){return A.cg(this)},
n(a){return"Instance of '"+A.ch(this)+"'"},
gA(a){return A.iT(this)},
toString(){return this.n(this)}}
A.aX.prototype={
gj(a){return this.a.length},
n(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$ihG:1}
A.cp.prototype={
aF(a){if(a<=0||a>4294967296)throw A.d(A.hC("max must be in range 0 < max \u2264 2^32, was "+a))
return Math.random()*a>>>0},
aE(){return Math.random()},
$iew:1}
A.dT.prototype={
$1(a){var t,s=this.a,r=B.b.t(s.a*48271,2147483647)
s.a=r
t=B.b.t(r,33)
return new A.n(t,B.b.t(t,8))},
$S:25}
A.bR.prototype={
aF(a){var t=B.b.t(this.a*48271,2147483647)
this.a=t
return B.b.t(t,a)},
aE(){var t=B.b.t(this.a*48271,2147483647)
this.a=t
return(t-1)/2147483646},
$iew:1}
A.e4.prototype={
$2(a,b){var t,s,r,q,p,o,n=u.W
n.a(a)
n.a(b)
n=a.c
t=A.w(n)
s=t.h("Q<1,a?>")
r=new A.t(new A.Q(n,t.h("b<a?>(1)").a(new A.dX()),s),s.h("i(b.E)").a(new A.dY()),s.h("t<b.E>")).gj(0)
s=b.c
t=A.w(s)
n=t.h("Q<1,a?>")
q=new A.t(new A.Q(s,t.h("b<a?>(1)").a(new A.dZ()),n),n.h("i(b.E)").a(new A.e_()),n.h("t<b.E>")).gj(0)
if(r!==q)return B.b.H(q,r)
n=a.c
t=A.w(n)
s=t.h("Q<1,a?>")
p=u.N
s=A.eu(new A.Q(n,t.h("b<a?>(1)").a(new A.e0()),s),s.h("o(b.E)").a(new A.e1()),s.h("b.E"),p).b3(0)
t=b.c
n=A.w(t)
o=n.h("Q<1,a?>")
return B.n.H(s,A.eu(new A.Q(t,n.h("b<a?>(1)").a(new A.e2()),o),o.h("o(b.E)").a(new A.e3()),o.h("b.E"),p).b3(0))},
$S:38}
A.dX.prototype={
$1(a){return u.R.a(a)},
$S:1}
A.dY.prototype={
$1(a){return A.u(a)!=null},
$S:2}
A.dZ.prototype={
$1(a){return u.R.a(a)},
$S:1}
A.e_.prototype={
$1(a){return A.u(a)!=null},
$S:2}
A.e0.prototype={
$1(a){return u.R.a(a)},
$S:1}
A.e1.prototype={
$1(a){return A.u(a)==null?"0":"1"},
$S:10}
A.e2.prototype={
$1(a){return u.R.a(a)},
$S:1}
A.e3.prototype={
$1(a){return A.u(a)==null?"0":"1"},
$S:10}
A.e5.prototype={
$1(a){var t=u.A.a(a).a
if(!(t>=0&&t<39))return A.f(B.d,t)
return B.d[t].length===1},
$S:3}
A.e6.prototype={
$1(a){u.i.a(a)
return a.b5()-a.gav()*8},
$S:11}
A.e7.prototype={
$1(a){return u.A.a(a).a===this.a},
$S:3}
A.dR.prototype={
$1(a){return u.i.a(a).Z(this.a)==null},
$S:29}
A.dM.prototype={
$1(a){return u.i.a(a).gav()},
$S:11}
A.dN.prototype={
$1(a){var t=u.A.a(a).a
if(!(t>=0&&t<39))return A.f(B.d,t)
return B.d[t].length>=5},
$S:3}
A.dO.prototype={
$1(a){return u.A.a(a).a===this.a},
$S:3}
A.dP.prototype={
$2(a,b){return A.dL(a)+u.cX.a(b).c},
$S:19}
A.dS.prototype={
$2(a,b){var t,s=u.A
s.a(a)
s=s.a(b).a
if(!(s>=0&&s<39))return A.f(B.d,s)
s=B.d[s]
t=a.a
if(!(t>=0&&t<39))return A.f(B.d,t)
return B.b.H(s.length,B.d[t].length)},
$S:22}
A.a2.prototype={
gav(){var t=this.a,s=A.a9(t)
return new A.t(t,s.h("i(q.E)").a(new A.dF()),s.h("t<q.E>")).gj(0)/t.length},
b5(){var t,s,r,q,p,o,n,m,l,k
for(t=$.bN(),s=t.length,r=this.b,q=0,p=0;p<t.length;t.length===s||(0,A.D)(t),++p){o=t[p]
if(!(o<39))return A.f(B.d,o)
n=B.d[o]
A:for(m=0;m<r;++m)for(l=0;l<r;++l)if(this.a9(n,m,l)){k=q+1
q=k
break A}}return q},
a9(a,b,c){var t,s,r,q,p,o,n,m,l
u.ao.a(a)
for(t=a.length,s=this.b,r=this.a,q=r.length,p=0;p<t;++p){o=a[p]
n=b+o[0]
m=c+o[1]
l=!0
if(n<s)if(m<s){l=n*s+m
if(!(l>=0&&l<q))return A.f(r,l)
l=r[l]!==0}if(l)return!1}return!0},
Z(a8){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7
if(!(a8>=0&&a8<39))return A.f(B.d,a8)
t=B.d[a8]
for(s=this.b,r=t.length,q=this.a,p=q.$flags|0,o=q.length,n=null,m=-1,l=0,k=0;k<s;++k)for(j=k*s,i=0;i<s;++i){if(!this.a9(t,k,i))continue;++l
for(h=0;h<r;++h){g=t[h]
f=(k+g[0])*s+i+g[1]
p&2&&A.a5(q)
if(!(f>=0&&f<o))return A.f(q,f)
q[f]=2}for(e=0,d=0;d<s;++d){for(f=d*s,c=!0,b=!0,a=0;a<s;++a){a0=f+a
if(!(a0>=0&&a0<o))return A.f(q,a0)
if(q[a0]===0)c=!1
a0=a*s+d
if(!(a0>=0&&a0<o))return A.f(q,a0)
if(q[a0]===0)b=!1}if(c)++e
if(b)++e}for(a1=0,h=0;h<r;++h){g=t[h]
a2=k+g[0]
a3=i+g[1]
for(a4=0;a4<4;++a4){f=B.ak[a4]
a5=a2+f.a
a6=a3+f.b
f=!0
if(a5>=0)if(a5<s)if(a6>=0)if(a6<s){f=a5*s+a6
if(!(f>=0&&f<o))return A.f(q,f)
f=q[f]===1}if(f)++a1}}for(h=0;h<r;++h){g=t[h]
f=(k+g[0])*s+i+g[1]
p&2&&A.a5(q)
if(!(f>=0&&f<o))return A.f(q,f)
q[f]=0}a7=e*1000+a1
if(a7>m){n=new A.a1(j+i,e)
m=a7}}return n==null?null:new A.av(n.a,n.b,l)},
aG(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h=this.b,g=B.b.aM(b,h),f=B.b.t(b,h)
if(!(a>=0&&a<39))return A.f(B.d,a)
t=B.d[a]
s=t.length
r=this.a
q=r.$flags|0
p=0
for(;p<s;++p){o=t[p]
n=(g+o[0])*h+f+o[1]
q&2&&A.a5(r)
if(!(n>=0&&n<r.length))return A.f(r,n)
r[n]=1}m=A.f5(u.p)
for(t=r.length,s=u.t,l=0;l<h;++l){k=A.e(new Array(h),s)
for(n=l*h,j=0;j<h;++j){i=n+j
if(!(i>=0&&i<t))return A.f(r,i)
k[j]=r[i]}if(B.a.E(k,new A.dG()))for(j=0;j<h;++j)m.p(0,n+j)
k=A.e(new Array(h),s)
for(j=0;j<h;++j){n=j*h+l
if(!(n>=0&&n<t))return A.f(r,n)
k[j]=r[n]}if(B.a.E(k,new A.dH()))for(j=0;j<h;++j)m.p(0,j*h+l)}for(h=A.hM(m,m.r,m.$ti.c),s=h.$ti.c;h.k();){n=h.d
if(n==null)n=s.a(n)
q&2&&A.a5(r)
if(n>>>0!==n||n>=t)return A.f(r,n)
r[n]=0}}}
A.dF.prototype={
$1(a){return A.h(a)!==0},
$S:4}
A.dG.prototype={
$1(a){return A.h(a)!==0},
$S:4}
A.dH.prototype={
$1(a){return A.h(a)!==0},
$S:4}
A.F.prototype={
aa(a){return B.a.D(this.CW,a)&&!B.a.D(this.cx,a)},
gU(){var t=this.db
if(t==null)t=this.dx!=null?this.dy:null
return t},
bp(){var t=this.c
if(t==null)t=new A.cW(this)
return t.$1(this.f++)},
W(){var t=this,s=t.e
s===$&&A.W()
return A.m(["id",t.a,"name",t.d,"game",s.W(),"nextSet",t.f,"lives",t.r,"boardOuts",t.w,"thresholds",t.x,"damage",t.y,"lastMove",t.z,"ready",t.Q,"connected",t.as,"rematch",t.at,"disconnectAt",t.ax,"out",t.ay,"place",t.ch,"jokers",t.CW,"usedJokers",t.cx,"frozenUntil",t.cy,"stuckAt",t.db,"stuckLeft",t.dx,"aimUntil",t.dy,"expandUntil",t.fr,"expandCorner",t.fx,"reflectUntil",t.fy,"reflected",t.go,"saltUntil",t.id],u.N,u.z)},
saJ(a){this.c=u.b8.a(a)},
saD(a){this.CW=u.l.a(a)},
sb9(a){this.cx=u.l.a(a)}}
A.cW.prototype={
$1(a){return A.fE(this.a.b,a)},
$S:14}
A.dW.prototype={
$1(a){return A.h(a)!==this.a},
$S:4}
A.bQ.prototype={
ga6(){var t=B.r.i(0,this.e)
return t==null?2:t},
gF(){var t=this.d,s=A.w(t)
return new A.t(t,s.h("i(1)").a(new A.cJ()),s.h("t<1>"))},
bt(a){var t,s,r,q,p=this
if(p.r===1)return A.fE(p.b,a)
t=p.x
s=t.bY(a,new A.cB(p,a))
if(p.d.length===p.ga6()&&!p.gF().gu(0)){r=p.gF()
q=r.$ti
t.c1(0,new A.cC(new A.a6(r,q.h("a(1)").a(new A.cD()),q.h("a6<1,a>")).V(0,B.D)))}t=A.S(s,u.k)
return t},
M(a){return B.a.bL(this.d,new A.cP(a))},
bQ(a,b,c,d){var t,s,r=this,q=r.d
if(B.a.G(q,new A.cK(b)))return
t=r.f
if(t.length!==0&&!B.a.D(t,b))throw A.d(A.ey("Bu oda ba\u015fka bir oyuncu i\xe7in kuruldu."))
if(r.at!=="waiting"||q.length>=r.ga6())throw A.d(A.ey("Oda dolu veya ma\xe7 ba\u015flam\u0131\u015f."))
s=A.h9(b,c,r.b,!1)
s.saJ(r.gaV())
s.e=A.cX(s.gap(),null)
B.a.p(q,s)
s.e.a0();++r.ax},
bH(a,b){var t,s,r,q,p,o=this
o.J(b)
t=o.M(a)
s=t.at=t.as=!1
r=o.at
if(r==="finished"){++o.ax
return}if(r==="playing"?!t.ay:s)t.ax=b+15e3
else t.ax=null
if(r==="countdown"||r==="draft"){o.at="waiting"
o.z=o.ay=null
for(s=o.d,r=s.length,q=u.s,p=0;p<s.length;s.length===r||(0,A.D)(s),++p)s[p].saD(A.e([],q))}++o.ax},
bZ(a,b){var t,s=this
s.J(b)
if(s.at!=="waiting")return
t=s.M(a)
if(!t.as)return
t.Q=!0;++s.ax
s.aP(b)},
aP(a){var t,s=this
if(s.at==="waiting"){t=s.d
t=t.length===s.ga6()&&B.a.E(t,new A.cy())}else t=!1
if(t){if(s.y&&s.e==="duel"){s.aX(a)
return}s.at="countdown"
s.ay=a+3000;++s.ax}},
aX(a){var t,s,r,q,p,o,n=this
n.at="draft"
n.ay=null
n.z=a+2e4
t=n.d
s=A.S(t,u.h)
B.a.T(s,new A.cE())
r=A.em(n.b,7919+n.w)
q=B.b.t(r.a*48271,2147483647)
r.a=q
q=B.b.t(q,2)
if(!(q<s.length))return A.f(s,q)
n.Q=s[q].a
for(s=t.length,r=u.s,p=0;p<t.length;t.length===s||(0,A.D)(t),++p){o=t[p]
o.saD(A.e([],r))
o.sb9(A.e([],r))}B.a.p(n.cy,A.m(["type","DRAFT","picker",n.Q],u.N,u.z));++n.ax},
ga5(){var t,s,r,q=A.e([],u.s)
for(t=this.d,s=0;s<4;++s){r=B.ai[s]
if(!B.a.G(t,new A.cz(r)))q.push(r)}return q},
ga2(){var t,s,r,q
if(this.at!=="draft")return null
t=this.d
s=A.w(t)
r=A.iM(this.Q,new A.H(t,s.h("a(1)").a(new A.cS()),s.h("H<1,a>")))
q=B.a.aw(t,0,new A.cT(),u.p)
t=r.length
if(q<t){if(!(q>=0))return A.f(r,q)
t=r[q]}else t=null
return t},
aR(a,b){B.a.p(this.M(a).CW,b)
B.a.p(this.cy,A.m(["type","JOKER_PICKED","player",a,"joker",b],u.N,u.z))},
bT(a,b,c){var t,s,r=this
r.cy=A.e([],u.X)
r.J(c)
if(r.at!=="draft")return A.m(["error","Joker se\xe7imi bitti."],u.N,u.z)
if(r.ga2()!==a)return A.m(["error","Se\xe7im s\u0131ras\u0131 sende de\u011fil."],u.N,u.z)
if(!B.a.D(r.ga5(),b))return A.m(["error","Bu joker al\u0131nm\u0131\u015f."],u.N,u.z)
r.aR(a,b)
t=r.ga2()
if(t!=null&&r.ga5().length===1)r.aR(t,B.a.gaL(r.ga5()))
if(r.ga2()==null){s=r.z
s.toString
r.z=Math.min(s,c+2500)}++r.ax
return A.m(["ok",!0],u.N,u.z)},
c7(a,b,c,d){var t,s,r,q,p,o,n,m=this,l="reflected"
m.cy=A.e([],u.X)
m.J(c)
if(m.at!=="playing")return A.m(["error","Ma\xe7 \u015fu anda oynanabilir de\u011fil."],u.N,u.z)
t=m.M(a)
if(t.ay)return A.m(["error","Bu ma\xe7ta elendin."],u.N,u.z)
if(!t.aa(b))return A.m(["error","Bu joker sende yok."],u.N,u.z)
if(!t.as||m.gF().G(0,new A.cU()))return A.m(["error","Ba\u011flant\u0131 bekleniyor."],u.N,u.z)
s=t.cy
if(s!=null&&c<s)return A.m(["error","Tahtan donuk."],u.N,u.z)
if(B.aG.D(0,b)){s=m.gF()
r=s.$ti
q=A.f0(new A.t(s,r.h("i(b.E)").a(new A.cV(a)),r.h("t<b.E>")),u.h)
if(q==null)return A.m(["error","Rakip yok."],u.N,u.z)
s=q.fy
p=s!=null&&c<s
if(p){q.go=!0
q.fy=null
q=t}s=u.N
r=u.z
o=q.a
if(b==="freeze"){q.cy=c+8000
n=m.cy
r=A.ah(s,r)
r.l(0,"type","FREEZE")
r.l(0,"player",o)
r.l(0,"by",a)
r.l(0,"until",q.cy)
if(p)r.l(0,l,!0)
B.a.p(n,r)}else{n=q.e
n===$&&A.W()
n.bW()
q.id=c+2e4
n=m.cy
r=A.ah(s,r)
r.l(0,"type","SALT")
r.l(0,"player",o)
r.l(0,"by",a)
r.l(0,"until",q.id)
if(p)r.l(0,l,!0)
B.a.p(n,r)
m.ah(q,c)}}else if(b==="reflect")t.fy=c+3e4
else{if(t.aa("expand")){s=t.e
s===$&&A.W()
s=s.c.length===8}else s=!1
r=!0
if(s)if(d!=null){s=t.e
s===$&&A.W()
s=!s.bK(0,d)}else s=r
else s=r
if(s)return A.m(["error","Tahta geni\u015fletilemez."],u.N,u.z)
t.fr=c+15e3
t.fx=d
B.a.p(m.cy,A.m(["type","EXPAND","player",a,"corner",d],u.N,u.z))
if(t.gU()!=null){t.dy=t.dx=t.db=null
s=t.e
s===$&&A.W()
if(!s.gaz())m.af(t,c)}}B.a.p(t.cx,b);++m.ax
return A.m(["ok",!0],u.N,u.z)},
by(a,b,c){var t,s,r=this
r.cy=A.e([],u.X)
r.J(c)
if(r.at!=="playing")return A.m(["ok",!0],u.N,u.z)
t=r.M(a)
if(!t.ay){if(t.aa("expand")){s=t.e
s===$&&A.W()
s=s.c.length===8}else s=!1
s=!s}else s=!0
if(s)return A.m(["ok",!0],u.N,u.z)
if(b&&t.db!=null){s=t.dy
if(c>=(s==null?t.dy=c+1e4:s))return A.m(["ok",!0],u.N,u.z)
s=t.db
s.toString
t.dx=s-c
t.db=null;++r.ax}else if(!b&&t.dx!=null){s=t.dx
s.toString
t.db=c+s
t.dx=null;++r.ax}return A.m(["ok",!0],u.N,u.z)},
ah(a,b){var t=!0
if(this.at!=="finished")if(!a.ay){t=a.e
t===$&&A.W()
t=t.gaz()||a.gU()!=null}if(t)return
if(a.aa("expand")){t=a.e
t===$&&A.W()
t=t.c.length===8}else t=!1
if(t){t=b+5000
a.db=t
B.a.p(this.cy,A.m(["type","STUCK","player",a.a,"until",t],u.N,u.z))}else this.af(a,b)},
bn(a){var t,s,r,q,p,o,n,m,l,k,j,i=this
for(t=u.N,s=u.z;i.at!=="finished";){for(r=i.gF(),q=J.M(r.a),r=new A.aj(q,r.b,r.$ti.h("aj<1>")),p=null,o=null;r.k();){n=q.gm()
for(m=[n.id,n.fr],l=0;l<2;++l){k=m[l]
j=!1
if(k!=null)if(k<=a)j=o==null||k<o
if(j){o=k
p=n}}}if(p==null)return
if(p.id==o){p.id=null
r=p.e
r===$&&A.W()
r.c0()
B.a.p(i.cy,A.m(["type","SALT_GONE","player",p.a],t,s))
r=p.db
if(r==null)r=p.dx!=null?p.dy:null
if(r!=null&&p.e.gaz())p.dy=p.dx=p.db=null}else{p.fr=null
r=p.e
r===$&&A.W()
q=p.fx
r.bd(q==null?"br":q)
p.fx=null
B.a.p(i.cy,A.m(["type","SHRINK","player",p.a],t,s))
o.toString
i.ah(p,o)}++i.ax}},
J(a){var t,s,r,q,p,o,n,m,l,k,j=this,i="countdown",h=j.at
if(h==="finished")return
if(h==="playing"){h=j.gF()
t=h.$ti
s=t.h("t<b.E>")
r=A.S(new A.t(h,t.h("i(b.E)").a(new A.cF(a)),s),s.h("b.E"))
B.a.T(r,new A.cG())
for(h=r.length,q=0;q<r.length;r.length===h||(0,A.D)(r),++q){p=r[q]
t=p.ax
t.toString
j.a4(p,"disconnect",t)}h=j.at
if(h==="finished")return}if(h==="waiting"&&a>=j.c+36e5){j.at="finished"
j.cx="expired"
j.ch=a;++j.ax
return}if(h==="draft"){t=j.z
t.toString
t=a>=t}else t=!1
if(t){o=A.em(j.b,104729+j.w)
for(n=j.ga2(),h=u.N,t=u.z;n!=null;n=j.ga2()){m=j.ga5()
s=m.length
l=B.b.t(o.a*48271,2147483647)
o.a=l
s=m[B.b.t(l,s)]
B.a.p(j.M(n).CW,s)
B.a.p(j.cy,A.m(["type","JOKER_PICKED","player",n,"joker",s],h,t))}j.at=i
h=j.z
h.toString
j.ay=h+3000;++j.ax
h=i}if(h==="countdown"){t=j.ay
t.toString
t=a>=t}else t=!1
if(t){h=j.at="playing";++j.ax}if(h==="playing"){j.bn(a)
h=j.gF()
t=h.$ti
s=t.h("t<b.E>")
k=A.S(new A.t(h,t.h("i(b.E)").a(new A.cH(a)),s),s.h("b.E"))
B.a.T(k,new A.cI())
for(h=k.length,q=0;q<k.length;k.length===h||(0,A.D)(k),++q){p=k[q]
if(j.at==="finished")break
t=p.db
if(t==null)t=p.dx!=null?p.dy:null
t.toString
p.dy=p.dx=p.db=null
j.af(p,t);++j.ax}}},
a4(a,b,c){var t,s,r,q,p=this
if(p.at==="finished"||a.ay)return
a.ch=p.gF().gj(0)
a.ay=!0
t=a.ax=null;++p.ax
s=p.gF()
r=A.S(s,s.$ti.h("b.E"))
s=r.length
if(s>1){B.a.p(p.cy,A.m(["type","ELIMINATED","player",a.a,"reason",b],u.N,u.z))
return}p.at="finished"
p.ch=c
p.cx=b
p.CW=s===0?t:B.a.gaL(r).a
for(t=r.length,q=0;q<t;++q)r[q].ch=1
B.a.p(p.cy,A.m(["type","GAME_OVER","loser",a.a,"reason",b],u.N,u.z))},
c2(a,b){var t,s,r=this
r.J(b)
t=r.M(a)
s=r.at
if(s==="finished")return
if(s==="waiting"&&r.d.length>1){B.a.a1(r.d,t);++r.ax
return}r.a4(t,"resigned",b)},
bV(a,b,c,d,a0,a1,a2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this
e.cy=A.e([],u.X)
e.J(a1)
t=e.M(a)
if(a2!=null&&a2!==e.w)return A.m(["error","Eski round hamlesi."],u.N,u.z)
if(b<=t.z&&b>0)return A.m(["duplicate",!0],u.N,u.z)
if(e.at!=="playing")return A.m(["error","Ma\xe7 \u015fu anda oynanabilir de\u011fil."],u.N,u.z)
if(t.ay)return A.m(["error","Bu ma\xe7ta elendin."],u.N,u.z)
if(!t.as||e.gF().G(0,new A.cL()))return A.m(["error","Ba\u011flant\u0131 bekleniyor."],u.N,u.z)
s=t.cy
if(s!=null&&a1<s)return A.m(["error","Tahtan donuk."],u.N,u.z)
if(b!==t.z+1)return A.m(["error","Hamle s\u0131ras\u0131 g\xfcncel de\u011fil."],u.N,u.z)
s=t.e
s===$&&A.W()
r=s.bU(c,d,a0)
if(r==null)return A.m(["error","Ge\xe7ersiz yerle\u015ftirme."],u.N,u.z)
t.z=b
s=B.b.aq(t.e.f,500)
q=s-t.x
t.x=s
if(q>0){s=e.gF()
p=s.$ti
o=p.h("t<b.E>")
n=A.S(new A.t(s,p.h("i(b.E)").a(new A.cM(a)),o),o.h("b.E"))
for(s=n.length,p=u.N,o=u.z,m=0;m<n.length;n.length===s||(0,A.D)(n),++m){l=n[m]
k=B.b.bB(q,0,l.r)
t.y+=k
l.r-=k
B.a.p(e.cy,A.m(["type","DAMAGE","player",l.a,"amount",k],p,o))}s=A.w(n)
p=s.h("t<1>")
j=A.S(new A.t(n,s.h("i(1)").a(new A.cN()),p),p.h("b.E"))
B.a.T(j,new A.cO())
for(s=j.length,m=0;m<j.length;j.length===s||(0,A.D)(j),++m)e.a4(j[m],"score",a1)}if(e.at!=="finished")e.ah(t,a1);++e.ax
s=r.b
p=r.c
o=r.d
i=u.N
h=A.ah(i,u.p)
for(g=r.a,g=new A.ag(g,A.r(g).h("ag<1,2>")).gq(0);g.k();){f=g.d
h.l(0,""+f.a,f.b)}return A.m(["ok",!0,"move",A.m(["player",a,"slot",c,"row",d,"col",a0,"lines",s,"points",p,"allClear",o,"clearedCells",h],i,u.K)],i,u.z)},
af(a,b){var t,s,r,q
a.id=a.fx=a.fr=a.dy=a.dx=a.db=null;--a.r;++a.w
B.a.p(this.cy,A.m(["type","BOARD_RESET","player",a.a,"amount",1],u.N,u.z))
if(a.r===0)this.a4(a,"board_out",b)
else{t=a.e
t===$&&A.W()
s=J.aS(8,u.R)
for(r=u.I,q=0;q<8;++q)s[q]=A.c5(8,null,!1,r)
t.sae(s)
t=a.e
t.x=t.w=t.r=0
t.a0()}},
c_(a,b,c){var t,s,r=this
r.J(b)
if(r.at!=="finished")return
t=r.M(a)
if(!t.as)return
t.at=!0;++r.ax
s=r.d
if(s.length===r.ga6()&&B.a.E(s,new A.cQ()))r.bw(c,b)},
bw(a,b){var t,s,r,q,p,o=this;++o.w
o.b=a==null?B.b.t(o.b*48271+b,2147483646)+1:a
o.x.ar(0)
o.as=-100
o.at="countdown"
o.ay=b+3000
o.cx=o.CW=o.ch=null
o.cy=A.e([A.m(["type","REMATCH_STARTED","round",o.w],u.N,u.z)],u.X)
for(t=o.d,s=t.length,r=0;r<t.length;t.length===s||(0,A.D)(t),++r){q=t[r]
p=A.cX(q.gap(),null)
q.e=p
q.f=0
q.r=5
q.z=q.y=q.x=q.w=0
q.Q=!0
q.ay=q.at=!1
q.fy=q.fx=q.fr=q.dy=q.dx=q.db=q.cy=q.ax=q.ch=null
q.go=!1
q.id=null
p.a0()}if(o.y&&o.e==="duel")o.aX(b);++o.ax},
W(){var t,s,r,q,p,o,n,m,l=this,k=u.N,j=A.ah(k,u.z)
j.l(0,"version",l.r)
j.l(0,"damageStep",500)
j.l(0,"round",l.w)
if(l.r===2){k=A.ah(k,u.at)
for(t=l.x,t=new A.ag(t,A.r(t).h("ag<1,2>")).gq(0),s=u.t,r=u.q;t.k();){q=t.d
p=q.a
o=A.e([],r)
for(n=J.M(q.b);n.k();){m=n.gm()
o.push(m==null?null:A.e([m.a,m.b],s))}k.l(0,""+p,o)}j.l(0,"sets",k)}j.l(0,"roomId",l.a)
j.l(0,"mode",l.e)
j.l(0,"invited",l.f)
j.l(0,"jokers",l.y)
j.l(0,"draftEnd",l.z)
j.l(0,"picker",l.Q)
j.l(0,"lastRescue",l.as)
j.l(0,"seed",l.b)
j.l(0,"createdAt",l.c)
j.l(0,"status",l.at)
j.l(0,"revision",l.ax)
j.l(0,"startAt",l.ay)
j.l(0,"endedAt",l.ch)
j.l(0,"winner",l.CW)
j.l(0,"reason",l.cx)
k=l.d
t=A.w(k)
s=t.h("H<1,T<o,@>>")
k=A.S(new A.H(k,t.h("T<o,@>(1)").a(new A.cR()),s),s.h("C.E"))
j.l(0,"players",k)
return j},
sb2(a){this.f=u.L.a(a)}}
A.cJ.prototype={
$1(a){return!u.h.a(a).ay},
$S:0}
A.cB.prototype={
$0(){var t,s=this.a,r=s.b,q=this.b,p=s.gF(),o=p.$ti,n=o.h("a6<1,Z>")
p=A.S(new A.a6(p,o.h("Z(1)").a(new A.cA()),n),n.h("b.E"))
t=A.iO(r,q,p,q-s.as>=6)
if(t.b)s.as=q
return t.a},
$S:13}
A.cA.prototype={
$1(a){var t=u.h.a(a).e
t===$&&A.W()
return t},
$S:31}
A.cD.prototype={
$1(a){return u.h.a(a).f},
$S:15}
A.cC.prototype={
$2(a,b){A.h(a)
u.U.a(b)
return a<this.a},
$S:21}
A.cP.prototype={
$1(a){return u.h.a(a).a===this.a},
$S:0}
A.cK.prototype={
$1(a){return u.h.a(a).a===this.a},
$S:0}
A.cy.prototype={
$1(a){u.h.a(a)
return a.Q&&a.as},
$S:0}
A.cE.prototype={
$2(a,b){var t=u.h
return B.b.H(t.a(a).a,t.a(b).a)},
$S:5}
A.cz.prototype={
$1(a){return B.a.D(u.h.a(a).CW,this.a)},
$S:0}
A.cS.prototype={
$1(a){return u.h.a(a).a},
$S:15}
A.cT.prototype={
$2(a,b){return A.h(a)+u.h.a(b).CW.length},
$S:23}
A.cU.prototype={
$1(a){return!u.h.a(a).as},
$S:0}
A.cV.prototype={
$1(a){return u.h.a(a).a!==this.a},
$S:0}
A.cF.prototype={
$1(a){var t=u.h.a(a).ax
return t!=null&&this.a>=t},
$S:0}
A.cG.prototype={
$2(a,b){var t,s=u.h
s.a(a)
s.a(b)
s=a.ax
s.toString
t=b.ax
t.toString
return B.b.H(s,t)},
$S:5}
A.cH.prototype={
$1(a){var t
u.h.a(a)
if(a.gU()!=null){t=a.gU()
t.toString
t=this.a>=t}else t=!1
return t},
$S:0}
A.cI.prototype={
$2(a,b){var t,s=u.h
s.a(a)
s.a(b)
s=a.gU()
s.toString
t=b.gU()
t.toString
return B.b.H(s,t)},
$S:5}
A.cL.prototype={
$1(a){return!u.h.a(a).as},
$S:0}
A.cM.prototype={
$1(a){return u.h.a(a).a!==this.a},
$S:0}
A.cN.prototype={
$1(a){return u.h.a(a).r===0},
$S:0}
A.cO.prototype={
$2(a,b){var t,s=u.h
s.a(a)
s.a(b)
s=a.e
s===$&&A.W()
s=s.f
t=b.e
t===$&&A.W()
return B.b.H(s,t.f)},
$S:5}
A.cQ.prototype={
$1(a){u.h.a(a)
return a.at&&a.as},
$S:0}
A.cR.prototype={
$1(a){return u.h.a(a).W()},
$S:24}
A.ee.prototype={
$1(a){var t,s,r,q,p=this
u.L.a(a)
t=J.a8(a)
s=p.a+t.i(a,0)
r=p.b+t.i(a,1)
t=p.c
q=!1
if(s<t)if(r<t){t=p.d
if(!(s>=0&&s<t.length))return A.f(t,s)
t=J.l(t[s],r)==null}else t=q
else t=q
return t},
$S:9}
A.eh.prototype={
$2(a,b){var t=this.a
if(!(a<t.length))return A.f(t,a)
return J.l(t[a],b)!=null||this.b.D(0,a*this.c+b)},
$S:26}
A.ef.prototype={
$1(a){return A.aK(a)},
$S:17}
A.eg.prototype={
$1(a){return A.aK(a)},
$S:17}
A.n.prototype={
gc3(){var t,s=this.a
if(!(s>=0&&s<39))return A.f(B.d,s)
s=B.d[s]
t=A.w(s)
return new A.H(s,t.h("a(1)").a(new A.di()),t.h("H<1,a>")).V(0,B.u)+1},
gbC(){var t,s=this.a
if(!(s>=0&&s<39))return A.f(B.d,s)
s=B.d[s]
t=A.w(s)
return new A.H(s,t.h("a(1)").a(new A.dh()),t.h("H<1,a>")).V(0,B.u)+1}}
A.di.prototype={
$1(a){return J.l(u.L.a(a),0)},
$S:18}
A.dh.prototype={
$1(a){return J.l(u.L.a(a),1)},
$S:18}
A.dg.prototype={}
A.Z.prototype={
b1(a,b,c,d){var t,s
u.D.a(d)
t=d==null?this.c:d
s=a.a
if(!(s>=0&&s<39))return A.f(B.d,s)
return B.a.E(B.d[s],new A.d_(this,b,c,t))},
a9(a,b,c){return this.b1(a,b,c,null)},
b7(a,b){var t,s,r
u.D.a(b)
t=A.e([],u.u)
for(s=0;s<=this.c.length-a.gc3();++s)for(r=0;r<=this.c.length-a.gbC();++r)if(this.b1(a,s,r,b))t.push(new A.a1(s,r))
return t},
b6(a){return this.b7(a,null)},
gaz(){return J.eQ(this.e,new A.d0(this))},
bK(a,b){var t,s,r,q,p,o,n=this
if(n.c.length!==8||!B.C.D(0,b))return!1
t=b.length
if(0>=t)return A.f(b,0)
s=b[0]==="t"?1:0
if(1>=t)return A.f(b,1)
r=b[1]==="l"?1:0
q=n.c.length+1
p=J.aS(q,u.R)
for(t=u.I,o=0;o<q;++o)p[o]=A.f6(q,new A.cZ(n,o,s,r),t)
n.c=p
return!0},
bd(a){var t,s,r,q,p,o,n,m,l
if(this.c.length!==9||!B.C.D(0,a))return!1
t=a.length
if(0>=t)return A.f(a,0)
s=a[0]==="t"?1:0
if(1>=t)return A.f(a,1)
r=a[1]==="l"?1:0
q=J.aS(8,u.R)
for(t=u.d,p=0;p<8;++p){o=A.e(new Array(8),t)
for(n=p+s,m=0;m<8;++m){l=this.c
if(!(n<l.length))return A.f(l,n)
o[m]=J.l(l[n],m+r)}q[p]=o}this.c=q
A.cY(q)
return!0},
bW(){var t,s,r=this.c.length,q=B.b.aq(r-2,2),p=r/2|0
for(r=q+3,t=q;t<r;++t){s=this.c
if(!(t>=0&&t<s.length))return A.f(s,t)
J.aO(s[t],p,8)}},
c0(){var t,s,r,q,p,o
for(t=this.c,s=t.length,r=0;r<t.length;t.length===s||(0,A.D)(t),++r){q=t[r]
for(p=J.a8(q),o=0;o<p.gj(q);++o)if(p.i(q,o)===8)p.l(q,o,null)}},
bU(a,b,c){var t,s,r,q,p,o,n,m,l,k=this
if(a<0||a>=J.Y(k.e))return null
t=J.l(k.e,a)
if(t==null||!k.a9(t,b,c))return null;++k.y
A.eo(k.c,t,b,c)
J.aO(k.e,a,null)
s=A.en(k.c)
r=s.a.length+s.b.length
q=A.cY(k.c)
p=r>0
if(p){o=++k.r
k.z+=r
k.Q=Math.max(k.Q,o)
k.w=0
k.x=10*r*r*o}else if(k.r>0)if(++k.w>=3)k.x=k.w=k.r=0
n=p&&B.a.E(k.c,new A.d2())
if(n)++k.as
p=t.a
if(!(p>=0&&p<39))return A.f(B.d,p)
p=B.d[p]
o=k.r
m=n?300:0
l=p.length+10*r*r*o+m
k.f+=l
if(J.cw(k.e,new A.d3()))k.a0()
return new A.dg(q,r,l,n)},
a0(){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6=this,a7=a6.b
if(a7!=null){a6.e=a7.$0()
return}t=A.hb(a6.c)
s=A.e([],u.a)
if(++a6.d>=6&&A.he(t)&&a6.a.aE()<0.5){r=A.j5(t)
if(r!=null){a7=r.a
q=new A.n(a7,B.b.t(a7,8))
B.a.p(s,q)
A.eo(t,q,r.b,r.c)
A.cY(t)
a6.d=0}}for(p=s.length,a7=a6.a,o=u.H,n=u.G,m=A.w(t),l=m.h("b<a?>(1)"),m=m.h("Q<1,a?>"),k=m.h("i(b.E)"),j=m.h("t<b.E>");p<3;++p){i=A.e([],n)
h=new A.t(new A.Q(t,l.a(new A.d4()),m),k.a(new A.d5()),j).gj(0)
g=t.length
for(f=$.bN(),e=f.length,g=h/(g*g)>0.65,d=0;d<f.length;f.length===e||(0,A.D)(f),++d){c=f[d]
q=new A.n(c,B.b.t(c,8))
b=a6.b7(q,t)
if(b.length===0)continue
if(!(c<39))return A.f(B.d,c)
h=B.d[c].length
a=h===1?0.18:1
if(h>=5)a*=1.3+Math.min(a6.f/5000,0.7)
if(g&&h<=3)a*=1.8
B.a.p(i,new A.av(q,b,B.a.G(s,new A.d6(c))?a*0.25:a))}if(i.length===0)break
a0=a7.aE()*B.a.aw(i,0,new A.d7(),o)
a1=B.a.gb4(i)
for(h=i.length,d=0;d<h;++d){a2=i[d]
a0-=a2.c
if(a0<=0){a1=a2
break}}h=a1.b
g=J.a8(h)
a3=g.i(h,a7.aF(g.gj(h)))
h=a1.a
B.a.p(s,h)
A.eo(t,h,a3.a,a3.b)
A.cY(t)}B.a.aK(s,a7)
a4=J.aS(3,u.k)
for(a7=s.length,a5=0;a5<3;++a5){if(a5<a7){if(!(a5<a7))return A.f(s,a5)
o=s[a5]}else o=null
a4[a5]=o}a6.e=a4},
W(){var t,s,r,q,p=this,o=p.c,n=A.e([],u.q)
for(t=J.M(p.e),s=u.t;t.k();){r=t.gm()
n.push(r==null?null:A.e([r.a,r.b],s))}q=A.m(["version",1,"grid",o,"tray",n,"score",p.f,"combo",p.r,"misses",p.w,"comboBonus",p.x,"reviveUsed",p.ax,"sinceRescue",p.d],u.N,u.z)
return q},
sae(a){this.c=u.cw.a(a)},
sc5(a){this.e=u.U.a(a)},
sbc(a){this.f=A.h(a)},
sbD(a){this.r=A.h(a)},
sbS(a){this.w=A.h(a)},
sbE(a){this.x=A.h(a)},
sbX(a){this.y=A.h(a)},
sbR(a){this.z=A.h(a)},
sbA(a){this.Q=A.h(a)},
sbz(a){this.as=A.h(a)},
sc4(a){this.at=A.aK(a)}}
A.d_.prototype={
$1(a){var t,s,r,q,p=this
u.L.a(a)
t=J.a8(a)
s=p.b+t.i(a,0)
r=p.c+t.i(a,1)
t=!1
if(s>=0){q=p.a.c.length
if(s<q)if(r>=0)if(r<q){t=p.d
if(!(s<t.length))return A.f(t,s)
t=J.l(t[s],r)==null}}return t},
$S:9}
A.d0.prototype={
$1(a){u.k.a(a)
return a!=null&&this.a.b6(a).length!==0},
$S:6}
A.cZ.prototype={
$1(a){var t,s=this,r=s.b-s.c,q=a-s.d
if(r>=0){t=s.a.c.length
t=r<t&&q>=0&&q<t}else t=!1
if(t){t=s.a.c
if(!(r>=0&&r<t.length))return A.f(t,r)
t=J.l(t[r],q)}else t=null
return t},
$S:30}
A.d2.prototype={
$1(a){return J.cw(u.R.a(a),new A.d1())},
$S:7}
A.d1.prototype={
$1(a){return A.u(a)==null},
$S:2}
A.d3.prototype={
$1(a){return u.k.a(a)==null},
$S:6}
A.d4.prototype={
$1(a){return u.R.a(a)},
$S:1}
A.d5.prototype={
$1(a){return A.u(a)!=null},
$S:2}
A.d6.prototype={
$1(a){return u.A.a(a).a===this.a},
$S:3}
A.d7.prototype={
$2(a,b){return A.dL(a)+u.bb.a(b).c},
$S:32}
A.dd.prototype={
$1(a){return u.R.a(a)},
$S:1}
A.de.prototype={
$1(a){return A.u(a)!=null},
$S:2}
A.df.prototype={
$1(a){return this.a.b6(new A.n(A.h(a),0)).length!==0},
$S:4}
A.d9.prototype={
$1(a){var t=J.el(u.j.a(a),new A.d8(),u.I)
t=A.S(t,t.$ti.h("C.E"))
return t},
$S:33}
A.d8.prototype={
$1(a){var t
if(a!=null)t=!A.cu(a)||a<0||a>8
else t=!1
if(t)throw A.d(B.y)
return A.u(a)},
$S:34}
A.da.prototype={
$1(a){return J.Y(u.R.a(a))!==this.a.length},
$S:7}
A.db.prototype={
$1(a){var t,s,r
if(a==null)return null
t=!0
if(u.j.b(a)){s=J.a8(a)
if(s.gj(a)===2)if(A.cu(s.i(a,0)))if(A.cu(s.i(a,1))){r=s.i(a,0)
if(typeof r!=="number")return r.R()
if(!(r<0)){r=s.i(a,0)
if(typeof r!=="number")return r.aI()
if(!(r>=39)){r=s.i(a,1)
if(typeof r!=="number")return r.R()
if(!(r<0)){t=s.i(a,1)
if(typeof t!=="number")return t.aI()
t=t>=8}}}}}if(t)throw A.d(B.y)
t=J.a8(a)
return new A.n(A.h(t.i(a,0)),A.h(t.i(a,1)))},
$S:35}
A.dc.prototype={
$1(a){return u.k.a(a)==null},
$S:6}
A.ec.prototype={
$1(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null,d="state",c="mode",b="id"
A.I(a)
try{t=u.cg.a(B.o.bF(a,e))
if(J.l(t,d)==null){k=A.eT(A.I(J.l(t,"roomId")),A.h(J.l(t,"seed")),A.h(J.l(t,"now")))
k.e=A.I(B.r.I(J.l(t,c))?J.l(t,c):"duel")
s=A.e([],u.t)
j=u.g.a(J.l(t,"invited"))
j=J.M(j==null?[]:j)
while(j.k()){r=j.gm()
J.h1(s,A.h(r))}k.sb2(s)
k.y=J.E(J.l(t,"jokers"),!0)&&!J.E(J.l(t,c),"trio")}else k=A.h8(A.es(u.f.a(J.l(t,d)),u.N,u.z))
q=k
p=A.h(J.l(t,"now"))
o=null
switch(J.l(t,"action")){case"join":J.h7(q,A.h(J.l(t,b)),A.I(J.l(t,"name")),p)
break
case"connect":s=q
j=A.h(J.l(t,b))
i=A.h(p)
s.J(i)
h=s.M(j)
h.as=!0
h.ax=null;++s.ax
s.aP(i)
break
case"disconnect":q.bH(A.h(J.l(t,b)),p)
break
case"ready":q.bZ(A.h(J.l(t,b)),p)
break
case"advance":q.J(p)
break
case"resign":q.c2(A.h(J.l(t,b)),p)
break
case"rematch":q.c_(A.h(J.l(t,b)),p,A.u(J.l(t,"seed")))
break
case"pick":o=q.bT(A.h(J.l(t,b)),A.I(J.l(t,"joker")),p)
break
case"joker":o=q.c7(A.h(J.l(t,b)),A.I(J.l(t,"joker")),p,A.ct(J.l(t,"corner")))
break
case"aim":o=q.by(A.h(J.l(t,b)),J.E(J.l(t,"on"),!0),p)
break
case"place":o=q.bV(A.h(J.l(t,b)),A.h(J.l(t,"moveId")),A.h(J.l(t,"slot")),A.h(J.l(t,"row")),A.h(J.l(t,"col")),p,A.u(J.l(t,"round")))
break}n=A.ah(u.N,u.z)
J.aO(n,d,q.W())
J.aO(n,"events",q.cy)
m=o
if(m!=null)J.h2(n,m)
g=B.o.au(n,e)
return g}catch(f){s=A.eO(f)
if(s instanceof A.aF){l=s
s=u.N
return B.o.au(A.m(["error",l.a],s,s),e)}else{s=u.N
g=B.o.au(A.m(["error","Ge\xe7ersiz ma\xe7 iste\u011fi."],s,s),e)
return g}}},
$S:36};(function aliases(){var t=J.ar.prototype
t.bg=t.n
t=A.b.prototype
t.bf=t.c8})();(function installTearOffs(){var t=hunkHelpers._static_2,s=hunkHelpers._static_1,r=hunkHelpers.installStaticTearOff,q=hunkHelpers._instance_0u,p=hunkHelpers._instance_1u
t(J,"ij","hw",37)
s(A,"iK","i9",12)
r(A,"fK",2,null,["$1$2","$2"],["fM",function(a,b){return A.fM(a,b,u.H)}],16,0)
r(A,"fJ",2,null,["$1$2","$2"],["fL",function(a,b){return A.fL(a,b,u.H)}],16,0)
q(A.F.prototype,"gap","bp",13)
p(A.bQ.prototype,"gaV","bt",14)
s(A,"fF","hc",2)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.y,null)
r(A.y,[A.eq,J.c_,A.bt,J.ay,A.b,A.b6,A.A,A.dw,A.aD,A.bm,A.aj,A.bc,A.bb,A.by,A.R,A.al,A.b7,A.aG,A.as,A.O,A.dx,A.du,A.x,A.dq,A.aB,A.bl,A.a7,A.co,A.dI,A.bH,A.cs,A.aI,A.q,A.bU,A.bW,A.dC,A.bu,A.dz,A.bd,A.U,A.br,A.aX,A.cp,A.bR,A.a2,A.F,A.bQ,A.n,A.dg,A.Z])
r(J.c_,[J.c1,J.bf,J.bh,J.bg,J.bi,J.aT,J.aA])
r(J.bh,[J.ar,J.p,A.aU,A.bp])
r(J.ar,[J.cf,J.aY,J.aq])
s(J.c0,A.bt)
s(J.dk,J.p)
r(J.aT,[J.be,J.c2])
r(A.b,[A.au,A.k,A.a6,A.t,A.Q,A.ak,A.bB,A.b0])
r(A.au,[A.az,A.bM])
s(A.bA,A.az)
s(A.bz,A.bM)
s(A.ac,A.bz)
r(A.A,[A.bk,A.bw,A.c3,A.cm,A.ci,A.cn,A.bj,A.bO,A.ap,A.bx,A.cl,A.aF,A.bV])
r(A.k,[A.C,A.aC,A.ag])
r(A.C,[A.bv,A.H,A.cr])
s(A.ba,A.a6)
r(A.al,[A.aZ,A.b_])
s(A.a1,A.aZ)
s(A.av,A.b_)
s(A.b9,A.b7)
r(A.as,[A.b8,A.bG])
s(A.aQ,A.b8)
r(A.O,[A.bZ,A.bS,A.bT,A.ck,A.e8,A.ea,A.ds,A.dT,A.dX,A.dY,A.dZ,A.e_,A.e0,A.e1,A.e2,A.e3,A.e5,A.e6,A.e7,A.dR,A.dM,A.dN,A.dO,A.dF,A.dG,A.dH,A.cW,A.dW,A.cJ,A.cA,A.cD,A.cP,A.cK,A.cy,A.cz,A.cS,A.cU,A.cV,A.cF,A.cH,A.cL,A.cM,A.cN,A.cQ,A.cR,A.ee,A.ef,A.eg,A.di,A.dh,A.d_,A.d0,A.cZ,A.d2,A.d1,A.d3,A.d4,A.d5,A.d6,A.dd,A.de,A.df,A.d9,A.d8,A.da,A.db,A.dc,A.ec])
s(A.ab,A.bZ)
s(A.bs,A.bw)
r(A.ck,[A.cj,A.aP])
r(A.x,[A.af,A.cq])
r(A.bT,[A.dl,A.e9,A.dr,A.dt,A.dD,A.e4,A.dP,A.dS,A.cC,A.cE,A.cT,A.cG,A.cI,A.cO,A.eh,A.d7])
r(A.bp,[A.c6,A.aV])
r(A.aV,[A.bC,A.bE])
s(A.bD,A.bC)
s(A.bn,A.bD)
s(A.bF,A.bE)
s(A.bo,A.bF)
r(A.bn,[A.c7,A.c8])
r(A.bo,[A.c9,A.ca,A.cb,A.cc,A.cd,A.bq,A.ce])
s(A.b1,A.cn)
s(A.aH,A.bG)
s(A.c4,A.bj)
s(A.dm,A.bU)
r(A.bW,[A.dp,A.dn])
s(A.dB,A.dC)
r(A.ap,[A.aW,A.bY])
s(A.cB,A.bS)
t(A.bM,A.q)
t(A.bC,A.q)
t(A.bD,A.R)
t(A.bE,A.q)
t(A.bF,A.R)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{a:"int",j:"double",K:"num",o:"String",i:"bool",br:"Null",c:"List",y:"Object",T:"Map",G:"JSObject"},mangledNames:{},types:["i(F)","c<a?>(c<a?>)","i(a?)","i(n)","i(a)","a(F,F)","i(n?)","i(c<a?>)","~(y?,y?)","i(c<a>)","o(a?)","j(a2)","@(@)","c<n?>()","c<n?>(a)","a(F)","0^(0^,0^)<K>","i(i)","a(c<a>)","j(K,+(a,c<a>,j))","@(@,o)","i(a,c<n?>)","a(n,n)","a(a,F)","T<o,@>(F)","n(a)","i(a,a)","@(o)","~(@,@)","i(a2)","a?(a)","Z(F)","j(K,+(n,c<+(a,a)>,j))","c<a?>(@)","a?(@)","n?(@)","o(o)","a(@,@)","a(Z,Z)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof A.a1&&a.b(c.a)&&b.b(c.b),"3;":(a,b,c)=>d=>d instanceof A.av&&a.b(d.a)&&b.b(d.b)&&c.b(d.c)}}
A.i0(v.typeUniverse,JSON.parse('{"aq":"ar","cf":"ar","aY":"ar","jb":"aU","c1":{"i":[],"v":[]},"bf":{"v":[]},"bh":{"G":[]},"ar":{"G":[]},"p":{"c":["1"],"k":["1"],"G":[],"b":["1"]},"c0":{"bt":[]},"dk":{"p":["1"],"c":["1"],"k":["1"],"G":[],"b":["1"]},"ay":{"B":["1"]},"aT":{"j":[],"K":[],"ad":["K"]},"be":{"j":[],"a":[],"K":[],"ad":["K"],"v":[]},"c2":{"j":[],"K":[],"ad":["K"],"v":[]},"aA":{"o":[],"ad":["o"],"v":[]},"au":{"b":["2"]},"b6":{"B":["2"]},"az":{"au":["1","2"],"b":["2"],"b.E":"2"},"bA":{"az":["1","2"],"au":["1","2"],"k":["2"],"b":["2"],"b.E":"2"},"bz":{"q":["2"],"c":["2"],"au":["1","2"],"k":["2"],"b":["2"]},"ac":{"bz":["1","2"],"q":["2"],"c":["2"],"au":["1","2"],"k":["2"],"b":["2"],"q.E":"2","b.E":"2"},"bk":{"A":[]},"k":{"b":["1"]},"C":{"k":["1"],"b":["1"]},"bv":{"C":["1"],"k":["1"],"b":["1"],"C.E":"1","b.E":"1"},"aD":{"B":["1"]},"a6":{"b":["2"],"b.E":"2"},"ba":{"a6":["1","2"],"k":["2"],"b":["2"],"b.E":"2"},"bm":{"B":["2"]},"H":{"C":["2"],"k":["2"],"b":["2"],"C.E":"2","b.E":"2"},"t":{"b":["1"],"b.E":"1"},"aj":{"B":["1"]},"Q":{"b":["2"],"b.E":"2"},"bc":{"B":["2"]},"bb":{"B":["1"]},"ak":{"b":["1"],"b.E":"1"},"by":{"B":["1"]},"a1":{"aZ":[],"al":[]},"av":{"b_":[],"al":[]},"b7":{"T":["1","2"]},"b9":{"b7":["1","2"],"T":["1","2"]},"bB":{"b":["1"],"b.E":"1"},"aG":{"B":["1"]},"b8":{"as":["1"],"k":["1"],"b":["1"]},"aQ":{"b8":["1"],"as":["1"],"k":["1"],"b":["1"]},"bZ":{"O":[],"ae":[]},"ab":{"O":[],"ae":[]},"bs":{"A":[]},"c3":{"A":[]},"cm":{"A":[]},"O":{"ae":[]},"bS":{"O":[],"ae":[]},"bT":{"O":[],"ae":[]},"ck":{"O":[],"ae":[]},"cj":{"O":[],"ae":[]},"aP":{"O":[],"ae":[]},"ci":{"A":[]},"af":{"x":["1","2"],"f3":["1","2"],"T":["1","2"],"x.K":"1","x.V":"2"},"aC":{"k":["1"],"b":["1"],"b.E":"1"},"aB":{"B":["1"]},"ag":{"k":["U<1,2>"],"b":["U<1,2>"],"b.E":"U<1,2>"},"bl":{"B":["U<1,2>"]},"aZ":{"al":[]},"b_":{"al":[]},"aU":{"G":[],"v":[]},"bp":{"G":[]},"c6":{"G":[],"v":[]},"aV":{"a_":["1"],"G":[]},"bn":{"q":["j"],"c":["j"],"a_":["j"],"k":["j"],"G":[],"b":["j"],"R":["j"]},"bo":{"q":["a"],"c":["a"],"a_":["a"],"k":["a"],"G":[],"b":["a"],"R":["a"]},"c7":{"q":["j"],"c":["j"],"a_":["j"],"k":["j"],"G":[],"b":["j"],"R":["j"],"v":[],"q.E":"j"},"c8":{"q":["j"],"c":["j"],"a_":["j"],"k":["j"],"G":[],"b":["j"],"R":["j"],"v":[],"q.E":"j"},"c9":{"q":["a"],"c":["a"],"a_":["a"],"k":["a"],"G":[],"b":["a"],"R":["a"],"v":[],"q.E":"a"},"ca":{"q":["a"],"c":["a"],"a_":["a"],"k":["a"],"G":[],"b":["a"],"R":["a"],"v":[],"q.E":"a"},"cb":{"q":["a"],"c":["a"],"a_":["a"],"k":["a"],"G":[],"b":["a"],"R":["a"],"v":[],"q.E":"a"},"cc":{"q":["a"],"c":["a"],"a_":["a"],"k":["a"],"G":[],"b":["a"],"R":["a"],"v":[],"q.E":"a"},"cd":{"q":["a"],"c":["a"],"a_":["a"],"k":["a"],"G":[],"b":["a"],"R":["a"],"v":[],"q.E":"a"},"bq":{"q":["a"],"c":["a"],"a_":["a"],"k":["a"],"G":[],"b":["a"],"R":["a"],"v":[],"q.E":"a"},"ce":{"eA":[],"q":["a"],"c":["a"],"a_":["a"],"k":["a"],"G":[],"b":["a"],"R":["a"],"v":[],"q.E":"a"},"cn":{"A":[]},"b1":{"A":[]},"bH":{"B":["1"]},"b0":{"b":["1"],"b.E":"1"},"aH":{"as":["1"],"f4":["1"],"k":["1"],"b":["1"]},"aI":{"B":["1"]},"x":{"T":["1","2"]},"as":{"k":["1"],"b":["1"]},"bG":{"as":["1"],"k":["1"],"b":["1"]},"cq":{"x":["o","@"],"T":["o","@"],"x.K":"o","x.V":"@"},"cr":{"C":["o"],"k":["o"],"b":["o"],"C.E":"o","b.E":"o"},"bj":{"A":[]},"c4":{"A":[]},"j":{"K":[],"ad":["K"]},"a":{"K":[],"ad":["K"]},"c":{"k":["1"],"b":["1"]},"K":{"ad":["K"]},"o":{"ad":["o"]},"bO":{"A":[]},"bw":{"A":[]},"ap":{"A":[]},"aW":{"A":[]},"bY":{"A":[]},"bx":{"A":[]},"cl":{"A":[]},"aF":{"A":[]},"bV":{"A":[]},"bu":{"A":[]},"aX":{"hG":[]},"cp":{"ew":[]},"bR":{"ew":[]},"hr":{"c":["a"],"k":["a"],"b":["a"]},"eA":{"c":["a"],"k":["a"],"b":["a"]},"hJ":{"c":["a"],"k":["a"],"b":["a"]},"hp":{"c":["a"],"k":["a"],"b":["a"]},"hH":{"c":["a"],"k":["a"],"b":["a"]},"hq":{"c":["a"],"k":["a"],"b":["a"]},"hI":{"c":["a"],"k":["a"],"b":["a"]},"hn":{"c":["j"],"k":["j"],"b":["j"]},"ho":{"c":["j"],"k":["j"],"b":["j"]}}'))
A.i_(v.typeUniverse,JSON.parse('{"bM":2,"aV":1,"bG":1,"bU":2,"bW":2}'))
var u=(function rtii(){var t=A.b4
return{h:t("F"),W:t("Z"),A:t("n"),w:t("ad<@>"),Y:t("aQ<o>"),_:t("k<@>"),C:t("A"),Z:t("ae"),n:t("ab<j>"),v:t("ab<a>"),c:t("b<@>"),x:t("p<F>"),a:t("p<n>"),S:t("p<c<a>>"),E:t("p<c<a?>>"),X:t("p<T<o,@>>"),u:t("p<+(a,a)>"),G:t("p<+(n,c<+(a,a)>,j)>"),r:t("p<+(a,c<a>,j)>"),s:t("p<o>"),J:t("p<a2>"),bx:t("p<i>"),o:t("p<@>"),t:t("p<a>"),b:t("p<n?>"),q:t("p<c<a>?>"),d:t("p<a?>"),T:t("bf"),m:t("G"),e:t("aq"),da:t("a_<@>"),ao:t("c<c<a>>"),cw:t("c<c<a?>>"),l:t("c<o>"),j:t("c<@>"),L:t("c<a>"),U:t("c<n?>"),at:t("c<c<a>?>"),R:t("c<a?>"),cg:t("T<o,@>"),f:t("T<@,@>"),cC:t("H<a2,j>"),P:t("br"),K:t("y"),cY:t("jc"),F:t("+()"),bb:t("+(n,c<+(a,a)>,j)"),cX:t("+(a,c<a>,j)"),N:t("o"),bW:t("v"),cr:t("aY"),Q:t("t<n>"),i:t("a2"),y:t("i"),B:t("i(n)"),V:t("j"),ba:t("j(a2)"),z:t("@"),p:t("a"),k:t("n?"),bc:t("f_<br>?"),aQ:t("G?"),D:t("c<c<a?>>?"),g:t("c<@>?"),b8:t("c<n?>(a)?"),a5:t("T<@,@>?"),O:t("y?"),aD:t("o?"),M:t("cs?"),cG:t("i?"),dd:t("j?"),I:t("a?"),ae:t("K?"),H:t("K"),cQ:t("~(o,@)")}})();(function constants(){var t=hunkHelpers.makeConstList
B.O=J.c_.prototype
B.a=J.p.prototype
B.b=J.be.prototype
B.q=J.aT.prototype
B.n=J.aA.prototype
B.P=J.aq.prototype
B.Q=J.bh.prototype
B.B=J.cf.prototype
B.t=J.aY.prototype
B.F=new A.ab(A.fJ(),u.n)
B.u=new A.ab(A.fJ(),u.v)
B.E=new A.ab(A.fK(),u.n)
B.D=new A.ab(A.fK(),u.v)
B.G=new A.bb(A.b4("bb<0&>"))
B.v=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.H=function() {
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
B.M=function(getTagFallback) {
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
B.I=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.L=function(hooks) {
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
B.K=function(hooks) {
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
B.J=function(hooks) {
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
B.w=function(hooks) { return hooks; }

B.o=new A.dm()
B.m=new A.dw()
B.x=new A.cp()
B.N=new A.bd("Battle version")
B.y=new A.bd("")
B.R=new A.dn(null)
B.S=new A.dp(null)
B.c=t([0,0],u.t)
B.a5=t([B.c],u.S)
B.e=t([0,1],u.t)
B.a4=t([B.c,B.e],u.S)
B.f=t([1,0],u.t)
B.au=t([B.c,B.f],u.S)
B.i=t([0,2],u.t)
B.a9=t([B.c,B.e,B.i],u.S)
B.j=t([2,0],u.t)
B.X=t([B.c,B.f,B.j],u.S)
B.z=t([0,3],u.t)
B.V=t([B.c,B.e,B.i,B.z],u.S)
B.A=t([3,0],u.t)
B.al=t([B.c,B.f,B.j,B.A],u.S)
B.T=t([0,4],u.t)
B.aq=t([B.c,B.e,B.i,B.z,B.T],u.S)
B.W=t([4,0],u.t)
B.a6=t([B.c,B.f,B.j,B.A,B.W],u.S)
B.h=t([1,1],u.t)
B.av=t([B.c,B.e,B.f,B.h],u.S)
B.k=t([1,2],u.t)
B.l=t([2,1],u.t)
B.p=t([2,2],u.t)
B.ae=t([B.c,B.e,B.i,B.f,B.h,B.k,B.j,B.l,B.p],u.S)
B.ac=t([B.c,B.e,B.f],u.S)
B.aa=t([B.c,B.e,B.h],u.S)
B.Z=t([B.c,B.f,B.h],u.S)
B.ax=t([B.e,B.f,B.h],u.S)
B.ag=t([B.c,B.f,B.j,B.l],u.S)
B.U=t([B.c,B.e,B.i,B.f],u.S)
B.at=t([B.c,B.e,B.h,B.l],u.S)
B.a1=t([B.i,B.f,B.h,B.k],u.S)
B.a8=t([B.e,B.h,B.j,B.l],u.S)
B.a_=t([B.c,B.f,B.h,B.k],u.S)
B.af=t([B.c,B.e,B.f,B.j],u.S)
B.ar=t([B.c,B.e,B.i,B.k],u.S)
B.ap=t([B.c,B.e,B.i,B.h],u.S)
B.aw=t([B.e,B.f,B.h,B.k],u.S)
B.ao=t([B.c,B.f,B.h,B.j],u.S)
B.as=t([B.e,B.f,B.h,B.l],u.S)
B.ah=t([B.e,B.i,B.f,B.h],u.S)
B.am=t([B.c,B.f,B.h,B.l],u.S)
B.ay=t([B.c,B.e,B.h,B.k],u.S)
B.aj=t([B.e,B.f,B.h,B.j],u.S)
B.Y=t([B.c,B.e,B.i,B.f,B.h,B.k],u.S)
B.ad=t([B.c,B.e,B.f,B.h,B.j,B.l],u.S)
B.a3=t([B.c,B.f,B.j,B.l,B.p],u.S)
B.an=t([B.c,B.e,B.i,B.f,B.j],u.S)
B.a2=t([B.c,B.e,B.i,B.k,B.p],u.S)
B.ab=t([B.i,B.k,B.j,B.l,B.p],u.S)
B.a0=t([B.c,B.h],u.S)
B.a7=t([B.e,B.f],u.S)
B.d=t([B.a5,B.a4,B.au,B.a9,B.X,B.V,B.al,B.aq,B.a6,B.av,B.ae,B.ac,B.aa,B.Z,B.ax,B.ag,B.U,B.at,B.a1,B.a8,B.a_,B.af,B.ar,B.ap,B.aw,B.ao,B.as,B.ah,B.am,B.ay,B.aj,B.Y,B.ad,B.a3,B.an,B.a2,B.ab,B.a0,B.a7],A.b4("p<c<c<a>>>"))
B.ai=t(["freeze","expand","reflect","salt"],u.s)
B.aC=new A.a1(0,1)
B.aD=new A.a1(0,-1)
B.aE=new A.a1(1,0)
B.aF=new A.a1(-1,0)
B.ak=t([B.aC,B.aD,B.aE,B.aF],u.u)
B.az={duel:0,trio:1}
B.r=new A.b9(B.az,[2,3],A.b4("b9<o,a>"))
B.aA={freeze:0,salt:1}
B.aG=new A.aQ(B.aA,2,u.Y)
B.aB={tl:0,tr:1,bl:2,br:3}
B.C=new A.aQ(B.aB,4,u.Y)
B.aH=A.aa("j8")
B.aI=A.aa("j9")
B.aJ=A.aa("hn")
B.aK=A.aa("ho")
B.aL=A.aa("hp")
B.aM=A.aa("hq")
B.aN=A.aa("hr")
B.aO=A.aa("y")
B.aP=A.aa("hH")
B.aQ=A.aa("hI")
B.aR=A.aa("hJ")
B.aS=A.aa("eA")})();(function staticFields(){$.dA=null
$.a0=A.e([],A.b4("p<y>"))
$.f7=null
$.eW=null
$.eV=null
$.fH=null
$.fD=null
$.fP=null
$.dV=null
$.eb=null
$.eK=null
$.dE=A.e([],A.b4("p<c<y>?>"))})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"ja","eP",()=>A.iS("_$dart_dartClosure"))
t($,"jo","h0",()=>A.e([new J.c0()],A.b4("p<bt>")))
t($,"jd","fR",()=>A.ai(A.dy({
toString:function(){return"$receiver$"}})))
t($,"je","fS",()=>A.ai(A.dy({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"jf","fT",()=>A.ai(A.dy(null)))
t($,"jg","fU",()=>A.ai(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"jj","fX",()=>A.ai(A.dy(void 0)))
t($,"jk","fY",()=>A.ai(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"ji","fW",()=>A.ai(A.fb(null)))
t($,"jh","fV",()=>A.ai(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"jm","h_",()=>A.ai(A.fb(void 0)))
t($,"jl","fZ",()=>A.ai(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"jn","ei",()=>A.fN(B.aO))
t($,"jq","ej",()=>A.hz([37,38],u.p))
t($,"jp","bN",()=>{var s,r=A.e([],u.t)
for(s=0;s<39;++s)if(!$.ej().D(0,s))r.push(s)
return r})})();(function nativeSupport(){!function(){var t=function(a){var n={}
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
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.aU,SharedArrayBuffer:A.aU,ArrayBufferView:A.bp,DataView:A.c6,Float32Array:A.c7,Float64Array:A.c8,Int16Array:A.c9,Int32Array:A.ca,Int8Array:A.cb,Uint16Array:A.cc,Uint32Array:A.cd,Uint8ClampedArray:A.bq,CanvasPixelArray:A.bq,Uint8Array:A.ce})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.aV.$nativeSuperclassTag="ArrayBufferView"
A.bC.$nativeSuperclassTag="ArrayBufferView"
A.bD.$nativeSuperclassTag="ArrayBufferView"
A.bn.$nativeSuperclassTag="ArrayBufferView"
A.bE.$nativeSuperclassTag="ArrayBufferView"
A.bF.$nativeSuperclassTag="ArrayBufferView"
A.bo.$nativeSuperclassTag="ArrayBufferView"})()
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
var t=A.j2
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()