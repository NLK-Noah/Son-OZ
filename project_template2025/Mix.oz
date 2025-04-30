 
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
      else
         raise error(unknownMusicElement(Music)) end
      end
   end
end