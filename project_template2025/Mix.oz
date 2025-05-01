 
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

   % Début de la fonction VectorSum
   fun{VectorSum V}
      case V of nil then 0.0
      [] H|T then H + {VectorSum T}
         else
            raise error(unknownList(V))
         end
      end
   end
   %fin de la fonction VectorSum
    % Début de la fonction Merge 
    fun {Merge Im P2T}
         case Im of nil then nil
         [] (Intensite#MusicDesc)|T then
            Music = {Mix P2T MusicDesc}
            MusicScaled = {Map Music fun {$ S} S * Intensite end}
         in
            {VectorSum MusicScaled} | {Merge T P2T}
         end
   end
   % Fin de la fonction Merge   
      
   % Début de la fonction Repeat
   fun {Repeat L N}
      if N =< 0 then nil
      else {Append L {Repeat L (N - 1)}}
      end
   end
   % Fin de la fonction Repeat

   % Début de la fonction Loop
   fun {Loop D M P2T FiveSamples}
      Samples = {Mix P2T M}
      SampleLen = {Length Samples}
      TotalNeeded = {FloatToInt D / FiveSamples}
      
      fun {RepeatUntil N Acc}
         if N =< 0 then Acc
         elseif N < SampleLen then
            {Append Acc {List.take Samples N}}
         else
            {RepeatUntil (N - SampleLen) {Append Acc Samples}}
         end
      end
   in
      {RepeatUntil TotalNeeded nil}
   end
   
   
   % Fin de la fonction Loop
   % Début de la fonction Clip
   fun {Clip Low High X}
      if X < Low then Low
      elseif X > High then High
      else X
      end
   end
   % Fin de la fonction Clip
       
   % Mix principal
   fun {Mix P2T Music}
      case Music
      of nil then nil
      [] H|T then {Append {Mix P2T H} {Mix P2T T}}
      [] samples(Samples) then Samples
      [] partition(Partition) then {P2T Partition}
      [] wave(filename:F) then {Project2025.readFile CWD#F}
      [] merge(Im) then {Merge Im P2T}
      [] reverse(M) then {Reverse {Mix P2T M}} 
      [] repeat(amount:A music:M) then {Repeat {Mix P2T M} A}
      [] loop(duration:D music:M) then {Loop D M P2T 0.00011337868}
      [] clip(low:Low high:High music:M) then {Map {Mix P2T M} fun {$ X} {Clip Low High X} end}
      else  
         raise error(unknownMusicElement(Music  )) end
      end
   end
end