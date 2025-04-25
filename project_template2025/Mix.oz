 
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
   % Mix principal
   fun {Mix P2T Music}
      case Music
      of nil then nil
      [] samples(Samples) then Samples
      [] partition(Partition) then {P2T Partition}
      [] wave(filename:F) then {Project2025.readFile CWD#F}
      [] H|T then {Append {Mix P2T H} {Mix P2T T}}
      else
         raise error(unknownMusicElement(Music)) end
      end
   end
end