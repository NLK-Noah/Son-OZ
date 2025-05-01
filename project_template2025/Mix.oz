 
 functor
 import
    Project2025
    OS
    System
    Property
 export 
    mix: Mix
 define
   % Get the full path of the program
    CWD = {Atom.toString {OS.getCWD}}#"/"
    % {Project2025.readFile CWD#'wave/animals/cow.wav'} Pour pas le perdre

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    fun {NoteToIndex Name Sharp}
      case Name#Sharp
      of c#false then 0 [] c#true  then 1
      [] d#false then 2 [] d#true  then 3
      [] e#false then 4
      [] f#false then 5 [] f#true  then 6
      [] g#false then 7 [] g#true  then 8
      [] a#false then 9 [] a#true  then 10
      [] b#false then 11
      else
         raise error(invalidNote(Name#Sharp)) end
      end
   end

   fun {NoteToFrequency Name Octave Sharp}
      Index = {NoteToIndex Name Sharp}
      Height = (Octave - 4) * 12 + (Index - 9)
   in
      {Pow 2.0 ({IntToFloat Height} / 12.0)} * 440.0
   end   

   fun {MakeSamples N F}
      fun {Loop I}
         if I >= N then nil
         else
            A = 0.5 * {Float.sin ((2.0 * 3.1415926535 * F * {IntToFloat I}) / 44100.0)}
         in
            A | {Loop I + 1}
         end
      end
   in
      if N =< 0 then nil 
      else 
         {Loop 0}
      end
   end

   fun {NoteToSamples Sound}
      case Sound
      of silence(duration:D) then
         Len = {Float.toInt D * 44100.0}
      in
         if Len =< 0 then nil else {List.make Len 0.0} end
   
      [] note(name:N octave:O sharp:S duration:D instrument:_) then
         Freq = {NoteToFrequency N O S}
         Len = {Float.toInt D * 44100.0}
      in
         {MakeSamples Len Freq}
   
      else
         raise error(invalidNoteOrSilence(Sound)) end
      end
   end   

   fun {MergeSamples SampleLists}
      fun {ZipSum Ls}
         if {All Ls fun {$ L} L == nil end} then nil
         else
            Heads = {Map Ls fun {$ L} case L of H|_ then H else 0.0 end end}
            Tails = {Map Ls fun {$ L} case L of _|T then T else nil end end}
            Sum = {FoldL Heads Number.'+' 0.0}
         in
            Sum | {ZipSum Tails}
         end
      end
   in
      {ZipSum SampleLists}
   end

   fun {ChordToSamples Chord}
      SampleLists = {Map Chord NoteToSamples}
   in
      {MergeSamples SampleLists}
   end

   fun {SoundToSamples Sound}
      case Sound
      of note(...) then {NoteToSamples Sound}
      [] silence(...) then {NoteToSamples Sound}
      [] L then {ChordToSamples L}
      else raise error(invalidSound(Sound)) end
      end
   end
   
   fun {PartitionToSamples Flat}
      case Flat
      of nil then nil
      [] H | T then
         {Append {SoundToSamples H} {PartitionToSamples T}}
      end
   end
   
   fun {ApplyMerge P2T MergeList Mix}
      SampleLists = {Map MergeList
         fun {$ Intensity#Music}
            local
               Samples = {Mix P2T Music}
            in
               {Map Samples fun {$ S} Intensity * S end}
            end
         end}
   in
      {MergeSamples SampleLists}
   end

   fun {Repeat Amount Music}
      if Amount =< 0 then nil
      else
         {Append Music {Repeat (Amount - 1) Music}}
      end
   end

   fun {Loop Duration Music}
      SampleCount = {Float.toInt Duration * 44100.0}
      fun {Extend Music N}
         if N =< 0 then nil
         else
            {Append Music {Extend Music (N - {Length Music})}}
         end
      end
   in
      {List.take {Extend Music SampleCount} SampleCount}
   end

   fun {Clip ClipSpec L}
      case ClipSpec
      of clip(start:Start duration:Dur music:_) then
         StartIndex = {Float.toInt Start * 44100.0}
         Length     = {Float.toInt Dur * 44100.0}
      in
         {List.take {List.drop L StartIndex} Length}
   
      [] clip(low:Low high:High music:_) then
         if Low >= High then
            raise error("Clip: low must be < high") end
         else
            {Map L fun {$ X}
               if X < Low then Low
               elseif X > High then High
               else X
               end
            end}
         end
      else
         raise error("Clip: invalid or unsupported arguments") end
      end
   end
   
   % Mix principal
   fun {Mix P2T Music}
      case Music
      of nil then nil
      [] H | T then
         case H
         of samples(Sample) then
            {Append Sample {Mix P2T T}}
   
         [] partition(Partition) then
            {Append {PartitionToSamples {P2T Partition}} {Mix P2T T}}
   
         [] wave(filename:F) then
            {Append {Project2025.readFile F} {Mix P2T T}}
   
         [] merge(MWI) then
            {Append {ApplyMerge P2T MWI Mix} {Mix P2T T}}

         [] repeat(amount:A music:M) then
            {Append {Repeat A {Mix P2T M}} {Mix P2T T}}

         [] loop(duration:D music:M) then
            {Append {Loop D {Mix P2T M}} {Mix P2T T}}

         [] clip(...) then
            {Append {Clip H {Mix P2T H.music}} {Mix P2T T}}
   
         else
            raise error(unsupportedMusicPart(H)) end
         end
      end
   end   
end