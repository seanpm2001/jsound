NB. C and J implementations of (mostly) IIR filters.

NB. Assumes 44.1 kHz.
F =: 44100

NB. ---------------------------------------------------------
NB. C filter binding
pointer_to_name =: 1 { [: memr (0 4,JINT) ,~ symget@boxopen@,
vptrn =: (+ [: memr ,&0 1 4)@:pointer_to_name
LIBFILTER =: jpath '~user/Sound/libsynth.so'

NB. Generalized filtering with C
NB. y is the signal to filter
NB. x is (x coefficients ; y coefficients).
filter =: 4 : 0 "1
y =. (-~2.1) + y
assert. 8 = 3!:0 y  NB. Input must be floating point
'xc yc' =. x
(LIBFILTER, ' filter > n',6 rep' x') cd ,(#@".,vptrn)@> ;:'y xc yc'
y
)

NB. ---------------------------------------------------------
NB. Coefficients for specific filters

makefilter =: 1 :'u 2 :''(u n)&filter'''

lpcutoff =: (F%2p1) * <:&.%
hpcutoff =: (F%2p1) * <:@%

NB. two-pole low-pass filter coefficient generator
NB. y is the corrected cutoff frequency
NB. x is the p,g list
getlpcoeffs2 =: 3 ({. ;&|. }.) [: (,1-+/)@:((1 2 1 , 2*1-~%@{:) * ({: % 1++/)) (* (,*:)@:(3 o.o.))

NB. m is (filter type);(number of passes);(0 if lowpass, 1 if highpass)
NB. filter type is one of 'bw', 'cd', or 'bessel'.
getcoeffs =: 1 : 0
't n ifhp' =. m
assert. 3 > t =. ('bw';'cd';'bessel') i. <t
C  =.  (4%:<:) ` (%:@<:@%:) ` (3 %:@* 0.5 -~ %:@-&0.75) @. t   n%:2
X  =.  t {:: (%:2 1) , 2 1 ,: 3 3
if. ifhp do.
  (1 _1 1; 1 _1) *&.> X getlpcoeffs2 0.5 - (C%F)&*
else.
  X getlpcoeffs2 (%C*F)&*
end.
)

(".@:({.,'=:(',}.,') makefilter'"_)~ i.&' ');._2 ]0 : 0
lowpass    [: (;-.) lpcutoff^:_1
highpass   [: (;~ (,~-)) hpcutoff^:_1
bwlp2      ('bw';1;0) getcoeffs
bwhp2      ('bw';1;1) getcoeffs
cdlp2      ('cd';1;0) getcoeffs
cdhp2      ('cd';1;1) getcoeffs
bslp2  ('bessel';1;0) getcoeffs
bshp2  ('bessel';1;1) getcoeffs
)

NB. Doesn't work...
NB. getcoeffs =: [: (;&|. }.)/@:(% (<1 0)&{) (2*F) p.~ (] , (2 0 _2*|.) ,: 1 _1 1&*)"1

NB. ---------------------------------------------------------
NB. Notch filter
NB. y is (frequency, width) in Hz.
NB. Filter with no gain outside of the notch due to A.G. Constantinides
NB. The width is for 3dB attenuation although in practice the filter
NB. seems to be about 15% wider.
notch =: (3 : 0) makefilter
'w0 dw' =. 2p1 * y%F
cw =. 2 o. w0
k =. (2%>:cw) * 3 o. -:dw
(_2*cw) ({.@] %~&.> (1,1,~[) (;-) [,~{:@]) 1(+,-)k
)

0 : 0 NB. Alternate notch filter design
w0 =. 2p1 * ({.y)%F
r =. 1{y,0.99
((%:r)&* ; [: -@:|.@:}. (r^i.3)&*) 1,(_2*2 o. w0),1
)

NB. ---------------------------------------------------------
NB. high-pass filter with variable frequency
highpass_f =: 4 : 0"1
y =. (-~2.1) + y
x =. (-~2.1) + x
assert. x *.&(8 = 3!:0) y
assert. x (= <:)&# y
x =. hpcutoff^:_1 x
(LIBFILTER, ' highpass_f > n',3 rep' x') cd (#y), ,vptrn@> ;:'y x'
y
)