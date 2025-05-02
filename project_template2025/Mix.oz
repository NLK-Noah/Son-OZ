 
 functor
 import
    Project2025
    OS
    System
    Property
 export 
    mix: Mix
 define
    % Constantes
    Pi = 3.14159265358979323846
    SampleRate = 44100.0
   % Get the full path of the program
    CWD = {Atom.toString {OS.getCWD}}#"/"

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Convertit une note en index de 0 à 11
    fun {NoteToIndex Name Sharp}
      case Name#Sharp
      of c#false then 0 
      [] c#true  then 1
      [] d#false then 2 
      [] d#true  then 3
      [] e#false then 4
      [] f#false then 5 
      [] f#true  then 6
      [] g#false then 7 
      [] g#true  then 8
      [] a#false then 9 
      [] a#true  then 10
      [] b#false then 11
      else
         raise error(invalidNote(Name#Sharp)) end
      end
   end

   % Calcule la fréquence (en Hz) d'une note à partir de son nom, octave et dièse
   fun {NoteToFrequency Name Octave Sharp}
      Index = {NoteToIndex Name Sharp}
      Height = ((Octave - 4) * 12) + (Index - 9)
   in
      ({Pow 2.0 ({IntToFloat Height} / 12.0)} * 440.0)
   end   

   % Génère une liste d'échantillons sinusoïdaux d'amplitude 0.5 pour une fréquence donnée
   fun {MakeSamples N F}
      fun {Loop I}
         if I >= N then nil
         else
            Ai = 0.5 * {Float.sin ((2.0 * Pi * F * {IntToFloat I}) / SampleRate)}
         in
            Ai | {Loop I + 1}
         end
      end
   in
      if N =< 0 then nil 
      else 
         {Loop 0}
      end
   end
   % Convertit une note ou un silence étendu en liste d'échantillons
   fun {NoteToSamples Sound}
      case Sound
      of silence(duration:D) then
         Len = {Float.toInt D * SampleRate}
      in
         if Len =< 0 then nil else {List.make Len 0.0} end
   
      [] note(name:N octave:O sharp:S duration:D instrument:I) then
         Freq = {NoteToFrequency N O S}
         Len = {Float.toInt D * SampleRate}
      in
         {MakeSamples Len Freq}
   
      else
         raise error(invalidNoteOrSilence(Sound)) end
      end
   end   

   % Fusionne plusieurs listes de samples en sommant leurs éléments
   fun {MergeSamples SampleLists}
      fun {ZipSum Ls}
         if {All Ls fun {$ L} L == nil end} then nil
         else
            Heads = {Map Ls 
            fun {$ L} 
               case L 
               of H|_ then H 
               else 0.0 end 
            end}

            Tails = {Map Ls 
            fun {$ L} 
               case L 
               of _|T then T 
               else nil end 
            end}
            
            Sum = {FoldL Heads Number.'+' 0.0}
         in
            Sum | {ZipSum Tails}
         end
      end
   in
      {ZipSum SampleLists}
   end

   % Convertit un accord (liste de notes étendues) en échantillons en fusionnant les notes
   fun {ChordToSamples Chord}
      SampleLists = {Map Chord NoteToSamples}
   in
      {MergeSamples SampleLists}
   end

   % Applique la bonne conversion selon que c'est une note, un silence ou un accord
   fun {SoundToSamples Sound}
      case Sound
      of note(...) then {NoteToSamples Sound}
      [] silence(...) then {NoteToSamples Sound}
      [] L then {ChordToSamples L}
      else raise error(invalidSound(Sound)) end
      end
   end
   
   % Convertit une partition aplatie (liste de sons étendus) en échantillons
   fun {PartitionToSamples Flat}
      case Flat
      of nil then nil
      [] H | T then
         {Append {SoundToSamples H} {PartitionToSamples T}}
      end
   end
   % Applique le mixage avec pondération des intensités à une liste (intensité # musique)
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

   % Répète une musique A fois en concaténant les samples
   fun {Repeat Amount Music}
      if Amount =< 0 then nil
      else
         {Append Music {Repeat (Amount - 1) Music}}
      end
   end

   % Répète une musique jusqu’à atteindre une durée (en secondes)
   fun {Loop Duration Music}
      SampleCount = {Float.toInt Duration * SampleRate}
      fun {Extend Music N}
         if N =< 0 then nil
         else
            {Append Music {Extend Music (N - {Length Music})}}
         end
      end
   in
      {List.take {Extend Music SampleCount} SampleCount}
   end

   % Applique un filtre clip : tronque ou restreint les valeurs d'une musique
   fun {Clip ClipSpec L}
      case ClipSpec
      of clip(start:Start duration:Dur music:_) then
         StartIndex = {Float.toInt Start * SampleRate}
         Length     = {Float.toInt Dur * SampleRate}
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

   % Supprime les N premiers éléments d’une liste
   fun {DropUntil N L}
      if N =< 0 then L
      else
         case L of _|T then {DropUntil N - 1 T}
         [] nil then nil end
      end
   end
   
   % Prend les N premiers éléments d’une liste
   fun {TakeUntil N L}
      if N =< 0 orelse L == nil then nil
      else
         case L of H|T then H | {TakeUntil N - 1 T} end
      end
   end
   
   % Génère une liste de N zéros (pour remplir le silence)
   fun {FillZeros N}
      if N =< 0 then nil
      else 0.0 | {FillZeros N - 1}
      end
   end
   
   % Coupe une musique entre deux instants (en secondes), complète avec silence si besoin
   fun {Cut Start Finish Music}
      StartIndex = {Float.toInt Start * SampleRate}
      EndIndex = {Float.toInt Finish * SampleRate}
      Needed = (EndIndex - StartIndex)
   
      Dropped = {DropUntil StartIndex Music}
      Taken = {TakeUntil Needed Dropped}
      Missing = (Needed - {Length Taken})
      Filling = {FillZeros Missing}
   in
      {Append Taken Filling}
   end

   %% Applique un fondu linéaire sur le début et la fin d'une liste d'échantillons
   %% start : durée (en secondes) de fondu entrant (0.0 → 1.0)
   %% finish : durée (en secondes) de fondu sortant (1.0 → 0.0)
   %% music : liste de samples
   fun {Fade Start Finish Music}
      local
         N = {Length Music}
         StartCount = {Float.toInt {Float.ceil Start * SampleRate}}
         FinishCount = {Float.toInt {Float.ceil Finish * SampleRate}}
      in
         fun {FadeCoeff I}
            if StartCount > 0 andthen I < StartCount then
               {IntToFloat I} / {IntToFloat StartCount}
            elseif FinishCount > 0 andthen I >= N - FinishCount then
               {IntToFloat (N - I - 1)} / {IntToFloat FinishCount}
            else
               1.0
            end
         end
      end
      fun {Apply I L}
         case L
         of nil then nil
         [] H|T then (H * {FadeCoeff I}) | {Apply I + 1 T}
         end
      end
   in
      {Apply 0 Music}
   end   
   
   % Fonction principale Mix : interprète tous les types de musique et retourne des échantillons
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

         [] cut(...) then
            {Append {Cut H.start H.finish {Mix P2T H.music}} {Mix P2T T}}    
            
         [] fade(...) then
            {Append {Fade H.start H.finish {Mix P2T H.music}} {Mix P2T T}}

         else
            raise error(unsupportedMusicPart(H)) end
         end
      end
   end   
end