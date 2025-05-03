%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Projet Son'OZ - LINFO1104 (UCLouvain)
%%
%% Auteurs :
%%   - Akman Kaan [0910-23-00]
%%   - Moussaoui Noah [8231-23-00]
%%
%% Fichier : Mix.oz
%% Description : Interprétation de structures musicales en échantillons WAV
%%               (notes, silences, effets, partitions, filtres).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 functor
 import
    Project2025
    OS
    System
    Property
 export 
    mix: Mix
 define
    % Variable qui permet d'activer nos extensions 
    % Il suffit de switch à true pour activer l'extension
    % et de switch à false pour la désactiver
    ActivatorOfExtensions = false
    % Constantes
    Pi = 3.14159265358979323846
    SampleRate = 44100.0
   % Get the full path of the program
    CWD = {Atom.toString {OS.getCWD}}#"/"

   % Clip chaque échantillon entre -1.0 et 1.0
   fun {NormalizeIntervals L}
      fun {Value X}
         if X > 1.0 then 1.0
         elseif X < ~1.0 then ~1.0
         else X
         end
      end
   in
      {Map L Value}
   end
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
         raise error(wrongNote(Name#Sharp)) end
      end
   end

   % Calcule la fréquence (en Hz) d'une note à partir de son nom, octave et dièse
   fun {NoteToFrequency Name Octave Sharp}
      NoteIndex = {NoteToIndex Name Sharp}
      H = ((Octave - 4) * 12) + (NoteIndex - 9)
   in
      ({Pow 2.0 ({IntToFloat H} / 12.0)} * 440.0)
   end   

   % Génère une liste d'échantillons sinusoïdaux d'amplitude 0.5 pour une fréquence donnée
   fun {CreateSamples TotalSamples F}
      fun {Loop I}
         if I >= TotalSamples then nil
         else Ai = 0.5 * {Float.sin ((2.0 * Pi * F * {IntToFloat I}) / SampleRate)}
         in
            Ai | {Loop I + 1}
         end
      end
   in
      if TotalSamples =< 0 then nil 
      else 
         {Loop 0}
      end
   end

   % Génère une liste de zéros de longueur N
   fun {Zeros N}
      if N =< 0 then nil
      else 0.0 | {Zeros N - 1}
      end
   end   

   % Convertit une note ou un silence étendu en liste d'échantillons
   fun {NoteToSamples NoteOrSilence}
      case NoteOrSilence
      of silence(duration:D) then
         SampleLength = {Float.toInt D * SampleRate}
      in
         if SampleLength =< 0 then nil 
         else {Zeros SampleLength} end
   
      [] note(name:N octave:O sharp:S duration:D instrument:I) then
         Frequency = {NoteToFrequency N O S}
         SampleLength = {Float.toInt D * SampleRate}
      in
         {CreateSamples SampleLength Frequency}
      else
         raise error(invalidNoteOrSilence(NoteOrSilence)) end
      end
   end   

   % Fusionne plusieurs listes de samples en sommant leurs éléments
   fun {MergeListsOfSamples ListOfSamples}
      fun {SumOfLists Lists}
         if {All Lists fun {$ L} L == nil end} then nil
         else
            Head = {Map Lists
            fun {$ L} 
               case L 
               of H|_ then H 
               else 0.0 
               end 
            end}

            Tail = {Map Lists 
            fun {$ L} 
               case L
               of _|T then T 
               else nil 
               end 
            end}
            
            Result = {FoldL Head Number.'+' 0.0}
         in
            Result | {SumOfLists Tail}
         end
      end
   in
      {SumOfLists ListOfSamples}
   end

   % Convertit un accord (liste de notes étendues) en échantillons en fusionnant les notes
   fun {ChordToSamples Chord}
      L = {Map Chord NoteToSamples}
   in
      {MergeListsOfSamples L}
   end

   % Applique la bonne conversion selon que c'est une note, un silence ou un accord
   fun {SoundToSamples NoteOrSilence}
      case NoteOrSilence
      of note(...) then {NoteToSamples NoteOrSilence}
      [] silence(...) then {NoteToSamples NoteOrSilence}
      [] L then {ChordToSamples L}
      else raise error(invalidSound(NoteOrSilence)) end
      end
   end
   
   % Convertit une partition aplatie (liste de sons étendus) en échantillons
   fun {PartitionToSamples Flat}
      case Flat
      of nil then nil
      [] H|T then
         {Append {SoundToSamples H} {PartitionToSamples T}}
      end
   end

   % Applique le mixage avec pondération des intensités à une liste (intensité # musique)
   fun {ApplyMerge P2T MergeList Mix}
      List = {Map MergeList
         fun {$ Intensity#Music}
            local
               Samples = {Mix P2T Music}
            in
               {Map Samples fun {$ S} Intensity * S end}
            end
         end}
   in
      {MergeListsOfSamples List}
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
      Counter = {Float.toInt Duration * SampleRate}
      fun {MusicExtension Music N}
         if N =< 0 then nil
         else
            {Append Music {MusicExtension Music (N - {Length Music})}}
         end
      end
   in
      {List.take {MusicExtension Music Counter} Counter}
   end

   % Applique un filtre clip : tronque ou restreint les valeurs d'une musique
   fun {Clip Filter List}
      case Filter
      of clip(start:S duration:D music:_) then
         StartId = {Float.toInt S * SampleRate}
         SampleLength = {Float.toInt D * SampleRate}
      in
         {List.take {List.drop List StartId} SampleLength}
   
      [] clip(low:L high:H music:_) then
         if L >= H then
            raise error("Clip: low must be < high") end
         else
            {Map List fun {$ X}
               if X < L then L
               elseif X > H then H
               else X
               end
            end}
         end
      else
         raise error("Clip: wrong arguments") end
      end
   end

   % Supprime les X premiers éléments d’une liste
   fun {DeleteElements X L}
      if X =< 0 then L
      else
         case L of _|T then {DeleteElements X - 1 T}
         [] nil then nil end
      end
   end
   
   % Prend les X premiers éléments d’une liste
   fun {GetElements X L}
      if X =< 0 orelse L == nil then nil
      else
         case L of H|T then H | {GetElements X - 1 T} end
      end
   end
   
   % Génère une liste de X zéros (pour remplir le silence)
   fun {InsertZeros X}
      if X =< 0 then nil
      else 0.0 | {InsertZeros X - 1}
      end
   end
   
   % Coupe une musique entre deux instants (en secondes), complète avec silence si besoin
   fun {Cut Start Finish Music}
      StartId = {Float.toInt Start * SampleRate}
      EndIndex = {Float.toInt Finish * SampleRate}
      
      Diff = (EndIndex - StartId)
      Delete = {DeleteElements StartId Music}
      Get = {GetElements Diff Delete}
      Empty = (Diff - {Length Get})
      Insert = {InsertZeros Empty}
   in
      {Append Get Insert}
   end

   % Applique un fondu linéaire sur le début et la fin d'une liste d'échantillons
   fun {Fade Start Finish Music}
      local
         MusicLength = {Length Music}
         StartCounter = {Float.toInt {Float.ceil Start * SampleRate}}
         FinishCounter = {Float.toInt {Float.ceil Finish * SampleRate}}
      in
         fun {FadeAux I}
            if StartCounter > 0 andthen I < StartCounter then
               ({IntToFloat I} / {IntToFloat StartCounter})
            elseif FinishCounter > 0 andthen I >= MusicLength - FinishCounter then
               ({IntToFloat (MusicLength - I - 1)} / {IntToFloat FinishCounter})
            else 1.0
            end
         end
      end
      fun {Apply I Music}
         case Music
         of nil then nil
         [] H|T then (H * {FadeAux I}) | {Apply (I + 1) T}
         end
      end
   in
      {Apply 0 Music}
   end   

   % Applique un effet d'écho à une musique 
   fun {Echo Delay Decay Repeat Music P2T}
      Base =
         case Music of samples(S) then S
         else {Mix P2T Music} end
      DelaySamples = {Float.toInt (Delay / 0.00011337868)}

      fun {MakeEcho I}
         if I > Repeat then nil
         else
            Level = {Pow Decay {Int.toFloat I}}
            Echoed = {Map Base fun {$ X} X * Level end}
            Insert = {InsertZeros (DelaySamples * I)}
            EchoPart = {Append Insert Echoed}
         in
            EchoPart | {MakeEcho (I + 1)}
         end
      end

      EchoList = Base | {MakeEcho 1}
   in
      {MergeListsOfSamples EchoList}
   end

   fun {Reverse Music}
      fun {ReverseAcc L Acc}
         case L
         of nil then Acc
         [] H|T then {ReverseAcc T H|Acc}
         end
      end
   in
      {ReverseAcc Music nil}
   end
   
   % Fonction principale Mix : interprète tous les types de musique et retourne des échantillons
   fun {Mix P2T Music}
      case Music
      of nil then nil
      [] H|T then
         local Result = case H
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

               [] echo(delay:D decay:Dec repeat:R music:M) then
                  {Append {Echo D Dec R M P2T} {Mix P2T T}} 

               [] reverse(...) then
                  if ActivatorOfExtensions then
                     {Append {Reverse {Mix P2T H.music}} {Mix P2T T}}
                  else
                     {System.show "L'extension n'est pas activée, reverse ne sera pas appliqué"}
                     {Mix P2T T}
                  end
               else
                  raise error(wrongMusic(H)) end
            end
         in
            {NormalizeIntervals Result}
         end
      end
   end
   
end