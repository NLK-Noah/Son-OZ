 
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
    fun {Mix P2T Music}
      case Music
      of nil then nil
      [] H|T then {Append {Mix P2T H} {Mix P2T T}}
      [] samples(Samples) then Samples
      [] partition(Partition) then {P2T Partition}
      [] wave(filename:F) then {Project2025.readFile CWD#F}
      [] merge(Im) then {Merge Im P2T} 
      else
         raise error(unknownMusicElement(Music)) end
      end
   end
end