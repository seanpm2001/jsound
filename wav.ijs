NB. Functions to read to and write from wave files.
NB. Does not work on many kinds of wave files, such as compressed data.

default =. ".@:(, '=:',":) ^: (0~:4!:0@<@[)
'FMT' default 1 16
'F'   default 44100

NB. The output from readwav (input to writewav) is either:
NB. - A list containing three boxes:
NB.     The sample rate (in Hz)
NB.     The audio format (see below)
NB.     PCM data, which has shape (n,l) for n-channels with l samples.
NB. - The last of these three, unboxed.
NB.
NB. For the latter case, the sample rate and audio format default to
NB. the constant values F and FMT (in the base locale).
NB. For a read, the second case is used whenever both of these values
NB. match their corresponding constants.

NB. The audio format consists of the type of audio and the bit depth.
NB. The type is one of:
NB.   1  unsigned integer
NB.   3  floating point
NB. Other audio formats may be supported in the future.

cocurrent 'pwav'

NB. ---------------------------------------------------------
WAVE_HEADER =: ((;:@{. , >:@[<@}.])~ i.&'|');._2 ] 0 : 0
4 c ChunkID        |'RIFF'
4 i ChunkSize      |20 + Subchunk1Size + Subchunk2Size
4 c Format         |'WAVE'
4 c Subchunk1ID    |'fmt '
4 i Subchunk1Size  |16
2 i AudioFormat    |
2 i NumChannels    |
4 i SampleRate     |
4 i ByteRate       |SampleRate * NumChannels * BitsPerSample%8
2 i BlockAlign     |NumChannels * BitsPerSample%8
2 i BitsPerSample  |
4 c Subchunk2ID    |'data'
4 i Subchunk2Size  |
)

'LEN TYP NAME DEF' =: <"_1|: WAVE_HEADER
LEN =: ".@> LEN
TYP =: ; TYP

NB. Topological order for field definitions
tsort =. (] , 1 i.~ ] (0"0@[)`[`]} (*./@:e.&> <))^:(>&#)^:_ & ($0)
ORDER =: tsort (+./@:E.)&>~&NAME(I.@:)(<@)"0 DEF
NB. Fill blank definitions with their own names.
DEF =: =&a:`(,:&NAME)} DEF

NB. Get integer from little-endian unsigned byte representation.
toint =: 256 #. a.i.|.

NB. ---------------------------------------------------------
NB. u is (AudioFormat,BitsPerSample).
NB. Return an invertible verb to convert bitstream to PCM data.
audioconvert =: 1 : 0
'AudioFormat BitsPerSample' =. u
if. 1 = AudioFormat do.
  mb =. -b =. BitsPerSample%8
  'Bits per sample cannot exceed 64' assert b <: 8
  m2p =. -2^ p =. 2 >.@^. b
  (2<.@^8*-b+m2p) <.@%~ :.* (-p) (3!:4) mb&(m2p&({.!.({.a.))\)(,@:) :. (m2p&(mb&{.\)(,@:))
elseif. 3 = AudioFormat do.
  'Floating point only supports 32-bit' assert 32 = BitsPerSample
  _1&(3!:5)
elseif. do.
  0 assert~ 'Unsupported audio format: ',":AudioFormat
end.
)

NB. =========================================================
NB. readwav, writewav

NB. ---------------------------------------------------------
NB. y is the path to a wave file.
NB. readwav returns the PCM data from that file.
NB. The output has shape (n,l) for n-channel sound.
readwav =: 3 : 0
y =. 1!:1 boxopen y
'hdr y' =. (+/LEN) ({. ; }.) y

NB. Assign field values to field names.
(NAME) =. hdr =. ('i'=TYP) toint&.>@]^:["0 hdr (</.~ I.) LEN
NB. Check that fields match their definitions
msg =. 'Values for fields ' , ' are incorrect' ,~ ;:^:_1
(*./ assert~ [: msg NAME#~-.) hdr = ".&.> DEF

fmt =. AudioFormat,BitsPerSample
SampleRate;fmt; |: (-NumChannels) ]\ fmt audioconvert y
)

NB. ---------------------------------------------------------
NB. x is PCM data as output by readwav, and y is the file to write to.
writewav =: 4 : 0
'SampleRate fmt x' =. x
NumChannels =. #x
Subchunk2Size =. #x =. fmt audioconvert^:_1 ,|:x
'AudioFormat BitsPerSample' =. fmt

for_i. ORDER do. (i{::NAME) =. ". i{::DEF end.

hdr =. ; LEN {.!.({.a.)&.> ('i'=TYP) toint^:_1&.>@]^:["0 ".&.> NAME
(hdr, x) 1!:2 boxopen y
)

NB. =========================================================
cocurrent 'base'
readwav  =: 3 : '_1&{::^:((F;FMT) -: 2&{.) readwav_pwav_ y'
writewav =: 4 : '((F;FMT;])^:(0=L.) x) writewav_pwav_ y'
