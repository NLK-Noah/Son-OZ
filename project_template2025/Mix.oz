 
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

    fun {Mix P2T Music}
      case Music of nil then nil
      [] samples(S) | _ then S
      else
         {Project2025.readFile CWD#'wave/animals/cow.wav'}
      end
    end
end